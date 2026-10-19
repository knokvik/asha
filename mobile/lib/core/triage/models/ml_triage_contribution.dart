import 'triage_flag.dart';

/// Machine learning contribution component for triage severity inference.
///
/// Acceptance Criteria:
/// Requirement 8.9: The ML component can only raise the severity relative to the
/// rule-based output and never lower it, and is displayed as a separately
/// labelled item showing specific input features and their relative weights.
class MLTriageContribution {
  final TriageFlag mlFlag;
  final Map<String, double> featureWeights;
  final double confidenceScore;

  const MLTriageContribution({
    required this.mlFlag,
    required this.featureWeights,
    required this.confidenceScore,
  });

  factory MLTriageContribution.fromJson(Map<String, dynamic> json) =>
      MLTriageContribution(
        mlFlag: TriageFlag.fromString(
          json['ml_flag'] as String? ?? json['mlFlag'] as String?,
        ),
        featureWeights: (json['feature_weights'] as Map? ?? json['featureWeights'] as Map? ?? {})
            .map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
        confidenceScore: (json['confidence_score'] as num? ??
                json['confidenceScore'] as num? ??
                0.0)
            .toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'ml_flag': mlFlag.label,
        'feature_weights': featureWeights,
        'confidence_score': confidenceScore,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MLTriageContribution &&
          runtimeType == other.runtimeType &&
          mlFlag == other.mlFlag &&
          confidenceScore == other.confidenceScore &&
          _mapEquals(featureWeights, other.featureWeights);

  @override
  int get hashCode => Object.hash(
        mlFlag,
        confidenceScore,
        Object.hashAll(featureWeights.entries.map((e) => Object.hash(e.key, e.value))),
      );

  static bool _mapEquals(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
