import 'package:core_model/core_model.dart';

/// The rendered referral, in the three forms the system needs (§11.3).
class ReferralNote {
  const ReferralNote({
    required this.actionHeader,
    required this.plainText,
    required this.structured,
  });

  /// Tier 1 alone. Short enough for the SMS-degraded channel (§11.3), and the
  /// only thing the §11.4 acceptance test shows the doctor.
  final String actionHeader;

  /// Tier 1 + Tier 2, the full document shown on screen and shared as text.
  final String plainText;

  /// Machine-readable form. The dashboard renders from this; it never parses
  /// the plain text.
  final JsonMap structured;

  /// §11.3 — the share channel leaves the encrypted app boundary and MUST NOT
  /// carry the child's name or the caregiver's number.
  String get smsSafeHeader => actionHeader
      .split('\n')
      .where((line) => !line.startsWith(_ReferralRedaction.contactPrefix))
      .join('\n');

  int get actionHeaderLineCount => actionHeader.trim().split('\n').length;
}

abstract final class _ReferralRedaction {
  static const contactPrefix = 'ASHA ';
}

/// Everything the note needs that is not part of the clinical assessment:
/// who assessed the child, when, and how to reach them.
class ReferralContext {
  const ReferralContext({
    required this.patientLocalCode,
    required this.workerName,
    required this.workerCode,
    required this.generatedAt,
    this.workerContact,
    this.patientName,
    this.appVersion = 'unknown',
    this.facilityName,
  });

  final String patientLocalCode;
  final String? patientName;
  final String workerName;
  final String workerCode;
  final String? workerContact;
  final DateTime generatedAt;
  final String appVersion;
  final String? facilityName;
}
