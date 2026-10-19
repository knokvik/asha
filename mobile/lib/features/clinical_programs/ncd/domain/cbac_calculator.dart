import '../../../../core/triage/models/models.dart';
import 'cbac_models.dart';

/// Pure clinical calculator implementing official MoHFW NHM CBAC scoring rules,
/// National NCD Guidelines for Hypertension & Diabetes, and National Cancer Screening.
///
/// Implements Requirements 19.1 – 19.3, 19.6.
class CbacCalculator {
  /// Computes waist circumference score according to sex-specific cutoffs.
  ///
  /// Female: <= 80 cm (0), 81 - 90 cm (1), > 90 cm (2)
  /// Male: <= 90 cm (0), 91 - 100 cm (1), > 100 cm (2)
  static int computeWaistScore({
    required double waistCm,
    required String sex,
  }) {
    final isFemale = sex.toUpperCase() == 'F';

    if (isFemale) {
      if (waistCm <= 80.0) return 0;
      if (waistCm <= 90.0) return 1;
      return 2;
    } else {
      if (waistCm <= 90.0) return 0;
      if (waistCm <= 100.0) return 1;
      return 2;
    }
  }

  /// Calculates total CBAC Risk Assessment score (0 to 10 points).
  static int computeTotalCbacScore({
    required int ageYears,
    required TobaccoUse tobaccoUse,
    required AlcoholConsumption alcoholConsumption,
    required double waistCircumferenceCm,
    required String sex,
    required PhysicalActivity physicalActivity,
    required FamilyHistoryNcd familyHistory,
  }) {
    final ageBand = CbacAgeBand.fromAge(ageYears);
    final waistScore = computeWaistScore(waistCm: waistCircumferenceCm, sex: sex);

    final total = ageBand.score +
        tobaccoUse.score +
        alcoholConsumption.score +
        waistScore +
        physicalActivity.score +
        familyHistory.score;

    return total.clamp(0, 10);
  }

  /// Classifies Blood Pressure per National NCD Management Guidelines (MoHFW).
  static BloodPressureCategory classifyBloodPressure({
    required int systolic,
    required int diastolic,
  }) {
    if (systolic >= 180 || diastolic >= 110) {
      return BloodPressureCategory.hypertensiveCrisis;
    }
    if (systolic >= 160 || diastolic >= 100) {
      return BloodPressureCategory.stage2Hypertension;
    }
    if (systolic >= 140 || diastolic >= 90) {
      return BloodPressureCategory.stage1Hypertension;
    }
    if ((systolic >= 120 && systolic <= 139) || (diastolic >= 80 && diastolic <= 89)) {
      return BloodPressureCategory.prehypertension;
    }
    return BloodPressureCategory.normal;
  }

  /// Classifies Blood Glucose per National NCD Management Guidelines (MoHFW).
  static BloodGlucoseCategory classifyBloodGlucose({
    required double glucoseMgDl,
    required GlucoseType type,
  }) {
    if (glucoseMgDl < 54.0) {
      return BloodGlucoseCategory.severeHypoglycemia;
    }
    if (glucoseMgDl >= 300.0) {
      return BloodGlucoseCategory.severeHyperglycemia;
    }

    if (type == GlucoseType.fasting) {
      // Fasting Blood Sugar
      if (glucoseMgDl >= 126.0) {
        return BloodGlucoseCategory.suspectedDiabetes;
      }
      if (glucoseMgDl >= 100.0) {
        return BloodGlucoseCategory.prediabetes;
      }
      return BloodGlucoseCategory.normal;
    } else {
      // Random or Post-Prandial Blood Sugar
      if (glucoseMgDl >= 200.0) {
        return BloodGlucoseCategory.suspectedDiabetes;
      }
      if (glucoseMgDl >= 140.0) {
        return BloodGlucoseCategory.prediabetes;
      }
      return BloodGlucoseCategory.normal;
    }
  }

