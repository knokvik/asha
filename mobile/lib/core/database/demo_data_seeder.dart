import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:asha_platform/core/database/app_database.dart';

/// Pre-populates the local encrypted database with a realistic rural field dataset
/// for investor and clinical evaluation walkthroughs.
class DemoDataSeeder {
  static Future<void> seedIfEmpty(AppDatabase db) async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final dayMs = 24 * 3600 * 1000;
    const workerId = 'asha_sunita_01';

    final existingHouseholds = await db.select(db.households).get();
    if (existingHouseholds.isNotEmpty) {
      await _seedIncentivesAndEncountersIfEmpty(db, workerId, nowMs, dayMs);
      return; // Already seeded households
    }

    // 1. ASHA Worker Profile
    await db.into(db.users).insert(
          UsersCompanion.insert(
            id: workerId,
            name: 'Sunita Sharma',
            role: 'ASHA',
            ashaId: 'ASHA-2026-089',
            areaVillage: const Value('Rampur'),
            areaSubcentre: const Value('Rampur Sub-Centre'),
            createdAt: nowMs - (60 * dayMs),
            updatedAt: nowMs,
          ),
        );

    // 2. Local Facility Directory (PHC, CHC)
    await db.into(db.facilityDirectory).insert(
          FacilityDirectoryCompanion.insert(
            id: 'fac_phc_shahpur',
            name: 'PHC Shahpur Emergency Hospital',
            facilityLevel: 'PHC',
            contactPhone: const Value('+91-94500-11223'),
            latitude: const Value(25.3176),
            longitude: const Value(82.9739),
            servicesJson: const Value('["24x7 Emergency", "Maternity", "Cold Chain", "Basic Lab"]'),
            lastUpdatedAt: nowMs,
          ),
        );

    await db.into(db.facilityDirectory).insert(
          FacilityDirectoryCompanion.insert(
            id: 'fac_chc_rampur',
            name: 'CHC Rampur FRU Referral Hospital',
            facilityLevel: 'CHC',
            contactPhone: const Value('+91-94500-44556'),
            latitude: const Value(25.3280),
            longitude: const Value(82.9850),
            servicesJson: const Value('["FRU", "C-Section", "Blood Storage", "SNCU", "Specialist OPD"]'),
            lastUpdatedAt: nowMs,
          ),
        );

    await db.into(db.facilityDirectory).insert(
          FacilityDirectoryCompanion.insert(
            id: 'fac_bb_district',
            name: 'District Red Cross Blood Bank & Component Lab',
            facilityLevel: 'Blood Bank',
            contactPhone: const Value('+91-94500-77889'),
            latitude: const Value(25.3210),
            longitude: const Value(82.9790),
            servicesJson: const Value('["24x7 Blood Bank", "Platelet Apheresis", "PRBC", "FFP", "Cold Storage"]'),
            lastUpdatedAt: nowMs,
          ),
        );

    // 3. Households & Members
    // Household 1: High-Risk Pregnant Mother (Pooja Devi)
    await db.into(db.households).insert(
          HouseholdsCompanion.insert(
            id: 'hh_01',
            village: 'Rampur',
            headName: 'Ramesh Kumar',
            hamlet: const Value('Ward 2 (Purwa Tola)'),
            createdAt: nowMs - (40 * dayMs),
            updatedAt: nowMs,
            createdBy: workerId,
          ),
        );

    await db.into(db.members).insert(
          MembersCompanion.insert(
            id: 'mem_pooja_01',
            householdId: 'hh_01',
            name: 'Pooja Devi',
            sex: 'F',
            dobApprox: Value(nowMs - (24 * 365 * dayMs)),
            relationshipToHead: const Value('Wife'),
            phone: const Value('9876501122'),
            abhaId: const Value('14-8899-7711-2233'),
            rchId: const Value('RCH-2026-90123'),
            isBpl: const Value(true),
            socialCategory: const Value('OBC'),
            lifecycleStatus: const Value('active'),
            consentStatus: const Value('given'),
            createdAt: nowMs - (40 * dayMs),
            updatedAt: nowMs,
            createdBy: workerId,
          ),
        );

