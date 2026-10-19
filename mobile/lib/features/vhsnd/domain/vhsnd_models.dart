/// Types of clinical and preventive health services delivered at VHSND (Requirement 27.1).
enum VhsndServiceType {
  immunization('immunization', 'Routine Child & Maternal Immunization'),
  anc('anc', 'Antenatal Health Checkup & MCP Review'),
  cbac('cbac', 'NCD / CBAC Risk Assessment'),
  familyPlanning('family_planning', 'Family Planning & Contraceptive Distribution'),
  nutritionCounseling('nutrition', 'Nutrition Counseling & Growth Monitoring'),
  adolescentHealth('adolescent', 'WIFS & Adolescent Health Support');

  final String code;
  final String label;
  const VhsndServiceType(this.code, this.label);

  static VhsndServiceType fromCode(String? code) {
    if (code == null) return VhsndServiceType.immunization;
    return VhsndServiceType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => VhsndServiceType.immunization,
    );
  }
}

/// Status of a planned VHSND session (Requirement 27.1, 27.2).
enum VhsndSessionStatus {
  planned,
  inProgress,
  completed,
  cancelled,
}

/// A beneficiary due for specific health services at an upcoming VHSND (Requirement 27.1).
class VhsndDueBeneficiary {
  final String memberId;
  final String memberName;
  final String householdId;
  final String hamlet;
  final String sex;
  final int? ageMonths;
  final VhsndServiceType serviceType;
  final String dueServiceDetails; // e.g. "Pentavalent 1 + Rota 1", "ANC-3 & Td Booster", "CBAC > 30 yrs"
  final bool isMobilised;
  final bool hasAttended;
  final List<String> servicesDelivered;
  final String? serviceGapNotes;
  final String? visitScheduleId;

  const VhsndDueBeneficiary({
    required this.memberId,
    required this.memberName,
    required this.householdId,
    required this.hamlet,
    required this.sex,
    this.ageMonths,
    required this.serviceType,
    required this.dueServiceDetails,
    this.isMobilised = false,
    this.hasAttended = false,
    this.servicesDelivered = const [],
    this.serviceGapNotes,
    this.visitScheduleId,
  });

  VhsndDueBeneficiary copyWith({
    bool? isMobilised,
    bool? hasAttended,
    List<String>? servicesDelivered,
    String? serviceGapNotes,
  }) {
    return VhsndDueBeneficiary(
      memberId: memberId,
      memberName: memberName,
      householdId: householdId,
      hamlet: hamlet,
      sex: sex,
      ageMonths: ageMonths,
      serviceType: serviceType,
      dueServiceDetails: dueServiceDetails,
      isMobilised: isMobilised ?? this.isMobilised,
      hasAttended: hasAttended ?? this.hasAttended,
      servicesDelivered: servicesDelivered ?? this.servicesDelivered,
      serviceGapNotes: serviceGapNotes ?? this.serviceGapNotes,
      visitScheduleId: visitScheduleId,
    );
  }

  Map<String, dynamic> toJson() => {
        'member_id': memberId,
        'member_name': memberName,
        'household_id': householdId,
        'hamlet': hamlet,
        'sex': sex,
        'age_months': ageMonths,
        'service_type': serviceType.code,
        'due_service_details': dueServiceDetails,
        'is_mobilised': isMobilised,
        'has_attended': hasAttended,
        'services_delivered': servicesDelivered,
        'service_gap_notes': serviceGapNotes,
        'visit_schedule_id': visitScheduleId,
      };

