import 'ml_triage_contribution.dart';
import 'triage_finding.dart';
import 'triage_flag.dart';

/// Complete result of evaluating a clinical assessment through the triage engine.
class TriageResult {
  final String id;
  final String? encounterId;
  final TriageFlag flag;
  final TriageFlag ruleFlag;
  final String ruleVersionId;
  final List<TriageFinding> findings;
  final List<String> missingFields;
  final bool escalatedForMissingData;
  final MLTriageContribution? mlContribution;
  final List<String> inputErrors;
  final DateTime evaluatedAt;

  /// Prominent clinical decision support disclaimer.
  /// Requirement 8.7: Requires ASHA judgment; excludes "diagnosis" and "prescription".
  static const String disclaimer =
      'This is clinical decision support. Your judgment as an ASHA is the final decision.';

  const TriageResult({
    required this.id,
    this.encounterId,
    required this.flag,
    required this.ruleFlag,
    required this.ruleVersionId,
    required this.findings,
    this.missingFields = const [],
    this.escalatedForMissingData = false,
    this.mlContribution,
    this.inputErrors = const [],
    required this.evaluatedAt,
  });

  factory TriageResult.fromJson(Map<String, dynamic> json) => TriageResult(
        id: json['id'] as String? ?? '',
        encounterId: json['encounter_id'] as String? ?? json['encounterId'] as String?,
        flag: TriageFlag.fromString(json['flag'] as String?),
        ruleFlag: TriageFlag.fromString(
          json['rule_flag'] as String? ?? json['ruleFlag'] as String? ?? json['flag'] as String?,
        ),
        ruleVersionId: json['rule_version_id'] as String? ??
            json['ruleVersionId'] as String? ??
            '',
        findings: (json['findings'] as List<dynamic>? ?? [])
            .map((e) => TriageFinding.fromJson(e as Map<String, dynamic>))
            .toList(),
        missingFields: (json['missing_fields'] as List<dynamic>? ??
                json['missingFields'] as List<dynamic>? ??
                [])
            .map((e) => e.toString())
            .toList(),
        escalatedForMissingData: json['escalated_for_missing_data'] as bool? ??
            json['escalatedForMissingData'] as bool? ??
            false,
        mlContribution: json['ml_contribution'] != null || json['mlContribution'] != null
            ? MLTriageContribution.fromJson(
                (json['ml_contribution'] ?? json['mlContribution']) as Map<String, dynamic>,
              )
            : null,
        inputErrors: (json['input_errors'] as List<dynamic>? ??
                json['inputErrors'] as List<dynamic>? ??
                [])
            .map((e) => e.toString())
            .toList(),
        evaluatedAt: json['evaluated_at'] != null
            ? (json['evaluated_at'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['evaluated_at'] as int)
                : DateTime.parse(json['evaluated_at'] as String))
            : (json['evaluatedAt'] != null
                ? (json['evaluatedAt'] is int
                    ? DateTime.fromMillisecondsSinceEpoch(json['evaluatedAt'] as int)
                    : DateTime.parse(json['evaluatedAt'] as String))
                : DateTime.now()),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        if (encounterId != null) 'encounter_id': encounterId,
        'flag': flag.label,
        'rule_flag': ruleFlag.label,
        'rule_version_id': ruleVersionId,
        'findings': findings.map((f) => f.toJson()).toList(),
        'missing_fields': missingFields,
        'escalated_for_missing_data': escalatedForMissingData,
        if (mlContribution != null) 'ml_contribution': mlContribution!.toJson(),
        if (inputErrors.isNotEmpty) 'input_errors': inputErrors,
        'evaluated_at': evaluatedAt.toIso8601String(),
        'disclaimer': disclaimer,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriageResult &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          encounterId == other.encounterId &&
          flag == other.flag &&
          ruleFlag == other.ruleFlag &&
          ruleVersionId == other.ruleVersionId &&
          escalatedForMissingData == other.escalatedForMissingData &&
          mlContribution == other.mlContribution &&
          _listEquals(findings, other.findings) &&
          _stringListEquals(missingFields, other.missingFields) &&
          _stringListEquals(inputErrors, other.inputErrors);

  @override
  int get hashCode => Object.hash(
        id,
        encounterId,
        flag,
        ruleFlag,
        ruleVersionId,
        escalatedForMissingData,
        mlContribution,
        Object.hashAll(findings),
        Object.hashAll(missingFields),
        Object.hashAll(inputErrors),
      );

  static bool _listEquals(List<TriageFinding> a, List<TriageFinding> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _stringListEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
