import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart' hide TriageResult;
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/features/clinical_programs/anc_pnc/data/anc_repository.dart';
import 'package:asha_platform/features/clinical_programs/anc_pnc/domain/anc_models.dart';
import 'package:asha_platform/features/clinical_programs/hbnc/data/hbnc_repository.dart';

void main() {
  group('Task 9.3: Antenatal Care (ANC) & High-Risk Pregnancy Tests (Requirements 14.1 – 14.7)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late HbncRepository hbncRepo;
    late AncRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      hbncRepo = HbncRepository(db, syncEngine);
      repo = AncRepository(db, syncEngine, hbncRepo);

      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed Household and pregnant mother member
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_anc_1',
              village: 'Devpur',
              headName: 'Vikram Singh',
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'woman_sunita_1',
              householdId: 'hh_anc_1',
              name: 'Sunita Devi',
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

    // ── 1. Registration & Schedule Generation (Requirements 14.1, 14.2) ──────
    test('Registration: Captures LMP, calculates EDD correctly, and generates full ANC schedule', () async {
      final lmp = DateTime(2025, 2, 1);
      final reg = PregnancyRegistration(
        womanId: 'woman_sunita_1',
        lmp: lmp,
        gravida: 2,
        para: 1,
        livingChildren: 1,
        mcpCardNumber: 'MCP-992384',
        rchId: 'RCH-100234',
        bloodGroup: 'O+',
        maternalAgeYears: 24,
      );

      // Verify Naegele EDD calculation: LMP + 280 days
      final expectedEdd = lmp.add(const Duration(days: 280));
      expect(reg.edd, equals(expectedEdd));

      final schedules = await repo.registerPregnancy(registration: reg, ashaId: 'asha_01');

      // Standard contacts (10, 20, 30, 36 weeks) + Td-1 + Td-2 + Birth Plan (34 weeks) = 7 schedules
      expect(schedules.length, equals(7));

      // Verify schedules in DB
      final dbSchedules = await (db.select(db.visitSchedules)
            ..where((t) => t.memberId.equals('woman_sunita_1') & t.programCode.equals('anc')))
          .get();
      expect(dbSchedules.length, equals(7));

      // Check specific schedule items
      expect(dbSchedules.any((s) => s.visitType.contains('Contact (10 Weeks')), isTrue);
      expect(dbSchedules.any((s) => s.visitType.contains('Contact (20 Weeks')), isTrue);
      expect(dbSchedules.any((s) => s.visitType.contains('Contact 3 (30 Weeks')), isTrue);
      expect(dbSchedules.any((s) => s.visitType.contains('Contact (36 Weeks')), isTrue);
      expect(dbSchedules.any((s) => s.id.contains('anc_td1_')), isTrue);
      expect(dbSchedules.any((s) => s.id.contains('anc_td2_')), isTrue);
      expect(dbSchedules.any((s) => s.id.contains('anc_birthplan_')), isTrue);

      // Verify Member updated with RCH ID
      final member = await (db.select(db.members)..where((t) => t.id.equals('woman_sunita_1'))).getSingle();
      expect(member.rchId, equals('RCH-100234'));
    });

    // ── 2. High-Risk Pregnancy Baseline Flagging (Requirements 14.3, 14.4) ───
    test('High-Risk Baseline: Flags previous C-section / teenage pregnancy, adds extra visits and alerts AF', () async {
      final lmp = DateTime(2025, 2, 1);
      final highRiskReg = PregnancyRegistration(
        womanId: 'woman_sunita_1',
        lmp: lmp,
        gravida: 3,
        para: 2,
        previousCesarean: true, // High risk!
        stillbirths: 1, // High risk!
        maternalAgeYears: 17, // Adolescent high risk!
        bloodGroup: 'B-', // Rh negative high risk!
      );

      expect(highRiskReg.isBaselineHighRisk, isTrue);
      expect(highRiskReg.baselineHighRiskReasons.length, greaterThanOrEqualTo(3));

      final schedules = await repo.registerPregnancy(registration: highRiskReg, ashaId: 'asha_01');

      // Baseline high risk adds 3 extra contacts (26, 34, 38 weeks) -> 7 + 3 = 10 total schedules
      expect(schedules.length, equals(10));
      expect(schedules.any((s) => s.visitType.contains('High-Risk Review (26 Weeks')), isTrue);
      expect(schedules.any((s) => s.visitType.contains('High-Risk Review (34 Weeks')), isTrue);
      expect(schedules.any((s) => s.visitType.contains('High-Risk Review (38 Weeks')), isTrue);

      // Verify critical alert enqueued in sync queue for ANM and AF
      final alerts = await (db.select(db.syncQueue)
            ..where((t) => t.targetTable.equals('alerts') & t.recordId.equals('alert_hrp_woman_sunita_1')))
          .get();
      expect(alerts.isNotEmpty, isTrue);
      expect(alerts.first.priority, equals(1)); // SyncPriority.critical
    });

    // ── 3. ANC Contact Danger Signs & Severe Hypertension (Requirement 14.3) ──
    test('ANC Contact Triage: Severe hypertension (165/112) or bleeding produces RED triage and emergency referral', () async {
      final lmp = DateTime(2025, 2, 1);
      final reg = PregnancyRegistration(
        womanId: 'woman_sunita_1',
        lmp: lmp,
        gravida: 2,
        para: 1,
      );
      final schedules = await repo.registerPregnancy(registration: reg, ashaId: 'asha_01');
      final anc2 = schedules.firstWhere((s) => s.visitType.contains('20 Weeks'));

      // Severe pre-eclampsia danger signs
      const visitData = AncContactData(
        contactNumber: 2,
        gestationWeeks: 20,
        systolicBp: 165, // Severe hypertension >= 160
        diastolicBp: 112, // Severe hypertension >= 110
        haemoglobin: 10.5,
        vaginalBleeding: true, // Emergency danger sign!
        severeHeadacheOrBlurredVision: true, // Emergency danger sign!
        urineAlbuminPresent: true,
      );

      final result = await repo.recordAncVisit(
        womanId: 'woman_sunita_1',
        visitScheduleId: anc2.id,
        visitData: visitData,
        ashaId: 'asha_01',
      );

      expect(result.isRedFlag, isTrue);
      expect(result.isHighRisk, isTrue);
      expect(result.triageResult, isNotNull);
      expect(result.triageResult!.flag, equals(TriageFlag.red));
      expect(result.suggestedReferralFacility, contains('Community Health Centre (CHC) / District Hospital (FRU)'));
      expect(result.prePopulatedReferralReason, contains('Antepartum vaginal bleeding'));
      expect(result.prePopulatedReferralReason, contains('Severe hypertension (BP 165/112 mmHg)'));

      // Verify RED TriageResult persisted in database
      final triageRows = await (db.select(db.triageResults)
            ..where((t) => t.encounterId.equals(result.encounterId)))
          .get();
      expect(triageRows.length, equals(1));
      expect(triageRows.first.flag, equals('RED'));

      // Verify critical priority alert enqueued
      final alerts = await (db.select(db.syncQueue)
            ..where((t) => t.targetTable.equals('alerts') & t.recordId.equals('alert_red_anc_${result.encounterId}')))
          .get();
      expect(alerts.isNotEmpty, isTrue);
      expect(alerts.first.priority, equals(1));
    });

    // ── 4. Moderate Risk Flagging (BP 145/95, Hb 9.2) (Requirement 14.3) ─────
    test('ANC Contact Triage: Moderate hypertension and mild anaemia produces YELLOW triage for PMSMA clinic', () async {
      final lmp = DateTime(2025, 2, 1);
      final reg = PregnancyRegistration(womanId: 'woman_sunita_1', lmp: lmp, gravida: 1, para: 0);
      final schedules = await repo.registerPregnancy(registration: reg, ashaId: 'asha_01');
      final anc1 = schedules.firstWhere((s) => s.visitType.contains('10 Weeks'));

      const visitData = AncContactData(
        contactNumber: 1,
        gestationWeeks: 10,
        systolicBp: 145, // Mild/moderate hypertension
        diastolicBp: 95,
        haemoglobin: 9.2, // Moderate anaemia (7.0 - 10.9)
        vaginalBleeding: false,
        severeHeadacheOrBlurredVision: false,
      );

      final result = await repo.recordAncVisit(
        womanId: 'woman_sunita_1',
        visitScheduleId: anc1.id,
        visitData: visitData,
        ashaId: 'asha_01',
      );

      expect(result.isRedFlag, isFalse);
      expect(result.isHighRisk, isTrue);
      expect(result.triageResult, isNotNull);
      expect(result.triageResult!.flag, equals(TriageFlag.yellow));
      expect(result.suggestedReferralFacility, contains('Primary Health Centre (PHC) / PMSMA Clinic'));
      expect(result.prePopulatedReferralReason, contains('Gestational hypertension (BP 145/95 mmHg)'));
      expect(result.prePopulatedReferralReason, contains('Moderate / Mild anaemia'));
    });

    // ── 5. Birth Preparedness Plan at 34 Weeks (Requirement 14.5) ────────────
    test('Birth Plan: Records facility, 108 transport, escort, blood donor, and completes schedule', () async {
      final lmp = DateTime(2025, 2, 1);
      final reg = PregnancyRegistration(womanId: 'woman_sunita_1', lmp: lmp, gravida: 2, para: 1);
      await repo.registerPregnancy(registration: reg, ashaId: 'asha_01');

      final plan = BirthPlan(
        womanId: 'woman_sunita_1',
        chosenDeliveryFacility: 'CHC Kotra',
        facilityType: 'Community Health Centre (FRU)',
        facilityDistanceKm: 12.5,
        transportArrangement: '108 Ambulance + Janani Express',
        namedEscortName: 'Kailash Devi',
        namedEscortPhone: '9829012345',
        escortRelationship: 'Mother-in-law',
        bloodDonorName: 'Vikram Singh',
        bloodDonorPhone: '9829054321',
        bloodDonorGroup: 'O+',
        emergencySavingsConfirmed: true,
        recordedAt: DateTime.now(),
      );

      final planEncounterId = await repo.recordBirthPlan(plan: plan, ashaId: 'asha_01');
      expect(planEncounterId.isNotEmpty, isTrue);

      // Verify birth plan schedule item completed
      final birthPlanSchedule = await (db.select(db.visitSchedules)
            ..where((t) => t.id.equals('anc_birthplan_woman_sunita_1')))
          .getSingle();
      expect(birthPlanSchedule.status, equals('completed'));
      expect(birthPlanSchedule.completedEncounterId, equals(planEncounterId));

      // Verify observations recorded
      final observations = await (db.select(db.clinicalObservations)
            ..where((t) => t.encounterId.equals(planEncounterId)))
          .get();
      expect(observations.any((o) => o.observationCode == 'DELIVERY_FACILITY' && o.valueText!.contains('CHC Kotra')), isTrue);
      expect(observations.any((o) => o.observationCode == 'TRANSPORT_ARRANGEMENT' && o.valueText!.contains('108')), isTrue);
      expect(observations.any((o) => o.observationCode == 'NAMED_ESCORT' && o.valueText!.contains('Kailash Devi')), isTrue);
      expect(observations.any((o) => o.observationCode == 'BLOOD_DONOR' && o.valueText!.contains('Vikram Singh')), isTrue);
    });

    // ── 6. Overdue Visit Detection (Requirement 14.6) ─────────────────────────
    test('Overdue Visits: Detects expired windows and marks visit status as overdue', () async {
      final lmp = DateTime(2025, 2, 1);
      final reg = PregnancyRegistration(womanId: 'woman_sunita_1', lmp: lmp, gravida: 1, para: 0);
      final schedules = await repo.registerPregnancy(registration: reg, ashaId: 'asha_01');
      final firstSchedule = schedules.first;

      // Expire window
      final pastMs = DateTime.now().millisecondsSinceEpoch - 5000;
      await (db.update(db.visitSchedules)..where((t) => t.id.equals(firstSchedule.id))).write(
        VisitSchedulesCompanion(dueWindowEnd: Value(pastMs)),
      );

      final overdueIds = await repo.checkAndMarkOverdueVisits('woman_sunita_1');
      expect(overdueIds, contains(firstSchedule.id));

      final updated = await (db.select(db.visitSchedules)..where((t) => t.id.equals(firstSchedule.id))).getSingle();
      expect(updated.status, equals('overdue'));
    });

    // ── 7. Pregnancy Outcome Downstream Routing (Requirement 14.7) ───────────
    test('Pregnancy Outcome: Live birth cancels open ANC visits, registers newborn, and auto-generates HBNC schedule', () async {
      final lmp = DateTime(2025, 2, 1);
      final reg = PregnancyRegistration(womanId: 'woman_sunita_1', lmp: lmp, gravida: 2, para: 1);
      await repo.registerPregnancy(registration: reg, ashaId: 'asha_01');

      final outcome = PregnancyOutcome(
        womanId: 'woman_sunita_1',
        outcomeDate: DateTime.now(),
        outcomeType: PregnancyOutcomeType.liveBirth,
        placeOfDelivery: 'phc',
        deliveryType: 'normal_vaginal',
        skilledAttendant: 'Staff Nurse Sunita',
        newbornSex: 'M',
        birthWeightKg: 2.9,
        gestationalWeeksAtDelivery: 39,
      );

      final downstream = await repo.recordPregnancyOutcome(outcome: outcome, ashaId: 'asha_01');

      expect(downstream['outcome_type'], equals('live_birth'));
      expect(downstream['newborn_id'], isNotNull);
      expect(downstream['hbnc_visits_scheduled'], greaterThanOrEqualTo(6));

      // Verify open ANC schedules are cancelled
      final remainingAnc = await (db.select(db.visitSchedules)
            ..where((t) =>
                t.memberId.equals('woman_sunita_1') &
                t.programCode.equals('anc') &
                (t.status.equals('pending') | t.status.equals('overdue'))))
          .get();
      expect(remainingAnc.isEmpty, isTrue);

      // Verify newborn member created in DB
      final newborn = await (db.select(db.members)..where((t) => t.id.equals(downstream['newborn_id']))).getSingle();
      expect(newborn.householdId, equals('hh_anc_1'));
      expect(newborn.name, contains('Baby of Sunita Devi'));

      // Verify HBNC visit schedules created for newborn
      final hbncSchedules = await (db.select(db.visitSchedules)
            ..where((t) => t.memberId.equals(downstream['newborn_id']) & t.programCode.equals('hbnc')))
          .get();
      expect(hbncSchedules.length, equals(6)); // Institutional delivery has 6 visits (Days 3, 7, 14, 21, 28, 42)
    });
  });
}