  /// Comprehensive offline evaluation of CBAC assessment (Requirement 19.1 – 19.3).
  static CbacAssessment evaluateAssessment({
    required String id,
    required String memberId,
    required DateTime screenedAt,
    required int ageYears,
    required String sex,
    required TobaccoUse tobaccoUse,
    required AlcoholConsumption alcoholConsumption,
    required double waistCircumferenceCm,
    required PhysicalActivity physicalActivity,
    required FamilyHistoryNcd familyHistory,
    required CancerWarningSigns warningSigns,
    int? systolicBp,
    int? diastolicBp,
    double? bloodGlucoseMgDl,
    GlucoseType? glucoseType,
  }) {
    final ageBand = CbacAgeBand.fromAge(ageYears);
    final waistScore = computeWaistScore(waistCm: waistCircumferenceCm, sex: sex);
    final totalCbacScore = computeTotalCbacScore(
      ageYears: ageYears,
      tobaccoUse: tobaccoUse,
      alcoholConsumption: alcoholConsumption,
      waistCircumferenceCm: waistCircumferenceCm,
      sex: sex,
      physicalActivity: physicalActivity,
      familyHistory: familyHistory,
    );
    final isHighRiskScore = totalCbacScore > 4; // Requirement 19.1: score > 4

    BloodPressureCategory? bpCategory;
    if (systolicBp != null && diastolicBp != null) {
      bpCategory = classifyBloodPressure(systolic: systolicBp, diastolic: diastolicBp);
    }

    BloodGlucoseCategory? glucoseCategory;
    if (bloodGlucoseMgDl != null && glucoseType != null) {
      glucoseCategory = classifyBloodGlucose(glucoseMgDl: bloodGlucoseMgDl, type: glucoseType);
    }

    // Triage determinations
    final findings = <String>[];
    final actions = <String>[];
    TriageFlag flag = TriageFlag.green;
    String? referralDestination;

    // Check RED urgency conditions
    if (bpCategory == BloodPressureCategory.hypertensiveCrisis) {
      flag = TriageFlag.red;
      findings.add('Hypertensive Crisis (BP $systolicBp/$diastolicBp mmHg) — immediate risk of stroke or heart failure');
      actions.add('Arrange immediate emergency transport (108 Ambulance) to CHC or District Hospital');
      actions.add('Advise patient to sit upright quietly; do NOT administer unprescribed drugs');
      referralDestination = 'CHC / District Hospital Emergency';
    }

    if (glucoseCategory == BloodGlucoseCategory.severeHyperglycemia) {
      flag = TriageFlag.red;
      findings.add('Severe Hyperglycemia (Glucose ${bloodGlucoseMgDl?.toStringAsFixed(0)} mg/dL) — risk of Diabetic Ketoacidosis (DKA)');
      actions.add('Refer immediately to CHC/Hospital for intravenous fluids and insulin therapy');
      referralDestination = 'CHC / District Hospital';
    } else if (glucoseCategory == BloodGlucoseCategory.severeHypoglycemia) {
      flag = TriageFlag.red;
      findings.add('Severe Hypoglycemia (Glucose ${bloodGlucoseMgDl?.toStringAsFixed(0)} mg/dL) — danger of hypoglycemic coma');
      actions.add('Administer oral sugar / glucose water immediately if conscious; refer urgently to health facility');
      referralDestination = 'PHC / CHC Emergency';
    }

    if (warningSigns.bloodInSputum) {
      if (flag != TriageFlag.red) flag = TriageFlag.red;
      findings.add('Haemoptysis (blood in sputum) noted');
      actions.add('Urgent chest physician referral and TB sputum examination');
      referralDestination ??= 'CHC / District TB Centre';
    }

    // Check YELLOW conditions if not already RED
    if (flag != TriageFlag.red) {
      if (isHighRiskScore) {
        flag = TriageFlag.yellow;
        findings.add('CBAC Score is $totalCbacScore/10 (High Risk > 4) — priority confirmatory NCD screening needed');
        actions.add('Refer to Primary Health Centre (PHC) / Ayushman Arogya Mandir (HWC) for confirmation');
        referralDestination ??= 'Ayushman Arogya Mandir (HWC) / PHC';
      }

      if (warningSigns.hasOralCancerSigns) {
        flag = TriageFlag.yellow;
        findings.add('Oral cancer warning signs present: ${warningSigns.activeFindings.where((f) => f.startsWith("Oral")).join(", ")}');
        actions.add('Refer to Medical Officer for visual examination of oral cavity (oral cancer screening)');
        referralDestination ??= 'Ayushman Arogya Mandir (HWC) / PHC Dental Clinic';
      }

      if (warningSigns.hasBreastCancerSigns) {
        flag = TriageFlag.yellow;
        findings.add('Breast cancer warning signs present: ${warningSigns.activeFindings.where((f) => f.startsWith("Breast")).join(", ")}');
        actions.add('Refer to Lady Medical Officer / Gynaecologist for Clinical Breast Examination (CBE)');
        referralDestination ??= 'PHC / CHC Gynaecology';
      }

      if (warningSigns.hasCervicalCancerSigns) {
        flag = TriageFlag.yellow;
        findings.add('Cervical cancer warning signs present: ${warningSigns.activeFindings.where((f) => f.startsWith("Cervix")).join(", ")}');
        actions.add('Refer for pelvic examination and Visual Inspection with Acetic Acid (VIA)');
        referralDestination ??= 'PHC / CHC Gynaecology';
      }

      if (warningSigns.persistentCoughGt2Weeks) {
        flag = TriageFlag.yellow;
        findings.add('Chronic cough > 2 weeks: Presumptive TB case');
        actions.add('Collect or refer for sputum AFB / NAAT (CBNAAT/Truenat) examination');
        referralDestination ??= 'Designated Microscopy Centre (DMC) / PHC';
      }

      if (bpCategory == BloodPressureCategory.stage1Hypertension || bpCategory == BloodPressureCategory.stage2Hypertension) {
        flag = TriageFlag.yellow;
        findings.add('${bpCategory!.label} recorded (BP $systolicBp/$diastolicBp mmHg)');
        actions.add('Refer to Medical Officer for diagnosis confirmation and treatment initiation');
        referralDestination ??= 'Ayushman Arogya Mandir (HWC) / PHC';
      } else if (bpCategory == BloodPressureCategory.prehypertension) {
        findings.add('Pre-hypertension recorded (BP $systolicBp/$diastolicBp mmHg)');
        actions.add('Provide lifestyle counselling on low-salt diet and physical activity; recheck in 3 months');
      }

      if (glucoseCategory == BloodGlucoseCategory.suspectedDiabetes) {
        flag = TriageFlag.yellow;
        findings.add('Elevated blood glucose (${bloodGlucoseMgDl?.toStringAsFixed(0)} mg/dL, ${glucoseType?.label ?? ""}) — Suspected Diabetes');
        actions.add('Refer to Medical Officer for fasting blood sugar and HbA1c confirmatory test');
        referralDestination ??= 'Ayushman Arogya Mandir (HWC) / PHC';
      } else if (glucoseCategory == BloodGlucoseCategory.prediabetes) {
        findings.add('Pre-diabetes / Impaired glucose tolerance detected');
        actions.add('Provide intensive dietary and exercise counselling; repeat test in 3 months');
      }
    }

    if (flag == TriageFlag.green) {
      findings.add('CBAC Score is $totalCbacScore/10 (Low to Moderate Risk <= 4); no warning signs');
      actions.add('Provide routine lifestyle counselling (diet, physical activity, avoidance of tobacco & alcohol)');
      actions.add('Schedule annual CBAC rescreening');
    }

    return CbacAssessment(
      id: id,
      memberId: memberId,
      screenedAt: screenedAt,
      ageYears: ageYears,
      sex: sex,
      ageBand: ageBand,
      tobaccoUse: tobaccoUse,
      alcoholConsumption: alcoholConsumption,
      waistCircumferenceCm: waistCircumferenceCm,
      waistScore: waistScore,
      physicalActivity: physicalActivity,
      familyHistory: familyHistory,
      totalCbacScore: totalCbacScore,
      isHighRiskScore: isHighRiskScore,
      warningSigns: warningSigns,
      systolicBp: systolicBp,
      diastolicBp: diastolicBp,
      bpCategory: bpCategory,
      bloodGlucoseMgDl: bloodGlucoseMgDl,
      glucoseType: glucoseType,
      glucoseCategory: glucoseCategory,
      triageFlag: flag,
      clinicalFindings: findings,
      recommendedActions: actions,
      referralDestination: referralDestination,
    );
  }

