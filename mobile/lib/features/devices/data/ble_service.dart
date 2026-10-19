import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:uuid/uuid.dart' as uuid_pkg;

import '../domain/ble_models.dart';

/// Service managing Bluetooth Low Energy (BLE) peripheral discovery, GATT characteristics parsing,
/// physiological bounds checking, and provenance tagging (Requirements 28.1 – 28.7).
class BleService {
  final FlutterReactiveBle? _ble;
  static const _uuid = uuid_pkg.Uuid();

  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  DeviceConnectionState _connectionState = DeviceConnectionState.disconnected;
  String? _connectedDeviceId;

  BleService([FlutterReactiveBle? ble]) : _ble = ble;

  DeviceConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == DeviceConnectionState.connected;
  String? get connectedDeviceId => _connectedDeviceId;

  // ── 1. Lifecycle & Scanning (Requirement 28.6) ───────────────────────────────

  /// Scans for nearby BLE medical devices.
  /// Automatically stops after [timeout] to prevent battery drain.
  Stream<DiscoveredBleDevice> scanForDevices({
    List<Uuid> serviceFilter = const [],
    Duration timeout = const Duration(seconds: 15),
  }) {
    final controller = StreamController<DiscoveredBleDevice>();

    if (_ble == null) {
      // In headless test / mock environments without BLE hardware
      controller.close();
      return controller.stream;
    }

    try {
      _scanSub?.cancel();
      _scanSub = _ble.scanForDevices(
        withServices: serviceFilter,
        scanMode: ScanMode.lowLatency,
      ).listen(
        (device) {
          controller.add(
            DiscoveredBleDevice(
              id: device.id,
              name: device.name.isNotEmpty ? device.name : 'Unknown BLE Device',
              rssi: device.rssi,
              serviceUuids: device.serviceUuids.map((u) => u.toString()).toList(),
            ),
          );
        },
        onError: (err) {
          debugPrint('BLE Scan error: $err');
          controller.close();
        },
      );

      // Enforce timeout to terminate scanning and preserve battery (Requirement 28.6)
      Timer(timeout, () {
        stopScan();
        if (!controller.isClosed) controller.close();
      });
    } catch (e) {
      debugPrint('BLE Scan Exception: $e');
      controller.close();
    }

    return controller.stream;
  }

  /// Explicitly halts active BLE scan.
  void stopScan() {
    _scanSub?.cancel();
    _scanSub = null;
  }

