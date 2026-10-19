import '../../../../core/triage/models/models.dart';

/// Status of an individual vaccine dose for a child.
enum VaccineDoseStatus {
  given,
  due,
  overdue,
  defaulter,
  expired,
  upcoming,
}

/// Clinical severity of Adverse Event Following Immunization (AEFI) (Requirement 16.6).
enum AefiSeverity {
  minor,
  severe,
  serious,
}

/// Session setting where immunization was administered.
enum ImmunizationSessionType {
  vhsnd('VHSND'),
  healthFacility('Health Facility / Sub-Centre'),
  outreach('Outreach Camp'),
  private('Private Clinic / Hospital');

  final String displayName;
  const ImmunizationSessionType(this.displayName);
}

/// Body site of administration per MoHFW guidelines.
enum AdministrationSite {
  leftUpperArm('Left Upper Arm (Intradermal / Subcutaneous)'),
  rightUpperArm('Right Upper Arm (Fractional IPV / MR)'),
  leftMidThigh('Anterolateral Mid-Thigh (Left)'),
  rightMidThigh('Anterolateral Mid-Thigh (Right)'),
  oral('Oral (Drops)'),
  other('Other');

  final String displayName;
  const AdministrationSite(this.displayName);
}

/// Metadata definition of a National Immunization Schedule (NIS) vaccine dose.
class VaccineDefinition {
  final String code;
  final String name;
  final String periodCategory; // AT_BIRTH, 6_WEEKS, 10_WEEKS, 14_WEEKS, 9_12_MONTHS, 16_24_MONTHS, 5_6_YEARS, 10_YEARS, 16_YEARS, PREGNANT_WOMAN
  final int targetAgeDays;
  final int windowStartDays;
  final int windowEndDays;
  final int maxAgeDays; // Upper limit after which dose is omitted/contraindicated
  final String? prerequisiteCode; // Previous dose code if sequential
  final int minimumIntervalDays; // Minimum spacing after prerequisite dose
  final String route; // ORAL, INTRADERMAL, INTRAMUSCULAR, SUBCUTANEOUS
  final AdministrationSite standardSite;
  final String doseVolume;
  final String? incentiveEventCode; // e.g. FULL_IMMUNIZATION_1YR

  const VaccineDefinition({
    required this.code,
    required this.name,
    required this.periodCategory,
    required this.targetAgeDays,
    required this.windowStartDays,
    required this.windowEndDays,
    required this.maxAgeDays,
    this.prerequisiteCode,
    this.minimumIntervalDays = 0,
    required this.route,
    required this.standardSite,
    required this.doseVolume,
    this.incentiveEventCode,
  });
}