  /// Generates CSV content compliant with the National NCD Application Portal (Requirement 19.6).
  static String generateNationalNcdPortalCsv(List<Map<String, dynamic>> records) {
    final buffer = StringBuffer();

    // Standard National NCD Portal Headers
    buffer.writeln(
      'Beneficiary_ID,Household_ID,Name,Age,Sex,Village,CBAC_Score,Risk_Level,'
      'Tobacco_Use,Alcohol_Use,Waist_CM,Physical_Activity,Family_History,'
      'Systolic_BP,Diastolic_BP,BP_Category,Glucose_Value,Glucose_Type,Glucose_Category,'
      'Oral_Cancer_Signs,Breast_Cancer_Signs,Cervical_Cancer_Signs,Cough_Gt_2W,'
      'Referral_Required,Referral_Destination,Screened_By_ASHA,Screened_Date',
    );

    for (final r in records) {
      final fields = [
        _csvEscape(r['member_id']?.toString() ?? ''),
        _csvEscape(r['household_id']?.toString() ?? ''),
        _csvEscape(r['name']?.toString() ?? ''),
        r['age']?.toString() ?? '',
        r['sex']?.toString() ?? '',
        _csvEscape(r['village']?.toString() ?? ''),
        r['cbac_score']?.toString() ?? '0',
        r['is_high_risk'] == true ? 'HIGH' : 'NORMAL',
        _csvEscape(r['tobacco']?.toString() ?? 'NEVER'),
        _csvEscape(r['alcohol']?.toString() ?? 'NO'),
        r['waist_cm']?.toString() ?? '',
        _csvEscape(r['physical_activity']?.toString() ?? ''),
        r['family_history'] == true ? 'YES' : 'NO',
        r['systolic_bp']?.toString() ?? '',
        r['diastolic_bp']?.toString() ?? '',
        _csvEscape(r['bp_category']?.toString() ?? ''),
        r['glucose_val']?.toString() ?? '',
        _csvEscape(r['glucose_type']?.toString() ?? ''),
        _csvEscape(r['glucose_category']?.toString() ?? ''),
        r['oral_signs'] == true ? 'YES' : 'NO',
        r['breast_signs'] == true ? 'YES' : 'NO',
        r['cervical_signs'] == true ? 'YES' : 'NO',
        r['cough_signs'] == true ? 'YES' : 'NO',
        r['referral_required'] == true ? 'YES' : 'NO',
        _csvEscape(r['referral_dest']?.toString() ?? ''),
        _csvEscape(r['asha_id']?.toString() ?? ''),
        _csvEscape(r['screened_date']?.toString() ?? ''),
      ];
      buffer.writeln(fields.join(','));
    }

    return buffer.toString();
  }

  static String _csvEscape(String val) {
    if (val.contains(',') || val.contains('"') || val.contains('\n')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }
}
