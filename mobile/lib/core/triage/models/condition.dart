import 'triage_inputs.dart';

/// Condition evaluation operators supported by the triage rule engine.
enum ConditionOp {
  and('and'),
  or('or'),
  not('not'),
  gt('gt'),
  lt('lt'),
  gte('gte'),
  lte('lte'),
  eq('eq'),
  neq('neq'),
  isIn('in'),
  notIn('not_in'),
  present('present'),
  absent('absent');

  final String op;
  const ConditionOp(this.op);

  static ConditionOp fromString(String raw) {
    final lower = raw.trim().toLowerCase();
    for (final o in values) {
      if (o.op == lower || o.name == lower) return o;
    }
    throw ArgumentError('Unsupported condition operator: $raw');
  }
}

/// Outcome of evaluating a [Condition] against [TriageInputs].
enum ConditionResult {
  matched,
  unmatched,
  error;

  bool get isMatched => this == ConditionResult.matched;
}

/// An AST node in the triage condition decision tree.
class Condition {
  final ConditionOp op;
  final String? field;
  final dynamic value;
  final List<dynamic>? values;
  final List<Condition> children;

  const Condition({
    required this.op,
    this.field,
    this.value,
    this.values,
    this.children = const [],
  });

  /// Evaluates this condition tree against [inputs].
  ConditionResult evaluate(TriageInputs inputs) {
    switch (op) {
      case ConditionOp.and:
        if (children.isEmpty) return ConditionResult.matched;
        bool hasError = false;
        for (final child in children) {
          final res = child.evaluate(inputs);
          if (res == ConditionResult.error) hasError = true;
          if (res == ConditionResult.unmatched) return ConditionResult.unmatched;
        }
        return hasError ? ConditionResult.error : ConditionResult.matched;

      case ConditionOp.or:
        if (children.isEmpty) return ConditionResult.unmatched;
        bool hasError = false;
        for (final child in children) {
          final res = child.evaluate(inputs);
          if (res == ConditionResult.matched) return ConditionResult.matched;
          if (res == ConditionResult.error) hasError = true;
        }
        return hasError ? ConditionResult.error : ConditionResult.unmatched;

      case ConditionOp.not:
        if (children.isEmpty) return ConditionResult.error;
        final res = children.first.evaluate(inputs);
        switch (res) {
          case ConditionResult.matched:
            return ConditionResult.unmatched;
          case ConditionResult.unmatched:
            return ConditionResult.matched;
          case ConditionResult.error:
            return ConditionResult.error;
        }

      case ConditionOp.present:
        if (field == null) return ConditionResult.error;
        return inputs.hasField(field!)
            ? ConditionResult.matched
            : ConditionResult.unmatched;

      case ConditionOp.absent:
        if (field == null) return ConditionResult.error;
        return !inputs.hasField(field!)
            ? ConditionResult.matched
            : ConditionResult.unmatched;

      case ConditionOp.gt:
      case ConditionOp.lt:
      case ConditionOp.gte:
      case ConditionOp.lte:
        if (field == null) return ConditionResult.error;
        if (!inputs.hasField(field!)) return ConditionResult.unmatched;

        final numVal = inputs.getNumeric(field!);
        if (numVal == null) return ConditionResult.error;

        final target = value is num ? value : num.tryParse(value.toString());
        if (target == null) return ConditionResult.error;

        switch (op) {
          case ConditionOp.gt:
            return numVal > target ? ConditionResult.matched : ConditionResult.unmatched;
          case ConditionOp.lt:
            return numVal < target ? ConditionResult.matched : ConditionResult.unmatched;
          case ConditionOp.gte:
            return numVal >= target ? ConditionResult.matched : ConditionResult.unmatched;
          case ConditionOp.lte:
            return numVal <= target ? ConditionResult.matched : ConditionResult.unmatched;
          default:
            return ConditionResult.error;
        }

      case ConditionOp.eq:
        if (field == null) return ConditionResult.error;
        if (!inputs.hasField(field!)) {
          return value == null ? ConditionResult.matched : ConditionResult.unmatched;
        }
        final val = inputs.get(field!);
        return _compareValuesEqual(val, value)
            ? ConditionResult.matched
            : ConditionResult.unmatched;

      case ConditionOp.neq:
        if (field == null) return ConditionResult.error;
        if (!inputs.hasField(field!)) return ConditionResult.unmatched;
        final val = inputs.get(field!);
        return !_compareValuesEqual(val, value)
            ? ConditionResult.matched
            : ConditionResult.unmatched;

      case ConditionOp.isIn:
        if (field == null) return ConditionResult.error;
        if (!inputs.hasField(field!)) return ConditionResult.unmatched;
        final targetList = values ?? (value is List ? value as List : null);
        if (targetList == null) return ConditionResult.error;
        final val = inputs.get(field!);
        for (final item in targetList) {
          if (_compareValuesEqual(val, item)) return ConditionResult.matched;
        }
        return ConditionResult.unmatched;

      case ConditionOp.notIn:
        if (field == null) return ConditionResult.error;
        if (!inputs.hasField(field!)) return ConditionResult.unmatched;
        final targetList = values ?? (value is List ? value as List : null);
        if (targetList == null) return ConditionResult.error;
        final val = inputs.get(field!);
        for (final item in targetList) {
          if (_compareValuesEqual(val, item)) return ConditionResult.unmatched;
        }
        return ConditionResult.matched;
    }
  }

