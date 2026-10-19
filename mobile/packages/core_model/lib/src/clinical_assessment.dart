import 'sourced_value.dart';

enum PatientSex { male, female, other, unknown }

extension PatientSexX on PatientSex {
  String get wireName => switch (this) {
    PatientSex.male => 'M',
    PatientSex.female => 'F',
    PatientSex.other => 'OTHER',
    PatientSex.unknown => 'UNKNOWN',
  };

  static PatientSex fromWire(Object? value) => switch (value) {
    'M' || 'MALE' => PatientSex.male,
    'F' || 'FEMALE' => PatientSex.female,
    'OTHER' => PatientSex.other,
    _ => PatientSex.unknown,
  };
}

/// SI-4. Escalation only. There is deliberately no de-escalation field.
class WorkerOverride {
  const WorkerOverride({this.escalateToRed = false, this.note});

  final bool escalateToRed;
  final String? note;

  JsonMap toJson() => {'escalate_to_red': escalateToRed, 'note': note};

  factory WorkerOverride.fromJson(Object? raw) {
    final map = (raw as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return WorkerOverride(
      escalateToRed: map['escalate_to_red'] == true || map['escalate_to_red'] == 'YES',
      note: map['note'] as String?,
    );
  }
}

/// Canonical dotted field paths shared by the ruleset, the UI, and the
/// extractor. Rules address fields by these strings, so they are frozen:
/// renaming one is a breaking ruleset change (architecture.md §7.1).
abstract final class FieldPaths {
  // Patient (synthesised by ClinicalAssessment.valueAt)
  static const ageMonths = 'patient.age_months';
  static const sex = 'patient.sex';

  // Symptoms
  static const fever = 'symptoms.fever';
  static const feverDurationDays = 'symptoms.fever_duration_days';
  static const cough = 'symptoms.cough';
  static const coughDurationDays = 'symptoms.cough_duration_days';
  static const difficultyBreathing = 'symptoms.difficulty_breathing';
  static const diarrhoea = 'symptoms.diarrhoea';
  static const diarrhoeaDurationDays = 'symptoms.diarrhoea_duration_days';
  static const bloodInStool = 'symptoms.blood_in_stool';
  static const vomiting = 'symptoms.vomiting';

  // General danger signs (§10.4 group A)
  static const unableToDrinkOrBreastfeed = 'danger_signs.unable_to_drink_or_breastfeed';
  static const vomitsEverything = 'danger_signs.vomits_everything';
  static const convulsionsThisIllness = 'danger_signs.convulsions_this_illness';
  static const convulsingNow = 'danger_signs.convulsing_now';
  static const lethargicOrUnconscious = 'danger_signs.lethargic_or_unconscious';

  // Observations
  static const chestIndrawing = 'observations.chest_indrawing';
  static const stridorWhenCalm = 'observations.stridor_when_calm';
  static const grunting = 'observations.grunting';
  static const nasalFlaring = 'observations.nasal_flaring';
  static const severeRespiratoryDistress = 'observations.severe_respiratory_distress';
  static const sunkenEyes = 'observations.sunken_eyes';
  static const skinPinch = 'observations.skin_pinch';
  static const drinkingPattern = 'observations.drinking_pattern';
  static const restlessIrritable = 'observations.restless_irritable';
  static const observedLethargic = 'observations.lethargic_or_unconscious';
  static const stiffNeck = 'observations.stiff_neck';
  static const feelsHotToTouch = 'observations.feels_hot_to_touch';
  static const oedemaBothFeet = 'observations.oedema_both_feet';
  static const visibleSevereWasting = 'observations.visible_severe_wasting';

  // Vitals
  static const temperatureC = 'vitals.temperature_c';
  static const respiratoryRate = 'vitals.respiratory_rate';
  static const muacMm = 'vitals.muac_mm';

  /// §10.5 — always collected regardless of what the transcript said, because
  /// each is `requires` for at least one RED rule.
  static const mandatoryDangerSigns = <String>[
    unableToDrinkOrBreastfeed,
    vomitsEverything,
    convulsionsThisIllness,
    convulsingNow,
    lethargicOrUnconscious,
    chestIndrawing,
    stridorWhenCalm,
  ];

  /// §10.5 conditional follow-ups keyed by the symptom that triggers them.
  static const conditionalQuestions = <String, List<String>>{
    cough: [respiratoryRate],
    diarrhoea: [sunkenEyes, skinPinch, drinkingPattern],
  };