    // Household 2: Postpartum Mother & Newborn (Baby Aarav - HBNC Visit Day 7)
    await db.into(db.households).insert(
          HouseholdsCompanion.insert(
            id: 'hh_02',
            village: 'Rampur',
            headName: 'Vikram Singh',
            hamlet: const Value('Ward 1 (Main Village)'),
            createdAt: nowMs - (15 * dayMs),
            updatedAt: nowMs,
            createdBy: workerId,
          ),
        );

    await db.into(db.members).insert(
          MembersCompanion.insert(
            id: 'mem_kavita_02',
            householdId: 'hh_02',
            name: 'Kavita Singh',
            sex: 'F',
            dobApprox: Value(nowMs - (22 * 365 * dayMs)),
            relationshipToHead: const Value('Wife'),
            phone: const Value('9811223344'),
            abhaId: const Value('14-5544-3322-1100'),
            lifecycleStatus: const Value('active'),
            consentStatus: const Value('given'),
            createdAt: nowMs - (15 * dayMs),
            updatedAt: nowMs,
            createdBy: workerId,
          ),
        );

    await db.into(db.members).insert(
          MembersCompanion.insert(
            id: 'mem_aarav_02',
            householdId: 'hh_02',
            name: 'Baby Aarav',
            sex: 'M',
            dobApprox: Value(nowMs - (7 * dayMs)),
            relationshipToHead: const Value('Son'),
            lifecycleStatus: const Value('active'),
            consentStatus: const Value('given'),
            createdAt: nowMs - (7 * dayMs),
            updatedAt: nowMs,
            createdBy: workerId,
          ),
        );

    // Household 3: Senior Citizen with NCD (Hypertension + Diabetes)
    await db.into(db.households).insert(
          HouseholdsCompanion.insert(
            id: 'hh_03',
            village: 'Rampur',
            headName: 'Ramprasad Verma',
            hamlet: const Value('Ward 3 (Basti)'),
            createdAt: nowMs - (50 * dayMs),
            updatedAt: nowMs,
            createdBy: workerId,
          ),
        );

    await db.into(db.members).insert(
          MembersCompanion.insert(
            id: 'mem_ramprasad_03',
            householdId: 'hh_03',
            name: 'Ramprasad Verma',
            sex: 'M',
            dobApprox: Value(nowMs - (62 * 365 * dayMs)),
            relationshipToHead: const Value('Self'),
            phone: const Value('9822334455'),
            abhaId: const Value('14-3322-1144-5566'),
            lifecycleStatus: const Value('active'),
            consentStatus: const Value('given'),
            createdAt: nowMs - (50 * dayMs),
            updatedAt: nowMs,
            createdBy: workerId,
          ),
        );

    // Household 4: Rural Farming Family with Toddler (Immunization & Nutrition tracking)
    await db.into(db.households).insert(
          HouseholdsCompanion.insert(
            id: 'hh_04',
            village: 'Rampur',
            headName: 'Sunil Yadav',
            hamlet: const Value('Ward 2 (Purwa Tola)'),
            createdAt: nowMs - (30 * dayMs),
            updatedAt: nowMs,
            createdBy: workerId,
          ),
        );

    await db.into(db.members).insert(
          MembersCompanion.insert(
            id: 'mem_priya_04',
            householdId: 'hh_04',
            name: 'Priya Yadav',
            sex: 'F',
            dobApprox: Value(nowMs - (16 * 30 * dayMs)),
            relationshipToHead: const Value('Daughter'),
            phone: const Value('9876543210'),
            abhaId: const Value('14-7711-2244-9988'),
            rchId: const Value('RCH-2025-44551'),
            lifecycleStatus: const Value('active'),
            consentStatus: const Value('given'),
            createdAt: nowMs - (30 * dayMs),
            updatedAt: nowMs,
            createdBy: workerId,
          ),
        );

    // Household 5: Elderly Citizen (Presumptive TB Screening & Nikshay Follow-up)
    await db.into(db.households).insert(
          HouseholdsCompanion.insert(
            id: 'hh_05',
            village: 'Rampur',
            headName: 'Shanti Devi',
            hamlet: const Value('Ward 3 (Basti)'),
            createdAt: nowMs - (45 * dayMs),
            updatedAt: nowMs,
            createdBy: workerId,
          ),
        );