/// Official Government of India MoHFW National Immunization Schedule (NIS) Catalog.
class NationalImmunizationCatalog {
  static const List<VaccineDefinition> infantAndChildSchedule = [
    // ── At Birth ─────────────────────────────────────────────────────────────
    VaccineDefinition(
      code: 'BCG',
      name: 'BCG (Bacillus Calmette–Guérin)',
      periodCategory: 'AT_BIRTH',
      targetAgeDays: 0,
      windowStartDays: 0,
      windowEndDays: 14,
      maxAgeDays: 365, // Can be given up to 1 year of age
      route: 'INTRADERMAL',
      standardSite: AdministrationSite.leftUpperArm,
      doseVolume: '0.05 ml (0.1 ml if > 1 month)',
    ),
    VaccineDefinition(
      code: 'OPV_0',
      name: 'OPV-0 (Oral Polio Vaccine Birth Dose)',
      periodCategory: 'AT_BIRTH',
      targetAgeDays: 0,
      windowStartDays: 0,
      windowEndDays: 15,
      maxAgeDays: 15, // Must be given within 15 days of birth
      route: 'ORAL',
      standardSite: AdministrationSite.oral,
      doseVolume: '2 drops',
    ),
    VaccineDefinition(
      code: 'HEPB_0',
      name: 'Hepatitis B (Birth Dose)',
      periodCategory: 'AT_BIRTH',
      targetAgeDays: 0,
      windowStartDays: 0,
      windowEndDays: 1,
      maxAgeDays: 1, // Must be given within 24 hours of birth
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.leftMidThigh,
      doseVolume: '0.5 ml',
    ),

    // ── 6 Weeks ──────────────────────────────────────────────────────────────
    VaccineDefinition(
      code: 'OPV_1',
      name: 'OPV-1 (Oral Polio Vaccine 1)',
      periodCategory: '6_WEEKS',
      targetAgeDays: 42, // 6 weeks
      windowStartDays: 42,
      windowEndDays: 69,
      maxAgeDays: 1825, // Up to 5 years
      route: 'ORAL',
      standardSite: AdministrationSite.oral,
      doseVolume: '2 drops',
    ),
    VaccineDefinition(
      code: 'PENTA_1',
      name: 'Pentavalent-1 (DPT + HepB + Hib)',
      periodCategory: '6_WEEKS',
      targetAgeDays: 42,
      windowStartDays: 42,
      windowEndDays: 69,
      maxAgeDays: 365, // Up to 1 year
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.leftMidThigh,
      doseVolume: '0.5 ml',
    ),
    VaccineDefinition(
      code: 'ROTA_1',
      name: 'Rotavirus-1 (RVV 1)',
      periodCategory: '6_WEEKS',
      targetAgeDays: 42,
      windowStartDays: 42,
      windowEndDays: 69,
      maxAgeDays: 365,
      route: 'ORAL',
      standardSite: AdministrationSite.oral,
      doseVolume: '5 drops',
    ),
    VaccineDefinition(
      code: 'FIPV_1',
      name: 'fIPV-1 (Fractional Inactivated Polio Vaccine 1)',
      periodCategory: '6_WEEKS',
      targetAgeDays: 42,
      windowStartDays: 42,
      windowEndDays: 69,
      maxAgeDays: 365,
      route: 'INTRADERMAL',
      standardSite: AdministrationSite.rightUpperArm,
      doseVolume: '0.1 ml',
    ),
    VaccineDefinition(
      code: 'PCV_1',
      name: 'PCV-1 (Pneumococcal Conjugate Vaccine 1)',
      periodCategory: '6_WEEKS',
      targetAgeDays: 42,
      windowStartDays: 42,
      windowEndDays: 69,
      maxAgeDays: 365,
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.rightMidThigh,
      doseVolume: '0.5 ml',
    ),

    // ── 10 Weeks ─────────────────────────────────────────────────────────────
    VaccineDefinition(
      code: 'OPV_2',
      name: 'OPV-2 (Oral Polio Vaccine 2)',
      periodCategory: '10_WEEKS',
      targetAgeDays: 70, // 10 weeks
      windowStartDays: 70,
      windowEndDays: 97,
      maxAgeDays: 1825,
      prerequisiteCode: 'OPV_1',
      minimumIntervalDays: 28, // 4 weeks
      route: 'ORAL',
      standardSite: AdministrationSite.oral,
      doseVolume: '2 drops',
    ),
    VaccineDefinition(
      code: 'PENTA_2',
      name: 'Pentavalent-2 (DPT + HepB + Hib)',
      periodCategory: '10_WEEKS',
      targetAgeDays: 70,
      windowStartDays: 70,
      windowEndDays: 97,
      maxAgeDays: 365,
      prerequisiteCode: 'PENTA_1',
      minimumIntervalDays: 28, // 4 weeks minimum interval
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.leftMidThigh,
      doseVolume: '0.5 ml',
    ),
    VaccineDefinition(
      code: 'ROTA_2',
      name: 'Rotavirus-2 (RVV 2)',
      periodCategory: '10_WEEKS',
      targetAgeDays: 70,
      windowStartDays: 70,
      windowEndDays: 97,
      maxAgeDays: 365,
      prerequisiteCode: 'ROTA_1',
      minimumIntervalDays: 28,
      route: 'ORAL',
      standardSite: AdministrationSite.oral,
      doseVolume: '5 drops',
    ),

    // ── 14 Weeks ─────────────────────────────────────────────────────────────
    VaccineDefinition(
      code: 'OPV_3',
      name: 'OPV-3 (Oral Polio Vaccine 3)',
      periodCategory: '14_WEEKS',
      targetAgeDays: 98, // 14 weeks
      windowStartDays: 98,
      windowEndDays: 180,
      maxAgeDays: 1825,
      prerequisiteCode: 'OPV_2',
      minimumIntervalDays: 28,
      route: 'ORAL',
      standardSite: AdministrationSite.oral,
      doseVolume: '2 drops',
    ),
    VaccineDefinition(
      code: 'PENTA_3',
      name: 'Pentavalent-3 (DPT + HepB + Hib)',
      periodCategory: '14_WEEKS',
      targetAgeDays: 98,
      windowStartDays: 98,
      windowEndDays: 180,
      maxAgeDays: 365,
      prerequisiteCode: 'PENTA_2',
      minimumIntervalDays: 28,
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.leftMidThigh,
      doseVolume: '0.5 ml',
    ),
    VaccineDefinition(
      code: 'ROTA_3',
      name: 'Rotavirus-3 (RVV 3)',
      periodCategory: '14_WEEKS',
      targetAgeDays: 98,
      windowStartDays: 98,
      windowEndDays: 180,
      maxAgeDays: 365,
      prerequisiteCode: 'ROTA_2',
      minimumIntervalDays: 28,
      route: 'ORAL',
      standardSite: AdministrationSite.oral,
      doseVolume: '5 drops',
    ),
    VaccineDefinition(
      code: 'FIPV_2',
      name: 'fIPV-2 (Fractional Inactivated Polio Vaccine 2)',
      periodCategory: '14_WEEKS',
      targetAgeDays: 98,
      windowStartDays: 98,
      windowEndDays: 180,
      maxAgeDays: 365,
      prerequisiteCode: 'FIPV_1',
      minimumIntervalDays: 28,
      route: 'INTRADERMAL',
      standardSite: AdministrationSite.rightUpperArm,
      doseVolume: '0.1 ml',
    ),
    VaccineDefinition(
      code: 'PCV_2',
      name: 'PCV-2 (Pneumococcal Conjugate Vaccine 2)',
      periodCategory: '14_WEEKS',
      targetAgeDays: 98,
      windowStartDays: 98,
      windowEndDays: 180,
      maxAgeDays: 365,
      prerequisiteCode: 'PCV_1',
      minimumIntervalDays: 28,
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.rightMidThigh,
      doseVolume: '0.5 ml',
    ),

    // ── 9–12 Months ──────────────────────────────────────────────────────────
    VaccineDefinition(
      code: 'MR_1',
      name: 'MR-1 (Measles-Rubella 1)',
      periodCategory: '9_12_MONTHS',
      targetAgeDays: 270, // 9 completed months
      windowStartDays: 270,
      windowEndDays: 365,
      maxAgeDays: 1825, // Up to 5 years
      route: 'SUBCUTANEOUS',
      standardSite: AdministrationSite.rightUpperArm,
      doseVolume: '0.5 ml',
    ),
    VaccineDefinition(
      code: 'JE_1',
      name: 'JE-1 (Japanese Encephalitis 1)',
      periodCategory: '9_12_MONTHS',
      targetAgeDays: 270,
      windowStartDays: 270,
      windowEndDays: 365,
      maxAgeDays: 1825,
      route: 'SUBCUTANEOUS',
      standardSite: AdministrationSite.leftUpperArm,
      doseVolume: '0.5 ml',
    ),
    VaccineDefinition(
      code: 'PCV_BOOSTER',
      name: 'PCV Booster',
      periodCategory: '9_12_MONTHS',
      targetAgeDays: 270,
      windowStartDays: 270,
      windowEndDays: 365,
      maxAgeDays: 365,
      prerequisiteCode: 'PCV_2',
      minimumIntervalDays: 60,
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.rightMidThigh,
      doseVolume: '0.5 ml',
    ),
    VaccineDefinition(
      code: 'VITA_1',
      name: 'Vitamin A Dose 1 (100,000 IU)',
      periodCategory: '9_12_MONTHS',
      targetAgeDays: 270,
      windowStartDays: 270,
      windowEndDays: 365,
      maxAgeDays: 1825,
      route: 'ORAL',
      standardSite: AdministrationSite.oral,
      doseVolume: '1 ml (1 lakh IU)',
      incentiveEventCode: 'FULL_IMMUNIZATION_1YR',
    ),

    // ── 16–24 Months ─────────────────────────────────────────────────────────
    VaccineDefinition(
      code: 'MR_2',
      name: 'MR-2 (Measles-Rubella 2)',
      periodCategory: '16_24_MONTHS',
      targetAgeDays: 480, // 16 months
      windowStartDays: 480,
      windowEndDays: 730,
      maxAgeDays: 1825,
      prerequisiteCode: 'MR_1',
      minimumIntervalDays: 180, // Minimum 6 months after MR-1
      route: 'SUBCUTANEOUS',
      standardSite: AdministrationSite.rightUpperArm,
      doseVolume: '0.5 ml',
    ),
    VaccineDefinition(
      code: 'JE_2',
      name: 'JE-2 (Japanese Encephalitis 2)',
      periodCategory: '16_24_MONTHS',
      targetAgeDays: 480,
      windowStartDays: 480,
      windowEndDays: 730,
      maxAgeDays: 1825,
      prerequisiteCode: 'JE_1',
      minimumIntervalDays: 180,
      route: 'SUBCUTANEOUS',
      standardSite: AdministrationSite.leftUpperArm,
      doseVolume: '0.5 ml',
    ),
    VaccineDefinition(
      code: 'DPT_BOOSTER_1',
      name: 'DPT Booster 1',
      periodCategory: '16_24_MONTHS',
      targetAgeDays: 480,
      windowStartDays: 480,
      windowEndDays: 730,
      maxAgeDays: 2555, // Up to 7 years
      prerequisiteCode: 'PENTA_3',
      minimumIntervalDays: 180, // Minimum 6 months after Penta-3
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.leftMidThigh,
      doseVolume: '0.5 ml',
    ),
    VaccineDefinition(
      code: 'OPV_BOOSTER',
      name: 'OPV Booster',
      periodCategory: '16_24_MONTHS',
      targetAgeDays: 480,
      windowStartDays: 480,
      windowEndDays: 730,
      maxAgeDays: 1825,
      prerequisiteCode: 'OPV_3',
      minimumIntervalDays: 180,
      route: 'ORAL',
      standardSite: AdministrationSite.oral,
      doseVolume: '2 drops',
    ),
    VaccineDefinition(
      code: 'VITA_2',
      name: 'Vitamin A Dose 2 (200,000 IU)',
      periodCategory: '16_24_MONTHS',
      targetAgeDays: 480,
      windowStartDays: 480,
      windowEndDays: 730,
      maxAgeDays: 1825,
      prerequisiteCode: 'VITA_1',
      minimumIntervalDays: 180,
      route: 'ORAL',
      standardSite: AdministrationSite.oral,
      doseVolume: '2 ml (2 lakh IU)',
      incentiveEventCode: 'FULL_IMMUNIZATION_2YR',
    ),

    // ── 5–6 Years ────────────────────────────────────────────────────────────
    VaccineDefinition(
      code: 'DPT_BOOSTER_2',
      name: 'DPT Booster 2',
      periodCategory: '5_6_YEARS',
      targetAgeDays: 1825, // 5 years
      windowStartDays: 1825,
      windowEndDays: 2190,
      maxAgeDays: 2555, // Up to 7 years
      prerequisiteCode: 'DPT_BOOSTER_1',
      minimumIntervalDays: 1095, // 3 years
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.leftUpperArm,
      doseVolume: '0.5 ml',
    ),

    // ── 10 & 16 Years ────────────────────────────────────────────────────────
    VaccineDefinition(
      code: 'TD_10Y',
      name: 'Td (10 Years)',
      periodCategory: '10_YEARS',
      targetAgeDays: 3650, // 10 years
      windowStartDays: 3650,
      windowEndDays: 4015,
      maxAgeDays: 4380,
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.leftUpperArm,
      doseVolume: '0.5 ml',
    ),
    VaccineDefinition(
      code: 'TD_16Y',
      name: 'Td (16 Years)',
      periodCategory: '16_YEARS',
      targetAgeDays: 5840, // 16 years
      windowStartDays: 5840,
      windowEndDays: 6205,
      maxAgeDays: 6570,
      prerequisiteCode: 'TD_10Y',
      minimumIntervalDays: 1825,
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.leftUpperArm,
      doseVolume: '0.5 ml',
    ),
  ];

