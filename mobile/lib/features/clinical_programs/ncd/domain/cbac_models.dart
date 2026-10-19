import '../../../../core/triage/models/models.dart';

/// Age bracket for CBAC Risk Assessment (>= 30 years).
enum CbacAgeBand {
  age30To39(0, '30 - 39 years (0 pts)'),
  age40To49(1, '40 - 49 years (+1 pt)'),
  age50To59(2, '50 - 59 years (+2 pts)'),
  age60Plus(2, '60 years or older (+2 pts)');

  final int score;
  final String label;
  const CbacAgeBand(this.score, this.label);

  static CbacAgeBand fromAge(int ageYears) {
    if (ageYears < 40) return age30To39;
    if (ageYears < 50) return age40To49;
    if (ageYears < 60) return age50To59;
    return age60Plus;
  }
}

/// Smoking and tobacco consumption risk factor.
enum TobaccoUse {
  never(0, 'Never used (0 pts)'),
  pastQuit(1, 'Used in past / Quit (+1 pt)'),
  currentDaily(2, 'Current / Daily tobacco consumer (+2 pts)');

  final int score;
  final String label;
  const TobaccoUse(this.score, this.label);
}

/// Alcohol consumption risk factor.
enum AlcoholConsumption {
  no(0, 'No / Never consumes (0 pts)'),
  yes(1, 'Yes / Consumes alcohol (+1 pt)');

  final int score;
  final String label;
  const AlcoholConsumption(this.score, this.label);
}

/// Physical activity risk factor (minimum 150 min/week).
enum PhysicalActivity {
  atLeast150Mins(0, 'At least 150 mins/week / >= 30 mins for 5 days (0 pts)'),
  lessThan150Mins(1, 'Less than 150 mins/week / sedentary (+1 pt)');

  final int score;
  final String label;
  const PhysicalActivity(this.score, this.label);
}

/// Family history of high BP, diabetes, or heart disease.
enum FamilyHistoryNcd {
  no(0, 'No family history (0 pts)'),
  yes(2, 'Yes (parent or sibling has high BP, diabetes, or stroke) (+2 pts)');

  final int score;
  final String label;
  const FamilyHistoryNcd(this.score, this.label);
}

/// Clinical classification of Blood Pressure per National NCD guidelines (MoHFW).
enum BloodPressureCategory {
  normal('Normal BP (<120 / <80 mmHg)', TriageFlag.green),
  prehypertension('Pre-hypertension (120-139 / 80-89 mmHg)', TriageFlag.yellow),
  stage1Hypertension('Stage 1 Hypertension (140-159 / 90-99 mmHg)', TriageFlag.yellow),
  stage2Hypertension('Stage 2 Hypertension (160-179 / 100-109 mmHg)', TriageFlag.yellow),
  hypertensiveCrisis('Hypertensive Crisis (>=180 / >=110 mmHg) - URGENT', TriageFlag.red);

  final String label;
  final TriageFlag triageFlag;
  const BloodPressureCategory(this.label, this.triageFlag);
}

/// Blood glucose test type.
enum GlucoseType {
  random('Random Blood Sugar (RBS)'),
  fasting('Fasting Blood Sugar (FBS)'),
  postPrandial('Post-Prandial Blood Sugar (PPBS)');

  final String label;
  const GlucoseType(this.label);
}

/// Clinical classification of Blood Glucose per National NCD guidelines (MoHFW).
enum BloodGlucoseCategory {
  normal('Normal Glucose', TriageFlag.green),
  prediabetes('Pre-diabetes / Impaired Glucose', TriageFlag.yellow),
  suspectedDiabetes('Suspected Diabetes (Requires PHC Confirmation)', TriageFlag.yellow),
  severeHyperglycemia('Severe Hyperglycemia (>= 300 mg/dL) - URGENT', TriageFlag.red),
  severeHypoglycemia('Severe Hypoglycemia (< 54 mg/dL) - URGENT', TriageFlag.red);

  final String label;
  final TriageFlag triageFlag;
  const BloodGlucoseCategory(this.label, this.triageFlag);
}

/// Early warning symptoms suggestive of cancer (Part B of CBAC).
class CancerWarningSigns {
  // Oral Cancer Warning Signs
  final bool oralUlcerGt2Weeks;
  final bool oralRedWhitePatch;
  final bool oralDifficultyChewingOpeningMouth;
  final bool oralUnexplainedGrowth;

  // Breast Cancer Warning Signs (Women)
  final bool breastLump;
  final bool breastBloodStainedDischarge;
  final bool breastShapeChange;
  final bool breastSkinDimpling;

