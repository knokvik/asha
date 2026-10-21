/// How urgent the overall classification is.
enum TriageFlag { red, yellow, green }

extension TriageFlagX on TriageFlag {
  String get wireName => name.toUpperCase();

  int get rank => switch (this) {
    TriageFlag.red => 3,
    TriageFlag.yellow => 2,
    TriageFlag.green => 1,
  };

  String get urgency => switch (this) {
    TriageFlag.red => 'refer URGENTLY',
    TriageFlag.yellow => 'refer / follow-up',
    TriageFlag.green => 'home care',
  };
}

/// Measured values. Null means not measured, so a numeric rule does not fire.
class Vitals {
  const Vitals({
    this.respiratoryRate,
    this.tempC,
    this.weightKg,
    this.weightForAgeZscore,
    this.systolicBp,
    this.diastolicBp,
    this.pulseRate,
  });

  final num? respiratoryRate;
  final num? tempC;
  final num? weightKg;
  final num? weightForAgeZscore;
  final num? systolicBp;
  final num? diastolicBp;
  final num? pulseRate;
}

/// Booleans default to false. Durations stay null until the worker enters them.
class Symptoms {
  const Symptoms({
    this.unableToDrink = false,
    this.vomitsEverything = false,
    this.convulsions = false,
    this.convulsingNow = false,
    this.lethargicOrUnconscious = false,
    this.cough = false,
    this.coughOrDifficultBreathing = false,
    this.coughDurationDays,
    this.chestIndrawing = false,
    this.stridorInCalmChild = false,
    this.diarrhoea = false,
    this.diarrhoeaDurationDays,
    this.bloodInStool = false,
    this.restlessIrritable = false,
    this.sunkenEyes = false,
    this.drinksEagerly = false,
    this.drinkingPoorly = false,
    this.skinPinchSlow = false,
    this.skinPinchVerySlow = false,
    this.fever = false,
    this.stiffNeck = false,
    this.malariaTestPositive = false,
    this.severeMalaria = false,
    this.earPain = false,
    this.earDischarge = false,
    this.earDischargeDays,
    this.tenderSwellingBehindEar = false,
    this.earAssessed = false,
    this.visibleSevereWasting = false,
    this.oedemaBothFeet = false,
    this.palmarPallor = false,
    this.severeAbdominalPain = false,
    this.persistentVomiting = false,
    this.mucosalBleeding = false,
    this.clinicalFluidAccumulation = false,
    this.measlesRash = false,
    this.redEyes = false,
    this.runnyNose = false,
    this.acuteEncephalopathy = false,
    this.wateryStoolsMany = false,
    this.mosquitoBreedingNearby = false,
    this.dengueRestlessOrLethargic = false,
  });

  final bool unableToDrink;
  final bool vomitsEverything;
  final bool convulsions;
  final bool convulsingNow;
  final bool lethargicOrUnconscious;
  final bool cough;
  final bool coughOrDifficultBreathing;
  final int? coughDurationDays;
  final bool chestIndrawing;
  final bool stridorInCalmChild;
  final bool diarrhoea;
  final int? diarrhoeaDurationDays;
  final bool bloodInStool;
  final bool restlessIrritable;
  final bool sunkenEyes;
  final bool drinksEagerly;
  final bool drinkingPoorly;
  final bool skinPinchSlow;
  final bool skinPinchVerySlow;
  final bool fever;
  final bool stiffNeck;
  final bool malariaTestPositive;
  final bool severeMalaria;
  final bool earPain;
  final bool earDischarge;
  final int? earDischargeDays;
  final bool tenderSwellingBehindEar;
  final bool earAssessed;
  final bool visibleSevereWasting;
  final bool oedemaBothFeet;
  final bool palmarPallor;
  final bool severeAbdominalPain;
  final bool persistentVomiting;
  final bool mucosalBleeding;
  final bool clinicalFluidAccumulation;
  final bool measlesRash;
  final bool redEyes;
  final bool runnyNose;
  final bool acuteEncephalopathy;
  final bool wateryStoolsMany;
  final bool mosquitoBreedingNearby;
  final bool dengueRestlessOrLethargic;