  /// Pregnant Women Td schedule (Requirement 16.7).
  static const List<VaccineDefinition> pregnantWomenSchedule = [
    VaccineDefinition(
      code: 'TD_1',
      name: 'Td-1 (Early in Pregnancy)',
      periodCategory: 'PREGNANT_WOMAN',
      targetAgeDays: 70, // ~10 weeks gestation
      windowStartDays: 0,
      windowEndDays: 112,
      maxAgeDays: 280,
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.leftUpperArm,
      doseVolume: '0.5 ml',
    ),
    VaccineDefinition(
      code: 'TD_2',
      name: 'Td-2 (4 Weeks after Td-1)',
      periodCategory: 'PREGNANT_WOMAN',
      targetAgeDays: 98, // ~14 weeks gestation
      windowStartDays: 98,
      windowEndDays: 280,
      maxAgeDays: 280,
      prerequisiteCode: 'TD_1',
      minimumIntervalDays: 28, // 4 weeks minimum interval
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.leftUpperArm,
      doseVolume: '0.5 ml',
    ),
    VaccineDefinition(
      code: 'TD_BOOSTER',
      name: 'Td-Booster (Pregnancy within 3 Years of previous 2 Td doses)',
      periodCategory: 'PREGNANT_WOMAN',
      targetAgeDays: 70,
      windowStartDays: 0,
      windowEndDays: 280,
      maxAgeDays: 280,
      route: 'INTRAMUSCULAR',
      standardSite: AdministrationSite.leftUpperArm,
      doseVolume: '0.5 ml',
    ),
  ];

