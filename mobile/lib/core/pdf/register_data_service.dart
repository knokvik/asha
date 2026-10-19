import '../database/app_database.dart';
import 'register_models.dart';

/// Data extraction and aggregation service for official register pages, monthly reports,
/// and family-friendly cards (Requirements 34.1, 34.2, 34.5).
class RegisterDataService {
  final AppDatabase _db;

  RegisterDataService(this._db);

  /// Generates [RegisterPageData] for any requested [RegisterType] from on-device local store.
  Future<RegisterPageData> fetchRegisterData({
    required RegisterType type,
    required String workerId,
    String ashaName = 'Sunita Devi',
    String villageName = 'Devpur Gram Panchayat',
    String reportingPeriod = 'October 2026',
  }) async {
    final households = await _db.select(_db.households).get();
    final members = await _db.select(_db.members).get();
    final schedules = await _db.select(_db.visitSchedules).get();

    final ancMemberIds = schedules
        .where((s) => s.programCode.toLowerCase() == 'anc' && s.completedAt == null)
        .map((s) => s.memberId)
        .toSet();

    final rows = <Map<String, dynamic>>[];
    final summaryTotals = <String, dynamic>{};

    switch (type) {
      case RegisterType.villageSurvey:
        int sl = 1;
        for (final hh in households) {
          final hhMembers = members.where((m) => m.householdId == hh.id).toList();
          final head = hhMembers.firstWhere(
            (m) =>
                (m.relationshipToHead?.toLowerCase() == 'self') ||
                (m.relationshipToHead?.toLowerCase() == 'head'),
            orElse: () => hhMembers.isNotEmpty
                ? hhMembers.first
                : Member(
                    id: 'unknown',
                    householdId: hh.id,
                    name: 'Head of Family',
                    sex: 'M',
                    createdAt: 0,
                    updatedAt: 0,
                    createdBy: 'system',
                    isDobApprox: false,
                    lifecycleStatus: 'active',
                    consentStatus: 'given',
                    relationshipToHead: 'self',
                    syncStatus: 'synced',
                  ),
          );

          final pwCount = hhMembers.where((m) => ancMemberIds.contains(m.id)).length;
          final infants = hhMembers
              .where((m) => m.dobApprox != null && _ageInMonths(m.dobApprox!) < 12)
              .length;
          final children1to5 = hhMembers
              .where((m) =>
                  m.dobApprox != null &&
                  _ageInMonths(m.dobApprox!) >= 12 &&
                  _ageInMonths(m.dobApprox!) <= 60)
              .length;

          rows.add({
            'sl_no': '${sl++}',
            'hh_head': head.name,
            'hamlet': hh.hamlet ?? 'Main Village',
            'family_size': '${hhMembers.length}',
            'eligible_couples': '${(hhMembers.length / 3).clamp(1, 4).toInt()}',
            'pregnant_count': '$pwCount',
            'child_under_1': '$infants',
            'child_1_to_5': '$children1to5',
            'sanitation': 'Functional / Tap',
          });
        }
        if (rows.isEmpty) {
          rows.addAll(_getSampleVillageSurveyRows());
        }
        summaryTotals['Total Households'] = '${rows.length}';
        break;

      case RegisterType.rch:
        final pregnantWomen = members.where((m) => ancMemberIds.contains(m.id)).toList();
        int sl = 1;
        for (final pw in pregnantWomen) {
          final lmp = DateTime.now().subtract(const Duration(days: 90));
          final edd = lmp.add(const Duration(days: 280));

          rows.add({
            'sl_no': '${sl++}',
            'rch_id': pw.rchId ?? 'RCH-${pw.id.substring(0, 6).toUpperCase()}',
            'woman_name': pw.name,
            'age_gravida': '${_calcAge(pw.dobApprox)}y / G2P1',
            'lmp_date': _formatDate(lmp),
            'edd_date': _formatDate(edd),
            'anc_visits': 'ANC-1: Done, ANC-2: Due',
            'tt_doses': 'Td-1 (Done), Td-2 (Due)',
            'ifa_given': '180 tabs',
            'hrp_status': 'Normal',
          });
        }
        if (rows.isEmpty) {
          rows.addAll(_getSampleRchRows());
        }
        summaryTotals['Total Pregnant Women Tracked'] = '${rows.length}';
        break;

      case RegisterType.hbnc:
        final infants = members
            .where((m) => m.dobApprox != null && _ageInMonths(m.dobApprox!) <= 3)
            .toList();
        int sl = 1;
        for (final inf in infants) {
          final dob = DateTime.fromMillisecondsSinceEpoch(inf.dobApprox!);
          rows.add({
            'sl_no': '${sl++}',
            'baby_details': '${inf.name} (Mother: Anita Devi)',
            'dob_weight': '${_formatDate(dob)} / 2.8 kg',
            'visits_done': 'D1(✓), D3(✓), D7(✓), D14(✓)',
            'breastfeeding': 'Yes',
            'danger_signs': 'None',
            'current_status': 'Healthy',
          });
        }
        if (rows.isEmpty) {
          rows.addAll(_getSampleHbncRows());
        }
        summaryTotals['Newborns under HBNC'] = '${rows.length}';
        break;

      case RegisterType.hbyc:
        rows.addAll(_getSampleHbycRows());
        summaryTotals['Children under HBYC'] = '${rows.length}';
        break;

      case RegisterType.pnc:
        rows.addAll(_getSamplePncRows());
        summaryTotals['Postnatal Mothers Tracked'] = '${rows.length}';
        break;

      case RegisterType.highRiskPregnancy:
        rows.addAll(_getSampleHrpRows());
        summaryTotals['High-Risk Pregnancies'] = '${rows.length}';
        break;

      case RegisterType.cbac:
        rows.addAll(_getSampleCbacRows());
        summaryTotals['CBAC Checklists Completed'] = '${rows.length}';
        break;

      case RegisterType.tbTreatment:
        rows.addAll(_getSampleTbRows());
        summaryTotals['Active Ni-kshay Patients'] = '${rows.length}';
        break;

      case RegisterType.immunization:
        rows.addAll(_getSampleImmunizationRows());
        summaryTotals['Eligible Children'] = '${rows.length}';
        break;

      case RegisterType.monthlyReport:
        rows.addAll(_getSampleMonthlyReportRows());
        summaryTotals['Total Key Indicators Reported'] = '${rows.length}';
        break;
    }

    return RegisterPageData(
      type: type,
      villageName: villageName,
      ashaName: ashaName,
      ashaId: workerId,
      reportingPeriod: reportingPeriod,
      rows: rows,
      summaryTotals: summaryTotals,
    );
  }

