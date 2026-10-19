import 'dart:math' as math;

/// Clinical severity tier for respiratory assessment and growth triage
enum ClinicalTriageTier {
  red,
  yellow,
  green,
}

/// WHO / IMNCI Fast Breathing Classification (Requirement 29.1).
class FastBreathingClassifier {
  /// Classifies respiratory rate against age-appropriate IMNCI fast-breathing thresholds.
  ///
  /// Thresholds:
  /// - < 2 months: >= 60 breaths/min (RED Alert - Severe Pneumonia danger sign)
  /// - 2 to 11 months: >= 50 breaths/min (YELLOW Alert - Pneumonia)
  /// - 12 to 59 months: >= 40 breaths/min (YELLOW Alert - Pneumonia)
  /// - >= 5 years: >= 30 breaths/min (YELLOW Alert - Tachypnea)
  static Map<String, dynamic> classify({
    required int ageMonths,
    required int breathsPerMinute,
  }) {
    int threshold;
    ClinicalTriageTier tier;
    bool isFastBreathing;
    String interpretation;

    if (ageMonths < 2) {
      threshold = 60;
      isFastBreathing = breathsPerMinute >= threshold;
      tier = isFastBreathing ? ClinicalTriageTier.red : ClinicalTriageTier.green;
      interpretation = isFastBreathing
          ? 'Fast breathing in young infant (< 2 months). Severe Pneumonia / Serious Bacterial Infection (RED alert).'
          : 'Normal breathing rate for young infant.';
    } else if (ageMonths < 12) {
      threshold = 50;
      isFastBreathing = breathsPerMinute >= threshold;
      tier = isFastBreathing ? ClinicalTriageTier.yellow : ClinicalTriageTier.green;
      interpretation = isFastBreathing
          ? 'Fast breathing in infant (2–11 months). Presumptive Pneumonia (YELLOW alert).'
          : 'Normal breathing rate for infant.';
    } else if (ageMonths < 60) {
      threshold = 40;
      isFastBreathing = breathsPerMinute >= threshold;
      tier = isFastBreathing ? ClinicalTriageTier.yellow : ClinicalTriageTier.green;
      interpretation = isFastBreathing
          ? 'Fast breathing in child (12–59 months). Presumptive Pneumonia (YELLOW alert).'
          : 'Normal breathing rate for child.';
    } else {
      threshold = 30;
      isFastBreathing = breathsPerMinute >= threshold;
      tier = isFastBreathing ? ClinicalTriageTier.yellow : ClinicalTriageTier.green;
      interpretation = isFastBreathing
          ? 'Tachypnea / Fast breathing in older child or adult (>= 5 years).'
          : 'Normal breathing rate.';
    }

    return {
      'age_months': ageMonths,
      'breaths_per_minute': breathsPerMinute,
      'threshold': threshold,
      'is_fast_breathing': isFastBreathing,
      'triage_tier': tier,
      'interpretation': interpretation,
    };
  }
}

/// WHO / UNICEF MUAC (Mid-Upper Arm Circumference) classification (Requirement 29.2).
enum MuacCategory {
  redSam('red', 'Severe Acute Malnutrition (SAM)', 0xFFD32F2F),
  yellowMam('yellow', 'Moderate Acute Malnutrition (MAM)', 0xFFFBC02D),
  greenNormal('green', 'Normal Nutrition Status', 0xFF388E3C);

  final String code;
  final String label;
  final int colorValue;
  const MuacCategory(this.code, this.label, this.colorValue);
}

class MuacClassifier {
  /// Evaluates child MUAC in centimeters (6 – 59 months).
  ///
  /// Standards:
  /// - < 11.5 cm: Red (SAM - Immediate Referral)
  /// - 11.5 cm to 12.5 cm: Yellow (MAM - Supplementary Nutrition Counseling)
  /// - > 12.5 cm: Green (Normal)
  static MuacCategory classify(double muacCm) {
    if (muacCm < 11.5) {
      return MuacCategory.redSam;
    } else if (muacCm <= 12.5) {
      return MuacCategory.yellowMam;
    } else {
      return MuacCategory.greenNormal;
    }
  }
}

/// Offline Clinical Calculators for ASHA Scope of Care (Requirement 29.5).
class ClinicalCalculators {
  /// Calculates Expected Date of Delivery (EDD) from Last Menstrual Period (LMP) using Naegele's rule.
  /// EDD = LMP + 280 days (40 weeks)
  static DateTime calculateEdd(DateTime lmp) {
    return lmp.add(const Duration(days: 280));
  }

  /// Calculates Gestational Age in completed weeks and days.
  static Map<String, int> calculateGestationalAge(DateTime lmp, [DateTime? asOfDate]) {
    final ref = asOfDate ?? DateTime.now();
    final differenceDays = ref.difference(lmp).inDays;
    final totalDays = math.max(0, differenceDays);

    final weeks = totalDays ~/ 7;
    final days = totalDays % 7;

    return {
      'total_days': totalDays,
      'weeks': weeks,
      'days': days,
    };
  }

