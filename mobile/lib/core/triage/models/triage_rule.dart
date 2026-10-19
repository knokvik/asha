import 'age_band.dart';
import 'condition.dart';
import 'triage_flag.dart';
import 'triage_inputs.dart';

/// Single clinical decision rule evaluated against triage inputs.
class TriageRule {
  final String ruleId;
  final AgeBandCode ageBand;
  final TriageFlag severity;
  final String sourceCitation;
  final Condition condition;
  final String findingTemplate;
  final String action;

  const TriageRule({
    required this.ruleId,
    required this.ageBand,
    required this.severity,
    required this.sourceCitation,
    required this.condition,
    required this.findingTemplate,
    required this.action,
  });

  /// Renders finding sentence substituting `{field}` tokens with measured inputs.
  /// Example: "Breathing rate {respiratory_rate}/min in infant {age_days} days — refer now"
  String renderFinding(TriageInputs inputs) {
    var rendered = findingTemplate;
    final tokenRegex = RegExp(r'\{([a-zA-Z0-9_]+)\}');
    final matches = tokenRegex.allMatches(findingTemplate);
    for (final match in matches) {
      final key = match.group(1);
      if (key != null) {
        final val = inputs.get(key);
        rendered = rendered.replaceAll('{$key}', val?.toString() ?? 'unknown');
      }
    }
    return rendered;
  }

  /// Extracts map of fields used in this rule and their actual values from [inputs].
  Map<String, dynamic> extractTriggeringValues(TriageInputs inputs) {
    final values = <String, dynamic>{};
    final refFields = condition.referencedFields();

    final tokenRegex = RegExp(r'\{([a-zA-Z0-9_]+)\}');
    for (final match in tokenRegex.allMatches(findingTemplate)) {
      final key = match.group(1);
      if (key != null) refFields.add(key);
    }

    for (final field in refFields) {
      final val = inputs.get(field);
      if (val != null) {
        values[field] = val;
      }
    }
    return values;
  }

  factory TriageRule.fromJson(Map<String, dynamic> json) => TriageRule(
        ruleId: json['rule_id'] as String? ?? json['ruleId'] as String? ?? '',
        ageBand: AgeBandCode.fromCode(
          json['age_band'] as String? ?? json['ageBand'] as String?,
        ),
        severity: TriageFlag.fromString(json['severity'] as String?),
        sourceCitation: json['source_citation'] as String? ??
            json['sourceCitation'] as String? ??
            '',
        condition: Condition.fromJson(json['condition'] as Map<String, dynamic>),
        findingTemplate: json['finding_template'] as String? ??
            json['findingTemplate'] as String? ??
            '',
        action: json['action'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'rule_id': ruleId,
        'age_band': ageBand.code,
        'severity': severity.label,
        'source_citation': sourceCitation,
        'condition': condition.toJson(),
        'finding_template': findingTemplate,
        'action': action,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriageRule &&
          runtimeType == other.runtimeType &&
          ruleId == other.ruleId &&
          ageBand == other.ageBand &&
          severity == other.severity &&
          sourceCitation == other.sourceCitation &&
          condition == other.condition &&
          findingTemplate == other.findingTemplate &&
          action == other.action;

  @override
  int get hashCode => Object.hash(
        ruleId,
        ageBand,
        severity,
        sourceCitation,
        condition,
        findingTemplate,
        action,
      );
}
