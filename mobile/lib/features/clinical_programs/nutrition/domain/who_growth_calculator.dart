import 'dart:math' as math;

import '../../../../core/triage/models/models.dart';
import 'growth_models.dart';
import 'who_standards_data.dart';

/// Pure clinical calculator implementing WHO Child Growth Standards and
/// MoHFW National Malnutrition & Anaemia Guidelines (Requirement 17.1 – 17.5).
class WhoGrowthCalculator {
  /// Computes WHO Z-score from anthropometric measurement [x] and LMS parameters.
  ///
  /// Implements standard Box-Cox power transformation with WHO standard
  /// restricted SD3 adjustments for extreme Z-scores.
  ///
  /// Guarantees strictly non-decreasing monotonicity:
  /// For any fixed (l, m, s), if x2 > x1 then calculateZScore(x2) >= calculateZScore(x1).
  /// (Property 8: WHO Z-Score Monotonicity).
  static double calculateZScore({
    required double measurement,
    required double l,
    required double m,
    required double s,
  }) {
    if (measurement <= 0 || m <= 0 || s <= 0) {
      return 0.0;
    }

    // 1. Initial Box-Cox calculation
    double zInd;
    if (l.abs() < 0.0001) {
      zInd = math.log(measurement / m) / s;
    } else {
      zInd = (math.pow(measurement / m, l) - 1.0) / (l * s);
    }

    // 2. WHO standard adjustment for extreme values beyond +/- 3 SD
    if (zInd > 3.0) {
      final sd3pos = _calcSdBound(3.0, l, m, s);
      final sd2pos = _calcSdBound(2.0, l, m, s);
      final sd23pos = sd3pos - sd2pos;
      if (sd23pos > 0) {
        return 3.0 + ((measurement - sd3pos) / sd23pos);
      }
    } else if (zInd < -3.0) {
      final sd3neg = _calcSdBound(-3.0, l, m, s);
      final sd2neg = _calcSdBound(-2.0, l, m, s);
      final sd23neg = sd2neg - sd3neg;
      if (sd23neg > 0) {
        return -3.0 + ((measurement - sd3neg) / sd23neg);
      }
    }

    return zInd;
  }

  static double _calcSdBound(double z, double l, double m, double s) {
    if (l.abs() < 0.0001) {
      return m * math.exp(s * z);
    }
    final term = 1.0 + (l * s * z);
    if (term <= 0) return 0.0;
    return m * math.pow(term, 1.0 / l);
  }

  /// Linearly interpolates LMS parameters from an empirical table for point [x].
  static LmsPoint interpolateLms(List<LmsPoint> table, double x) {
    if (table.isEmpty) {
      throw ArgumentError('LMS lookup table cannot be empty');
    }
    if (x <= table.first.x) return table.first;
    if (x >= table.last.x) return table.last;

    for (int i = 0; i < table.length - 1; i++) {
      final p1 = table[i];
      final p2 = table[i + 1];
      if (x >= p1.x && x <= p2.x) {
        final t = (x - p1.x) / (p2.x - p1.x);
        return LmsPoint(
          x: x,
          l: p1.l + t * (p2.l - p1.l),
          m: p1.m + t * (p2.m - p1.m),
          s: p1.s + t * (p2.s - p1.s),
          sd3neg: p1.sd3neg + t * (p2.sd3neg - p1.sd3neg),
          sd2neg: p1.sd2neg + t * (p2.sd2neg - p1.sd2neg),
          sd1neg: p1.sd1neg + t * (p2.sd1neg - p1.sd1neg),
          sd0: p1.sd0 + t * (p2.sd0 - p1.sd0),
          sd1pos: p1.sd1pos + t * (p2.sd1pos - p1.sd1pos),
          sd2pos: p1.sd2pos + t * (p2.sd2pos - p1.sd2pos),
          sd3pos: p1.sd3pos + t * (p2.sd3pos - p1.sd3pos),
        );
      }
    }

    return table.last;
  }

