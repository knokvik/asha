import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:asha_platform/core/database/app_database.dart';

/// Pre-populates the local encrypted database with a realistic rural field dataset
/// for investor and clinical evaluation walkthroughs.
class DemoDataSeeder {
  static Future<void> seedIfEmpty(AppDatabase db) async {
    final existingHouseholds = await db.select(db.households).get();
    if (existingHouseholds.isNotEmpty) return; // Already seeded

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final dayMs = 24 * 3600 * 1000;

    const workerId = 'asha_sunita_01';

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

    // 5. Scheduled Due List Tasks
    await db.into(db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: 'task_due_01',
            memberId: 'mem_pooja_01',
            programCode: 'anc',
            visitType: 'RED Emergency Referral Follow-up (PHC)',
            dueDate: nowMs,
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

    // 7. ASHA Earnings & Incentive Claims (₹ 4,200)
    final lineItems = [
      {'activity_code': 'ANC_REG_EARLY', 'description': 'Early ANC registration (<12 wks) - Pooja Devi', 'amount': 300.0, 'date': '2026-10-02'},
      {'activity_code': 'INST_DELIVERY_ESCORT', 'description': 'Institutional delivery escort - Kavita Singh', 'amount': 600.0, 'date': '2026-10-09'},
      {'activity_code': 'HBNC_HOME_VISITS', 'description': 'HBNC home visits package - Baby Aarav', 'amount': 250.0, 'date': '2026-10-12'},
      {'activity_code': 'IMMUNIZATION_COMPLETE', 'description': 'Complete child immunization tracking', 'amount': 400.0, 'date': '2026-10-05'},
      {'activity_code': 'CBAC_NCD_SCREENING', 'description': 'CBAC screening 30+ adults (15 individuals)', 'amount': 1500.0, 'date': '2026-10-07'},
      {'activity_code': 'VHSND_MOBILIZATION', 'description': 'VHSND monthly community mobilization', 'amount': 200.0, 'date': '2026-10-01'},
      {'activity_code': 'PPIUCD_POSTPARTUM_FP', 'description': 'Postpartum PPIUCD counselling & adoption', 'amount': 300.0, 'date': '2026-10-10'},
      {'activity_code': 'ROUTINE_MONTHLY_MEETING', 'description': 'Monthly PHC review meeting attendance', 'amount': 650.0, 'date': '2026-10-03'},
    ];

    await db.into(db.incentiveClaims).insert(
          IncentiveClaimsCompanion.insert(
            id: 'claim_oct_2026',
            workerId: workerId,
            claimPeriod: 'October 2026',
            status: const Value('submitted'),
            lineItemsJson: Value(jsonEncode(lineItems)),
            totalAmount: const Value(4200.0),
            submittedAt: Value(nowMs - (2 * dayMs)),
            paymentReference: const Value('PFMS-PENDING-APPROVAL'),
            syncStatus: const Value('synced'),
          ),
        );
  }
}
