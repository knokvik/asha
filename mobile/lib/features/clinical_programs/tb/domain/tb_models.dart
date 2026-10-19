import '../../../../core/triage/models/models.dart';

/// Sputum sample transport and processing status (Requirement 20.2).
enum SputumTransportStatus {
  collectedAtVillage('Sample Collected'),
  inTransitToDmc('In Transit to Laboratory / DMC'),
  receivedAtLab('Received at Testing Lab'),
  testingCompleted('Testing Completed'),
  sampleRejected('Sample Rejected / Repeat Needed');

  final String label;
  const SputumTransportStatus(this.label);
}

/// Sputum diagnostic test result.
enum SputumTestResult {
  pending('Result Pending'),
  negative('Negative / Acid Fast Bacilli Not Found'),
  smearPositive1Plus('Smear Microscopy Positive (1+)'),
  smearPositive2Plus('Smear Microscopy Positive (2+)'),
  smearPositive3Plus('Smear Microscopy Positive (3+)'),
  naatMtbDetectedSensitive('NAAT (Truenat/CBNAAT): MTB Detected, Rifampicin Sensitive'),
  naatMtbDetectedResistant('NAAT (Truenat/CBNAAT): MTB Detected, Rifampicin RESISTANT (DR-TB)'),
  naatMtbNotDetected('NAAT: MTB Not Detected'),
  invalidOrError('Invalid / Test Error');

  final String label;
  const SputumTestResult(this.label);

  bool get isPositive =>
      this == smearPositive1Plus ||
      this == smearPositive2Plus ||
      this == smearPositive3Plus ||
      this == naatMtbDetectedSensitive ||
      this == naatMtbDetectedResistant;

  bool get isDrugResistant => this == naatMtbDetectedResistant;
}

/// TB treatment regimen categories.
enum TbRegimenType {
  dsTbDailyFdc('Drug-Sensitive TB (Daily 4-Drug FDC: HRZE)'),
  drTbSecondLine('Drug-Resistant TB (Second-Line Regimen)'),
  tptPreventiveIsoniazid('TB Preventive Therapy (3HP / 6H)');

  final String label;
  const TbRegimenType(this.label);
}

/// TB Disease Site.
enum TbSite {
  pulmonary('Pulmonary (Lungs)'),
  extraPulmonaryLymphNode('Extra-Pulmonary: Lymph Nodes'),
  extraPulmonaryPleural('Extra-Pulmonary: Pleural Effusion'),
  extraPulmonaryAbdominal('Extra-Pulmonary: Abdomen / GI'),
  extraPulmonaryOther('Extra-Pulmonary: Other');

  final String label;
  const TbSite(this.label);
}

/// Dose observation status for direct observation visits (Requirement 20.4).
enum DoseIntakeStatus {
  observedTaken('Observed Taken (Swallowed in presence of ASHA/Supporter)'),
  unobservedTaken('Reported Taken (Self-administered)'),
  missed('Dose Missed / Not Taken'),
  vomitedWithin30Mins('Vomited within 30 mins (Re-dose administered)');

  final String label;
  const DoseIntakeStatus(this.label);
}

/// Side effects of anti-TB medications.
enum TbSideEffect {
  none('No side effects reported'),
  nauseaVomiting('Nausea or vomiting'),
  jaundiceYellowEyes('Yellow eyes/urine (Jaundice / Hepatitis) - URGENT', isUrgent: true),
  skinRashItching('Skin rash or severe itching'),
  jointPains('Joint pains / Hyperuricemia'),
  visionChanges('Blurry vision or color blindness - URGENT', isUrgent: true),
  numbnessTingling('Numbness or burning sensation in feet/hands');

  final String label;
  final bool isUrgent;
  const TbSideEffect(this.label, {this.isUrgent = false});
}

/// Nikshay Poshan Yojana financial nutritional incentive status (Requirement 20.7).
enum NikshayPoshanStatus {
  notApplied('Not Enrolled'),
  bankDetailsSubmitted('Bank Account Details Submitted'),
  approvedAwaitingPayment('Approved, Awaiting DBT Payment'),
  installmentReceived('Monthly DBT Installment Received (Rs 500)'),
  rejected('Rejected / Account Issue');

  final String label;
  const NikshayPoshanStatus(this.label);
}