  static VaccineDefinition? findByCode(String code) {
    for (final v in infantAndChildSchedule) {
      if (v.code == code) return v;
    }
    for (final v in pregnantWomenSchedule) {
      if (v.code == code) return v;
    }
    return null;
  }
}

/// A recorded vaccine dose administration event (Requirement 16.2).
class VaccineDoseRecord {
  final String vaccineCode;
  final DateTime administeredDate;
  final AdministrationSite bodySite;
  final String? batchNumber;
  final ImmunizationSessionType sessionType;
  final String? administeredBy;
  final String? encounterId;
  final String? notes;

  const VaccineDoseRecord({
    required this.vaccineCode,
    required this.administeredDate,
    required this.bodySite,
    this.batchNumber,
    this.sessionType = ImmunizationSessionType.vhsnd,
    this.administeredBy,
    this.encounterId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'vaccine_code': vaccineCode,
        'administered_date': administeredDate.toIso8601String(),
        'body_site': bodySite.name,
        'batch_number': batchNumber,
        'session_type': sessionType.name,
        'administered_by': administeredBy,
        'encounter_id': encounterId,
        'notes': notes,
      };

  factory VaccineDoseRecord.fromJson(Map<String, dynamic> json) =>
      VaccineDoseRecord(
        vaccineCode: json['vaccine_code'] as String,
        administeredDate: DateTime.parse(json['administered_date'] as String),
        bodySite: AdministrationSite.values.firstWhere(
          (s) => s.name == json['body_site'],
          orElse: () => AdministrationSite.other,
        ),
        batchNumber: json['batch_number'] as String?,
        sessionType: ImmunizationSessionType.values.firstWhere(
          (st) => st.name == json['session_type'],
          orElse: () => ImmunizationSessionType.vhsnd,
        ),
        administeredBy: json['administered_by'] as String?,
        encounterId: json['encounter_id'] as String?,
        notes: json['notes'] as String?,
      );
}

/// Item in the child's immunization matrix / MCP card view.
class ImmunizationCardItem {
  final VaccineDefinition definition;
  final VaccineDoseStatus status;
  final DateTime targetDueDate;
  final DateTime windowStartDate;
  final DateTime windowEndDate;
  final VaccineDoseRecord? doseRecord;
  final String? catchUpGuidance;
  final int daysLapsed; // If overdue or defaulter