  // Cervical Cancer Warning Signs (Women)
  final bool cervicalBleedingBetweenPeriods;
  final bool cervicalPostCoitalBleeding;
  final bool cervicalPostMenopausalBleeding;
  final bool cervicalFoulDischarge;

  // Other Chronic Signs
  final bool persistentCoughGt2Weeks;
  final bool chronicShortnessOfBreath;
  final bool bloodInSputum;
  final bool bloodInUrineOrStool;
  final bool historyOfFitsOrFainting;

  const CancerWarningSigns({
    this.oralUlcerGt2Weeks = false,
    this.oralRedWhitePatch = false,
    this.oralDifficultyChewingOpeningMouth = false,
    this.oralUnexplainedGrowth = false,
    this.breastLump = false,
    this.breastBloodStainedDischarge = false,
    this.breastShapeChange = false,
    this.breastSkinDimpling = false,
    this.cervicalBleedingBetweenPeriods = false,
    this.cervicalPostCoitalBleeding = false,
    this.cervicalPostMenopausalBleeding = false,
    this.cervicalFoulDischarge = false,
    this.persistentCoughGt2Weeks = false,
    this.chronicShortnessOfBreath = false,
    this.bloodInSputum = false,
    this.bloodInUrineOrStool = false,
    this.historyOfFitsOrFainting = false,
  });

  bool get hasOralCancerSigns =>
      oralUlcerGt2Weeks || oralRedWhitePatch || oralDifficultyChewingOpeningMouth || oralUnexplainedGrowth;

  bool get hasBreastCancerSigns =>
      breastLump || breastBloodStainedDischarge || breastShapeChange || breastSkinDimpling;

  bool get hasCervicalCancerSigns =>
      cervicalBleedingBetweenPeriods ||
      cervicalPostCoitalBleeding ||
      cervicalPostMenopausalBleeding ||
      cervicalFoulDischarge;

  bool get hasAnyCancerSign => hasOralCancerSigns || hasBreastCancerSigns || hasCervicalCancerSigns;

  bool get hasAnyWarningSign =>
      hasAnyCancerSign ||
      persistentCoughGt2Weeks ||
      chronicShortnessOfBreath ||
      bloodInSputum ||
      bloodInUrineOrStool ||
      historyOfFitsOrFainting;

  List<String> get activeFindings {
    final list = <String>[];
    if (oralUlcerGt2Weeks) list.add('Oral: Non-healing mouth ulcer > 2 weeks');
    if (oralRedWhitePatch) list.add('Oral: White or red patch inside mouth');
    if (oralDifficultyChewingOpeningMouth) list.add('Oral: Difficulty in opening mouth or chewing');
    if (oralUnexplainedGrowth) list.add('Oral: Unexplained growth/swelling in mouth or neck');

    if (breastLump) list.add('Breast: Palpable lump in breast');
    if (breastBloodStainedDischarge) list.add('Breast: Blood-stained or serous nipple discharge');
    if (breastShapeChange) list.add('Breast: Noticeable change in breast size/shape');
    if (breastSkinDimpling) list.add('Breast: Skin dimpling, puckering or nipple retraction');

    if (cervicalBleedingBetweenPeriods) list.add('Cervix: Abnormal bleeding between menstrual periods');
    if (cervicalPostCoitalBleeding) list.add('Cervix: Post-coital bleeding');
    if (cervicalPostMenopausalBleeding) list.add('Cervix: Post-menopausal vaginal bleeding');
    if (cervicalFoulDischarge) list.add('Cervix: Persistent foul-smelling vaginal discharge');

    if (persistentCoughGt2Weeks) list.add('Chronic cough > 2 weeks (Presumptive TB/Respiratory)');
    if (chronicShortnessOfBreath) list.add('Chronic shortness of breath/wheezing');
    if (bloodInSputum) list.add('Haemoptysis (blood in sputum)');
    if (bloodInUrineOrStool) list.add('Blood observed in stool or urine');
    if (historyOfFitsOrFainting) list.add('History of seizures/fits or sudden fainting spells');

    return list;
  }

  Map<String, dynamic> toJson() => {
        'oral_ulcer': oralUlcerGt2Weeks,
        'oral_patch': oralRedWhitePatch,
        'oral_difficulty': oralDifficultyChewingOpeningMouth,
        'oral_growth': oralUnexplainedGrowth,
        'breast_lump': breastLump,
        'breast_discharge': breastBloodStainedDischarge,
        'breast_shape': breastShapeChange,
        'breast_dimpling': breastSkinDimpling,
        'cervical_intermenstrual': cervicalBleedingBetweenPeriods,
        'cervical_postcoital': cervicalPostCoitalBleeding,
        'cervical_postmenopausal': cervicalPostMenopausalBleeding,
        'cervical_foul_discharge': cervicalFoulDischarge,
        'persistent_cough': persistentCoughGt2Weeks,
        'shortness_of_breath': chronicShortnessOfBreath,
        'blood_in_sputum': bloodInSputum,
        'blood_in_stool_urine': bloodInUrineOrStool,
        'history_of_fits': historyOfFitsOrFainting,
      };
}

