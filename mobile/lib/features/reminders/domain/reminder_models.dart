/// Urgency level for local push notifications and alarms (Requirement 26.1, 26.5).
enum NotificationUrgency {
  /// Emergency / RED triage / danger signs. Bypasses quiet hours immediately.
  urgent,

  /// Routine scheduled visit reminders. Suppressed during quiet hours and batched if volume is high.
  standard,

  /// Aggregated daily digest / summary notification.
  summary,
}

/// Channel for beneficiary communication reminders (Requirement 26.2, 26.4).
enum ReminderChannel {
  sms('SMS'),
  ivr('Automated Voice Call (IVR)'),
  inApp('Local In-App Push'),
  manualCall('Direct Phone Call');

  final String label;
  const ReminderChannel(this.label);
}

/// Delivery and acknowledgement status of a reminder (Requirement 26.4).
enum ReminderDeliveryStatus {
  pending('Pending Dispatch'),
  sent('Sent to Gateway'),
  delivered('Delivered to Device'),
  acknowledged('Acknowledged by Beneficiary / Family'),
  failed('Delivery Failed'),
  undelivered('Unable to Reach / No Network');

  final String label;
  const ReminderDeliveryStatus(this.label);
}

/// Configuration for quiet hours during which non-urgent alerts are suppressed (Requirement 26.5).
class QuietHoursConfig {
  final bool enabled;
  final int startHour; // 24-hour format, e.g. 21 for 9:00 PM
  final int startMinute;
  final int endHour; // 24-hour format, e.g. 7 for 7:00 AM
  final int endMinute;

  const QuietHoursConfig({
    this.enabled = true,
    this.startHour = 21,
    this.startMinute = 0,
    this.endHour = 7,
    this.endMinute = 0,
  });

  /// Checks if a given timestamp falls within the quiet hours window.
  bool isWithinQuietHours(DateTime time) {
    if (!enabled) return false;

    final currentMinutes = time.hour * 60 + time.minute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    if (startMinutes <= endMinutes) {
      // Quiet hours within the same calendar day (e.g., 13:00 to 15:00)
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Overnight quiet hours spanning midnight (e.g., 21:00 to 07:00)
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'start_hour': startHour,
        'start_minute': startMinute,
        'end_hour': endHour,
        'end_minute': endMinute,
      };

  factory QuietHoursConfig.fromJson(Map<String, dynamic> json) => QuietHoursConfig(
        enabled: json['enabled'] as bool? ?? true,
        startHour: json['start_hour'] as int? ?? 21,
        startMinute: json['start_minute'] as int? ?? 0,
        endHour: json['end_hour'] as int? ?? 7,
        endMinute: json['end_minute'] as int? ?? 0,
      );
}

/// Types of pre-approved clinical reminder message templates (Requirement 26.3).
enum BeneficiaryTemplateType {
  ancCheckup,
  immunizationDue,
  hbncNewbornVisit,
  ncdRefill,
  medicationAdherence,
  generalHealthCamp,
}

/// Bilingual template message generator conforming to privacy protections (Requirement 26.2, 26.3).
///
/// Acceptance criteria:
/// - Messages in beneficiary's language (Hindi, English, etc.).
/// - Strictly avoids including sensitive clinical health details (no diagnostic stigma).
class BeneficiaryMessageTemplates {
  // Disallowed sensitive diagnostic and stigmatizing terms per Requirement 26.2
  static final List<RegExp> _sensitivePatterns = [
    RegExp(r'\b(tb|tuberculosis|kshay|nikshay|dots)\b', caseSensitive: false),
    RegExp(r'\b(hiv|aids)\b', caseSensitive: false),
    RegExp(r'\b(cancer|karak|tumour|tumor|malignan)\b', caseSensitive: false),
    RegExp(r'\b(leprosy|kushth)\b', caseSensitive: false),
    RegExp(r'\b(std|sti|syphilis|gonorrhea)\b', caseSensitive: false),
    RegExp(r'\b(abortion|garbhavat|miscarriage)\b', caseSensitive: false),
    RegExp(r'\b(psychiatric|mental\s+illness|depression|suicide)\b', caseSensitive: false),
  ];

  /// Checks if a message text contains prohibited sensitive clinical health words.
  static bool containsSensitiveHealthDetails(String text) {
    for (final pattern in _sensitivePatterns) {
      if (pattern.hasMatch(text)) {
        return true;
      }
    }
    return false;
  }

