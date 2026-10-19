import 'package:flutter/foundation.dart';

enum SarRequestType {
  dataAccess('Subject Access Request (Copy of Personal Health Data)'),
  dataCorrection('Correction / Rectification of Inaccurate Record'),
  dataErasure('Erasure / Right to be Forgotten (where legally permissible)');

  final String label;
  const SarRequestType(this.label);
}

enum SarRequestStatus {
  submitted,
  underVerification,
  fulfilled,
  rejectedWithLegalBasis;
}

@immutable
class PurposeLimitationMetadata {
  final String statedPurpose;
  final String dataCategory;
  final int retentionYears;
  final DateTime collectedAt;
  final String legalBasis;

  const PurposeLimitationMetadata({
    required this.statedPurpose,
    required this.dataCategory,
    required this.retentionYears,
    required this.collectedAt,
    this.legalBasis = 'DPDP Act 2023 Section 4(1) - Healthcare Delivery by Community Health Worker',
  });

  Map<String, dynamic> toJson() => {
        'purpose': statedPurpose,
        'category': dataCategory,
        'retention_years': retentionYears,
        'collected_at': collectedAt.toIso8601String(),
        'legal_basis': legalBasis,
      };
}

@immutable
class TrackedSarRequest {
  final String requestId;
  final String beneficiaryId;
  final SarRequestType requestType;
  final String details;
  final SarRequestStatus status;
  final DateTime submittedAt;
  final DateTime? fulfilledAt;
  final String? resolutionNotes;

  const TrackedSarRequest({
    required this.requestId,
    required this.beneficiaryId,
    required this.requestType,
    required this.details,
    required this.status,
    required this.submittedAt,
    this.fulfilledAt,
    this.resolutionNotes,
  });

  TrackedSarRequest copyWith({
    SarRequestStatus? status,
    DateTime? fulfilledAt,
    String? resolutionNotes,
  }) {
    return TrackedSarRequest(
      requestId: requestId,
      beneficiaryId: beneficiaryId,
      requestType: requestType,
      details: details,
      status: status ?? this.status,
      submittedAt: submittedAt,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
    );
  }
}

@immutable
class DataBreachIncident {
  final String incidentId;
  final DateTime detectedAt;
  final String anomalyType; // 'MASS_EXPORT', 'UNAUTHORIZED_DEVICE', 'FAILED_PIN_SPIKE'
  final int affectedRecordsCount;
  final bool notifiedCertIn;
  final String immediateMitigationTaken;

  const DataBreachIncident({
    required this.incidentId,
    required this.detectedAt,
    required this.anomalyType,
    required this.affectedRecordsCount,
    required this.notifiedCertIn,
    required this.immediateMitigationTaken,
  });
}

@immutable
class AccessAuditEntry {
  final String accessId;
  final String userId;
  final String userRole;
  final String patientId;
  final String accessedCategory;
  final String statedPurpose;
  final DateTime accessedAt;

  const AccessAuditEntry({
    required this.accessId,
    required this.userId,
    required this.userRole,
    required this.patientId,
    required this.accessedCategory,
    required this.statedPurpose,
    required this.accessedAt,
  });
}

class DpdpComplianceService {
  final List<AccessAuditEntry> _accessLogs = [];
  final Map<String, TrackedSarRequest> _sarRequests = {};
  final List<DataBreachIncident> _breachLogs = [];

  List<AccessAuditEntry> get accessLogs => List.unmodifiable(_accessLogs);
  List<DataBreachIncident> get breachLogs => List.unmodifiable(_breachLogs);

  /// Generates purpose limitation metadata to attach to every clinical record write (Requirement 44.2).
  PurposeLimitationMetadata generatePurposeMetadata({
    required String programCategory,
  }) {
    final now = DateTime.now();
    int retentionYears;
    String purpose;

    switch (programCategory.toLowerCase()) {
      case 'anc_pnc':
      case 'hbnc':
      case 'immunization':
        retentionYears = 7; // Pediatric records retained until age of majority + 2 yrs
        purpose = 'MOHFW_MATERNAL_CHILD_HEALTHCARE';
        break;
      case 'tb':
      case 'ncd':
        retentionYears = 10;
        purpose = 'CHRONIC_DISEASE_MANAGEMENT_AND_SURVEILLANCE';
        break;
      case 'family_planning':
        retentionYears = 5;
        purpose = 'REPRODUCTIVE_HEALTH_AND_CONTRACEPTION_SERVICES';
        break;
      default:
        retentionYears = 5;
        purpose = 'COMMUNITY_HEALTH_AND_WELLNESS_SURVEY';
    }

    return PurposeLimitationMetadata(
      statedPurpose: purpose,
      dataCategory: programCategory,
      retentionYears: retentionYears,
      collectedAt: now,
    );
  }

