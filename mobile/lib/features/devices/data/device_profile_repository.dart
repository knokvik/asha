import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/ble_models.dart';

/// Repository managing medical device profiles, physiological validation bounds,
/// dynamic profile additions, and measurement persistence in drift tables (Requirements 28.3, 28.4, 28.5).
class DeviceProfileRepository {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;
  static const _uuid = Uuid();

  DeviceProfileRepository(this._db, [this._syncEngine]);

  // ── 1. Default Profile Seeding (Requirement 28.5) ───────────────────────────

  /// Seeds standard MoHFW field device profiles into the `device_profiles` table.
  Future<void> seedDefaultDeviceProfiles() async {
    final existing = await (_db.select(_db.deviceProfiles)).get();
    if (existing.isNotEmpty) return;

    final defaultProfiles = [
      DeviceProfileConfig(
        id: 'prof_pulse_ox',
        deviceName: 'Standard Pulse Oximeter',
        bleServiceUuid: '00001822-0000-1000-8000-00805f9b34fb', // Pulse Oximeter Service
        bleCharacteristicUuid: '00002a5f-0000-1000-8000-00805f9b34fb', // PLX Continuous Measurement
        measurementType: MeasurementType.pulseOximetry,
        unit: '%',
        minPlausible: 70.0,
        maxPlausible: 100.0,
        secondaryMinPlausible: 30.0, // Heart Rate min
        secondaryMaxPlausible: 240.0, // Heart Rate max
      ),
      DeviceProfileConfig(
        id: 'prof_bp_monitor',
        deviceName: 'Digital Blood Pressure Monitor',
        bleServiceUuid: '00001810-0000-1000-8000-00805f9b34fb', // Blood Pressure Service
        bleCharacteristicUuid: '00002a35-0000-1000-8000-00805f9b34fb', // BP Measurement
        measurementType: MeasurementType.bloodPressure,
        unit: 'mmHg',
        minPlausible: 60.0, // Systolic min
        maxPlausible: 260.0, // Systolic max
        secondaryMinPlausible: 40.0, // Diastolic min
        secondaryMaxPlausible: 150.0, // Diastolic max
      ),
      DeviceProfileConfig(
        id: 'prof_thermometer',
        deviceName: 'Digital Clinical Thermometer',
        bleServiceUuid: '00001809-0000-1000-8000-00805f9b34fb', // Health Thermometer Service
        bleCharacteristicUuid: '00002a1c-0000-1000-8000-00805f9b34fb', // Temperature Measurement
        measurementType: MeasurementType.temperature,
        unit: '°C',
        minPlausible: 32.0,
        maxPlausible: 43.0,
      ),
      DeviceProfileConfig(
        id: 'prof_glucometer',
        deviceName: 'Digital Blood Glucose Meter',
        bleServiceUuid: '00001808-0000-1000-8000-00805f9b34fb', // Glucose Service
        bleCharacteristicUuid: '00002a18-0000-1000-8000-00805f9b34fb', // Glucose Measurement
        measurementType: MeasurementType.bloodGlucose,
        unit: 'mg/dL',
        minPlausible: 20.0,
        maxPlausible: 600.0,
      ),
      DeviceProfileConfig(
        id: 'prof_hemoglobin',
        deviceName: 'Point-of-Care Haemoglobinometer',
        bleServiceUuid: null, // Custom vendor profile
        bleCharacteristicUuid: null,
        measurementType: MeasurementType.hemoglobin,
        unit: 'g/dL',
        minPlausible: 2.0,
        maxPlausible: 25.0,
      ),
      DeviceProfileConfig(
        id: 'prof_weighing_scale',
        deviceName: 'Digital Adult & Infant Scale',
        bleServiceUuid: '0000181d-0000-1000-8000-00805f9b34fb', // Weight Scale Service
        bleCharacteristicUuid: '00002a9d-0000-1000-8000-00805f9b34fb', // Weight Measurement
        measurementType: MeasurementType.weight,
        unit: 'kg',
        minPlausible: 0.5,
        maxPlausible: 200.0,
      ),
    ];

    for (final p in defaultProfiles) {
      await registerNewDeviceProfile(p);
    }
  }

  // ── 2. Dynamic Profile Registration (Requirement 28.5) ──────────────────────

