import 'package:flutter/foundation.dart';

enum MalariaSpecies {
  negative('Negative / No parasites detected'),
  plasmodiumFalciparum('Plasmodium falciparum (Pf)'),
  plasmodiumVivax('Plasmodium vivax (Pv)'),
  mixed('Mixed infection (Pf + Pv)');

  final String label;
  const MalariaSpecies(this.label);
}

enum SyndromeType {
  feverWithChills('Fever with Chills / Rigors'),
  feverWithRash('Fever with Rash (Measles/Rubella/Dengue suspect)'),
  acuteDiarrhoealDisease('Acute Diarrhoeal Disease (ADD / Cholera suspect)'),
  acuteFlaccidParalysis('Acute Flaccid Paralysis (AFP / Polio surveillance)'),
  jaundiceCluster('Acute Jaundice Syndrome (Hepatitis suspect)'),
  respiratoryDistress('Severe Acute Respiratory Illness (SARI)');

  final String label;
  const SyndromeType(this.label);
}

@immutable
class MalariaRdtRecord {
  final String id;
  final String memberId;
  final DateTime testDate;
  final MalariaSpecies resultSpecies;
  final bool isEndemicArea;
  final String treatmentRegimen;
  final bool requiresFacilityReferral;
  final String referralUrgency;

  const MalariaRdtRecord({
    required this.id,
    required this.memberId,
    required this.testDate,
    required this.resultSpecies,
    required this.isEndemicArea,
    required this.treatmentRegimen,
    required this.requiresFacilityReferral,
    required this.referralUrgency,
  });
}

@immutable
class SyndromicCase {
  final String id;
  final String memberId;
  final String hamletId;
  final SyndromeType syndrome;
  final DateTime reportedAt;
  final int ageYears;
  final String gender;

  const SyndromicCase({
    required this.id,
    required this.memberId,
    required this.hamletId,
    required this.syndrome,
    required this.reportedAt,
    required this.ageYears,
    required this.gender,
  });
}

@immutable
class OutbreakAlert {
  final String alertId;
  final String hamletId;
  final SyndromeType syndrome;
  final int caseCount;
  final int timeWindowDays;
  final String alertLevel; // 'WARNING' or 'OUTBREAK_CONFIRMED'
  final List<String> supervisorResponseChecklist;
  final Map<String, dynamic> syncPayload;
  final DateTime triggeredAt;

  const OutbreakAlert({
    required this.alertId,
    required this.hamletId,
    required this.syndrome,
    required this.caseCount,
    required this.timeWindowDays,
    required this.alertLevel,
    required this.supervisorResponseChecklist,
    required this.syncPayload,
    required this.triggeredAt,
  });
}

@immutable
class EmergencyBitePoisoningProtocol {
  final String eventType;
  final String title;
  final List<String> mandatoryFirstAidSteps;
  final List<String> strictlyForbiddenActions;
  final String referralDestination;
  final String helplineNumber;

  const EmergencyBitePoisoningProtocol({
    required this.eventType,
    required this.title,
    required this.mandatoryFirstAidSteps,
    required this.strictlyForbiddenActions,
    required this.referralDestination,
    required this.helplineNumber,
  });
}
