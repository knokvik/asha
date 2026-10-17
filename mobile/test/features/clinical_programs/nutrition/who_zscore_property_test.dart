import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/features/clinical_programs/nutrition/domain/who_growth_calculator.dart';
import 'package:asha_platform/features/clinical_programs/nutrition/domain/who_standards_data.dart';

void main() {
  group('Task 10.5: Property 8 - WHO Z-Score Monotonicity (Requirement 17.1)', () {
    // ── 1. LMS Box-Cox Pure Monotonicity ──────────────────────────────────────
    test('Property 8.1: Box-Cox transformation is strictly monotonic for any valid LMS', () {
      final random = math.Random(42);

      for (int trial = 0; trial < 200; trial++) {
        // Sample L from [-3.0, 3.0]
        final l = (random.nextDouble() * 6.0) - 3.0;
        // Sample M from [1.0, 30.0]
        final m = 1.0 + (random.nextDouble() * 29.0);
        // Sample S from [0.05, 0.25]
        final s = 0.05 + (random.nextDouble() * 0.20);

        // Sample x1 and x2 such that x2 > x1 > 0
        final x1 = 1.0 + (random.nextDouble() * 25.0);
        final delta = 0.01 + (random.nextDouble() * 5.0);
        final x2 = x1 + delta;

        final z1 = WhoGrowthCalculator.calculateZScore(measurement: x1, l: l, m: m, s: s);
        final z2 = WhoGrowthCalculator.calculateZScore(measurement: x2, l: l, m: m, s: s);

        expect(
          z2,
          greaterThanOrEqualTo(z1),
          reason: 'Failed monotonicity: z($x2) = $z2 should be >= z($x1) = $z1 with L=$l, M=$m, S=$s',
        );
      }
    });

    // ── 2. Weight-for-Age (WAZ) Monotonicity Invariant ────────────────────────
    test('Property 8.2: For any fixed age (0-60m) and sex (M/F), weight2 > weight1 => WAZ(weight2) > WAZ(weight1)', () {
      final random = math.Random(1337);
      final sexes = ['M', 'F'];

      // Test 250 randomized cases across the 0-60 month spectrum
      for (int trial = 0; trial < 250; trial++) {
        final sex = sexes[random.nextInt(2)];
        final ageMonths = random.nextDouble() * 60.0; // 0 to 60 months

        // Realistic child weight between 1.5 kg and 35.0 kg
        final w1 = 1.5 + (random.nextDouble() * 30.0);
        final delta = 0.05 + (random.nextDouble() * 4.0);
        final w2 = w1 + delta;

        final waz1 = WhoGrowthCalculator.calculateWaz(
          weightKg: w1,
          ageMonths: ageMonths,
          sex: sex,
        );
        final waz2 = WhoGrowthCalculator.calculateWaz(
          weightKg: w2,
          ageMonths: ageMonths,
          sex: sex,
        );

        expect(
          waz2,
          greaterThan(waz1),
          reason: 'WAZ monotonicity violated for sex $sex, age $ageMonths: WAZ($w2 kg) = $waz2, WAZ($w1 kg) = $waz1',
        );
      }
    });

    // ── 3. Weight-for-Height (WFHZ) Monotonicity Invariant ─────────────────────
    test('Property 8.3: For any fixed height (45-120cm) and sex (M/F), weight2 > weight1 => WFHZ(weight2) > WFHZ(weight1)', () {
      final random = math.Random(2025);
      final sexes = ['M', 'F'];

      // Test 250 randomized cases across 45cm to 120cm
      for (int trial = 0; trial < 250; trial++) {
        final sex = sexes[random.nextInt(2)];
        final heightCm = 45.0 + (random.nextDouble() * 75.0); // 45 to 120 cm

        final w1 = 1.5 + (random.nextDouble() * 32.0);
        final delta = 0.05 + (random.nextDouble() * 4.0);
        final w2 = w1 + delta;

        final wfhz1 = WhoGrowthCalculator.calculateWfhz(
          weightKg: w1,
          heightCm: heightCm,
          sex: sex,
        );
        final wfhz2 = WhoGrowthCalculator.calculateWfhz(
          weightKg: w2,
          heightCm: heightCm,
          sex: sex,
        );

        expect(
          wfhz2,
          greaterThan(wfhz1),
          reason: 'WFHZ monotonicity violated for sex $sex, height $heightCm: WFHZ($w2 kg) = $wfhz2, WFHZ($w1 kg) = $wfhz1',
        );
      }
    });

    // ── 4. Height-for-Age (HAZ) Monotonicity Invariant ─────────────────────────
    test('Property 8.4: For any fixed age (0-60m) and sex (M/F), height2 > height1 => HAZ(height2) > HAZ(height1)', () {
      final random = math.Random(999);
      final sexes = ['M', 'F'];

      for (int trial = 0; trial < 250; trial++) {
        final sex = sexes[random.nextInt(2)];
        final ageMonths = random.nextDouble() * 60.0;

        final h1 = 40.0 + (random.nextDouble() * 80.0);
        final delta = 0.1 + (random.nextDouble() * 5.0);
        final h2 = h1 + delta;

        final haz1 = WhoGrowthCalculator.calculateHaz(
          heightCm: h1,
          ageMonths: ageMonths,
          sex: sex,
        );
        final haz2 = WhoGrowthCalculator.calculateHaz(
          heightCm: h2,
          ageMonths: ageMonths,
          sex: sex,
        );

        expect(
          haz2,
          greaterThan(haz1),
          reason: 'HAZ monotonicity violated for sex $sex, age $ageMonths: HAZ($h2 cm) = $haz2, HAZ($h1 cm) = $haz1',
        );
      }
    });

    // ── 5. Standard Tables LMS Sanity Invariants ───────────────────────────────
    test('Standard tables satisfy WHO invariants (M > 0, S > 0, strictly ascending x values)', () {
      final tables = [
        WhoStandardsData.wazBoys,
        WhoStandardsData.wazGirls,
        WhoStandardsData.hazBoys,
        WhoStandardsData.hazGirls,
        WhoStandardsData.wfhzBoys,
        WhoStandardsData.wfhzGirls,
      ];

      for (final table in tables) {
        expect(table.isNotEmpty, isTrue);
        for (int i = 0; i < table.length; i++) {
          final pt = table[i];
          expect(pt.m, greaterThan(0.0), reason: 'Median M must be positive');
          expect(pt.s, greaterThan(0.0), reason: 'CV S must be positive');
          expect(pt.sd3neg, lessThan(pt.sd2neg));
          expect(pt.sd2neg, lessThan(pt.sd1neg));
          expect(pt.sd1neg, lessThan(pt.sd0));
          expect(pt.sd0, lessThan(pt.sd1pos));
          expect(pt.sd1pos, lessThan(pt.sd2pos));
          expect(pt.sd2pos, lessThan(pt.sd3pos));

          if (i > 0) {
            expect(pt.x, greaterThan(table[i - 1].x), reason: 'x values must be strictly ascending');
          }
        }
      }
    });
  });
}
