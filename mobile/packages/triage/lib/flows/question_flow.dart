import 'package:imci_engine/imci_engine.dart';

import '../context/context_pack.dart';

/// General danger signs. This order is fixed. Adaptation cannot move them.
const dangerFields = <String>[
  'symptoms.unable_to_drink',
  'symptoms.vomits_everything',
  'symptoms.convulsions',
  'symptoms.convulsing_now',
  'symptoms.lethargic_or_unconscious',
];

class FlowState {
  FlowState({
    required this.questions,
    required this.wardId,
    required this.districtId,
    required this.activeModules,
  });

  final List<BankQuestion> questions;
  final String wardId;
  final String districtId;
  final List<String> activeModules;
  final Map<String, Object?> answers = {};
  final Set<String> answeredIds = {};
  var earlyStopped = false;

  BankQuestion? questionById(String id) {
    for (final question in questions) {
      if (question.id == id) return question;
    }
    return null;
  }

  /// Worker answer. `true` / `false` is Yes / No. Null is Unknown and stores nothing.
  ///
  /// ⚠️  INVERSION WARNING — drink / breastfeed question:
  /// The question asked to the ASHA is positively framed:
  ///   "Can the child drink or breastfeed?"   → Yes means the child CAN drink
  /// But the IMCI engine field is negatively framed:
  ///   `symptoms.unable_to_drink`             → true means the child CANNOT drink
  ///
  /// The inversion is controlled by `BankQuestion.invertYes = true` (set in the
  /// JSON pack via `"invert_yes": true` on the DS-DRINK question). When you add
  /// any new question whose UI answer polarity differs from the stored field
  /// polarity, you MUST set `"invert_yes": true` in the pack JSON — otherwise
  /// the IMCI classifier will silently store the wrong value and may misclassify
  /// a danger sign.
  void answer(String questionId, Object? raw) {
    final question = questionById(questionId);
    if (question == null) return;
    answeredIds.add(questionId);
    if (raw == null) return;
    if (question.type == 'bool') {
      final yes = raw == true;
      final stored = question.invertYes ? !yes : yes;
      answers[question.inputField] = stored;
      if (stored == true && dangerFields.contains(question.inputField)) {
        earlyStopped = true;
      }
      return;
    }
    answers[question.inputField] = raw;
  }

  /// Seeds an answer collected during the unified intake screen.
  ///
  /// Seeded values are treated as answered but do not early-stop the flow;
  /// the adaptive question list still controls the remaining assessment.
  void seedInput(String inputField, Object? value) {
    final question = questions.cast<BankQuestion?>().firstWhere(
      (item) => item!.inputField == inputField,
      orElse: () => null,
    );
    if (question == null) return;
    answeredIds.add(question.id);
    answers[inputField] = value;
  }

  List<BankQuestion> get pending {
    if (earlyStopped) return const [];
    return [
      for (final question in questions)
        if (!answeredIds.contains(question.id)) question,
    ];
  }

  bool get dangerComplete {
    for (final field in dangerFields) {
      if (!answers.containsKey(field)) return false;
    }
    return true;
  }