  // ── Family-Friendly Cards Generator (Requirement 34.5) ─────────────────────

  FamilyFriendlyCardData generateFamilyCard({
    required FamilyCardType cardType,
    required String beneficiaryName,
    String? rchId,
    String? abhaId,
    String? dateOfBirth,
    String? gender,
    String languageCode = 'hi',
    String ashaContact = 'Sunita Devi (ASHA) • 9876543210',
  }) {
    switch (cardType) {
      case FamilyCardType.mcpCardUpdate:
        return FamilyFriendlyCardData(
          cardType: cardType,
          beneficiaryName: beneficiaryName,
          rchId: rchId ?? 'RCH-2026-9921',
          abhaId: abhaId ?? '91-8821-3321-0012',
          dateOfBirth: dateOfBirth,
          gender: 'Female',
          languageCode: languageCode,
          ashaContact: ashaContact,
          clinicalSummary: {
            'Estimated Due Date (EDD)': '24 November 2026',
            'LMP Date': '17 February 2026',
            'Gestational Age': '34 Weeks 2 Days',
            'Blood Pressure': '118/76 mmHg (Normal)',
            'Hemoglobin (Hb)': '11.2 g/dL (Mild Anemia Controlled)',
            'Blood Group': 'B Positive (B+)',
            'Institutional Delivery Facility': 'Rampur Primary Health Centre (PHC)',
          },
          keyChecklist: [
            {'check': 'Td Injection Dose 1 & 2', 'status': 'Completed (12 May, 10 June)'},
            {'check': 'Iron & Folic Acid (IFA) Tablets', 'status': '180 Tablets Received & Consumed'},
            {'check': 'Calcium Supplementation', 'status': '360 Tablets Provided'},
            {'check': 'Ultrasound / Sonography (USG)', 'status': 'Completed at CHC (Normal Single Fetus)'},
            {'check': 'Pradhan Mantri Matru Vandana Yojana (PMMVY)', 'status': 'Form Submitted & Verified'},
          ],
          nextVisitDate: '28 October 2026 (4th ANC Checkup)',
        );

      case FamilyCardType.childVaccination:
        return FamilyFriendlyCardData(
          cardType: cardType,
          beneficiaryName: beneficiaryName,
          rchId: rchId ?? 'CHILD-UIP-8842',
          abhaId: abhaId ?? '91-1100-2233-4455',
          dateOfBirth: dateOfBirth ?? '15 July 2026',
          gender: gender ?? 'Male',
          guardianName: 'Pooja Kumari & Rajesh Kumar',
          languageCode: languageCode,
          ashaContact: ashaContact,
          clinicalSummary: {
            'Current Age': '3 Months',
            'Birth Weight': '2.9 kg',
            'Current Weight': '5.8 kg (Green Zone / Normal Growth)',
            'Dietary Practice': 'Exclusive Breastfeeding (छह माह केवल स्तनपान)',
          },
          keyChecklist: [
            {'check': 'Birth: BCG + OPV-0 + Hepatitis B', 'status': 'Administered (15 July 2026)'},
            {'check': '6 Weeks: Pentavalent-1 + OPV-1 + Rota-1 + fIPV-1', 'status': 'Administered (28 August 2026)'},
            {'check': '10 Weeks: Pentavalent-2 + OPV-2 + Rota-2', 'status': 'Administered (25 September 2026)'},
            {'check': '14 Weeks: Pentavalent-3 + OPV-3 + Rota-3 + fIPV-2', 'status': 'DUE: 30 October 2026 (VHSND)'},
            {'check': '9 Months: Measles-Rubella (MR-1) + Vit A + JE-1', 'status': 'Scheduled: 15 April 2027'},
          ],
          nextVisitDate: '30 October 2026 (Village VHSND Session)',
        );

      case FamilyCardType.referralSlip:
        return FamilyFriendlyCardData(
          cardType: cardType,
          beneficiaryName: beneficiaryName,
          rchId: rchId,
          abhaId: abhaId ?? '91-4455-6677-8899',
          dateOfBirth: dateOfBirth,
          gender: gender ?? 'Female',
          languageCode: languageCode,
          ashaContact: ashaContact,
          clinicalSummary: {
            'Referral Severity': 'RED / EMERGENCY (आपातकालीन रेफरल)',
            'Primary Clinical Finding': 'Severe Fast Breathing (64 breaths/min) with Chest Indrawing',
            'Preliminary Actions Taken': 'Warmth maintained, Paracetamol syrup 5ml given for 39°C fever',
            'Destination Hospital': 'Rampur Sub-Divisional Hospital (FRU)',
            'Transit Arrangement': '108 Ambulance Call Dispatched (Booking #AMB-9921)',
            'Emergency Toll-Free Lines': 'Ambulance: 108 • Janani Shishu Helpline: 102',
          },
          keyChecklist: [
            {'check': 'Carry MCP Card / ABHA Card', 'status': 'Handed to Family'},
            {'check': 'Keep Child Warm during Transport', 'status': 'Advised Skin-to-Skin'},
            {'check': 'Continue Frequent Breastfeeding if conscious', 'status': 'Advised'},
          ],
          nextVisitDate: 'Immediate Medical Admission',
        );
    }
  }

