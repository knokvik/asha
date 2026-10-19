import 'package:flutter/foundation.dart';

@immutable
class CivilBirthRecord {
  final String id;
  final String childMemberId;
  final String motherMemberId;
  final String fatherName;
  final DateTime dateOfBirth;
  final String timeOfBirth;
  final String placeOfBirth; // 'home', 'subcentre', 'phc', 'chc', 'district_hospital', 'private'
  final int birthWeightGrams;
  final String gender;
  final String deliveryType; // 'normal_vaginal', 'assisted', 'caesarean'
  final String crsHandoverSummary;

  const CivilBirthRecord({
    required this.id,
    required this.childMemberId,
    required this.motherMemberId,
    required this.fatherName,
    required this.dateOfBirth,
    required this.timeOfBirth,
    required this.placeOfBirth,
    required this.birthWeightGrams,
    required this.gender,
    required this.deliveryType,
    required this.crsHandoverSummary,
  });
}

@immutable
class CivilDeathRecord {
  final String id;
  final String deceasedMemberId;
  final DateTime dateOfDeath;
  final String placeOfDeath; // 'home', 'transit_to_facility', 'facility'
  final String presumedCauseOfDeath;
  final bool isMaternalDeath;
  final bool isInfantDeath;
  final bool isUnderFiveChildDeath;
  final String crsHandoverSummary;

  const CivilDeathRecord({
    required this.id,
    required this.deceasedMemberId,
    required this.dateOfDeath,
    required this.placeOfDeath,
    required this.presumedCauseOfDeath,
    required this.isMaternalDeath,
    required this.isInfantDeath,
    required this.isUnderFiveChildDeath,
    required this.crsHandoverSummary,
  });
}

@immutable
class DeathAuditReview {
  final String id;
  final String deceasedMemberId;
  final String auditType; // 'MATERNAL_DEATH_REVIEW' or 'CHILD_DEATH_REVIEW'
  final DateTime auditDate;
  final List<String> threeDelaysIdentified;
  final String primaryContributingCause;
  final bool supervisorAlertSent;
  final Map<String, dynamic> alertPayload;

  const DeathAuditReview({
    required this.id,
    required this.deceasedMemberId,
    required this.auditType,
    required this.auditDate,
    required this.threeDelaysIdentified,
    required this.primaryContributingCause,
    required this.supervisorAlertSent,
    required this.alertPayload,
  });
}

@immutable
class StillbirthAbortionRecord {
  final String id;
  final String motherMemberId;
  final DateTime eventDate;
  final String eventType; // 'stillbirth_fresh', 'stillbirth_macerated', 'spontaneous_loss', 'mtp_service'
  final int gestationalWeeks;
  final String neutralClinicalNotes;
  final String visibilityRestriction; // 'RESTRICTED_ASHA_ANM_MO_ONLY'

  const StillbirthAbortionRecord({
    required this.id,
    required this.motherMemberId,
    required this.eventDate,
    required this.eventType,
    required this.gestationalWeeks,
    required this.neutralClinicalNotes,
    this.visibilityRestriction = 'RESTRICTED_ASHA_ANM_MO_ONLY',
  });
}

@immutable
class VitalEventOutcome {
  final String householdId;
  final String memberId;
  final int updatedLivingMembersCount;
  final int cancelledPendingTasksCount;
  final String summaryMessage;
  final String crsHandoverSummary;

  const VitalEventOutcome({
    required this.householdId,
    required this.memberId,
    required this.updatedLivingMembersCount,
    required this.cancelledPendingTasksCount,
    required this.summaryMessage,
    this.crsHandoverSummary = '',
  });
}
