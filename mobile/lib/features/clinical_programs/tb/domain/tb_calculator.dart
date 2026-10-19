import '../../../../core/triage/models/models.dart';
import 'tb_models.dart';

/// Pure clinical calculator implementing MoHFW National Tuberculosis Elimination Programme
/// (NTEP) guidelines for Presumptive TB triage, Sputum tracking, TPT eligibility, and Adherence.
///
/// Implements Requirements 20.1, 20.4, 20.5.
class TbCalculator {
  /// Evaluates presumptive TB symptoms and computes triage flag & recommended actions (Requirement 20.1).
  static PresumptiveTbAssessment evaluatePresumptiveTb({
    required String id,
    required String memberId,
    required DateTime screenedAt,
    bool coughGt2Weeks = false,
    bool feverGt2Weeks = false,
    bool unexplainedWeightLoss = false,
    bool nightSweats = false,
    bool haemoptysis = false,
    bool chestPain = false,
    bool contactWithKnownTbPatient = false,
  }) {
    final findings = <String>[];
    final actions = <String>[];
    TriageFlag flag = TriageFlag.green;

    // 1. Check for RED flags (Emergency symptoms)
    if (haemoptysis) {
      flag = TriageFlag.red;
      findings.add('Haemoptysis (blood in sputum) present — high risk of pulmonary haemorrhage');
      actions.add('Arrange urgent referral (108 Ambulance) to District Hospital / CHC Chest Department');
      actions.add('Advise patient to sit upright quietly; do NOT suppress cough with heavy sedatives');
    }

    // 2. Check for Presumptive TB (YELLOW flag)
    final isPresumptive =
        coughGt2Weeks || (feverGt2Weeks && (unexplainedWeightLoss || nightSweats)) || contactWithKnownTbPatient;

    if (flag != TriageFlag.red && isPresumptive) {
      flag = TriageFlag.yellow;

      if (coughGt2Weeks) {
        findings.add('Persistent cough of 2 or more weeks duration');
      }
      if (feverGt2Weeks) {
        findings.add('Unexplained low-grade fever > 2 weeks');
      }
      if (unexplainedWeightLoss) {
        findings.add('Significant unexplained weight loss / poor appetite');
      }
      if (nightSweats) {
        findings.add('Drenching night sweats reported');
      }
      if (chestPain) {
        findings.add('Pleuritic chest pain reported');
      }
      if (contactWithKnownTbPatient) {
        findings.add('Close contact with active pulmonary TB patient');
      }

      actions.add('Collect 2 sputum samples (spot & early morning) in NTEP falcon falcon cups');
      actions.add('Refer for rapid molecular testing: NAAT (Truenat / CBNAAT) or AFB sputum smear at DMC');
      actions.add('Advise cough hygiene (covering mouth with handkerchief/cloth) and adequate room ventilation');
      actions.add('Inform patient that all TB diagnostics and medications are 100% FREE under NTEP');
    }

    if (flag == TriageFlag.green) {
      findings.add('No cardinal signs of tuberculosis identified (cough < 2 weeks, no fever or weight loss)');
      actions.add('Provide routine symptomatic care; instruct to return if cough persists beyond 2 weeks');
    }

    return PresumptiveTbAssessment(
      id: id,
      memberId: memberId,
      screenedAt: screenedAt,
      coughGt2Weeks: coughGt2Weeks,
      feverGt2Weeks: feverGt2Weeks,
      unexplainedWeightLoss: unexplainedWeightLoss,
      nightSweats: nightSweats,
      haemoptysis: haemoptysis,
      chestPain: chestPain,
      contactWithKnownTbPatient: contactWithKnownTbPatient,
      triageFlag: flag,
      clinicalFindings: findings,
      recommendedActions: actions,
    );
  }

  /// Determines TB Preventive Therapy (TPT) eligibility for household contacts (Requirement 20.5).
  ///
  /// Per current NTEP guidelines:
  /// - Contacts with symptoms are NOT eligible for TPT; they must be evaluated for active TB disease.
  /// - Asymptomatic contacts < 5 years: unconditionally eligible for TPT after ruling out active TB.
  /// - Asymptomatic contacts >= 5 years: eligible for TPT after clinical and chest X-ray evaluation.
  static bool isEligibleForTpt({
    required int ageYears,
    required bool hasSymptoms,
  }) {
    if (hasSymptoms) {
      // Must test for active disease first
      return false;
    }
    // All asymptomatic household contacts of pulmonary TB cases are eligible
    return true;
  }

  /// Checks if consecutive missed doses breaches alert threshold (Requirement 20.4).
  /// Default threshold is 3 consecutive missed doses.
  static bool checkConsecutiveMissAlert({
    required int consecutiveMissedCount,
    int alertThreshold = 3,
  }) {
    return consecutiveMissedCount >= alertThreshold;
  }
}