/// TB Privacy display mode (Requirement 20.8).
enum TbPrivacyMode {
  ashaPrivateView,
  sharedSupervisorView;

  bool get isShared => this == sharedSupervisorView;
}

/// Stigma-free neutral privacy labels helper (Requirement 20.8).
class TbPrivacyFilter {
  static String filterTerm(String term, TbPrivacyMode mode) {
    if (mode == TbPrivacyMode.ashaPrivateView) {
      return term;
    }

    // Replace more specific multi-word phrases first before individual words
    var neutral = term;
    neutral = neutral.replaceAll(RegExp(r'\bPresumptive TB\b', caseSensitive: false), 'Chest Health Assessment');
    neutral = neutral.replaceAll(RegExp(r'\bDOTS Supporter\b', caseSensitive: false), 'Care Supporter');
    neutral = neutral.replaceAll(RegExp(r'\bNi-kshay Poshan\b', caseSensitive: false), 'Direct Nutritional Support');
    neutral = neutral.replaceAll(RegExp(r'\bNi-kshay\b', caseSensitive: false), 'Health Portal');
    neutral = neutral.replaceAll(RegExp(r'\bSputum\b', caseSensitive: false), 'Respiratory Sample');
    neutral = neutral.replaceAll(RegExp(r'\bDOTS\b', caseSensitive: false), 'Daily Therapy');
    neutral = neutral.replaceAll(RegExp(r'\bAnti-TB\b', caseSensitive: false), 'Prescribed Respiratory');
    neutral = neutral.replaceAll(RegExp(r'\b(TB|Tuberculosis)\b', caseSensitive: false), 'Respiratory Care');
    return neutral;
  }
}

/// Presumptive TB symptom assessment (Requirement 20.1).
class PresumptiveTbAssessment {
  final String id;
  final String memberId;
  final DateTime screenedAt;
  final bool coughGt2Weeks;
  final bool feverGt2Weeks;
  final bool unexplainedWeightLoss;
  final bool nightSweats;
  final bool haemoptysis; // Blood in sputum
  final bool chestPain;
  final bool contactWithKnownTbPatient;
  final TriageFlag triageFlag;
  final List<String> clinicalFindings;
  final List<String> recommendedActions;

  const PresumptiveTbAssessment({
    required this.id,
    required this.memberId,
    required this.screenedAt,
    this.coughGt2Weeks = false,
    this.feverGt2Weeks = false,
    this.unexplainedWeightLoss = false,
    this.nightSweats = false,
    this.haemoptysis = false,
    this.chestPain = false,
    this.contactWithKnownTbPatient = false,
    required this.triageFlag,
    required this.clinicalFindings,
    required this.recommendedActions,
  });

  bool get isPresumptiveTb =>
      coughGt2Weeks ||
      (feverGt2Weeks && (unexplainedWeightLoss || nightSweats)) ||
      haemoptysis;

  Map<String, dynamic> toJson() => {
        'id': id,
        'member_id': memberId,
        'screened_at': screenedAt.toIso8601String(),
        'cough_gt_2w': coughGt2Weeks,
        'fever_gt_2w': feverGt2Weeks,
        'weight_loss': unexplainedWeightLoss,
        'night_sweats': nightSweats,
        'haemoptysis': haemoptysis,
        'chest_pain': chestPain,
        'contact_known_tb': contactWithKnownTbPatient,
        'triage_flag': triageFlag.name,
        'findings': clinicalFindings,
        'actions': recommendedActions,
      };
}

/// Sputum collection and testing record (Requirement 20.2).
class SputumSampleRecord {
  final String sampleId;
  final String memberId;
  final DateTime collectionDate;
  final String collectionSite;
  final SputumTransportStatus transportStatus;
  final SputumTestResult testResult;
  final DateTime? resultDate;
  final String? labName;
  final String ashaId;

  const SputumSampleRecord({
    required this.sampleId,
    required this.memberId,
    required this.collectionDate,
    required this.collectionSite,
    this.transportStatus = SputumTransportStatus.collectedAtVillage,
    this.testResult = SputumTestResult.pending,
    this.resultDate,
    this.labName,
    required this.ashaId,
  });

