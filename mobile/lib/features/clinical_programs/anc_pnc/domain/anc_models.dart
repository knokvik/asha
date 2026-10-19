import '../../../../core/triage/models/models.dart';

/// Pregnancy registration and baseline obstetric history (Requirement 14.1).
class PregnancyRegistration {
  final String womanId;
  final DateTime lmp; // Last Menstrual Period
  final DateTime edd; // Estimated Date of Delivery (LMP + 280 days / 40 weeks)
  final int gravida; // Total number of pregnancies
  final int para; // Viable births
  final int livingChildren;
  final int stillbirths;
  final int abortions;
  final bool previousCesarean;
  final List<String> previousComplications;
  final String? mcpCardNumber;
  final String? rchId;
  final String? abhaId;
  final String? bloodGroup; // A+, B+, AB+, O+, A-, B-, AB-, O-
  final double? baselineWeightKg;
  final double? baselineHeightCm;
  final int? maternalAgeYears;

  PregnancyRegistration({
    required this.womanId,
    required this.lmp,
    DateTime? edd,
    required this.gravida,
    required this.para,
    this.livingChildren = 0,
    this.stillbirths = 0,
    this.abortions = 0,
    this.previousCesarean = false,
    this.previousComplications = const [],
    this.mcpCardNumber,
    this.rchId,
    this.abhaId,
    this.bloodGroup,
    this.baselineWeightKg,
    this.baselineHeightCm,
    this.maternalAgeYears,
  }) : edd = edd ?? lmp.add(const Duration(days: 280));

  /// Calculates gestational age in full weeks from LMP to [referenceDate].
  int gestationWeeksAt([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    final diffDays = ref.difference(lmp).inDays;
    return (diffDays / 7).floor();
  }

  /// Calculates gestational age in days from LMP.
  int gestationDaysAt([DateTime? referenceDate]) {
    final ref = referenceDate ?? DateTime.now();
    return ref.difference(lmp).inDays;
  }

  /// Whether the pregnancy is at or past 34 weeks gestation (Requirement 14.5).
  bool get isBirthPlanDue => gestationWeeksAt() >= 34;

  /// Whether the mother is Rh-negative (Rh-incompatibility risk).
  bool get isRhNegative => bloodGroup != null && bloodGroup!.contains('-');

  /// Evaluates baseline high-risk obstetric indicators (Requirement 14.3).
  List<String> get baselineHighRiskReasons {
    final reasons = <String>[];
    if (maternalAgeYears != null && maternalAgeYears! < 18) {
      reasons.add('Adolescent pregnancy (Age < 18 years)');
    }
    if (maternalAgeYears != null && maternalAgeYears! > 35) {
      reasons.add('Elderly gravida (Age > 35 years)');
    }
    if (para >= 4 || gravida >= 5) {
      reasons.add('Grand multipara (Parity >= 4 / Gravida >= 5)');
    }
    if (previousCesarean) {
      reasons.add('History of previous Cesarean Section (Scarred uterus)');
    }
    if (stillbirths > 0) {
      reasons.add('History of previous stillbirth ($stillbirths)');
    }
    if (abortions >= 2) {
      reasons.add('History of recurrent spontaneous abortions ($abortions)');
    }
    if (previousComplications.isNotEmpty) {
      reasons.add('Previous obstetric complications: ${previousComplications.join(", ")}');
    }
    if (isRhNegative) {
      reasons.add('Rh-Negative blood group ($bloodGroup) — risk of isoimmunization');
    }
    return reasons;
  }

  bool get isBaselineHighRisk => baselineHighRiskReasons.isNotEmpty;
}

/// Clinical data recorded during an ANC contact (Requirements 14.2, 14.3).
class AncContactData {
  final int contactNumber; // 1, 2, 3, 4, etc.
  final int gestationWeeks;
  final double? weightKg;
  final int? systolicBp; // Normal: < 140 mmHg
  final int? diastolicBp; // Normal: < 90 mmHg
  final double? haemoglobin; // Normal: >= 11.0 g/dL; Mild/Mod: 7.0-10.9; Severe: < 7.0
  final int? fundalHeightWeeks;
  final int? fetalHeartRateBpm; // Normal: 110-160 bpm
  final bool fetalMovementPresent;
  final bool urineAlbuminPresent;
  final bool urineSugarPresent;

