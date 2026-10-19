import '../../../../core/triage/models/models.dart';

/// Nutritional wasting classification per WHO standards (Weight-for-Height/Length or MUAC).
enum WastingStatus {
  normal('Normal'),
  mam('Moderate Acute Malnutrition (MAM)'),
  sam('Severe Acute Malnutrition (SAM)');

  final String label;
  const WastingStatus(this.label);
}

/// Stunting classification per WHO standards (Height/Length-for-Age).
enum StuntingStatus {
  normal('Normal Height/Length'),
  moderateStunting('Moderate Stunting (HAZ < -2 SD)'),
  severeStunting('Severe Stunting (HAZ < -3 SD)');

  final String label;
  const StuntingStatus(this.label);
}

/// Underweight classification per WHO standards (Weight-for-Age).
enum UnderweightStatus {
  normal('Normal Weight-for-Age'),
  moderateUnderweight('Moderate Underweight (WAZ < -2 SD)'),
  severeUnderweight('Severe Underweight (WAZ < -3 SD)'),
  overweight('Overweight (WAZ > +2 SD)');

  final String label;
  const UnderweightStatus(this.label);
}

/// Mid-Upper Arm Circumference (MUAC) classification (6 to 59 months).
enum MuacClassification {
  normal('Normal (>= 12.5 cm / >= 125 mm)'),
  mam('MAM (11.5 - 12.4 cm / 115 - 124 mm)'),
  sam('SAM (< 11.5 cm / < 115 mm)');

  final String label;
  const MuacClassification(this.label);
}

/// Anaemia severity classification according to WHO & MoHFW Anemia Mukt Bharat guidelines.
enum AnaemiaSeverity {
  none('Normal (Non-anaemic)'),
  mild('Mild Anaemia'),
  moderate('Moderate Anaemia'),
  severe('Severe Anaemia (Urgent Medical Attention)');

  final String label;
  const AnaemiaSeverity(this.label);
}

/// National supplementation programs (Requirement 17.4).
enum SupplementType {
  ifa('Iron & Folic Acid (IFA)'),
  vitaminA('Vitamin A Prophylaxis'),
  albendazoleDeworming('Deworming (Albendazole)');

  final String displayName;
  const SupplementType(this.displayName);
}

/// Exit criteria outcomes for malnutrition treatment programs (Requirement 17.6).
enum MalnutritionExitOutcome {
  cured('Cured (Discharged)'),
  defaulted('Defaulted (Absent / Missed visits)'),
  died('Died'),
  nonResponder('Non-Responder (Failed to reach discharge criteria within 16 weeks)');

  final String label;
  const MalnutritionExitOutcome(this.label);
}

/// Anthropometric measurement and offline classification record (Requirement 17.1 – 17.3).
class GrowthMeasurement {
  final String id;
  final String memberId;
  final DateTime measuredAt;
  final int ageInDays;
  final double ageInMonths;
  final double weightKg;
  final double? heightCm;
  final double? muacCm;
  final bool bilateralOedema;
  final bool? appetiteTestPassed;
  final double? haemoglobinGdl;
  final double waz;
  final double? haz;
  final double? wfhz;
  final WastingStatus wastingStatus;
  final StuntingStatus stuntingStatus;
  final UnderweightStatus underweightStatus;
  final MuacClassification? muacClassification;
  final AnaemiaSeverity? anaemiaSeverity;
  final TriageFlag triageFlag;
  final List<String> clinicalFindings;
  final List<String> recommendedActions;
  final String? suggestedReferralDestination;

  const GrowthMeasurement({
    required this.id,
    required this.memberId,
    required this.measuredAt,
    required this.ageInDays,
    required this.ageInMonths,
    required this.weightKg,
    this.heightCm,
    this.muacCm,
    this.bilateralOedema = false,
    this.appetiteTestPassed,
    this.haemoglobinGdl,
    required this.waz,
    this.haz,
    this.wfhz,
    required this.wastingStatus,
    required this.stuntingStatus,
    required this.underweightStatus,
    this.muacClassification,
    this.anaemiaSeverity,
    required this.triageFlag,
    required this.clinicalFindings,
    required this.recommendedActions,
    this.suggestedReferralDestination,
  });

