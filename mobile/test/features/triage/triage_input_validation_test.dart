import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/features/triage/domain/triage_input_validation.dart';
import 'package:asha_platform/features/clinical_programs/nutrition/domain/who_growth_calculator.dart';

void main() {
  group('Triage measurement validation', () {
    test('accepts measurements inside the plausibility guardrails', () {
      final issues = TriageInputValidation.validate({
        'vitals.temp_c': 37.2,
        'vitals.respiratory_rate': 40,
        'vitals.systolic_bp': 120,
        'vitals.diastolic_bp': 80,
        'vitals.pulse_rate': 76,
      });

      expect(issues, isEmpty);
    });

    test('requires explicit confirmation for an implausible measurement', () {
      final issues = TriageInputValidation.validate({'vitals.temp_c': 52});

      expect(issues, hasLength(1));
      expect(issues.single.fieldKey, 'vitals.temp_c');
      expect(issues.single.confirmable, isTrue);
      expect(issues.single.message, contains('30–45'));
    });

    test('checks systolic and diastolic values together', () {
      final issues = TriageInputValidation.validate({
        'vitals.systolic_bp': 70,
        'vitals.diastolic_bp': 90,
      });

      expect(
        issues.map((issue) => issue.message),
        contains(
          'Check blood pressure: systolic must be higher than diastolic.',
        ),
      );
      expect(issues.any((issue) => !issue.confirmable), isTrue);
    });

    test('does not validate missing optional measurements', () {
      expect(
        TriageInputValidation.validate({
          'vitals.temp_c': null,
          'vitals.systolic_bp': null,
          'vitals.diastolic_bp': null,
        }),
        isEmpty,
      );
    });

    test('does not change triage decision thresholds', () {
      final rr = TriageInputValidation.boundsFor('vitals.respiratory_rate');

      // This layer only checks entry plausibility. IMCI age-specific fast
      // breathing thresholds remain in the existing rules engine.
      expect(rr?.min, 5);
      expect(rr?.max, 120);
    });

    test('computes the bundled WHO weight-for-age reference value offline', () {
      final boysAtBirth = WhoGrowthCalculator.calculateWaz(
        weightKg: 3.346,
        ageMonths: 0,
        sex: 'M',
      );
      final girlsAtBirth = WhoGrowthCalculator.calculateWaz(
        weightKg: 3.232,
        ageMonths: 0,
        sex: 'F',
      );

      expect(boysAtBirth, closeTo(0, 0.05));
      expect(girlsAtBirth, closeTo(0, 0.05));
    });
  });
}
