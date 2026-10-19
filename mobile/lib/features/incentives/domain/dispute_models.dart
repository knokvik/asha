/// Domain models for payment dispute resolution, bank/PFMS rejection interpretation,
/// and systemic policy issue reporting.
///
/// Implements Requirements 57.2, 57.3, 57.4, 57.5, 57.6.
library;

/// Structured information explaining a bank/PFMS rejection in plain language (Requirement 57.2).
class BankRejectionInfo {
  final String code;
  final String title;
  final String plainLanguageReason;
  final List<String> correctionSteps;
  final bool requiresBranchVisit;
  final String contactAuthority;

  const BankRejectionInfo({
    required this.code,
    required this.title,
    required this.plainLanguageReason,
    required this.correctionSteps,
    this.requiresBranchVisit = false,
    this.contactAuthority = 'Bank Branch / ASHA Facilitator',
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'plain_language_reason': plainLanguageReason,
        'correction_steps': correctionSteps,
        'requires_branch_visit': requiresBranchVisit,
        'contact_authority': contactAuthority,
      };
}

/// Catalog of known Bank / PFMS / DBT rejection codes with human explanations (Req 57.2).
class BankRejectionInterpreter {
  static const Map<String, BankRejectionInfo> _catalog = {
    'R01': BankRejectionInfo(
      code: 'R01',
      title: 'Invalid Account Number or Account Closed',
      plainLanguageReason:
          'Your bank account could not receive the payment because the account number is incorrect, closed, or transferred to another branch.',
      correctionSteps: [
        'Check your physical bank passbook to confirm your 9 to 18-digit account number.',
        'If your account is active, update your account details in the app profile.',
        'If the account was closed, open a new savings account and submit the passbook to your ASHA Facilitator.',
      ],
      requiresBranchVisit: true,
    ),
    'R02': BankRejectionInfo(
      code: 'R02',
      title: 'Bank Branch IFSC Code Mismatch',
      plainLanguageReason:
          'The IFSC code registered in the health portal does not match your current bank branch, often due to recent national bank mergers.',
      correctionSteps: [
        'Verify your updated branch IFSC code from your newest chequebook or bank passbook.',
        'Update the new 11-character IFSC code in your profile before the next payment cycle.',
      ],
      requiresBranchVisit: false,
    ),
    'R03': BankRejectionInfo(
      code: 'R03',
      title: 'Aadhaar Not Seeded with Bank Account (APBS Failure)',
      plainLanguageReason:
          'Direct Benefit Transfer (DBT) payments require your bank account to be linked to your Aadhaar on the NPCI mapper. Your account is currently unlinked.',
      correctionSteps: [
        'Visit your home bank branch with your original Aadhaar card and passbook.',
        'Request the bank executive for "Aadhaar Seeding and NPCI Mapping for DBT/APBS payments".',
        'Obtain a signed/stamped confirmation receipt from the bank teller.',
      ],
      requiresBranchVisit: true,
      contactAuthority: 'Home Bank Branch Manager',
    ),
    'R04': BankRejectionInfo(
      code: 'R04',
      title: 'Account Holder Name Mismatch',
      plainLanguageReason:
          'The name registered in your bank passbook differs slightly from the official name in the National Health Mission ASHA portal.',
      correctionSteps: [
        'Compare the exact spelling of your name in your bank passbook with your ASHA registration ID.',
        'Submit a name synchronization request to your Block Community Mobilizer (BCM) or update your bank KYC.',
      ],
      requiresBranchVisit: true,
    ),
    'R05': BankRejectionInfo(
      code: 'R05',
      title: 'Dormant or Inoperative Bank Account',
      plainLanguageReason:
          'No transactions have taken place in your bank account for over 12 months, causing the bank to temporarily lock incoming transfers.',
      correctionSteps: [
        'Visit your bank branch with your passbook and Aadhaar/PAN for Biometric Re-KYC.',
        'Deposit or withdraw a nominal cash amount (e.g., Rs. 50) to reactivate the account.',
      ],
      requiresBranchVisit: true,
    ),
    'R06': BankRejectionInfo(
      code: 'R06',
      title: 'Account Credit Limit Exceeded',
      plainLanguageReason:
          'Your Jan Dhan or Basic Savings Bank Deposit (BSBD) account has reached its monthly or annual deposit limit.',
      correctionSteps: [
        'Visit your bank branch to complete full KYC documentation.',
        'Request the bank manager to upgrade your account to a regular zero-balance savings account without balance caps.',
      ],
      requiresBranchVisit: true,
    ),
    'R07': BankRejectionInfo(
      code: 'R07',
      title: 'Administrative Freeze / Operational Hold',
      plainLanguageReason:
          'Your bank has placed an operational hold on the account due to pending KYC verification or document renewal.',
      correctionSteps: [
        'Visit your bank branch to submit fresh KYC documents.',
        'Request removal of the administrative debit/credit hold.',
      ],
      requiresBranchVisit: true,
    ),
  };

