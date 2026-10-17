import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart' hide TriageResult;
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/features/clinical_programs/anc_pnc/data/anc_repository.dart';
import 'package:asha_platform/features/clinical_programs/anc_pnc/data/pnc_repository.dart';
import 'package:asha_platform/features/clinical_programs/anc_pnc/domain/anc_models.dart';
import 'package:asha_platform/features/clinical_programs/hbnc/data/hbnc_repository.dart';
import 'package:asha_platform/features/clinical_programs/hbnc/domain/hbnc_models.dart';
import 'package:asha_platform/features/clinical_programs/immunization/data/immunization_repository.dart';
import 'package:asha_platform/features/clinical_programs/immunization/domain/immunization_models.dart';
import 'package:asha_platform/features/clinical_programs/ncd/data/ncd_repository.dart';
import 'package:asha_platform/features/clinical_programs/ncd/domain/cbac_models.dart';
import 'package:asha_platform/features/clinical_programs/nutrition/data/nutrition_repository.dart';
import 'package:asha_platform/features/clinical_programs/nutrition/domain/growth_models.dart';
import 'package:asha_platform/features/clinical_programs/tb/data/tb_repository.dart';
import 'package:asha_platform/features/clinical_programs/tb/domain/tb_calculator.dart';
import 'package:asha_platform/features/clinical_programs/tb/domain/tb_models.dart';
import 'package:asha_platform/features/referral/data/referral_repository.dart';
import 'package:asha_platform/features/referral/domain/facility_matcher.dart';
import 'package:asha_platform/features/referral/domain/referral_models.dart';
import 'package:asha_platform/features/referral/domain/referral_note_generator.dart';

