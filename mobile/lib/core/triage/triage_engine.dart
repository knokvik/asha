import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'models/models.dart';

/// Pure Dart deterministic clinical triage rule evaluator.
///
/// Implements Requirements 8.1, 8.2, 8.3, 8.4, 8.8:
/// - Pure function with no I/O, no network calls, no side effects.
/// - Evaluates all rules without short-circuiting to collect all findings.
/// - Highest severity flag: RED > YELLOW > GREEN.
/// - Escalates severity by one level (cap at RED) when required inputs are missing.
/// - Enforces ML severity monotonicity: ML can only raise, never lower.
/// - Produces conservative flag with explicit input error on malformed/non-physiological inputs.
/// - Deterministic: same inputs + same rule set always produces the identical output.
class TriageEngine {
  final RuleSet ruleSet;

  const TriageEngine({RuleSet? ruleSet})
      : ruleSet = ruleSet ?? const RuleSet(
          id: 'default',
          versionString: '0.0.0',
          publishedAt: 0,
          clinicalLeadId: 'system',
          approvalSignature: 'none',
          bundleHash: '',
          ageBands: [],
          rules: [],
        );

  /// Evaluates clinical [inputs] against the engine's [ruleSet] (or [overrideRuleSet]).
  TriageResult evaluate(
    TriageInputs inputs, [
    RuleSet? overrideRuleSet,
    MLTriageContribution? mlContribution,
  ]) {
    final activeRuleSet = overrideRuleSet ?? ruleSet;
    return evaluatePure(
      inputs,
      activeRuleSet,
      mlContribution: mlContribution,
    );
  }

  /// Pure functional entry point: `evaluate(TriageInputs inputs, RuleSet ruleSet) → TriageResult`.
  static TriageResult evaluatePure(
    TriageInputs inputs,
    RuleSet ruleSet, {
    MLTriageContribution? mlContribution,
    String? encounterId,
    DateTime? evaluatedAt,
    String? explicitId,
  }) {
    final ageBandCode = inputs.resolveAgeBand();
    final ageBandConfig = ruleSet.ageBandConfig(ageBandCode) ?? AgeBand.defaultFor(ageBandCode);

    final missingFields = <String>[];
    for (final field in ageBandConfig.requiredFields) {
      if (!inputs.hasField(field)) {
        missingFields.add(field);
      }
    }

    final findings = <TriageFinding>[];
    final inputErrors = <String>[];
    TriageFlag ruleHighestFlag = TriageFlag.green;

    // Validate physiological bounds for entered numeric values
    _validatePhysiologicalRanges(inputs, inputErrors);

    // Evaluate all rules for the age band without short-circuiting
    final applicableRules = ruleSet.rulesForAgeBand(ageBandCode);
    for (final rule in applicableRules) {
      final conditionResult = rule.condition.evaluate(inputs);

      if (conditionResult == ConditionResult.matched) {
        final findingText = rule.renderFinding(inputs);
        final triggeringValues = rule.extractTriggeringValues(inputs);

        findings.add(
          TriageFinding(
            ruleId: rule.ruleId,
            severity: rule.severity,
            findingText: findingText,
            triggeringValues: triggeringValues,
            action: rule.action,
            sourceCitation: rule.sourceCitation,
          ),
        );

        if (rule.severity > ruleHighestFlag) {
          ruleHighestFlag = rule.severity;
        }
      } else if (conditionResult == ConditionResult.error) {
        inputErrors.add(
          'Evaluation error in rule ${rule.ruleId} for fields: ${rule.condition.referencedFields().join(', ')}',
        );
      }
    }

    // Handle malformed or out-of-range physiological inputs conservatively
    // Requirement 8: Out-of-physiological-range inputs SHALL produce a conservative flag
    // with an explicit "input error" annotation rather than a crash or silent normal result.
    if (inputErrors.isNotEmpty && ruleHighestFlag == TriageFlag.green) {
      ruleHighestFlag = TriageFlag.yellow;
    }

    // Missing-input handling (Requirement 8.4):
    // Escalate severity by one level (cap at RED), list each missing item explicitly.
    final bool escalatedForMissingData = missingFields.isNotEmpty;
    TriageFlag finalFlag = ruleHighestFlag;
    if (escalatedForMissingData) {
      finalFlag = ruleHighestFlag.escalate();
    }

    // ML contribution hook (Requirement 8.9):
    // ML component can only raise severity relative to rule output, never lower it.
    if (mlContribution != null) {
      if (mlContribution.mlFlag > finalFlag) {
        finalFlag = mlContribution.mlFlag;
      }
    }

    // Deterministic timestamp & result ID
    final timestamp = evaluatedAt ?? DateTime.fromMillisecondsSinceEpoch(1710000000000);
    final resultId = explicitId ?? _computeDeterministicId(inputs, ruleSet, timestamp);

    return TriageResult(
      id: resultId,
      encounterId: encounterId ?? inputs.encounterId,
      flag: finalFlag,
      ruleFlag: ruleHighestFlag,
      ruleVersionId: ruleSet.versionString.isNotEmpty ? ruleSet.versionString : ruleSet.id,
      findings: findings,
      missingFields: missingFields,
      escalatedForMissingData: escalatedForMissingData,
      mlContribution: mlContribution,
      inputErrors: inputErrors,
      evaluatedAt: timestamp,
    );
  }

  /// Validates standard physiological limits on clinical vitals.
  static void _validatePhysiologicalRanges(
    TriageInputs inputs,
    List<String> inputErrors,
  ) {
    void checkRange(String field, num min, num max) {
      final raw = inputs.get(field);
      if (raw == null) return;
      final val = inputs.getNumeric(field);
      if (val == null) {
        inputErrors.add('Malformed non-numeric value for $field: "$raw"');
        return;
      }
      if (val < min || val > max) {
        inputErrors.add(
          'Out-of-range physiological value for $field: $val (expected $min - $max)',
        );
      }
    }

    checkRange('respiratory_rate', 0, 200);
    checkRange('pulse_rate', 0, 300);
    checkRange('temperature', 25.0, 45.0);
    checkRange('systolic_bp', 30, 300);
    checkRange('diastolic_bp', 20, 200);
    checkRange('blood_glucose', 10, 1000);
    checkRange('oxygen_saturation', 0, 100);
    checkRange('weight_kg', 0.2, 500);
    checkRange('haemoglobin', 1, 30);
  }

  static String _computeDeterministicId(
    TriageInputs inputs,
    RuleSet ruleSet,
    DateTime timestamp,
  ) {
    final payload = '${ruleSet.id}:${ruleSet.versionString}:${inputs.ageInDays}:'
        '${inputs.values}:${inputs.explicitAgeBand?.code}';
    final digest = sha256.convert(utf8.encode(payload)).toString();
    return 'trg_${digest.substring(0, 16)}';
  }
}