  /// Calculates Weight-for-Age Z-score (WAZ) (0 to 60 months).
  static double calculateWaz({
    required double weightKg,
    required double ageMonths,
    required String sex,
  }) {
    final table = sex.toUpperCase() == 'M' ? WhoStandardsData.wazBoys : WhoStandardsData.wazGirls;
    final lms = interpolateLms(table, ageMonths);
    return calculateZScore(measurement: weightKg, l: lms.l, m: lms.m, s: lms.s);
  }

  /// Calculates Length/Height-for-Age Z-score (HAZ) (0 to 60 months).
  static double calculateHaz({
    required double heightCm,
    required double ageMonths,
    required String sex,
  }) {
    final table = sex.toUpperCase() == 'M' ? WhoStandardsData.hazBoys : WhoStandardsData.hazGirls;
    final lms = interpolateLms(table, ageMonths);
    return calculateZScore(measurement: heightCm, l: lms.l, m: lms.m, s: lms.s);
  }

  /// Calculates Weight-for-Height/Length Z-score (WFHZ) (45 cm to 120 cm).
  static double calculateWfhz({
    required double weightKg,
    required double heightCm,
    required String sex,
  }) {
    final table = sex.toUpperCase() == 'M' ? WhoStandardsData.wfhzBoys : WhoStandardsData.wfhzGirls;
    final lms = interpolateLms(table, heightCm);
    return calculateZScore(measurement: weightKg, l: lms.l, m: lms.m, s: lms.s);
  }

  /// Classifies Mid-Upper Arm Circumference (MUAC).
  static MuacClassification classifyMuac(double muacCm, {double? ageMonths}) {
    if (ageMonths != null && ageMonths < 6.0) {
      if (muacCm < 11.0) return MuacClassification.sam;
      if (muacCm < 12.0) return MuacClassification.mam;
      return MuacClassification.normal;
    }

    if (muacCm < 11.5) {
      return MuacClassification.sam;
    } else if (muacCm < 12.5) {
      return MuacClassification.mam;
    } else {
      return MuacClassification.normal;
    }
  }

  /// Classifies anaemia severity per WHO and Anemia Mukt Bharat thresholds (Requirement 17.5).
  static AnaemiaSeverity classifyAnaemia({
    required double haemoglobinGdl,
    required double ageMonths,
    required String sex,
    bool isPregnant = false,
  }) {
    if (haemoglobinGdl <= 0) return AnaemiaSeverity.none;

    final isFemale = sex.toUpperCase() == 'F';

    if (isPregnant) {
      // Pregnant Women: Severe < 7.0, Moderate 7.0-9.9, Mild 10.0-10.9, Normal >= 11.0
      if (haemoglobinGdl < 7.0) return AnaemiaSeverity.severe;
      if (haemoglobinGdl < 10.0) return AnaemiaSeverity.moderate;
      if (haemoglobinGdl < 11.0) return AnaemiaSeverity.mild;
      return AnaemiaSeverity.none;
    }

    if (ageMonths < 60) {
      // Children 6 to 59 months: Severe < 7.0, Moderate 7.0-9.9, Mild 10.0-10.9, Normal >= 11.0
      if (haemoglobinGdl < 7.0) return AnaemiaSeverity.severe;
      if (haemoglobinGdl < 10.0) return AnaemiaSeverity.moderate;
      if (haemoglobinGdl < 11.0) return AnaemiaSeverity.mild;
      return AnaemiaSeverity.none;
    } else if (ageMonths < 144) {
      // Children 5 to 11 years (60 to 143 months): Severe < 7.0, Moderate 7.0-9.9, Mild 10.0-11.4, Normal >= 11.5
      if (haemoglobinGdl < 7.0) return AnaemiaSeverity.severe;
      if (haemoglobinGdl < 10.0) return AnaemiaSeverity.moderate;
      if (haemoglobinGdl < 11.5) return AnaemiaSeverity.mild;
      return AnaemiaSeverity.none;
    } else {
      // Adolescents & Adults (>= 12 years)
      if (isFemale) {
        // Non-pregnant women & adolescent girls: Severe < 7.0, Moderate 7.0-9.9, Mild 10.0-11.9, Normal >= 12.0
        if (haemoglobinGdl < 7.0) return AnaemiaSeverity.severe;
        if (haemoglobinGdl < 10.0) return AnaemiaSeverity.moderate;
        if (haemoglobinGdl < 12.0) return AnaemiaSeverity.mild;
        return AnaemiaSeverity.none;
      } else {
        // Adult men: Severe < 8.0, Moderate 8.0-10.9, Mild 11.0-12.9, Normal >= 13.0
        if (haemoglobinGdl < 8.0) return AnaemiaSeverity.severe;
        if (haemoglobinGdl < 11.0) return AnaemiaSeverity.moderate;
        if (haemoglobinGdl < 13.0) return AnaemiaSeverity.mild;
        return AnaemiaSeverity.none;
      }
    }
  }

