import 'package:core_model/core_model.dart';

class RuleSetParseException implements Exception {
  const RuleSetParseException(this.message);
  final String message;
  @override
  String toString() => 'RuleSetParseException: $message';
}

class RuleSet {
  RuleSet({
    required this.id,
    required this.version,
    required this.sourceNote,
    required this.clinicalSignoffStatus,
    required this.rules,
  });

  final String id;
  final String version;
  final String sourceNote;
  final String clinicalSignoffStatus;
  final List<RuleDefinition> rules;

  factory RuleSet.fromJson(JsonMap json) {
    final rawRules = json['rules'];
    if (json['ruleset_id'] is! String ||
        json['ruleset_version'] is! String ||
        rawRules is! List) {
      throw const RuleSetParseException(
        'ruleset_id, ruleset_version, and rules are required',
      );
    }
    final rules = rawRules
        .map(
          (raw) =>
              RuleDefinition.fromJson((raw as Map).cast<String, dynamic>()),
        )
        .toList(growable: false);
    final ids = <String>{};
    for (final rule in rules) {
      if (!ids.add(rule.id))
        throw RuleSetParseException('duplicate rule id: ${rule.id}');
      if (rule.severity == RuleSeverity.red &&
          rule.requires.isEmpty &&
          rule.composite == null) {
        throw RuleSetParseException(
          'RED rule ${rule.id} must declare requires or a composite',
        );
      }
    }
    return RuleSet(
      id: json['ruleset_id'] as String,
      version: json['ruleset_version'] as String,
      sourceNote: json['source_note'] as String? ?? '',
      clinicalSignoffStatus:
          ((json['clinical_signoff'] as Map?)?['status'] as String?) ??
          'PENDING',
      rules: rules,
    );
  }

  /// Every field that some RED-capable rule needs before it can be evaluated.
  ///
  /// §10.5 defines the mandatory question set as "the fields that are
  /// `requires` for at least one RED rule". Deriving it here rather than
  /// hard-coding a list keeps the UI and the ruleset from drifting apart: add a
  /// RED rule with a new input and the question set grows with it. If they do
  /// drift, the engine blocks on NEEDS_MORE_INFO forever and no band is ever
  /// produced, so this is a correctness property and not a convenience.
  ///
  /// `patient.*` paths are excluded: they are synthesised from the patient
  /// record rather than asked.
  List<String> get redRequiredFields {
    final fields = <String>{};
    for (final rule in rules) {
      if (rule.severity != RuleSeverity.red) continue;
      for (final field in rule.requires) {
        if (field.startsWith('patient.')) continue;
        fields.add(field);
      }
    }
    final ordered = fields.toList()..sort();
    return List.unmodifiable(ordered);
  }

  RuleDefinition? ruleById(String id) {
    for (final rule in rules) {
      if (rule.id == id) return rule;
    }
    return null;
  }
}

class RuleDefinition {
  RuleDefinition({
    required this.id,
    required this.category,
    required this.severity,
    required this.requires,
    required this.when,
    required this.reasonKey,
    required this.reasonText,
    required this.adviceKey,
    required this.evidenceFields,
    required this.sourceRef,
    this.composite,
  });

  final String id;
  final String category;
  final RuleSeverity severity;
  final List<String> requires;
  final ConditionNode when;
  final String reasonKey;
  final Map<String, String> reasonText;
  final String adviceKey;
  final List<String> evidenceFields;
  final String? sourceRef;
  final CompositeTrigger? composite;

