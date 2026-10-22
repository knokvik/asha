import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/features/due_list/data/hamlet_repository.dart';
import 'package:asha_platform/features/due_list/domain/due_list_models.dart';
import 'package:asha_platform/features/due_list/domain/route_models.dart';
import 'package:asha_platform/features/due_list/domain/route_planner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  group('Task 12.2: Route Planning, Offline Maps & Hamlet Accessibility (Requirements 25.1 – 25.5)', () {
    // ── 1. GeoCoordinate & Haversine Distance ────────────────────────────────
    group('GeoCoordinate', () {
      test('computes accurate Haversine distance in kilometers', () {
        // Point A: Devpur Center (25.3176, 82.9739)
        // Point B: North Tola (~1.1 km North)
        const p1 = GeoCoordinate(latitude: 25.3176, longitude: 82.9739);
        const p2 = GeoCoordinate(latitude: 25.3276, longitude: 82.9739);

        final dist = p1.distanceTo(p2);
        // 0.01 deg latitude ~ 1.11 km
        expect(dist, greaterThan(1.05));
        expect(dist, lessThan(1.20));

        // Distance to self is 0
        expect(p1.distanceTo(p1), equals(0.0));
      });

      test('supports JSON serialization and deserialization', () {
        const coord = GeoCoordinate(latitude: 26.8467, longitude: 80.9462);
        final json = coord.toJson();
        final restored = GeoCoordinate.fromJson(json);

        expect(restored.latitude, equals(26.8467));
        expect(restored.longitude, equals(80.9462));
        expect(restored, equals(coord));
      });
    });

    // ── 2. Route Planner Algorithm & Privacy Guarantees ──────────────────────
    group('RoutePlanner', () {
      // Setup mock hamlets with coordinates
      // North Tola: (25.3200, 82.9700)
      // East Purwa: (25.3180, 82.9850)
      // South Basti: (25.3050, 82.9720)
      // Remote Ghati: (25.3400, 82.9900)
      final hamletCoords = {
        'North Tola': const GeoCoordinate(latitude: 25.3200, longitude: 82.9700),
        'East Purwa': const GeoCoordinate(latitude: 25.3180, longitude: 82.9850),
        'South Basti': const GeoCoordinate(latitude: 25.3050, longitude: 82.9720),
        'Remote Ghati': const GeoCoordinate(latitude: 25.3400, longitude: 82.9900),
      };

      final baseTime = DateTime(2025, 5, 10, 9, 0);

      final taskNorthRoutine = DueTask(
        id: 't_north_1',
        memberId: 'm_1',
        memberName: 'Pooja Devi',
        sex: 'F',
        householdId: 'hh_1',
        village: 'Devpur',
        hamlet: 'North Tola',
        programCode: 'anc',
        visitType: 'ANC Checkup 2',
        dueDate: baseTime,
        status: 'pending',
        urgencyGroup: UrgencyGroup.dueToday,
        clinicalRiskLevel: 1.0,
        daysUntilWindowExpiry: 3.0,
        urgencyScore: 1.0 / 3.0,
        prioritisationReason: 'ANC due today',
      );

      final taskSouthEmergency = DueTask(
        id: 't_south_emergency',
        memberId: 'm_2',
        memberName: 'Sunita Devi',
        sex: 'F',
        householdId: 'hh_2',
        village: 'Devpur',
        hamlet: 'South Basti',
        programCode: 'anc',
        visitType: 'Severe Preeclampsia Followup',
        dueDate: baseTime,
        status: 'pending',
        urgencyGroup: UrgencyGroup.redFollowUp,
        clinicalRiskLevel: 3.0,
        daysUntilWindowExpiry: 0.5,
        urgencyScore: 6.0,
        prioritisationReason: 'RED alert high-risk pregnancy',
        hasRedAlert: true,
      );

      final taskEastOverdue = DueTask(
        id: 't_east_1',
        memberId: 'm_3',
        memberName: 'Rohan Kumar',
        sex: 'M',
        householdId: 'hh_3',
        village: 'Devpur',
        hamlet: 'East Purwa',
        programCode: 'immunization',
        visitType: 'Pentavalent 1',
        dueDate: baseTime.subtract(const Duration(days: 2)),
        status: 'overdue',
        urgencyGroup: UrgencyGroup.overdue,
        clinicalRiskLevel: 1.5,
        daysUntilWindowExpiry: 0.0,
        urgencyScore: 10.0,
        prioritisationReason: 'Overdue vaccination',
      );

      test('handles empty task list gracefully', () {
        final route = RoutePlanner.planRoute(tasks: []);
        expect(route.orderedWaypoints, isEmpty);
        expect(route.totalStops, equals(0));
        expect(route.totalEstimatedDistanceKm, equals(0.0));
        expect(route.estimatedWalkingDuration, equals(Duration.zero));
      });

      test('enforces GPS opt-in privacy guarantee (Requirement 25.2)', () {
        // ASHA is physically standing right at North Tola
        const ashaGps = GeoCoordinate(latitude: 25.3200, longitude: 82.9700);

        // Case A: gpsOptIn == false -> ASHA position MUST NOT be used!
        // Router should prioritize clinical urgency (South Basti has RED emergency)
        final routeWithoutGps = RoutePlanner.planRoute(
          tasks: [taskNorthRoutine, taskSouthEmergency, taskEastOverdue],
          hamletCoordinates: hamletCoords,
          ashaLocation: ashaGps,
          gpsOptIn: false,
        );

        expect(routeWithoutGps.isOptInGpsUsed, isFalse);
        expect(routeWithoutGps.startLocation, isNull);
        // Initial stop is South Basti because of RED emergency follow-up
        expect(routeWithoutGps.orderedWaypoints.first.hamlet, equals('South Basti'));

        // Case B: gpsOptIn == true -> ASHA position is used to minimize walking from current location
        final routeWithGps = RoutePlanner.planRoute(
          tasks: [taskNorthRoutine, taskSouthEmergency, taskEastOverdue],
          hamletCoordinates: hamletCoords,
          ashaLocation: ashaGps,
          gpsOptIn: true,
        );

        expect(routeWithGps.isOptInGpsUsed, isTrue);
        expect(routeWithGps.startLocation, equals(ashaGps));
        // First stop is North Tola because ASHA is physically standing there (dist = 0)
        expect(routeWithGps.orderedWaypoints.first.hamlet, equals('North Tola'));
      });

      test('batches multiple tasks within the same hamlet in clinical priority order (Req 25.1)', () {
        final taskNorthSecond = DueTask(
          id: 't_north_2',
          memberId: 'm_4',
          memberName: 'Meena',
          sex: 'F',
          householdId: 'hh_4',
          village: 'Devpur',
          hamlet: 'North Tola',
          programCode: 'hbnc',
          visitType: 'HBNC Day 3',
          dueDate: baseTime,
          status: 'pending',
          urgencyGroup: UrgencyGroup.dueToday,
          clinicalRiskLevel: 2.0,
          daysUntilWindowExpiry: 1.0,
          urgencyScore: 2.0,
          prioritisationReason: 'HBNC Newborn Visit',
        );

        final route = RoutePlanner.planRoute(
          tasks: [taskNorthRoutine, taskNorthSecond, taskEastOverdue],
          hamletCoordinates: hamletCoords,
        );

        final northWaypoint = route.orderedWaypoints.firstWhere((w) => w.hamlet == 'North Tola');
        expect(northWaypoint.totalVisits, equals(2));
        // Higher urgency task (HBNC urgency score 2.0 vs 0.33) should be ordered first
        expect(northWaypoint.tasks.first.id, equals('t_north_2'));
        expect(northWaypoint.tasks.last.id, equals('t_north_1'));
      });

      test('excludes seasonally/physically blocked hamlets and computes distance (Req 25.4)', () {
        final taskRemote = DueTask(
          id: 't_remote_1',
          memberId: 'm_5',
          memberName: 'Kavita',
          sex: 'F',
          householdId: 'hh_5',
          village: 'Devpur',
          hamlet: 'Remote Ghati',
          programCode: 'ncd',
          visitType: 'CBAC Assessment',
          dueDate: baseTime,
          status: 'pending',
          urgencyGroup: UrgencyGroup.dueToday,
          clinicalRiskLevel: 1.0,
          daysUntilWindowExpiry: 5.0,
          urgencyScore: 0.2,
          prioritisationReason: 'NCD screening',
        );

        final accessMap = {
          'Remote Ghati': HamletAccessibility(
            id: 'acc_block_1',
            village: 'Devpur',
            hamlet: 'Remote Ghati',
            isBlocked: true,
            reason: BarrierReason.landslide,
            notes: 'Monsoon landslide washed away bridge road',
            reportedAt: baseTime,
          ),
        };

        final route = RoutePlanner.planRoute(
          tasks: [taskNorthRoutine, taskEastOverdue, taskRemote],
          hamletCoordinates: hamletCoords,
          accessibilityMap: accessMap,
        );

        // Remote Ghati must be excluded from orderedWaypoints and placed in blockedWaypoints
        expect(route.orderedWaypoints.any((w) => w.hamlet == 'Remote Ghati'), isFalse);
        expect(route.blockedWaypoints.length, equals(1));
        expect(route.blockedWaypoints.first.hamlet, equals('Remote Ghati'));
        expect(route.blockedWaypoints.first.accessibility?.reason, equals(BarrierReason.landslide));

        // Distance and duration calculation
        expect(route.totalEstimatedDistanceKm, greaterThan(0.0));
        expect(route.estimatedWalkingDuration.inMinutes, greaterThan(20));
      });
    });

    // ── 3. Hamlet Repository, Auto-Rescheduling & Supervisor Coverage ────────
    group('HamletRepository & Coverage Analysis (Req 25.4, 25.5)', () {
      late AppDatabase db;
      late SyncEngine syncEngine;
      late HamletRepository repository;

      final now = DateTime(2025, 5, 10, 10, 0);
      final nowMs = now.millisecondsSinceEpoch;

      setUp(() async {
        db = AppDatabase.forTesting(NativeDatabase.memory());
        syncEngine = SyncEngine(db);
        repository = HamletRepository(db, syncEngine);

        // Seed Household in 'River Hamlet'
        await db.into(db.households).insert(
              HouseholdsCompanion.insert(
                id: 'hh_river_01',
                village: 'Devpur',
                hamlet: const Value('River Hamlet'),
                headName: 'Vikram Singh',
                createdAt: nowMs,
                updatedAt: nowMs,
                createdBy: 'asha_01',
              ),
            );

        // Seed Beneficiary
        await db.into(db.members).insert(
              MembersCompanion.insert(
                id: 'member_river_01',
                householdId: 'hh_river_01',
                name: 'Radha Devi',
                sex: 'F',
                createdAt: nowMs,
                updatedAt: nowMs,
                createdBy: 'asha_01',
              ),
            );

        // Seed Open Visit Schedule
        await db.into(db.visitSchedules).insert(
              VisitSchedulesCompanion.insert(
                id: 'sched_river_anc_1',
                memberId: 'member_river_01',
                programCode: 'anc',
                visitType: 'ANC Checkup 3',
                dueDate: nowMs,
                createdAt: nowMs,
              ),
            );
      });

      tearDown(() async {
        await db.close();
      });

      test('flags hamlet blocked and automatically reschedules open visits (Req 25.4)', () async {
        final blockedUntil = now.add(const Duration(days: 7));

        final access = await repository.flagHamletBlocked(
          village: 'Devpur',
          hamlet: 'River Hamlet',
          reason: BarrierReason.flood,
          notes: 'River bridge submerged by monsoon overflow',
          blockedUntil: blockedUntil,
        );

        expect(access.isBlocked, isTrue);
        expect(access.reason, equals(BarrierReason.flood));

        // Verify visit schedule in that hamlet was automatically deferred
        final schedules = await (db.select(db.visitSchedules)..where((s) => s.id.equals('sched_river_anc_1'))).get();
        expect(schedules.length, equals(1));
        final updatedSchedule = schedules.first;

        // Due date moved to blockedUntil + 1 day
        final expectedNewDueMs = blockedUntil.add(const Duration(days: 1)).millisecondsSinceEpoch;
        expect(updatedSchedule.dueDate, equals(expectedNewDueMs));
        expect(updatedSchedule.status, equals('rescheduled'));
        expect(updatedSchedule.skipReason, equals(SkipReason.weatherRoadIssue.code));
        expect(updatedSchedule.rescheduledCount, equals(1));

        // Verify sync queue item
        final syncItems = await db.select(db.syncQueue).get();
        expect(syncItems.any((i) => i.targetTable == 'hamlet_accessibility'), isTrue);
      });

      test('clears hamlet blockage and reflects in accessibility map', () async {
        await repository.flagHamletBlocked(
          village: 'Devpur',
          hamlet: 'River Hamlet',
          reason: BarrierReason.flood,
        );

        var map = await repository.getAccessibilityMap('Devpur');
        expect(map['River Hamlet']?.isBlocked, isTrue);

        await repository.clearHamletBlockage(village: 'Devpur', hamlet: 'River Hamlet');
        map = await repository.getAccessibilityMap('Devpur');
        expect(map['River Hamlet']?.isBlocked, isFalse);
      });

      test('enforces ASHA consent in supervisor coverage analysis (Requirement 25.5)', () async {
        // Without consent
        final reportWithoutConsent = await repository.generateCoverageAnalysis(
          village: 'Devpur',
          ashaConsentGiven: false,
        );

        expect(reportWithoutConsent.ashaConsentGiven, isFalse);
        expect(reportWithoutConsent.totalHamlets, equals(0));
        expect(reportWithoutConsent.hamletVisitFrequencies, isEmpty);
        expect(reportWithoutConsent.accessBarriersHistory.first, contains('Consent not granted'));

        // With consent
        final reportWithConsent = await repository.generateCoverageAnalysis(
          village: 'Devpur',
          ashaConsentGiven: true,
        );

        expect(reportWithConsent.ashaConsentGiven, isTrue);
        expect(reportWithConsent.totalHamlets, equals(1));
        expect(reportWithConsent.hamletVisitFrequencies['River Hamlet'], equals(1));
        expect(reportWithConsent.hamletCompletionRates['River Hamlet'], equals(0.0)); // 0 completed out of 1
      });
    });
  });
}