  /// Submits a tracked DPDP Subject Access / Correction / Erasure request (Requirement 44.3).
  TrackedSarRequest submitSarRequest({
    required String beneficiaryId,
    required SarRequestType requestType,
    required String details,
  }) {
    final requestId = 'sar_${DateTime.now().millisecondsSinceEpoch}';
    final request = TrackedSarRequest(
      requestId: requestId,
      beneficiaryId: beneficiaryId,
      requestType: requestType,
      details: details,
      status: SarRequestStatus.submitted,
      submittedAt: DateTime.now(),
    );
    _sarRequests[requestId] = request;
    return request;
  }

  /// Fulfills a tracked SAR request with resolution timestamp and notes (Requirement 44.3).
  TrackedSarRequest fulfillSarRequest(String requestId, {required String resolutionNotes}) {
    final existing = _sarRequests[requestId];
    if (existing == null) {
      throw ArgumentError('Request $requestId not found.');
    }
    final updated = existing.copyWith(
      status: SarRequestStatus.fulfilled,
      fulfilledAt: DateTime.now(),
      resolutionNotes: resolutionNotes,
    );
    _sarRequests[requestId] = updated;
    return updated;
  }

  /// Logs every staff data access with user, purpose, and timestamp (Requirement 44.6).
  void logDataAccess({
    required String userId,
    required String userRole,
    required String patientId,
    required String category,
    required String purpose,
  }) {
    _accessLogs.add(
      AccessAuditEntry(
        accessId: 'acc_${DateTime.now().microsecondsSinceEpoch}',
        userId: userId,
        userRole: userRole,
        patientId: patientId,
        accessedCategory: category,
        statedPurpose: purpose,
        accessedAt: DateTime.now(),
      ),
    );
  }

  /// Detects anomalous access frequency by a single user (Requirement 44.6).
  bool isAccessAnomalous({
    required String userId,
    int thresholdWithinFiveMinutes = 50,
  }) {
    final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
    final recentCount = _accessLogs
        .where((l) => l.userId == userId && l.accessedAt.isAfter(fiveMinAgo))
        .length;
    return recentCount >= thresholdWithinFiveMinutes;
  }

  /// Records a security breach incident and triggers CERT-In notification requirement (Requirement 44.4).
  DataBreachIncident logBreachIncident({
    required String anomalyType,
    required int affectedRecordsCount,
    required String immediateMitigationTaken,
  }) {
    final incident = DataBreachIncident(
      incidentId: 'breach_${DateTime.now().millisecondsSinceEpoch}',
      detectedAt: DateTime.now(),
      anomalyType: anomalyType,
      affectedRecordsCount: affectedRecordsCount,
      notifiedCertIn: true, // DPDP & CERT-In 6-hour mandate
      immediateMitigationTaken: immediateMitigationTaken,
    );
    _breachLogs.add(incident);
    return incident;
  }

  /// Applies de-stigmatising neutral labels for sensitive conditions in shared views (Requirement 44.9).
  Map<String, dynamic> maskStigmatisedConditions({
    required Map<String, dynamic> record,
    required String viewerRole,
  }) {
    final result = Map<String, dynamic>.from(record);
    final allowedRoles = ['asha', 'anm', 'mo', 'cho'];

    if (!allowedRoles.contains(viewerRole.toLowerCase())) {
      // Mask TB
      if (result.containsKey('tb_status')) {
        result['tb_status'] = 'Respiratory Care Follow-up';
      }
      // Mask HIV
      if (result.containsKey('hiv_status')) {
        result['hiv_status'] = 'Specialized Wellness Protocol';
      }
      // Mask Mental Health
      if (result.containsKey('mental_health_score') || result.containsKey('phq4_result')) {
        result['mental_health_score'] = 'General Counselling';
        result.remove('phq4_result');
      }
      // Mask Family Planning
      if (result.containsKey('contraceptive_method')) {
        result['contraceptive_method'] = 'Reproductive Health Protocol';
      }
    }
    return result;
  }
}
