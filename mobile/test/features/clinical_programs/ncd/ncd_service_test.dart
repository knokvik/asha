import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart' hide TriageResult;
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/features/clinical_programs/ncd/data/ncd_repository.dart';
import 'package:asha_platform/features/clinical_programs/ncd/domain/cbac_calculator.dart';
import 'package:asha_platform/features/clinical_programs/ncd/domain/cbac_models.dart';

void main() {
  group('Task 10.3: NCD / CBAC Screening & Chronic Care Register (Requirements 19.1 – 19.7)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late NcdRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      repo = NcdRepository(db, syncEngine);

      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed Household
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_ncd_1',
              village: 'Rampur',
              hamlet: const Value('East Hamlet'),
              headName: 'Sohan Lal',
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      // Seed Adult Member: Male 52 years old
      final fiftyTwoYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 52)).millisecondsSinceEpoch;
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'member_sohan_1',
              householdId: 'hh_ncd_1',
              name: 'Sohan Lal',
              sex: 'M',
              dobApprox: Value(fiftyTwoYearsAgo),
              relationshipToHead: const Value('Self'),
              phone: const Value('9812345678'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      // Seed Adult Member: Female 45 years old
      final fortyFiveYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 45)).millisecondsSinceEpoch;
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'member_kamla_1',
              householdId: 'hh_ncd_1',
              name: 'Kamla Devi',
              sex: 'F',
              dobApprox: Value(fortyFiveYearsAgo),
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

    // ── 1. Official CBAC Score Calculation (Requirement 19.1) ─────────────────
    test('19.1: CBAC score computation conforms to official NHM scoring algorithm and age-bands', () {
      // Test Male 35y (0 pt), never tobacco (0), no alcohol (0), waist 85cm (0), >=150m activity (0), no family history (0)
      // Total = 0
      final scoreLow = CbacCalculator.computeTotalCbacScore(
        ageYears: 35,
        tobaccoUse: TobaccoUse.never,
        alcoholConsumption: AlcoholConsumption.no,
        waistCircumferenceCm: 85.0,
        sex: 'M',
        physicalActivity: PhysicalActivity.atLeast150Mins,
        familyHistory: FamilyHistoryNcd.no,
      );
      expect(scoreLow, equals(0));

      // Test Male 52y (2 pts), daily tobacco (2 pts), consumes alcohol (1 pt), waist 102cm (>100cm: 2 pts), sedentary (1 pt), family history (2 pts)
      // Total = 2 + 2 + 1 + 2 + 1 + 2 = 10 pts
      final scoreHigh = CbacCalculator.computeTotalCbacScore(
        ageYears: 52,
        tobaccoUse: TobaccoUse.currentDaily,
        alcoholConsumption: AlcoholConsumption.yes,
        waistCircumferenceCm: 102.0,
        sex: 'M',
        physicalActivity: PhysicalActivity.lessThan150Mins,
        familyHistory: FamilyHistoryNcd.yes,
      );
      expect(scoreHigh, equals(10));

      // Test Female 45y (1 pt), quit tobacco (1 pt), waist 88cm (81-90cm: 1 pt), family history (2 pts) -> Total = 5 pts
      final scoreThreshold = CbacCalculator.computeTotalCbacScore(
        ageYears: 45,
        tobaccoUse: TobaccoUse.pastQuit,
        alcoholConsumption: AlcoholConsumption.no,
        waistCircumferenceCm: 88.0,
        sex: 'F',
        physicalActivity: PhysicalActivity.atLeast150Mins,
        familyHistory: FamilyHistoryNcd.yes,
      );
      expect(scoreThreshold, equals(5));
      expect(scoreThreshold > 4, isTrue); // High risk threshold breached
    });

    // ── 2. Blood Pressure & Blood Glucose Classification (Requirement 19.2) ───
    test('19.2: Classifies Blood Pressure & Blood Glucose per national NCD guidelines', () {
      // BP classifications
      expect(
        CbacCalculator.classifyBloodPressure(systolic: 118, diastolic: 78),
        equals(BloodPressureCategory.normal),
      );
      expect(
        CbacCalculator.classifyBloodPressure(systolic: 130, diastolic: 85),
        equals(BloodPressureCategory.prehypertension),
      );
      expect(
        CbacCalculator.classifyBloodPressure(systolic: 145, diastolic: 92),
        equals(BloodPressureCategory.stage1Hypertension),
      );
      expect(
        CbacCalculator.classifyBloodPressure(systolic: 165, diastolic: 102),
        equals(BloodPressureCategory.stage2Hypertension),
      );
      // Hypertensive Crisis: SBP >= 180 or DBP >= 110 -> RED
      final crisis = CbacCalculator.classifyBloodPressure(systolic: 185, diastolic: 115);
      expect(crisis, equals(BloodPressureCategory.hypertensiveCrisis));
      expect(crisis.triageFlag, equals(TriageFlag.red));

      // Blood Glucose classifications
      // Fasting
      expect(
        CbacCalculator.classifyBloodGlucose(glucoseMgDl: 90, type: GlucoseType.fasting),
        equals(BloodGlucoseCategory.normal),
      );
      expect(
        CbacCalculator.classifyBloodGlucose(glucoseMgDl: 115, type: GlucoseType.fasting),
        equals(BloodGlucoseCategory.prediabetes),
      );
      expect(
        CbacCalculator.classifyBloodGlucose(glucoseMgDl: 150, type: GlucoseType.fasting),
        equals(BloodGlucoseCategory.suspectedDiabetes),
      );

      // Random
      expect(
        CbacCalculator.classifyBloodGlucose(glucoseMgDl: 120, type: GlucoseType.random),
        equals(BloodGlucoseCategory.normal),
      );
      expect(
        CbacCalculator.classifyBloodGlucose(glucoseMgDl: 165, type: GlucoseType.random),
        equals(BloodGlucoseCategory.prediabetes),
      );
      expect(
        CbacCalculator.classifyBloodGlucose(glucoseMgDl: 230, type: GlucoseType.random),
        equals(BloodGlucoseCategory.suspectedDiabetes),
      );

      // Severe emergencies
      final severeHigh = CbacCalculator.classifyBloodGlucose(glucoseMgDl: 340, type: GlucoseType.random);
      expect(severeHigh, equals(BloodGlucoseCategory.severeHyperglycemia));
      expect(severeHigh.triageFlag, equals(TriageFlag.red));

      final severeLow = CbacCalculator.classifyBloodGlucose(glucoseMgDl: 48, type: GlucoseType.random);
      expect(severeLow, equals(BloodGlucoseCategory.severeHypoglycemia));
      expect(severeLow.triageFlag, equals(TriageFlag.red));
    });

    // ── 3. Cancer Warning Signs Flagging (Requirement 19.3) ───────────────────
    test('19.3: Oral, breast, and cervical cancer symptoms flag case for confirmatory referral', () {
      final signsOral = const CancerWarningSigns(oralUlcerGt2Weeks: true);
      expect(signsOral.hasOralCancerSigns, isTrue);
      expect(signsOral.hasAnyCancerSign, isTrue);
      expect(signsOral.activeFindings.first, contains('Oral: Non-healing mouth ulcer'));

      final signsBreast = const CancerWarningSigns(breastLump: true);
      expect(signsBreast.hasBreastCancerSigns, isTrue);
      expect(signsBreast.hasAnyCancerSign, isTrue);

      final signsCervical = const CancerWarningSigns(cervicalPostCoitalBleeding: true);
      expect(signsCervical.hasCervicalCancerSigns, isTrue);
      expect(signsCervical.hasAnyCancerSign, isTrue);
    });

    // ── 4. Record CBAC Screening & Referral Integration (Requirements 19.1, 19.2) ──
    test('19.1 & 19.2: Records CBAC screening, generates referral for high risk/BP, and adds follow-up task', () async {
      // Sohan Lal: 52y male, score = 6 (high risk > 4), stage 1 hypertension (BP 148/94)
      final assessment = await repo.recordCbacScreening(
        memberId: 'member_sohan_1',
        tobaccoUse: TobaccoUse.currentDaily,
        alcoholConsumption: AlcoholConsumption.no,
        waistCircumferenceCm: 96.0, // +1 pt
        physicalActivity: PhysicalActivity.lessThan150Mins, // +1 pt
        familyHistory: FamilyHistoryNcd.yes, // +2 pts, age 52 (+2 pts) -> Total = 6 pts
        warningSigns: const CancerWarningSigns(),
        systolicBp: 148,
        diastolicBp: 94,
        ashaId: 'asha_01',
      );

      expect(assessment.totalCbacScore, equals(8));
      expect(assessment.isHighRiskScore, isTrue);
      expect(assessment.triageFlag, equals(TriageFlag.yellow));
      expect(assessment.requiresFacilityConfirmation, isTrue);

      // Verify discrete observations in database
      final obs = await (db.select(db.clinicalObservations)..where((t) => t.encounterId.equals(assessment.id))).get();
      final obsMap = {for (final o in obs) o.observationCode: o};
      expect(obsMap['CBAC_SCORE']?.valueNumeric, equals(8.0));
      expect(obsMap['IS_HIGH_RISK_CBAC']?.valueEnum, equals('YES'));
      expect(obsMap['SYSTOLIC_BP']?.valueNumeric, equals(148.0));
      expect(obsMap['DIASTOLIC_BP']?.valueNumeric, equals(94.0));
      expect(obsMap['BP_CATEGORY']?.valueText, equals('stage1Hypertension'));

      // Verify TriageResults
      final triage = await (db.select(db.triageResults)..where((t) => t.encounterId.equals(assessment.id))).getSingle();
      expect(triage.flag, equals('YELLOW'));

      // Verify ReferralRecord created
      final referrals = await (db.select(db.referralRecords)..where((t) => t.memberId.equals('member_sohan_1'))).get();
      expect(referrals.isNotEmpty, isTrue);
      expect(referrals.first.triageFlag, equals('YELLOW'));

      // Verify VisitSchedule follow-up task created
      final schedules = await (db.select(db.visitSchedules)..where((t) => t.memberId.equals('member_sohan_1'))).get();
      expect(schedules.any((s) => s.visitType.contains('NCD Confirmatory Screening Follow-Up')), isTrue);

      // Verify IncentiveEvent recorded (CBAC_SCREENING_COMPLETE)
      final incentives = await (db.select(db.incentiveEvents)..where((t) => t.memberId.equals('member_sohan_1'))).get();
      expect(incentives.isNotEmpty, isTrue);
      expect(incentives.first.activityCode, equals('CBAC_SCREENING_COMPLETE'));
      expect(incentives.first.status, equals('eligible'));
    });

    // ── 5. Hypertensive Crisis Triggers Immediate RED Triage (Requirement 19.2) ──
    test('19.2: Hypertensive Crisis (BP >= 180/110) triggers RED flag, 108 ambulance, and P1 sync alert', () async {
      final assessment = await repo.recordCbacScreening(
        memberId: 'member_sohan_1',
        tobaccoUse: TobaccoUse.never,
        alcoholConsumption: AlcoholConsumption.no,
        waistCircumferenceCm: 85.0,
        physicalActivity: PhysicalActivity.atLeast150Mins,
        familyHistory: FamilyHistoryNcd.no,
        warningSigns: const CancerWarningSigns(),
        systolicBp: 190,
        diastolicBp: 115,
        ashaId: 'asha_01',
      );

      expect(assessment.triageFlag, equals(TriageFlag.red));
      expect(assessment.bpCategory, equals(BloodPressureCategory.hypertensiveCrisis));
      expect(assessment.clinicalFindings.any((f) => f.contains('Hypertensive Crisis')), isTrue);

      // Verify ReferralRecord transport is 108_AMBULANCE
      final referrals = await (db.select(db.referralRecords)..where((t) => t.encounterId.equals(assessment.id))).get();
      expect(referrals.first.triageFlag, equals('RED'));
      expect(referrals.first.transportArranged, equals('108_AMBULANCE'));

      // Verify Critical P1 sync alert enqueued
      final syncItems = await (db.select(db.syncQueue)..where((t) => t.recordId.equals(referrals.first.id))).get();
      expect(syncItems.any((item) => item.priority == 1), isTrue);
    });

    // ── 6. NCD Chronic Care Patient Register (Requirement 19.4) ────────────────
    test('19.4: Enrols confirmed patient, schedules monthly adherence checks and 30-day refill reminders', () async {
      final patient = await repo.enrolNcdPatient(
        memberId: 'member_sohan_1',
        diagnosis: NcdDiagnosisType.hypertension,
        prescribedMedications: ['Amlodipine 5mg OD', 'Telmisartan 40mg OD'],
        ashaId: 'asha_01',
      );

      expect(patient.diagnosis, equals(NcdDiagnosisType.hypertension));
      expect(patient.prescribedMedications.length, equals(2));

      // Verify 30-day Refill Reminder in visit_schedules
      final schedules = await (db.select(db.visitSchedules)..where((t) => t.memberId.equals('member_sohan_1'))).get();
      final refillTask = schedules.firstWhere((s) => s.visitType.contains('Medication Refill Reminder'));
      final checkupTask = schedules.firstWhere((s) => s.visitType.contains('Monthly Adherence'));

      expect(refillTask.status, equals('pending'));
      expect(checkupTask.status, equals('pending'));

      final diffDays = (refillTask.dueDate - DateTime.now().millisecondsSinceEpoch) / (24 * 3600 * 1000);
      expect(diffDays, closeTo(30, 0.5));
    });

    // ── 7. Follow-Up Visit & Repeat Measurements (Requirement 19.4) ────────────
    test('19.4: Records follow-up repeat BP/glucose, marks adherence check completed, and sets next refill date', () async {
      // First enrol
      await repo.enrolNcdPatient(
        memberId: 'member_sohan_1',
        diagnosis: NcdDiagnosisType.hypertension,
        prescribedMedications: ['Amlodipine 5mg OD'],
        ashaId: 'asha_01',
      );

      // Now record follow-up visit
      final followUp = await repo.recordFollowUpVisit(
        memberId: 'member_sohan_1',
        systolicBp: 128,
        diastolicBp: 82,
        bloodGlucoseMgDl: 104.0,
        glucoseType: GlucoseType.fasting,
        adherence: MedicationAdherence.regular,
        medicinesRefilled: true,
        daysOfRefillProvided: 30,
        ashaId: 'asha_01',
      );

      expect(followUp.adherence, equals(MedicationAdherence.regular));
      expect(followUp.medicinesRefilled, isTrue);

      // Verify clinical encounter was recorded
      final enc = await (db.select(db.clinicalEncounters)..where((t) => t.id.equals(followUp.encounterId))).getSingle();
      expect(enc.encounterType, equals('NCD_FOLLOW_UP'));

      // Verify observations recorded
      final obs = await (db.select(db.clinicalObservations)..where((t) => t.encounterId.equals(followUp.encounterId))).get();
      final obsMap = {for (final o in obs) o.observationCode: o};
      expect(obsMap['SYSTOLIC_BP']?.valueNumeric, equals(128.0));
      expect(obsMap['MEDICATION_ADHERENCE']?.valueText, equals('regular'));
      expect(obsMap['MEDICINES_REFILLED']?.valueEnum, equals('YES'));
    });

    // ── 8. Overdue Defaulter Tracing Tasks (Requirement 19.5) ──────────────────
    test('19.5: Identifies patients overdue > 14 days and generates urgent tracing tasks in due list', () async {
      // Enrol patient
      await repo.enrolNcdPatient(
        memberId: 'member_sohan_1',
        diagnosis: NcdDiagnosisType.diabetes,
        prescribedMedications: ['Metformin 500mg BD'],
        ashaId: 'asha_01',
      );

      // Artificially age the refill schedule to be 20 days overdue
      final overdueMs = DateTime.now().subtract(const Duration(days: 20)).millisecondsSinceEpoch;
      await (db.update(db.visitSchedules)..where((t) => t.memberId.equals('member_sohan_1') & t.visitType.like('%Refill%'))).write(
        VisitSchedulesCompanion(
          dueDate: Value(overdueMs),
        ),
      );

      // Generate overdue tracing tasks
      final tracingTasks = await repo.generateOverdueTracingTasks(overdueDaysThreshold: 14);
      expect(tracingTasks.isNotEmpty, isTrue);
      expect(tracingTasks.first.visitType, contains('URGENT NCD Tracing'));
      expect(tracingTasks.first.memberId, equals('member_sohan_1'));
    });

    // ── 9. National NCD Portal CSV Export (Requirement 19.6, 35) ────────────────
    test('19.6: Exports CBAC screening records in exact National NCD Portal CSV format', () async {
      // Record a screening
      await repo.recordCbacScreening(
        memberId: 'member_kamla_1',
        tobaccoUse: TobaccoUse.never,
        alcoholConsumption: AlcoholConsumption.no,
        waistCircumferenceCm: 84.0,
        physicalActivity: PhysicalActivity.atLeast150Mins,
        familyHistory: FamilyHistoryNcd.no,
        warningSigns: const CancerWarningSigns(),
        systolicBp: 122,
        diastolicBp: 80,
        ashaId: 'asha_01',
      );

      final csvContent = await repo.exportNationalNcdPortalCsv();
      expect(csvContent.isNotEmpty, isTrue);

      final lines = csvContent.trim().split('\n');
      expect(lines.length, greaterThanOrEqualTo(2)); // Header + at least 1 record

      // Check header columns
      final header = lines.first;
      expect(header, contains('Beneficiary_ID'));
      expect(header, contains('CBAC_Score'));
      expect(header, contains('Systolic_BP'));
      expect(header, contains('Oral_Cancer_Signs'));
      expect(header, contains('Screened_By_ASHA'));

      // Check data row
      final dataRow = lines[1];
      expect(dataRow, contains('member_kamla_1'));
      expect(dataRow, contains('Kamla Devi'));
      expect(dataRow, contains('122'));
      expect(dataRow, contains('80'));
    });
  });
}
