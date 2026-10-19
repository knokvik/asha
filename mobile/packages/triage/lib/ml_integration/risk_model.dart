import 'dart:convert';
import 'dart:math' as math;

import 'package:imci_engine/imci_engine.dart';

import '../context/context_pack.dart';
import '../engine/hybrid.dart';

/// On-device score from the exported int8 linear layer or the LightGBM trees.
/// No native plugin and no network. The Flutter `tflite_flutter` hook in the
/// app can replace [score] with the same feature order.
class RiskModel {
  RiskModel({
    required this.kind,
    required this.featureNames,
    required this.redThreshold,
    this.coefficients = const [],
    this.intercepts = const [],
    this.weightScale = 1,
    this.isotonicX = const [],
    this.isotonicY = const [],
    this.classTrees = const [],
  });

  final String kind;
  final List<String> featureNames;
  final double redThreshold;
  final List<List<int>> coefficients;
  final List<double> intercepts;
  final double weightScale;
  final List<double> isotonicX;
  final List<double> isotonicY;

  /// One list of trees per class. Each tree is walked with `feature <= threshold`.
  final List<List<_TreeNode>> classTrees;

  bool get isReady => kind == 'linear' || kind == 'lightgbm';

  ModelScore score(AssessmentInput input, DistrictPrior? prior) {
    final started = DateTime.now().microsecondsSinceEpoch;
    final features = vector(input, prior);
    final logits = kind == 'lightgbm' ? _trees(features) : _linear(features);
    var probs = _softmax(logits);
    if (isotonicX.length >= 2 && isotonicY.length == isotonicX.length) {
      final calibratedRed = _isotonicOf(isotonicX, isotonicY, probs[2]).clamp(0.0, 1.0);
      final rest = probs[0] + probs[1];
      final remain = 1 - calibratedRed;
      if (rest <= 0) {
        probs = [remain / 2, remain / 2, calibratedRed];
      } else {
        probs = [probs[0] / rest * remain, probs[1] / rest * remain, calibratedRed];
      }
    }
    final elapsed = (DateTime.now().microsecondsSinceEpoch - started) / 1000.0;
    return ModelScore(
      pGreen: probs[0],
      pYellow: probs[1],
      pRed: probs[2],
      latencyMs: elapsed < 0 ? 0 : elapsed,
    );
  }

  List<double> vector(AssessmentInput input, DistrictPrior? prior) {
    final fields = input.toFields();
    return [
      for (final name in featureNames) _feature(name, fields, prior),
    ];
  }

  static RiskModel? fromJson(String raw) {
    final root = jsonDecode(raw);
    if (root is! Map) return null;
    final kind = root['kind'];
    if (kind == 'none' || kind is! String) return null;
    final names = root['feature_names'];
    if (names is! List) return null;
    final threshold = root['red_threshold'];
    final coefRaw = root['coefficients_int8'];
    final coefficients = <List<int>>[];
    if (coefRaw is List) {
      for (final row in coefRaw) {
        if (row is List) coefficients.add([for (final value in row) (value as num).toInt()]);
      }
    }
    final interceptRaw = root['intercepts'];
    final isotonic = root['isotonic_red'];
    return RiskModel(
      kind: kind,
      featureNames: [for (final name in names) name.toString()],
      redThreshold: threshold is num ? threshold.toDouble() : 0.65,
      coefficients: coefficients,
      intercepts: interceptRaw is List ? [for (final value in interceptRaw) (value as num).toDouble()] : const [],
      weightScale: (root['weight_scale'] as num?)?.toDouble() ?? 1,
      isotonicX: _numList(isotonic is Map ? isotonic['x'] : null),
      isotonicY: _numList(isotonic is Map ? isotonic['y'] : null),
      classTrees: _parseTrees(root['trees']),
    );
  }