  // Supplementation & Immunization
  final bool ifaTabletsGiven;
  final int ifaCount;
  final bool calciumTabletsGiven;
  final int calciumCount;
  final bool tdAdministered;
  final String? tdDoseType; // Td-1, Td-2, Td-Booster

  // Danger symptoms (Requirements 14.3)
  final bool vaginalBleeding;
  final bool severeHeadacheOrBlurredVision;
  final bool severeSwellingFaceHands;
  final bool highFever;
  final bool leakingAmnioticFluid;
  final bool severeAbdominalPain;
  final String? generalNotes;

  const AncContactData({
    required this.contactNumber,
    required this.gestationWeeks,
    this.weightKg,
    this.systolicBp,
    this.diastolicBp,
    this.haemoglobin,
    this.fundalHeightWeeks,
    this.fetalHeartRateBpm,
    this.fetalMovementPresent = true,
    this.urineAlbuminPresent = false,
    this.urineSugarPresent = false,
    this.ifaTabletsGiven = true,
    this.ifaCount = 30,
    this.calciumTabletsGiven = true,
    this.calciumCount = 60,
    this.tdAdministered = false,
    this.tdDoseType,
    this.vaginalBleeding = false,
    this.severeHeadacheOrBlurredVision = false,
    this.severeSwellingFaceHands = false,
    this.highFever = false,
    this.leakingAmnioticFluid = false,
    this.severeAbdominalPain = false,
    this.generalNotes,
  });

  /// Evaluates immediate clinical danger signs requiring RED referral.
  List<String> get clinicalDangerSigns {
    final signs = <String>[];
    if (vaginalBleeding) {
      signs.add('Antepartum vaginal bleeding (Suspected Placenta Praevia / Abruptio)');
    }
    if (severeHeadacheOrBlurredVision) {
      signs.add('Severe headache with visual disturbance / epigastric pain (Impending Eclampsia)');
    }
    if (systolicBp != null && diastolicBp != null) {
      if (systolicBp! >= 160 || diastolicBp! >= 110) {
        signs.add('Severe hypertension (BP $systolicBp/$diastolicBp mmHg) — severe pre-eclampsia');
      }
    }
    if (haemoglobin != null && haemoglobin! < 7.0) {
      signs.add('Severe anaemia (Hb $haemoglobin g/dL < 7.0 g/dL) — urgent transfusion evaluation');
    }
    if (gestationWeeks >= 24 && !fetalMovementPresent) {
      signs.add('Reduced or absent fetal movements at $gestationWeeks weeks');
    }
    if (leakingAmnioticFluid) {
      signs.add('Premature rupture of membranes / leaking amniotic fluid');
    }
    if (highFever) {
      signs.add('High fever with chills (Suspected severe systemic infection / malaria)');
    }
    if (severeAbdominalPain) {
      signs.add('Severe persistent abdominal pain / uterine tenderness');
    }
    return signs;
  }

  /// Evaluates moderate high-risk signs requiring YELLOW flag and closer monitoring.
  List<String> get moderateRiskSigns {
    final signs = <String>[];
    if (systolicBp != null && diastolicBp != null) {
      if ((systolicBp! >= 140 && systolicBp! < 160) || (diastolicBp! >= 90 && diastolicBp! < 110)) {
        signs.add('Gestational hypertension (BP $systolicBp/$diastolicBp mmHg)');
      }
    }
    if (haemoglobin != null && haemoglobin! >= 7.0 && haemoglobin! < 11.0) {
      signs.add('Moderate / Mild anaemia in pregnancy (Hb $haemoglobin g/dL < 11.0 g/dL)');
    }
    if (urineAlbuminPresent) {
      signs.add('Proteinuria / Albumin in urine detected (+ or ++) — pre-eclampsia screen');
    }
    if (severeSwellingFaceHands) {
      signs.add('Excessive pedal / generalized oedema');
    }
    return signs;
  }