  factory RuleDefinition.fromJson(JsonMap json) {
    if (json['id'] is! String ||
        json['category'] is! String ||
        json['severity'] is! String ||
        json['when'] is! Map) {
      throw const RuleSetParseException(
        'rule requires id, category, severity, and when',
      );
    }
    final rawReasonText =
        (json['reason_text'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return RuleDefinition(
      id: json['id'] as String,
      category: json['category'] as String,
      severity: RuleSeverityX.fromWire(json['severity']),
      requires: (json['requires'] as List<dynamic>? ?? const []).cast<String>(),
      when: ConditionNode.fromJson(
        (json['when'] as Map).cast<String, dynamic>(),
      ),
      reasonKey: json['reason_key'] as String? ?? 'reason.${json['id']}',
      reasonText: {
        for (final entry in rawReasonText.entries)
          entry.key: entry.value.toString(),
      },
      adviceKey:
          json['advice_key'] as String? ??
          'advice.${(json['severity'] as String).toLowerCase()}',
      evidenceFields: (json['evidence_fields'] as List<dynamic>? ?? const [])
          .cast<String>(),
      sourceRef: json['source_ref'] as String?,
      composite: CompositeTrigger.fromJson(json['composite']),
    );
  }
}

class CompositeTrigger {
  const CompositeTrigger({required this.type, required this.threshold});
  final String type;
  final int threshold;

  static CompositeTrigger? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return CompositeTrigger(
      type: raw['type'] as String,
      threshold: (raw['threshold'] as num?)?.toInt() ?? 0,
    );
  }
}

sealed class ConditionNode {
  const ConditionNode();

  factory ConditionNode.fromJson(JsonMap json) {
    if (json.containsKey('all'))
      return AllCondition(
        (json['all'] as List)
            .map(
              (item) =>
                  ConditionNode.fromJson((item as Map).cast<String, dynamic>()),
            )
            .toList(growable: false),
      );
    if (json.containsKey('any'))
      return AnyCondition(
        (json['any'] as List)
            .map(
              (item) =>
                  ConditionNode.fromJson((item as Map).cast<String, dynamic>()),
            )
            .toList(growable: false),
      );
    if (json.containsKey('not'))
      return NotCondition(
        ConditionNode.fromJson((json['not'] as Map).cast<String, dynamic>()),
      );
    if (json['field'] is String && json['op'] is String)
      return PredicateCondition.fromJson(json);
    throw const RuleSetParseException('invalid condition node');
  }
}

class AllCondition extends ConditionNode {
  const AllCondition(this.children);
  final List<ConditionNode> children;
}

class AnyCondition extends ConditionNode {
  const AnyCondition(this.children);
  final List<ConditionNode> children;
}

class NotCondition extends ConditionNode {
  const NotCondition(this.child);
  final ConditionNode child;
}

class PredicateCondition extends ConditionNode {
  const PredicateCondition({
    required this.field,
    required this.operator,
    this.value,
    this.values,
    this.thresholdTable,
    this.countFields,
    this.countConditions,
  });
  final String field;
  final String operator;
  final Object? value;
  final List<Object?>? values;
  final ThresholdTable? thresholdTable;
  final List<String>? countFields;
  final List<ConditionNode>? countConditions;

  factory PredicateCondition.fromJson(JsonMap json) => PredicateCondition(
    field: json['field'] as String,
    operator: json['op'] as String,
    value: json['value'],
    values: (json['values'] as List<dynamic>?)?.cast<Object?>(),
    thresholdTable: ThresholdTable.fromJson(json['threshold_table']),
    countFields: (json['fields'] as List<dynamic>?)?.cast<String>(),
    countConditions: (json['conditions'] as List<dynamic>?)
        ?.map(
          (item) =>
              ConditionNode.fromJson((item as Map).cast<String, dynamic>()),
        )
        .toList(growable: false),
  );
}

class ThresholdTable {
  const ThresholdTable({required this.keyField, required this.bands});
  final String keyField;
  final List<ThresholdBand> bands;

  static ThresholdTable? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final map = raw.cast<String, dynamic>();
    return ThresholdTable(
      keyField: map['key_field'] as String,
      bands: (map['bands'] as List)
          .map((item) {
            final band = (item as Map).cast<String, dynamic>();
            return ThresholdBand(
              min: (band['min'] as num).toInt(),
              max: (band['max'] as num).toInt(),
              value: band['value'],
            );
          })
          .toList(growable: false),
    );
  }
}

class ThresholdBand {
  const ThresholdBand({
    required this.min,
    required this.max,
    required this.value,
  });
  final int min;
  final int max;
  final Object? value;
}
