/// Age band identifiers supported by the clinical decision support engine.
enum AgeBandCode {
  infant02m('INFANT_0_2M'),
  child2m5y('CHILD_2M_5Y'),
  adolescent('ADOLESCENT'),
  adult('ADULT'),
  pregnant('PREGNANT');

  final String code;
  const AgeBandCode(this.code);

  static AgeBandCode fromCode(String? code) {
    if (code == null) return AgeBandCode.adult;
    final upper = code.trim().toUpperCase();
    for (final b in values) {
      if (b.code == upper || b.name.toUpperCase() == upper) return b;
    }
    return AgeBandCode.adult;
  }
}

/// Metadata configuration for an age band, including clinical required fields.
class AgeBand {
  final AgeBandCode code;
  final String name;
  final List<String> requiredFields;
  final int? minAgeDays;
  final int? maxAgeDays;

  const AgeBand({
    required this.code,
    required this.name,
    this.requiredFields = const [],
    this.minAgeDays,
    this.maxAgeDays,
  });

  static const Map<AgeBandCode, List<String>> defaultRequiredFields = {
    AgeBandCode.infant02m: ['respiratory_rate', 'temperature'],
    AgeBandCode.child2m5y: ['respiratory_rate', 'temperature'],
    AgeBandCode.adolescent: ['temperature', 'systolic_bp'],
    AgeBandCode.adult: ['systolic_bp', 'diastolic_bp', 'pulse_rate'],
    AgeBandCode.pregnant: ['systolic_bp', 'diastolic_bp', 'gestational_weeks'],
  };

  factory AgeBand.defaultFor(AgeBandCode code) {
    return AgeBand(
      code: code,
      name: code.code,
      requiredFields: defaultRequiredFields[code] ?? const [],
    );
  }

  factory AgeBand.fromJson(Map<String, dynamic> json) => AgeBand(
        code: AgeBandCode.fromCode(json['code'] as String? ?? json['age_band'] as String?),
        name: json['name'] as String? ?? '',
        requiredFields: (json['required_fields'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        minAgeDays: json['min_age_days'] as int?,
        maxAgeDays: json['max_age_days'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'code': code.code,
        'name': name,
        'required_fields': requiredFields,
        if (minAgeDays != null) 'min_age_days': minAgeDays,
        if (maxAgeDays != null) 'max_age_days': maxAgeDays,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgeBand &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          name == other.name &&
          _listEquals(requiredFields, other.requiredFields) &&
          minAgeDays == other.minAgeDays &&
          maxAgeDays == other.maxAgeDays;

  @override
  int get hashCode => Object.hash(
        code,
        name,
        Object.hashAll(requiredFields),
        minAgeDays,
        maxAgeDays,
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Resolves the appropriate [AgeBandCode] based on patient inputs.
class AgeBandResolver {
  static AgeBandCode resolve({
    int? ageInDays,
    double? ageInYears,
    bool isPregnant = false,
    AgeBandCode? explicitCode,
  }) {
    if (isPregnant) return AgeBandCode.pregnant;
    if (explicitCode != null) return explicitCode;

    if (ageInDays != null) {
      if (ageInDays <= 60) return AgeBandCode.infant02m;
      if (ageInDays <= 1825) return AgeBandCode.child2m5y;
      if (ageInDays <= 6935) return AgeBandCode.adolescent;
      return AgeBandCode.adult;
    }

    if (ageInYears != null) {
      if (ageInYears <= (60.0 / 365.25)) return AgeBandCode.infant02m;
      if (ageInYears <= 5.0) return AgeBandCode.child2m5y;
      if (ageInYears < 19.0) return AgeBandCode.adolescent;
      return AgeBandCode.adult;
    }

    return AgeBandCode.adult;
  }
}