  /// Formats a reminder message for the beneficiary in the requested language.
  /// Throws [ArgumentError] if sensitive diagnostic details are present.
  static String formatMessage({
    required BeneficiaryTemplateType type,
    String languageCode = 'hi', // 'hi' (Hindi) or 'en' (English)
    required Map<String, String> parameters,
  }) {
    final isHindi = languageCode.toLowerCase() == 'hi';
    final name = parameters['name'] ?? 'लाभार्थी';
    final date = parameters['date'] ?? 'आज';
    final facility = parameters['facility'] ?? 'स्वास्थ्य केंद्र';
    final detail = parameters['detail'] ?? 'नियमित जांच';

    String message;
    switch (type) {
      case BeneficiaryTemplateType.ancCheckup:
        message = isHindi
            ? 'नमस्ते $name जी, आपकी मातृत्व स्वास्थ्य जांच $date को $facility में निर्धारित है। कृपया एमसीपी कार्ड साथ लाएं।'
            : 'Hello $name, your maternal health checkup is scheduled on $date at $facility. Please carry your MCP card.';
        break;

      case BeneficiaryTemplateType.immunizationDue:
        message = isHindi
            ? 'नमस्ते, $name का नियमित टीकाकरण ($detail) $date को $facility में है। कृपया समय पर पहुंचें।'
            : 'Hello, regular vaccination ($detail) for $name is due on $date at $facility. Please arrive on time.';
        break;

      case BeneficiaryTemplateType.hbncNewbornVisit:
        message = isHindi
            ? 'नमस्ते $name जी, आशा दीदी आज नवजात शिशु और माता की गृह भेंट के लिए आपके घर आएंगी।'
            : 'Hello $name, ASHA Didi will visit your home today for newborn and mother routine checkup.';
        break;

      case BeneficiaryTemplateType.ncdRefill:
        message = isHindi
            ? 'नमस्ते $name जी, आपकी नियमित स्वास्थ्य जांच और दवा रीफिल $date को $facility में निर्धारित है।'
            : 'Hello $name, your routine health checkup and medicine refill is due on $date at $facility.';
        break;

      case BeneficiaryTemplateType.medicationAdherence:
        message = isHindi
            ? 'नमस्ते $name जी, कृपया अपनी निर्धारित दैनिक खुराक लेना न भूलें। स्वस्थ रहें।'
            : 'Hello $name, please remember to take your daily prescribed dose. Stay healthy.';
        break;

      case BeneficiaryTemplateType.generalHealthCamp:
        message = isHindi
            ? 'नमस्ते, ग्राम स्वास्थ्य स्वच्छता एवं पोषण दिवस (VHSND) $date को $facility में आयोजित होगा।'
            : 'Hello, Village Health Sanitation and Nutrition Day (VHSND) is scheduled on $date at $facility.';
        break;
    }

    if (containsSensitiveHealthDetails(message)) {
      throw ArgumentError('Formatted message violates Requirement 26.2 by containing sensitive diagnostic details: $message');
    }

    return message;
  }
}

/// Supervisor and Emergency contact entity (Requirement 26.6).
class SupervisorContact {
  final String id;
  final String name;
  final String role; // 'ANM', 'ASHA_FACILITATOR', 'MEDICAL_OFFICER', 'EMERGENCY_108', 'HELPLINE_104'
  final String phone;
  final String designatedArea;

  const SupervisorContact({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    required this.designatedArea,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'phone': phone,
        'designated_area': designatedArea,
      };

  factory SupervisorContact.fromJson(Map<String, dynamic> json) => SupervisorContact(
        id: json['id'] as String,
        name: json['name'] as String,
        role: json['role'] as String,
        phone: json['phone'] as String,
        designatedArea: json['designated_area'] as String,
      );
}

/// Beneficiary acknowledgement record (Requirement 26.4).
class ReminderAcknowledgement {
  final String id;
  final String scheduleId;
  final String memberId;
  final ReminderChannel channel;
  final ReminderDeliveryStatus status;
  final DateTime recordedAt;
  final String? responseNote;

  const ReminderAcknowledgement({
    required this.id,
    required this.scheduleId,
    required this.memberId,
    required this.channel,
    required this.status,
    required this.recordedAt,
    this.responseNote,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'schedule_id': scheduleId,
        'member_id': memberId,
        'channel': channel.name,
        'status': status.name,
        'recorded_at': recordedAt.toIso8601String(),
        'response_note': responseNote,
      };

  factory ReminderAcknowledgement.fromJson(Map<String, dynamic> json) => ReminderAcknowledgement(
        id: json['id'] as String,
        scheduleId: json['schedule_id'] as String,
        memberId: json['member_id'] as String,
        channel: ReminderChannel.values.firstWhere((e) => e.name == json['channel']),
        status: ReminderDeliveryStatus.values.firstWhere((e) => e.name == json['status']),
        recordedAt: DateTime.parse(json['recorded_at'] as String),
        responseNote: json['response_note'] as String?,
      );
}