  /// Every field some RED rule needs before it can be evaluated.
  ///
  /// §10.5 names seven danger signs plus two conditional groups, but the
  /// `imci-mvp-1.0.0` ruleset rests RED rules on considerably more than that
  /// (nutrition, fever, severe respiratory signs). If the UI collects only the
  /// seven, every RED rule needing a missing field stays INDETERMINATE and the
  /// engine returns NEEDS_MORE_INFO forever — no band is ever produced.
  ///
  /// This list therefore MUST equal `RuleSet.redRequiredFields` for the shipped
  /// ruleset; `field_coverage_test.dart` asserts exactly that, so adding a RED
  /// rule with a new input fails CI until the question set catches up.
  static const redRequiredFields = <String>[
    convulsingNow,
    convulsionsThisIllness,
    lethargicOrUnconscious,
    unableToDrinkOrBreastfeed,
    vomitsEverything,
    chestIndrawing,
    drinkingPattern,
    grunting,
    observedLethargic,
    nasalFlaring,
    oedemaBothFeet,
    severeRespiratoryDistress,
    skinPinch,
    stiffNeck,
    stridorWhenCalm,
    sunkenEyes,
    visibleSevereWasting,
    cough,
    diarrhoea,
    fever,
    muacMm,
    respiratoryRate,
    temperatureC,
  ];
}

/// Canonical, flattened representation consumed by the pure engine.
/// Field names intentionally match the JSON paths in the ruleset.
class ClinicalAssessment {
  ClinicalAssessment({
    required this.ageMonths,
    this.sex = PatientSex.unknown,
    Map<String, SourcedValue>? fields,
    this.workerOverride = const WorkerOverride(),
    this.previousBand,
    this.symptomsImproved,
  }) : fields = Map.unmodifiable(fields ?? const {});

  final int ageMonths;
  final PatientSex sex;
  final Map<String, SourcedValue> fields;
  final WorkerOverride workerOverride;
  final String? previousBand;
  final bool? symptomsImproved;

  SourcedValue valueAt(String path) {
    if (path == FieldPaths.ageMonths) return SourcedValue(value: ageMonths, source: ClinicalSource.measured);
    if (path == FieldPaths.sex) return SourcedValue(value: sex.wireName, source: ClinicalSource.confirmedByWorker);
    if (path == 'worker_override.escalate_to_red') {
      return SourcedValue(value: workerOverride.escalateToRed ? 'YES' : 'NO', source: ClinicalSource.guidedAnswer);
    }
    return fields[path] ?? const SourcedValue(value: null, source: ClinicalSource.unset);
  }

  ClinicalAssessment withField(String path, SourcedValue value) =>
      copyWith(fields: {...fields, path: value});

  ClinicalAssessment copyWith({
    int? ageMonths,
    PatientSex? sex,
    Map<String, SourcedValue>? fields,
    WorkerOverride? workerOverride,
    String? previousBand,
    bool? symptomsImproved,
  }) => ClinicalAssessment(
    ageMonths: ageMonths ?? this.ageMonths,
    sex: sex ?? this.sex,
    fields: fields ?? this.fields,
    workerOverride: workerOverride ?? this.workerOverride,
    previousBand: previousBand ?? this.previousBand,
    symptomsImproved: symptomsImproved ?? this.symptomsImproved,
  );

  JsonMap toJson() => {
    'patient': {'age_months': ageMonths, 'sex': sex.wireName},
    'fields': {for (final entry in fields.entries) entry.key: entry.value.toJson()},
    'worker_override': workerOverride.toJson(),
    'previous_band': previousBand,
    'symptoms_improved': symptomsImproved,
  };

  factory ClinicalAssessment.fromJson(JsonMap json) {
    final patient = (json['patient'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final rawFields = (json['fields'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return ClinicalAssessment(
      ageMonths: (patient['age_months'] as num?)?.toInt() ?? -1,
      sex: PatientSexX.fromWire(patient['sex']),
      fields: {for (final entry in rawFields.entries) entry.key: SourcedValue.fromJson(entry.value)},
      workerOverride: WorkerOverride.fromJson(json['worker_override']),
      previousBand: json['previous_band'] as String?,
      symptomsImproved: json['symptoms_improved'] as bool?,
    );
  }
}