  /// Connects to a selected BLE peripheral.
  /// Binds connection lifetime strictly to measurement screen lifecycle (Requirement 28.6).
  Future<bool> connect(String deviceId) async {
    if (_ble == null) {
      _connectedDeviceId = deviceId;
      _connectionState = DeviceConnectionState.connected;
      return true;
    }

    final completer = Completer<bool>();
    _connectionSub?.cancel();

    _connectionSub = _ble.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 10),
    ).listen(
      (update) {
        _connectionState = update.connectionState;
        if (update.connectionState == DeviceConnectionState.connected) {
          _connectedDeviceId = deviceId;
          if (!completer.isCompleted) completer.complete(true);
        } else if (update.connectionState == DeviceConnectionState.disconnected) {
          _connectedDeviceId = null;
          if (!completer.isCompleted) completer.complete(false);
        }
      },
      onError: (err) {
        debugPrint('BLE Connect Error: $err');
        _connectionState = DeviceConnectionState.disconnected;
        _connectedDeviceId = null;
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    return completer.future;
  }

  /// Disconnects from the active device and releases hardware handles (Requirement 28.6).
  Future<void> disconnect() async {
    stopScan();
    await _connectionSub?.cancel();
    _connectionSub = null;
    _connectedDeviceId = null;
    _connectionState = DeviceConnectionState.disconnected;
  }

  // ── 2. Standard GATT Payload Parsers ─────────────────────────────────────────

  /// Parses Bluetooth SIG Blood Pressure Measurement characteristic (0x2A35).
  /// Returns (Systolic, Diastolic, HeartRate)
  static Map<String, double> parseBloodPressure(List<int> bytes) {
    if (bytes.length < 5) {
      throw const FormatException('Invalid Blood Pressure GATT payload length');
    }

    final flags = bytes[0];
    final isKpa = (flags & 0x01) != 0; // 0 = mmHg, 1 = kPa
    final hasPulse = (flags & 0x04) != 0;

    double systolic = (bytes[1] | (bytes[2] << 8)).toDouble();
    double diastolic = (bytes[3] | (bytes[4] << 8)).toDouble();

    if (isKpa) {
      // Convert kPa to mmHg: 1 kPa ~ 7.50062 mmHg
      systolic = systolic * 7.50062;
      diastolic = diastolic * 7.50062;
    }

    double? pulseRate;
    if (hasPulse && bytes.length >= 16) {
      // If timestamps present (bit 1 set), pulse is at bytes 14-15
      pulseRate = (bytes[14] | (bytes[15] << 8)).toDouble();
    } else if (hasPulse && bytes.length >= 8) {
      // Without timestamp, pulse is at bytes 7-8
      pulseRate = (bytes[7] | (bytes[8] << 8)).toDouble();
    }

    return {
      'systolic': double.parse(systolic.toStringAsFixed(1)),
      'diastolic': double.parse(diastolic.toStringAsFixed(1)),
      if (pulseRate != null) 'heart_rate': double.parse(pulseRate.toStringAsFixed(1)),
    };
  }

  /// Parses Bluetooth SIG / IEEE-11073 Pulse Oximeter characteristic (0x2A5F).
  /// Returns (SpO2, HeartRate)
  static Map<String, double> parsePulseOximeter(List<int> bytes) {
    if (bytes.length < 4) {
      throw const FormatException('Invalid Pulse Oximeter GATT payload length');
    }

    // Standard layout:
    // byte 0: flags
    // byte 1-2: SpO2 SFLOAT (or byte 1 uint8)
    // byte 3-4: Pulse Rate SFLOAT
    double spo2;
    double pulseRate;

    if (bytes.length == 4) {
      // Simplified consumer pulse oximeter format
      spo2 = bytes[1].toDouble();
      pulseRate = bytes[2].toDouble();
    } else {
      // IEEE-11073 16-bit SFLOAT format
      final rawSpo2 = bytes[1] | (bytes[2] << 8);
      spo2 = _decodeSFloat(rawSpo2);
      final rawPulse = bytes[3] | (bytes[4] << 8);
      pulseRate = _decodeSFloat(rawPulse);
    }

    return {
      'spo2': double.parse(spo2.toStringAsFixed(1)),
      'heart_rate': double.parse(pulseRate.toStringAsFixed(1)),
    };
  }

  /// Parses Bluetooth SIG Health Thermometer characteristic (0x2A1C).
  /// Returns temperature in °C
  static double parseThermometer(List<int> bytes) {
    if (bytes.length < 5) {
      throw const FormatException('Invalid Thermometer GATT payload length');
    }

    final flags = bytes[0];
    final isFahrenheit = (flags & 0x01) != 0;

    // Bytes 1-4: IEEE-11073 32-bit FLOAT
    final rawTemp = bytes[1] | (bytes[2] << 8) | (bytes[3] << 16) | (bytes[4] << 24);
    double celsius = _decodeFloat32(rawTemp);

    if (isFahrenheit) {
      // Convert Fahrenheit to Celsius: (°F - 32) * 5/9
      celsius = (celsius - 32.0) * (5.0 / 9.0);
    }

    return double.parse(celsius.toStringAsFixed(1));
  }

  /// Parses Bluetooth SIG Glucose Measurement characteristic (0x2A18).
  /// Returns glucose concentration in mg/dL
  static double parseGlucose(List<int> bytes) {
    if (bytes.length < 12) {
      throw const FormatException('Invalid Glucose GATT payload length');
    }

    final flags = bytes[0];
    final isMmol = (flags & 0x04) != 0;

    // Bytes 10-11: SFLOAT concentration
    final rawConcentration = bytes[10] | (bytes[11] << 8);
    double value = _decodeSFloat(rawConcentration);

    if (isMmol) {
      // Convert mol/L to mg/dL: 1 mmol/L ~ 18.0182 mg/dL
      value = value * 1000.0 * 18.0182;
    } else {
      // kg/L to mg/dL: 1 kg/L = 100,000 mg/dL
      value = value * 100000.0;
    }

    return double.parse(value.toStringAsFixed(1));
  }

  /// Parses Bluetooth SIG Weight Scale characteristic (0x2A9D).
  /// Returns weight in kg
  static double parseWeight(List<int> bytes) {
    if (bytes.length < 3) {
      throw const FormatException('Invalid Weight GATT payload length');
    }

    final flags = bytes[0];
    final isLbs = (flags & 0x01) != 0;

    // Bytes 1-2: UINT16 weight with resolution 0.005 kg or 0.01 lbs
    final rawWeight = bytes[1] | (bytes[2] << 8);
    double kg = isLbs ? (rawWeight * 0.01) * 0.45359237 : rawWeight * 0.005;

    return double.parse(kg.toStringAsFixed(2));
  }

  // ── 3. Record Measurement & Provenance Tagging ───────────────────────────────

  /// Creates a tagged physiological measurement record, enforcing physiological plausibility
  /// bounds checking and patient/worker attribution (Requirements 28.1, 28.3, 28.4, 28.7).
  static DeviceMeasurementRecord createMeasurementRecord({
    required DeviceProfileConfig profile,
    required double value,
    double? secondaryValue,
    String? deviceId,
    String? deviceName,
    required String patientId,
    required String authenticatedWorkerId,
    bool isManual = false,
  }) {
    final now = DateTime.now();
    final sourceTag = isManual || deviceId == null ? 'MANUAL' : 'BLE:$deviceId';
    final isPlausible = profile.isPlausible(value, secondaryValue);
    final warning = isPlausible ? null : profile.getValidationWarning(value, secondaryValue);

    return DeviceMeasurementRecord(
      id: _uuid.v4(),
      deviceId: isManual ? null : deviceId,
      deviceName: isManual ? 'Manual Entry' : (deviceName ?? profile.deviceName),
      measurementType: profile.measurementType,
      value: value,
      secondaryValue: secondaryValue,
      unit: profile.unit,
      measurementTimestamp: now,
      sourceTag: sourceTag,
      patientId: patientId, // Associated with active patient (Req 28.7)
      authenticatedWorkerId: authenticatedWorkerId, // Authenticated ASHA (Req 28.7)
      isPlausible: isPlausible,
      validationWarning: warning,
    );
  }

  // ── Helpers for IEEE-11073 Number Decoding ──────────────────────────────────

  static double _decodeSFloat(int raw) {
    int mantissa = raw & 0x0FFF;
    if ((mantissa & 0x0800) != 0) {
      mantissa = -((0x0FFF + 1) - mantissa);
    }
    int exponent = (raw >> 12) & 0x0F;
    if ((exponent & 0x08) != 0) {
      exponent = -((0x0F + 1) - exponent);
    }
    var mult = 1.0;
    if (exponent > 0) {
      for (var i = 0; i < exponent; i++) {
        mult *= 10.0;
      }
    } else if (exponent < 0) {
      for (var i = 0; i < -exponent; i++) {
        mult /= 10.0;
      }
    }
    return mantissa * mult;
  }

  static double _decodeFloat32(int raw) {
    int mantissa = raw & 0x00FFFFFF;
    if ((mantissa & 0x00800000) != 0) {
      mantissa = -((0x00FFFFFF + 1) - mantissa);
    }
    int exponent = (raw >> 24) & 0xFF;
    if ((exponent & 0x80) != 0) {
      exponent = -((0xFF + 1) - exponent);
    }
    var mult = 1.0;
    if (exponent > 0) {
      for (var i = 0; i < exponent; i++) {
        mult *= 10.0;
      }
    } else if (exponent < 0) {
      for (var i = 0; i < -exponent; i++) {
        mult /= 10.0;
      }
    }
    return mantissa * mult;
  }
}
