import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/triage/models/models.dart';

void main() {
  group('Rule Set Serialization Round-Trip (Property 18, Requirement 9.1)', () {
    test('Round-trip serialization preserves all condition trees, operators, thresholds, and citations', () {
      final originalRuleSet = RuleSet.defaultNational();

      // Serialise to JSON string
      final jsonMap = originalRuleSet.toJson();
      final jsonString = jsonEncode(jsonMap);

      // Deserialise from JSON string
      final decodedMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final restoredRuleSet = RuleSet.fromJson(decodedMap);

      expect(restoredRuleSet.id, equals(originalRuleSet.id));
      expect(restoredRuleSet.versionString, equals(originalRuleSet.versionString));
      expect(restoredRuleSet.publishedAt, equals(originalRuleSet.publishedAt));
      expect(restoredRuleSet.clinicalLeadId, equals(originalRuleSet.clinicalLeadId));
      expect(restoredRuleSet.approvalSignature, equals(originalRuleSet.approvalSignature));
      expect(restoredRuleSet.bundleHash, equals(originalRuleSet.bundleHash));

      expect(restoredRuleSet.ageBands.length, equals(originalRuleSet.ageBands.length));
      for (var i = 0; i < originalRuleSet.ageBands.length; i++) {
        expect(restoredRuleSet.ageBands[i], equals(originalRuleSet.ageBands[i]));
      }

      expect(restoredRuleSet.rules.length, equals(originalRuleSet.rules.length));
      for (var i = 0; i < originalRuleSet.rules.length; i++) {
        final originalRule = originalRuleSet.rules[i];
        final restoredRule = restoredRuleSet.rules[i];

        expect(restoredRule.ruleId, equals(originalRule.ruleId));
        expect(restoredRule.ageBand, equals(originalRule.ageBand));
        expect(restoredRule.severity, equals(originalRule.severity));
        expect(restoredRule.sourceCitation, equals(originalRule.sourceCitation));
        expect(restoredRule.findingTemplate, equals(originalRule.findingTemplate));
        expect(restoredRule.action, equals(originalRule.action));
        expect(restoredRule.condition, equals(originalRule.condition));
        expect(restoredRule, equals(originalRule));
      }

      expect(restoredRuleSet.testSuite.length, equals(originalRuleSet.testSuite.length));
      for (var i = 0; i < originalRuleSet.testSuite.length; i++) {
        expect(restoredRuleSet.testSuite[i], equals(originalRuleSet.testSuite[i]));
      }

      // Exact equality check
      expect(restoredRuleSet, equals(originalRuleSet));
    });

    test('Complex nested condition tree round-trip serialization', () {
      const complexCondition = Condition(
        op: ConditionOp.and,
        children: [
          Condition(
            op: ConditionOp.or,
            children: [
              Condition(op: ConditionOp.gt, field: 'systolic_bp', value: 160),
              Condition(op: ConditionOp.gte, field: 'diastolic_bp', value: 110),
            ],
          ),
          Condition(
            op: ConditionOp.not,
            children: [
              Condition(op: ConditionOp.eq, field: 'treatment_active', value: true),
            ],
          ),
          Condition(
            op: ConditionOp.isIn,
            field: 'symptoms',
            values: ['headache', 'visual_blurring', 'epigastric_pain'],
          ),
          Condition(op: ConditionOp.present, field: 'proteinuria'),
        ],
      );

      final rule = const TriageRule(
        ruleId: 'COMPLEX_ECLAMPSIA_SCREEN',
        ageBand: AgeBandCode.pregnant,
        severity: TriageFlag.red,
        sourceCitation: 'MoHFW Maternal Health Clinical Protocols 2021, p.45',
        condition: complexCondition,
        findingTemplate: 'Hypertensive emergency in pregnancy with danger signs ({symptoms})',
        action: 'EMERGENCY_OBSTETRIC_REFERRAL',
      );

      final customRuleSet = RuleSet(
        id: 'custom-eclampsia-v1',
        versionString: '1.2.0',
        publishedAt: 1715000000000,
        clinicalLeadId: 'clinician_lead_test',
        approvalSignature: 'SIG_CUSTOM_ECLAMPSIA_HASH',
        bundleHash: 'dummy_sha256_hash',
        ageBands: [AgeBand.defaultFor(AgeBandCode.pregnant)],
        rules: [rule],
        testSuite: const [
          TestCase(
            testId: 'TC_COMPLEX_01',
            inputs: {
              'systolic_bp': 170,
              'treatment_active': false,
              'symptoms': 'headache',
              'proteinuria': '2+',
            },
            expectedFlag: TriageFlag.red,
            description: 'Severe pre-eclampsia triage red',
          ),
        ],
      );

      final json = customRuleSet.toJson();
      final roundTripped = RuleSet.fromJson(json);

      expect(roundTripped, equals(customRuleSet));
      expect(roundTripped.rules.first.condition, equals(complexCondition));
    });
  });
}