  const ImmunizationCardItem({
    required this.definition,
    required this.status,
    required this.targetDueDate,
    required this.windowStartDate,
    required this.windowEndDate,
    this.doseRecord,
    this.catchUpGuidance,
    this.daysLapsed = 0,
  });

  bool get isCompleted => status == VaccineDoseStatus.given;
  bool get isDefaulter => status == VaccineDoseStatus.defaulter;
  bool get isOverdue => status == VaccineDoseStatus.overdue;
  bool get isExpired => status == VaccineDoseStatus.expired;
}

/// A beneficiary on the defaulter list with applicable catch-up guidance (Requirement 16.3).
class DefaulterBeneficiary {
  final String memberId;
  final String childName;
  final DateTime dateOfBirth;
  final String? guardianName;
  final String? contactPhone;
  final String? hamlet;
  final List<ImmunizationCardItem> missedDoses;
  final String? recordedSkipReason;
  final String overallCatchUpAdvice;

  const DefaulterBeneficiary({
    required this.memberId,
    required this.childName,
    required this.dateOfBirth,
    this.guardianName,
    this.contactPhone,
    this.hamlet,
    required this.missedDoses,
    this.recordedSkipReason,
    required this.overallCatchUpAdvice,
  });

  int get maxDaysOverdue {
    if (missedDoses.isEmpty) return 0;
    return missedDoses.map((d) => d.daysLapsed).reduce((a, b) => a > b ? a : b);
  }
}

/// Known symptoms for Adverse Events Following Immunization (Requirement 16.6).
class AefiSymptoms {
  // Urgent symptoms requiring RED flag triage and immediate referral
  static const String anaphylaxis = 'anaphylaxis';
  static const String convulsionsSeizures = 'convulsions_seizures';
  static const String persistentCryingGt3h = 'persistent_crying_gt_3h';
  static const String injectionSiteAbscess = 'injection_site_abscess';
  static const String highFeverGt39c = 'high_fever_gt_39c';
  static const String encephalopathy = 'encephalopathy';
  static const String toxicShockSyndrome = 'toxic_shock_syndrome';
  static const String hospitalizationRequired = 'hospitalization_required';

