import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/features/clinical_programs/anc_pnc/data/pnc_repository.dart';
import 'package:asha_platform/features/clinical_programs/anc_pnc/domain/pnc_models.dart';

void main() {
  group('Task 9.4: Postnatal Care (PNC) Program Tests (Requirements 15.1 – 15.6)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late PncRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      repo = PncRepository(db, syncEngine);

      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed Household and mother
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_pnc_1',
              village: 'Sundarpur',
              headName: 'Ramesh Patel',
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'mother_geeta_1',
              householdId: 'hh_pnc_1',
              name: 'Geeta Patel',
              sex: 'F',
              relationshipToHead: const Value('Wife'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. Schedule Generation: Institutional vs Home Delivery (Requirement 15.1)
    test('Schedule Generation: Generates 6 visits for institutional delivery (Day 1 covered at facility)', () async {
      final deliveryDate = DateTime(2025, 4, 10);
      final schedules = await repo.generatePncSchedule(
        motherId: 'mother_geeta_1',
        deliveryDate: deliveryDate,
        isHomeDelivery: false,
      );

      // Days 3, 7, 14, 21, 28, 42
      expect(schedules.length, equals(6));
      expect(
        schedules.map((s) => s.visitType).toList(),
        equals([
          'Maternal PNC Day 3 Visit',
          'Maternal PNC Day 7 Visit',
          'Maternal PNC Day 14 Visit',
          'Maternal PNC Day 21 Visit',
          'Maternal PNC Day 28 Visit',
          'Maternal PNC Day 42 Visit',
        ]),
      );

      // Verify records in DB
      final dbSchedules = await (db.select(db.visitSchedules)
            ..where((t) => t.memberId.equals('mother_geeta_1') & t.programCode.equals('pnc')))
          .get();
      expect(dbSchedules.length, equals(6));

      // Day 3 check
      final day3 = dbSchedules.firstWhere((s) => s.id.contains('_d3'));
      expect(day3.visitType, contains('PNC Day 3 Visit'));
      expect(DateTime.fromMillisecondsSinceEpoch(day3.dueDate), equals(deliveryDate.add(const Duration(days: 3))));
    });

    test('Schedule Generation: Generates 7 visits for home delivery (includes Day 1)', () async {
      final deliveryDate = DateTime(2025, 4, 10);
      final schedules = await repo.generatePncSchedule(
        motherId: 'mother_geeta_1',
        deliveryDate: deliveryDate,
        isHomeDelivery: true,
      );

      // Days 1, 3, 7, 14, 21, 28, 42
      expect(schedules.length, equals(7));
      expect(
        schedules.map((s) => s.visitType).toList(),
        equals([
          'Maternal PNC Day 1 Visit',
          'Maternal PNC Day 3 Visit',
          'Maternal PNC Day 7 Visit',
          'Maternal PNC Day 14 Visit',
          'Maternal PNC Day 21 Visit',
          'Maternal PNC Day 28 Visit',
          'Maternal PNC Day 42 Visit',
        ]),
      );

      final dbSchedules = await (db.select(db.visitSchedules)
            ..where((t) => t.memberId.equals('mother_geeta_1') & t.programCode.equals('pnc')))
          .get();
      expect(dbSchedules.length, equals(7));
      expect(dbSchedules.any((s) => s.id.contains('_d1')), isTrue);
    });

    // ── 2. Standard Healthy PNC Visit Recording (Requirements 15.2, 15.3) ─────
    test('Record PNC Visit: Healthy maternal state yields normal outcome and records observations', () async {
      final deliveryDate = DateTime.now().subtract(const Duration(days: 7));
      final schedules = await repo.generatePncSchedule(
        motherId: 'mother_geeta_1',
        deliveryDate: deliveryDate,
        isHomeDelivery: false,
      );
      final day7Schedule = schedules.firstWhere((s) => s.visitType.contains('Day 7'));

      final checklist = PncChecklistData(
        visitDay: 7,
        temperatureC: 36.8,
        systolicBp: 118,
        diastolicBp: 78,
        bleedingStatus: PncBleedingStatus.normalLochia,
        breastStatus: PncBreastStatus.normalLactating,
        woundStatus: PncWoundStatus.normalHealing,
        depressionScreening: const PncDepressionScreening(),
        severeHeadacheOrBlurredVision: false,
        convulsionsOrLossOfConsciousness: false,
        severeAbdominalPain: false,
        severeBreathlessness: false,
        nutritionCounsellingGiven: true,
        restAndHydrationCounseled: true,
        postpartumContraceptionCounseled: true,
        chosenContraceptionMethod: 'LAM',
      );

      final result = await repo.recordPncVisit(
        motherId: 'mother_geeta_1',
        visitScheduleId: day7Schedule.id,
        checklist: checklist,
        ashaId: 'asha_01',
      );

      expect(result.isRedFlag, isFalse);
      expect(result.hasPpd, isFalse);
      expect(result.triageResult, isNull);

      // Verify schedule status updated to 'completed'
      final updatedSchedule = await (db.select(db.visitSchedules)
            ..where((t) => t.id.equals(day7Schedule.id)))
          .getSingle();
      expect(updatedSchedule.status, equals('completed'));

      // Verify clinicalObservations inserted
      final obs = await (db.select(db.clinicalObservations)
            ..where((t) => t.encounterId.equals(result.encounterId)))
          .get();
      expect(obs.length, greaterThanOrEqualTo(5));
      expect(obs.any((o) => o.observationCode == 'TEMPERATURE' && o.valueNumeric == 36.8), isTrue);
      expect(obs.any((o) => o.observationCode == 'BLOOD_PRESSURE' && o.valueNumeric == 118), isTrue);
      expect(obs.any((o) => o.observationCode == 'MATERNAL_BLEEDING' && o.valueEnum == 'normal_lochia'), isTrue);
      expect(obs.any((o) => o.observationCode == 'PPFP_CONTRACEPTION' && o.valueText == 'LAM'), isTrue);
    });

    // ── 3. Danger Signs & Emergency Obstetric Referral (Requirement 15.4) ──────
    test('Danger Signs: High fever (>= 38°C) triggers RED emergency triage for puerperal sepsis', () async {
      final checklist = PncChecklistData(
        visitDay: 3,
        temperatureC: 38.8,
        systolicBp: 120,
        diastolicBp: 80,
        bleedingStatus: PncBleedingStatus.foulSmellingLochia,
        breastStatus: PncBreastStatus.normalLactating,
        woundStatus: PncWoundStatus.normalHealing,
      );

      expect(checklist.maternalDangerSigns.length, equals(2));
      expect(checklist.maternalDangerSigns.any((s) => s.contains('High postpartum fever')), isTrue);
      expect(checklist.maternalDangerSigns.any((s) => s.contains('Foul-Smelling')), isTrue);

      final result = await repo.recordPncVisit(
        motherId: 'mother_geeta_1',
        visitScheduleId: 'pnc_sched_fever_3',
        checklist: checklist,
        ashaId: 'asha_01',
      );

      expect(result.isRedFlag, isTrue);
      expect(result.triageResult?.flag, equals(TriageFlag.red));
      expect(result.suggestedReferral, contains('CHC'));
    });

    test('Danger Signs: Postpartum severe hypertension (BP 165/112) triggers RED triage', () async {
      final checklist = PncChecklistData(
        visitDay: 3,
        temperatureC: 37.0,
        systolicBp: 165,
        diastolicBp: 112,
        bleedingStatus: PncBleedingStatus.normalLochia,
        breastStatus: PncBreastStatus.normalLactating,
        woundStatus: PncWoundStatus.normalHealing,
        severeHeadacheOrBlurredVision: true,
      );

      expect(checklist.maternalDangerSigns.any((s) => s.contains('Severe hypertension')), isTrue);
      expect(checklist.maternalDangerSigns.any((s) => s.contains('Severe persistent headache')), isTrue);

      final result = await repo.recordPncVisit(
        motherId: 'mother_geeta_1',
        visitScheduleId: 'pnc_sched_bp_3',
        checklist: checklist,
        ashaId: 'asha_01',
      );

      expect(result.isRedFlag, isTrue);
      expect(result.triageResult?.flag, equals(TriageFlag.red));
    });

    test('Danger Signs: Severe postpartum hemorrhage (excessive bleeding soaking pads) triggers RED', () async {
      final checklist = PncChecklistData(
        visitDay: 3,
        temperatureC: 36.9,
        bleedingStatus: PncBleedingStatus.heavySoakingPads,
        breastStatus: PncBreastStatus.normalLactating,
        woundStatus: PncWoundStatus.normalHealing,
      );

      expect(checklist.maternalDangerSigns.any((s) => s.contains('PPH')), isTrue);

      final result = await repo.recordPncVisit(
        motherId: 'mother_geeta_1',
        visitScheduleId: 'pnc_sched_pph_3',
        checklist: checklist,
        ashaId: 'asha_01',
      );

      expect(result.isRedFlag, isTrue);
      expect(result.triageResult?.flag, equals(TriageFlag.red));
      expect(result.prePopulatedReferralReason, contains('PPH'));
    });

    // ── 4. Postpartum Depression (PPD) Screening & Tele-MANAS (Requirement 15.5)
    test('PPD Screening: Identifies depressive symptoms and offers supportive Tele-MANAS referral', () async {
      final checklist = PncChecklistData(
        visitDay: 14,
        temperatureC: 36.6,
        systolicBp: 110,
        diastolicBp: 70,
        bleedingStatus: PncBleedingStatus.normalLochia,
        breastStatus: PncBreastStatus.normalLactating,
        woundStatus: PncWoundStatus.normalHealing,
        depressionScreening: const PncDepressionScreening(
          feelsOverwhelmedOrHopeless: true,
          persistentCryingOrSadness: true,
          difficultyBondingWithBaby: true,
          severeAnxietyOrInsomnia: false,
          thoughtsOfSelfHarmOrHarmToBaby: false,
        ),
      );

      expect(checklist.hasPpd, isTrue);
      expect(checklist.depressionScreening.hasPpdIndicators, isTrue);
      expect(checklist.depressionScreening.ppdFindings.length, equals(3));

      final result = await repo.recordPncVisit(
        motherId: 'mother_geeta_1',
        visitScheduleId: 'pnc_sched_ppd_14',
        checklist: checklist,
        ashaId: 'asha_01',
      );

      expect(result.hasPpd, isTrue);
      expect(result.isRedFlag, isFalse);
      expect(result.triageResult?.flag, equals(TriageFlag.yellow));
      expect(result.suggestedReferral, contains('Tele-MANAS'));
      expect(result.suggestedReferral, contains('14416'));

      // Check observation for PPD recorded
      final obs = await (db.select(db.clinicalObservations)
            ..where((t) => t.encounterId.equals(result.encounterId) & t.observationCode.equals('PPD_SCREENING')))
          .get();
      expect(obs.length, equals(1));
      expect(obs.first.valueEnum, equals('POSITIVE'));
    });

    test('PPD Crisis: Thoughts of self-harm escalate to RED emergency referral', () async {
      final checklist = PncChecklistData(
        visitDay: 14,
        temperatureC: 36.6,
        bleedingStatus: PncBleedingStatus.normalLochia,
        breastStatus: PncBreastStatus.normalLactating,
        woundStatus: PncWoundStatus.normalHealing,
        depressionScreening: const PncDepressionScreening(
          thoughtsOfSelfHarmOrHarmToBaby: true,
        ),
      );

      expect(checklist.depressionScreening.isSevereUrgentRisk, isTrue);
      expect(checklist.maternalDangerSigns.any((s) => s.toLowerCase().contains('thoughts of self-harm')), isTrue);

      final result = await repo.recordPncVisit(
        motherId: 'mother_geeta_1',
        visitScheduleId: 'pnc_sched_crisis_14',
        checklist: checklist,
        ashaId: 'asha_01',
      );

      expect(result.isRedFlag, isTrue);
      expect(result.triageResult?.flag, equals(TriageFlag.red));
    });

    // ── 5. Institutional Delivery Incentive Confirmation (Requirement 15.6) ───
    test('Institutional Delivery Incentive: Creates JSY escort incentive event and sync queue item', () async {
      final incentiveId = await repo.confirmInstitutionalDelivery(
        motherId: 'mother_geeta_1',
        placeOfDelivery: 'District Hospital Sundarpur',
        ashaId: 'asha_01',
      );

      expect(incentiveId, isNotNull);

      // Verify incentive event in DB
      final incentives = await (db.select(db.incentiveEvents)
            ..where((t) => t.memberId.equals('mother_geeta_1')))
          .get();

      expect(incentives.length, equals(1));
      final incentive = incentives.first;
      expect(incentive.activityCode, equals('INSTITUTIONAL_DELIVERY_ESCORT'));
      expect(incentive.status, equals('eligible'));

      // Verify sync queue created
      final syncItems = await (db.select(db.syncQueue)
            ..where((t) => t.recordId.equals(incentiveId!)))
          .get();
      expect(syncItems.length, equals(1));
      expect(syncItems.first.targetTable, equals('incentive_events'));
      expect(syncItems.first.operation, equals('insert'));
    });
  });
}