  static bool _compareValuesEqual(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;

    // Numeric comparison
    if (a is num && b is num) return a == b;
    if (a is num && b is String) {
      final parsed = num.tryParse(b);
      return parsed != null && a == parsed;
    }
    if (a is String && b is num) {
      final parsed = num.tryParse(a);
      return parsed != null && parsed == b;
    }

    // Boolean comparison
    if (a is bool && b is bool) return a == b;
    if (a is bool && b is String) {
      final bl = b.trim().toLowerCase();
      if (bl == 'true' || bl == 'yes' || bl == '1') return a == true;
      if (bl == 'false' || bl == 'no' || bl == '0') return a == false;
    }
    if (a is String && b is bool) {
      final al = a.trim().toLowerCase();
      if (al == 'true' || al == 'yes' || al == '1') return b == true;
      if (al == 'false' || al == 'no' || al == '0') return b == false;
    }

    // String comparison (case-insensitive)
    if (a is String && b is String) {
      return a.trim().toLowerCase() == b.trim().toLowerCase();
    }

    return a == b;
  }

  /// Collects all fields accessed by this condition tree.
  Set<String> referencedFields() {
    final fields = <String>{};
    if (field != null) fields.add(field!);
    for (final child in children) {
      fields.addAll(child.referencedFields());
    }
    return fields;
  }

  factory Condition.fromJson(Map<String, dynamic> json) {
    final opStr = json['op'] as String? ?? 'and';
    final op = ConditionOp.fromString(opStr);
    final field = json['field'] as String?;
    final value = json['value'];
    final values = (json['values'] as List<dynamic>?)?.toList();
    final childrenJson = json['children'] as List<dynamic>?;
    final children = childrenJson != null
        ? childrenJson.map((e) => Condition.fromJson(e as Map<String, dynamic>)).toList()
        : const <Condition>[];

    return Condition(
      op: op,
      field: field,
      value: value,
      values: values,
      children: children,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'op': op.op,
      if (field != null) 'field': field,
      if (value != null) 'value': value,
      if (values != null) 'values': values,
      if (children.isNotEmpty)
        'children': children.map((c) => c.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Condition &&
          runtimeType == other.runtimeType &&
          op == other.op &&
          field == other.field &&
          value == other.value &&
          _listEquals(values, other.values) &&
          _childrenEquals(children, other.children);

  @override
  int get hashCode => Object.hash(
        op,
        field,
        value,
        values == null ? null : Object.hashAll(values!),
        Object.hashAll(children),
      );

  static bool _listEquals(List<dynamic>? a, List<dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _childrenEquals(List<Condition> a, List<Condition> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