    await db.into(db.members).insert(
          MembersCompanion.insert(
            id: 'mem_shanti_05',
            householdId: 'hh_05',
            name: 'Shanti Devi',
            sex: 'F',
            dobApprox: Value(nowMs - (58 * 365 * dayMs)),
            relationshipToHead: const Value('Self'),
            phone: const Value('9833445566'),
            abhaId: const Value('14-6655-4433-2211'),
            isBpl: const Value(true),
            socialCategory: const Value('SC'),
            lifecycleStatus: const Value('active'),
            consentStatus: const Value('given'),
            createdAt: nowMs - (45 * dayMs),
            updatedAt: nowMs,
            createdBy: workerId,
          ),
        );

    // 4. Clinical Encounter, Triage & RED Referral
    final poojaEncId = 'enc_pooja_$nowMs';
    await db.into(db.clinicalEncounters).insert(
          ClinicalEncountersCompanion.insert(
            id: poojaEncId,
            memberId: 'mem_pooja_01',
            encounterType: 'anc_visit',
            programCode: 'anc',
            encounterDate: nowMs,
            ashaId: workerId,
            status: const Value('completed'),
            visitNotes: const Value('Severe headache, blurred vision, BP 148/96. Triage Flag: RED Emergency Pre-Eclampsia.'),
            createdAt: nowMs,
            updatedAt: nowMs,
            syncStatus: const Value('pending'),
          ),
        );

    await db.into(db.triageResults).insert(
          TriageResultsCompanion.insert(
            id: 'triage_pooja_$nowMs',
            encounterId: poojaEncId,
            flag: 'RED',
            ruleVersionId: 'v1.0-mohfw',
            findingsJson: jsonEncode([
              {'finding': 'High BP: 148/96 mmHg', 'severity': 'danger'},
              {'finding': 'Severe frontal headache', 'severity': 'danger'},
              {'finding': 'Visual disturbance', 'severity': 'danger'},
            ]),
            evaluatedAt: nowMs,
          ),
        );

    await db.into(db.referralRecords).insert(
          ReferralRecordsCompanion.insert(
            id: 'ref_pooja_01',
            encounterId: poojaEncId,
            memberId: 'mem_pooja_01',
            triageFlag: 'RED',
            destinationFacilityId: const Value('fac_phc_shahpur'),
            destinationLevel: const Value('PHC'),
            transportArranged: const Value('108 Ambulance Dispatched'),
            status: const Value('en_route'),
            referralNoteText: const Value('Suspected Pre-Eclampsia / Severe Gestational Hypertension. Emergency stabilization needed.'),
            referralQrData: const Value('{"ref_id":"ref_pooja_01","patient":"Pooja Devi","risk":"RED","bp":"148/96"}'),
            createdAt: nowMs,
            updatedAt: nowMs,
            syncStatus: const Value('pending'),
          ),
        );

    // 4b. Reported Disease Outbreak Cases (Dengue Hotspot in Catchment)
    final dengueEncId1 = 'enc_dengue_kavita_$nowMs';
    await db.into(db.clinicalEncounters).insert(
          ClinicalEncountersCompanion.insert(
            id: dengueEncId1,
            memberId: 'mem_kavita_02',
            encounterType: 'fever_survey',
            programCode: 'vector_borne',
            encounterDate: nowMs - (1 * dayMs),
            ashaId: workerId,
            status: const Value('completed'),
            visitNotes: const Value('High continuous fever 103.5°F, retro-orbital headache, body ache. Platelets: 54,000/µL. Triage Flag: RED Emergency Dengue.'),
            createdAt: nowMs - (1 * dayMs),
            updatedAt: nowMs,
            syncStatus: const Value('pending'),
          ),
        );

    await db.into(db.triageResults).insert(
          TriageResultsCompanion.insert(
            id: 'triage_dengue1_$nowMs',
            encounterId: dengueEncId1,
            flag: 'RED',
            ruleVersionId: 'v1.0-mohfw',
            findingsJson: jsonEncode([
              {'finding': 'High Fever: 103.5°F continuous', 'severity': 'danger'},
              {'finding': 'Severe retro-orbital pain & arthralgia', 'severity': 'danger'},
              {'finding': 'Platelet count: 54,000/µL (Critical)', 'severity': 'danger'},
              {'finding': 'Dengue NS1 Rapid Antigen Positive', 'severity': 'danger'},
            ]),
            evaluatedAt: nowMs - (1 * dayMs),
          ),
        );