  factory VhsndDueBeneficiary.fromJson(Map<String, dynamic> json) => VhsndDueBeneficiary(
        memberId: json['member_id'] as String,
        memberName: json['member_name'] as String,
        householdId: json['household_id'] as String,
        hamlet: json['hamlet'] as String,
        sex: json['sex'] as String,
        ageMonths: json['age_months'] as int?,
        serviceType: VhsndServiceType.fromCode(json['service_type'] as String?),
        dueServiceDetails: json['due_service_details'] as String,
        isMobilised: json['is_mobilised'] as bool? ?? false,
        hasAttended: json['has_attended'] as bool? ?? false,
        servicesDelivered: (json['services_delivered'] as List<dynamic>?)?.cast<String>() ?? const [],
        serviceGapNotes: json['service_gap_notes'] as String?,
        visitScheduleId: json['visit_schedule_id'] as String?,
      );
}

/// Mobilisation checklist item for pre-session preparation (Requirement 27.1).
class MobilisationChecklistItem {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime? completedAt;

  const MobilisationChecklistItem({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.completedAt,
  });

  MobilisationChecklistItem copyWith({
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return MobilisationChecklistItem(
      id: id,
      title: title,
      description: description,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'is_completed': isCompleted,
        'completed_at': completedAt?.toIso8601String(),
      };

  factory MobilisationChecklistItem.fromJson(Map<String, dynamic> json) => MobilisationChecklistItem(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        isCompleted: json['is_completed'] as bool? ?? false,
        completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      );
}

/// A complete Village Health Sanitation and Nutrition Day session plan and record (Requirement 27.1, 27.2).
class VhsndSession {
  final String id;
  final String village;
  final String anganwadiCenter;
  final DateTime sessionDate;
  final VhsndSessionStatus status;
  final String anmName;
  final String ashaName;
  final String anganwadiWorkerName;
  final List<VhsndDueBeneficiary> beneficiaries;
  final List<MobilisationChecklistItem> mobilisationChecklist;
  final String? sessionSummaryNotes;
  final String? communityFeedbackNotes;
  final DateTime? completedAt;

  const VhsndSession({
    required this.id,
    required this.village,
    required this.anganwadiCenter,
    required this.sessionDate,
    this.status = VhsndSessionStatus.planned,
    required this.anmName,
    required this.ashaName,
    required this.anganwadiWorkerName,
    required this.beneficiaries,
    required this.mobilisationChecklist,
    this.sessionSummaryNotes,
    this.communityFeedbackNotes,
    this.completedAt,
  });

  int get totalMobilised => beneficiaries.where((b) => b.isMobilised).length;
  int get totalAttended => beneficiaries.where((b) => b.hasAttended).length;
  int get totalUnservedGaps => beneficiaries.where((b) => b.hasAttended && b.servicesDelivered.isEmpty).length;

  Map<VhsndServiceType, int> get attendancePerService {
    final map = <VhsndServiceType, int>{};
    for (final b in beneficiaries) {
      if (b.hasAttended) {
        map[b.serviceType] = (map[b.serviceType] ?? 0) + 1;
      }
    }
    return map;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'village': village,
        'anganwadi_center': anganwadiCenter,
        'session_date': sessionDate.toIso8601String(),
        'status': status.name,
        'anm_name': anmName,
        'asha_name': ashaName,
        'aww_name': anganwadiWorkerName,
        'beneficiaries': beneficiaries.map((b) => b.toJson()).toList(),
        'mobilisation_checklist': mobilisationChecklist.map((c) => c.toJson()).toList(),
        'session_summary_notes': sessionSummaryNotes,
        'community_feedback_notes': communityFeedbackNotes,
        'completed_at': completedAt?.toIso8601String(),
      };
}

/// Meeting record for Village Health Sanitation and Nutrition Committee (Requirement 27.3, 27.6).
class VhsncMeetingLog {
  final String id;
  final String village;
  final DateTime meetingDate;
  final int participantsCount;
  final List<String> decisionsMade;
  final List<String> agreedFollowUpActions;
  final String? communityFeedbackSummary;
  final DateTime recordedAt;

  const VhsncMeetingLog({
    required this.id,
    required this.village,
    required this.meetingDate,
    required this.participantsCount,
    required this.decisionsMade,
    required this.agreedFollowUpActions,
    this.communityFeedbackSummary,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'village': village,
        'meeting_date': meetingDate.toIso8601String(),
        'participants_count': participantsCount,
        'decisions_made': decisionsMade,
        'agreed_follow_up_actions': agreedFollowUpActions,
        'community_feedback_summary': communityFeedbackSummary,
        'recorded_at': recordedAt.toIso8601String(),
      };

  factory VhsncMeetingLog.fromJson(Map<String, dynamic> json) => VhsncMeetingLog(
        id: json['id'] as String,
        village: json['village'] as String,
        meetingDate: DateTime.parse(json['meeting_date'] as String),
        participantsCount: json['participants_count'] as int,
        decisionsMade: (json['decisions_made'] as List<dynamic>).cast<String>(),
        agreedFollowUpActions: (json['agreed_follow_up_actions'] as List<dynamic>).cast<String>(),
        communityFeedbackSummary: json['community_feedback_summary'] as String?,
        recordedAt: DateTime.parse(json['recorded_at'] as String),
      );
}

/// Health Topic classification for offline multimedia education library (Requirement 27.4).
enum HealthEducationTopic {
  maternalHealth('maternal_health', 'Maternal Health & ANC Care'),
  immunization('immunization', 'Routine Vaccination & Cold Chain'),
  newbornCare('newborn_care', 'HBNC & Essential Newborn Care'),
  childNutrition('nutrition', 'Breastfeeding, Complementary Feeding & Growth'),
  hygieneSanitation('sanitation', 'WASH, Safe Water & Handwashing'),
  communicableDisease('communicable', 'TB, Malaria, Dengue & Diarrhea Control'),
  ncdPrevention('ncd', 'Hypertension, Diabetes & Healthy Lifestyle');

  final String code;
  final String label;
  const HealthEducationTopic(this.code, this.label);

  static HealthEducationTopic fromCode(String? code) {
    if (code == null) return HealthEducationTopic.maternalHealth;
    return HealthEducationTopic.values.firstWhere(
      (e) => e.code == code,
      orElse: () => HealthEducationTopic.maternalHealth,
    );
  }
}

/// Offline multimedia health education asset in SQLite index (Requirement 27.4).
class HealthEducationAsset {
  final String id;
  final String title;
  final HealthEducationTopic topic;
  final String mediaType; // 'audio_clip', 'illustrated_card', 'video_clip'
  final String assetPath;
  final int durationSeconds;
  final String languageCode;
  final String description;
  final List<String> tags;

  const HealthEducationAsset({
    required this.id,
    required this.title,
    required this.topic,
    required this.mediaType,
    required this.assetPath,
    required this.durationSeconds,
    this.languageCode = 'hi',
    required this.description,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'topic': topic.code,
        'media_type': mediaType,
        'asset_path': assetPath,
        'duration_seconds': durationSeconds,
        'language_code': languageCode,
        'description': description,
        'tags': tags,
      };

  factory HealthEducationAsset.fromJson(Map<String, dynamic> json) => HealthEducationAsset(
        id: json['id'] as String,
        title: json['title'] as String,
        topic: HealthEducationTopic.fromCode(json['topic'] as String?),
        mediaType: json['media_type'] as String,
        assetPath: json['asset_path'] as String,
        durationSeconds: json['duration_seconds'] as int,
        languageCode: json['language_code'] as String? ?? 'hi',
        description: json['description'] as String,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      );
}

/// Active Public Health Campaign Entity (Requirement 27.5).
class CommunityCampaign {
  final String id;
  final String campaignCode; // 'pulse_polio', 'mda', 'ifa_week', 'tb_active_case'
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> checklistItems;
  final String targetDescription;

  const CommunityCampaign({
    required this.id,
    required this.campaignCode,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.checklistItems,
    required this.targetDescription,
  });

  bool isActiveOn(DateTime date) =>
      !date.isBefore(startDate) && !date.isAfter(endDate);
}
