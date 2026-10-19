import '../../../../core/triage/models/models.dart';

/// Bleeding severity for postpartum mother (Requirement 15.3, 15.4).
enum PncBleedingStatus {
  normalLochia('normal_lochia', 'Normal Lochia — Pinkish/Brown, Normal Odour'),
  heavySoakingPads('heavy_soaking', 'Severe Bleeding — Soaking 2+ pads/cloths per hour (DANGER SIGN: PPH)'),
  foulSmellingLochia('foul_smelling', 'Foul-Smelling Vaginal Discharge (DANGER SIGN: Puerperal Sepsis)'),
  largeClots('large_clots', 'Passing Large Blood Clots (> lemon sized)');

  final String code;
  final String label;
  const PncBleedingStatus(this.code, this.label);

  bool get isDangerSign =>
      this == PncBleedingStatus.heavySoakingPads ||
      this == PncBleedingStatus.foulSmellingLochia ||
      this == PncBleedingStatus.largeClots;
}

/// Breast examination findings during PNC (Requirement 15.3).
enum PncBreastStatus {
  normalLactating('normal', 'Normal, Soft, Lactating Freely'),
  engorgedPainful('engorged', 'Mild Breast Engorgement / Heaviness'),
  crackedNipples('cracked_nipples', 'Cracked, Sore, or Bleeding Nipples'),
  mastitisOrAbscess('mastitis_abscess', 'Red, Hot, Tender Swelling / Suspected Abscess (DANGER SIGN)');

  final String code;
  final String label;
  const PncBreastStatus(this.code, this.label);

  bool get isDangerSign => this == PncBreastStatus.mastitisOrAbscess;
}

/// Perineal or surgical wound healing status (Requirement 15.3).
enum PncWoundStatus {
  normalHealing('normal', 'Clean, Dry, Intact, Healing Normally'),
  mildDiscomfort('mild_discomfort', 'Mild Tenderness without Discharge'),
  pusOrInfection('pus_infection', 'Swollen, Red, Pus Discharge, Foul Smell (DANGER SIGN)'),
  woundDehiscence('dehiscence', 'Wound Breakdown / Gaping Edges (DANGER SIGN)');

  final String code;
  final String label;
  const PncWoundStatus(this.code, this.label);

  bool get isDangerSign =>
      this == PncWoundStatus.pusOrInfection || this == PncWoundStatus.woundDehiscence;
}

/// Postpartum Depression (PPD) assessment indicators (Requirement 15.5).
class PncDepressionScreening {
  final bool feelsOverwhelmedOrHopeless;
  final bool persistentCryingOrSadness;
  final bool difficultyBondingWithBaby;
  final bool severeAnxietyOrInsomnia;
  final bool thoughtsOfSelfHarmOrHarmToBaby; // URGENT RED FLAG

  const PncDepressionScreening({
    this.feelsOverwhelmedOrHopeless = false,
    this.persistentCryingOrSadness = false,
    this.difficultyBondingWithBaby = false,
    this.severeAnxietyOrInsomnia = false,
    this.thoughtsOfSelfHarmOrHarmToBaby = false,
  });

  /// Evaluates positive screening for postpartum depression.
  bool get hasPpdIndicators =>
      thoughtsOfSelfHarmOrHarmToBaby ||
      ((feelsOverwhelmedOrHopeless ? 1 : 0) +
              (persistentCryingOrSadness ? 1 : 0) +
              (difficultyBondingWithBaby ? 1 : 0) +
              (severeAnxietyOrInsomnia ? 1 : 0)) >=
          2;

  bool get isSevereUrgentRisk => thoughtsOfSelfHarmOrHarmToBaby;

  List<String> get ppdFindings {
    final list = <String>[];
    if (thoughtsOfSelfHarmOrHarmToBaby) {
      list.add('Urgent: Thoughts of self-harm or harm to baby (Immediate psychiatric crisis referral)');
    }
    if (feelsOverwhelmedOrHopeless) list.add('Constant feeling of sadness, hopelessness or emptiness');
    if (persistentCryingOrSadness) list.add('Frequent unexplained crying or emotional numbness');
    if (difficultyBondingWithBaby) list.add('Difficulty bonding with or feeling affection for newborn');
    if (severeAnxietyOrInsomnia) list.add('Severe anxiety, panic attacks, or inability to sleep even when baby sleeps');
    return list;
  }
}

