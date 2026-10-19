import 'models.dart';

/// IMCI module order. Danger signs are always first and always run.
const imciModuleOrder = <String>[
  'danger_signs',
  'cough_breathing',
  'diarrhoea',
  'fever',
  'ear',
  'malnutrition_anaemia',
];

class ImciRule {
  const ImciRule({
    required this.ruleId,
    required this.module,
    required this.severity,
    required this.reasonText,
    required this.guidelineRef,
    required this.suspectedDisease,
    required this.conditions,
    required this.actions,
    this.followUpDays,
  });

  final String ruleId;
  final String module;
  final TriageFlag severity;
  final String reasonText;
  final String guidelineRef;
  final String suspectedDisease;
  final Map<String, Object?> conditions;
  final List<String> actions;
  final int? followUpDays;

  factory ImciRule.fromJson(Map<String, Object?> json, String module) {
    final severityName = json['severity'];
    final severity = TriageFlag.values.firstWhere(
      (flag) => flag.wireName == severityName,
      orElse: () => throw FormatException('Unknown severity on ${json['rule_id']}'),
    );
    final actions = json['actions'];
    final reason = _reasonText(json['reason_text']);
    return ImciRule(
      ruleId: json['rule_id']! as String,
      module: (json['module'] as String?) ?? module,
      severity: severity,
      reasonText: reason,
      guidelineRef: json['guideline_ref']! as String,
      suspectedDisease: (json['suspected_disease'] as String?) ?? '',
      conditions: (json['conditions'] as Map).cast<String, Object?>(),
      actions: actions is List ? actions.cast<String>() : const [],
      followUpDays: (json['follow_up_days'] as num?)?.toInt(),
    );
  }
}

String _reasonText(Object? value) {
  if (value is String && value.isNotEmpty) return value;
  if (value is Map) {
    final en = value['en'];
    if (en is String && en.isNotEmpty) return en;
  }
  throw FormatException('reason_text needs an English string');
}

class ImciCatalog {
  const ImciCatalog(this.rules);

  final List<ImciRule> rules;

  /// [modules] is file name or module name to the decoded JSON object.
  factory ImciCatalog.fromModuleMaps(Map<String, Map<String, Object?>> modules) {
    final byModule = <String, List<ImciRule>>{};
    for (final entry in modules.entries) {
      final root = entry.value;
      final module = (root['module'] as String?) ?? entry.key.replaceAll('.json', '');
      final rawRules = root['rules'];
      if (rawRules is! List) {
        throw FormatException('rules array missing in $module');
      }
      byModule[module] = [
        for (final raw in rawRules)
          ImciRule.fromJson((raw as Map).cast<String, Object?>(), module),
      ];
    }
    final ordered = <ImciRule>[];
    for (final module in imciModuleOrder) {
      ordered.addAll(byModule[module] ?? const []);
    }
    for (final entry in byModule.entries) {
      if (!imciModuleOrder.contains(entry.key)) ordered.addAll(entry.value);
    }
    return ImciCatalog(List.unmodifiable(ordered));
  }
}