  /// Interprets a bank or PFMS rejection code, providing plain language and recovery steps.
  static BankRejectionInfo interpret(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (_catalog.containsKey(cleanCode)) {
      return _catalog[cleanCode]!;
    }

    // Secondary prefix matching (e.g. ERR_AADHAAR -> R03)
    if (cleanCode.contains('AADHAAR') || cleanCode.contains('APBS') || cleanCode.contains('NPCI')) {
      return _catalog['R03']!;
    }
    if (cleanCode.contains('IFSC')) {
      return _catalog['R02']!;
    }
    if (cleanCode.contains('NAME') || cleanCode.contains('MISMATCH')) {
      return _catalog['R04']!;
    }
    if (cleanCode.contains('DORMANT') || cleanCode.contains('INACTIVE')) {
      return _catalog['R05']!;
    }
    if (cleanCode.contains('LIMIT') || cleanCode.contains('CAP')) {
      return _catalog['R06']!;
    }

    return BankRejectionInfo(
      code: cleanCode,
      title: 'Payment Processing Hold',
      plainLanguageReason:
          'Payment processing was paused by the government treasury or bank clearing gateway (code: $cleanCode).',
      correctionSteps: [
        'Verify your bank account number and IFSC code with your ASHA Facilitator.',
        'Contact the Block Accounts Officer (BPMU) for transaction clearing details.',
      ],
      requiresBranchVisit: false,
    );
  }
}

/// Dispute categorization to differentiate technical issues from systemic policy challenges (Req 57.3, 57.6).
class DisputeType {
  static const String technicalError = 'TECHNICAL_ERROR';
  static const String dataDeficit = 'DATA_DEFICIT';
  static const String systemicPolicy = 'SYSTEMIC_POLICY';

  static const List<String> all = [
    technicalError,
    dataDeficit,
    systemicPolicy,
  ];
}

/// Payment Dispute Model (Requirement 57.3).
class PaymentDisputeModel {
  final String id;
  final String workerId;
  final String claimPeriod; // "YYYY-MM"
  final String? claimId;
  final String? activityCode;
  final String disputeType; // technical_error, data_deficit, systemic_policy
  final String description;
  final List<String> evidenceEventIds;
  final String status; // submitted, assigned, in_review, resolved, escalated, rejected
  final String? assignedTo;
  final String? assignedRole; // ANM, AF, BPMU, DISTRICT_OFFICER
  final DateTime? slaDeadline;
  final bool isEscalated;
  final int escalationLevel;
  final String? resolutionNotes;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentDisputeModel({
    required this.id,
    required this.workerId,
    required this.claimPeriod,
    this.claimId,
    this.activityCode,
    this.disputeType = DisputeType.technicalError,
    required this.description,
    this.evidenceEventIds = const [],
    this.status = 'submitted',
    this.assignedTo,
    this.assignedRole,
    this.slaDeadline,
    this.isEscalated = false,
    this.escalationLevel = 0,
    this.resolutionNotes,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == 'submitted' || status == 'assigned' || status == 'in_review';
  bool get isResolved => status == 'resolved';
  bool get isRejected => status == 'rejected';

  bool get isBreachedSla {
    if (slaDeadline == null || isResolved || isRejected) return false;
    return DateTime.now().isAfter(slaDeadline!);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'worker_id': workerId,
        'claim_period': claimPeriod,
        'claim_id': claimId,
        'activity_code': activityCode,
        'dispute_type': disputeType,
        'description': description,
        'evidence_event_ids': evidenceEventIds,
        'status': status,
        'assigned_to': assignedTo,
        'assigned_role': assignedRole,
        'sla_deadline': slaDeadline?.toIso8601String(),
        'is_escalated': isEscalated,
        'escalation_level': escalationLevel,
        'resolution_notes': resolutionNotes,
        'resolved_by': resolvedBy,
        'resolved_at': resolvedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PaymentDisputeModel.fromJson(Map<String, dynamic> json) {
    final rawEv = json['evidence_event_ids'] as List<dynamic>? ?? [];
    return PaymentDisputeModel(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      claimPeriod: json['claim_period'] as String,
      claimId: json['claim_id'] as String?,
      activityCode: json['activity_code'] as String?,
      disputeType: json['dispute_type'] as String? ?? DisputeType.technicalError,
      description: json['description'] as String,
      evidenceEventIds: rawEv.map((e) => e.toString()).toList(),
      status: json['status'] as String? ?? 'submitted',
      assignedTo: json['assigned_to'] as String?,
      assignedRole: json['assigned_role'] as String?,
      slaDeadline: json['sla_deadline'] != null ? DateTime.parse(json['sla_deadline'] as String) : null,
      isEscalated: json['is_escalated'] as bool? ?? false,
      escalationLevel: json['escalation_level'] as int? ?? 0,
      resolutionNotes: json['resolution_notes'] as String?,
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }
}
