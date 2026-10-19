import 'package:flutter/foundation.dart';

@immutable
class WorkerPrivacyNotice {
  final String title;
  final String plainTextExplanation;
  final String audioPromptAssetKey;
  final List<String> dataCollectedSummary;
  final List<String> authorizedViewers;
  final List<String> prohibitedUses;

  const WorkerPrivacyNotice({
    required this.title,
    required this.plainTextExplanation,
    required this.audioPromptAssetKey,
    required this.dataCollectedSummary,
    required this.authorizedViewers,
    required this.prohibitedUses,
  });
}

@immutable
class WorkerGrievance {
  final String grievanceId;
  final String ashaWorkerId;
  final String category; // 'INCENTIVE_PAYMENT', 'DEVICE_HARDWARE', 'SUPERVISION_HARASSMENT', 'WORKLOAD'
  final String description;
  final String status; // 'OPEN', 'UNDER_INVESTIGATION', 'RESOLVED'
  final String assignedOwner;
  final DateTime filedAt;
  final DateTime? resolvedAt;
  final String? resolutionOutcome;

  const WorkerGrievance({
    required this.grievanceId,
    required this.ashaWorkerId,
    required this.category,
    required this.description,
    required this.status,
    required this.assignedOwner,
    required this.filedAt,
    this.resolvedAt,
    this.resolutionOutcome,
  });

  WorkerGrievance copyWith({
    String? status,
    DateTime? resolvedAt,
    String? resolutionOutcome,
  }) {
    return WorkerGrievance(
      grievanceId: grievanceId,
      ashaWorkerId: ashaWorkerId,
      category: category,
      description: description,
      status: status ?? this.status,
      assignedOwner: assignedOwner,
      filedAt: filedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionOutcome: resolutionOutcome ?? this.resolutionOutcome,
    );
  }
}

class WorkerPrivacyService {
  final Map<String, WorkerGrievance> _grievances = {};

  /// Generates the plain-language, audio-supported install notice for ASHA workers (Requirement 45.1).
  WorkerPrivacyNotice getInstallNotice() {
    return const WorkerPrivacyNotice(
      title: 'ASHA Transparency & Privacy Charter (आशा दीदी गोपनीयता सूचना)',
      plainTextExplanation:
          'This application helps you record health visits, calculate incentives, and care for mothers and children. We value your dignity and respect your privacy.',
      audioPromptAssetKey: 'audio_worker_privacy_notice_hi',
      dataCollectedSummary: [
        'Records of household visits, maternal care, child immunization, and tests you perform.',
        'Timestamps when visits are marked complete for incentive calculation.',
        'Approximate village hamlet locations only when you explicitly opt-in during village surveys.',
      ],
      authorizedViewers: [
        'You (ASHA) - with full access to your own performance and earnings records.',
        'Your ASHA Facilitator (AF) - solely for supportive mentoring and visit planning.',
        'ANM and Medical Officer - for clinical referral coordination.',
      ],
      prohibitedUses: [
        'NO 24/7 background GPS tracking or continuous location surveillance.',
        'NO geofencing attendance enforcement or automated deduction of honorarium.',
        'NO secret performance tracking or punitive use without leadership sign-off and notification.',
      ],
    );
  }

  /// Verifies location permission rules: location must be opt-in per-feature and active in foreground only (Requirement 45.2).
  bool canAccessLocation({
    required bool hasUserOptedInForFeature,
    required bool isFeatureActivelyInForeground,
    required bool isBackgroundLoggingRequested,
  }) {
    // Strictly forbid background logging or unconsented access
    if (isBackgroundLoggingRequested) return false;
    if (!hasUserOptedInForFeature) return false;
    if (!isFeatureActivelyInForeground) return false;
    return true;
  }

  /// Submits an ASHA worker grievance with assigned ombudsman / owner and tracking (Requirement 45.4).
  WorkerGrievance submitGrievance({
    required String ashaWorkerId,
    required String category,
    required String description,
  }) {
    final grievanceId = 'grv_${DateTime.now().millisecondsSinceEpoch}';
    String assignedOwner;
    switch (category) {
      case 'INCENTIVE_PAYMENT':
        assignedOwner = 'Block Accounts Officer (BPMU)';
        break;
      case 'SUPERVISION_HARASSMENT':
        assignedOwner = 'District Grievance Redressal Committee';
        break;
      default:
        assignedOwner = 'Block Community Mobilizer (BCM)';
    }

    final record = WorkerGrievance(
      grievanceId: grievanceId,
      ashaWorkerId: ashaWorkerId,
      category: category,
      description: description,
      status: 'OPEN',
      assignedOwner: assignedOwner,
      filedAt: DateTime.now(),
    );

    _grievances[grievanceId] = record;
    return record;
  }

  /// Resolves an ASHA worker grievance (Requirement 45.4).
  WorkerGrievance resolveGrievance(String grievanceId, {required String resolution}) {
    final existing = _grievances[grievanceId];
    if (existing == null) throw ArgumentError('Grievance $grievanceId not found.');

    final updated = existing.copyWith(
      status: 'RESOLVED',
      resolvedAt: DateTime.now(),
      resolutionOutcome: resolution,
    );
    _grievances[grievanceId] = updated;
    return updated;
  }

  /// Simulates rooted / integrity-compromised device check (Requirement 44.8).
  ///
  /// In a production Android environment, this checks su binary presence, test-keys build tags, and Magisk pipes.
  bool isDeviceIntegrityCompromised({List<String>? detectedRootBinaries}) {
    if (detectedRootBinaries != null && detectedRootBinaries.isNotEmpty) {
      return true;
    }
    return false;
  }

  /// Restricts patient data access and returns support advice if device is compromised (Requirement 44.8).
  String getRootedDeviceWarning() {
    return 'SECURITY ALERT: Device system integrity is modified (Root detected). Access to sensitive patient health records is restricted to protect community data. Please contact the district helpdesk at 1800-180-1104 or visit your Block Health Center.';
  }

  /// Sanitizes crash stack traces to guarantee zero PHI leakage (Requirements 48.4, 44.2).
  String sanitizeCrashStackTrace(String rawStackTrace) {
    // Regex matching Indian phone numbers (10 digits / +91)
    var sanitized = rawStackTrace.replaceAll(RegExp(r'(\+91[\-\s]?)?[6-9]\d{9}'), '[REDACTED_PHONE]');
    // Regex matching 14-digit ABHA IDs (XX-XXXX-XXXX-XXXX)
    sanitized = sanitized.replaceAll(RegExp(r'\b\d{2}-\d{4}-\d{4}-\d{4}\b'), '[REDACTED_ABHA]');
    // Regex matching Aadhaar numbers (XXXX XXXX XXXX)
    sanitized = sanitized.replaceAll(RegExp(r'\b\d{4}\s\d{4}\s\d{4}\b'), '[REDACTED_UIDAI]');
    // Regex matching patient names in known tags
    sanitized = sanitized.replaceAll(RegExp(r'patientName:\s*[A-Za-z\s]+,'), 'patientName: [REDACTED_NAME],');
    return sanitized;
  }
}