/// Full CBAC Screening Assessment record (Requirement 19.1 – 19.3).
class CbacAssessment {
  final String id;
  final String memberId;
  final DateTime screenedAt;
  final int ageYears;
  final String sex; // 'M' or 'F'
  final CbacAgeBand ageBand;
  final TobaccoUse tobaccoUse;
  final AlcoholConsumption alcoholConsumption;
  final double waistCircumferenceCm;
  final int waistScore;
  final PhysicalActivity physicalActivity;
  final FamilyHistoryNcd familyHistory;
  final int totalCbacScore; // 0 to 10
  final bool isHighRiskScore; // score > 4 (Requirement 19.1)

  final CancerWarningSigns warningSigns;

  // Direct readings
  final int? systolicBp;
  final int? diastolicBp;
  final BloodPressureCategory? bpCategory;
  final double? bloodGlucoseMgDl;
  final GlucoseType? glucoseType;
  final BloodGlucoseCategory? glucoseCategory;

  // Triage evaluation
  final TriageFlag triageFlag;
  final List<String> clinicalFindings;
  final List<String> recommendedActions;
  final String? referralDestination;

  const CbacAssessment({
    required this.id,
    required this.memberId,
    required this.screenedAt,
    required this.ageYears,
    required this.sex,
    required this.ageBand,
    required this.tobaccoUse,
    required this.alcoholConsumption,
    required this.waistCircumferenceCm,
    required this.waistScore,
    required this.physicalActivity,
    required this.familyHistory,
    required this.totalCbacScore,
    required this.isHighRiskScore,
    required this.warningSigns,
    this.systolicBp,
    this.diastolicBp,
    this.bpCategory,
    this.bloodGlucoseMgDl,
    this.glucoseType,
    this.glucoseCategory,
    required this.triageFlag,
    required this.clinicalFindings,
    required this.recommendedActions,
    this.referralDestination,
  });

  bool get requiresFacilityConfirmation =>
      isHighRiskScore ||
      warningSigns.hasAnyWarningSign ||
      (bpCategory != null && bpCategory != BloodPressureCategory.normal) ||
      (glucoseCategory != null && glucoseCategory != BloodGlucoseCategory.normal);

  Map<String, dynamic> toJson() => {
        'id': id,
        'member_id': memberId,
        'screened_at': screenedAt.toIso8601String(),
        'age_years': ageYears,
        'sex': sex,
        'cbac_score': totalCbacScore,
        'is_high_risk': isHighRiskScore,
        'age_score': ageBand.score,
        'tobacco_score': tobaccoUse.score,
        'alcohol_score': alcoholConsumption.score,
        'waist_cm': waistCircumferenceCm,
        'waist_score': waistScore,
        'physical_activity_score': physicalActivity.score,
        'family_history_score': familyHistory.score,
        'warning_signs': warningSigns.toJson(),
        'systolic_bp': systolicBp,
        'diastolic_bp': diastolicBp,
        'bp_category': bpCategory?.name,
        'glucose_mg_dl': bloodGlucoseMgDl,
        'glucose_type': glucoseType?.name,
        'glucose_category': glucoseCategory?.name,
        'triage_flag': triageFlag.name,
        'clinical_findings': clinicalFindings,
        'recommended_actions': recommendedActions,
        'referral_destination': referralDestination,
      };
}

/// Confirmed NCD disease status.
enum NcdDiagnosisType {
  hypertension('Hypertension'),
  diabetes('Diabetes Mellitus (Type 2)'),
  both('Hypertension & Diabetes (Co-morbid)'),
  cancerOral('Oral Cancer'),
  cancerBreast('Breast Cancer'),
  cancerCervical('Cervical Cancer'),
  other('Other Chronic Disease');

  final String label;
  const NcdDiagnosisType(this.label);
}

/// Medication adherence level.
enum MedicationAdherence {
  regular('Regular (Taking daily as prescribed)'),
  irregular('Irregular (Missed doses in last week)'),
  discontinued('Discontinued / Stopped taking medicines');

  final String label;
  const MedicationAdherence(this.label);
}