  bool get isSam => wastingStatus == WastingStatus.sam || bilateralOedema || muacClassification == MuacClassification.sam;
  bool get isMam => !isSam && (wastingStatus == WastingStatus.mam || muacClassification == MuacClassification.mam);
  bool get isStunted => stuntingStatus != StuntingStatus.normal;
  bool get emergencyReferralRequired => triageFlag == TriageFlag.red;
  bool get isUnderweight => underweightStatus == UnderweightStatus.moderateUnderweight || underweightStatus == UnderweightStatus.severeUnderweight;

  Map<String, dynamic> toJson() => {
        'id': id,
        'member_id': memberId,
        'measured_at': measuredAt.toIso8601String(),
        'age_days': ageInDays,
        'age_months': ageInMonths,
        'weight_kg': weightKg,
        'height_cm': heightCm,
        'muac_cm': muacCm,
        'bilateral_oedema': bilateralOedema,
        'appetite_test_passed': appetiteTestPassed,
        'haemoglobin_gdl': haemoglobinGdl,
        'waz': waz,
        'haz': haz,
        'wfhz': wfhz,
        'wasting_status': wastingStatus.name,
        'stunting_status': stuntingStatus.name,
        'underweight_status': underweightStatus.name,
        'muac_classification': muacClassification?.name,
        'anaemia_severity': anaemiaSeverity?.name,
        'triage_flag': triageFlag.name,
        'clinical_findings': clinicalFindings,
        'recommended_actions': recommendedActions,
        'suggested_referral': suggestedReferralDestination,
      };
}

/// Record of supplementation administration (Requirement 17.4).
class SupplementationRecord {
  final String id;
  final String memberId;
  final SupplementType supplementType;
  final DateTime dateAdministered;
  final String doseAmount; // e.g. '1 ml (100,000 IU)', '400 mg tablet', '1 ml IFA syrup'
  final String ashaId;
  final String? notes;

  const SupplementationRecord({
    required this.id,
    required this.memberId,
    required this.supplementType,
    required this.dateAdministered,
    required this.doseAmount,
    required this.ashaId,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'member_id': memberId,
        'supplement_type': supplementType.name,
        'date_administered': dateAdministered.toIso8601String(),
        'dose_amount': doseAmount,
        'asha_id': ashaId,
        'notes': notes,
      };
}

/// Malnutrition Programme Enrolment and Tracking Episode (Requirement 17.6).
class MalnutritionEpisode {
  final String id;
  final String memberId;
  final DateTime enrolledAt;
  final String programmeType; // 'NRC', 'CMAM_ANGANWADI'
  final double baselineWeightKg;
  final double? baselineHeightCm;
  final double? baselineMuacCm;
  final double? baselineWfhz;
  final String status; // 'active', 'cured', 'defaulted', 'died', 'non_responder'
  final int consecutiveCureVisits; // 2 consecutive visits with WFHZ >= -2 and MUAC >= 12.5cm needed
  final DateTime? exitDate;
  final MalnutritionExitOutcome? exitOutcome;
  final String? exitNotes;

  const MalnutritionEpisode({
    required this.id,
    required this.memberId,
    required this.enrolledAt,
    this.programmeType = 'CMAM_ANGANWADI',
    required this.baselineWeightKg,
    this.baselineHeightCm,
    this.baselineMuacCm,
    this.baselineWfhz,
    this.status = 'active',
    this.consecutiveCureVisits = 0,
    this.exitDate,
    this.exitOutcome,
    this.exitNotes,
  });

  bool get isActive => status == 'active';
  bool get isCured => status == 'cured' || exitOutcome == MalnutritionExitOutcome.cured;
}
