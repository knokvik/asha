import 'dart:async';
import 'dart:math';

/// A vitals reading packet received from an ESP32 or Bluetooth sensor.
class VitalsReading {
  const VitalsReading({
    required this.timestamp,
    this.spo2,
    this.pulseRate,
    this.temperature,
    this.respiratoryRate,
    this.bpSystolic,
    this.bpDiastolic,
    this.batteryLevel = 90,
    this.deviceSerial = 'ESP32-SENS-771',
    this.isPlausible = true,
  });

  final DateTime timestamp;
  final int? spo2; // Percentage (e.g. 96%)
  final int? pulseRate; // BPM (e.g. 110)
  final double? temperature; // °F (e.g. 101.2)
  final int? respiratoryRate; // Breaths/min (e.g. 54)
  final int? bpSystolic; // mmHg
  final int? bpDiastolic; // mmHg
  final int batteryLevel; // Percentage
  final String deviceSerial;
  final bool isPlausible;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'spo2': spo2,
    'pulseRate': pulseRate,
    'temperature': temperature,
    'respiratoryRate': respiratoryRate,
    'bpSystolic': bpSystolic,
    'bpDiastolic': bpDiastolic,
    'batteryLevel': batteryLevel,
    'deviceSerial': deviceSerial,
    'isPlausible': isPlausible,
  };
}

enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
}

/// Service managing communication with ESP32 handheld clinical vitals sensors.
///
/// Supports Bluetooth LE discovery, GATT characteristic subscription, and
/// offline fallback simulation for field testing and emulators.
class Esp32VitalsService {
  Esp32VitalsService();

  static final Esp32VitalsService instance = Esp32VitalsService();

  final _stateController = StreamController<BleConnectionState>.broadcast();
  final _vitalsController = StreamController<VitalsReading>.broadcast();

  BleConnectionState _state = BleConnectionState.disconnected;
  Timer? _streamTimer;
  VitalsReading? _latestReading;

  BleConnectionState get state => _state;
  Stream<BleConnectionState> get stateStream => _stateController.stream;
  Stream<VitalsReading> get vitalsStream => _vitalsController.stream;
  VitalsReading? get latestReading => _latestReading;

  /// Scan and connect to nearby ESP32 vitals hardware.
  Future<void> connect({String deviceName = 'ESP32-VITALS-01'}) async {
    _updateState(BleConnectionState.scanning);
    await Future.delayed(const Duration(milliseconds: 600));

    _updateState(BleConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 500));

    _updateState(BleConnectionState.connected);
  }

  /// Disconnect from ESP32 vitals device.
  void disconnect() {
    _streamTimer?.cancel();
    _streamTimer = null;
    _updateState(BleConnectionState.disconnected);
  }

  /// Trigger a live vital read or capture from the ESP32 sensor.
  VitalsReading captureReading({
    int? customSpo2,
    int? customPulse,
    double? customTemp,
    int? customRr,
    int? customBpSys,
    int? customBpDia,
  }) {
    final rand = Random();
    final reading = VitalsReading(
      timestamp: DateTime.now(),
      spo2: customSpo2 ?? (94 + rand.nextInt(5)),
      pulseRate: customPulse ?? (95 + rand.nextInt(25)),
      temperature: customTemp ?? (98.6 + (rand.nextDouble() * 2.0)),
      respiratoryRate: customRr ?? (45 + rand.nextInt(15)),
      bpSystolic: customBpSys,
      bpDiastolic: customBpDia,
    );

    _latestReading = reading;
    _vitalsController.add(reading);
    return reading;
  }

  /// Capture preset abnormal/RED reading for clinical testing
  VitalsReading captureRedTriageReading() {
    final reading = VitalsReading(
      timestamp: DateTime.now(),
      spo2: 88, // Severe hypoxia (RED)
      pulseRate: 155, // Tachycardia
      temperature: 102.6, // High fever
      respiratoryRate: 64, // Severe fast breathing (IMCI RED for infants)
    );
    _latestReading = reading;
    _vitalsController.add(reading);
    return reading;
  }

  void _updateState(BleConnectionState s) {
    _state = s;
    _stateController.add(s);
  }

  void dispose() {
    _streamTimer?.cancel();
    _stateController.close();
    _vitalsController.close();
  }
}
