import 'package:flutter/foundation.dart';

@immutable
class AdolescentRecord {
  final String id;
  final String memberId;
  final int ageYears;
  final String gender;
  final bool isInSchool;
  final bool receivedMenstrualHygieneCounselling;
  final int wifsTabletsDispensed; // Blue weekly IFA tablets
  final int sanitaryNapkinPacksDispensed;
  final bool referredToAfhc; // Adolescent Friendly Health Clinic (Ujala Clinic)
  final DateTime recordedAt;

  const AdolescentRecord({
    required this.id,
    required this.memberId,
    required this.ageYears,
    required this.gender,
    required this.isInSchool,
    required this.receivedMenstrualHygieneCounselling,
    required this.wifsTabletsDispensed,
    required this.sanitaryNapkinPacksDispensed,
    required this.referredToAfhc,
    required this.recordedAt,
  });
}

@immutable
class ElderlyPalliativeRecord {
  final String id;
  final String memberId;
  final int ageYears;
  final String mobilityStatus; // 'independent', 'assisted', 'bedridden'
  final List<String> chronicConditions;
  final int visitIntervalDays; // default 14 or 30 days
  final DateTime lastVisitDate;
  final DateTime nextDueDate;
  final bool hasPressureUlcers;
  final String caregiverName;

  const ElderlyPalliativeRecord({
    required this.id,
    required this.memberId,
    required this.ageYears,
    required this.mobilityStatus,
    required this.chronicConditions,
    required this.visitIntervalDays,
    required this.lastVisitDate,
    required this.nextDueDate,
    required this.hasPressureUlcers,
    required this.caregiverName,
  });
}

@immutable
class MentalHealthScreeningResult {
  final String id;
  final String memberId;
  final DateTime screenedAt;
  final int phq4Score; // 0 to 12
  final int anxietySubscore; // 0 to 6
  final int depressionSubscore; // 0 to 6
  final bool hasSelfHarmIdeation;
  final String triageFlag; // 'GREEN', 'YELLOW', 'RED'
  final String recommendation;
  final Map<String, String> helplineNumbers;

  const MentalHealthScreeningResult({
    required this.id,
    required this.memberId,
    required this.screenedAt,
    required this.phq4Score,
    required this.anxietySubscore,
    required this.depressionSubscore,
    required this.hasSelfHarmIdeation,
    required this.triageFlag,
    required this.recommendation,
    required this.helplineNumbers,
  });
}

@immutable
class DisabilityRecord {
  final String id;
  final String memberId;
  final String disabilityType; // 'locomotor', 'visual', 'hearing_speech', 'intellectual', 'multiple'
  final int percentageSeverity;
  final String? udidNumber; // Unique Disability ID
  final List<String> linkedGovernmentSchemes;
  final DateTime registeredAt;

  const DisabilityRecord({
    required this.id,
    required this.memberId,
    required this.disabilityType,
    required this.percentageSeverity,
    this.udidNumber,
    required this.linkedGovernmentSchemes,
    required this.registeredAt,
  });
}

@immutable
class CommunityActivityLog {
  final String id;
  final String activityType; // 'household_survey', 'awareness_session', 'sanitation_drive', 'vhsnc_meeting'
  final DateTime activityDate;
  final String hamletName;
  final int participantCount;
  final String topicCovered;
  final String actionPointsOrNotes;
  final bool rolledUpToAfDashboard;

  const CommunityActivityLog({
    required this.id,
    required this.activityType,
    required this.activityDate,
    required this.hamletName,
    required this.participantCount,
    required this.topicCovered,
    required this.actionPointsOrNotes,
    this.rolledUpToAfDashboard = false,
  });
}

@immutable
class OtaProgramModule {
  final String moduleKey;
  final String version;
  final String programTitle;
  final Map<String, dynamic> formSchema;
  final Map<String, dynamic> scheduleRules;
  final bool isActive;

  const OtaProgramModule({
    required this.moduleKey,
    required this.version,
    required this.programTitle,
    required this.formSchema,
    required this.scheduleRules,
    this.isActive = true,
  });
}