    final dengueEncId2 = 'enc_dengue_ramprasad_$nowMs';
    await db.into(db.clinicalEncounters).insert(
          ClinicalEncountersCompanion.insert(
            id: dengueEncId2,
            memberId: 'mem_ramprasad_03',
            encounterType: 'fever_survey',
            programCode: 'vector_borne',
            encounterDate: nowMs,
            ashaId: workerId,
            status: const Value('completed'),
            visitNotes: const Value('Fever Day 4, abdominal pain, petechiae spots on forearm. Triage Flag: RED Dengue Warning Signs.'),
            createdAt: nowMs,
            updatedAt: nowMs,
            syncStatus: const Value('pending'),
          ),
        );

    await db.into(db.triageResults).insert(
          TriageResultsCompanion.insert(
            id: 'triage_dengue2_$nowMs',
            encounterId: dengueEncId2,
            flag: 'RED',
            ruleVersionId: 'v1.0-mohfw',
            findingsJson: jsonEncode([
              {'finding': 'Dengue Warning Signs: Persistent abdominal pain', 'severity': 'danger'},
              {'finding': 'Petechiae / mucosal bleeding risk', 'severity': 'danger'},
              {'finding': 'High fever 102.8°F with dehydration', 'severity': 'danger'},
            ]),
            evaluatedAt: nowMs,
          ),
        );

    // 4c. Presumptive TB Screening Encounter & Triage
    final tbEncId = 'enc_tb_shanti_$nowMs';
    await db.into(db.clinicalEncounters).insert(
          ClinicalEncountersCompanion.insert(
            id: tbEncId,
            memberId: 'mem_shanti_05',
            encounterType: 'tb_screening',
            programCode: 'tb',
            encounterDate: nowMs - (2 * dayMs),
            ashaId: workerId,
            status: const Value('completed'),
            visitNotes: const Value('Persistent cough >2 weeks, low-grade evening fever, loss of appetite. Sputum container given for PHC testing.'),
            createdAt: nowMs - (2 * dayMs),
            updatedAt: nowMs - (2 * dayMs),
            syncStatus: const Value('pending'),
          ),
        );

    await db.into(db.triageResults).insert(
          TriageResultsCompanion.insert(
            id: 'triage_tb_$nowMs',
            encounterId: tbEncId,
            flag: 'YELLOW',
            ruleVersionId: 'v1.0-mohfw',
            findingsJson: jsonEncode([
              {'finding': 'Chronic productive cough (>14 days)', 'severity': 'warning'},
              {'finding': 'Intermittent evening low-grade fever', 'severity': 'warning'},
              {'finding': 'Unintentional weight loss & loss of appetite', 'severity': 'warning'},
            ]),
            evaluatedAt: nowMs - (2 * dayMs),
          ),
        );