  List<double> _linear(List<double> features) {
    if (coefficients.isEmpty) return const [0, 0, 0];
    return [
      for (var klass = 0; klass < coefficients.length; klass++)
        intercepts[klass] +
            _dot(coefficients[klass], features) * weightScale,
    ];
  }

  List<double> _trees(List<double> features) {
    if (classTrees.isEmpty) return const [0, 0, 0];
    return [
      for (final trees in classTrees) trees.fold<double>(0, (sum, tree) => sum + tree.eval(features)),
    ];
  }
}

double _feature(String name, Map<String, Object?> fields, DistrictPrior? prior) {
  switch (name) {
    case 'prior_anaemia_pct':
      return prior?.anaemiaPct ?? 0;
    case 'prior_stunting_pct':
      return prior?.stuntingPct ?? 0;
    case 'prior_immunization_pct':
      return prior?.immunizationPct ?? 0;
    case 'sex_female':
      final sex = fields['sex'];
      return sex is String && sex.toLowerCase().startsWith('f') ? 1 : 0;
    case 'rr_missing':
      return fields['vitals.respiratory_rate'] == null ? 1 : 0;
    case 'temp_missing':
      return fields['vitals.temp_c'] == null ? 1 : 0;
    case 'z_missing':
      return fields['vitals.weight_for_age_zscore'] == null ? 1 : 0;
  }
  final value = fields[name];
  if (value is bool) return value ? 1 : 0;
  if (value is num) return value.toDouble();
  return 0;
}

double _dot(List<int> weights, List<double> features) {
  var sum = 0.0;
  final count = weights.length < features.length ? weights.length : features.length;
  for (var i = 0; i < count; i++) {
    sum += weights[i] * features[i];
  }
  return sum;
}

List<double> _softmax(List<double> logits) {
  var peak = logits.first;
  for (final value in logits) {
    if (value > peak) peak = value;
  }
  final exps = [for (final value in logits) math.exp(value - peak)];
  final total = exps.fold<double>(0, (sum, value) => sum + value);
  return [for (final value in exps) value / total];
}

double _isotonicOf(List<double> xs, List<double> ys, double value) {
  if (value <= xs.first) return ys.first;
  if (value >= xs.last) return ys.last;
  for (var i = 1; i < xs.length; i++) {
    if (value > xs[i]) continue;
    final span = xs[i] - xs[i - 1];
    if (span == 0) return ys[i];
    final t = (value - xs[i - 1]) / span;
    return ys[i - 1] + t * (ys[i] - ys[i - 1]);
  }
  return ys.last;
}

List<double> _numList(Object? raw) {
  if (raw is! List) return const [];
  return [for (final value in raw) if (value is num) value.toDouble()];
}

class _TreeNode {
  _TreeNode.leaf(this.leaf) : feature = null, threshold = null, left = null, right = null;

  _TreeNode.split(this.feature, this.threshold, this.left, this.right) : leaf = null;

  final int? feature;
  final double? threshold;
  final double? leaf;
  final _TreeNode? left;
  final _TreeNode? right;

  double eval(List<double> features) {
    if (feature == null) return leaf ?? 0;
    final value = feature! < features.length ? features[feature!] : 0;
    final next = value <= threshold! ? left : right;
    return next?.eval(features) ?? 0;
  }
}

List<List<_TreeNode>> _parseTrees(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final klass in raw)
      if (klass is List)
        [
          for (final tree in klass)
            if (tree is Map) _node(tree.cast<String, Object?>()),
        ],
  ];
}

_TreeNode _node(Map<String, Object?> json) {
  if (json.containsKey('leaf')) {
    return _TreeNode.leaf((json['leaf'] as num).toDouble());
  }
  final left = json['left'];
  final right = json['right'];
  return _TreeNode.split(
    (json['feature'] as num).toInt(),
    (json['threshold'] as num).toDouble(),
    left is Map ? _node(left.cast<String, Object?>()) : null,
    right is Map ? _node(right.cast<String, Object?>()) : null,
  );
}
