import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/features/clinical_programs/family_planning/domain/family_planning_models.dart';
import 'package:asha_platform/features/clinical_programs/family_planning/domain/family_planning_service.dart';
import 'package:asha_platform/features/clinical_programs/communicable_diseases/domain/communicable_disease_models.dart';
import 'package:asha_platform/features/clinical_programs/communicable_diseases/domain/communicable_disease_service.dart';
import 'package:asha_platform/features/clinical_programs/other_programs/domain/other_programs_service.dart';
import 'package:asha_platform/features/clinical_programs/vital_events/domain/vital_events_service.dart';

void main() {
  late AppDatabase db;
  late FamilyPlanningService fpService;
  late CommunicableDiseaseService cdService;
  late OtherProgramsService otherService;
  late VitalEventsService vitalService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    fpService = FamilyPlanningService(db);
    cdService = CommunicableDiseaseService();
    otherService = OtherProgramsService(db);
    vitalService = VitalEventsService(db);

    final now = DateTime.now().millisecondsSinceEpoch;

    // Seed baseline household and members
    await db.into(db.households).insert(
          HouseholdsCompanion.insert(
            id: 'hh_001',
            village: 'Rampur',
            headName: 'Ramesh Kumar',
            hamlet: const Value('North Ward'),
            createdAt: now,
            updatedAt: now,
            createdBy: 'worker_sunita',
          ),
        );

    await db.into(db.members).insert(
          MembersCompanion.insert(
            id: 'mem_mother_001',
            householdId: 'hh_001',
            name: 'Pooja Devi',
            sex: 'F',
            relationshipToHead: const Value('wife'),
            lifecycleStatus: const Value('active'),
            createdAt: now,
            updatedAt: now,
            createdBy: 'worker_sunita',
          ),
        );

    await db.into(db.stockItems).insert(
          StockItemsCompanion.insert(
            id: 'stock_condoms',
            workerId: 'worker_sunita',
            itemCode: 'ITEM_CONDOM',
            itemName: 'Nirodh Condoms',
            unit: 'pieces',
            quantity: const Value(100.0),
            lastUpdatedAt: now,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('Task 15.3: Family Planning & Reproductive Health (Requirement 18)', () {
    test('18.1: Unmet need classification distinguishes spacing from limiting', () {
      final spacingNeed = fpService.classifyUnmetNeed(
        parity: 1,
        youngestChildAgeMonths: 8,
        wantsMoreChildren: true,
        currentMethod: ContraceptiveMethod.none,
      );
      expect(spacingNeed, UnmetNeedType.spacing);

      final limitingNeed = fpService.classifyUnmetNeed(
        parity: 3,
        youngestChildAgeMonths: 36,
        wantsMoreChildren: false,
        currentMethod: ContraceptiveMethod.traditional,
      );
      expect(limitingNeed, UnmetNeedType.limiting);

      final satisfiedNeed = fpService.classifyUnmetNeed(
        parity: 2,
        youngestChildAgeMonths: 14,
        wantsMoreChildren: false,
        currentMethod: ContraceptiveMethod.antara,
      );
      expect(satisfiedNeed, UnmetNeedType.none);
    });

    test('18.4: Side-effect evaluation triggers RED emergency triage for dangerous symptoms', () {
      final severeEval = fpService.evaluateSideEffects(
        method: ContraceptiveMethod.iucd380A,
        symptoms: ['High fever', 'Severe pelvic pain', 'Foul discharge'],
      );
      expect(severeEval.requiresImmediateReferral, isTrue);
      expect(severeEval.triageFlag, 'RED');
      expect(severeEval.counsellingGuidance, contains('Immediately refer'));

      final mildEval = fpService.evaluateSideEffects(
        method: ContraceptiveMethod.malaN,
        symptoms: ['Mild nausea', 'Occasional spotting'],
      );
      expect(mildEval.requiresImmediateReferral, isFalse);
      expect(mildEval.triageFlag, 'YELLOW');
    });

    test('18.3: Records contraceptive distribution, decrements stock, and schedules refill', () async {
      final record = await fpService.recordDistribution(
        memberId: 'mem_mother_001',
        coupleId: 'cpl_001',
        method: ContraceptiveMethod.condoms,
        quantity: 30,
        ashaWorkerId: 'worker_sunita',
        stockItemId: 'stock_condoms',
        batchNumber: 'BATCH-2026-X',
      );

      expect(record.quantity, 30);
      expect(record.method, ContraceptiveMethod.condoms);

      // Verify stock transaction recorded
      final stockTx = await (db.select(db.stockTransactions)
            ..where((t) => t.itemId.equals('stock_condoms')))
          .get();
      expect(stockTx.length, 1);
      expect(stockTx.first.quantityDelta, -30.0);

      // Verify refill task generated
      final tasks = await (db.select(db.visitSchedules)
            ..where((t) => t.memberId.equals('mem_mother_001')))
          .get();
      expect(tasks.length, 1);
      expect(tasks.first.visitType, 'family_planning_refill');
      expect(tasks.first.programCode, 'FP');
    });

    test('18.6: Generates eligible incentive event for clinical family planning procedures', () async {
      final eventId = await fpService.recordFpIncentiveEvent(
        memberId: 'mem_mother_001',
        method: ContraceptiveMethod.ppiucd,
        ashaWorkerId: 'worker_sunita',
        facilityName: 'Community Health Centre Rampur',
      );

      expect(eventId, startsWith('inc_fp_mem_mother_001_'));
      final inc = await (db.select(db.incentiveEvents)
            ..where((t) => t.id.equals(eventId)))
          .getSingle();
      expect(inc.activityCode, 'FP_PPIUCD');
      expect(inc.status, 'eligible');
    });

    test('18.7: Stricter privacy filter redacts contraceptive details from non-clinical roles', () {
      final confidentialRecord = {
        'member_name': 'Pooja Devi',
        'contraceptive_method': 'Antara Injectable',
        'fp_notes': 'Second dose due on 24th',
        'last_refill_date': '2026-09-10',
      };

      final publicView = fpService.applyPrivacyFilter(confidentialRecord, 'surveyor');
      expect(publicView['contraceptive_method'], contains('Confidential'));
      expect(publicView.containsKey('last_refill_date'), isFalse);

      final ashaView = fpService.applyPrivacyFilter(confidentialRecord, 'asha');
      expect(ashaView['contraceptive_method'], 'Antara Injectable');
      expect(ashaView.containsKey('last_refill_date'), isTrue);
    });
  });

  group('Task 15.3: Communicable Disease, Malaria & Outbreak Surveillance (Requirement 21)', () {
    test('21.1: Malaria RDT evaluation routes species-specific NVBDCP treatment', () {
      final pfResult = cdService.evaluateMalariaRdt(
        memberId: 'mem_mother_001',
        species: MalariaSpecies.plasmodiumFalciparum,
        isEndemicArea: true,
      );
      expect(pfResult.treatmentRegimen, contains('ACT-AL'));
      expect(pfResult.requiresFacilityReferral, isTrue);

      final pvResult = cdService.evaluateMalariaRdt(
        memberId: 'mem_mother_001',
        species: MalariaSpecies.plasmodiumVivax,
        isEndemicArea: true,
      );
      expect(pvResult.treatmentRegimen, contains('Chloroquine'));
      expect(pvResult.treatmentRegimen, contains('Primaquine'));

      final negResult = cdService.evaluateMalariaRdt(
        memberId: 'mem_mother_001',
        species: MalariaSpecies.negative,
        isEndemicArea: false,
      );
      expect(negResult.requiresFacilityReferral, isFalse);
    });

    test('21.2: Syndromic cluster analysis detects outbreak above threshold and builds checklist', () {
      final now = DateTime.now();
      final cases = [
        SyndromicCase(
          id: 'c1',
          memberId: 'm1',
          hamletId: 'North Ward',
          syndrome: SyndromeType.acuteDiarrhoealDisease,
          reportedAt: now.subtract(const Duration(days: 1)),
          ageYears: 4,
          gender: 'female',
        ),
        SyndromicCase(
          id: 'c2',
          memberId: 'm2',
          hamletId: 'North Ward',
          syndrome: SyndromeType.acuteDiarrhoealDisease,
          reportedAt: now.subtract(const Duration(days: 2)),
          ageYears: 3,
          gender: 'male',
        ),
        SyndromicCase(
          id: 'c3',
          memberId: 'm3',
          hamletId: 'North Ward',
          syndrome: SyndromeType.acuteDiarrhoealDisease,
          reportedAt: now.subtract(const Duration(days: 2)),
          ageYears: 6,
          gender: 'female',
        ),
      ];

      final alerts = cdService.detectOutbreakClusters(cases, threshold: 3, windowDays: 7);
      expect(alerts.length, 1);
      final alert = alerts.first;
      expect(alert.hamletId, 'North Ward');
      expect(alert.syndrome, SyndromeType.acuteDiarrhoealDisease);
      expect(alert.caseCount, 3);
      expect(alert.supervisorResponseChecklist.any((item) => item.contains('Superchlorinate')), isTrue);
      expect(alert.syncPayload['target_recipients'], contains('MO'));
    });

    test('21.6: Emergency protocols for snake bites and dog bites specify vital DO NOTs and 108', () {
      final snakeProtocol = cdService.getEmergencyProtocol('snake_bite');
      expect(snakeProtocol.helplineNumber, '108');
      expect(snakeProtocol.strictlyForbiddenActions.any((action) => action.contains('DO NOT apply a tight arterial tourniquet')), isTrue);
      expect(snakeProtocol.mandatoryFirstAidSteps.any((step) => step.contains('Immobilize the bitten limb')), isTrue);

      final dogBiteProtocol = cdService.getEmergencyProtocol('rabid_dog_bite');
      expect(dogBiteProtocol.mandatoryFirstAidSteps.any((step) => step.contains('15 minutes')), isTrue);
      expect(dogBiteProtocol.strictlyForbiddenActions.any((action) => action.contains('DO NOT suture')), isTrue);
    });

    test('21.3: Formats IDSP Form S reporting structure', () {
      final sForm = cdService.formatIdspWeeklySForm(
        reportingWeek: 'Week 42 - 2026',
        hamletName: 'North Ward',
        ashaWorkerId: 'worker_sunita',
        cases: [
          SyndromicCase(
            id: 'c1',
            memberId: 'm1',
            hamletId: 'North Ward',
            syndrome: SyndromeType.feverWithChills,
            reportedAt: DateTime.now(),
            ageYears: 24,
            gender: 'female',
          ),
        ],
      );

      expect(sForm['reporting_format'], 'IDSP_FORM_S');
      expect(sForm['total_cases'], 1);
    });
  });

  group('Task 15.3: Other Programs & Life-Stage Coverage (Requirement 22)', () {
    test('22.3: Evaluates PHQ-4 mental health screening and flags high risk with helplines', () {
      final highRisk = otherService.evaluateMentalHealthScreening(
        memberId: 'mem_mother_001',
        feelingNervousAnxious: 3,
        notBeingAbleToStopWorrying: 3,
        littleInterestOrPleasure: 2,
        feelingDownDepressedHopeless: 2,
        hasSelfHarmThoughts: true,
      );

      expect(highRisk.triageFlag, 'RED');
      expect(highRisk.phq4Score, 10);
      expect(highRisk.helplineNumbers['Tele-MANAS (MoHFW National Helpline)'], '14416');
      expect(highRisk.helplineNumbers['iCall Psychosocial Helpline'], '9152987821');

      final normalScreen = otherService.evaluateMentalHealthScreening(
        memberId: 'mem_mother_001',
        feelingNervousAnxious: 0,
        notBeingAbleToStopWorrying: 0,
        littleInterestOrPleasure: 1,
        feelingDownDepressedHopeless: 0,
      );
      expect(normalScreen.triageFlag, 'GREEN');
      expect(normalScreen.phq4Score, 1);
    });

    test('22.4: Disability registration links national schemes for severity >= 40%', () {
      final severeDisability = otherService.registerDisability(
        memberId: 'mem_mother_001',
        disabilityType: 'locomotor',
        percentageSeverity: 60,
      );
      expect(severeDisability.linkedGovernmentSchemes, contains('Unique Disability ID (UDID) Card & Certificate'));
      expect(severeDisability.linkedGovernmentSchemes, contains('National Divyangjan Monthly Pension Scheme'));

      final mildDisability = otherService.registerDisability(
        memberId: 'mem_mother_001',
        disabilityType: 'visual',
        percentageSeverity: 20,
      );
      expect(mildDisability.linkedGovernmentSchemes.length, 1);
    });

    test('22.5: Dynamic OTA program module parses form schema and rules without APK update', () {
      final otaModule = otherService.loadOtaProgramModule({
        'module_key': 'japanese_encephalitis_pilot',
        'version': '1.2.0',
        'program_title': 'JE Surveillance & Vector Control Drive',
        'form_schema': {'fields': ['fever_duration', 'altered_sensorium']},
        'schedule_rules': {'visit_days': [1, 3, 7]},
      });

      expect(otaModule.moduleKey, 'japanese_encephalitis_pilot');
      expect(otaModule.version, '1.2.0');
      expect(otaModule.programTitle, contains('JE Surveillance'));
      expect(otaModule.isActive, isTrue);
    });
  });

  group('Task 15.3: Vital Events Registration & Audits (Requirement 23)', () {
    test('23.1: Civil birth registration outputs standardized CRS Form 1 summary', () async {
      final birth = await vitalService.registerCivilBirth(
        childMemberId: 'child_newborn_01',
        motherMemberId: 'mem_mother_001',
        fatherName: 'Ramesh Kumar',
        dateOfBirth: DateTime(2026, 10, 15),
        timeOfBirth: '04:30 AM',
        placeOfBirth: 'Primary Health Centre Rampur',
        birthWeightGrams: 2800,
        gender: 'female',
        deliveryType: 'normal_vaginal',
      );

      expect(birth.crsHandoverSummary, contains('FORM 1: BIRTH REPORT'));
      expect(birth.crsHandoverSummary, contains('Birth Weight: 2800g'));
      expect(birth.crsHandoverSummary, contains('Ramesh Kumar'));
    });

    test('23.2, 23.4: Death registration cancels pending due tasks and raises MDR supervisor alert', () async {
      // Create pending tasks for member
      await db.into(db.visitSchedules).insert(
            VisitSchedulesCompanion.insert(
              id: 'task_anc_pending',
              memberId: 'mem_mother_001',
              programCode: 'ANC',
              visitType: 'anc_visit',
              dueDate: DateTime.now().millisecondsSinceEpoch,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );

      final outcome = await vitalService.registerDeathAndAudit(
        deceasedMemberId: 'mem_mother_001',
        householdId: 'hh_001',
        dateOfDeath: DateTime.now(),
        placeOfDeath: 'District Hospital',
        presumedCauseOfDeath: 'Postpartum Haemorrhage (PPH)',
        isMaternalDeath: true,
        isInfantDeath: false,
        isUnderFiveChildDeath: false,
        threeDelays: ['Phase 2: Delay in transport due to broken road'],
        primaryContributingCause: 'Severe PPH',
      );

      expect(outcome.cancelledPendingTasksCount, 1);

      // Verify task was marked cancelled in database
      final task = await (db.select(db.visitSchedules)
            ..where((t) => t.id.equals('task_anc_pending')))
          .getSingle();
      expect(task.status, 'cancelled');
      expect(task.skipReason, contains('Beneficiary deceased'));

      // Verify death audit alert queued for supervisors
      final queued = await db.select(db.syncQueue).get();
      expect(queued.any((q) => q.targetTable == 'death_audit_alert'), isTrue);
    });

    test('23.3: Pregnancy loss registers with neutral phrasing, cancels ANC and schedules follow-up', () async {
      // Pending ANC visit
      await db.into(db.visitSchedules).insert(
            VisitSchedulesCompanion.insert(
              id: 'task_anc_mother',
              memberId: 'mem_mother_001',
              programCode: 'ANC',
              visitType: 'anc_visit',
              dueDate: DateTime.now().millisecondsSinceEpoch,
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );

      final lossRecord = await vitalService.recordPregnancyLoss(
        motherMemberId: 'mem_mother_001',
        eventDate: DateTime.now(),
        eventType: 'spontaneous_loss',
        gestationalWeeks: 14,
        neutralClinicalNotes: 'Clinical management at CHC. Recovery supportive care indicated.',
      );

      expect(lossRecord.visibilityRestriction, 'RESTRICTED_ASHA_ANM_MO_ONLY');

      // Verify ANC task cancelled
      final ancTask = await (db.select(db.visitSchedules)
            ..where((t) => t.id.equals('task_anc_mother')))
          .getSingle();
      expect(ancTask.status, 'cancelled');

      // Verify recovery schedule created
      final recoveryTask = await (db.select(db.visitSchedules)
            ..where((t) => t.visitType.equals('post_pregnancy_loss_recovery')))
          .getSingle();
      expect(recoveryTask.memberId, 'mem_mother_001');
    });
  });
}
