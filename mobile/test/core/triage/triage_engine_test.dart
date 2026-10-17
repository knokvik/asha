import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/core/triage/triage_engine.dart';

void main() {
  group('TriageEngine - Pure Dart Clinical Evaluator (Task 6.1, Req 8.1-8.4, 8.8)', () {
    late RuleSet nationalRules;

    setUp(() {
      nationalRules = RuleSet.defaultNational();
    });

    test('8.1 & 8.8: Instant pure evaluation with determinism for Infant fast breathing (RED)', () {
      final inputs = const TriageInputs(
        ageInDays: 30,
        values: {
          'respiratory_rate': 65,
          'temperature': 36.8,
        },
      );

      final result1 = TriageEngine.evaluatePure(inputs, nationalRules);
      final result2 = TriageEngine.evaluatePure(inputs, nationalRules);

      expect(result1.flag, equals(TriageFlag.red));
      expect(result1.ruleFlag, equals(TriageFlag.red));
      expect(result1.escalatedForMissingData, isFalse);
      expect(result1.missingFields, isEmpty);
      expect(result1.findings.length, equals(1));
      expect(result1.findings.first.ruleId, equals('INFANT_FAST_BREATHING'));
      expect(result1.findings.first.action, equals('REFER_IMMEDIATELY'));
      expect(
        result1.findings.first.findingText,
        contains('Breathing rate 65/min in infant 30 days — refer now'),
      );

      // Determinism check (Property 3)
      expect(result1.id, equals(result2.id));
      expect(result1.flag, equals(result2.flag));
      expect(result1.findings, equals(result2.findings));
      expect(result1, equals(result2));
    });

    test('8.3: Multiple rules firing simultaneously returns highest severity without suppressing findings', () {
      // 20-day-old infant with fast breathing (>=60 -> RED) AND severe hypothermia (<35.5 -> RED)
      final inputs = const TriageInputs(
        ageInDays: 20,
        values: {
          'respiratory_rate': 68,
          'temperature': 34.8,
        },
      );

      final result = TriageEngine.evaluatePure(inputs, nationalRules);

      expect(result.flag, equals(TriageFlag.red));
      expect(result.findings.length, equals(2));
      final ruleIds = result.findings.map((f) => f.ruleId).toSet();
      expect(ruleIds, contains('INFANT_FAST_BREATHING'));
      expect(ruleIds, contains('INFANT_HYPOTHERMIA_SEVERE'));
    });

    test('8.4: Missing required fields escalates severity by one level and lists missing fields', () {
      // Infant missing temperature (required fields: respiratory_rate, temperature)
      // Respiratory rate 45 is normal -> rule severity is GREEN.
      // Missing temperature escalates GREEN -> YELLOW.
      final incompleteInputs = const TriageInputs(
        ageInDays: 40,
        values: {
          'respiratory_rate': 45,
          // 'temperature' is omitted
        },
      );

      final result = TriageEngine.evaluatePure(incompleteInputs, nationalRules);

      expect(result.ruleFlag, equals(TriageFlag.green));
      expect(result.flag, equals(TriageFlag.yellow)); // Escalated from green to yellow
      expect(result.escalatedForMissingData, isTrue);
      expect(result.missingFields, contains('temperature'));

      // If already RED, cap at RED
      final incompleteRedInputs = const TriageInputs(
        ageInDays: 40,
        values: {
          'respiratory_rate': 70, // triggers RED
          // 'temperature' omitted
        },
      );

      final redResult = TriageEngine.evaluatePure(incompleteRedInputs, nationalRules);
      expect(redResult.ruleFlag, equals(TriageFlag.red));
      expect(redResult.flag, equals(TriageFlag.red)); // Capped at RED
      expect(redResult.escalatedForMissingData, isTrue);
      expect(redResult.missingFields, contains('temperature'));
    });

    test('Age-band routing routes to PREGNANT band when isPregnant is true', () {
      final pregnantInputs = const TriageInputs(
        isPregnant: true,
        ageInYears: 24,
        values: {
          'systolic_bp': 165,
          'diastolic_bp': 115,
          'gestational_weeks': 32,
        },
      );

      expect(pregnantInputs.resolveAgeBand(), equals(AgeBandCode.pregnant));

      final result = TriageEngine.evaluatePure(pregnantInputs, nationalRules);
      expect(result.flag, equals(TriageFlag.red));
      expect(result.findings.first.ruleId, equals('PREGNANT_SEVERE_HYPERTENSION'));
      expect(result.findings.first.findingText, contains('Severe hypertension'));
    });

    test('Age-band routing for child 2m-5y and adult hypertension', () {
      // Child 2m-5y
      final childInputs = const TriageInputs(
        ageInDays: 200, // ~6.5 months
        values: {
          'respiratory_rate': 55, // fast breathing (>50 for child under 1 year)
          'temperature': 37.0,
        },
      );
      expect(childInputs.resolveAgeBand(), equals(AgeBandCode.child2m5y));
      final childResult = TriageEngine.evaluatePure(childInputs, nationalRules);
      expect(childResult.flag, equals(TriageFlag.yellow));
      expect(childResult.findings.first.ruleId, equals('CHILD_FAST_BREATHING_INFANT'));

      // Adult moderate hypertension (SBP 145 / DBP 92) -> YELLOW
      final adultInputs = const TriageInputs(
        ageInYears: 45,
        values: {
          'systolic_bp': 145,
          'diastolic_bp': 92,
          'pulse_rate': 78,
        },
      );
      expect(adultInputs.resolveAgeBand(), equals(AgeBandCode.adult));
      final adultResult = TriageEngine.evaluatePure(adultInputs, nationalRules);
      expect(adultResult.flag, equals(TriageFlag.yellow));
      expect(adultResult.findings.first.ruleId, equals('ADULT_HYPERTENSION_STAGE1'));
    });

    test('Requirement 8.9: ML contribution can only raise severity and never lower it', () {
      final normalAdultInputs = const TriageInputs(
        ageInYears: 30,
        values: {
          'systolic_bp': 120,
          'diastolic_bp': 80,
          'pulse_rate': 72,
        },
      );

      // Rule flag alone is GREEN
      final baseResult = TriageEngine.evaluatePure(normalAdultInputs, nationalRules);
      expect(baseResult.flag, equals(TriageFlag.green));

      // ML suggests RED -> final flag raises to RED
      const mlRed = MLTriageContribution(
        mlFlag: TriageFlag.red,
        featureWeights: {'systolic_bp': 0.1, 'pulse_rate': 0.8},
        confidenceScore: 0.94,
      );

      final raisedResult = TriageEngine.evaluatePure(
        normalAdultInputs,
        nationalRules,
        mlContribution: mlRed,
      );
      expect(raisedResult.ruleFlag, equals(TriageFlag.green));
      expect(raisedResult.flag, equals(TriageFlag.red));
      expect(raisedResult.mlContribution, equals(mlRed));

      // ML suggests GREEN for a RED case -> final flag stays RED (cannot lower)
      final hypertensiveInputs = const TriageInputs(
        ageInYears: 50,
        values: {
          'systolic_bp': 190,
          'diastolic_bp': 125,
          'pulse_rate': 85,
        },
      );
      const mlGreen = MLTriageContribution(
        mlFlag: TriageFlag.green,
        featureWeights: {'systolic_bp': 0.9},
        confidenceScore: 0.80,
      );

      final protectedResult = TriageEngine.evaluatePure(
        hypertensiveInputs,
        nationalRules,
        mlContribution: mlGreen,
      );
      expect(protectedResult.ruleFlag, equals(TriageFlag.red));
      expect(protectedResult.flag, equals(TriageFlag.red)); // Retained RED!
    });

    test('Conservative handling of malformed and out-of-range inputs without crashing', () {
      final malformedInputs = const TriageInputs(
        ageInDays: 30,
        values: {
          'respiratory_rate': 'invalid_string',
          'temperature': 36.8,
        },
      );

      final result = TriageEngine.evaluatePure(malformedInputs, nationalRules);
      expect(result.inputErrors, isNotEmpty);
      expect(result.inputErrors.first, contains('Malformed non-numeric value for respiratory_rate'));
      // Conservative flag is at least YELLOW
      expect(result.flag >= TriageFlag.yellow, isTrue);

      final outOfRangeInputs = const TriageInputs(
        ageInYears: 25,
        values: {
          'systolic_bp': 500, // Non-physiological > 300
          'diastolic_bp': 80,
          'pulse_rate': 72,
        },
      );

      final rangeResult = TriageEngine.evaluatePure(outOfRangeInputs, nationalRules);
      expect(rangeResult.inputErrors, isNotEmpty);
      expect(rangeResult.inputErrors.first, contains('Out-of-range physiological value for systolic_bp'));
      expect(rangeResult.flag >= TriageFlag.yellow, isTrue);
    });

    test('All condition operators evaluate correctly', () {
      const inputs = TriageInputs(
        values: {
          'num_val': 50,
          'str_val': 'fever',
          'bool_val': true,
          'null_field': null,
        },
      );

      // gt
      expect(
        const Condition(op: ConditionOp.gt, field: 'num_val', value: 40).evaluate(inputs),
        equals(ConditionResult.matched),
      );
      expect(
        const Condition(op: ConditionOp.gt, field: 'num_val', value: 60).evaluate(inputs),
        equals(ConditionResult.unmatched),
      );

      // lt
      expect(
        const Condition(op: ConditionOp.lt, field: 'num_val', value: 60).evaluate(inputs),
        equals(ConditionResult.matched),
      );

      // gte
      expect(
        const Condition(op: ConditionOp.gte, field: 'num_val', value: 50).evaluate(inputs),
        equals(ConditionResult.matched),
      );

      // lte
      expect(
        const Condition(op: ConditionOp.lte, field: 'num_val', value: 50).evaluate(inputs),
        equals(ConditionResult.matched),
      );

      // eq & neq
      expect(
        const Condition(op: ConditionOp.eq, field: 'str_val', value: 'FEVER').evaluate(inputs),
        equals(ConditionResult.matched),
      );
      expect(
        const Condition(op: ConditionOp.neq, field: 'str_val', value: 'cough').evaluate(inputs),
        equals(ConditionResult.matched),
      );

      // in & not_in
      expect(
        const Condition(
          op: ConditionOp.isIn,
          field: 'str_val',
          values: ['cough', 'fever', 'chills'],
        ).evaluate(inputs),
        equals(ConditionResult.matched),
      );
      expect(
        const Condition(
          op: ConditionOp.notIn,
          field: 'str_val',
          values: ['vomiting', 'diarrhoea'],
        ).evaluate(inputs),
        equals(ConditionResult.matched),
      );

      // present & absent
      expect(
        const Condition(op: ConditionOp.present, field: 'str_val').evaluate(inputs),
        equals(ConditionResult.matched),
      );
      expect(
        const Condition(op: ConditionOp.absent, field: 'missing_field').evaluate(inputs),
        equals(ConditionResult.matched),
      );

      // and, or, not
      const andCond = Condition(
        op: ConditionOp.and,
        children: [
          Condition(op: ConditionOp.gte, field: 'num_val', value: 50),
          Condition(op: ConditionOp.eq, field: 'bool_val', value: true),
        ],
      );
      expect(andCond.evaluate(inputs), equals(ConditionResult.matched));

      const orCond = Condition(
        op: ConditionOp.or,
        children: [
          Condition(op: ConditionOp.eq, field: 'str_val', value: 'cough'),
          Condition(op: ConditionOp.eq, field: 'str_val', value: 'fever'),
        ],
      );
      expect(orCond.evaluate(inputs), equals(ConditionResult.matched));

      const notCond = Condition(
        op: ConditionOp.not,
        children: [
          Condition(op: ConditionOp.eq, field: 'str_val', value: 'cough'),
        ],
      );
      expect(notCond.evaluate(inputs), equals(ConditionResult.matched));
    });

    test('TriageOverride validates reason length (10-500 chars)', () {
      expect(
        () => TriageOverride(
          encounterId: 'enc-1',
          originalFlag: TriageFlag.yellow,
          overrideFlag: TriageFlag.red,
          reason: 'Too short', // 9 chars
          overridingUserId: 'user-1',
        ),
        throwsArgumentError,
      );

      final validOverride = TriageOverride(
        encounterId: 'enc-1',
        originalFlag: TriageFlag.yellow,
        overrideFlag: TriageFlag.red,
        reason: 'Patient exhibits signs of severe distress not in rule table',
        overridingUserId: 'user-1',
      );
      expect(validOverride.reason.length, greaterThanOrEqualTo(10));
      expect(validOverride.overrideFlag, equals(TriageFlag.red));
    });
  });
}
