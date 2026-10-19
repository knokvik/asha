/// Standard physiological measurement types supported by MoHFW field kits (Requirement 28.1, 28.5).
enum MeasurementType {
  bloodPressure('bp', 'Blood Pressure (Systolic / Diastolic)', 'mmHg'),
  pulseOximetry('spo2', 'Oxygen Saturation (SpO₂)', '%'),
  heartRate('heart_rate', 'Pulse / Heart Rate', 'bpm'),
  temperature('temperature', 'Body Temperature', '°C'),
  bloodGlucose('glucose', 'Blood Glucose', 'mg/dL'),
  hemoglobin('hemoglobin', 'Haemoglobin (Hb)', 'g/dL'),
  weight('weight', 'Body Weight', 'kg');

  final String code;
  final String label;
  final String defaultUnit;
  const MeasurementType(this.code, this.label, this.defaultUnit);

  static MeasurementType fromCode(String? code) {
    if (code == null) return MeasurementType.bloodPressure;
    return MeasurementType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => MeasurementType.bloodPressure,
    );
  }
}

/// Plausible physiological validation bounds configuration (Requirements 28.3, 28.5).
class DeviceProfileConfig {
  final String id;
  final String deviceName;
  final String? bleServiceUuid;
  final String? bleCharacteristicUuid;
  final MeasurementType measurementType;
  final String unit;
  final double minPlausible;
  final double maxPlausible;
  final double? secondaryMinPlausible; // e.g. diastolic minimum
  final double? secondaryMaxPlausible; // e.g. diastolic maximum
  final Map<String, dynamic>? unitConversion;
  final bool isActive;

  const DeviceProfileConfig({
    required this.id,
    required this.deviceName,
    this.bleServiceUuid,
    this.bleCharacteristicUuid,
    required this.measurementType,
    required this.unit,
    required this.minPlausible,
    required this.maxPlausible,
    this.secondaryMinPlausible,
    this.secondaryMaxPlausible,
    this.unitConversion,
    this.isActive = true,
  });

  /// Evaluates whether a measurement value is within plausible physiological bounds (Requirement 28.3).
  bool isPlausible(double value, [double? secondaryValue]) {
    if (value < minPlausible || value > maxPlausible) {
      return false;
    }
    if (secondaryValue != null &&
        secondaryMinPlausible != null &&
        secondaryMaxPlausible != null) {
      if (secondaryValue < secondaryMinPlausible! ||
          secondaryValue > secondaryMaxPlausible!) {
        return false;
      }
    }
    return true;
  }

  /// Returns user-friendly validation warning message for out-of-bounds readings.
  String? getValidationWarning(double value, [double? secondaryValue]) {
    if (value < minPlausible || value > maxPlausible) {
      return '$value $unit is outside plausible physiological bounds ($minPlausible – $maxPlausible $unit). Please remeasure before saving.';
    }
    if (secondaryValue != null &&
        secondaryMinPlausible != null &&
        secondaryMaxPlausible != null) {
      if (secondaryValue < secondaryMinPlausible! ||
          secondaryValue > secondaryMaxPlausible!) {
        return 'Secondary reading $secondaryValue is outside plausible bounds ($secondaryMinPlausible – $secondaryMaxPlausible). Please remeasure.';
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_name': deviceName,
        'ble_service_uuid': bleServiceUuid,
        'ble_characteristic_uuid': bleCharacteristicUuid,
        'measurement_type': measurementType.code,
        'unit': unit,
        'min_plausible': minPlausible,
        'max_plausible': maxPlausible,
        'secondary_min_plausible': secondaryMinPlausible,
        'secondary_max_plausible': secondaryMaxPlausible,
        'unit_conversion': unitConversion,
        'is_active': isActive,
      };

  factory DeviceProfileConfig.fromJson(Map<String, dynamic> json) => DeviceProfileConfig(
        id: json['id'] as String,
        deviceName: json['device_name'] as String,
        bleServiceUuid: json['ble_service_uuid'] as String?,
        bleCharacteristicUuid: json['ble_characteristic_uuid'] as String?,
        measurementType: MeasurementType.fromCode(json['measurement_type'] as String?),
        unit: json['unit'] as String,
        minPlausible: (json['min_plausible'] as num).toDouble(),
        maxPlausible: (json['max_plausible'] as num).toDouble(),
        secondaryMinPlausible: (json['secondary_min_plausible'] as num?)?.toDouble(),
        secondaryMaxPlausible: (json['secondary_max_plausible'] as num?)?.toDouble(),
        unitConversion: json['unit_conversion'] as Map<String, dynamic>?,
        isActive: json['is_active'] as bool? ?? true,
      );
}

/// Recorded physiological measurement tagged with provenance, user, and patient identity (Requirements 28.1, 28.4, 28.7).
class DeviceMeasurementRecord {
  final String id;
  final String? deviceId;
  final String? deviceName;
  final MeasurementType measurementType;
  final double value;
  final double? secondaryValue;
  final String unit;
  final DateTime measurementTimestamp;
  final String sourceTag; // 'BLE:<device_id>' or 'MANUAL'
  final String patientId; // associated with active patient (Req 28.7)
  final String authenticatedWorkerId; // authenticated ASHA (Req 28.7)
  final bool isPlausible;
  final String? validationWarning;

  const DeviceMeasurementRecord({
    required this.id,
    this.deviceId,
    this.deviceName,
    required this.measurementType,
    required this.value,
    this.secondaryValue,
    required this.unit,
    required this.measurementTimestamp,
    required this.sourceTag,
    required this.patientId,
    required this.authenticatedWorkerId,
    required this.isPlausible,
    this.validationWarning,
  });

  bool get isManual => sourceTag == 'MANUAL';
  bool get isBle => sourceTag.startsWith('BLE:');

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'device_name': deviceName,
        'measurement_type': measurementType.code,
        'value': value,
        'secondary_value': secondaryValue,
        'unit': unit,
        'measurement_timestamp': measurementTimestamp.toIso8601String(),
        'source_tag': sourceTag,
        'patient_id': patientId,
        'worker_id': authenticatedWorkerId,
        'is_plausible': isPlausible,
        'validation_warning': validationWarning,
      };

  factory DeviceMeasurementRecord.fromJson(Map<String, dynamic> json) => DeviceMeasurementRecord(
        id: json['id'] as String,
        deviceId: json['device_id'] as String?,
        deviceName: json['device_name'] as String?,
        measurementType: MeasurementType.fromCode(json['measurement_type'] as String?),
        value: (json['value'] as num).toDouble(),
        secondaryValue: (json['secondary_value'] as num?)?.toDouble(),
        unit: json['unit'] as String,
        measurementTimestamp: DateTime.parse(json['measurement_timestamp'] as String),
        sourceTag: json['source_tag'] as String,
        patientId: json['patient_id'] as String,
        authenticatedWorkerId: json['worker_id'] as String,
        isPlausible: json['is_plausible'] as bool,
        validationWarning: json['validation_warning'] as String?,
      );
}

/// Discovered BLE peripheral device descriptor
class DiscoveredBleDevice {
  final String id;
  final String name;
  final int rssi;
  final List<String> serviceUuids;

  const DiscoveredBleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.serviceUuids = const [],
  });
}