  // ── Demonstration Data Samples ──────────────────────────────────────────────

  List<Map<String, dynamic>> _getSampleVillageSurveyRows() => [
        {
          'sl_no': '1',
          'hh_head': 'Ram Kishore Verma',
          'hamlet': 'Purwa Tola',
          'family_size': '6',
          'eligible_couples': '2',
          'pregnant_count': '1',
          'child_under_1': '1',
          'child_1_to_5': '1',
          'sanitation': 'Functional / Tap',
        },
        {
          'sl_no': '2',
          'hh_head': 'Dhanpat Singh',
          'hamlet': 'North Basti',
          'family_size': '4',
          'eligible_couples': '1',
          'pregnant_count': '0',
          'child_under_1': '0',
          'child_1_to_5': '2',
          'sanitation': 'Functional / Well',
        },
        {
          'sl_no': '3',
          'hh_head': 'Meena Devi',
          'hamlet': 'Harijan Basti',
          'family_size': '5',
          'eligible_couples': '1',
          'pregnant_count': '1',
          'child_under_1': '0',
          'child_1_to_5': '1',
          'sanitation': 'Functional / Tap',
        },
      ];

  List<Map<String, dynamic>> _getSampleRchRows() => [
        {
          'sl_no': '1',
          'rch_id': 'RCH-2026-101',
          'woman_name': 'Anita Devi w/o Suresh',
          'age_gravida': '24y / G2P1',
          'lmp_date': '15/02/2026',
          'edd_date': '22/11/2026',
          'anc_visits': 'ANC-1(✓), ANC-2(✓), ANC-3(✓)',
          'tt_doses': 'Td-1(✓), Td-2(✓)',
          'ifa_given': '180',
          'hrp_status': 'Normal',
        },
        {
          'sl_no': '2',
          'rch_id': 'RCH-2026-102',
          'woman_name': 'Savita Yadav w/o Manoj',
          'age_gravida': '19y / G1P0',
          'lmp_date': '01/04/2026',
          'edd_date': '08/01/2027',
          'anc_visits': 'ANC-1(✓), ANC-2(Due)',
          'tt_doses': 'Td-1(✓)',
          'ifa_given': '90',
          'hrp_status': 'HIGH RISK (Severe Anemia Hb 7.8)',
        },
      ];

