import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/features/devices/data/ble_service.dart';
import 'package:asha_platform/features/devices/data/device_profile_repository.dart';
import 'package:asha_platform/features/devices/domain/ble_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 12.4: BLE Device Integration & Physiological Bounds (Requirements 28.1 – 28.7)', () {
    // ── 1. Physiological Bounds Validation (Requirement 28.3, 28.5) ───────────
    group('DeviceProfileConfig Plausibility Bounds', () {
      const spo2Profile = DeviceProfileConfig(
        id: 'prof_test_spo2',
        deviceName: 'Test Pulse Oximeter',
        measurementType: MeasurementType.pulseOximetry,
        unit: '%',
        minPlausible: 70.0,
        maxPlausible: 100.0,
        secondaryMinPlausible: 30.0, // HR min
        secondaryMaxPlausible: 240.0, // HR max
      );

      const bpProfile = DeviceProfileConfig(
        id: 'prof_test_bp',
        deviceName: 'Test BP Monitor',
        measurementType: MeasurementType.bloodPressure,
        unit: 'mmHg',
        minPlausible: 60.0, // Systolic
        maxPlausible: 260.0,
        secondaryMinPlausible: 40.0, // Diastolic
        secondaryMaxPlausible: 150.0,
      );

      test('accepts readings within physiological bounds', () {
        expect(spo2Profile.isPlausible(98.0, 72.0), isTrue);
        expect(spo2Profile.getValidationWarning(98.0, 72.0), isNull);

        expect(bpProfile.isPlausible(120.0, 80.0), isTrue);
        expect(bpProfile.getValidationWarning(120.0, 80.0), isNull);
      });

      test('rejects implausible readings and formats warning (Requirement 28.3)', () {
        // SpO2 reading of 65% (below 70%) or 105% (above 100%)
        expect(spo2Profile.isPlausible(65.0), isFalse);
        expect(spo2Profile.isPlausible(105.0), isFalse);
        final warningSpo2 = spo2Profile.getValidationWarning(65.0);
        expect(warningSpo2, contains('outside plausible physiological bounds'));
        expect(warningSpo2, contains('70.0 – 100.0 %'));

        // BP Systolic of 45 mmHg (below 60)
        expect(bpProfile.isPlausible(45.0, 80.0), isFalse);
        // BP Diastolic of 165 mmHg (above 150)
        expect(bpProfile.isPlausible(130.0, 165.0), isFalse);
      });

      test('supports dynamic profile creation from configuration JSON (Requirement 28.5)', () {
        final configJson = {
          'id': 'prof_smart_stethoscope',
          'device_name': 'Smart Digital Stethoscope',
          'ble_service_uuid': '0000180d-0000-1000-8000-00805f9b34fb',
          'ble_characteristic_uuid': '00002a37-0000-1000-8000-00805f9b34fb',
          'measurement_type': 'heart_rate',
          'unit': 'bpm',
          'min_plausible': 30.0,
          'max_plausible': 220.0,
          'is_active': true,
        };

        final newProfile = DeviceProfileConfig.fromJson(configJson);
        expect(newProfile.id, equals('prof_smart_stethoscope'));
        expect(newProfile.measurementType, equals(MeasurementType.heartRate));
        expect(newProfile.isPlausible(78.0), isTrue);
        expect(newProfile.isPlausible(250.0), isFalse);
      });
    });

    // ── 2. Standard Bluetooth SIG GATT Parsers ─────────────────────────────────
    group('BleService GATT Payload Decoders', () {
      test('decodes Blood Pressure GATT characteristic (0x2A35)', () {
        // 0x00 flags: mmHg, no timestamp, with pulse
        // Systolic: 120 (0x0078 -> 120, 0)
        // Diastolic: 80 (0x0050 -> 80, 0)
        // MAP: 93 (0x005D -> 93, 0)
        // Pulse: 72 (0x0048 -> 72, 0)
        final payloadMmHg = [
          0x04, // flags: bit 2 set = pulse rate present, bit 0 clear = mmHg
          120, 0, // Systolic 120
          80, 0, // Diastolic 80
          93, 0, // MAP 93
          72, 0, // Pulse 72
        ];

        final result = BleService.parseBloodPressure(payloadMmHg);
        expect(result['systolic'], equals(120.0));
        expect(result['diastolic'], equals(80.0));
        expect(result['heart_rate'], equals(72.0));
      });

      test('decodes Pulse Oximeter GATT payload', () {
        // Simplified consumer format: byte 0 flags, byte 1 SpO2, byte 2 Pulse
        final payload = [0x00, 98, 75, 0x00];
        final result = BleService.parsePulseOximeter(payload);

        expect(result['spo2'], equals(98.0));
        expect(result['heart_rate'], equals(75.0));
      });

      test('decodes Health Thermometer GATT characteristic (0x2A1C)', () {
        // Flags: 0x00 = Celsius
        // Mantissa 368 with exponent -1 = 36.8 °C
        // 368 = 0x000170 -> byte1 = 0x70, byte2 = 0x01, byte3 = 0x00, byte4 (exponent -1 = 0xFF)
        final payloadCelsius = [0x00, 0x70, 0x01, 0x00, 0xFF];
        final temp = BleService.parseThermometer(payloadCelsius);

        expect(temp, equals(36.8));
      });

      test('decodes Weight Scale GATT characteristic (0x2A9D)', () {
        // Flags: 0x00 = kg with 0.005 kg resolution
        // 60 kg = 60 / 0.005 = 12000 units = 0x2EE0
        // byte 1 = 0xE0, byte 2 = 0x2E
        final payloadWeight = [0x00, 0xE0, 0x2E];
        final weight = BleService.parseWeight(payloadWeight);

        expect(weight, equals(60.0));
      });
    });

    // ── 3. Provenance Tagging & Patient/Worker Attribution (Req 28.4, 28.7) ────
    group('Measurement Provenance & Attribution', () {
      const bpProfile = DeviceProfileConfig(
        id: 'prof_bp',
        deviceName: 'Omron Hem-7120',
        measurementType: MeasurementType.bloodPressure,
        unit: 'mmHg',
        minPlausible: 60.0,
        maxPlausible: 260.0,
        secondaryMinPlausible: 40.0,
        secondaryMaxPlausible: 150.0,
      );

      test('tags BLE hardware measurement and attributes to active patient (Req 28.4, 28.7)', () {
        final record = BleService.createMeasurementRecord(
          profile: bpProfile,
          value: 125.0,
          secondaryValue: 82.0,
          deviceId: 'OMRON_BLE_8821',
          deviceName: 'Omron Hem-7120',
          patientId: 'patient_sunita_01',
          authenticatedWorkerId: 'asha_rekha_01',
          isManual: false,
        );

        expect(record.sourceTag, equals('BLE:OMRON_BLE_8821'));
        expect(record.isBle, isTrue);
        expect(record.isManual, isFalse);
        // Must associate with active patient and worker, not shared device owner (Req 28.7)
        expect(record.patientId, equals('patient_sunita_01'));
        expect(record.authenticatedWorkerId, equals('asha_rekha_01'));
        expect(record.isPlausible, isTrue);
      });

      test('tags manual fallback measurement seamlessly (Req 28.2, 28.4)', () {
        final record = BleService.createMeasurementRecord(
          profile: bpProfile,
          value: 118.0,
          secondaryValue: 78.0,
          patientId: 'patient_sunita_01',
          authenticatedWorkerId: 'asha_rekha_01',
          isManual: true,
        );

        expect(record.sourceTag, equals('MANUAL'));
        expect(record.isManual, isTrue);
        expect(record.isBle, isFalse);
        expect(record.deviceId, isNull);
        expect(record.patientId, equals('patient_sunita_01'));
      });
    });

    // ── 4. Device Profile Repository & Observations Persistence ──────────────
    group('DeviceProfileRepository & Observations (Req 28.3 – 28.5)', () {
      late AppDatabase db;
      late SyncEngine syncEngine;
      late DeviceProfileRepository repository;

      setUp(() async {
        db = AppDatabase.forTesting(NativeDatabase.memory());
        syncEngine = SyncEngine(db);
        repository = DeviceProfileRepository(db, syncEngine);

        final nowMs = DateTime.now().millisecondsSinceEpoch;

        // Seed Household
        await db.into(db.households).insert(
              HouseholdsCompanion.insert(
                id: 'hh_test',
                village: 'Devpur',
                headName: 'Kavita Head',
                createdAt: nowMs,
                updatedAt: nowMs,
                createdBy: 'asha_01',
              ),
            );

        // Seed Member and Encounter
        await db.into(db.members).insert(
              MembersCompanion.insert(
                id: 'm_obs_test',
                householdId: 'hh_test',
                name: 'Kavita',
                sex: 'F',
                createdAt: nowMs,
                updatedAt: nowMs,
                createdBy: 'asha_01',
              ),
            );

        await db.into(db.clinicalEncounters).insert(
              ClinicalEncountersCompanion.insert(
                id: 'enc_obs_test',
                memberId: 'm_obs_test',
                encounterType: 'routine_visit',
                programCode: 'ncd',
                encounterDate: nowMs,
                ashaId: 'asha_01',
                createdAt: nowMs,
                updatedAt: nowMs,
              ),
            );
      });

      tearDown(() async {
        await db.close();
      });

      test('seeds default field device profiles', () async {
        await repository.seedDefaultDeviceProfiles();

        final profiles = await repository.getAllActiveProfiles();
        expect(profiles.length, greaterThanOrEqualTo(6));

        final types = profiles.map((p) => p.measurementType).toList();
        expect(types, contains(MeasurementType.pulseOximetry));
        expect(types, contains(MeasurementType.bloodPressure));
        expect(types, contains(MeasurementType.temperature));
        expect(types, contains(MeasurementType.bloodGlucose));
        expect(types, contains(MeasurementType.hemoglobin));
        expect(types, contains(MeasurementType.weight));
      });

      test('saves measurement into clinical observations tagged with BLE source (Req 28.4)', () async {
        await repository.seedDefaultDeviceProfiles();
        final bpProfile = (await repository.getProfileForType(MeasurementType.bloodPressure))!;

        final validRecord = BleService.createMeasurementRecord(
          profile: bpProfile,
          value: 130.0,
          secondaryValue: 85.0,
          deviceId: 'BLE_BP_001',
          patientId: 'm_obs_test',
          authenticatedWorkerId: 'asha_01',
        );

        final obsId = await repository.saveObservationRecord(
          encounterId: 'enc_obs_test',
          record: validRecord,
        );

        expect(obsId, isNotEmpty);

        // Verify observations created in SQLite
        final observations = await (db.select(db.clinicalObservations)
              ..where((o) => o.encounterId.equals('enc_obs_test')))
            .get();

        expect(observations.length, equals(2)); // Systolic + Diastolic
        final systolic = observations.firstWhere((o) => o.observationCode == 'bp');
        expect(systolic.valueNumeric, equals(130.0));
        expect(systolic.source, equals('BLE:BLE_BP_001')); // Provenance tag

        final diastolic = observations.firstWhere((o) => o.observationCode == 'bp_diastolic');
        expect(diastolic.valueNumeric, equals(85.0));
        expect(diastolic.source, equals('BLE:BLE_BP_001'));

        // Verify sync queue item was created
        final syncItems = await db.select(db.syncQueue).get();
        expect(syncItems.any((i) => i.targetTable == 'clinical_observations'), isTrue);
      });

      test('strictly refuses to auto-save implausible out-of-range readings (Requirement 28.3)', () async {
        await repository.seedDefaultDeviceProfiles();
        final bpProfile = (await repository.getProfileForType(MeasurementType.bloodPressure))!;

        // Implausible Systolic BP of 320 mmHg (above 260)
        final implausibleRecord = BleService.createMeasurementRecord(
          profile: bpProfile,
          value: 320.0,
          secondaryValue: 90.0,
          deviceId: 'BLE_BP_001',
          patientId: 'm_obs_test',
          authenticatedWorkerId: 'asha_01',
        );

        expect(implausibleRecord.isPlausible, isFalse);

        // Must throw ArgumentError rather than silently persisting bad data
        expect(
          () => repository.saveObservationRecord(
            encounterId: 'enc_obs_test',
            record: implausibleRecord,
          ),
          throwsArgumentError,
        );
      });
    });
  });
}
