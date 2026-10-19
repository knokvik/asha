import 'triage_flag.dart';

/// Clinical override record when an ASHA worker overrides an automated triage flag.
///
/// Acceptance Criteria:
/// Requirement 8.6: ASHA can override severity level (upward or downward),
/// requires a reason between 10 and 500 characters (text or voice note),
/// and records both original output and override.
class TriageOverride {
  final String encounterId;
  final TriageFlag originalFlag;
  final TriageFlag overrideFlag;
  final String reason;
  final String? voiceNotePath;
  final String overridingUserId;
  final DateTime overriddenAt;

  TriageOverride({
    required this.encounterId,
    required this.originalFlag,
    required this.overrideFlag,
    required this.reason,
    this.voiceNotePath,
    required this.overridingUserId,
    DateTime? overriddenAt,
  })  : overriddenAt = overriddenAt ?? DateTime.now() {
    final trimmedReason = reason.trim();
    if (voiceNotePath == null || voiceNotePath!.isEmpty) {
      if (trimmedReason.length < 10 || trimmedReason.length > 500) {
        throw ArgumentError(
          'Override reason must be between 10 and 500 characters (was ${trimmedReason.length})',
        );
      }
    }
  }

  factory TriageOverride.fromJson(Map<String, dynamic> json) => TriageOverride(
        encounterId: json['encounter_id'] as String? ?? json['encounterId'] as String? ?? '',
        originalFlag: TriageFlag.fromString(
          json['original_flag'] as String? ?? json['originalFlag'] as String?,
        ),
        overrideFlag: TriageFlag.fromString(
          json['override_flag'] as String? ?? json['overrideFlag'] as String?,
        ),
        reason: json['reason'] as String? ?? '',
        voiceNotePath: json['voice_note_path'] as String? ?? json['voiceNotePath'] as String?,
        overridingUserId: json['overriding_user_id'] as String? ??
            json['overridingUserId'] as String? ??
            '',
        overriddenAt: json['overridden_at'] != null
            ? (json['overridden_at'] is int
                ? DateTime.fromMillisecondsSinceEpoch(json['overridden_at'] as int)
                : DateTime.parse(json['overridden_at'] as String))
            : (json['overriddenAt'] != null
                ? (json['overriddenAt'] is int
                    ? DateTime.fromMillisecondsSinceEpoch(json['overriddenAt'] as int)
                    : DateTime.parse(json['overriddenAt'] as String))
                : DateTime.now()),
      );

  Map<String, dynamic> toJson() => {
        'encounter_id': encounterId,
        'original_flag': originalFlag.label,
        'override_flag': overrideFlag.label,
        'reason': reason,
        if (voiceNotePath != null) 'voice_note_path': voiceNotePath,
        'overriding_user_id': overridingUserId,
        'overridden_at': overriddenAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriageOverride &&
          runtimeType == other.runtimeType &&
          encounterId == other.encounterId &&
          originalFlag == other.originalFlag &&
          overrideFlag == other.overrideFlag &&
          reason == other.reason &&
          voiceNotePath == other.voiceNotePath &&
          overridingUserId == other.overridingUserId;

  @override
  int get hashCode => Object.hash(
        encounterId,
        originalFlag,
        overrideFlag,
        reason,
        voiceNotePath,
        overridingUserId,
      );
}