  bool get hasRedFlag => clinicalDangerSigns.isNotEmpty;
  bool get hasYellowFlag => moderateRiskSigns.isNotEmpty && !hasRedFlag;
}

/// Birth preparedness and complication readiness plan (Requirement 14.5).
///
/// Prompted at 34 weeks gestation.
class BirthPlan {
  final String womanId;
  final String chosenDeliveryFacility; // e.g. PHC Rampur, CHC Kotra, DH Alwar
  final String facilityType; // PHC, CHC, Sub-Divisional Hospital, District Hospital
  final double? facilityDistanceKm;
  final String transportArrangement; // 108 Ambulance, 102 Janani Express, Auto, Private
  final String namedEscortName;
  final String namedEscortPhone;
  final String escortRelationship;
  final String? bloodDonorName;
  final String? bloodDonorPhone;
  final String? bloodDonorGroup;
  final bool emergencySavingsConfirmed;
  final List<String> emergencyContactNumbers;
  final DateTime recordedAt;

  const BirthPlan({
    required this.womanId,
    required this.chosenDeliveryFacility,
    required this.facilityType,
    this.facilityDistanceKm,
    required this.transportArrangement,
    required this.namedEscortName,
    required this.namedEscortPhone,
    required this.escortRelationship,
    this.bloodDonorName,
    this.bloodDonorPhone,
    this.bloodDonorGroup,
    this.emergencySavingsConfirmed = true,
    this.emergencyContactNumbers = const ['108', '102'],
    required this.recordedAt,
  });
}

/// Pregnancy outcome record and downstream pathway trigger (Requirement 14.7).
enum PregnancyOutcomeType {
  liveBirth('live_birth', 'Live Birth'),
  stillbirth('stillbirth', 'Stillbirth (Intrauterine Fetal Death)'),
  spontaneousAbortion('spontaneous_abortion', 'Spontaneous Abortion / Miscarriage'),
  inducedAbortion('induced_abortion', 'Medical Termination of Pregnancy (MTP) / Induced Abortion'),
  maternalDeath('maternal_death', 'Maternal Death during Pregnancy / Delivery');

  final String code;
  final String label;
  const PregnancyOutcomeType(this.code, this.label);
}

class PregnancyOutcome {
  final String womanId;
  final DateTime outcomeDate;
  final PregnancyOutcomeType outcomeType;
  final String placeOfDelivery; // home, sub_centre, phc, chc, district_hospital, private_hospital
  final String deliveryType; // normal_vaginal, c_section, assisted_vaginal
  final String skilledAttendant; // doctor, staff_nurse, anm, dai, family
  final String? newbornSex; // M, F, Other
  final double? birthWeightKg;
  final int? gestationalWeeksAtDelivery;
  final String? complicationsNotes;

  const PregnancyOutcome({
    required this.womanId,
    required this.outcomeDate,
    required this.outcomeType,
    required this.placeOfDelivery,
    required this.deliveryType,
    required this.skilledAttendant,
    this.newbornSex,
    this.birthWeightKg,
    this.gestationalWeeksAtDelivery,
    this.complicationsNotes,
  });

  bool get isLiveBirth => outcomeType == PregnancyOutcomeType.liveBirth;
  bool get isInstitutionalDelivery => placeOfDelivery != 'home';
  bool get isPreterm => (gestationalWeeksAtDelivery ?? 40) < 37;
  bool get isLowBirthWeight => (birthWeightKg ?? 3.0) < 2.5;
}

/// Result of an ANC contact assessment (Requirements 14.2 – 14.6).
class AncVisitResult {
  final String encounterId;
  final String visitScheduleId;
  final String womanId;
  final int contactNumber;
  final bool isHighRisk;
  final List<String> highRiskReasons;
  final bool isRedFlag;
  final TriageResult? triageResult;
  final bool birthPlanPromptNeeded;
  final String? suggestedReferralFacility;
  final String? prePopulatedReferralReason;

  const AncVisitResult({
    required this.encounterId,
    required this.visitScheduleId,
    required this.womanId,
    required this.contactNumber,
    required this.isHighRisk,
    required this.highRiskReasons,
    required this.isRedFlag,
    this.triageResult,
    required this.birthPlanPromptNeeded,
    this.suggestedReferralFacility,
    this.prePopulatedReferralReason,
  });
}
