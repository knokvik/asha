import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart' hide TriageResult;
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/features/clinical_programs/hbnc/data/hbnc_repository.dart';
import 'package:asha_platform/features/clinical_programs/hbnc/domain/hbnc_models.dart';
import 'package:asha_platform/features/clinical_programs/hbnc/domain/kmc_guidance.dart';

void main() {
  group('Task 9.1: Home Based Newborn Care (HBNC) Tests (Requirements 12.1 – 12.7)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late HbncRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      repo = HbncRepository(db, syncEngine);

      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed Household, Mother, and Infant members to satisfy FK constraints
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_hbnc_1',
              village: 'Rampur',
              headName: 'Sanjay Kumar',
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'mother_1',
              householdId: 'hh_hbnc_1',
              name: 'Meena Devi',
              sex: 'F',
              relationshipToHead: const Value('Wife'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'infant_normal_1',
              householdId: 'hh_hbnc_1',
              name: 'Baby of Meena',
              sex: 'M',
              relationshipToHead: const Value('Son'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'infant_lbw_1',
              householdId: 'hh_hbnc_1',
              name: 'Twin Baby (LBW)',
              sex: 'F',
              relationshipToHead: const Value('Daughter'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('Schedule Generation: Home delivery schedules Days 1, 3, 7, 14, 21, 28, 42 (Requirement 12.1)', () async {
      final delivery = HbncDeliveryRecord(
        newbornId: 'infant_normal_1',
        motherId: 'mother_1',
        householdId: 'hh_hbnc_1',
        deliveryDate: DateTime.now(),
        place: DeliveryPlace.home,
        birthWeightKg: 2.9,
        ashaId: 'asha_01',
      );

      final schedules = await repo.generateSchedule(delivery);
      expect(schedules.length, 7);

      final visitTypes = schedules.map((s) => s.visitType).toList();
      expect(visitTypes, contains('HBNC Day 1 Visit'));
      expect(visitTypes, contains('HBNC Day 3 Visit'));
      expect(visitTypes, contains('HBNC Day 7 Visit'));
      expect(visitTypes, contains('HBNC Day 14 Visit'));
      expect(visitTypes, contains('HBNC Day 21 Visit'));
      expect(visitTypes, contains('HBNC Day 28 Visit'));
      expect(visitTypes, contains('HBNC Day 42 Visit'));
    });

    test('Schedule Generation: Institutional delivery excludes Day 1 (Days 3, 7, 14, 21, 28, 42) (Requirement 12.1)', () async {
      final delivery = HbncDeliveryRecord(
        newbornId: 'infant_normal_1',
        motherId: 'mother_1',
        householdId: 'hh_hbnc_1',
        deliveryDate: DateTime.now(),
        place: DeliveryPlace.institutionalChc,
        facilityName: 'Gopalganj CHC',
        birthWeightKg: 3.1,
        ashaId: 'asha_01',
      );

      final schedules = await repo.generateSchedule(delivery);
      expect(schedules.length, 6);

      final visitTypes = schedules.map((s) => s.visitType).toList();
      expect(visitTypes, isNot(contains('HBNC Day 1 Visit')));
      expect(visitTypes, contains('HBNC Day 3 Visit'));
      expect(visitTypes, contains('HBNC Day 7 Visit'));
      expect(visitTypes, contains('HBNC Day 42 Visit'));
    });

    test('Schedule Generation: Low Birth Weight (< 2.5 kg) adds high-risk KMC visits (Requirement 12.4)', () async {
      final delivery = HbncDeliveryRecord(
        newbornId: 'infant_lbw_1',
        motherId: 'mother_1',
        householdId: 'hh_hbnc_1',
        deliveryDate: DateTime.now(),
        place: DeliveryPlace.institutionalPhc,
        birthWeightKg: 2.1, // LBW
        isPreterm: true,
        ashaId: 'asha_01',
      );

      expect(delivery.isLbw, isTrue);
      expect(delivery.isHighRisk, isTrue);

      final schedules = await repo.generateSchedule(delivery);
      // 6 standard (institutional) + 6 extra high risk KMC visits (Days 2, 5, 9, 11, 18, 25) = 12 total visits
      expect(schedules.length, 12);

      final visitTypes = schedules.map((s) => s.visitType).toList();
      expect(visitTypes.any((t) => t.contains('Day 2') && t.contains('High Risk KMC')), isTrue);
      expect(visitTypes.any((t) => t.contains('Day 5') && t.contains('High Risk KMC')), isTrue);
      expect(visitTypes.any((t) => t.contains('Day 9') && t.contains('High Risk KMC')), isTrue);
    });

    test('Visit Checklist Execution: records discrete observations and marks visit completed (Requirement 12.2)', () async {
      final delivery = HbncDeliveryRecord(
        newbornId: 'infant_normal_1',
        motherId: 'mother_1',
        householdId: 'hh_hbnc_1',
        deliveryDate: DateTime.now(),
        place: DeliveryPlace.home,
        birthWeightKg: 3.0,
        ashaId: 'asha_01',
      );

      final schedules = await repo.generateSchedule(delivery);
      final firstVisit = schedules.first;

      const checklist = HbncChecklistData(
        currentWeightKg: 3.05,
        temperatureC: 36.8,
        respiratoryRate: 48,
        chestIndrawing: false,
        grunting: false,
        feedingStatus: FeedingStatus.exclusiveBreastfeeding,
        cordStatus: CordStatus.cleanAndDry,
        skinStatus: SkinStatus.clearNormal,
        eyeStatus: EyeStatus.clear,
        activityStatus: ActivityStatus.activeAndAlert,
        jaundiceStatus: JaundiceStatus.none,
        delayedBathingPracticed: true,
        keptWarmInWarmChain: true,
      );

      final result = await repo.recordVisit(
        newbornId: 'infant_normal_1',
        visitScheduleId: firstVisit.id,
        checklist: checklist,
        ashaId: 'asha_01',
      );

      expect(result.hasDangerSign, isFalse);
      expect(result.triageResult, isNull);

      // Verify VisitSchedule updated to completed
      final updatedVisit = await (db.select(db.visitSchedules)..where((t) => t.id.equals(firstVisit.id))).getSingle();
      expect(updatedVisit.status, 'completed');
      expect(updatedVisit.completedAt, isNotNull);
      expect(updatedVisit.completedEncounterId, result.encounterId);

      // Verify clinical observations persisted
      final obs = await (db.select(db.clinicalObservations)
            ..where((t) => t.encounterId.equals(result.encounterId)))
          .get();
      expect(obs.isNotEmpty, isTrue);

      final weightObs = obs.firstWhere((o) => o.observationCode == 'WEIGHT_KG');
      expect(weightObs.valueNumeric, 3.05);

      final tempObs = obs.firstWhere((o) => o.observationCode == 'TEMP_C');
      expect(tempObs.valueNumeric, 36.8);

      final rrObs = obs.firstWhere((o) => o.observationCode == 'RESPIRATORY_RATE');
      expect(rrObs.valueNumeric, 48.0);
    });

    test('Danger Signs Detection: triggers immediate RED triage and referral workflow (Requirement 12.3)', () async {
      final delivery = HbncDeliveryRecord(
        newbornId: 'infant_normal_1',
        motherId: 'mother_1',
        householdId: 'hh_hbnc_1',
        deliveryDate: DateTime.now(),
        place: DeliveryPlace.home,
        birthWeightKg: 2.8,
        ashaId: 'asha_01',
      );

      final schedules = await repo.generateSchedule(delivery);
      final firstVisit = schedules.first;

      // Clinical scenario with fast breathing (68 >= 60) and inability to feed
      const severeChecklist = HbncChecklistData(
        currentWeightKg: 2.7,
        temperatureC: 38.3, // fever
        respiratoryRate: 68, // fast breathing >= 60
        chestIndrawing: true,
        feedingStatus: FeedingStatus.unableToFeed, // danger sign
        cordStatus: CordStatus.pusDischarge, // danger sign
        activityStatus: ActivityStatus.lethargicDrowsy, // danger sign
        jaundiceStatus: JaundiceStatus.severePalmsSoles, // danger sign
      );

      expect(severeChecklist.hasAnyDangerSign, isTrue);
      expect(severeChecklist.newbornDangerSigns.length, greaterThanOrEqualTo(5));

      final result = await repo.recordVisit(
        newbornId: 'infant_normal_1',
        visitScheduleId: firstVisit.id,
        checklist: severeChecklist,
        ashaId: 'asha_01',
      );

      expect(result.hasDangerSign, isTrue);
      expect(result.triageResult, isNotNull);
      expect(result.triageResult!.flag, TriageFlag.red);
      expect(
        result.triageResult!.findings.any((f) => f.findingText.contains('Fast breathing')),
        isTrue,
      );
      expect(
        result.triageResult!.findings.any((f) => f.findingText.contains('Unable to feed')),
        isTrue,
      );
    });

    test('Missed Visit Handling: marks overdue, reschedules in window, and alerts AF (Requirement 12.5)', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      const dayMs = 24 * 60 * 60 * 1000;

      // Insert an overdue pending visit whose due window ended 3 days ago
      final overdueTaskId = 'hbnc_overdue_test';
      await db.into(db.visitSchedules).insert(
            VisitSchedulesCompanion.insert(
              id: overdueTaskId,
              memberId: 'infant_normal_1',
              programCode: 'hbnc',
              visitType: 'HBNC Day 3 Visit',
              dueDate: now - (3 * dayMs),
              dueWindowStart: Value(now - (4 * dayMs)),
              dueWindowEnd: Value(now - (2 * dayMs)),
              status: const Value('pending'),
              createdAt: now - (5 * dayMs),
            ),
          );

      // First check: should mark overdue and reschedule within grace period
      final rescheduledList = await repo.checkAndRescheduleMissedVisits(graceDays: 2);
      expect(rescheduledList.isNotEmpty, isTrue);

      var visit = await (db.select(db.visitSchedules)..where((t) => t.id.equals(overdueTaskId))).getSingle();
      expect(visit.status, 'overdue');
      expect(visit.rescheduledCount, 1);
      expect(visit.dueDate, greaterThan(now));

      // Simulate rescheduled window expiring as well
      await (db.update(db.visitSchedules)..where((t) => t.id.equals(overdueTaskId))).write(
        VisitSchedulesCompanion(
          dueWindowEnd: Value(now - 1000),
        ),
      );

      // Second check: should alert supervisor (AF) and keep overdue
      await repo.checkAndRescheduleMissedVisits(graceDays: 2);
      visit = await (db.select(db.visitSchedules)..where((t) => t.id.equals(overdueTaskId))).getSingle();
      expect(visit.status, 'overdue');

      // Verify supervisor escalation enqueued to sync
      final syncEntries = await db.select(db.syncQueue).get();
      final escalationAlert = syncEntries.firstWhere(
        (q) => q.payloadJson.contains('SUPERVISOR_ALERT_MISSED_HBNC'),
      );
      expect(escalationAlert.priority, 2); // SyncPriority.clinical
    });

    test('Death Review: records cause, cancels pending visits, and alerts AF/ANM/MO (Requirement 12.6)', () async {
      final delivery = HbncDeliveryRecord(
        newbornId: 'infant_normal_1',
        motherId: 'mother_1',
        householdId: 'hh_hbnc_1',
        deliveryDate: DateTime.now().subtract(const Duration(days: 5)),
        place: DeliveryPlace.home,
        birthWeightKg: 2.8,
        ashaId: 'asha_01',
      );

      final schedules = await repo.generateSchedule(delivery);
      expect(schedules.every((s) => s.status == 'pending'), isTrue);

      final deathReview = HbncDeathReview(
        isNewbornDeath: true,
        isMaternalDeath: false,
        deceasedMemberId: 'infant_normal_1',
        deathDate: DateTime.now(),
        placeOfDeath: 'Home',
        probableCause: 'Severe birth asphyxia with neonatal hypothermia',
        delaysIdentified: const ['Delay in seeking care', 'Transport delay'],
        referralAttempted: true,
        notes: 'Reached facility late due to unavailable night transport',
      );

      await repo.recordDeathReview(review: deathReview, ashaId: 'asha_01');

      // 1. Verify member marked deceased
      final member = await (db.select(db.members)..where((t) => t.id.equals('infant_normal_1'))).getSingle();
      expect(member.lifecycleStatus, 'deceased');

      // 2. Verify all remaining pending visits cancelled
      final remainingVisits = await repo.getMemberHbncVisits('infant_normal_1');
      expect(remainingVisits.every((v) => v.status == 'cancelled_deceased'), isTrue);

      // 3. Verify critical alert enqueued for AF, ANM, MO
      final syncQueue = await db.select(db.syncQueue).get();
      final deathAlert = syncQueue.firstWhere(
        (q) => q.payloadJson.contains('NEONATAL_DEATH'),
      );
      expect(deathAlert.priority, 1); // SyncPriority.critical
      expect(deathAlert.payloadJson, contains('MO'));
      expect(deathAlert.payloadJson, contains('ANM'));
      expect(deathAlert.payloadJson, contains('AF'));
    });

    test('Episode Completion: all completed visits trigger HBNC_COMPLETE incentive event (Requirement 12.7)', () async {
      final delivery = HbncDeliveryRecord(
        newbornId: 'infant_normal_1',
        motherId: 'mother_1',
        householdId: 'hh_hbnc_1',
        deliveryDate: DateTime.now(),
        place: DeliveryPlace.institutionalChc,
        birthWeightKg: 3.0,
        ashaId: 'asha_01',
      );

      final schedules = await repo.generateSchedule(delivery);

      // Complete all 6 visits sequentially
      HbncVisitResult? lastResult;
      for (final visit in schedules) {
        lastResult = await repo.recordVisit(
          newbornId: 'infant_normal_1',
          visitScheduleId: visit.id,
          checklist: const HbncChecklistData(
            currentWeightKg: 3.2,
            temperatureC: 36.7,
            respiratoryRate: 46,
          ),
          ashaId: 'asha_01',
        );
      }

      expect(lastResult, isNotNull);
      expect(lastResult!.isEpisodeCompleted, isTrue);
      expect(lastResult.incentiveEvent, isNotNull);
      expect(lastResult.incentiveEvent!.activityCode, 'HBNC_COMPLETE');
      expect(lastResult.incentiveEvent!.status, 'eligible');
      expect(lastResult.incentiveEvent!.catalogueVersionId, 'NHM_ASHA_2024');

      // Verify incentive event enqueued to sync
      final syncEntries = await db.select(db.syncQueue).get();
      final incSync = syncEntries.firstWhere((q) => q.targetTable == 'incentive_events');
      expect(incSync.payloadJson, contains('HBNC_COMPLETE'));
    });

    test('KMC Guidance: recommended target hours scale by birth weight (Requirement 12.4)', () {
      expect(KmcGuidance.recommendedTargetHours(1.2), 18.0);
      expect(KmcGuidance.recommendedTargetHours(1.8), 12.0);
      expect(KmcGuidance.recommendedTargetHours(2.3), 8.0);
      expect(KmcGuidance.coreSteps.isNotEmpty, isTrue);
      expect(KmcGuidance.dangerSignAlerts.isNotEmpty, isTrue);
    });
  });
}