/// Full guided postpartum checklist for mother (Requirements 15.3 – 15.6).
class PncChecklistData {
  final int visitDay; // Day 1, 3, 7, 14, 21, 28, 42
  final double? temperatureC;
  final int? systolicBp;
  final int? diastolicBp;
  final PncBleedingStatus bleedingStatus;
  final PncBreastStatus breastStatus;
  final PncWoundStatus woundStatus;
  final PncDepressionScreening depressionScreening;

  // General danger symptoms
  final bool severeHeadacheOrBlurredVision;
  final bool convulsionsOrLossOfConsciousness;
  final bool severeAbdominalPain;
  final bool severeBreathlessness;

  // Counselling & Support
  final bool nutritionCounsellingGiven;
  final bool restAndHydrationCounseled;
  final bool postpartumContraceptionCounseled;
  final String? chosenContraceptionMethod; // PPIUCD, Chhaya, Antara, Condoms, Tubectomy, LAM
  final String? generalNotes;

  const PncChecklistData({
    required this.visitDay,
    this.temperatureC,
    this.systolicBp,
    this.diastolicBp,
    required this.bleedingStatus,
    required this.breastStatus,
    required this.woundStatus,
    this.depressionScreening = const PncDepressionScreening(),
    this.severeHeadacheOrBlurredVision = false,
    this.convulsionsOrLossOfConsciousness = false,
    this.severeAbdominalPain = false,
    this.severeBreathlessness = false,
    this.nutritionCounsellingGiven = true,
    this.restAndHydrationCounseled = true,
    this.postpartumContraceptionCounseled = true,
    this.chosenContraceptionMethod,
    this.generalNotes,
  });

  /// Evaluates immediate maternal clinical danger signs (Requirement 15.4).
  List<String> get maternalDangerSigns {
    final signs = <String>[];
    if (bleedingStatus.isDangerSign) {
      signs.add(bleedingStatus.label);
    }
    if (temperatureC != null && temperatureC! >= 38.0) {
      signs.add('High postpartum fever ($temperatureC°C >= 38.0°C) — suspected puerperal sepsis');
    }
    if (systolicBp != null && diastolicBp != null) {
      if (systolicBp! >= 160 || diastolicBp! >= 110) {
        signs.add('Severe hypertension (BP $systolicBp/$diastolicBp mmHg) — postpartum eclampsia risk');
      }
    }
    if (convulsionsOrLossOfConsciousness) {
      signs.add('Convulsions, fits, or loss of consciousness (Postpartum Eclampsia)');
    }
    if (severeHeadacheOrBlurredVision) {
      signs.add('Severe persistent headache with blurred vision / epigastric pain');
    }
    if (woundStatus.isDangerSign) {
      signs.add(woundStatus.label);
    }
    if (breastStatus.isDangerSign) {
      signs.add(breastStatus.label);
    }
    if (severeAbdominalPain) {
      signs.add('Severe persistent lower abdominal tenderness / uterine pain');
    }
    if (severeBreathlessness) {
      signs.add('Severe breathlessness / chest pain (Suspected pulmonary embolism / fluid overload)');
    }
    if (depressionScreening.isSevereUrgentRisk) {
      signs.add('Acute psychiatric crisis / thoughts of self-harm');
    }
    return signs;
  }

  bool get hasRedFlag => maternalDangerSigns.isNotEmpty;
  bool get hasPpd => depressionScreening.hasPpdIndicators;
}

/// Result of a completed PNC contact (Requirements 15.3 – 15.6).
class PncVisitResult {
  final String encounterId;
  final String visitScheduleId;
  final String motherId;
  final int visitDay;
  final bool isRedFlag;
  final List<String> dangerSigns;
  final bool hasPpd;
  final List<String> ppdFindings;
  final TriageResult? triageResult;
  final String? suggestedReferral;
  final String? prePopulatedReferralReason;
  final bool institutionalDeliveryIncentiveEligible;
  final String? incentiveEventId;

  const PncVisitResult({
    required this.encounterId,
    required this.visitScheduleId,
    required this.motherId,
    required this.visitDay,
    required this.isRedFlag,
    required this.dangerSigns,
    required this.hasPpd,
    required this.ppdFindings,
    this.triageResult,
    this.suggestedReferral,
    this.prePopulatedReferralReason,
    this.institutionalDeliveryIncentiveEligible = false,
    this.incentiveEventId,
  });
}
