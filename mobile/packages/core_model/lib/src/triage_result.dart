import 'sourced_value.dart';

enum TriageBand { red, yellow, green, needsMoreInfo, outOfScope }

extension TriageBandX on TriageBand {
  String get wireName => switch (this) {
    TriageBand.red => 'RED',
    TriageBand.yellow => 'YELLOW',
    TriageBand.green => 'GREEN',
    TriageBand.needsMoreInfo => 'NEEDS_MORE_INFO',
    TriageBand.outOfScope => 'OUT_OF_SCOPE',
  };

  int get rank => switch (this) {
    TriageBand.red => 3,
    TriageBand.yellow => 2,
    TriageBand.green => 1,
    TriageBand.needsMoreInfo => 0,
    TriageBand.outOfScope => 4,
  };

  /// A band that represents a completed clinical decision. NEEDS_MORE_INFO and
  /// OUT_OF_SCOPE are routing states, not decisions (§6.3).
  bool get isDecision => this == TriageBand.red || this == TriageBand.yellow || this == TriageBand.green;

  static TriageBand fromWire(Object? value) =>
      TriageBand.values.firstWhere((band) => band.wireName == value, orElse: () => TriageBand.needsMoreInfo);
}

enum RuleSeverity { red, yellow, green }

extension RuleSeverityX on RuleSeverity {
  String get wireName => name.toUpperCase();
  int get rank => switch (this) { RuleSeverity.red => 3, RuleSeverity.yellow => 2, RuleSeverity.green => 1 };
  static RuleSeverity fromWire(Object? value) =>
      RuleSeverity.values.firstWhere((item) => item.wireName == value, orElse: () => RuleSeverity.green);
}

class FiredRule {
  const FiredRule({
    required this.ruleId,
    required this.severity,
    required this.category,
    required this.reasonKey,
    required this.reasonText,
    required this.evidence,
    this.sourceRef,
  });

  final String ruleId;
  final RuleSeverity severity;
  final String category;
  final String reasonKey;
  final String reasonText;
  final Map<String, Object?> evidence;
  final String? sourceRef;

  JsonMap toJson() => {
    'rule_id': ruleId,
    'severity': severity.wireName,
    'category': category,
    'reason_key': reasonKey,
    'reason_text': reasonText,
    'evidence': evidence,
    'source_ref': sourceRef,
  };

  factory FiredRule.fromJson(JsonMap json) => FiredRule(
    ruleId: json['rule_id'] as String,
    severity: RuleSeverityX.fromWire(json['severity']),
    category: json['category'] as String? ?? 'UNKNOWN',
    reasonKey: json['reason_key'] as String? ?? '',
    reasonText: json['reason_text'] as String? ?? '',
    evidence: (json['evidence'] as Map?)?.cast<String, Object?>() ?? const {},
    sourceRef: json['source_ref'] as String?,
  );
}

class ClinicalTriageResult {
  const ClinicalTriageResult({
    required this.band,
    required this.firedRules,
    required this.blockingQuestions,
    required this.flooredBy,
    required this.escalatedByWorker,
    required this.adviceKey,
    required this.rulesetVersion,
    required this.engineVersion,
  });

  final TriageBand band;
  final List<FiredRule> firedRules;
  final List<String> blockingQuestions;
  final List<String> flooredBy;
  final bool escalatedByWorker;
  final String adviceKey;
  final String rulesetVersion;
  final String engineVersion;

  /// SI-2. A band without a complete explanation is an engine error.
  bool get hasExplanation => firedRules.isNotEmpty && firedRules.every((rule) => rule.reasonText.trim().isNotEmpty);

  String get reason => firedRules.map((rule) => rule.reasonText).join(' ');

  List<FiredRule> get redRules => firedRules.where((rule) => rule.severity == RuleSeverity.red).toList(growable: false);

  JsonMap toJson() => {
    'band': band.wireName,
    'fired_rules': firedRules.map((rule) => rule.toJson()).toList(growable: false),
    'blocking_questions': blockingQuestions,
    'floored_by': flooredBy,
    'escalated_by_worker': escalatedByWorker,
    'advice_key': adviceKey,
    'ruleset_version': rulesetVersion,
    'engine_version': engineVersion,
  };

  factory ClinicalTriageResult.fromJson(JsonMap json) => ClinicalTriageResult(
    band: TriageBandX.fromWire(json['band']),
    firedRules: ((json['fired_rules'] as List?) ?? const [])
        .map((raw) => FiredRule.fromJson((raw as Map).cast<String, dynamic>()))
        .toList(growable: false),
    blockingQuestions: ((json['blocking_questions'] as List?) ?? const []).cast<String>(),
    flooredBy: ((json['floored_by'] as List?) ?? const []).cast<String>(),
    escalatedByWorker: json['escalated_by_worker'] == true,
    adviceKey: json['advice_key'] as String? ?? '',
    rulesetVersion: json['ruleset_version'] as String? ?? 'unknown',
    engineVersion: json['engine_version'] as String? ?? 'unknown',
  );
}