  AssessmentInput toAssessmentInput({
    required String patientId,
    required int ageMonths,
    required String sex,
  }) {
    bool flag(String field) => answers[field] == true;
    int? days(String field) {
      final value = answers[field];
      return value is num ? value.toInt() : null;
    }

    num? measure(String field) {
      final value = answers[field];
      return value is num ? value : null;
    }

    final pinch = answers['symptoms.skin_pinch'];
    final earTouched =
        answers.containsKey('symptoms.ear_pain') ||
        answers.containsKey('symptoms.ear_discharge') ||
        answers.containsKey('symptoms.ear_discharge_days') ||
        answers.containsKey('symptoms.tender_swelling_behind_ear');

    return AssessmentInput(
      patientId: patientId,
      ageMonths: ageMonths,
      sex: sex,
      context: AssessmentContext(
        districtId: districtId,
        wardId: wardId,
        activeModules: activeModules,
        malariaRiskArea: flag('context.malaria_risk_area'),
      ),
      vitals: Vitals(
        respiratoryRate: measure('vitals.respiratory_rate'),
        tempC: measure('vitals.temp_c'),
        weightKg: measure('vitals.weight_kg'),
        weightForAgeZscore: measure('vitals.weight_for_age_zscore'),
        systolicBp: measure('vitals.systolic_bp'),
        diastolicBp: measure('vitals.diastolic_bp'),
        pulseRate: measure('vitals.pulse_rate'),
      ),
      symptoms: Symptoms(
        // NOTE: The 'unable_to_drink' field is stored with polarity already
        // inverted by answer() via BankQuestion.invertYes. A `true` value here
        // means the child genuinely CANNOT drink (a danger sign). Do not invert again.
        unableToDrink: flag('symptoms.unable_to_drink'),
        vomitsEverything: flag('symptoms.vomits_everything'),
        convulsions: flag('symptoms.convulsions'),
        convulsingNow: flag('symptoms.convulsing_now'),
        lethargicOrUnconscious: flag('symptoms.lethargic_or_unconscious'),
        cough:
            flag('symptoms.cough') ||
            flag('symptoms.cough_or_difficult_breathing'),
        coughOrDifficultBreathing:
            flag('symptoms.cough') ||
            flag('symptoms.cough_or_difficult_breathing'),
        coughDurationDays: days('symptoms.cough_duration_days'),
        chestIndrawing: flag('symptoms.chest_indrawing'),
        stridorInCalmChild: flag('symptoms.stridor_in_calm_child'),
        diarrhoea: flag('symptoms.diarrhoea'),
        diarrhoeaDurationDays: days('symptoms.diarrhoea_duration_days'),
        bloodInStool: flag('symptoms.blood_in_stool'),
        restlessIrritable: flag('symptoms.restless_irritable'),
        sunkenEyes: flag('symptoms.sunken_eyes'),
        drinksEagerly: flag('symptoms.drinks_eagerly'),
        drinkingPoorly: flag('symptoms.drinking_poorly'),
        skinPinchSlow: pinch == 'slow',
        skinPinchVerySlow: pinch == 'very_slow',
        fever: flag('symptoms.fever'),
        stiffNeck: flag('symptoms.stiff_neck'),
        malariaTestPositive: flag('symptoms.malaria_test_positive'),
        severeMalaria: flag('symptoms.severe_malaria'),
        earPain: flag('symptoms.ear_pain'),
        earDischarge: flag('symptoms.ear_discharge'),
        earDischargeDays: days('symptoms.ear_discharge_days'),
        tenderSwellingBehindEar: flag('symptoms.tender_swelling_behind_ear'),
        earAssessed: earTouched,
        visibleSevereWasting: flag('symptoms.visible_severe_wasting'),
        oedemaBothFeet: flag('symptoms.oedema_both_feet'),
        palmarPallor: flag('symptoms.palmar_pallor'),
        severeAbdominalPain: flag('symptoms.severe_abdominal_pain'),
        persistentVomiting: flag('symptoms.persistent_vomiting'),
        mucosalBleeding: flag('symptoms.mucosal_bleeding'),
        clinicalFluidAccumulation: flag('symptoms.clinical_fluid_accumulation'),
        measlesRash: flag('symptoms.measles_rash'),
        redEyes: flag('symptoms.red_eyes'),
        runnyNose: flag('symptoms.runny_nose'),
        acuteEncephalopathy: flag('symptoms.acute_encephalopathy'),
        wateryStoolsMany: flag('symptoms.watery_stools_many'),
        mosquitoBreedingNearby: flag('symptoms.mosquito_breeding_nearby'),
        dengueRestlessOrLethargic: flag(
          'symptoms.dengue_restless_or_lethargic',
        ),
      ),
    );
  }
}

class FlowBuilder {
  const FlowBuilder(this.pack);

  final ContextPack pack;

  FlowState build({
    required String wardId,
    int? calendarMonth,
    int? ageMonths,
    Set<String> extraModules = const {},
  }) {
    final active = {
      ...pack.activeModuleIds(wardId, month: calendarMonth),
      ...extraModules,
    }.toList();
    final activeSet = active.toSet();

    // --- age-aware question selection ---
    final eligible = <BankQuestion>[];
    for (final question in pack.questions) {
      // Module gate: core + adult are always eligible; others need active outbreak
      if (question.module != 'core' &&
          question.module != 'adult' &&
          question.module != 'adult_vitals' &&
          !activeSet.contains(question.module)) {
        continue;
      }
      // Age gate: skip questions outside the patient's age range
      if (ageMonths != null && !question.appliesTo(ageMonths)) continue;
      eligible.add(question);
    }

    final byField = <String, BankQuestion>{};
    for (final question in eligible) {
      byField.putIfAbsent(question.inputField, () => question);
    }

    final danger = <BankQuestion>[];
    for (final field in dangerFields) {
      final question = byField[field];
      if (question != null && question.module == 'core') danger.add(question);
    }

    final outbreakFlags = _sorted([
      for (final question in eligible)
        if (question.module != 'core' &&
            question.module != 'adult' &&
            question.module != 'adult_vitals' &&
            question.isRedFlag &&
            activeSet.contains(question.module))
          question,
    ]);
    final coreRest = _sorted([
      for (final question in eligible)
        if ((question.module == 'core' ||
                question.module == 'adult' ||
                question.module == 'adult_vitals') &&
            !dangerFields.contains(question.inputField))
          question,
    ]);
    final outbreakRest = _sorted([
      for (final question in eligible)
        if (question.module != 'core' &&
            question.module != 'adult' &&
            question.module != 'adult_vitals' &&
            !question.isRedFlag &&
            activeSet.contains(question.module))
          question,
    ]);

    return FlowState(
      questions: [...danger, ...outbreakFlags, ...coreRest, ...outbreakRest],
      wardId: wardId,
      districtId: pack.districtId,
      activeModules: active,
    );
  }

  static List<BankQuestion> _sorted(List<BankQuestion> questions) {
    final copy = [...questions];
    copy.sort((a, b) {
      final byWeight = b.weight.compareTo(a.weight);
      if (byWeight != 0) return byWeight;
      return a.id.compareTo(b.id);
    });
    return copy;
  }
}
