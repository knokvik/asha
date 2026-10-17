import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart' hide TriageResult;
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/features/clinical_programs/hbyc/data/hbyc_repository.dart';
import 'package:asha_platform/features/clinical_programs/hbyc/domain/hbyc_models.dart';
import 'package:asha_platform/features/clinical_programs/hbyc/domain/hbyc_storyboards.dart';

void main() {
  group('Task 9.2: Home Based Care for Young Child (HBYC) Tests (Requirements 13.1 – 13.5)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late HbycRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      repo = HbycRepository(db, syncEngine);

      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed Household and Child members to satisfy foreign key constraints
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_hbyc_1',
              village: 'Shivpur',
              headName: 'Ramesh Sharma',
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'child_aarav_1',
              householdId: 'hh_hbyc_1',
              name: 'Aarav Sharma',
              sex: 'M',
              relationshipToHead: const Value('Son'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. Schedule Generation (Requirement 13.1) ───────────────────────────
    test('Schedule Generation: Generates 5 visits at 3, 6, 9, 12, and 15 months with ±15 day windows', () async {
      final dob = DateTime(2025, 1, 1);
      final schedules = await repo.generateSchedule(childId: 'child_aarav_1', dob: dob);

      expect(schedules.length, equals(5));

      const dayMs = 24 * 60 * 60 * 1000;
      final expectedAges = [90, 180, 270, 365, 455];

      for (int i = 0; i < schedules.length; i++) {
        final schedule = schedules[i];
        final expectedDueMs = dob.millisecondsSinceEpoch + (expectedAges[i] * dayMs);

        expect(schedule.memberId, equals('child_aarav_1'));
        expect(schedule.programCode, equals('hbyc'));
        expect(schedule.dueDate, equals(expectedDueMs));
        expect(schedule.status, equals('pending'));

        // Window margins: ±15 days
        expect(schedule.dueWindowStart, equals(expectedDueMs - (15 * dayMs)));
        expect(schedule.dueWindowEnd, equals(expectedDueMs + (15 * dayMs)));
      }

      // Verify sync queue enqueued 5 metadata items
      final queueItems = await (db.select(db.syncQueue)
            ..where((t) => t.targetTable.equals('visit_schedules') & t.recordId.like('hbyc_child_aarav_1_%')))
          .get();
      expect(queueItems.length, equals(5));
      expect(queueItems.every((q) => q.priority == 3), isTrue); // SyncPriority.metadata
    });

    // ── 2. Checklist Execution & Observation Recording (Requirement 13.2) ──
    test('Checklist Recording: Inserts discrete observations and completes visit schedule', () async {
      final dob = DateTime(2025, 1, 1);
      final schedules = await repo.generateSchedule(childId: 'child_aarav_1', dob: dob);
      final schedule6m = schedules.firstWhere((s) => s.id.contains('m6'));

      final checklist = HbycChecklistData(
        milestone: HbycMilestone.month6,
        feedingPractice: FeedingPractice.complementaryWithBf,
        complementaryFeedingStarted: true,
        mealsPerDay: 2,
        foodGroupsCount: 4,
        washedHandsBeforeFeeding: true,
        immunizationUpToDate: true,
        growth: const HbycGrowthData(
          weightKg: 7.2,
          lengthCm: 65.0,
          muacCm: 13.5, // Normal MUAC >= 12.5 cm
          hasBilateralOedema: false,
          hasSevereWasting: false,
          appetiteTestPassed: true,
        ),
        milestoneAchievements: {
          'm6_roll_over': true,
          'm6_sit_supported': true,
          'm6_transfer_objects': true,
          'm6_babbles': true,
          'm6_responds_name': true,
        },
        illness: const HbycIllnessInterval(
          hadDiarrhoea: false,
          hadCoughFastBreathing: false,
          hadFever: false,
        ),
        responsiveCaregivingCounseled: true,
        hygieneWashCounseled: true,
        storyboardShown: true,
        audioMessagePlayed: true,
        generalNotes: 'Baby thriving, started mashed khichdi',
      );

      final result = await repo.recordVisit(
        childId: 'child_aarav_1',
        visitScheduleId: schedule6m.id,
        checklist: checklist,
        ashaId: 'asha_01',
      );

      // Verify result status
      expect(result.isRedFlag, isFalse);
      expect(result.isSam, isFalse);
      expect(result.isMam, isFalse);
      expect(result.hasMilestoneDelay, isFalse);
      expect(result.incentiveEligible, isTrue);

      // Verify ClinicalEncounter created in DB
      final encounter = await (db.select(db.clinicalEncounters)
            ..where((t) => t.id.equals(result.encounterId)))
          .getSingle();
      expect(encounter.encounterType, equals('HBYC'));
      expect(encounter.programCode, equals('hbyc'));
      expect(encounter.status, equals('completed'));
      expect(encounter.visitNotes, equals('Baby thriving, started mashed khichdi'));

      // Verify discrete ClinicalObservations created
      final observations = await (db.select(db.clinicalObservations)
            ..where((t) => t.encounterId.equals(result.encounterId)))
          .get();
      expect(observations.any((o) => o.observationCode == 'WEIGHT' && o.valueNumeric == 7.2), isTrue);
      expect(observations.any((o) => o.observationCode == 'LENGTH' && o.valueNumeric == 65.0), isTrue);
      expect(observations.any((o) => o.observationCode == 'MUAC' && o.valueNumeric == 13.5), isTrue);
      expect(observations.any((o) => o.observationCode == 'FEEDING_PRACTICE' && o.valueEnum == 'comp_with_bf'), isTrue);
      expect(observations.any((o) => o.observationCode == 'IMMUNIZATION_STATUS' && o.valueEnum == 'UP_TO_DATE'), isTrue);
      expect(observations.any((o) => o.observationCode == 'BILATERAL_OEDEMA' && o.valueEnum == 'NO'), isTrue);
      expect(observations.any((o) => o.observationCode == 'DEVELOPMENTAL_MILESTONES' && o.valueEnum == 'NORMAL_DEVELOPMENT'), isTrue);
      expect(observations.any((o) => o.observationCode == 'RESPONSIVE_CAREGIVING_COUNSELING'), isTrue);

      // Verify VisitSchedule marked as completed
      final updatedSchedule = await (db.select(db.visitSchedules)
            ..where((t) => t.id.equals(schedule6m.id)))
          .getSingle();
      expect(updatedSchedule.status, equals('completed'));
      expect(updatedSchedule.completedEncounterId, equals(result.encounterId));

      // Verify IncentiveEvent was recorded
      final incentive = await (db.select(db.incentiveEvents)
            ..where((t) => t.encounterId.equals(result.encounterId)))
          .getSingle();
      expect(incentive.activityCode, equals('HBYC_VISIT'));
      expect(incentive.status, equals('eligible'));
    });

    // ── 3. Delayed Milestone Detection & RBSK Referral (Requirement 13.3) ───
    test('Delayed Milestones: Identifies missed milestones and pre-populates RBSK/DEIC referral note', () async {
      final dob = DateTime(2025, 1, 1);
      final schedules = await repo.generateSchedule(childId: 'child_aarav_1', dob: dob);
      final schedule9m = schedules.firstWhere((s) => s.id.contains('m9'));

      // 9 months milestone assessment where sitting unsupported and pincer grasp are delayed
      final checklist = HbycChecklistData(
        milestone: HbycMilestone.month9,
        feedingPractice: FeedingPractice.complementaryWithBf,
        immunizationUpToDate: true,
        growth: const HbycGrowthData(weightKg: 8.0, lengthCm: 70.0, muacCm: 13.0),
        milestoneAchievements: {
          'm9_sit_unsupported': false, // Delayed!
          'm9_crawls_stands_support': true,
          'm9_immature_pincer': false, // Delayed!
          'm9_peekaboo_bye': true,
        },
        illness: const HbycIllnessInterval(),
      );

      final result = await repo.recordVisit(
        childId: 'child_aarav_1',
        visitScheduleId: schedule9m.id,
        checklist: checklist,
        ashaId: 'asha_01',
      );

      expect(result.hasMilestoneDelay, isTrue);
      expect(result.delayedMilestoneNames.length, equals(2));
      expect(result.delayedMilestoneNames.any((d) => d.contains('Sits steadily without any support')), isTrue);
      expect(result.delayedMilestoneNames.any((d) => d.contains('immature pincer') || d.contains('small pieces')), isTrue);
      expect(result.suggestedReferralDestination, contains('RBSK / District Early Intervention Centre (DEIC)'));
      expect(result.prePopulatedReferralReason, contains('Developmental delay observed at 9 Months HBYC assessment'));

      // Triage result should be YELLOW
      expect(result.triageResult, isNotNull);
      expect(result.triageResult!.flag, equals(TriageFlag.yellow));
      expect(result.triageResult!.findings.first.action, equals('REFER_TO_RBSK_DEIC'));
    });

    // ── 4. SAM Detection by Low MUAC (< 11.5 cm) (Requirement 13.4) ─────────
    test('SAM Detection by MUAC: MUAC < 11.5 cm auto-triggers nutrition pathway and RED referral to NRC', () async {
      final dob = DateTime(2025, 1, 1);
      final schedules = await repo.generateSchedule(childId: 'child_aarav_1', dob: dob);
      final schedule6m = schedules.firstWhere((s) => s.id.contains('m6'));

      // 6-month child with severe wasting: MUAC 10.8 cm (< 11.5 cm)
      final checklist = HbycChecklistData(
        milestone: HbycMilestone.month6,
        feedingPractice: FeedingPractice.animalMilkOnly,
        immunizationUpToDate: false,
        missingVaccinesNotes: 'Missed Penta-3 dose',
        growth: const HbycGrowthData(
          weightKg: 5.1,
          lengthCm: 62.0,
          muacCm: 10.8, // SAM threshold < 11.5 cm
          hasBilateralOedema: false,
          hasSevereWasting: true,
          appetiteTestPassed: false,
        ),
        milestoneAchievements: {
          'm6_roll_over': true,
          'm6_sit_supported': false,
          'm6_transfer_objects': false,
          'm6_babbles': true,
          'm6_responds_name': true,
        },
        illness: const HbycIllnessInterval(),
      );

      final result = await repo.recordVisit(
        childId: 'child_aarav_1',
        visitScheduleId: schedule6m.id,
        checklist: checklist,
        ashaId: 'asha_01',
      );

      expect(result.isSam, isTrue);
      expect(result.isRedFlag, isTrue);
      expect(result.suggestedReferralDestination, contains('Nutritional Rehabilitation Centre (NRC)'));
      expect(result.prePopulatedReferralReason, contains('MUAC 10.8 cm (< 11.5 cm threshold)'));
      expect(result.prePopulatedReferralReason, contains('Appetite test failed'));

      // Verify RED TriageResult persisted in DB
      final triageRecords = await (db.select(db.triageResults)
            ..where((t) => t.encounterId.equals(result.encounterId)))
          .get();
      expect(triageRecords.length, equals(1));
      expect(triageRecords.first.flag, equals('RED'));
      expect(triageRecords.first.findingsJson, contains('REFER_TO_NRC_IMMEDIATELY'));

      // Critical priority sync queue entry
      final syncItem = await (db.select(db.syncQueue)
            ..where((t) => t.targetTable.equals('clinical_encounters') & t.recordId.equals(result.encounterId)))
          .getSingle();
      expect(syncItem.priority, equals(1)); // SyncPriority.critical for RED flag
    });

    // ── 5. SAM Detection by Bilateral Oedema (Requirement 13.4) ─────────────
    test('SAM Detection by Oedema: Bilateral pitting oedema flags SAM and immediate NRC referral', () async {
      final dob = DateTime(2025, 1, 1);
      final schedules = await repo.generateSchedule(childId: 'child_aarav_1', dob: dob);
      final schedule12m = schedules.firstWhere((s) => s.id.contains('m12'));

      final checklist = HbycChecklistData(
        milestone: HbycMilestone.month12,
        feedingPractice: FeedingPractice.complementaryWithBf,
        immunizationUpToDate: true,
        growth: const HbycGrowthData(
          weightKg: 8.5,
          muacCm: 12.8,
          hasBilateralOedema: true, // Kwashiorkor bilateral pitting oedema!
        ),
        milestoneAchievements: {
          'm12_stands_alone': true,
          'm12_neat_pincer': true,
          'm12_meaningful_words': true,
          'm12_simple_commands': true,
        },
        illness: const HbycIllnessInterval(),
      );

      final result = await repo.recordVisit(
        childId: 'child_aarav_1',
        visitScheduleId: schedule12m.id,
        checklist: checklist,
        ashaId: 'asha_01',
      );

      expect(result.isSam, isTrue);
      expect(result.isRedFlag, isTrue);
      expect(result.suggestedReferralDestination, contains('Nutritional Rehabilitation Centre'));
      expect(result.prePopulatedReferralReason, contains('Bilateral pitting oedema'));
    });

    // ── 6. Caregiver Counselling Storyboard Catalog (Requirement 13.5) ──────
    test('Storyboards & Audio: Catalog covers all 5 milestones with Hindi and English audio scripts', () {
      for (final milestone in HbycMilestone.values) {
        final card = HbycStoryboardsCatalog.forMilestone(milestone);
        expect(card.milestone, equals(milestone));
        expect(card.title.isNotEmpty, isTrue);
        expect(card.titleHi.isNotEmpty, isTrue);
        expect(card.bulletTips.isNotEmpty, isTrue);
        expect(card.bulletTipsHi.isNotEmpty, isTrue);
        expect(card.audioScriptEn.isNotEmpty, isTrue);
        expect(card.audioScriptHi.isNotEmpty, isTrue);
      }
    });

    // ── 7. Missed Visit Rescheduling & Escalation (Requirement 13.1, 24.3) ──
    test('Missed Visit Handling: Reschedules overdue visit within grace window; alerts AF on repeat lapse', () async {
      final dob = DateTime(2025, 1, 1);
      final schedules = await repo.generateSchedule(childId: 'child_aarav_1', dob: dob);
      final target = schedules.first;

      // Simulate visit due window passed in the past
      final pastDueWindow = DateTime.now().millisecondsSinceEpoch - 1000;
      await (db.update(db.visitSchedules)..where((t) => t.id.equals(target.id))).write(
        VisitSchedulesCompanion(dueWindowEnd: Value(pastDueWindow)),
      );

      // First check: marks overdue and reschedules +14 days
      final escalated1 = await repo.checkAndRescheduleMissedVisits('child_aarav_1');
      expect(escalated1.isEmpty, isTrue); // Not escalated on 1st lapse

      final rescheduled1 = await (db.select(db.visitSchedules)..where((t) => t.id.equals(target.id))).getSingle();
      expect(rescheduled1.status, equals('overdue'));
      expect(rescheduled1.rescheduledCount, equals(1));
      expect(rescheduled1.dueWindowEnd! > pastDueWindow, isTrue);

      // Simulate rescheduled window also expired
      await (db.update(db.visitSchedules)..where((t) => t.id.equals(target.id))).write(
        VisitSchedulesCompanion(dueWindowEnd: Value(pastDueWindow)),
      );

      // Second check: repeated lapse -> escalates alert for ASHA Facilitator (AF)
      final escalated2 = await repo.checkAndRescheduleMissedVisits('child_aarav_1');
      expect(escalated2, contains(target.id));

      final rescheduled2 = await (db.select(db.visitSchedules)..where((t) => t.id.equals(target.id))).getSingle();
      expect(rescheduled2.rescheduledCount, equals(2));

      // Verify critical alert enqueued in sync queue
      final alerts = await (db.select(db.syncQueue)
            ..where((t) => t.targetTable.equals('alerts') & t.recordId.equals('alert_missed_${target.id}')))
          .get();
      expect(alerts.isNotEmpty, isTrue);
      expect(alerts.first.priority, equals(1)); // Critical priority for supervisor alert
    });

    // ── 8. Episode Completion Incentive (Requirement 13.1, 54.1) ─────────────
    test('Episode Completion: Completing all 5 HBYC visits triggers HBYC_COMPLETE incentive', () async {
      final dob = DateTime(2025, 1, 1);
      final schedules = await repo.generateSchedule(childId: 'child_aarav_1', dob: dob);

      // Complete all 5 visits sequentially
      for (int i = 0; i < schedules.length; i++) {
        final schedule = schedules[i];
        final milestone = HbycMilestone.values[i];

        final checklist = HbycChecklistData(
          milestone: milestone,
          feedingPractice: FeedingPractice.complementaryWithBf,
          immunizationUpToDate: true,
          growth: const HbycGrowthData(weightKg: 8.0, lengthCm: 70.0, muacCm: 13.0),
          milestoneAchievements: {
            for (final item in HbycMilestonesCatalog.forMilestone(milestone)) item.id: true,
          },
          illness: const HbycIllnessInterval(),
        );

        final result = await repo.recordVisit(
          childId: 'child_aarav_1',
          visitScheduleId: schedule.id,
          checklist: checklist,
          ashaId: 'asha_01',
        );

        expect(result.incentiveEligible, isTrue);
      }

      // Check final incentive event activityCode
      final allIncentives = await (db.select(db.incentiveEvents)
            ..where((t) => t.memberId.equals('child_aarav_1')))
          .get();
      expect(allIncentives.length, equals(5));

      // The final visit completion records HBYC_COMPLETE
      final finalIncentive = allIncentives.last;
      expect(finalIncentive.activityCode, equals('HBYC_COMPLETE'));
      expect(finalIncentive.status, equals('eligible'));
    });
  });
}
