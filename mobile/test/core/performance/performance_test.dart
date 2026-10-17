import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/performance/device_profile_service.dart';

void main() {
  late DeviceProfileService profileService;
  late AppDatabase db;

  setUp(() {
    profileService = DeviceProfileService();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Task 15.7: Performance, Low-Power & Hardware Constraints (Requirements 48.2, 48.6, 48.7)', () {
    test('48.6: Automatically activates reduced-feature mode for low-memory phones (<1.5 GB RAM)', () {
      const lowEndSpecs = DeviceHardwareSpecs(
        ramMegabytes: 1024, // 1 GB RAM
        androidApiLevel: 26, // Android 8.0 Oreo
      );

      final config = profileService.evaluateHardwareConstraints(lowEndSpecs);
      expect(config.isEnabled, isTrue);
      expect(config.disableVoiceAsrModel, isTrue);
      expect(config.useSimplifiedTriage, isTrue);
      expect(config.statusNotice, contains('Offline voice model disabled'));
    });

    test('48.6: Activates standard full-featured mode on reference device (2 GB RAM, Android 9+)', () {
      const standardSpecs = DeviceHardwareSpecs(
        ramMegabytes: 2048, // 2 GB RAM
        androidApiLevel: 28, // Android 9 Pie
      );

      final config = profileService.evaluateHardwareConstraints(standardSpecs);
      expect(config.isEnabled, isFalse);
      expect(config.disableVoiceAsrModel, isFalse);
    });

    test('48.7: Low-power mode enables dark theme, reduces animations, defers sync to Wi-Fi', () {
      expect(profileService.lowPowerConfig.isEnabled, isFalse);

      profileService.setLowPowerMode(true);
      expect(profileService.lowPowerConfig.isEnabled, isTrue);
      expect(profileService.lowPowerConfig.enableDarkTheme, isTrue);
      expect(profileService.lowPowerConfig.disableAnimations, isTrue);
      expect(profileService.lowPowerConfig.deferSyncToWifiOnly, isTrue);
      expect(profileService.lowPowerConfig.disableNonEssentialBackgroundTasks, isTrue);

      profileService.setLowPowerMode(false);
      expect(profileService.lowPowerConfig.isEnabled, isFalse);
    });

    test('48.2: Execution timing asserts triage and critical database queries execute < 1000 ms', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed sample records
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_perf_1',
              village: 'Rampur',
              headName: 'Ramesh',
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'mem_perf_1',
              householdId: 'hh_perf_1',
              name: 'Pooja',
              sex: 'F',
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      final elapsedMs = await profileService.profileExecutionTime(() async {
        // Benchmark query on primary indexed entity
        final members = await (db.select(db.members)..where((t) => t.householdId.equals('hh_perf_1'))).get();
        expect(members.length, 1);
      });

      // Benchmark assertion: Must execute well under 1000 ms SLA
      expect(elapsedMs, lessThan(1000));
    });
  });
}
