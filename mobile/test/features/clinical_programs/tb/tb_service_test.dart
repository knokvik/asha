import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart' hide TriageResult;
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/features/clinical_programs/tb/data/tb_repository.dart';
import 'package:asha_platform/features/clinical_programs/tb/domain/tb_models.dart';

void main() {
  group('Task 10.4 & 10.6: TB Support, Adherence Monitoring & Privacy Protections (Requirements 20.1 – 20.8)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late TbRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      repo = TbRepository(db, syncEngine);

      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed Household
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_tb_1',
              village: 'Rampur',
              hamlet: const Value('North Hamlet'),
              headName: 'Vijay Singh',
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      // Seed Adult Member: Male 38 years old (Index patient)
      final thirtyEightYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 38)).millisecondsSinceEpoch;
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'member_vijay_1',
              householdId: 'hh_tb_1',
              name: 'Vijay Singh',
              sex: 'M',
              dobApprox: Value(thirtyEightYearsAgo),
              relationshipToHead: const Value('Self'),
              phone: const Value('9811122233'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      // Seed Child Member: 3 years old (Household contact)
      final threeYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 3)).millisecondsSinceEpoch;
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'child_rohit_1',
              householdId: 'hh_tb_1',
              name: 'Rohit Singh',
              sex: 'M',
              dobApprox: Value(threeYearsAgo),
              relationshipToHead: const Value('Son'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      // Seed Wife Member: 32 years old (Household contact)
      final thirtyTwoYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 32)).millisecondsSinceEpoch;
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'wife_shanti_1',
              householdId: 'hh_tb_1',
              name: 'Shanti Devi',
              sex: 'F',
              dobApprox: Value(thirtyTwoYearsAgo),
              relationshipToHead: const Value('Wife'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      // Seed Brother Member: 22 years old (Household contact)
      final twentyTwoYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 22)).millisecondsSinceEpoch;
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'member_symptomatic_1',
              householdId: 'hh_tb_1',
              name: 'Ravi Singh',
              sex: 'M',
              dobApprox: Value(twentyTwoYearsAgo),
              relationshipToHead: const Value('Brother'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. Presumptive TB Screening (Requirement 20.1) ─────────────────────────
    test('20.1: Identifies presumptive TB case (cough >= 2 weeks, fever), generates DMC referral and sputum task', () async {
      final assessment = await repo.recordPresumptiveTbScreening(
        memberId: 'member_vijay_1',
        coughGt2Weeks: true,
        feverGt2Weeks: true,
        unexplainedWeightLoss: true,
        nightSweats: true,
        haemoptysis: false,
        ashaId: 'asha_01',
      );

      expect(assessment.isPresumptiveTb, isTrue);
      expect(assessment.triageFlag, equals(TriageFlag.yellow));
      expect(assessment.clinicalFindings.any((f) => f.contains('cough of 2 or more weeks')), isTrue);
      expect(assessment.recommendedActions.any((a) => a.contains('Collect 2 sputum samples')), isTrue);

      // Verify discrete observations in DB
      final obs = await (db.select(db.clinicalObservations)..where((t) => t.encounterId.equals(assessment.id))).get();
      final obsMap = {for (final o in obs) o.observationCode: o};
      expect(obsMap['IS_PRESUMPTIVE_TB']?.valueEnum, equals('YES'));
      expect(obsMap['COUGH_GT_2W']?.valueEnum, equals('YES'));
      expect(obsMap['FEVER_GT_2W']?.valueEnum, equals('YES'));

      // Verify ReferralRecord created
      final referrals = await (db.select(db.referralRecords)..where((t) => t.memberId.equals('member_vijay_1'))).get();
      expect(referrals.isNotEmpty, isTrue);
      expect(referrals.first.destinationLevel, equals('DMC_CHC'));

      // Verify Sputum follow-up task scheduled in visit_schedules
      final schedules = await (db.select(db.visitSchedules)..where((t) => t.memberId.equals('member_vijay_1'))).get();
      expect(schedules.any((s) => s.visitType.contains('Sputum Sample Collection')), isTrue);

      // Verify IncentiveEvent recorded
      final incentives = await (db.select(db.incentiveEvents)..where((t) => t.memberId.equals('member_vijay_1'))).get();
      expect(incentives.isNotEmpty, isTrue);
      expect(incentives.first.activityCode, equals('TB_PRESUMPTIVE_REFERRAL'));
      expect(incentives.first.status, equals('eligible'));
    });

    // ── 2. Haemoptysis Triggers Urgent RED Triage (Requirement 20.1) ───────────
    test('20.1: Haemoptysis (blood in sputum) triggers RED flag, 108 ambulance, and P1 critical sync', () async {
      final assessment = await repo.recordPresumptiveTbScreening(
        memberId: 'member_vijay_1',
        haemoptysis: true,
        coughGt2Weeks: true,
        ashaId: 'asha_01',
      );

      expect(assessment.triageFlag, equals(TriageFlag.red));
      expect(assessment.clinicalFindings.any((f) => f.contains('Haemoptysis')), isTrue);

      // Verify emergency referral with 108 transport
      final referrals = await (db.select(db.referralRecords)..where((t) => t.encounterId.equals(assessment.id))).get();
      expect(referrals.first.triageFlag, equals('RED'));
      expect(referrals.first.transportArranged, equals('108_AMBULANCE'));

      // Verify Critical P1 sync alert enqueued
      final syncItems = await (db.select(db.syncQueue)..where((t) => t.recordId.equals(referrals.first.id))).get();
      expect(syncItems.any((item) => item.priority == 1), isTrue);
    });

    // ── 3. Sputum Sample Tracking & Lab Results (Requirement 20.2) ──────────────
    test('20.2: Records sputum sample collection and updates diagnostic test results', () async {
      // Record sample collection
      final sample = await repo.recordSputumSample(
        memberId: 'member_vijay_1',
        sampleId: 'SP-RAM-2026-0042',
        collectionSite: 'Rampur Sub-Centre',
        transportStatus: SputumTransportStatus.inTransitToDmc,
        ashaId: 'asha_01',
      );

      expect(sample.sampleId, equals('SP-RAM-2026-0042'));
      expect(sample.transportStatus, equals(SputumTransportStatus.inTransitToDmc));

      // Update with NAAT lab test result
      final updatedSample = await repo.updateSputumTestResult(
        sampleId: sample.sampleId,
        memberId: 'member_vijay_1',
        testResult: SputumTestResult.naatMtbDetectedSensitive,
        labName: 'District Hospital Truenat Lab',
        ashaId: 'asha_01',
      );

      expect(updatedSample.testResult, equals(SputumTestResult.naatMtbDetectedSensitive));
      expect(updatedSample.testResult.isPositive, isTrue);

      // Positive result prompts urgent treatment initiation task in visit_schedules
      final schedules = await (db.select(db.visitSchedules)..where((t) => t.memberId.equals('member_vijay_1'))).get();
      expect(schedules.any((s) => s.visitType.contains('Initiate TB Treatment')), isTrue);
    });

    // ── 4. TB Treatment Registration (Requirement 20.3) ────────────────────────
    test('20.3: Registers TB patient, records supporter, and schedules daily dose observation (DOTS)', () async {
      final patient = await repo.registerTbTreatment(
        memberId: 'member_vijay_1',
        nikshayId: 'NK-2026-889900',
        site: TbSite.pulmonary,
        regimen: TbRegimenType.dsTbDailyFdc,
        treatmentSupporterName: 'Shanti Devi',
        treatmentSupporterPhone: '9811122244',
        supporterRelationship: 'Wife',
        totalDosesPrescribed: 168,
        ashaId: 'asha_01',
      );

      expect(patient.nikshayId, equals('NK-2026-889900'));
      expect(patient.regimen, equals(TbRegimenType.dsTbDailyFdc));
      expect(patient.treatmentSupporterName, equals('Shanti Devi'));

      // Check daily dose observation task scheduled
      final schedules = await (db.select(db.visitSchedules)..where((t) => t.memberId.equals('member_vijay_1'))).get();
      expect(schedules.any((s) => s.visitType.contains('TB Daily Dose Observation')), isTrue);

      // Check incentive event written
      final incentives = await (db.select(db.incentiveEvents)..where((t) => t.memberId.equals('member_vijay_1'))).get();
      expect(incentives.any((i) => i.activityCode == 'TB_TREATMENT_SUPPORT_START'), isTrue);
    });

    // ── 5. Dose Observation & Consecutive-Miss Alerting (Requirement 20.4) ──────
    test('20.4: Three consecutive missed doses triggers URGENT ASHA alert and critical sync', () async {
      // Register treatment first
      await repo.registerTbTreatment(
        memberId: 'member_vijay_1',
        nikshayId: 'NK-2026-889900',
        treatmentSupporterName: 'Shanti Devi',
        treatmentSupporterPhone: '9811122244',
        supporterRelationship: 'Wife',
        ashaId: 'asha_01',
      );

      final now = DateTime.now();

      // Dose 1: Missed
      await repo.recordDoseObservation(
        memberId: 'member_vijay_1',
        status: DoseIntakeStatus.missed,
        doseDate: now.subtract(const Duration(days: 2)),
        ashaId: 'asha_01',
      );

      // Dose 2: Missed
      await repo.recordDoseObservation(
        memberId: 'member_vijay_1',
        status: DoseIntakeStatus.missed,
        doseDate: now.subtract(const Duration(days: 1)),
        ashaId: 'asha_01',
      );

      // Dose 3: Missed -> Hits threshold of 3 consecutive misses!
      await repo.recordDoseObservation(
        memberId: 'member_vijay_1',
        status: DoseIntakeStatus.missed,
        doseDate: now,
        ashaId: 'asha_01',
      );

      // Verify URGENT TB Defaulter Tracing task created in visit_schedules
      final schedules = await (db.select(db.visitSchedules)..where((t) => t.memberId.equals('member_vijay_1'))).get();
      final alertTask = schedules.firstWhere((s) => s.visitType.contains('URGENT TB Defaulter Tracing'));
      expect(alertTask.visitType, contains('3 Consecutive Missed Doses'));
      expect(alertTask.status, equals('pending'));

      // Verify Critical P1 sync alert enqueued for STS / TB Programme staff
      final syncItems = await (db.select(db.syncQueue)..where((t) => t.recordId.equals(alertTask.id))).get();
      expect(syncItems.isNotEmpty, isTrue);
      expect(syncItems.first.priority, equals(1)); // P1 Critical
    });

    // ── 6. Contact Tracing & TPT Eligibility (Requirement 20.5) ────────────────
    test('20.5: Screens household contacts and determines TPT eligibility per NTEP guidelines', () async {
      final contacts = [
        // Child 3 years old, asymptomatic -> ELIGIBLE for TPT (< 5 years)
        {
          'contact_id': 'child_rohit_1',
          'contact_name': 'Rohit Singh',
          'age_years': 3,
          'has_symptoms': false,
        },
        // Adult wife 32 years old, asymptomatic -> ELIGIBLE for TPT (asymptomatic contact)
        {
          'contact_id': 'wife_shanti_1',
          'contact_name': 'Shanti Devi',
          'age_years': 32,
          'has_symptoms': false,
        },
        // Hypothetical contact with cough -> NOT eligible for TPT yet (must test for active disease first)
        {
          'contact_id': 'member_symptomatic_1',
          'contact_name': 'Ravi Singh',
          'age_years': 22,
          'has_symptoms': true,
        },
      ];

      final results = await repo.screenHouseholdContacts(
        indexPatientMemberId: 'member_vijay_1',
        contactScreenings: contacts,
        ashaId: 'asha_01',
      );

      expect(results.length, equals(3));

      final rohit = results.firstWhere((r) => r.contactMemberId == 'child_rohit_1');
      expect(rohit.eligibleForTpt, isTrue);

      final shanti = results.firstWhere((r) => r.contactMemberId == 'wife_shanti_1');
      expect(shanti.eligibleForTpt, isTrue);

      final symptomatic = results.firstWhere((r) => r.contactMemberId == 'member_symptomatic_1');
      expect(symptomatic.eligibleForTpt, isFalse);

      // Verify TPT Initiation task was scheduled for Rohit in visit_schedules
      final schedules = await (db.select(db.visitSchedules)..where((t) => t.memberId.equals('child_rohit_1'))).get();
      expect(schedules.any((s) => s.visitType.contains('TB Preventive Therapy')), isTrue);
    });

    // ── 7. Ni-kshay Poshan Yojana DBT Linkage (Requirement 20.7) ───────────────
    test('20.7: Records Ni-kshay Poshan Yojana Rs 500/month DBT status', () async {
      await repo.linkNikshayPoshanYojana(
        memberId: 'member_vijay_1',
        status: NikshayPoshanStatus.installmentReceived,
        ashaId: 'asha_01',
      );

      final obs = await (db.select(db.clinicalObservations)
            ..where((t) => t.observationCode.equals('NIKSHAY_POSHAN_STATUS')))
          .getSingle();
      expect(obs.valueText, equals('installmentReceived'));
    });

    // ── 8. Anti-Stigma Privacy Protections (Requirement 20.8, Task 10.6) ────────
    test('20.8: Hides TB labels in shared-device view; preserves clinical terms in ASHA private view', () {
      const privateMode = TbPrivacyMode.ashaPrivateView;
      const sharedMode = TbPrivacyMode.sharedSupervisorView;

      // In ASHA private view, terms are unaltered
      expect(TbPrivacyFilter.filterTerm('Presumptive TB Screening', privateMode), equals('Presumptive TB Screening'));
      expect(TbPrivacyFilter.filterTerm('TB Treatment Card (DOTS)', privateMode), equals('TB Treatment Card (DOTS)'));
      expect(TbPrivacyFilter.filterTerm('Sputum Sample Collection', privateMode), equals('Sputum Sample Collection'));
      expect(TbPrivacyFilter.filterTerm('DOTS Supporter', privateMode), equals('DOTS Supporter'));
      expect(TbPrivacyFilter.filterTerm('Ni-kshay Poshan Yojana', privateMode), equals('Ni-kshay Poshan Yojana'));

      // In Shared-Device / Beneficiary view, terms are neutrally replaced to protect against stigma
      final sharedScreening = TbPrivacyFilter.filterTerm('Presumptive TB Screening', sharedMode);
      expect(sharedScreening, isNot(contains('TB')));
      expect(sharedScreening, contains('Chest Health Assessment'));

      final sharedTreatment = TbPrivacyFilter.filterTerm('TB Treatment Card (DOTS)', sharedMode);
      expect(sharedTreatment, isNot(contains('TB')));
      expect(sharedTreatment, isNot(contains('DOTS')));
      expect(sharedTreatment, contains('Respiratory Care'));
      expect(sharedTreatment, contains('Daily Therapy'));

      final sharedSputum = TbPrivacyFilter.filterTerm('Sputum Sample Collection', sharedMode);
      expect(sharedSputum, isNot(contains('Sputum')));
      expect(sharedSputum, contains('Respiratory Sample'));

      final sharedSupporter = TbPrivacyFilter.filterTerm('DOTS Supporter', sharedMode);
      expect(sharedSupporter, isNot(contains('DOTS')));
      expect(sharedSupporter, contains('Care Supporter'));
    });
  });
}