  Map<String, dynamic> toJson() => {
        'sample_id': sampleId,
        'member_id': memberId,
        'collection_date': collectionDate.toIso8601String(),
        'collection_site': collectionSite,
        'transport_status': transportStatus.name,
        'test_result': testResult.name,
        'result_date': resultDate?.toIso8601String(),
        'lab_name': labName,
        'asha_id': ashaId,
      };
}

/// Confirmed TB patient treatment registration (Requirement 20.3, 20.6, 20.7).
class TbTreatmentPatient {
  final String id;
  final String memberId;
  final String beneficiaryName;
  final String? nikshayId;
  final TbSite site;
  final TbRegimenType regimen;
  final DateTime startDate;
  final String treatmentSupporterName;
  final String treatmentSupporterPhone;
  final String supporterRelationship;
  final int totalDosesPrescribed;
  final int dosesCompleted;
  final int consecutiveMissedDoses;
  final NikshayPoshanStatus nikshayPoshanStatus;
  final String ashaId;

  const TbTreatmentPatient({
    required this.id,
    required this.memberId,
    required this.beneficiaryName,
    this.nikshayId,
    required this.site,
    required this.regimen,
    required this.startDate,
    required this.treatmentSupporterName,
    required this.treatmentSupporterPhone,
    required this.supporterRelationship,
    this.totalDosesPrescribed = 168, // Standard 6-month daily regimen (24 weeks * 7 = 168 doses)
    this.dosesCompleted = 0,
    this.consecutiveMissedDoses = 0,
    this.nikshayPoshanStatus = NikshayPoshanStatus.notApplied,
    required this.ashaId,
  });

  bool get hasConsecutiveMissAlert => consecutiveMissedDoses >= 3;

  double get adherencePercentage =>
      totalDosesPrescribed > 0 ? (dosesCompleted / totalDosesPrescribed).clamp(0.0, 1.0) * 100 : 0.0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'member_id': memberId,
        'beneficiary_name': beneficiaryName,
        'nikshay_id': nikshayId,
        'site': site.name,
        'regimen': regimen.name,
        'start_date': startDate.toIso8601String(),
        'supporter_name': treatmentSupporterName,
        'supporter_phone': treatmentSupporterPhone,
        'supporter_relationship': supporterRelationship,
        'total_doses': totalDosesPrescribed,
        'doses_completed': dosesCompleted,
        'consecutive_missed': consecutiveMissedDoses,
        'nikshay_poshan_status': nikshayPoshanStatus.name,
        'asha_id': ashaId,
      };
}

/// Dose observation entry (Requirement 20.4).
class TbDoseObservation {
  final String encounterId;
  final String memberId;
  final DateTime doseDate;
  final DoseIntakeStatus status;
  final TbSideEffect sideEffect;
  final String? notes;
  final String ashaId;

  const TbDoseObservation({
    required this.encounterId,
    required this.memberId,
    required this.doseDate,
    required this.status,
    this.sideEffect = TbSideEffect.none,
    this.notes,
    required this.ashaId,
  });

  Map<String, dynamic> toJson() => {
        'encounter_id': encounterId,
        'member_id': memberId,
        'dose_date': doseDate.toIso8601String(),
        'status': status.name,
        'side_effect': sideEffect.name,
        'notes': notes,
        'asha_id': ashaId,
      };
}

/// Household contact investigation and TPT assessment (Requirement 20.5).
class TbContactScreening {
  final String contactMemberId;
  final String contactName;
  final String indexPatientMemberId;
  final int ageYears;
  final bool hasSymptoms;
  final bool eligibleForTpt;
  final bool tptStarted;
  final DateTime screenedAt;

  const TbContactScreening({
    required this.contactMemberId,
    required this.contactName,
    required this.indexPatientMemberId,
    required this.ageYears,
    required this.hasSymptoms,
    required this.eligibleForTpt,
    this.tptStarted = false,
    required this.screenedAt,
  });

  Map<String, dynamic> toJson() => {
        'contact_id': contactMemberId,
        'contact_name': contactName,
        'index_patient_id': indexPatientMemberId,
        'age_years': ageYears,
        'has_symptoms': hasSymptoms,
        'eligible_tpt': eligibleForTpt,
        'tpt_started': tptStarted,
        'screened_at': screenedAt.toIso8601String(),
      };
}