  /// Full comprehensive offline classification of nutritional status (Requirement 17.1 – 17.3).
  static GrowthMeasurement evaluateNutritionalStatus({
    required String id,
    required String memberId,
    required DateTime measuredAt,
    required DateTime dateOfBirth,
    required String sex,
    required double weightKg,
    double? heightCm,
    double? muacCm,
    bool bilateralOedema = false,
    bool? appetiteTestPassed,
    double? haemoglobinGdl,
    bool isPregnant = false,
  }) {
    final ageInDays = measuredAt.difference(dateOfBirth).inDays;
    final ageInMonths = (ageInDays / 30.4375).clamp(0.0, 120.0);

    // 1. Z-scores
    final waz = calculateWaz(weightKg: weightKg, ageMonths: ageInMonths, sex: sex);
    final haz = heightCm != null ? calculateHaz(heightCm: heightCm, ageMonths: ageInMonths, sex: sex) : null;
    final wfhz = heightCm != null ? calculateWfhz(weightKg: weightKg, heightCm: heightCm, sex: sex) : null;

    // 2. Classifications
    UnderweightStatus underweightStatus;
    if (waz < -3.0) {
      underweightStatus = UnderweightStatus.severeUnderweight;
    } else if (waz < -2.0) {
      underweightStatus = UnderweightStatus.moderateUnderweight;
    } else if (waz > 2.0) {
      underweightStatus = UnderweightStatus.overweight;
    } else {
      underweightStatus = UnderweightStatus.normal;
    }

    StuntingStatus stuntingStatus;
    if (haz != null) {
      if (haz < -3.0) {
        stuntingStatus = StuntingStatus.severeStunting;
      } else if (haz < -2.0) {
        stuntingStatus = StuntingStatus.moderateStunting;
      } else {
        stuntingStatus = StuntingStatus.normal;
      }
    } else {
      stuntingStatus = StuntingStatus.normal;
    }

    final muacClass = muacCm != null ? classifyMuac(muacCm, ageMonths: ageInMonths) : null;

    WastingStatus wastingStatus;
    if (bilateralOedema || (wfhz != null && wfhz < -3.0) || muacClass == MuacClassification.sam) {
      wastingStatus = WastingStatus.sam;
    } else if ((wfhz != null && wfhz < -2.0) || muacClass == MuacClassification.mam) {
      wastingStatus = WastingStatus.mam;
    } else {
      wastingStatus = WastingStatus.normal;
    }

    final anaemiaSev = haemoglobinGdl != null
        ? classifyAnaemia(
            haemoglobinGdl: haemoglobinGdl,
            ageMonths: ageInMonths,
            sex: sex,
            isPregnant: isPregnant,
          )
        : null;

    // 3. Triage & Recommendations (Requirements 17.2, 17.3)
    final findings = <String>[];
    final actions = <String>[];
    TriageFlag flag = TriageFlag.green;
    String? referralDestination;

    if (bilateralOedema) {
      findings.add('Bilateral pitting oedema present (+/++) — indicator of Kwashiorkor/SAM');
      flag = TriageFlag.red;
    }

    if (wastingStatus == WastingStatus.sam) {
      findings.add('Severe Acute Malnutrition (SAM) identified (${wfhz != null ? "WFHZ ${wfhz.toStringAsFixed(2)}" : ""} ${muacCm != null ? "MUAC $muacCm cm" : ""})');
      flag = TriageFlag.red;
    }

    if (appetiteTestPassed == false) {
      findings.add('Appetite test failed — complicated SAM');
      flag = TriageFlag.red;
    }

    if (anaemiaSev == AnaemiaSeverity.severe) {
      findings.add('Severe anaemia (Hb ${haemoglobinGdl?.toStringAsFixed(1)} g/dL) detected');
      flag = TriageFlag.red;
    }

    // Set actions for RED flag
    if (flag == TriageFlag.red) {
      actions.add('REFER_TO_NRC_IMMEDIATELY');
      actions.add('Arrange 108 emergency transport to Nutrition Rehabilitation Centre (NRC) or District Hospital');
      actions.add('Keep child warm during transport to prevent hypothermia');
      actions.add('Do NOT administer diuretic or high-protein feeds without medical supervision');
      referralDestination = 'Nutrition Rehabilitation Centre (NRC) / CHC';
    } else if (wastingStatus == WastingStatus.mam) {
      // MAM -> Yellow flag (Requirement 17.3)
      flag = TriageFlag.yellow;
      findings.add('Moderate Acute Malnutrition (MAM) identified (${wfhz != null ? "WFHZ ${wfhz.toStringAsFixed(2)}" : ""} ${muacCm != null ? "MUAC $muacCm cm" : ""})');
      actions.add('LINK_TO_ANGANWADI_FOR_SUPPLEMENTARY_NUTRITION');
      actions.add('Counsel mother on energy-dense feeds and frequent feeding');
      actions.add('Schedule bi-weekly growth monitoring follow-up visits');
      referralDestination = 'Anganwadi Centre / Sub-Centre';
    } else if (stuntingStatus != StuntingStatus.normal || underweightStatus != UnderweightStatus.normal) {
      flag = TriageFlag.yellow;
      findings.add('${stuntingStatus.label} / ${underweightStatus.label}');
      actions.add('Counsel caregiver on age-appropriate complementary feeding and micronutrients');
    }

    if (anaemiaSev != null && (anaemiaSev == AnaemiaSeverity.moderate || anaemiaSev == AnaemiaSeverity.mild)) {
      if (flag == TriageFlag.green) flag = TriageFlag.yellow;
      findings.add('${anaemiaSev.label} (Hb ${haemoglobinGdl?.toStringAsFixed(1)} g/dL)');
      actions.add('Initiate daily therapeutic IFA syrup/tablet regimen per national protocol');
    }

    if (findings.isEmpty) {
      findings.add('Nutritional status is within normal WHO growth standards');
      actions.add('Continue routine age-appropriate feeding and growth monitoring at next VHSND');
    }

    return GrowthMeasurement(
      id: id,
      memberId: memberId,
      measuredAt: measuredAt,
      ageInDays: ageInDays,
      ageInMonths: ageInMonths,
      weightKg: weightKg,
      heightCm: heightCm,
      muacCm: muacCm,
      bilateralOedema: bilateralOedema,
      appetiteTestPassed: appetiteTestPassed,
      haemoglobinGdl: haemoglobinGdl,
      waz: double.parse(waz.toStringAsFixed(2)),
      haz: haz != null ? double.parse(haz.toStringAsFixed(2)) : null,
      wfhz: wfhz != null ? double.parse(wfhz.toStringAsFixed(2)) : null,
      wastingStatus: wastingStatus,
      stuntingStatus: stuntingStatus,
      underweightStatus: underweightStatus,
      muacClassification: muacClass,
      anaemiaSeverity: anaemiaSev,
      triageFlag: flag,
      clinicalFindings: findings,
      recommendedActions: actions,
      suggestedReferralDestination: referralDestination,
    );
  }
}
