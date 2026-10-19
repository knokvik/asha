import 'triage_flag.dart';

/// Clinical finding produced when a triage rule condition evaluates to matched.
class TriageFinding {
  final String ruleId;
  final TriageFlag severity;
  final String findingText;
  final Map<String, dynamic> triggeringValues;
  final String action;
  final String? sourceCitation;

  const TriageFinding({
    required this.ruleId,
    required this.severity,
    required this.findingText,
    required this.triggeringValues,
    required this.action,
    this.sourceCitation,
  });

  factory TriageFinding.fromJson(Map<String, dynamic> json) => TriageFinding(
        ruleId: json['rule_id'] as String? ?? json['ruleId'] as String? ?? '',
        severity: TriageFlag.fromString(json['severity'] as String?),
        findingText: json['finding_text'] as String? ?? json['findingText'] as String? ?? '',
        triggeringValues: Map<String, dynamic>.from(
          json['triggering_values'] as Map? ?? json['triggeringValues'] as Map? ?? {},
        ),
        action: json['action'] as String? ?? '',
        sourceCitation: json['source_citation'] as String? ?? json['sourceCitation'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'rule_id': ruleId,
        'severity': severity.label,
        'finding_text': findingText,
        'triggering_values': triggeringValues,
        'action': action,
        if (sourceCitation != null) 'source_citation': sourceCitation,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriageFinding &&
          runtimeType == other.runtimeType &&
          ruleId == other.ruleId &&
          severity == other.severity &&
          findingText == other.findingText &&
          action == other.action &&
          sourceCitation == other.sourceCitation &&
          _mapEquals(triggeringValues, other.triggeringValues);

  @override
  int get hashCode => Object.hash(
        ruleId,
        severity,
        findingText,
        action,
        sourceCitation,
        Object.hashAll(triggeringValues.entries.map((e) => Object.hash(e.key, e.value))),
      );

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