  /// Signs a referral note can list. Outbreak answers are included.
  List<String> get notedSigns {
    final signs = <String>[];
    void add(bool on, String label) {
      if (on) signs.add(label);
    }

    add(unableToDrink, 'unable to drink');
    add(vomitsEverything, 'vomits everything');
    add(convulsions, 'convulsions');
    add(convulsingNow, 'convulsing now');
    add(lethargicOrUnconscious, 'lethargic or unconscious');
    add(cough, 'cough');
    add(coughOrDifficultBreathing, 'difficult breathing');
    add(chestIndrawing, 'chest indrawing');
    add(stridorInCalmChild, 'stridor in a calm child');
    add(diarrhoea, 'diarrhoea');
    add(bloodInStool, 'blood in stool');
    add(restlessIrritable, 'restless or irritable');
    add(sunkenEyes, 'sunken eyes');
    add(drinksEagerly, 'drinks eagerly');
    add(drinkingPoorly, 'drinking poorly');
    add(skinPinchSlow, 'skin pinch slow');
    add(skinPinchVerySlow, 'skin pinch very slow');
    add(fever, 'fever');
    add(stiffNeck, 'stiff neck');
    add(malariaTestPositive, 'malaria test positive');
    add(severeMalaria, 'severe malaria');
    add(earPain, 'ear pain');
    add(earDischarge, 'ear discharge');
    add(tenderSwellingBehindEar, 'tender swelling behind the ear');
    add(visibleSevereWasting, 'visible severe wasting');
    add(oedemaBothFeet, 'oedema of both feet');
    add(palmarPallor, 'palmar pallor');
    add(severeAbdominalPain, 'severe abdominal pain');
    add(persistentVomiting, 'persistent vomiting');
    add(mucosalBleeding, 'mucosal bleeding');
    add(clinicalFluidAccumulation, 'clinical fluid accumulation');
    add(measlesRash, 'measles-like rash');
    add(redEyes, 'red eyes');
    add(runnyNose, 'runny nose');
    add(acuteEncephalopathy, 'acute encephalopathy');
    add(wateryStoolsMany, 'many watery stools');
    add(mosquitoBreedingNearby, 'mosquito breeding nearby');
    add(dengueRestlessOrLethargic, 'dengue lethargy or restlessness');
    return signs;
  }
}

class AssessmentContext {
  const AssessmentContext({
    this.districtId,
    this.wardId,
    this.activeModules = const [],
    this.malariaRiskArea = false,
  });

  final String? districtId;
  final String? wardId;
  final List<String> activeModules;
  final bool malariaRiskArea;
}

/// Structured assessment. The engine reads this and nothing else.
class AssessmentInput {
  const AssessmentInput({
    required this.patientId,
    required this.ageMonths,
    required this.sex,
    this.vitals = const Vitals(),
    this.symptoms = const Symptoms(),
    this.context = const AssessmentContext(),
  });

  final String patientId;
  final int ageMonths;
  final String sex;
  final Vitals vitals;
  final Symptoms symptoms;
  final AssessmentContext context;