  // Minor symptoms
  static const String mildFever = 'mild_fever';
  static const String localSwelling = 'local_swelling';
  static const String painAtSite = 'pain_at_site';
  static const String mildIrritability = 'mild_irritability';

  static const List<String> urgentSymptoms = [
    anaphylaxis,
    convulsionsSeizures,
    persistentCryingGt3h,
    injectionSiteAbscess,
    highFeverGt39c,
    encephalopathy,
    toxicShockSyndrome,
    hospitalizationRequired,
  ];

  static bool isUrgent(String symptom) => urgentSymptoms.contains(symptom);

  static String displayName(String symptom) {
    switch (symptom) {
      case anaphylaxis:
        return 'Anaphylaxis / Severe Allergic Reaction (Breathing difficulty, facial swelling)';
      case convulsionsSeizures:
        return 'Convulsions / Seizures (Fits)';
      case persistentCryingGt3h:
        return 'Persistent Inconsolable Crying (> 3 Hours)';
      case injectionSiteAbscess:
        return 'Injection Site Abscess / Severe Local Infection';
      case highFeverGt39c:
        return 'High Persistent Fever (> 39°C / > 102.2°F)';
      case encephalopathy:
        return 'Encephalopathy / Altered Consciousness';
      case toxicShockSyndrome:
        return 'Toxic Shock Syndrome (Severe collapse/shock)';
      case hospitalizationRequired:
        return 'Condition Requiring Emergency Hospitalization';
      case mildFever:
        return 'Mild Fever (< 38.5°C)';
      case localSwelling:
        return 'Minor Redness or Swelling at Injection Site';
      case painAtSite:
        return 'Tenderness or Pain at Injection Site';
      case mildIrritability:
        return 'Mild Irritability or Restlessness';
      default:
        return symptom;
    }
  }
}

/// AEFI report record (Requirement 16.6).
class AefiRecord {
  final String id;
  final String memberId;
  final String? childName;
  final String vaccineCode;
  final DateTime sessionDate;
  final int onsetHoursAfterDose;
  final List<String> symptoms;
  final AefiSeverity severity;
  final bool isUrgent;
  final String? actionTaken;
  final String ashaId;
  final DateTime reportedAt;
  final bool notifiedAnm;
  final bool notifiedMo;
  final TriageFlag triageFlag;