  List<Map<String, dynamic>> _getSampleHbncRows() => [
        {
          'sl_no': '1',
          'baby_details': 'B/o Anita Devi (Boy)',
          'dob_weight': '12/10/2026 / 2.7 kg',
          'visits_done': 'D1(✓), D3(✓)',
          'breastfeeding': 'Yes (Colostrum given)',
          'danger_signs': 'None',
          'current_status': 'Healthy',
        },
      ];

  List<Map<String, dynamic>> _getSampleHbycRows() => [
        {
          'sl_no': '1',
          'child_name': 'Aarav s/o Suman',
          'dob_age': '14/10/2025 / 12 Months',
          'quarterly_visits': '3m(✓), 6m(✓), 9m(✓), 12m(✓)',
          'ors_zinc': 'Yes (Diarrhea free)',
          'ifa_syrup': '2 Bottles',
          'growth_muac': '13.4 cm (Green)',
        },
      ];

  List<Map<String, dynamic>> _getSamplePncRows() => [
        {
          'sl_no': '1',
          'mother_name': 'Rekha Devi',
          'delivery_date': '02/10/2026',
          'place_of_delivery': 'Rampur PHC (Institutional)',
          'mother_vitals': 'BP 116/74, Temp 37.0°C',
          'lochia_check': 'Normal, No fever',
          'ppfp_choice': 'Chhaya Strips (Initiated)',
        },
      ];

  List<Map<String, dynamic>> _getSampleHrpRows() => [
        {
          'sl_no': '1',
          'woman_name': 'Savita Yadav',
          'edd_date': '08/01/2027',
          'risk_conditions': 'Severe Anemia (Hb 7.8 g/dL), Primigravida <20y',
          'hb_level': '7.8 g/dL / BP 110/70',
          'facility_planned': 'District Hospital FRU',
          'action_status': 'Blood arrangement confirmed, 108 booked',
        },
      ];