  /// Flat values addressed by rule conditions.
  Map<String, Object?> toFields() => {
    'age_months': ageMonths,
    'sex': sex,
    'vitals.respiratory_rate': vitals.respiratoryRate,
    'vitals.temp_c': vitals.tempC,
    'vitals.weight_kg': vitals.weightKg,
    'vitals.weight_for_age_zscore': vitals.weightForAgeZscore,
    'vitals.systolic_bp': vitals.systolicBp,
    'vitals.diastolic_bp': vitals.diastolicBp,
    'vitals.pulse_rate': vitals.pulseRate,
    'symptoms.unable_to_drink': symptoms.unableToDrink,
    'symptoms.vomits_everything': symptoms.vomitsEverything,
    'symptoms.convulsions': symptoms.convulsions,
    'symptoms.convulsing_now': symptoms.convulsingNow,
    'symptoms.lethargic_or_unconscious': symptoms.lethargicOrUnconscious,
    'symptoms.cough': symptoms.cough,
    'symptoms.cough_or_difficult_breathing': symptoms.coughOrDifficultBreathing,
    'symptoms.cough_duration_days': symptoms.coughDurationDays,
    'symptoms.chest_indrawing': symptoms.chestIndrawing,
    'symptoms.stridor_in_calm_child': symptoms.stridorInCalmChild,
    'symptoms.diarrhoea': symptoms.diarrhoea,
    'symptoms.diarrhoea_duration_days': symptoms.diarrhoeaDurationDays,
    'symptoms.blood_in_stool': symptoms.bloodInStool,
    'symptoms.restless_irritable': symptoms.restlessIrritable,
    'symptoms.sunken_eyes': symptoms.sunkenEyes,
    'symptoms.drinks_eagerly': symptoms.drinksEagerly,
    'symptoms.drinking_poorly': symptoms.drinkingPoorly,
    'symptoms.skin_pinch_slow': symptoms.skinPinchSlow,
    'symptoms.skin_pinch_very_slow': symptoms.skinPinchVerySlow,
    'symptoms.fever': symptoms.fever,
    'symptoms.stiff_neck': symptoms.stiffNeck,
    'symptoms.malaria_test_positive': symptoms.malariaTestPositive,
    'symptoms.severe_malaria': symptoms.severeMalaria,
    'symptoms.ear_pain': symptoms.earPain,
    'symptoms.ear_discharge': symptoms.earDischarge,
    'symptoms.ear_discharge_days': symptoms.earDischargeDays,
    'symptoms.tender_swelling_behind_ear': symptoms.tenderSwellingBehindEar,
    'symptoms.ear_assessed': symptoms.earAssessed,
    'symptoms.visible_severe_wasting': symptoms.visibleSevereWasting,
    'symptoms.oedema_both_feet': symptoms.oedemaBothFeet,
    'symptoms.palmar_pallor': symptoms.palmarPallor,
    'symptoms.severe_abdominal_pain': symptoms.severeAbdominalPain,
    'symptoms.persistent_vomiting': symptoms.persistentVomiting,
    'symptoms.mucosal_bleeding': symptoms.mucosalBleeding,
    'symptoms.clinical_fluid_accumulation': symptoms.clinicalFluidAccumulation,
    'symptoms.measles_rash': symptoms.measlesRash,
    'symptoms.red_eyes': symptoms.redEyes,
    'symptoms.runny_nose': symptoms.runnyNose,
    'symptoms.acute_encephalopathy': symptoms.acuteEncephalopathy,
    'symptoms.watery_stools_many': symptoms.wateryStoolsMany,
    'symptoms.mosquito_breeding_nearby': symptoms.mosquitoBreedingNearby,
    'symptoms.dengue_restless_or_lethargic': symptoms.dengueRestlessOrLethargic,
    'context.malaria_risk_area': context.malariaRiskArea,
    'context.district_id': context.districtId,
    'context.ward_id': context.wardId,
  };
}

class FiredRule {
  const FiredRule({
    required this.ruleId,
    required this.module,
    required this.severity,
    required this.reasonText,
    required this.guidelineRef,
    required this.suspectedDisease,
    required this.actions,
    this.followUpDays,
  });

  final String ruleId;
  final String module;
  final TriageFlag severity;
  final String reasonText;
  final String guidelineRef;
  final String suspectedDisease;
  final List<String> actions;
  final int? followUpDays;
}

class TriageResult {
  const TriageResult({
    required this.flag,
    required this.firedRules,
    required this.followUpDays,
  });

  final TriageFlag flag;
  final List<FiredRule> firedRules;

  /// Taken from the rule that set [flag]. Null when that rule has no return visit.
  final int? followUpDays;

  List<String> get ruleIds =>
      firedRules.map((rule) => rule.ruleId).toList(growable: false);
}

class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.abhaId,
    required this.name,
    required this.ageMonths,
    required this.sex,
    required this.village,
  });

  final String id;
  final String abhaId;
  final String name;
  final int ageMonths;
  final String sex;
  final String village;
}

class FacilityProfile {
  const FacilityProfile({required this.id, required this.name});

  final String id;
  final String name;
}