  const AefiRecord({
    required this.id,
    required this.memberId,
    this.childName,
    required this.vaccineCode,
    required this.sessionDate,
    required this.onsetHoursAfterDose,
    required this.symptoms,
    required this.severity,
    required this.isUrgent,
    this.actionTaken,
    required this.ashaId,
    required this.reportedAt,
    this.notifiedAnm = true,
    this.notifiedMo = true,
    this.triageFlag = TriageFlag.red,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'member_id': memberId,
        'child_name': childName,
        'vaccine_code': vaccineCode,
        'session_date': sessionDate.toIso8601String(),
        'onset_hours_after_dose': onsetHoursAfterDose,
        'symptoms': symptoms,
        'severity': severity.name,
        'is_urgent': isUrgent,
        'action_taken': actionTaken,
        'asha_id': ashaId,
        'reported_at': reportedAt.toIso8601String(),
        'notified_anm': notifiedAnm,
        'notified_mo': notifiedMo,
        'triage_flag': triageFlag.name,
      };
}

/// VHSND Session model (Requirement 16.4, 27).
class VhsndSession {
  final String id;
  final DateTime sessionDate;
  final String villageName;
  final String? hamlet;
  final String anganwadiCenterName;
  final String ashaId;
  final String status; // planned, in_progress, completed
  final List<VhsndBeneficiaryDue> beneficiariesDue;

  const VhsndSession({
    required this.id,
    required this.sessionDate,
    required this.villageName,
    this.hamlet,
    required this.anganwadiCenterName,
    required this.ashaId,
    this.status = 'planned',
    this.beneficiariesDue = const [],
  });
}

/// Beneficiary mobilization and due entry for a VHSND session (Requirement 16.4, 27).
class VhsndBeneficiaryDue {
  final String memberId;
  final String beneficiaryName;
  final String beneficiaryType; // 'CHILD', 'PREGNANT_WOMAN', 'ADOLESCENT'
  final String? hamlet;
  final String? contactPhone;
  final List<String> dueVaccines;
  final List<String> dueOtherServices; // e.g. 'ANC_CHECK', 'IFA_DISTRIBUTION', 'WEIGHT_CHECK'
  final bool isMobilized;
  final bool attended;
  final List<String> servicesDelivered;
  final String? skipReason;

  const VhsndBeneficiaryDue({
    required this.memberId,
    required this.beneficiaryName,
    required this.beneficiaryType,
    this.hamlet,
    this.contactPhone,
    required this.dueVaccines,
    this.dueOtherServices = const [],
    this.isMobilized = false,
    this.attended = false,
    this.servicesDelivered = const [],
    this.skipReason,
  });

