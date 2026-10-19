import 'age_band.dart';

/// Clinical assessment inputs for the triage engine.
class TriageInputs {
  final String? encounterId;
  final String? memberId;
  final int? ageInDays;
  final double? ageInYears;
  final bool isPregnant;
  final AgeBandCode? explicitAgeBand;
  final Map<String, dynamic> values;

  const TriageInputs({
    this.encounterId,
    this.memberId,
    this.ageInDays,
    this.ageInYears,
    this.isPregnant = false,
    this.explicitAgeBand,
    this.values = const {},
  });

  /// Checks if a field is present with non-null, non-empty data.
  bool hasField(String key) {
    if (key == 'age_days') return ageInDays != null;
    if (key == 'age_years') return ageInYears != null;
    if (key == 'is_pregnant') return true;

    final v = values[key];
    if (v == null) return false;
    if (v is String && v.trim().isEmpty) return false;
    return true;
  }

  /// Retrieves raw value for [key], mapping built-in properties if queried.
  dynamic get(String key) {
    if (key == 'age_days') return ageInDays;
    if (key == 'age_years') return ageInYears;
    if (key == 'is_pregnant') {
      return isPregnant || (values['is_pregnant'] == true);
    }
    return values[key];
  }

  /// Retrieves numeric value for [key], handling int, double, and parsable strings.
  num? getNumeric(String key) {
    final raw = get(key);
    if (raw == null) return null;
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw.trim());
    return null;
  }

  /// Retrieves boolean value for [key].
  bool? getBool(String key) {
    final raw = get(key);
    if (raw == null) return null;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final s = raw.trim().toLowerCase();
      if (s == 'true' || s == 'yes' || s == '1') return true;
      if (s == 'false' || s == 'no' || s == '0') return false;
    }
    return null;
  }

  /// Retrieves string representation of [key].
  String? getString(String key) {
    final raw = get(key);
    return raw?.toString();
  }

  /// Resolves the applicable [AgeBandCode] for these inputs.
  AgeBandCode resolveAgeBand() {
    return AgeBandResolver.resolve(
      ageInDays: ageInDays,
      ageInYears: ageInYears,
      isPregnant: isPregnant || getBool('is_pregnant') == true,
      explicitCode: explicitAgeBand,
    );
  }

  /// Returns a new [TriageInputs] with specified updates.
  TriageInputs copyWith({
    String? encounterId,
    String? memberId,
    int? ageInDays,
    double? ageInYears,
    bool? isPregnant,
    AgeBandCode? explicitAgeBand,
    Map<String, dynamic>? values,
  }) {
    return TriageInputs(
      encounterId: encounterId ?? this.encounterId,
      memberId: memberId ?? this.memberId,
      ageInDays: ageInDays ?? this.ageInDays,
      ageInYears: ageInYears ?? this.ageInYears,
      isPregnant: isPregnant ?? this.isPregnant,
      explicitAgeBand: explicitAgeBand ?? this.explicitAgeBand,
      values: values ?? Map<String, dynamic>.from(this.values),
    );
  }

  factory TriageInputs.fromJson(Map<String, dynamic> json) => TriageInputs(
        encounterId: json['encounter_id'] as String?,
        memberId: json['member_id'] as String?,
        ageInDays: json['age_in_days'] as int?,
        ageInYears: (json['age_in_years'] as num?)?.toDouble(),
        isPregnant: json['is_pregnant'] as bool? ?? false,
        explicitAgeBand: json['explicit_age_band'] != null
            ? AgeBandCode.fromCode(json['explicit_age_band'] as String)
            : null,
        values: Map<String, dynamic>.from(json['values'] as Map? ?? {}),
      );

  Map<String, dynamic> toJson() => {
        if (encounterId != null) 'encounter_id': encounterId,
        if (memberId != null) 'member_id': memberId,
        if (ageInDays != null) 'age_in_days': ageInDays,
        if (ageInYears != null) 'age_in_years': ageInYears,
        'is_pregnant': isPregnant,
        if (explicitAgeBand != null)
          'explicit_age_band': explicitAgeBand!.code,
        'values': values,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriageInputs &&
          runtimeType == other.runtimeType &&
          encounterId == other.encounterId &&
          memberId == other.memberId &&
          ageInDays == other.ageInDays &&
          ageInYears == other.ageInYears &&
          isPregnant == other.isPregnant &&
          explicitAgeBand == other.explicitAgeBand &&
          _mapEquals(values, other.values);

  @override
  int get hashCode => Object.hash(
        encounterId,
        memberId,
        ageInDays,
        ageInYears,
        isPregnant,
        explicitAgeBand,
        Object.hashAll(values.entries.map((e) => Object.hash(e.key, e.value))),
      );

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