/// Enrolled NCD patient in chronic care register (Requirement 19.4).
class NcdPatientRecord {
  final String id;
  final String memberId;
  final String beneficiaryName;
  final String hamlet;
  final NcdDiagnosisType diagnosis;
  final DateTime enrolledAt;
  final List<String> prescribedMedications;
  final DateTime lastVisitDate;
  final DateTime nextRefillDueDate;
  final DateTime nextCheckupDueDate;
  final int? lastSystolic;
  final int? lastDiastolic;
  final double? lastGlucoseMgDl;
  final MedicationAdherence lastAdherence;
  final bool isOverdueForRefill;
  final bool isOverdueForCheckup;

  const NcdPatientRecord({
    required this.id,
    required this.memberId,
    required this.beneficiaryName,
    required this.hamlet,
    required this.diagnosis,
    required this.enrolledAt,
    required this.prescribedMedications,
    required this.lastVisitDate,
    required this.nextRefillDueDate,
    required this.nextCheckupDueDate,
    this.lastSystolic,
    this.lastDiastolic,
    this.lastGlucoseMgDl,
    this.lastAdherence = MedicationAdherence.regular,
    this.isOverdueForRefill = false,
    this.isOverdueForCheckup = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'member_id': memberId,
        'beneficiary_name': beneficiaryName,
        'hamlet': hamlet,
        'diagnosis': diagnosis.name,
        'enrolled_at': enrolledAt.toIso8601String(),
        'prescribed_medications': prescribedMedications,
        'last_visit_date': lastVisitDate.toIso8601String(),
        'next_refill_due_date': nextRefillDueDate.toIso8601String(),
        'next_checkup_due_date': nextCheckupDueDate.toIso8601String(),
        'last_systolic': lastSystolic,
        'last_diastolic': lastDiastolic,
        'last_glucose': lastGlucoseMgDl,
        'last_adherence': lastAdherence.name,
        'is_overdue_refill': isOverdueForRefill,
        'is_overdue_checkup': isOverdueForCheckup,
      };
}

/// NCD Follow-Up Visit Record (Requirement 19.4).
class NcdFollowUpRecord {
  final String encounterId;
  final String memberId;
  final DateTime visitDate;
  final int? systolicBp;
  final int? diastolicBp;
  final double? bloodGlucoseMgDl;
  final GlucoseType? glucoseType;
  final MedicationAdherence adherence;
  final bool medicinesRefilled;
  final int daysOfRefillProvided;
  final String? sideEffectsNoted;
  final List<String> lifestyleCounsellingTopics;
  final String ashaId;

  const NcdFollowUpRecord({
    required this.encounterId,
    required this.memberId,
    required this.visitDate,
    this.systolicBp,
    this.diastolicBp,
    this.bloodGlucoseMgDl,
    this.glucoseType,
    required this.adherence,
    this.medicinesRefilled = false,
    this.daysOfRefillProvided = 30,
    this.sideEffectsNoted,
    this.lifestyleCounsellingTopics = const [],
    required this.ashaId,
  });

  Map<String, dynamic> toJson() => {
        'encounter_id': encounterId,
        'member_id': memberId,
        'visit_date': visitDate.toIso8601String(),
        'systolic_bp': systolicBp,
        'diastolic_bp': diastolicBp,
        'blood_glucose_mg_dl': bloodGlucoseMgDl,
        'glucose_type': glucoseType?.name,
        'adherence': adherence.name,
        'medicines_refilled': medicinesRefilled,
        'days_of_refill_provided': daysOfRefillProvided,
        'side_effects': sideEffectsNoted,
        'counselling_topics': lifestyleCounsellingTopics,
        'asha_id': ashaId,
      };
}

/// Topics for Lifestyle Counselling (Requirement 19.7).
enum LifestyleTopic {
  tobaccoCessation(
    'Tobacco Cessation',
    'Say NO to Bidi, Gutkha, Khaini, and cigarettes. Tobacco narrows blood vessels and increases heart attack risk 3-fold.',
  ),
  alcoholReduction(
    'Alcohol Reduction',
    'Avoid alcohol consumption. Excess alcohol increases blood pressure and damages liver and pancreas function.',
  ),
  healthyDiet(
    'Healthy Balanced Diet',
    'Eat more green leafy vegetables, seasonal fruits, and whole grains. Avoid deep-fried snacks (samosas/pakoras) and refined flour.',
  ),
  saltReduction(
    'Salt Reduction (<5g/day)',
    'Limit daily salt intake to less than 1 level teaspoon (5 grams). Avoid papads, pickles, and packaged salted snacks.',
  ),
  physicalActivity(
    'Daily Physical Activity',
    'Walk briskly or do farming/yoga for at least 30 minutes every day (minimum 150 minutes a week).',
  );

  final String title;
  final String guidance;
  const LifestyleTopic(this.title, this.guidance);
}