  VhsndBeneficiaryDue copyWith({
    bool? isMobilized,
    bool? attended,
    List<String>? servicesDelivered,
    String? skipReason,
  }) {
    return VhsndBeneficiaryDue(
      memberId: memberId,
      beneficiaryName: beneficiaryName,
      beneficiaryType: beneficiaryType,
      hamlet: hamlet,
      contactPhone: contactPhone,
      dueVaccines: dueVaccines,
      dueOtherServices: dueOtherServices,
      isMobilized: isMobilized ?? this.isMobilized,
      attended: attended ?? this.attended,
      servicesDelivered: servicesDelivered ?? this.servicesDelivered,
      skipReason: skipReason ?? this.skipReason,
    );
  }
}

/// Pure clinical catch-up schedule calculator implementing National Immunization Guidelines.
class ImmunizationCalculator {
  /// Evaluates child's immunization matrix and calculates catch-up schedules.
  static List<ImmunizationCardItem> evaluateMatrix({
    required DateTime dateOfBirth,
    required List<VaccineDoseRecord> administeredDoses,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final childAgeDays = now.difference(dateOfBirth).inDays;

    final administeredMap = <String, VaccineDoseRecord>{};
    for (final dose in administeredDoses) {
      administeredMap[dose.vaccineCode] = dose;
    }

    final result = <ImmunizationCardItem>[];

    for (final def in NationalImmunizationCatalog.infantAndChildSchedule) {
      final targetDueDate = dateOfBirth.add(Duration(days: def.targetAgeDays));
      final windowStartDate = dateOfBirth.add(Duration(days: def.windowStartDays));
      final windowEndDate = dateOfBirth.add(Duration(days: def.windowEndDays));

      final doseRecord = administeredMap[def.code];

      VaccineDoseStatus status;
      String? catchUpGuidance;
      int daysLapsed = 0;

      if (doseRecord != null) {
        status = VaccineDoseStatus.given;
      } else if (childAgeDays > def.maxAgeDays) {
        // Upper age limit expired per national protocol
        status = VaccineDoseStatus.expired;
        catchUpGuidance =
            'Upper age limit of ${def.maxAgeDays ~/ 365 > 0 ? "${def.maxAgeDays ~/ 365} year(s)" : "${def.maxAgeDays} days"} exceeded for ${def.code}. Omit dose per national guidelines.';
      } else if (now.isAfter(windowEndDate)) {
        // Overdue past window end -> Defaulter if > 28 days past window end
        final lapsedDays = now.difference(windowEndDate).inDays;
        daysLapsed = lapsedDays;

        if (lapsedDays > 28) {
          status = VaccineDoseStatus.defaulter;
        } else {
          status = VaccineDoseStatus.overdue;
        }

        // Catch-up calculation
        catchUpGuidance = _computeCatchUpGuidance(
          def: def,
          administeredMap: administeredMap,
          now: now,
          dateOfBirth: dateOfBirth,
        );
      } else if (now.isAfter(windowStartDate)) {
        status = VaccineDoseStatus.due;
      } else {
        status = VaccineDoseStatus.upcoming;
      }

      result.add(
        ImmunizationCardItem(
          definition: def,
          status: status,
          targetDueDate: targetDueDate,
          windowStartDate: windowStartDate,
          windowEndDate: windowEndDate,
          doseRecord: doseRecord,
          catchUpGuidance: catchUpGuidance,
          daysLapsed: daysLapsed,
        ),
      );
    }

    return result;
  }

  static String _computeCatchUpGuidance({
    required VaccineDefinition def,
    required Map<String, VaccineDoseRecord> administeredMap,
    required DateTime now,
    required DateTime dateOfBirth,
  }) {
    if (def.prerequisiteCode != null) {
      final prereqDose = administeredMap[def.prerequisiteCode!];
      if (prereqDose == null) {
        return 'Prerequisite dose (${def.prerequisiteCode}) not yet administered. Administer ${def.prerequisiteCode} first, then wait ${def.minimumIntervalDays} days before giving ${def.code}.';
      }

      final daysSincePrereq = now.difference(prereqDose.administeredDate).inDays;
      if (daysSincePrereq < def.minimumIntervalDays) {
        final daysRemaining = def.minimumIntervalDays - daysSincePrereq;
        return 'Minimum interval not reached. Administer ${def.code} in $daysRemaining days (${def.minimumIntervalDays} days required after ${def.prerequisiteCode}).';
      }
    }

    return 'Eligible for administration now at next VHSND or health facility session.';
  }
}
