import 'dart:convert';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/safety_and_compliance/ai_safety_service.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/features/clinical_programs/anc_pnc/data/anc_repository.dart';
import 'package:asha_platform/features/clinical_programs/anc_pnc/domain/anc_models.dart';
import 'package:asha_platform/features/clinical_programs/family_planning/domain/family_planning_models.dart';
import 'package:asha_platform/features/clinical_programs/family_planning/domain/family_planning_service.dart';
import 'package:asha_platform/features/clinical_programs/hbnc/data/hbnc_repository.dart';
import 'package:asha_platform/features/clinical_programs/immunization/data/immunization_repository.dart';
import 'package:asha_platform/features/clinical_programs/ncd/domain/cbac_calculator.dart';
import 'package:asha_platform/features/clinical_programs/ncd/domain/cbac_models.dart';
import 'package:asha_platform/features/incentives/data/claim_service.dart';
import 'package:asha_platform/features/incentives/domain/incentive_service.dart';
import 'package:asha_platform/features/referral/data/referral_repository.dart';
import 'package:asha_platform/features/referral/domain/referral_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 15.5: End-to-End System Integration Wiring (All Parts 1–11)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late AncRepository ancRepo;
    late HbncRepository hbncRepo;
    late ImmunizationRepository immuRepo;
    late ReferralRepository referralRepo;
    late FamilyPlanningService fpService;
    late AiSafetyService aiSafetyService;
    late IncentiveService incentiveService;
    late ClaimService claimService;

    const testWorkerId = 'worker_sunita_01';
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final testCatalogueJson = json.encode({
      'version_id': 'v1.0-mohfw',
      'state_code': 'DEFAULT',
      'effective_from': '2026-01-01T00:00:00.000Z',
      'items': [
        {
          'activity_code': 'ANC_REG_EARLY',
          'activity_name': 'Early ANC Registration',
          'rates': {'performance_incentive': 100.0, 'state_top_up': 50.0},
        },
        {
          'activity_code': 'INST_DELIVERY_ESCORT',
          'activity_name': 'Institutional Delivery Escort (JSY)',
          'rates': {'performance_incentive': 300.0, 'state_top_up': 300.0},
        },
        {
          'activity_code': 'HBNC_COMPLETE',
          'activity_name': 'Home-Based Newborn Care Complete',
          'rates': {'performance_incentive': 250.0, 'state_top_up': 50.0},
        },
        {
          'activity_code': 'FP_PPIUCD',
          'activity_name': 'Postpartum IUCD Motivation',
          'rates': {'performance_incentive': 150.0, 'state_top_up': 0.0},
        },
      ],
    });

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      hbncRepo = HbncRepository(db, syncEngine);
      ancRepo = AncRepository(db, syncEngine, hbncRepo);
      immuRepo = ImmunizationRepository(db, syncEngine);
      referralRepo = ReferralRepository(db, syncEngine);
      fpService = FamilyPlanningService(db);
      aiSafetyService = AiSafetyService();
      incentiveService = IncentiveService(db: db, syncEngine: syncEngine);
      incentiveService.loadCatalogueFromJson(testCatalogueJson);
      claimService = ClaimService(db: db, incentiveService: incentiveService, syncEngine: syncEngine);

      // Seed ASHA Worker
      await db.into(db.users).insert(
            UsersCompanion.insert(
              id: testWorkerId,
              name: 'Sunita Sharma',
              role: 'ASHA',
              ashaId: 'ASHA-001',
              areaVillage: const Value('Rampur'),
              areaSubcentre: const Value('Rampur SC'),
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );

      // Seed Household & Member
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_e2e_001',
              village: 'Rampur',
              headName: 'Ramesh Kumar',
              hamlet: const Value('Ward 2'),
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: testWorkerId,
            ),
          );

      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'mem_pooja_001',
              householdId: 'hh_e2e_001',
              name: 'Pooja Devi',
              sex: 'F',
              relationshipToHead: const Value('wife'),
              lifecycleStatus: const Value('active'),
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: testWorkerId,
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('Complete continuous clinical care journey: Reg -> Triage -> RED Referral -> Birth -> HBNC -> Immunization -> NCD -> FP -> Incentives -> Claim Voucher -> Dashboard Sync Queue', () async {
      // 1. Early ANC Registration (< 12 weeks)
      final lmpDate = now.subtract(const Duration(days: 60)); // ~8.5 weeks pregnant
      final pregnancyReg = PregnancyRegistration(
        womanId: 'mem_pooja_001',
        lmp: lmpDate,
        gravida: 1,
        para: 0,
        mcpCardNumber: 'MCP-E2E-001',
        rchId: 'RCH-E2E-001',
        maternalAgeYears: 24,
      );

      await ancRepo.registerPregnancy(registration: pregnancyReg, ashaId: testWorkerId);

      final ancSchedules = await (db.select(db.visitSchedules)
            ..where((t) => t.memberId.equals('mem_pooja_001') & t.programCode.equals('anc')))
          .get();
      expect(ancSchedules.isNotEmpty, isTrue);

      // Early ANC registration incentive
      await db.into(db.incentiveEvents).insert(
            IncentiveEventsCompanion.insert(
              id: 'inc_anc_$nowMs',
              memberId: 'mem_pooja_001',
              activityCode: 'ANC_REG_EARLY',
              catalogueVersionId: 'v1.0-mohfw',
              eventDate: nowMs,
              status: const Value('eligible'),
              createdAt: nowMs,
              idempotencyKey: 'anc_reg_early_mem_pooja_001',
            ),
          );

      // 2. CDSS Triage Check with AI Safety Wrapper
      final suggestion = aiSafetyService.wrapCdssSuggestion(
        ruleId: 'rule_maternal_severe_preeclampsia',
        suggestedSeverity: TriageSeverity.red,
        rationale: 'Systolic BP >= 160 mmHg with severe headache',
        userEnteredObservations: ['BP: 165/110 mmHg', 'Severe headache', 'Gestational age: 34 weeks'],
      );
      expect(suggestion.isDecisionSupport, isTrue);

      // 3. Structured Referral Note & Emergency Transfer
      final note = StructuredReferralNote(
        referralId: 'ref_e2e_$nowMs',
        encounterId: 'enc_e2e_$nowMs',
        patient: const ReferralPatientInfo(
          memberId: 'mem_pooja_001',
          name: 'Pooja Devi',
          sex: 'F',
          ageInDays: 24 * 365,
          village: 'Rampur',
          contactPhone: '9876543210',
        ),
        triageFlag: TriageFlag.red,
        primaryReason: 'Severe pre-eclampsia with headache and hypertension',
        triggeringReasons: const ['BP 165/110', 'Visual blurring'],
        destinationFacility: const FacilityInfo(
          id: 'fac_chc_rampur',
          name: 'Rampur Community Health Centre',
          level: FacilityLevel.chc,
          distanceKm: 8.5,
        ),
        transportArranged: '108 Emergency Ambulance',
        createdAt: now,
        asha: const ReferralAshaInfo(
          id: testWorkerId,
          name: 'Sunita Sharma',
          phone: '9876500000',
        ),
      );

      final referralRecord = await referralRepo.createReferral(
        note: note,
        transportArranged: '108 Emergency Ambulance',
      );
      expect(referralRecord.status, 'created');

      // 4. Referral Transit & Outcome
      await referralRepo.updateStatus(
        referralId: referralRecord.id,
        newStatus: ReferralStatus.arrived,
      );
      await referralRepo.recordOutcome(
        referralId: referralRecord.id,
        outcomeType: OutcomeType.admitted,
        recordedBy: 'dr_kumar_mo',
        notes: 'Mother stabilized and delivered healthy infant via normal delivery at CHC.',
      );

      final updatedRef = await referralRepo.getReferral(referralRecord.id);
      expect(updatedRef?.status, 'outcome_recorded');

      // Institutional delivery escort incentive
      await db.into(db.incentiveEvents).insert(
            IncentiveEventsCompanion.insert(
              id: 'inc_deliv_$nowMs',
              memberId: 'mem_pooja_001',
              activityCode: 'INST_DELIVERY_ESCORT',
              catalogueVersionId: 'v1.0-mohfw',
              eventDate: nowMs,
              status: const Value('eligible'),
              createdAt: nowMs,
              idempotencyKey: 'inst_deliv_mem_pooja_001',
            ),
          );

      // 5. Live Birth Delivery Outcome -> Cancels ANC, Generates HBNC Schedule
      final outcome = PregnancyOutcome(
        womanId: 'mem_pooja_001',
        outcomeDate: now,
        outcomeType: PregnancyOutcomeType.liveBirth,
        placeOfDelivery: 'Rampur Community Health Centre',
        deliveryType: 'normal_vaginal',
        skilledAttendant: 'MO Dr. Kumar',
        newbornSex: 'F',
        birthWeightKg: 2.8,
      );

      final downstream = await ancRepo.recordPregnancyOutcome(outcome: outcome, ashaId: testWorkerId);
      final newbornId = downstream['newborn_id'] as String;
      expect(newbornId, isNotNull);

      // Verify open ANC visits were cancelled
      final openAnc = await (db.select(db.visitSchedules)
            ..where((t) => t.memberId.equals('mem_pooja_001') & t.programCode.equals('anc') & t.status.equals('pending')))
          .get();
      expect(openAnc.isEmpty, isTrue);

      // Verify HBNC schedule auto-generated (6 visits for institutional delivery)
      final hbncSchedules = await (db.select(db.visitSchedules)
            ..where((t) => t.memberId.equals(newbornId) & t.programCode.equals('hbnc')))
          .get();
      expect(hbncSchedules.length, 6);

      // 6. National Immunization Schedule Generation
      final immuTasks = await immuRepo.generateScheduleForChild(
        memberId: newbornId,
        dateOfBirth: now,
        ashaId: testWorkerId,
      );
      expect(immuTasks.isNotEmpty, isTrue);
      expect(immuTasks.any((t) => t.visitType.contains('BCG')), isTrue);
      expect(immuTasks.any((t) => t.visitType.contains('OPV-0')), isTrue);

      // 7. Adult NCD Screening via CBAC Calculator
      final cbacScore = CbacCalculator.computeTotalCbacScore(
        ageYears: 45,
        tobaccoUse: TobaccoUse.currentDaily,
        alcoholConsumption: AlcoholConsumption.no,
        waistCircumferenceCm: 92.0,
        sex: 'M',
        physicalActivity: PhysicalActivity.lessThan150Mins,
        familyHistory: FamilyHistoryNcd.yes,
      );
      expect(cbacScore >= 4, isTrue); // High risk score requiring facility screening

      // 8. Family Planning PPIUCD Motivation & Incentive Logging
      final fpIncentiveId = await fpService.recordFpIncentiveEvent(
        memberId: 'mem_pooja_001',
        method: ContraceptiveMethod.ppiucd,
        ashaWorkerId: testWorkerId,
        facilityName: 'Rampur CHC',
      );
      expect(fpIncentiveId, startsWith('inc_fp_mem_pooja_001_'));

      // 9. Verify All Incentive Event Idempotency Keys are Unique
      final allEvents = await db.select(db.incentiveEvents).get();
      expect(allEvents.length, greaterThanOrEqualTo(3));
      final idempotencyKeys = allEvents.map((e) => e.idempotencyKey).toSet();
      expect(idempotencyKeys.length, allEvents.length);

      // 10. Generate Monthly Claim Voucher
      final claimPeriod = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final voucher = await claimService.generateClaimVoucher(
        workerId: testWorkerId,
        period: claimPeriod,
      );

      expect(voucher.workerId, testWorkerId);
      expect(voucher.claimPeriod, claimPeriod);
      expect(voucher.status, 'generated');
      expect(voucher.totalAmount, greaterThan(0));

      // 11. Verify Sync Queue Integrity
      final syncQueueEntries = await db.select(db.syncQueue).get();
      expect(syncQueueEntries.isNotEmpty, isTrue);
      for (final entry in syncQueueEntries) {
        expect(entry.payloadJson.isNotEmpty, isTrue);
      }
    });
  });
}