  /// Calculates Body Mass Index (BMI) and Asian-Indian population risk classification.
  static Map<String, dynamic> calculateBmi({
    required double weightKg,
    required double heightCm,
  }) {
    if (heightCm <= 0 || weightKg <= 0) {
      throw ArgumentError('Weight and height must be positive values.');
    }

    final heightM = heightCm / 100.0;
    final bmi = weightKg / (heightM * heightM);
    final rounded = double.parse(bmi.toStringAsFixed(1));

    String classification;
    int colorValue;

    // Asian-Indian WHO Consensus Guidelines for Obesity & Metabolic Risk
    if (rounded < 18.5) {
      classification = 'Underweight (< 18.5)';
      colorValue = 0xFFFFA000;
    } else if (rounded <= 22.9) {
      classification = 'Normal (18.5 – 22.9)';
      colorValue = 0xFF388E3C;
    } else if (rounded <= 24.9) {
      classification = 'Overweight (23.0 – 24.9)';
      colorValue = 0xFFF57C00;
    } else {
      classification = 'Obese (>= 25.0)';
      colorValue = 0xFFD32F2F;
    }

    return {
      'bmi': rounded,
      'classification': classification,
      'color_value': colorValue,
    };
  }

  /// Calculates pediatric Paracetamol dose (10–15 mg/kg per dose every 4–6 hours).
  static Map<String, dynamic> calculateParacetamolDose({
    required double weightKg,
    double syrupConcentrationMgPer5Ml = 120.0, // standard pediatric syrup 120mg/5mL or 250mg/5mL
  }) {
    if (weightKg <= 0) throw ArgumentError('Weight must be positive.');

    final minMg = double.parse((weightKg * 10.0).toStringAsFixed(1));
    final maxMg = double.parse((weightKg * 15.0).toStringAsFixed(1));
    final targetMg = double.parse((weightKg * 12.5).toStringAsFixed(1));

    // Volume in mL = targetMg * (5.0 / syrupConcentration)
    final mlPerDose = double.parse((targetMg * (5.0 / syrupConcentrationMgPer5Ml)).toStringAsFixed(1));

    return {
      'weight_kg': weightKg,
      'target_dose_mg': targetMg,
      'min_dose_mg': minMg,
      'max_dose_mg': maxMg,
      'syrup_volume_ml': mlPerDose,
      'frequency': 'Every 4 to 6 hours as needed for fever/pain (Maximum 4 doses in 24 hours)',
    };
  }

  /// Calculates Pediatric Zinc Sulfate supplement dosage for childhood diarrhea (14-day course).
  static Map<String, dynamic> calculateZincDose(int ageMonths) {
    if (ageMonths < 6) {
      return {
        'dose_mg': 10.0,
        'form': 'Half dispersible tablet (10 mg) dissolved in breastmilk/clean water daily',
        'duration_days': 14,
        'instructions': 'Continue for the full 14 days even if diarrhea stops earlier.',
      };
    } else {
      return {
        'dose_mg': 20.0,
        'form': 'One full dispersible tablet (20 mg) dissolved in water/food daily',
        'duration_days': 14,
        'instructions': 'Continue for the full 14 days even if diarrhea stops earlier.',
      };
    }
  }

  /// Calculates Oral Rehydration Salts (ORS) volume for dehydration.
  static Map<String, dynamic> calculateOrsDosage({
    required double weightKg,
    required bool hasSomeDehydration,
  }) {
    if (hasSomeDehydration) {
      // WHO Plan B: 75 mL per kg over 4 hours
      final volumeMl = (weightKg * 75.0).round();
      return {
        'regimen': 'WHO Plan B (Some Dehydration)',
        'volume_ml': volumeMl,
        'duration_hours': 4,
        'instructions': 'Give $volumeMl mL of low-osmolarity ORS solution slowly by spoon over 4 hours. Reassess hydration after 4 hours.',
      };
    } else {
      // WHO Plan A: Prevention of dehydration at home
      return {
        'regimen': 'WHO Plan A (Home Treatment)',
        'volume_ml': weightKg < 10.0 ? 100 : 200,
        'instructions': 'Give 50–100 mL (< 2 yrs) or 100–200 mL (>= 2 yrs) after every loose watery stool.',
      };
    }
  }

