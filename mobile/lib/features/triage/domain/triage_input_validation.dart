/// Safety checks for measurements entered into the triage flow.
///
/// These checks only protect data entry. They do not classify a patient and
/// must not be used to change an IMCI/adult rule threshold.
class TriageInputIssue {
  const TriageInputIssue({
    required this.fieldKey,
    required this.message,
    this.confirmable = false,
  });

  final String fieldKey;
  final String message;

  /// A value outside a plausibility range may be real, but needs an explicit
  /// re-check/confirmation instead of being accepted silently.
  final bool confirmable;
}

class TriageInputBounds {
  const TriageInputBounds({
    required this.unit,
    required this.min,
    required this.max,
    this.decimals = 0,
  });

  final String unit;
  final num min;
  final num max;
  final int decimals;

  String get rangeLabel => '$min–$max $unit';
}

/// Plausibility validation for the measurements used by the current flow.
///
/// NEEDS CLINICIAN VALIDATION: these are conservative field-entry guardrails
/// supplied by the triage product specification, not diagnostic cut-offs.
class TriageInputValidation {
  const TriageInputValidation._();

  static const _bounds = <String, TriageInputBounds>{
    'vitals.temp_c': TriageInputBounds(
      unit: '°C',
      min: 30,
      max: 45,
      decimals: 1,
    ),
    'vitals.systolic_bp': TriageInputBounds(unit: 'mmHg', min: 50, max: 260),
    'vitals.diastolic_bp': TriageInputBounds(unit: 'mmHg', min: 30, max: 160),
    'vitals.pulse_rate': TriageInputBounds(
      unit: 'beats/min',
      min: 30,
      max: 250,
    ),
    'vitals.respiratory_rate': TriageInputBounds(
      unit: '/min',
      min: 5,
      max: 120,
    ),
  };

  static TriageInputBounds? boundsFor(String fieldKey) => _bounds[fieldKey];

  static List<TriageInputIssue> validate(
    Map<String, num?> values, {
    TriageInputBounds? Function(String fieldKey)? fallbackBounds,
  }) {
    final issues = <TriageInputIssue>[];
    for (final entry in values.entries) {
      final value = entry.value;
      if (value == null) continue;
      final bounds = _bounds[entry.key] ?? fallbackBounds?.call(entry.key);
      if (bounds == null) continue;
      if (value < bounds.min || value > bounds.max) {
        issues.add(
          TriageInputIssue(
            fieldKey: entry.key,
            message: 'Check ${_labelFor(entry.key)}. Use ${bounds.rangeLabel}.',
            confirmable: true,
          ),
        );
      }
    }

    final systolic = values['vitals.systolic_bp'];
    final diastolic = values['vitals.diastolic_bp'];
    if (systolic != null && diastolic != null && systolic <= diastolic) {
      issues.add(
        const TriageInputIssue(
          fieldKey: 'vitals.systolic_bp',
          message:
              'Check blood pressure: systolic must be higher than diastolic.',
        ),
      );
    }
    return issues;
  }

  static TriageInputIssue? validateValue(
    String fieldKey,
    num value, {
    TriageInputBounds? fallbackBounds,
  }) {
    final bounds = _bounds[fieldKey] ?? fallbackBounds;
    if (bounds == null || (value >= bounds.min && value <= bounds.max)) {
      return null;
    }
    return TriageInputIssue(
      fieldKey: fieldKey,
      message: 'Check this value. Use ${bounds.rangeLabel}.',
      confirmable: true,
    );
  }

  static String _labelFor(String fieldKey) => switch (fieldKey) {
    'vitals.temp_c' => 'temperature',
    'vitals.systolic_bp' => 'systolic BP',
    'vitals.diastolic_bp' => 'diastolic BP',
    'vitals.pulse_rate' => 'pulse rate',
    'vitals.respiratory_rate' => 'respiratory rate',
    _ => 'measurement',
  };
}