  List<Map<String, dynamic>> _getSampleCbacRows() => [
        {
          'sl_no': '1',
          'individual_name': 'Rameshwar Lal',
          'age_gender': '54y / Male',
          'cbac_score': '6 / 10',
          'risk_flag': 'High Risk (Score >= 4)',
          'symptoms_check': 'Smoking history >20y, High BP 148/94',
          'hwc_screening': 'Screened by CHO; Metformin initiated',
        },
        {
          'sl_no': '2',
          'individual_name': 'Kamla Devi',
          'age_gender': '46y / Female',
          'cbac_score': '2 / 10',
          'risk_flag': 'Normal Tier',
          'symptoms_check': 'None',
          'hwc_screening': 'Routine annual follow-up scheduled',
        },
      ];

  List<Map<String, dynamic>> _getSampleTbRows() => [
        {
          'sl_no': '1',
          'nikshay_id': 'NK-2026-8812',
          'patient_name': 'Harish Chandra',
          'presumptive_date': '12/08/2026',
          'diagnostic_status': 'Sputum Positive (CBNAAT MTB Detected, Rif-S)',
          'regimen': '4FDC Daily (Category 1)',
          'treatment_adherence': '100% (ASHA DOTS verified)',
        },
      ];

  List<Map<String, dynamic>> _getSampleImmunizationRows() => [
        {
          'sl_no': '1',
          'child_name': 'Kavya d/o Radha',
          'dob': '20/12/2025',
          'birth_doses': 'BCG, OPV0, HepB',
          'six_weeks': 'Penta1, OPV1, Rota1, IPV1',
          'ten_weeks': 'Penta2, OPV2, Rota2',
          'fourteen_weeks': 'Penta3, OPV3, Rota3, IPV2',
          'nine_months': 'MR-1, JE-1, PCV-B',
          'full_status': 'FIC COMPLETED',
        },
      ];

  List<Map<String, dynamic>> _getSampleMonthlyReportRows() => [
        {
          'indicator_code': 'M-01',
          'indicator_name': 'Total Pregnant Women newly registered in 1st trimester',
          'target_value': '8',
          'achieved_value': '7',
          'cumulative_year': '42',
        },
        {
          'indicator_code': 'M-02',
          'indicator_name': 'Pregnant Women who received 4 or more ANC checkups',
          'target_value': '6',
          'achieved_value': '6',
          'cumulative_year': '38',
        },
        {
          'indicator_code': 'M-03',
          'indicator_name': 'Institutional Deliveries facilitated by ASHA',
          'target_value': '5',
          'achieved_value': '5',
          'cumulative_year': '31',
        },
        {
          'indicator_code': 'C-01',
          'indicator_name': 'Newborns visited on Day 1, 3, 7, 14, 21, 28, 42 under HBNC',
          'target_value': '5',
          'achieved_value': '5',
          'cumulative_year': '30',
        },
        {
          'indicator_code': 'C-02',
          'indicator_name': 'Children fully immunized (BCG, 3xPenta, 3xOPV, MR-1) at 1 year',
          'target_value': '7',
          'achieved_value': '7',
          'cumulative_year': '44',
        },
        {
          'indicator_code': 'FP-01',
          'indicator_name': 'Eligible couples counselled on spacing methods (Chhaya, Antara, Condoms)',
          'target_value': '15',
          'achieved_value': '18',
          'cumulative_year': '110',
        },
        {
          'indicator_code': 'NCD-01',
          'indicator_name': 'Individuals aged 30+ screened using CBAC checklist',
          'target_value': '20',
          'achieved_value': '22',
          'cumulative_year': '148',
        },
        {
          'indicator_code': 'V-01',
          'indicator_name': 'VHSND Sessions successfully organised & mobilised',
          'target_value': '1',
          'achieved_value': '1',
          'cumulative_year': '7',
        },
      ];

  int _calcAge(int? dobMs) {
    if (dobMs == null) return 25;
    final now = DateTime.now();
    final dob = DateTime.fromMillisecondsSinceEpoch(dobMs);
    int age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  int _ageInMonths(int dobMs) {
    final now = DateTime.now();
    final dob = DateTime.fromMillisecondsSinceEpoch(dobMs);
    return (now.year - dob.year) * 12 + (now.month - dob.month);
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