    // 5. Scheduled Due List Tasks
    await db.into(db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: 'task_due_01',
            memberId: 'mem_pooja_01',
            programCode: 'anc',
            visitType: 'RED Emergency Referral Follow-up (PHC)',
            dueDate: nowMs,
            dueWindowStart: Value(nowMs - (1 * dayMs)),
            dueWindowEnd: Value(nowMs + (1 * dayMs)),
            status: const Value('due'),
            createdAt: nowMs,
          ),
        );

    await db.into(db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: 'task_due_02',
            memberId: 'mem_aarav_02',
            programCode: 'hbnc',
            visitType: 'HBNC Day 7 Newborn Check & Temperature',
            dueDate: nowMs,
            dueWindowStart: Value(nowMs - (1 * dayMs)),
            dueWindowEnd: Value(nowMs + (2 * dayMs)),
            status: const Value('due'),
            createdAt: nowMs - (7 * dayMs),
          ),
        );

    await db.into(db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: 'task_due_03',
            memberId: 'mem_ramprasad_03',
            programCode: 'ncd',
            visitType: 'NCD CBAC Checklist & Blood Pressure Check',
            dueDate: nowMs - (2 * dayMs),
            dueWindowStart: Value(nowMs - (5 * dayMs)),
            dueWindowEnd: Value(nowMs - (1 * dayMs)),
            status: const Value('overdue'),
            createdAt: nowMs - (10 * dayMs),
          ),
        );

    await db.into(db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: 'task_due_04',
            memberId: 'mem_kavita_02',
            programCode: 'vhsnd',
            visitType: 'VHSND Village Health, Sanitation & Nutrition Day',
            dueDate: nowMs + (3 * dayMs),
            dueWindowStart: Value(nowMs + (1 * dayMs)),
            dueWindowEnd: Value(nowMs + (5 * dayMs)),
            status: const Value('pending'),
            createdAt: nowMs,
          ),
        );

    await db.into(db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: 'task_due_05',
            memberId: 'mem_priya_04',
            programCode: 'immunization',
            visitType: 'Routine Immunization: MR-1 & DPT Booster-1',
            dueDate: nowMs,
            dueWindowStart: Value(nowMs - (7 * dayMs)),
            dueWindowEnd: Value(nowMs + (7 * dayMs)),
            status: const Value('due'),
            createdAt: nowMs - (14 * dayMs),
          ),
        );

    await db.into(db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: 'task_due_06',
            memberId: 'mem_shanti_05',
            programCode: 'tb',
            visitType: 'Presumptive TB Sputum Collection & Nikshay Registration',
            dueDate: nowMs - (1 * dayMs),
            dueWindowStart: Value(nowMs - (3 * dayMs)),
            dueWindowEnd: Value(nowMs - (1 * dayMs)),
            status: const Value('overdue'),
            createdAt: nowMs - (4 * dayMs),
          ),
        );

    await db.into(db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: 'task_due_07',
            memberId: 'mem_kavita_02',
            programCode: 'pnc',
            visitType: 'PNC Day 14 Maternal Health & Postpartum Recovery',
            dueDate: nowMs + (7 * dayMs),
            dueWindowStart: Value(nowMs + (5 * dayMs)),
            dueWindowEnd: Value(nowMs + (9 * dayMs)),
            status: const Value('pending'),
            createdAt: nowMs - (7 * dayMs),
          ),
        );

    await db.into(db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: 'task_due_08',
            memberId: 'mem_priya_04',
            programCode: 'nutrition',
            visitType: 'SAM/MAM Screening: MUAC Tape & Growth Faltering Check',
            dueDate: nowMs + (2 * dayMs),
            dueWindowStart: Value(nowMs),
            dueWindowEnd: Value(nowMs + (5 * dayMs)),
            status: const Value('pending'),
            createdAt: nowMs,
          ),
        );

    // 6. Consumable Stock in ASHA Kit
    final stockItems = [
      ('item_ifa', 'IFA_TAB', 'Iron Folic Acid (IFA) Tablets', 120.0, 'Tablets'),
      ('item_ors', 'ORS_PKT', 'Oral Rehydration Salts (ORS)', 18.0, 'Packets'),
      ('item_zinc', 'ZINC_20', 'Zinc Dispersible Tablets (20mg)', 40.0, 'Tablets'),
      ('item_pcm', 'PCM_500', 'Paracetamol 500mg', 60.0, 'Tablets'),
      ('item_chhaya', 'CHHAYA', 'Centchroman (Chhaya Oral Contraceptive)', 10.0, 'Strips'),
      ('item_nirodh', 'NIRODH', 'Nirodh Condoms', 35.0, 'Pieces'),
      ('item_rdt', 'MAL_RDT', 'Malaria Rapid Diagnostic Test (RDT)', 12.0, 'Kits'),
      ('item_cdk', 'CDK_KIT', 'Clean Delivery Kit (Disposable)', 2.0, 'Kits'),
    ];

    for (final item in stockItems) {
      await db.into(db.stockItems).insert(
            StockItemsCompanion.insert(
              id: item.$1,
              workerId: workerId,
              itemCode: item.$2,
              itemName: item.$3,
              quantity: Value(item.$4),
              unit: item.$5,
              lastUpdatedAt: nowMs,
            ),
          );
    }

    // 7. ASHA Earnings & Incentive Claims & Events
    await _seedIncentivesAndEncountersIfEmpty(db, workerId, nowMs, dayMs);
  }

  static Future<void> _seedIncentivesAndEncountersIfEmpty(
    AppDatabase db,
    String workerId,
    int nowMs,
    int dayMs,
  ) async {
    final existingEvents = await db.select(db.incentiveEvents).get();
    if (existingEvents.isEmpty) {
      final eventsData = [
        ('ANC_REG_EARLY', 'mem_pooja_01', 'approved', nowMs - (18 * dayMs)),
        ('ANC_CHECKUP_FULL', 'mem_pooja_01', 'approved', nowMs - (14 * dayMs)),
        ('INST_DELIVERY_ESCORT', 'mem_kavita_02', 'approved', nowMs - (8 * dayMs)),
        ('HBNC_COMPLETE', 'mem_aarav_02', 'eligible', nowMs - (3 * dayMs)),
        ('IMMUNIZATION_FULL_1YR', 'mem_priya_04', 'eligible', nowMs - (2 * dayMs)),
        ('CBAC_SCREENING', 'mem_ramprasad_03', 'paid', nowMs - (35 * dayMs)),
        ('TB_DOTS_SUPPORT', 'mem_shanti_05', 'paid', nowMs - (38 * dayMs)),
        ('VHSND_SESSION', 'mem_kavita_02', 'paid', nowMs - (42 * dayMs)),
      ];

      for (var i = 0; i < eventsData.length; i++) {
        final ev = eventsData[i];
        await db.into(db.incentiveEvents).insertOnConflictUpdate(
              IncentiveEventsCompanion.insert(
                id: 'ev_demo_$i',
                memberId: ev.$2,
                activityCode: ev.$1,
                catalogueVersionId: 'NHM_NAT_2024_V1',
                eventDate: ev.$4,
                status: Value(ev.$3),
                createdAt: ev.$4,
                idempotencyKey: 'idem_ev_$i',
                syncStatus: const Value('synced'),
              ),
            );
      }
    }

    final existingClaims = await db.select(db.incentiveClaims).get();
    if (existingClaims.isEmpty) {
      final lineItemsOct = [
        {'activity_code': 'ANC_REG_EARLY', 'description': 'Early ANC registration (<12 wks) - Pooja Devi', 'amount': 300.0, 'date': '2026-10-02'},
        {'activity_code': 'INST_DELIVERY_ESCORT', 'description': 'Institutional delivery escort - Kavita Singh', 'amount': 600.0, 'date': '2026-10-09'},
        {'activity_code': 'HBNC_COMPLETE', 'description': 'HBNC home visits package - Baby Aarav', 'amount': 250.0, 'date': '2026-10-12'},
      ];

      await db.into(db.incentiveClaims).insertOnConflictUpdate(
            IncentiveClaimsCompanion.insert(
              id: 'claim_2026_10',
              workerId: workerId,
              claimPeriod: '2026-10',
              status: const Value('approved'),
              lineItemsJson: Value(jsonEncode(lineItemsOct)),
              totalAmount: const Value(1150.0),
              submittedAt: Value(nowMs - (2 * dayMs)),
              paymentReference: const Value('PFMS-PENDING-DBT'),
              syncStatus: const Value('synced'),
            ),
          );

      final lineItemsSep = [
        {'activity_code': 'CBAC_SCREENING', 'description': 'CBAC screening 30+ adults - Ramprasad', 'amount': 150.0, 'date': '2026-09-12'},
        {'activity_code': 'TB_DOTS_SUPPORT', 'description': 'TB Treatment Support - Shanti Devi', 'amount': 500.0, 'date': '2026-09-18'},
        {'activity_code': 'VHSND_SESSION', 'description': 'VHSND monthly mobilization', 'amount': 200.0, 'date': '2026-09-22'},
      ];

      await db.into(db.incentiveClaims).insertOnConflictUpdate(
            IncentiveClaimsCompanion.insert(
              id: 'claim_2026_09',
              workerId: workerId,
              claimPeriod: '2026-09',
              status: const Value('paid'),
              lineItemsJson: Value(jsonEncode(lineItemsSep)),
              totalAmount: const Value(850.0),
              submittedAt: Value(nowMs - (32 * dayMs)),
              paidAt: Value(nowMs - (28 * dayMs)),
              paymentReference: const Value('PFMS-DBT-20260930-9941'),
              syncStatus: const Value('synced'),
            ),
          );
    }
  }
}
