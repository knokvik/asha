import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/features/devices/domain/measurement_aids.dart';

void main() {
  group('Task 12.5: Zero-Hardware Measurement Aids & Clinical Calculators (Requirements 29.1 – 29.5)', () {
    // ── 1. WHO / IMNCI Fast Breathing Classification (Requirement 29.1) ────────
    group('FastBreathingClassifier', () {
      test('classifies young infants (< 2 months) with threshold >= 60 (RED Alert)', () {
        // Fast breathing: 62 breaths/min -> RED
        final resFast = FastBreathingClassifier.classify(ageMonths: 1, breathsPerMinute: 62);
        expect(resFast['is_fast_breathing'], isTrue);
        expect(resFast['threshold'], equals(60));
        expect(resFast['triage_tier'], equals(ClinicalTriageTier.red));
        expect(resFast['interpretation'], contains('Severe Pneumonia'));

        // Normal: 55 breaths/min -> GREEN
        final resNormal = FastBreathingClassifier.classify(ageMonths: 1, breathsPerMinute: 55);
        expect(resNormal['is_fast_breathing'], isFalse);
        expect(resNormal['triage_tier'], equals(ClinicalTriageTier.green));
      });

      test('classifies infants (2 – 11 months) with threshold >= 50 (YELLOW Alert)', () {
        // Fast breathing: 52 breaths/min -> YELLOW
        final resFast = FastBreathingClassifier.classify(ageMonths: 6, breathsPerMinute: 52);
        expect(resFast['is_fast_breathing'], isTrue);
        expect(resFast['threshold'], equals(50));
        expect(resFast['triage_tier'], equals(ClinicalTriageTier.yellow));

        // Normal: 45 breaths/min -> GREEN
        final resNormal = FastBreathingClassifier.classify(ageMonths: 6, breathsPerMinute: 45);
        expect(resNormal['is_fast_breathing'], isFalse);
        expect(resNormal['triage_tier'], equals(ClinicalTriageTier.green));
      });

      test('classifies young children (12 – 59 months) with threshold >= 40 (YELLOW Alert)', () {
        // Fast breathing: 44 breaths/min -> YELLOW
        final resFast = FastBreathingClassifier.classify(ageMonths: 24, breathsPerMinute: 44);
        expect(resFast['is_fast_breathing'], isTrue);
        expect(resFast['threshold'], equals(40));
        expect(resFast['triage_tier'], equals(ClinicalTriageTier.yellow));

        // Normal: 34 breaths/min -> GREEN
        final resNormal = FastBreathingClassifier.classify(ageMonths: 24, breathsPerMinute: 34);
        expect(resNormal['is_fast_breathing'], isFalse);
        expect(resNormal['triage_tier'], equals(ClinicalTriageTier.green));
      });

      test('classifies children >= 5 years with threshold >= 30', () {
        final resFast = FastBreathingClassifier.classify(ageMonths: 72, breathsPerMinute: 32);
        expect(resFast['is_fast_breathing'], isTrue);
        expect(resFast['threshold'], equals(30));

        final resNormal = FastBreathingClassifier.classify(ageMonths: 72, breathsPerMinute: 22);
        expect(resNormal['is_fast_breathing'], isFalse);
      });
    });

    // ── 2. WHO / UNICEF MUAC Colour-Coded Tape Standards (Requirement 29.2) ───
    group('MuacClassifier Standards', () {
      test('classifies MUAC < 11.5 cm as Red (SAM - Severe Acute Malnutrition)', () {
        expect(MuacClassifier.classify(10.5), equals(MuacCategory.redSam));
        expect(MuacClassifier.classify(11.4), equals(MuacCategory.redSam));
      });

      test('classifies MUAC 11.5 cm to 12.5 cm as Yellow (MAM - Moderate Acute Malnutrition)', () {
        expect(MuacClassifier.classify(11.5), equals(MuacCategory.yellowMam));
        expect(MuacClassifier.classify(12.0), equals(MuacCategory.yellowMam));
        expect(MuacClassifier.classify(12.5), equals(MuacCategory.yellowMam));
      });

      test('classifies MUAC > 12.5 cm as Green (Normal Nutrition)', () {
        expect(MuacClassifier.classify(12.6), equals(MuacCategory.greenNormal));
        expect(MuacClassifier.classify(14.0), equals(MuacCategory.greenNormal));
      });
    });

    // ── 3. Offline Clinical Calculators (Requirement 29.5) ────────────────────
    group('ClinicalCalculators', () {
      test('computes EDD from LMP using Naegele\'s rule (LMP + 280 days)', () {
        final lmp = DateTime(2025, 1, 1);
        final edd = ClinicalCalculators.calculateEdd(lmp);

        // 2025-01-01 + 280 days = 2025-10-08
        expect(edd.year, equals(2025));
        expect(edd.month, equals(10));
        expect(edd.day, equals(8));
      });

      test('computes Gestational Age in completed weeks and days', () {
        final lmp = DateTime(2025, 1, 1);
        final asOf = DateTime(2025, 3, 12); // 70 days later -> exactly 10 weeks, 0 days

        final ga = ClinicalCalculators.calculateGestationalAge(lmp, asOf);
        expect(ga['total_days'], equals(70));
        expect(ga['weeks'], equals(10));
        expect(ga['days'], equals(0));
      });

      test('computes Adult BMI according to WHO Asian-Indian cut-offs', () {
        // Underweight: 42 kg, 155 cm -> BMI 17.5
        final bmiUnder = ClinicalCalculators.calculateBmi(weightKg: 42.0, heightCm: 155.0);
        expect(bmiUnder['bmi'], equals(17.5));
        expect(bmiUnder['classification'], contains('Underweight'));

        // Normal: 52 kg, 160 cm -> BMI 20.3 (18.5 – 22.9 Asian cutoff)
        final bmiNormal = ClinicalCalculators.calculateBmi(weightKg: 52.0, heightCm: 160.0);
        expect(bmiNormal['bmi'], equals(20.3));
        expect(bmiNormal['classification'], contains('Normal'));

        // Overweight: 60 kg, 160 cm -> BMI 23.4 (23.0 – 24.9)
        final bmiOver = ClinicalCalculators.calculateBmi(weightKg: 60.0, heightCm: 160.0);
        expect(bmiOver['bmi'], equals(23.4));
        expect(bmiOver['classification'], contains('Overweight'));

        // Obese: 70 kg, 160 cm -> BMI 27.3 (>= 25.0)
        final bmiObese = ClinicalCalculators.calculateBmi(weightKg: 70.0, heightCm: 160.0);
        expect(bmiObese['bmi'], equals(27.3));
        expect(bmiObese['classification'], contains('Obese'));

        expect(() => ClinicalCalculators.calculateBmi(weightKg: -5, heightCm: 160), throwsArgumentError);
      });

      test('computes pediatric Paracetamol dosage accurately', () {
        // 10 kg child -> Target: 10 * 12.5 = 125.0 mg; min: 100 mg; max: 150 mg
        final dose = ClinicalCalculators.calculateParacetamolDose(weightKg: 10.0);

        expect(dose['weight_kg'], equals(10.0));
        expect(dose['target_dose_mg'], equals(125.0));
        expect(dose['min_dose_mg'], equals(100.0));
        expect(dose['max_dose_mg'], equals(150.0));
        expect(dose['syrup_volume_ml'], equals(5.2)); // 125 * 5 / 120 ~ 5.2 mL
      });

      test('computes Zinc diarrhea dosage based on age threshold (6 months)', () {
        // < 6 months: 10 mg daily
        final doseUnder6m = ClinicalCalculators.calculateZincDose(3);
        expect(doseUnder6m['dose_mg'], equals(10.0));
        expect(doseUnder6m['duration_days'], equals(14));

        // >= 6 months: 20 mg daily
        final doseOver6m = ClinicalCalculators.calculateZincDose(18);
        expect(doseOver6m['dose_mg'], equals(20.0));
        expect(doseOver6m['duration_days'], equals(14));
      });

      test('computes ORS solution volumes for Plan A and Plan B', () {
        // Plan B (Some Dehydration): 12 kg child -> 12 * 75 = 900 mL
        final orsPlanB = ClinicalCalculators.calculateOrsDosage(weightKg: 12.0, hasSomeDehydration: true);
        expect(orsPlanB['volume_ml'], equals(900));
        expect(orsPlanB['duration_hours'], equals(4));

        // Plan A (Home Treatment)
        final orsPlanA = ClinicalCalculators.calculateOrsDosage(weightKg: 8.0, hasSomeDehydration: false);
        expect(orsPlanA['volume_ml'], equals(100));
      });

      test('provides Anemia Mukt Bharat IFA dosing across categories', () {
        final ifaPregnant = ClinicalCalculators.calculateIfaDosing(targetCategory: 'pregnant');
        expect(ifaPregnant['tablet_type'], contains('Red IFA'));
        expect(ifaPregnant['schedule'], contains('180 days'));

        final ifaChild = ClinicalCalculators.calculateIfaDosing(targetCategory: 'child_6_59m');
        expect(ifaChild['tablet_type'], contains('IFA Syrup'));

        final ifaAdolescent = ClinicalCalculators.calculateIfaDosing(targetCategory: 'adolescent');
        expect(ifaAdolescent['tablet_type'], contains('Blue IFA'));
      });

      test('computes WHO Child Growth Weight-for-Age Z-Score', () {
        // 12-month-old male weighing 10.5 kg (around median ~10.4 kg) -> Normal
        final normalGrowth = ClinicalCalculators.calculateWhoGrowthZScore(
          weightKg: 10.5,
          ageMonths: 12,
          sex: 'M',
        );
        expect(normalGrowth['tier'], equals(ClinicalTriageTier.green));
        expect(normalGrowth['classification'], contains('Normal'));

        // 12-month-old male severely malnourished at 5.5 kg -> Severe Underweight (< -3 SD) -> RED
        final severeGrowth = ClinicalCalculators.calculateWhoGrowthZScore(
          weightKg: 5.5,
          ageMonths: 12,
          sex: 'M',
        );
        expect(severeGrowth['tier'], equals(ClinicalTriageTier.red));
        expect(severeGrowth['classification'], contains('Severely Underweight'));
      });
    });

    // ── 4. Experimental Camera / AI Non-Downgrade Invariant (Requirement 29.4) ─
    group('ExperimentalAiGuard Non-Downgrade Invariant', () {
      test('strictly prevents experimental AI from reducing RED severity to Green or Yellow', () {
        // Clinical is RED, AI camera says GREEN -> MUST REMAIN RED!
        final reconciledRed = ExperimentalAiGuard.reconcileTriageSeverity(
          clinicalTier: ClinicalTriageTier.red,
          experimentalCameraTier: ClinicalTriageTier.green,
        );
        expect(reconciledRed, equals(ClinicalTriageTier.red));

        final reconciledRedYellow = ExperimentalAiGuard.reconcileTriageSeverity(
          clinicalTier: ClinicalTriageTier.red,
          experimentalCameraTier: ClinicalTriageTier.yellow,
        );
        expect(reconciledRedYellow, equals(ClinicalTriageTier.red));
      });

      test('strictly prevents experimental AI from reducing YELLOW severity to Green', () {
        // Clinical is YELLOW, AI camera says GREEN -> MUST REMAIN YELLOW!
        final reconciledYellow = ExperimentalAiGuard.reconcileTriageSeverity(
          clinicalTier: ClinicalTriageTier.yellow,
          experimentalCameraTier: ClinicalTriageTier.green,
        );
        expect(reconciledYellow, equals(ClinicalTriageTier.yellow));
      });

      test('allows experimental AI to escalate severity from Green to Red or Yellow', () {
        // Clinical is GREEN, AI camera detects high risk -> Can escalate to RED for safety
        final escalated = ExperimentalAiGuard.reconcileTriageSeverity(
          clinicalTier: ClinicalTriageTier.green,
          experimentalCameraTier: ClinicalTriageTier.red,
        );
        expect(escalated, equals(ClinicalTriageTier.red));
      });

      test('contains CDSCO non-clearance regulatory disclaimer', () {
        expect(ExperimentalAiGuard.disclaimerText, contains('EXPERIMENTAL'));
        expect(ExperimentalAiGuard.disclaimerText, contains('CDSCO'));
        expect(ExperimentalAiGuard.disclaimerText, contains('NEVER be used to downgrade'));
      });
    });
  });
}
