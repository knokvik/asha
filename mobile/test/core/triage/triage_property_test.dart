import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/core/triage/triage_engine.dart';

void main() {
  group('Triage Property-Based Tests (Properties 3, 4, 5)', () {
    late RuleSet nationalRules;
    final random = Random(42);

    setUp(() {
      nationalRules = RuleSet.defaultNational();
    });

    test('Property 3: Triage Engine Determinism across 200 random input evaluations', () {
      // For arbitrary (inputs, ruleVersion), assert evaluate(inputs) == evaluate(inputs) across iterations.
      for (var i = 0; i < 200; i++) {
        final ageInDays = random.nextInt(3000);
        final isPregnant = random.nextBool();
        final rr = random.nextInt(120);
        final temp = 34.0 + random.nextDouble() * 8.0; // 34.0 - 42.0
        final sbp = 70 + random.nextInt(150);
        final dbp = 40 + random.nextInt(100);

        final inputs = TriageInputs(
          ageInDays: ageInDays,
          isPregnant: isPregnant,
          values: {
            'respiratory_rate': rr,
            'temperature': double.parse(temp.toStringAsFixed(1)),
            'systolic_bp': sbp,
            'diastolic_bp': dbp,
            'chest_indrawing': random.nextBool(),
          },
        );

        final result1 = TriageEngine.evaluatePure(inputs, nationalRules);
        final result2 = TriageEngine.evaluatePure(inputs, nationalRules);

        expect(result1.flag, equals(result2.flag), reason: 'Iteration $i flag mismatch');
        expect(result1.ruleFlag, equals(result2.ruleFlag), reason: 'Iteration $i ruleFlag mismatch');
        expect(result1.id, equals(result2.id), reason: 'Iteration $i id mismatch');
        expect(result1.findings.length, equals(result2.findings.length));
        expect(result1.missingFields, equals(result2.missingFields));
        expect(result1.escalatedForMissingData, equals(result2.escalatedForMissingData));
        expect(result1, equals(result2));
      }
    });

    test('Property 4: Triage Severity Monotonicity (ML) across 200 random evaluations', () {
      // For arbitrary (rule_flag, ml_flag), assert final_flag.severity >= rule_flag.severity.
      final flags = TriageFlag.values;

      for (var i = 0; i < 200; i++) {
        final ageInDays = random.nextInt(100);
        final inputs = TriageInputs(
          ageInDays: ageInDays,
          values: {
            'respiratory_rate': 20 + random.nextInt(80),
            'temperature': 35.0 + random.nextDouble() * 5.0,
          },
        );

        final mlFlag = flags[random.nextInt(flags.length)];
        final mlContribution = MLTriageContribution(
          mlFlag: mlFlag,
          featureWeights: {'vital_metric': 0.75},
          confidenceScore: 0.85,
        );

        final result = TriageEngine.evaluatePure(
          inputs,
          nationalRules,
          mlContribution: mlContribution,
        );

        // Invariant: final_flag >= rule_flag
        expect(
          result.flag >= result.ruleFlag,
          isTrue,
          reason: 'Invariant violated: final (${result.flag}) < rule (${result.ruleFlag}) with ML ($mlFlag)',
        );

        // Invariant: final_flag >= ml_flag (since mlContribution is present, final flag is at least ml_flag or rule_flag escalated)
        expect(
          result.flag >= mlFlag,
          isTrue,
          reason: 'Invariant violated: final (${result.flag}) < ml ($mlFlag)',
        );
      }
    });

    test('Property 5: Missing-Input Escalation Monotonicity across 200 random evaluations', () {
      // For arbitrary inputs with absent fields:
      // 1. Adding a normal value never increases severity flag (relative to escalated incomplete flag).
      // 2. Adding an abnormal value never decreases severity flag.
      for (var i = 0; i < 200; i++) {
        final ageInDays = random.nextInt(50); // young infant 0-50 days
        // Incomplete inputs missing temperature (required for infant)
        // Normal respiratory rate is 30-50 for infant
        final incompleteNormalInputs = TriageInputs(
          ageInDays: ageInDays,
          values: const {
            'respiratory_rate': 42, // normal rate
          },
        );

        final incompleteResult = TriageEngine.evaluatePure(incompleteNormalInputs, nationalRules);
        expect(incompleteResult.missingFields, contains('temperature'));
        expect(incompleteResult.escalatedForMissingData, isTrue);

        // 1. Adding a NORMAL temperature (36.8 C is normal)
        final completeNormalInputs = incompleteNormalInputs.copyWith(
          values: {
            'respiratory_rate': 42,
            'temperature': 36.8, // normal
          },
        );

        final normalResult = TriageEngine.evaluatePure(completeNormalInputs, nationalRules);
        // Adding normal value never increases severity:
        // incomplete was escalated to YELLOW; normal complete should be GREEN <= YELLOW
        expect(
          normalResult.flag <= incompleteResult.flag,
          isTrue,
          reason: 'Adding normal value should never increase severity (${normalResult.flag} vs ${incompleteResult.flag})',
        );

        // 2. Adding an ABNORMAL value (e.g. severe fever 39.5 C or fast breathing)
        // never decreases severity relative to the incomplete assessment.
        final completeAbnormalInputs = incompleteNormalInputs.copyWith(
          values: {
            'respiratory_rate': 42,
            'temperature': 39.5, // High fever in infant -> RED
          },
        );

        final abnormalResult = TriageEngine.evaluatePure(completeAbnormalInputs, nationalRules);
        expect(
          abnormalResult.flag >= incompleteResult.flag,
          isTrue,
          reason: 'Adding abnormal value should never decrease severity (${abnormalResult.flag} vs ${incompleteResult.flag})',
        );
      }
    });
  });
}
