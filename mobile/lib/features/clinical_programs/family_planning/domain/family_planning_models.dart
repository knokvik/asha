import 'package:flutter/foundation.dart';

/// Contraceptive methods available under MoHFW National Family Planning Programme.
enum ContraceptiveMethod {
  condoms('Condoms (Nirodh)', isAshaDistributable: true, isPermanent: false),
  malaN('Oral Contraceptive Pills (Mala-N)', isAshaDistributable: true, isPermanent: false),
  chhaya('Non-hormonal Weekly Pills (Centchroman / Chhaya)', isAshaDistributable: true, isPermanent: false),
  ecp('Emergency Contraceptive Pills (E-Pill)', isAshaDistributable: true, isPermanent: false),
  antara('Injectable MPA (Antara)', isAshaDistributable: false, isPermanent: false),
  iucd380A('Interval IUCD (Copper-T 380A - 10 yr)', isAshaDistributable: false, isPermanent: false),
  iucd375('Interval IUCD (Cu-375 - 5 yr)', isAshaDistributable: false, isPermanent: false),
  ppiucd('Postpartum IUCD (PPIUCD within 48h of delivery)', isAshaDistributable: false, isPermanent: false),
  femaleSterilization('Female Sterilization (Minilap / Laparoscopic)', isAshaDistributable: false, isPermanent: true),
  maleSterilization('Male Sterilization (No-Scalpel Vasectomy - NSV)', isAshaDistributable: false, isPermanent: true),
  traditional('Natural / Traditional Spacing', isAshaDistributable: false, isPermanent: false),
  none('None / Unmet Need', isAshaDistributable: false, isPermanent: false);

  final String displayName;
  final bool isAshaDistributable;
  final bool isPermanent;

  const ContraceptiveMethod(
    this.displayName, {
    required this.isAshaDistributable,
    required this.isPermanent,
  });
}

/// Unmet need category for eligible couples (Requirement 18.1).
enum UnmetNeedType {
  none,
  spacing,  // Youngest child < 2 yrs or wants to delay next birth
  limiting, // Reached desired family size but not using modern method
}

@immutable
class EligibleCouple {
  final String coupleId;
  final String householdId;
  final String femaleMemberId;
  final String maleMemberId;
  final int femaleAge;
  final int parity; // number of living children
  final int youngestChildAgeMonths;
  final ContraceptiveMethod currentMethod;
  final bool wantsMoreChildren;
  final UnmetNeedType unmetNeed;

  const EligibleCouple({
    required this.coupleId,
    required this.householdId,
    required this.femaleMemberId,
    required this.maleMemberId,
    required this.femaleAge,
    required this.parity,
    required this.youngestChildAgeMonths,
    this.currentMethod = ContraceptiveMethod.none,
    this.wantsMoreChildren = true,
    this.unmetNeed = UnmetNeedType.none,
  });
}

@immutable
class ContraceptiveEducationCard {
  final ContraceptiveMethod method;
  final String title;
  final double effectivenessPercentage;
  final String eligibilityCriteria;
  final String commonSideEffects;
  final String audioPrompt;
  final String pictorialKey;
  final bool isAshaDistributable;

  const ContraceptiveEducationCard({
    required this.method,
    required this.title,
    required this.effectivenessPercentage,
    required this.eligibilityCriteria,
    required this.commonSideEffects,
    required this.audioPrompt,
    required this.pictorialKey,
    required this.isAshaDistributable,
  });
}

@immutable
class ContraceptiveDistributionRecord {
  final String id;
  final String memberId;
  final String coupleId;
  final ContraceptiveMethod method;
  final int quantity;
  final DateTime distributionDate;
  final DateTime nextRefillDate;
  final String stockItemId;
  final String batchNumber;

  const ContraceptiveDistributionRecord({
    required this.id,
    required this.memberId,
    required this.coupleId,
    required this.method,
    required this.quantity,
    required this.distributionDate,
    required this.nextRefillDate,
    required this.stockItemId,
    required this.batchNumber,
  });
}

@immutable
class FamilyPlanningSideEffectEvaluation {
  final ContraceptiveMethod method;
  final List<String> reportedSymptoms;
  final bool requiresImmediateReferral;
  final String triageFlag; // 'GREEN', 'YELLOW', 'RED'
  final String counsellingGuidance;
  final String recommendedFacility;

  const FamilyPlanningSideEffectEvaluation({
    required this.method,
    required this.reportedSymptoms,
    required this.requiresImmediateReferral,
    required this.triageFlag,
    required this.counsellingGuidance,
    required this.recommendedFacility,
  });
}
