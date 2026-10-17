import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/features/due_list/domain/due_list_models.dart';
import 'package:asha_platform/features/due_list/domain/task_scheduler.dart';

void main() {
  group('Task 9.5: Due List & Task Scheduler Tests (Requirements 24.1 – 24.7)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late TaskScheduler scheduler;

    final baseTime = DateTime(2025, 5, 10, 10, 0); // Reference: 10 May 2025
    final nowMs = baseTime.millisecondsSinceEpoch;
    const dayMs = 24 * 60 * 60 * 1000;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      scheduler = TaskScheduler(db, syncEngine);

      // Seed Household 1 in Hamlet 'North Tola'
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_north_1',
              village: 'Devpur',
              hamlet: const Value('North Tola'),
              headName: 'Suresh Kumar',
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_01',
            ),
          );

      // Seed Household 2 in Hamlet 'South Basti'
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_south_2',
              village: 'Devpur',
              hamlet: const Value('South Basti'),
              headName: 'Ramesh Singh',
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_01',
            ),
          );

      // Seed Beneficiaries
      // 1. Mother Anita (high risk pregnancy)
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'member_anita_1',
              householdId: 'hh_north_1',
              name: 'Anita Devi',
              sex: 'F',
              dobApprox: Value(baseTime.subtract(const Duration(days: 365 * 24)).millisecondsSinceEpoch),
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_01',
            ),
          );

      // 2. Child Rohan (Infant in North Tola)
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'member_rohan_2',
              householdId: 'hh_north_1',
              name: 'Rohan Kumar',
              sex: 'M',
              dobApprox: Value(baseTime.subtract(const Duration(days: 100)).millisecondsSinceEpoch),
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_01',
            ),
          );

      // 3. Mother Sunita (in South Basti)
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'member_sunita_3',
              householdId: 'hh_south_2',
              name: 'Sunita Singh',
              sex: 'F',
              dobApprox: Value(baseTime.subtract(const Duration(days: 365 * 22)).millisecondsSinceEpoch),
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_01',
            ),
          );

      // Seed Encounters and an unresolved RED referral for Sunita
      await db.into(db.clinicalEncounters).insert(
            ClinicalEncountersCompanion.insert(
              id: 'enc_sunita_red',
              memberId: 'member_sunita_3',
              encounterType: 'ANC_CONTACT',
              programCode: 'anc',
              encounterDate: nowMs - (dayMs * 1),
              ashaId: 'asha_01',
              createdAt: nowMs - (dayMs * 1),
              updatedAt: nowMs - (dayMs * 1),
            ),
          );

      await db.into(db.referralRecords).insert(
            ReferralRecordsCompanion.insert(
              id: 'ref_sunita_emergency',
              encounterId: 'enc_sunita_red',
              memberId: 'member_sunita_3',
              triageFlag: 'red',
              status: const Value('created'), // Unresolved RED referral
              createdAt: nowMs - (dayMs * 1),
              updatedAt: nowMs - (dayMs * 1),
            ),
          );

      // Seed VisitSchedules:
      // A) Sunita: ANC follow-up (has RED referral) -> UrgencyGroup.redFollowUp
      await db.into(db.visitSchedules).insert(
            VisitSchedulesCompanion.insert(
              id: 'task_sunita_red',
              memberId: 'member_sunita_3',
              programCode: 'anc',
              visitType: 'High-Risk ANC Emergency Follow-up',
              dueDate: nowMs,
              dueWindowStart: Value(nowMs - dayMs),
              dueWindowEnd: Value(nowMs + (dayMs * 1)),
              status: const Value('pending'),
              createdAt: nowMs,
            ),
          );

      // B) Anita: Overdue ANC contact (due 3 days ago) -> UrgencyGroup.overdue
      await db.into(db.visitSchedules).insert(
            VisitSchedulesCompanion.insert(
              id: 'task_anita_overdue',
              memberId: 'member_anita_1',
              programCode: 'anc',
              visitType: 'ANC Contact 3 (30 Weeks)',
              dueDate: nowMs - (dayMs * 3),
              dueWindowStart: Value(nowMs - (dayMs * 5)),
              dueWindowEnd: Value(nowMs - (dayMs * 1)),
              status: const Value('pending'),
              createdAt: nowMs - (dayMs * 10),
            ),
          );

      // C) Rohan: HBNC / HBYC visit due today -> UrgencyGroup.dueToday
      await db.into(db.visitSchedules).insert(
            VisitSchedulesCompanion.insert(
              id: 'task_rohan_today',
              memberId: 'member_rohan_2',
              programCode: 'hbyc',
              visitType: 'HBYC 3-Month Growth Check',
              dueDate: nowMs,
              dueWindowStart: Value(nowMs - dayMs),
              dueWindowEnd: Value(nowMs + (dayMs * 5)),
              status: const Value('pending'),
              createdAt: nowMs,
            ),
          );

      // D) Rohan: Upcoming Immunization visit (due in 5 days) -> UrgencyGroup.upcoming
      await db.into(db.visitSchedules).insert(
            VisitSchedulesCompanion.insert(
              id: 'task_rohan_upcoming',
              memberId: 'member_rohan_2',
              programCode: 'immunization',
              visitType: 'OPV-1 + Pentavalent-1 Dose',
              dueDate: nowMs + (dayMs * 5),
              dueWindowStart: Value(nowMs + (dayMs * 3)),
              dueWindowEnd: Value(nowMs + (dayMs * 10)),
              status: const Value('pending'),
              createdAt: nowMs,
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. Urgency Grouping & Ordering (Requirement 24.1) ─────────────────────
    test('Urgency Grouping: Tasks ordered RED follow-up -> Overdue -> Due today -> Upcoming', () async {
      final tasks = await scheduler.fetchDueTasks(referenceDate: baseTime);

      expect(tasks.length, equals(4));

      // Task 1: Sunita (Red follow-up)
      expect(tasks[0].id, equals('task_sunita_red'));
      expect(tasks[0].urgencyGroup, equals(UrgencyGroup.redFollowUp));
      expect(tasks[0].hasRedAlert, isTrue);

      // Task 2: Anita (Overdue)
      expect(tasks[1].id, equals('task_anita_overdue'));
      expect(tasks[1].urgencyGroup, equals(UrgencyGroup.overdue));

      // Task 3: Rohan (Due today)
      expect(tasks[2].id, equals('task_rohan_today'));
      expect(tasks[2].urgencyGroup, equals(UrgencyGroup.dueToday));

      // Task 4: Rohan (Upcoming)
      expect(tasks[3].id, equals('task_rohan_upcoming'));
      expect(tasks[3].urgencyGroup, equals(UrgencyGroup.upcoming));
    });

    test('Hamlet Grouping: Groups tasks by urgency group, then by hamlet (Requirement 24.1)', () async {
      final grouped = await scheduler.fetchGroupedDueList(referenceDate: baseTime);

      // RED follow-up in South Basti
      expect(grouped[UrgencyGroup.redFollowUp]!.containsKey('South Basti'), isTrue);
      expect(grouped[UrgencyGroup.redFollowUp]!['South Basti']!.length, equals(1));

      // Overdue in North Tola
      expect(grouped[UrgencyGroup.overdue]!.containsKey('North Tola'), isTrue);
      expect(grouped[UrgencyGroup.overdue]!['North Tola']!.length, equals(1));

      // Due today in North Tola
      expect(grouped[UrgencyGroup.dueToday]!.containsKey('North Tola'), isTrue);
      expect(grouped[UrgencyGroup.dueToday]!['North Tola']!.length, equals(1));

      // Upcoming in North Tola
      expect(grouped[UrgencyGroup.upcoming]!.containsKey('North Tola'), isTrue);
      expect(grouped[UrgencyGroup.upcoming]!['North Tola']!.length, equals(1));
    });

    // ── 2. Urgency Scoring Mathematical Formulation (Requirement 24.6) ────────
    test('Urgency Score Formula: urgency_score = clinical_risk_level * (1 / days_until_window_expiry)', () {
      // 1 day remaining, Standard risk (1.0) -> 1.0 * (1 / 1) = 1.0
      final score1 = DueTask.calculateUrgencyScore(
        clinicalRiskLevel: 1.0,
        daysUntilWindowExpiry: 1.0,
        hasRedAlert: false,
      );
      expect(score1, closeTo(1.0, 0.001));

      // 0.5 days remaining, High risk (3.0) -> 3.0 * (1 / 0.5) = 6.0
      final score2 = DueTask.calculateUrgencyScore(
        clinicalRiskLevel: 3.0,
        daysUntilWindowExpiry: 0.5,
        hasRedAlert: false,
      );
      expect(score2, closeTo(6.0, 0.001));

      // Active RED flag yields top priority multiplier (> 300)
      final scoreRed = DueTask.calculateUrgencyScore(
        clinicalRiskLevel: 3.0,
        daysUntilWindowExpiry: 1.0,
        hasRedAlert: true,
      );
      expect(scoreRed, greaterThan(300.0));

      // Overdue (negative days remaining) scales with lapsed days
      final scoreOverdue = DueTask.calculateUrgencyScore(
        clinicalRiskLevel: 2.0,
        daysUntilWindowExpiry: -2.0,
        hasRedAlert: false,
      );
      expect(scoreOverdue, equals(2.0 * (10.0 + 2.0))); // 24.0
    });

    // ── 3. Skip-Reason Capture & Rescheduling (Requirement 24.4) ───────────────
    test('Skip & Reschedule: captures skip reason and advances due date within protocol window', () async {
      final success = await scheduler.recordSkipAndReschedule(
        visitScheduleId: 'task_rohan_today',
        reason: SkipReason.notAtHome,
        notes: 'Mother at market, will be back tomorrow',
      );

      expect(success, isTrue);

      final updated = await (db.select(db.visitSchedules)
            ..where((t) => t.id.equals('task_rohan_today')))
          .getSingle();

      expect(updated.status, equals('pending'));
      expect(updated.rescheduledCount, equals(1));
      expect(updated.skipReason, contains('not at home'));
      expect(updated.skipReason, contains('Mother at market'));
      expect(updated.dueDate, greaterThan(nowMs)); // Rescheduled forward

      // Sync queue item created
      final syncItems = await (db.select(db.syncQueue)
            ..where((t) => t.recordId.equals('task_rohan_today')))
          .get();
      expect(syncItems.length, equals(1));
      expect(syncItems.first.operation, equals('update'));
    });

    test('Skip Permanent: permanently migrated marks task skipped without rescheduling', () async {
      final success = await scheduler.recordSkipAndReschedule(
        visitScheduleId: 'task_rohan_today',
        reason: SkipReason.permanentlyMigrated,
        notes: 'Family relocated to Delhi',
      );

      expect(success, isTrue);

      final updated = await (db.select(db.visitSchedules)
            ..where((t) => t.id.equals('task_rohan_today')))
          .getSingle();

      expect(updated.status, equals('skipped'));
      expect(updated.skipReason, contains('Permanently migrated'));
    });

    // ── 4. Task Completion (Requirement 24.3) ──────────────────────────────────
    test('Task Completion: removes task from active due list and marks completed', () async {
      await scheduler.completeTask(
        visitScheduleId: 'task_anita_overdue',
        encounterId: 'enc_completed_123',
      );

      final updated = await (db.select(db.visitSchedules)
            ..where((t) => t.id.equals('task_anita_overdue')))
          .getSingle();

      expect(updated.status, equals('completed'));
      expect(updated.completedEncounterId, equals('enc_completed_123'));
      expect(updated.completedAt, isNotNull);

      // Active due tasks query no longer contains anita's completed visit
      final activeTasks = await scheduler.fetchDueTasks(referenceDate: baseTime);
      expect(activeTasks.any((t) => t.id == 'task_anita_overdue'), isFalse);
    });

    // ── 5. Ad-Hoc Task Creation & Merging (Requirement 24.7) ───────────────────
    test('Ad-Hoc Task: creates unplanned visit and merges into due list at appropriate urgency', () async {
      final taskId = await scheduler.createAdHocTask(
        memberId: 'member_anita_1',
        title: 'Unplanned Fever & Blood Pressure Follow-up',
        dueDate: baseTime,
        clinicalRiskLevel: 2.0,
      );

      expect(taskId, startsWith('adhoc_'));

      // Check due list includes the ad-hoc visit in Due Today
      final tasks = await scheduler.fetchDueTasks(referenceDate: baseTime);
      final adhocTask = tasks.firstWhere((t) => t.id == taskId);

      expect(adhocTask.memberName, equals('Anita Devi'));
      expect(adhocTask.urgencyGroup, equals(UrgencyGroup.dueToday));
      expect(adhocTask.programCode, equals('ad_hoc'));
    });

    // ── 6. Workload Summary & Threshold Alert (Requirement 24.6) ───────────────
    test('Workload Summary: flags overloaded when day task count exceeds threshold', () async {
      // Current today tasks: 3 (Sunita RED + Anita Overdue + Rohan Due Today)
      final summaryNormal = await scheduler.fetchWorkloadSummary(
        referenceDate: baseTime,
        workloadThreshold: 5,
      );
      expect(summaryNormal.totalTasksToday, equals(3));
      expect(summaryNormal.isOverloaded, isFalse);

      // Low threshold (2) triggers overloaded state
      final summaryOverload = await scheduler.fetchWorkloadSummary(
        referenceDate: baseTime,
        workloadThreshold: 2,
      );
      expect(summaryOverload.isOverloaded, isTrue);
      expect(summaryOverload.excessTaskCount, equals(1));
    });

    // ── 7. Month Calendar & Programme Coverage (Requirement 24.5) ─────────────
    test('Calendar & Coverage: provides daily density distribution and programme completion metrics', () async {
      final dailyCounts = await scheduler.fetchMonthDailyCounts(year: 2025, month: 5);

      // 10 May 2025 has Sunita + Rohan visits
      expect(dailyCounts[10], greaterThanOrEqualTo(2));
      // 15 May 2025 has Rohan immunization visit
      expect(dailyCounts[15], equals(1));

      final coverage = await scheduler.fetchProgramCoverageSummary();
      expect(coverage.any((c) => c.programCode == 'anc'), isTrue);
      expect(coverage.any((c) => c.programCode == 'hbyc'), isTrue);
      expect(coverage.any((c) => c.programCode == 'immunization'), isTrue);
    });
  });
}
