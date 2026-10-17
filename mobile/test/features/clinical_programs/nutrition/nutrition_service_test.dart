import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart' hide TriageResult;
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/features/clinical_programs/nutrition/data/nutrition_repository.dart';
import 'package:asha_platform/features/clinical_programs/nutrition/domain/growth_models.dart';
import 'package:asha_platform/features/clinical_programs/nutrition/domain/who_growth_calculator.dart';

void main() {
  group('Task 10.2: WHO Growth Standards & Malnutrition Classification (Requirements 17.1 – 17.6)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late NutritionRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      repo = NutritionRepository(db, syncEngine);

      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed Household
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_nut_1',
              village: 'Rampur',
              hamlet: const Value('South Hamlet'),
              headName: 'Kailash Devi',
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      // Seed Child Member: Boy born 12 months ago
      final twelveMonthsAgo = DateTime.now().subtract(const Duration(days: 365)).millisecondsSinceEpoch;
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'child_kabir_1',
              householdId: 'hh_nut_1',
              name: 'Kabir Kumar',
              sex: 'M',
              dobApprox: Value(twelveMonthsAgo),
              relationshipToHead: const Value('Son'),
              phone: const Value('9876543210'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      // Seed Child Member: Girl born 24 months ago
      final twentyFourMonthsAgo = DateTime.now().subtract(const Duration(days: 730)).millisecondsSinceEpoch;
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'child_ananya_1',
              householdId: 'hh_nut_1',
              name: 'Ananya Kumari',
              sex: 'F',
              dobApprox: Value(twentyFourMonthsAgo),
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

    // ── 1. SQLite Standard Table Embedding (Requirement 17.1) ─────────────────
    test('17.1: Seeds SQLite who_growth_standards table with LMS reference data', () async {
      await repo.ensureSqliteStandardsTablePopulated();

      final countResult = await db.customSelect('SELECT COUNT(*) as count FROM who_growth_standards').getSingle();
      final totalRows = countResult.read<int>('count');
      expect(totalRows, equals(98));

      // Query WAZ median for newborn boy (x=0)
      final newbornRow = await db.customSelect(
        'SELECT * FROM who_growth_standards WHERE standard_type = ? AND sex = ? AND x_value = ?',
        variables: [const Variable('WAZ'), const Variable('M'), const Variable(0.0)],
      ).getSingle();

      final medianM = newbornRow.read<double>('m_value');
      expect(medianM, closeTo(3.346, 0.05));

      // Re-running ensureSqliteStandardsTablePopulated is idempotent and does not fail or duplicate
      await repo.ensureSqliteStandardsTablePopulated();
      final countResult2 = await db.customSelect('SELECT COUNT(*) as count FROM who_growth_standards').getSingle();
      expect(countResult2.read<int>('count'), equals(totalRows));
    });

    // ── 2. WHO Z-score Calculation Accuracy (Requirement 17.1) ────────────────
    test('17.1: Calculates accurate WAZ, HAZ, and WFHZ Z-scores against WHO standards', () {
      // 1. Newborn Boy (0m): Weight 3.35 kg (at median M=3.346) -> WAZ should be ~0.0 SD
      final wazNewbornBoy = WhoGrowthCalculator.calculateWaz(
        weightKg: 3.346,
        ageMonths: 0,
        sex: 'M',
      );
      expect(wazNewbornBoy, closeTo(0.0, 0.05));

      // 2. 12-month Boy: Median weight is ~9.6 kg
      final waz12mMedianBoy = WhoGrowthCalculator.calculateWaz(
        weightKg: 9.6,
        ageMonths: 12,
        sex: 'M',
      );
      expect(waz12mMedianBoy, closeTo(0.0, 0.2));

      // 3. 24-month Girl: Median height is ~86.44 cm -> HAZ ~ 0.0 SD
      final haz24mMedianGirl = WhoGrowthCalculator.calculateHaz(
        heightCm: 86.44,
        ageMonths: 24,
        sex: 'F',
      );
      expect(haz24mMedianGirl, closeTo(0.0, 0.05));

      // 4. Boy with height 75 cm: Median weight is ~9.683 kg -> WFHZ ~ 0.0 SD
      final wfhz75cmBoy = WhoGrowthCalculator.calculateWfhz(
        weightKg: 9.683,
        heightCm: 75.0,
        sex: 'M',
      );
      expect(wfhz75cmBoy, closeTo(0.0, 0.05));

      // 5. Boy with height 75 cm but weight only 7.2 kg -> Severely wasted (WFHZ < -3.0 SD)
      final wfhzWastedBoy = WhoGrowthCalculator.calculateWfhz(
        weightKg: 7.2,
        heightCm: 75.0,
        sex: 'M',
      );
      expect(wfhzWastedBoy, lessThan(-3.0));
    });

    // ── 3. MUAC & Anaemia Classification (Requirements 17.2, 17.5) ─────────────
    test('17.2 & 17.5: Accurately classifies MUAC and Anaemia severity per MoHFW guidelines', () {
      // MUAC for children >= 6m
      expect(WhoGrowthCalculator.classifyMuac(11.2, ageMonths: 12), equals(MuacClassification.sam));
      expect(WhoGrowthCalculator.classifyMuac(11.4, ageMonths: 12), equals(MuacClassification.sam));
      expect(WhoGrowthCalculator.classifyMuac(11.5, ageMonths: 12), equals(MuacClassification.mam));
      expect(WhoGrowthCalculator.classifyMuac(12.4, ageMonths: 12), equals(MuacClassification.mam));
      expect(WhoGrowthCalculator.classifyMuac(12.5, ageMonths: 12), equals(MuacClassification.normal));
      expect(WhoGrowthCalculator.classifyMuac(14.0, ageMonths: 12), equals(MuacClassification.normal));

      // MUAC for infants < 6m (<11.0 cm SAM, 11.0-11.9 MAM, >=12.0 Normal)
      expect(WhoGrowthCalculator.classifyMuac(10.8, ageMonths: 4), equals(MuacClassification.sam));
      expect(WhoGrowthCalculator.classifyMuac(11.5, ageMonths: 4), equals(MuacClassification.mam));
      expect(WhoGrowthCalculator.classifyMuac(12.2, ageMonths: 4), equals(MuacClassification.normal));

      // Anaemia in children 6-59 months
      expect(WhoGrowthCalculator.classifyAnaemia(haemoglobinGdl: 6.5, ageMonths: 18, sex: 'M'), equals(AnaemiaSeverity.severe));
      expect(WhoGrowthCalculator.classifyAnaemia(haemoglobinGdl: 8.5, ageMonths: 18, sex: 'M'), equals(AnaemiaSeverity.moderate));
      expect(WhoGrowthCalculator.classifyAnaemia(haemoglobinGdl: 10.5, ageMonths: 18, sex: 'M'), equals(AnaemiaSeverity.mild));
      expect(WhoGrowthCalculator.classifyAnaemia(haemoglobinGdl: 11.5, ageMonths: 18, sex: 'M'), equals(AnaemiaSeverity.none));

      // Anaemia in pregnant women
      expect(WhoGrowthCalculator.classifyAnaemia(haemoglobinGdl: 6.8, ageMonths: 260, sex: 'F', isPregnant: true), equals(AnaemiaSeverity.severe));
      expect(WhoGrowthCalculator.classifyAnaemia(haemoglobinGdl: 9.2, ageMonths: 260, sex: 'F', isPregnant: true), equals(AnaemiaSeverity.moderate));
      expect(WhoGrowthCalculator.classifyAnaemia(haemoglobinGdl: 10.4, ageMonths: 260, sex: 'F', isPregnant: true), equals(AnaemiaSeverity.mild));
      expect(WhoGrowthCalculator.classifyAnaemia(haemoglobinGdl: 11.8, ageMonths: 260, sex: 'F', isPregnant: true), equals(AnaemiaSeverity.none));
    });

    // ── 4. SAM Detection & Emergency NRC Referral (Requirements 17.2, 17.3) ─────
    test('17.2 & 17.3: SAM detection triggers RED triage flag, emergency NRC referral, and P1 sync alert', () async {
      // 12-month boy Kabir: Height 75 cm, severe wasting weight 7.0 kg, MUAC 11.2 cm, appetite test failed
      final measurement = await repo.recordGrowthMeasurement(
        memberId: 'child_kabir_1',
        weightKg: 7.0,
        heightCm: 75.0,
        muacCm: 11.2,
        bilateralOedema: false,
        appetiteTestPassed: false,
        ashaId: 'asha_01',
      );

      expect(measurement.wastingStatus, equals(WastingStatus.sam));
      expect(measurement.triageFlag, equals(TriageFlag.red));
      expect(measurement.wfhz, isNotNull);
      expect(measurement.wfhz!, lessThan(-3.0));
      expect(measurement.emergencyReferralRequired, isTrue);
      expect(measurement.clinicalFindings.any((f) => f.contains('SAM')), isTrue);
      expect(measurement.clinicalFindings.any((f) => f.contains('Appetite test failed')), isTrue);

      // Verify discrete clinical observations in DB
      final obs = await (db.select(db.clinicalObservations)..where((t) => t.encounterId.equals(measurement.id))).get();
      final obsMap = {for (final o in obs) o.observationCode: o};
      expect(obsMap['WEIGHT_KG']?.valueNumeric, equals(7.0));
      expect(obsMap['HEIGHT_CM']?.valueNumeric, equals(75.0));
      expect(obsMap['MUAC_CM']?.valueNumeric, equals(11.2));
      expect(obsMap['WASTING_STATUS']?.valueText, equals('sam'));
      expect(obsMap['APPETITE_TEST']?.valueEnum, equals('FAILED'));

      // Verify TriageResults table has RED flag
      final triage = await (db.select(db.triageResults)..where((t) => t.encounterId.equals(measurement.id))).getSingle();
      expect(triage.flag, equals('RED'));

      // Verify Emergency Referral Record created in referral_records
      final referrals = await (db.select(db.referralRecords)..where((t) => t.memberId.equals('child_kabir_1'))).get();
      expect(referrals.isNotEmpty, isTrue);
      final ref = referrals.first;
      expect(ref.triageFlag, equals('RED'));
      expect(ref.destinationLevel, equals('NRC_CHC'));
      expect(ref.transportArranged, equals('108_AMBULANCE'));
      expect(ref.referralNoteText, contains('URGENT MALNUTRITION'));

      // Verify Critical P1 Sync alert enqueued
      final syncItems = await (db.select(db.syncQueue)..where((t) => t.recordId.equals(measurement.id))).get();
      expect(syncItems.any((item) => item.priority == 1), isTrue); // P1 Critical
    });

    // ── 5. Bilateral Pitting Oedema triggers RED Flag immediately (Requirement 17.2) ──
    test('17.2: Bilateral pitting oedema (+/++) triggers RED flag even if weight appears normal', () async {
      // Normal weight 10.0kg at 12 months, but with bilateral oedema
      final measurement = await repo.recordGrowthMeasurement(
        memberId: 'child_kabir_1',
        weightKg: 10.0,
        heightCm: 76.0,
        muacCm: 13.5,
        bilateralOedema: true,
        ashaId: 'asha_01',
      );

      expect(measurement.bilateralOedema, isTrue);
      expect(measurement.wastingStatus, equals(WastingStatus.sam));
      expect(measurement.triageFlag, equals(TriageFlag.red));
      expect(measurement.emergencyReferralRequired, isTrue);
      expect(measurement.clinicalFindings.any((f) => f.contains('Bilateral pitting oedema')), isTrue);
    });

    // ── 6. MAM Detection & Anganwadi Linkage (Requirement 17.4) ────────────────
    test('17.4: MAM detection triggers YELLOW triage, Anganwadi linkage, and bi-weekly follow-up visit', () async {
      // 24-month girl Ananya: Height 85 cm, weight 9.8 kg, MUAC 12.0 cm -> MAM (-3 <= WFHZ < -2)
      final measurement = await repo.recordGrowthMeasurement(
        memberId: 'child_ananya_1',
        weightKg: 9.8,
        heightCm: 85.0,
        muacCm: 12.0,
        bilateralOedema: false,
        ashaId: 'asha_01',
      );

      expect(measurement.wastingStatus, equals(WastingStatus.mam));
      expect(measurement.triageFlag, equals(TriageFlag.yellow));
      expect(measurement.recommendedActions.any((a) => a.contains('LINK_TO_ANGANWADI')), isTrue);

      // Verify TriageResults
      final triage = await (db.select(db.triageResults)..where((t) => t.encounterId.equals(measurement.id))).getSingle();
      expect(triage.flag, equals('YELLOW'));

      // Verify Bi-Weekly Follow-up scheduled in visit_schedules
      final schedules = await (db.select(db.visitSchedules)..where((t) => t.memberId.equals('child_ananya_1'))).get();
      expect(schedules.isNotEmpty, isTrue);
      final followUp = schedules.firstWhere((s) => s.visitType.contains('MAM Bi-Weekly'));
      expect(followUp.status, equals('pending'));

      // Follow-up due date is 14 days later
      final diffDays = (followUp.dueDate - DateTime.now().millisecondsSinceEpoch) / (24 * 60 * 60 * 1000);
      expect(diffDays, closeTo(14, 0.5));
    });

    // ── 7. Supplementation Recording (Requirement 17.5) ─────────────────────────
    test('17.5: Records IFA, Vitamin A, and Albendazole deworming supplementation doses', () async {
      // Record Vitamin A bi-annual dose
      final vitaRecord = await repo.recordSupplementation(
        memberId: 'child_kabir_1',
        type: SupplementType.vitaminA,
        doseAmount: '100,000 IU (1 ml)',
        ashaId: 'asha_01',
        notes: 'Administered during bi-annual mop-up round',
      );

      expect(vitaRecord.supplementType, equals(SupplementType.vitaminA));
      expect(vitaRecord.doseAmount, equals('100,000 IU (1 ml)'));

      // Check ClinicalEncounters & Observations
      final enc = await (db.select(db.clinicalEncounters)..where((t) => t.encounterType.equals('SUPPLEMENTATION_DOSE'))).getSingle();
      expect(enc.programCode, equals('nutrition'));
      expect(enc.status, equals('completed'));

      final obs = await (db.select(db.clinicalObservations)..where((t) => t.encounterId.equals(enc.id))).get();
      final obsType = obs.firstWhere((o) => o.observationCode == 'SUPPLEMENT_TYPE').valueText;
      final obsDose = obs.firstWhere((o) => o.observationCode == 'DOSE_AMOUNT').valueText;
      expect(obsType, equals('vitaminA'));
      expect(obsDose, equals('100,000 IU (1 ml)'));

      // Record Deworming dose
      final albRecord = await repo.recordSupplementation(
        memberId: 'child_kabir_1',
        type: SupplementType.albendazoleDeworming,
        doseAmount: '400 mg single tablet',
        ashaId: 'asha_01',
      );
      expect(albRecord.supplementType, equals(SupplementType.albendazoleDeworming));
    });

    // ── 8. Growth History Trajectory (Requirement 17.6) ─────────────────────────
    test('17.6: Retrieves sequential growth history for plotting on WHO growth chart', () async {
      final now = DateTime.now();

      // Month 1 measurement
      await repo.recordGrowthMeasurement(
        memberId: 'child_kabir_1',
        weightKg: 8.5,
        heightCm: 72.0,
        ashaId: 'asha_01',
        measuredAt: now.subtract(const Duration(days: 60)),
      );

      // Month 2 measurement
      await repo.recordGrowthMeasurement(
        memberId: 'child_kabir_1',
        weightKg: 9.0,
        heightCm: 74.0,
        ashaId: 'asha_01',
        measuredAt: now.subtract(const Duration(days: 30)),
      );

      // Month 3 measurement
      await repo.recordGrowthMeasurement(
        memberId: 'child_kabir_1',
        weightKg: 9.6,
        heightCm: 75.5,
        ashaId: 'asha_01',
        measuredAt: now,
      );

      final history = await repo.getGrowthHistory('child_kabir_1');
      expect(history.length, equals(3));
      expect(history[0].weightKg, equals(8.5));
      expect(history[1].weightKg, equals(9.0));
      expect(history[2].weightKg, equals(9.6));

      // Trajectory is improving WAZ
      expect(history[2].waz, greaterThan(history[0].waz));
    });

    // ── 9. Malnutrition Exit Criteria Tracking (Requirement 17.6) ──────────────
    test('17.6: Tracks CMAM / NRC exit criteria (Cured, Defaulted, Non-responder)', () async {
      // 1. Visit 1 with normal indicators (WFHZ >= -2 and MUAC >= 12.5 cm) -> consecutive cures = 1, still in treatment (returns null)
      final outcome1 = await repo.evaluateMalnutritionVisit(
        memberId: 'child_kabir_1',
        weightKg: 9.8,
        heightCm: 75.0,
        muacCm: 12.8,
        consecutiveCureVisitsSoFar: 0,
        weeksInProgramme: 6,
      );
      expect(outcome1, isNull);

      // 2. Visit 2 with normal indicators -> consecutive cures = 2 -> CURED!
      final outcome2 = await repo.evaluateMalnutritionVisit(
        memberId: 'child_kabir_1',
        weightKg: 10.0,
        heightCm: 75.2,
        muacCm: 13.0,
        consecutiveCureVisitsSoFar: 1,
        weeksInProgramme: 7,
      );
      expect(outcome2, equals(MalnutritionExitOutcome.cured));

      // 3. Child missed 2 consecutive follow-up visits -> DEFAULTED
      final outcomeDefault = await repo.evaluateMalnutritionVisit(
        memberId: 'child_kabir_1',
        weightKg: 8.0,
        missedTwoConsecutiveVisits: true,
      );
      expect(outcomeDefault, equals(MalnutritionExitOutcome.defaulted));

      // 4. Beneficiary in programme for 16 weeks without reaching cure -> NON-RESPONDER
      final outcomeNonResp = await repo.evaluateMalnutritionVisit(
        memberId: 'child_kabir_1',
        weightKg: 8.2,
        heightCm: 75.0,
        muacCm: 11.8, // Still MAM
        consecutiveCureVisitsSoFar: 0,
        weeksInProgramme: 16,
      );
      expect(outcomeNonResp, equals(MalnutritionExitOutcome.nonResponder));

      // 5. Deceased child -> DIED
      final outcomeDied = await repo.evaluateMalnutritionVisit(
        memberId: 'child_kabir_1',
        weightKg: 8.0,
        isDeceased: true,
      );
      expect(outcomeDied, equals(MalnutritionExitOutcome.died));
    });
  });
}