  /// Calculates Iron Folic Acid (IFA) regimen according to Anemia Mukt Bharat guidelines.
  static Map<String, dynamic> calculateIfaDosing({
    required String targetCategory, // 'pregnant', 'lactating', 'child_6_59m', 'child_5_9y', 'adolescent'
  }) {
    switch (targetCategory.toLowerCase()) {
      case 'pregnant':
        return {
          'tablet_type': 'Red IFA Tablet (60 mg elemental iron + 500 mcg folic acid)',
          'schedule': '1 tablet daily starting from 14th week of pregnancy (second trimester) for at least 180 days',
          'counseling': 'Do not consume with tea or milk. Take with citrus/lemon water after meals.',
        };
      case 'lactating':
        return {
          'tablet_type': 'Red IFA Tablet (60 mg elemental iron + 500 mcg folic acid)',
          'schedule': '1 tablet daily for 180 days postpartum',
          'counseling': 'Take daily to replenish maternal iron stores.',
        };
      case 'child_6_59m':
        return {
          'tablet_type': 'IFA Syrup (20 mg iron + 100 mcg folic acid per mL)',
          'schedule': '1 mL bi-weekly throughout the year (100 doses)',
          'counseling': 'Administer using clean graduated dropper.',
        };
      case 'child_5_9y':
        return {
          'tablet_type': 'Pink IFA Tablet (45 mg elemental iron + 400 mcg folic acid)',
          'schedule': '1 tablet weekly under direct observation',
          'counseling': 'Administer at school/Anganwadi every Wednesday.',
        };
      case 'adolescent':
      default:
        return {
          'tablet_type': 'Blue IFA Tablet (60 mg elemental iron + 500 mcg folic acid)',
          'schedule': '1 tablet weekly on fixed day (Wednesday)',
          'counseling': 'Accompanied by bi-annual Albendazole (400 mg) deworming.',
        };
    }
  }

  /// Computes approximate WHO Growth Standard Weight-for-Age Z-Score for children 0–5 years.
  static Map<String, dynamic> calculateWhoGrowthZScore({
    required double weightKg,
    required int ageMonths,
    required String sex, // 'M' or 'F'
  }) {
    // Median and SD approximated from WHO Child Growth Standards
    final isMale = sex.toUpperCase() == 'M';
    final double median;
    if (ageMonths <= 12) {
      median = isMale ? (3.3 + ageMonths * 0.55) : (3.2 + ageMonths * 0.52);
    } else {
      final base12 = isMale ? 9.9 : 9.4;
      median = base12 + (ageMonths - 12) * (isMale ? 0.18 : 0.17);
    }
    final sd = median * 0.12;

    final zScore = (weightKg - median) / sd;
    final roundedZ = double.parse(zScore.toStringAsFixed(1));

    String classification;
    ClinicalTriageTier tier;

    if (roundedZ < -3.0) {
      classification = 'Severely Underweight (< -3 SD)';
      tier = ClinicalTriageTier.red;
    } else if (roundedZ < -2.0) {
      classification = 'Moderately Underweight (-3 SD to -2 SD)';
      tier = ClinicalTriageTier.yellow;
    } else if (roundedZ <= 2.0) {
      classification = 'Normal Weight-for-Age (-2 SD to +2 SD)';
      tier = ClinicalTriageTier.green;
    } else {
      classification = 'Overweight / Growth Acceleration (> +2 SD)';
      tier = ClinicalTriageTier.yellow;
    }

    return {
      'weight_kg': weightKg,
      'age_months': ageMonths,
      'median_weight_kg': double.parse(median.toStringAsFixed(1)),
      'z_score': roundedZ,
      'classification': classification,
      'tier': tier,
    };
  }
}

/// Regulatory and Safety Guard for Experimental Camera/AI Estimations (Requirement 29.4).
///
/// Acceptance Criteria:
/// - SHALL label prominently as "experimental".
/// - SHALL require clinical validation and CDSCO regulatory approval annotation.
/// - SHALL NOT use experimental estimates as the sole basis for reducing triage severity from Red or Yellow.
class ExperimentalAiGuard {
  static const String disclaimerText =
      'EXPERIMENTAL AID: Camera-based measurement is under active clinical research and has NOT received CDSCO regulatory device clearance. It is provided for observational guidance only and must NEVER be used to downgrade clinical triage from RED or YELLOW.';

  /// Enforces safety invariant: an experimental camera reading cannot downgrade an established
  /// Red or Yellow severity to Green.
  static ClinicalTriageTier reconcileTriageSeverity({
    required ClinicalTriageTier clinicalTier,
    required ClinicalTriageTier experimentalCameraTier,
  }) {
    // If clinical protocol assessed RED or YELLOW, experimental AI is forbidden from reducing it
    if (clinicalTier == ClinicalTriageTier.red) {
      return ClinicalTriageTier.red;
    }
    if (clinicalTier == ClinicalTriageTier.yellow && experimentalCameraTier == ClinicalTriageTier.green) {
      return ClinicalTriageTier.yellow;
    }

    // Experimental AI may only escalate severity (e.g. Green -> Yellow/Red for earlier referral)
    return experimentalCameraTier.index < clinicalTier.index ? experimentalCameraTier : clinicalTier;
  }
}