  /// Adds or updates a device profile configuration without requiring any application code change.
  Future<void> registerNewDeviceProfile(DeviceProfileConfig config) async {
    final conversionJson = config.unitConversion != null ? jsonEncode(config.unitConversion) : null;

    await _db.into(_db.deviceProfiles).insertOnConflictUpdate(
          DeviceProfilesCompanion.insert(
            id: config.id,
            deviceName: config.deviceName,
            bleServiceUuid: Value(config.bleServiceUuid),
            bleCharacteristicUuid: Value(config.bleCharacteristicUuid),
            measurementType: config.measurementType.code,
            unit: config.unit,
            minPlausible: config.minPlausible,
            maxPlausible: config.maxPlausible,
            unitConversionJson: Value(conversionJson),
            isActive: Value(config.isActive),
          ),
        );
  }

  /// Retrieves all active device profiles from the SQLite database.
  Future<List<DeviceProfileConfig>> getAllActiveProfiles() async {
    final rows = await (_db.select(_db.deviceProfiles)..where((p) => p.isActive.equals(true))).get();

    return rows.map((r) {
      final conv = r.unitConversionJson != null ? jsonDecode(r.unitConversionJson!) as Map<String, dynamic>? : null;
      return DeviceProfileConfig(
        id: r.id,
        deviceName: r.deviceName,
        bleServiceUuid: r.bleServiceUuid,
        bleCharacteristicUuid: r.bleCharacteristicUuid,
        measurementType: MeasurementType.fromCode(r.measurementType),
        unit: r.unit,
        minPlausible: r.minPlausible,
        maxPlausible: r.maxPlausible,
        unitConversion: conv,
        isActive: r.isActive,
      );
    }).toList();
  }

  /// Fetches profile matching a measurement type.
  Future<DeviceProfileConfig?> getProfileForType(MeasurementType type) async {
    final row = await (_db.select(_db.deviceProfiles)
          ..where((p) => p.measurementType.equals(type.code) & p.isActive.equals(true)))
        .getSingleOrNull();

    if (row == null) return null;

    final conv = row.unitConversionJson != null ? jsonDecode(row.unitConversionJson!) as Map<String, dynamic>? : null;
    return DeviceProfileConfig(
      id: row.id,
      deviceName: row.deviceName,
      bleServiceUuid: row.bleServiceUuid,
      bleCharacteristicUuid: row.bleCharacteristicUuid,
      measurementType: MeasurementType.fromCode(row.measurementType),
      unit: row.unit,
      minPlausible: row.minPlausible,
      maxPlausible: row.maxPlausible,
      unitConversion: conv,
      isActive: row.isActive,
    );
  }

  // ── 3. Save Measurement to Clinical Observations (Requirements 28.3, 28.4) ───

  /// Saves a verified physiological measurement into `clinical_observations` tagged with its provenance.
  /// Throws [ArgumentError] if the measurement is implausible (Requirement 28.3).
  Future<String> saveObservationRecord({
    required String encounterId,
    required DeviceMeasurementRecord record,
  }) async {
    if (!record.isPlausible) {
      throw ArgumentError(
        'Cannot save implausible physiological reading without user remeasure confirmation: ${record.validationWarning}',
      );
    }

    final obsId = _uuid.v4();
    final nowMs = record.measurementTimestamp.millisecondsSinceEpoch;

    // Save primary measurement (e.g. systolic BP, SpO2, temp)
    await _db.into(_db.clinicalObservations).insert(
          ClinicalObservationsCompanion.insert(
            id: obsId,
            encounterId: encounterId,
            observationCode: record.measurementType.code,
            valueNumeric: Value(record.value),
            valueUnit: Value(record.unit),
            source: Value(record.sourceTag), // 'BLE:<device_id>' or 'MANUAL' (Req 28.4)
            observedAt: nowMs,
          ),
        );

    // Save secondary measurement if present (e.g. diastolic BP)
    if (record.secondaryValue != null) {
      final secondaryCode = record.measurementType == MeasurementType.bloodPressure ? 'bp_diastolic' : 'heart_rate';
      final secondaryUnit = record.measurementType == MeasurementType.bloodPressure ? 'mmHg' : 'bpm';

      await _db.into(_db.clinicalObservations).insert(
            ClinicalObservationsCompanion.insert(
              id: _uuid.v4(),
              encounterId: encounterId,
              observationCode: secondaryCode,
              valueNumeric: Value(record.secondaryValue),
              valueUnit: Value(secondaryUnit),
              source: Value(record.sourceTag),
              observedAt: nowMs,
            ),
          );
    }

    // Enqueue to sync queue
    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'clinical_observations',
        recordId: obsId,
        operation: 'insert',
        priority: SyncPriority.clinical,
        payload: record.toJson(),
      );
    }

    return obsId;
  }
}