void main() {
  group('Task 9.6: Milestone 9 Clinical Programs Integration Test (Requirements 12.1, 14.3, 54.1)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late HbncRepository hbncRepo;
    late AncRepository ancRepo;
    late PncRepository pncRepo;

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      hbncRepo = HbncRepository(db, syncEngine);
      ancRepo = AncRepository(db, syncEngine, hbncRepo);
      pncRepo = PncRepository(db, syncEngine);

      // Seed Household
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_integ_1',
              village: 'Devpur',
              hamlet: const Value('Purbi Tola'),
              headName: 'Sanjay Yadav',
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_01',
            ),
          );

      // Seed Mother
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'member_rekha_1',
              householdId: 'hh_integ_1',
              name: 'Rekha Yadav',
              sex: 'F',
              relationshipToHead: const Value('Wife'),
              dobApprox: Value(DateTime(2000, 1, 1).millisecondsSinceEpoch), // 25 yrs
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_01',
            ),
          );

      // Seed Infant LBW
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'infant_lbw_integ',
              householdId: 'hh_integ_1',
              name: 'Baby LBW',
              sex: 'F',
              relationshipToHead: const Value('Daughter'),
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_01',
            ),
          );

      // Seed Infant Incentive
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'infant_incentive_integ',
              householdId: 'hh_integ_1',
              name: 'Baby Incentive',
              sex: 'M',
              relationshipToHead: const Value('Son'),
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_01',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. Pregnancy -> ANC Schedule -> Delivery -> HBNC Auto-Generation (Req 12.1, 14.1) ─
    test('End-to-End: Delivery outcome auto-generates HBNC newborn care schedule and cancels ANC', () async {
      final lmp = now.subtract(const Duration(days: 280)); // Full term
      final reg = PregnancyRegistration(
        womanId: 'member_rekha_1',
        lmp: lmp,
        gravida: 1,
        para: 0,
        mcpCardNumber: 'MCP-887766',
        rchId: 'RCH-123456',
        maternalAgeYears: 25,
      );

      // 1. Register Pregnancy
      await ancRepo.registerPregnancy(registration: reg, ashaId: 'asha_01');

      final ancSchedules = await (db.select(db.visitSchedules)
            ..where((t) => t.memberId.equals('member_rekha_1') & t.programCode.equals('anc')))
          .get();
      expect(ancSchedules.length, equals(7)); // 4 contacts + 2 Td + 1 Birth Plan

      // 2. Record Live Birth Delivery
      final outcome = PregnancyOutcome(
        womanId: 'member_rekha_1',
        outcomeDate: now,
        outcomeType: PregnancyOutcomeType.liveBirth,
        placeOfDelivery: 'District Hospital Devpur',
        deliveryType: 'normal_vaginal',
        skilledAttendant: 'Staff Nurse Sunita',
        newbornSex: 'M',
        birthWeightKg: 2.9, // Normal birth weight
      );

      final downstream = await ancRepo.recordPregnancyOutcome(outcome: outcome, ashaId: 'asha_01');
      expect(downstream['newborn_id'], isNotNull);
      final newbornId = downstream['newborn_id'] as String;

      // 3. Verify open ANC visits were cancelled
      final remainingAnc = await (db.select(db.visitSchedules)
            ..where((t) =>
                t.memberId.equals('member_rekha_1') &
                t.programCode.equals('anc') &
                (t.status.equals('pending') | t.status.equals('overdue'))))
          .get();
      expect(remainingAnc.isEmpty, isTrue);

      // 4. Verify newborn member was created
      final newbornMember = await (db.select(db.members)..where((t) => t.id.equals(newbornId))).getSingle();
      expect(newbornMember.householdId, equals('hh_integ_1'));
      expect(newbornMember.sex, equals('M'));

      // 5. Verify HBNC schedule was auto-generated for newborn (institutional: Days 3, 7, 14, 21, 28, 42 = 6 visits)
      final hbncSchedules = await (db.select(db.visitSchedules)
            ..where((t) => t.memberId.equals(newbornId) & t.programCode.equals('hbnc')))
          .get();
      expect(hbncSchedules.length, equals(6));
      expect(hbncSchedules.map((s) => s.visitType).toList(), contains('HBNC Day 3 Visit'));
      expect(hbncSchedules.map((s) => s.visitType).toList(), contains('HBNC Day 42 Visit'));
    });

    // ── 2. LBW Delivery -> High-Risk Pathway Enrolled with Extra Visits (Req 12.4) ─────
    test('LBW Delivery: Infant born < 2.5 kg enrolls in High-Risk KMC pathway with extra visits', () async {
      final delivery = HbncDeliveryRecord(
        newbornId: 'infant_lbw_integ',
        motherId: 'member_rekha_1',
        householdId: 'hh_integ_1',
        deliveryDate: now,
        place: DeliveryPlace.institutionalDh,
        birthWeightKg: 1.8, // LBW (< 2.5 kg)
        ashaId: 'asha_01',
      );

      expect(delivery.isHighRisk, isTrue);

      final schedules = await hbncRepo.generateSchedule(delivery);
      // 6 standard (institutional) + 6 extra high risk KMC visits = 12 total visits
      expect(schedules.length, equals(12));
      expect(schedules.any((s) => s.visitType.contains('High Risk KMC')), isTrue);
    });

    // ── 3. ANC High-Risk Criteria Thresholds (Requirement 14.3) ─────────────────
    test('ANC High-Risk: evaluates BP, Hb, maternal age, and obstetric history thresholds', () async {
      final lmp = DateTime(2025, 2, 1);
      final reg = PregnancyRegistration(womanId: 'member_rekha_1', lmp: lmp, gravida: 1, para: 0);
      final schedules = await ancRepo.registerPregnancy(registration: reg, ashaId: 'asha_01');
      final anc2 = schedules.firstWhere((s) => s.visitType.contains('20 Weeks'));

      // Severe hypertension & bleeding -> RED triage
      const severeVisit = AncContactData(
        contactNumber: 2,
        gestationWeeks: 20,
        systolicBp: 165,
        diastolicBp: 112,
        haemoglobin: 11.0,
        vaginalBleeding: true,
      );
      final redResult = await ancRepo.recordAncVisit(
        womanId: 'member_rekha_1',
        visitScheduleId: anc2.id,
        visitData: severeVisit,
        ashaId: 'asha_01',
      );
      expect(redResult.isRedFlag, isTrue);
      expect(redResult.triageResult?.flag, equals(TriageFlag.red));

      // Moderate hypertension + moderate anaemia -> YELLOW triage
      const moderateVisit = AncContactData(
        contactNumber: 2,
        gestationWeeks: 20,
        systolicBp: 142,
        diastolicBp: 92,
        haemoglobin: 8.8,
        vaginalBleeding: false,
      );
      final yellowResult = await ancRepo.recordAncVisit(
        womanId: 'member_rekha_1',
        visitScheduleId: anc2.id,
        visitData: moderateVisit,
        ashaId: 'asha_01',
      );
      expect(yellowResult.isRedFlag, isFalse);
      expect(yellowResult.isHighRisk, isTrue);
      expect(yellowResult.triageResult?.flag, equals(TriageFlag.yellow));

      // Baseline evaluation: Teenage pregnancy (age < 18) and previous Cesarean
      final teenageReg = PregnancyRegistration(
        womanId: 'member_rekha_1',
        lmp: lmp,
        gravida: 2,
        para: 1,
        maternalAgeYears: 16,
        previousCesarean: true,
      );
      expect(teenageReg.isBaselineHighRisk, isTrue);
      expect(teenageReg.baselineHighRiskReasons.any((r) => r.contains('Adolescent pregnancy')), isTrue);
      expect(teenageReg.baselineHighRiskReasons.any((r) => r.contains('Cesarean Section')), isTrue);
    });

    // ── 4. Missed Visit Handling: Overdue Detection & Rescheduling (Req 12.5) ────
    test('Missed Visit: detects lapsed window, flags overdue, and reschedules within grace window', () async {
      const dayMs = 24 * 60 * 60 * 1000;
      final pastDue = nowMs - (3 * dayMs);

      // Insert an overdue HBNC task
      await db.into(db.visitSchedules).insert(
            VisitSchedulesCompanion.insert(
              id: 'task_hbnc_overdue_integ',
              memberId: 'member_rekha_1',
              programCode: 'hbnc',
              visitType: 'HBNC Day 3 Visit',
              dueDate: pastDue,
              dueWindowStart: Value(pastDue - dayMs),
              dueWindowEnd: Value(pastDue + dayMs),
              status: const Value('pending'),
              createdAt: pastDue - (2 * dayMs),
            ),
          );

      // Check and reschedule missed visits
      final rescheduledList = await hbncRepo.checkAndRescheduleMissedVisits(graceDays: 2);
      expect(rescheduledList.isNotEmpty, isTrue);

      final record = await (db.select(db.visitSchedules)
            ..where((t) => t.id.equals('task_hbnc_overdue_integ')))
          .getSingle();

      expect(record.status, equals('overdue'));
      expect(record.rescheduledCount, equals(1));
      expect(record.dueDate, greaterThan(nowMs));
    });

    // ── 5. Program Completion Incentive Events (Requirement 12.7, 13.5, 54.1) ─
    test('Incentive Events: Full HBNC episode completion writes HBNC_COMPLETE incentive event', () async {
      final delivery = HbncDeliveryRecord(
        newbornId: 'infant_incentive_integ',
        motherId: 'member_rekha_1',
        householdId: 'hh_integ_1',
        deliveryDate: now.subtract(const Duration(days: 50)),
        place: DeliveryPlace.home, // 7 visits
        birthWeightKg: 3.0,
        ashaId: 'asha_01',
      );

      final schedules = await hbncRepo.generateSchedule(delivery);
      expect(schedules.length, equals(7));

      // Complete all 7 visits
      for (final s in schedules) {
        await hbncRepo.recordVisit(
          newbornId: 'infant_incentive_integ',
          visitScheduleId: s.id,
          checklist: const HbncChecklistData(
            temperatureC: 36.8,
            currentWeightKg: 3.2,
            respiratoryRate: 46,
            cordStatus: CordStatus.cleanAndDry,
            feedingStatus: FeedingStatus.exclusiveBreastfeeding,
            activityStatus: ActivityStatus.activeAndAlert,
            skinStatus: SkinStatus.clearNormal,
            eyeStatus: EyeStatus.clear,
          ),
          ashaId: 'asha_01',
        );
      }

      // Verify HBNC_COMPLETE incentive generated
      final incentives = await (db.select(db.incentiveEvents)
            ..where((t) => t.activityCode.equals('HBNC_COMPLETE')))
          .get();
      expect(incentives.length, equals(1));
      expect(incentives.first.memberId, equals('infant_incentive_integ'));
      expect(incentives.first.status, equals('eligible'));
    });

    test('Incentive Events: Facilitated institutional delivery writes JSY escort incentive', () async {
      final incentiveId = await pncRepo.confirmInstitutionalDelivery(
        motherId: 'member_rekha_1',
        placeOfDelivery: 'Community Health Centre Devpur',
        ashaId: 'asha_01',
      );

      expect(incentiveId, isNotNull);

      final events = await (db.select(db.incentiveEvents)
            ..where((t) => t.id.equals(incentiveId!)))
          .get();
      expect(events.length, equals(1));
      expect(events.first.activityCode, equals('INSTITUTIONAL_DELIVERY_ESCORT'));
      expect(events.first.status, equals('eligible'));
    });
  });

  group('Milestone 11 Checkpoint: Complete Clinical Programs & Triage Integration Flow (Tasks 9.1 – 10.6, Requirements 12.1, 14.3, 16.1, 17.1, 19.1, 20.1, 54.1)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late AncRepository ancRepo;
    late HbncRepository hbncRepo;
    late ImmunizationRepository immRepo;
    late NutritionRepository nutritionRepo;
    late NcdRepository ncdRepo;
    late TbRepository tbRepo;
    late ReferralRepository referralRepo;

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      hbncRepo = HbncRepository(db, syncEngine);
      ancRepo = AncRepository(db, syncEngine, hbncRepo);
      immRepo = ImmunizationRepository(db, syncEngine);
      nutritionRepo = NutritionRepository(db, syncEngine);
      ncdRepo = NcdRepository(db, syncEngine);
      tbRepo = TbRepository(db, syncEngine);
      referralRepo = ReferralRepository(db, syncEngine);

      // Seed ASHA user
      await db.into(db.users).insert(
            UsersCompanion.insert(
              id: 'asha_user_m11',
              ashaId: 'ASHA-DEV-001',
              name: 'Sunita Devi ASHA',
              role: 'ASHA',
              areaVillage: const Value('Devpur'),
              areaSubcentre: const Value('Devpur Sub-Centre'),
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );

      // Seed Health Facilities for Referral Matching
      await db.into(db.facilityDirectory).insert(
            FacilityDirectoryCompanion.insert(
              id: 'fac_sc_devpur',
              name: 'Devpur Health Sub-Centre',
              facilityLevel: 'SUB_CENTRE',
              district: const Value('Devpur District'),
              latitude: const Value(26.40),
              longitude: const Value(84.40),
              servicesJson: const Value('["OPD", "IMMUNIZATION"]'),
              isActive: const Value(true),
              lastUpdatedAt: nowMs,
            ),
          );

      await db.into(db.facilityDirectory).insert(
            FacilityDirectoryCompanion.insert(
              id: 'fac_chc_devpur',
              name: 'Devpur Community Health Centre (FRU)',
              facilityLevel: 'CHC',
              district: const Value('Devpur District'),
              latitude: const Value(26.45),
              longitude: const Value(84.45),
              contactPhone: const Value('06156-224400'),
              servicesJson: const Value('["EMERGENCY", "FRU", "24x7_DELIVERY", "BLOOD_STORAGE", "DMC_CHC", "NRC_CHC"]'),
              isActive: const Value(true),
              lastUpdatedAt: nowMs,
            ),
          );

      // Seed WHO Growth Standards table in SQLite
      await nutritionRepo.ensureSqliteStandardsTablePopulated();
    });

    tearDown(() async {
      await db.close();
    });

    test(
        'Complete End-to-End Multi-Program Integration Flow: '
        'Household Reg -> ANC Reg -> High-Risk Flag & Referral -> Delivery & HBNC Schedule -> '
        'Immunization Schedule -> WHO Growth Monitoring -> Adult NCD/CBAC -> Presumptive TB & Adherence',
        () async {
      // ──────────────────────────────────────────────────────────────────────────
      // STEP 1: Household Registration & Beneficiary Onboarding (Req 4.1)
      // ──────────────────────────────────────────────────────────────────────────
      const hhId = 'hh_sharma_m11';
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: hhId,
              village: 'Devpur',
              hamlet: const Value('Purbi Tola'),
              headName: 'Ramesh Sharma',
              isBpl: const Value(true),
              memberCount: const Value(3),
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_user_m11',
            ),
          );

      // Pregnant Wife: Sunita Sharma (24 years old)
      const motherId = 'member_sunita_m11';
      final motherDobMs = now.subtract(const Duration(days: 365 * 24)).millisecondsSinceEpoch;
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: motherId,
              householdId: hhId,
              name: 'Sunita Sharma',
              sex: 'F',
              dobApprox: Value(motherDobMs),
              relationshipToHead: const Value('Wife'),
              phone: const Value('9876543210'),
              abhaId: const Value('ABHA-9988-7766-5544'),
              lifecycleStatus: const Value('active'),
              consentStatus: const Value('granted'),
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_user_m11',
            ),
          );

      // Adult Male Head: Ramesh Sharma (48 years old, >= 30 for CBAC screening)
      const husbandId = 'member_ramesh_m11';
      final husbandDobMs = now.subtract(const Duration(days: 365 * 48)).millisecondsSinceEpoch;
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: husbandId,
              householdId: hhId,
              name: 'Ramesh Sharma',
              sex: 'M',
              dobApprox: Value(husbandDobMs),
              relationshipToHead: const Value('Self'),
              phone: const Value('9876543210'),
              lifecycleStatus: const Value('active'),
              consentStatus: const Value('granted'),
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_user_m11',
            ),
          );

      // Elderly Female: Sita Devi (68 years old, candidate for TB screening)
      const elderId = 'member_sita_m11';
      final elderDobMs = now.subtract(const Duration(days: 365 * 68)).millisecondsSinceEpoch;
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: elderId,
              householdId: hhId,
              name: 'Sita Devi',
              sex: 'F',
              dobApprox: Value(elderDobMs),
              relationshipToHead: const Value('Mother'),
              lifecycleStatus: const Value('active'),
              consentStatus: const Value('granted'),
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_user_m11',
            ),
          );

      // Verify all household members persisted
      final membersList = await (db.select(db.members)..where((t) => t.householdId.equals(hhId))).get();
      expect(membersList.length, equals(3));

      // ──────────────────────────────────────────────────────────────────────────
      // STEP 2: ANC Registration & Visit Schedule Generation (Req 14.1, 14.2)
      // ──────────────────────────────────────────────────────────────────────────
      final lmp = now.subtract(const Duration(days: 140)); // 20 weeks gestation
      final reg = PregnancyRegistration(
        womanId: motherId,
        lmp: lmp,
        gravida: 1,
        para: 0,
        mcpCardNumber: 'MCP-998877',
        rchId: 'RCH-776655',
        maternalAgeYears: 24,
      );

      final ancSchedules = await ancRepo.registerPregnancy(registration: reg, ashaId: 'asha_user_m11');
      // 4 contacts + 2 Td + 1 Birth Plan = 7 total scheduled visits
      expect(ancSchedules.length, equals(7));

      // ──────────────────────────────────────────────────────────────────────────
      // STEP 3: ANC Contact 2 with High-Risk Danger Signs & Emergency Referral (Req 10.1, 14.3, 14.4)
      // ──────────────────────────────────────────────────────────────────────────
      final anc2Schedule = ancSchedules.firstWhere((s) => s.visitType.contains('20 Weeks'));

      // Severe Gestational Hypertension + Severe Headache danger sign
      const severeAncContact = AncContactData(
        contactNumber: 2,
        gestationWeeks: 20,
        systolicBp: 168,
        diastolicBp: 112,
        haemoglobin: 10.2,
        weightKg: 55.0,
        severeHeadacheOrBlurredVision: true,
        vaginalBleeding: false,
      );

      final ancVisitResult = await ancRepo.recordAncVisit(
        womanId: motherId,
        visitScheduleId: anc2Schedule.id,
        visitData: severeAncContact,
        ashaId: 'asha_user_m11',
      );

      expect(ancVisitResult.isRedFlag, isTrue);
      expect(ancVisitResult.isHighRisk, isTrue);
      expect(ancVisitResult.triageResult?.flag, equals(TriageFlag.red));
      expect(ancVisitResult.suggestedReferralFacility, contains('District Hospital (FRU)'));

      // Emergency Referral Generation & Offline Facility Matching
      final matchedFacilities = await FacilityMatcher.matchFromDb(
        db: db,
        triageFlag: TriageFlag.red,
        ashaLatitude: 26.40,
        ashaLongitude: 84.40,
      );
      expect(matchedFacilities.isNotEmpty, isTrue);
      final fruFacility = matchedFacilities.firstWhere((f) => f.level == FacilityLevel.chc);

      final motherMember = await (db.select(db.members)..where((t) => t.id.equals(motherId))).getSingle();
      final household = await (db.select(db.households)..where((t) => t.id.equals(hhId))).getSingle();
      final ashaUser = await (db.select(db.users)..where((t) => t.id.equals('asha_user_m11'))).getSingle();

      final referralNote = ReferralNoteGenerator.generate(
        triageResult: ancVisitResult.triageResult!,
        member: motherMember,
        household: household,
        ashaUser: ashaUser,
        destinationFacility: fruFacility,
        transportArranged: '108 Emergency Ambulance',
        rawVitals: {'bp': '168/112 mmHg', 'gestation_weeks': 20},
      );

      final referralRecord = await referralRepo.createReferral(
        note: referralNote,
        transportArranged: '108 Emergency Ambulance',
      );

      expect(referralRecord.memberId, equals(motherId));
      expect(referralRecord.triageFlag, equals('RED'));
      expect(referralRecord.status, equals('created'));
      expect(referralNote.destinationFacility?.name, contains('Devpur Community Health Centre'));

      // ──────────────────────────────────────────────────────────────────────────
      // STEP 4: Live Delivery Outcome & HBNC Auto-Scheduling (Req 12.1, 14.6, 15.6)
      // ──────────────────────────────────────────────────────────────────────────
      final deliveryDate = now;
      final deliveryOutcome = PregnancyOutcome(
        womanId: motherId,
        outcomeDate: deliveryDate,
        outcomeType: PregnancyOutcomeType.liveBirth,
        placeOfDelivery: 'Devpur Community Health Centre (FRU)',
        deliveryType: 'normal_vaginal',
        skilledAttendant: 'Dr. Anita Roy (MO CHC)',
        newbornSex: 'M',
        birthWeightKg: 3.1, // Normal birth weight >= 2.5 kg
      );

      final downstream = await ancRepo.recordPregnancyOutcome(
        outcome: deliveryOutcome,
        ashaId: 'asha_user_m11',
      );

      final newbornId = downstream['newborn_id'] as String;
      expect(newbornId, isNotNull);

      // Verify open ANC schedules were cancelled
      final remainingAnc = await (db.select(db.visitSchedules)
            ..where((t) =>
                t.memberId.equals(motherId) &
                t.programCode.equals('anc') &
                (t.status.equals('pending') | t.status.equals('overdue'))))
          .get();
      expect(remainingAnc.isEmpty, isTrue);

      // Verify newborn member created in household
      final newborn = await (db.select(db.members)..where((t) => t.id.equals(newbornId))).getSingle();
      expect(newborn.householdId, equals(hhId));
      expect(newborn.sex, equals('M'));

      // Verify HBNC auto-generated (institutional delivery: Days 3, 7, 14, 21, 28, 42 = 6 visits)
      final hbncSchedules = await (db.select(db.visitSchedules)
            ..where((t) => t.memberId.equals(newbornId) & t.programCode.equals('hbnc')))
          .get();
      expect(hbncSchedules.length, equals(6));

      // Record first HBNC visit (Day 3)
      final day3Visit = hbncSchedules.firstWhere((s) => s.visitType.contains('Day 3'));
      await hbncRepo.recordVisit(
        newbornId: newbornId,
        visitScheduleId: day3Visit.id,
        checklist: const HbncChecklistData(
          temperatureC: 36.8,
          currentWeightKg: 3.15,
          respiratoryRate: 44,
          cordStatus: CordStatus.cleanAndDry,
          feedingStatus: FeedingStatus.exclusiveBreastfeeding,
          activityStatus: ActivityStatus.activeAndAlert,
          skinStatus: SkinStatus.clearNormal,
          eyeStatus: EyeStatus.clear,
        ),
        ashaId: 'asha_user_m11',
      );

      final day3Updated = await (db.select(db.visitSchedules)..where((t) => t.id.equals(day3Visit.id))).getSingle();
      expect(day3Updated.status, equals('completed'));

      // ──────────────────────────────────────────────────────────────────────────
      // STEP 5: National Immunization Schedule (NIS) Generation & Administration (Req 16.1, 16.2)
      // ──────────────────────────────────────────────────────────────────────────
      final immSchedules = await immRepo.generateScheduleForChild(
        memberId: newbornId,
        dateOfBirth: deliveryDate,
        ashaId: 'asha_user_m11',
      );

      // Verify full national immunization schedule generated (BCG, OPV-0, HepB-0, Penta 1-3, etc.)
      expect(immSchedules.length, equals(NationalImmunizationCatalog.infantAndChildSchedule.length));
      expect(immSchedules.any((s) => s.visitType.contains('BCG')), isTrue);
      expect(immSchedules.any((s) => s.visitType.contains('OPV-0')), isTrue);
      expect(immSchedules.any((s) => s.visitType.contains('PENTA_1')), isTrue);

      // Record Birth Doses (BCG & OPV-0)
      final bcgEncounter = await immRepo.recordDose(
        memberId: newbornId,
        record: VaccineDoseRecord(
          vaccineCode: 'BCG',
          administeredDate: deliveryDate,
          bodySite: AdministrationSite.leftUpperArm,
          batchNumber: 'BCG-2026-B01',
          sessionType: ImmunizationSessionType.healthFacility,
          administeredBy: 'Staff Nurse Sunita',
        ),
        ashaId: 'asha_user_m11',
      );
      expect(bcgEncounter.status, equals('completed'));

      final bcgSchedule = await (db.select(db.visitSchedules)
            ..where((t) => t.id.equals('imm_${newbornId}_bcg')))
          .getSingle();
      expect(bcgSchedule.status, equals('completed'));

      final opv0Encounter = await immRepo.recordDose(
        memberId: newbornId,
        record: VaccineDoseRecord(
          vaccineCode: 'OPV_0',
          administeredDate: deliveryDate,
          bodySite: AdministrationSite.oral,
          batchNumber: 'OPV-2026-B02',
          sessionType: ImmunizationSessionType.healthFacility,
          administeredBy: 'Staff Nurse Sunita',
        ),
        ashaId: 'asha_user_m11',
      );
      expect(opv0Encounter.status, equals('completed'));

      // ──────────────────────────────────────────────────────────────────────────
      // STEP 6: WHO Child Growth Standards & Malnutrition Classification (Req 17.1, 17.2)
      // ──────────────────────────────────────────────────────────────────────────
      // Aarav evaluated at 6 months of age (Weight: 7.9 kg, Height: 67.6 cm, MUAC: 14.2 cm)
      final sixMonthsLater = deliveryDate.add(const Duration(days: 182));
      final aaravGrowth = await nutritionRepo.recordGrowthMeasurement(
        memberId: newbornId,
        weightKg: 7.9,
        heightCm: 67.6,
        muacCm: 14.2,
        bilateralOedema: false,
        ashaId: 'asha_user_m11',
        measuredAt: sixMonthsLater,
      );

      // Verify normal growth and Z-scores
      expect(aaravGrowth.waz, inInclusiveRange(-1.0, 1.0));
      expect(aaravGrowth.haz, inInclusiveRange(-1.0, 1.0));
      expect(aaravGrowth.wfhz, inInclusiveRange(-1.0, 1.0));
      expect(aaravGrowth.wastingStatus, equals(WastingStatus.normal));
      expect(aaravGrowth.underweightStatus, equals(UnderweightStatus.normal));
      expect(aaravGrowth.triageFlag, equals(TriageFlag.green));

      // SAM Triage Case for village child: triggers RED flag and NRC referral
      const samChildId = 'child_sam_m11';
      final samDobMs = now.subtract(const Duration(days: 200)).millisecondsSinceEpoch;
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: samChildId,
              householdId: hhId,
              name: 'Vikas Kumar (SAM Child)',
              sex: 'M',
              dobApprox: Value(samDobMs),
              relationshipToHead: const Value('Other'),
              createdAt: nowMs,
              updatedAt: nowMs,
              createdBy: 'asha_user_m11',
            ),
          );

      final samMeasurement = await nutritionRepo.recordGrowthMeasurement(
        memberId: samChildId,
        weightKg: 4.1, // Severely low weight for 6.5 months
        heightCm: 64.0,
        muacCm: 11.0, // MUAC < 11.5 cm -> SAM threshold
        bilateralOedema: true, // Bilateral pitting oedema
        appetiteTestPassed: false,
        ashaId: 'asha_user_m11',
        measuredAt: now,
      );

      expect(samMeasurement.triageFlag, equals(TriageFlag.red));
      expect(samMeasurement.isSam, isTrue);
      expect(samMeasurement.emergencyReferralRequired, isTrue);

      // Verify NRC referral record automatically created for SAM case
      final samReferrals = await (db.select(db.referralRecords)
            ..where((t) => t.memberId.equals(samChildId) & t.triageFlag.equals('RED')))
          .get();
      expect(samReferrals.isNotEmpty, isTrue);
      expect(samReferrals.first.destinationLevel, equals('NRC_CHC'));
      expect(samReferrals.first.referralNoteText, contains('URGENT MALNUTRITION'));

      // ──────────────────────────────────────────────────────────────────────────
      // STEP 7: Adult NCD / CBAC Screening & Chronic Disease Register (Req 19.1, 19.2)
      // ──────────────────────────────────────────────────────────────────────────
      // Screening Ramesh Sharma (48y male): Part A score = 8 (>4), BP = 162/100, RBS = 215 mg/dL
      final cbacAssessment = await ncdRepo.recordCbacScreening(
        memberId: husbandId,
        tobaccoUse: TobaccoUse.currentDaily, // +2 pts
        alcoholConsumption: AlcoholConsumption.yes, // +1 pt
        waistCircumferenceCm: 96.0, // +1 pt (90-100cm)
        physicalActivity: PhysicalActivity.lessThan150Mins, // +1 pt
        familyHistory: FamilyHistoryNcd.yes, // +2 pts, age 48 (+1 pt) -> Total = 8 pts
        warningSigns: const CancerWarningSigns(),
        systolicBp: 162,
        diastolicBp: 100,
        bloodGlucoseMgDl: 215,
        glucoseType: GlucoseType.random,
        ashaId: 'asha_user_m11',
      );

      expect(cbacAssessment.totalCbacScore, equals(8));
      expect(cbacAssessment.isHighRiskScore, isTrue);
      expect(cbacAssessment.triageFlag, equals(TriageFlag.yellow));
      expect(cbacAssessment.requiresFacilityConfirmation, isTrue);
      expect(cbacAssessment.bpCategory, equals(BloodPressureCategory.stage2Hypertension));
      expect(cbacAssessment.glucoseCategory, equals(BloodGlucoseCategory.suspectedDiabetes));

      // Enrol Ramesh in NCD Chronic Care Register
      final ncdEnrolment = await ncdRepo.enrolNcdPatient(
        memberId: husbandId,
        diagnosis: NcdDiagnosisType.both,
        prescribedMedications: ['Amlodipine 5mg OD', 'Metformin 500mg BD'],
        ashaId: 'asha_user_m11',
      );
      expect(ncdEnrolment.diagnosis, equals(NcdDiagnosisType.both));
      expect(ncdEnrolment.prescribedMedications.length, equals(2));

      // Verify NCD Export CSV format
      final ncdCsv = await ncdRepo.exportNationalNcdPortalCsv();
      expect(ncdCsv, contains('Beneficiary_ID,Household_ID,Name,Age,Sex,Village,CBAC_Score'));
      expect(ncdCsv, contains(husbandId));
      expect(ncdCsv, contains(',8,HIGH,')); // CBAC score = 8

      // ──────────────────────────────────────────────────────────────────────────
      // STEP 8: Presumptive TB Screening, Sputum & DOTS Adherence (Req 20.1, 20.4, 20.8)
      // ──────────────────────────────────────────────────────────────────────────
      // Sita Devi (68y): chronic cough >= 2 weeks, evening fever, weight loss
      final tbAssessment = await tbRepo.recordPresumptiveTbScreening(
        memberId: elderId,
        coughGt2Weeks: true,
        feverGt2Weeks: true,
        unexplainedWeightLoss: true,
        nightSweats: true,
        haemoptysis: false,
        ashaId: 'asha_user_m11',
      );

      expect(tbAssessment.isPresumptiveTb, isTrue);
      expect(tbAssessment.triageFlag, equals(TriageFlag.yellow));
      expect(tbAssessment.recommendedActions.any((a) => a.contains('Collect 2 sputum samples')), isTrue);

      // Verify DMC referral created
      final tbReferrals = await (db.select(db.referralRecords)..where((t) => t.memberId.equals(elderId))).get();
      expect(tbReferrals.isNotEmpty, isTrue);
      expect(tbReferrals.first.destinationLevel, equals('DMC_CHC'));

      // Collect Sputum Sample & Update Result
      final sputumSample = await tbRepo.recordSputumSample(
        memberId: elderId,
        sampleId: 'SPUTUM-M11-DEV01',
        collectionSite: 'Devpur Sub-Centre',
        transportStatus: SputumTransportStatus.inTransitToDmc,
        ashaId: 'asha_user_m11',
      );
      expect(sputumSample.sampleId, equals('SPUTUM-M11-DEV01'));

      final updatedSputum = await tbRepo.updateSputumTestResult(
        sampleId: sputumSample.sampleId,
        memberId: elderId,
        testResult: SputumTestResult.naatMtbDetectedSensitive,
        labName: 'Devpur CHC Truenat Lab',
        ashaId: 'asha_user_m11',
      );
      expect(updatedSputum.testResult, equals(SputumTestResult.naatMtbDetectedSensitive));

      // Register TB Treatment
      final treatmentPatient = await tbRepo.registerTbTreatment(
        memberId: elderId,
        nikshayId: 'NIKSHAY-DEV-2026-99',
        site: TbSite.pulmonary,
        regimen: TbRegimenType.dsTbDailyFdc,
        treatmentSupporterName: 'Sunita Devi ASHA',
        treatmentSupporterPhone: '9876543210',
        supporterRelationship: 'ASHA',
        totalDosesPrescribed: 168,
        ashaId: 'asha_user_m11',
      );
      expect(treatmentPatient.nikshayId, equals('NIKSHAY-DEV-2026-99'));

      // Test DOTS Adherence Consecutive Miss Alert (>= 3 consecutive misses)
      final alertTriggered = TbCalculator.checkConsecutiveMissAlert(consecutiveMissedCount: 3, alertThreshold: 3);
      expect(alertTriggered, isTrue);

      // Verify Anti-Stigma Privacy Protections (Requirement 20.8)
      final supervisorSummary = TbPrivacyFilter.filterTerm('Presumptive TB screening performed by DOTS Supporter', TbPrivacyMode.sharedSupervisorView);
      expect(supervisorSummary, equals('Chest Health Assessment screening performed by Care Supporter'));
      expect(supervisorSummary.contains('TB'), isFalse);
      expect(supervisorSummary.contains('DOTS'), isFalse);
    });
  });
}
