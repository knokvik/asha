import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Rejection categories for programme analytics (Requirement 56.4).
class RejectionCategory {
  static const String documentationDeficit = 'DOCUMENTATION_DEFICIT';
  static const String dateMismatch = 'DATE_MISMATCH';
  static const String duplicateSubmission = 'DUPLICATE_SUBMISSION';
  static const String ineligibleCriteria = 'INELIGIBLE_CRITERIA';
  static const String outOfWindow = 'OUT_OF_WINDOW';
  static const String bankDetailMismatch = 'BANK_DETAIL_MISMATCH';
  static const String other = 'OTHER';

  static const List<String> all = [
    documentationDeficit,
    dateMismatch,
    duplicateSubmission,
    ineligibleCriteria,
    outOfWindow,
    bankDetailMismatch,
    other,
  ];
}

/// A single line item in an incentive claim voucher (Requirement 56.1, 56.7).
class ClaimLineItem {
  final String incentiveEventId;
  final String activityCode;
  final String activityName;
  final String memberCodedId; // De-identified: hash(memberId + claimPeriod)
  final DateTime serviceDate;
  final double amount;
  final String evidenceRecordId;
  final String status; // pending, approved, rejected, corrected
  final String? rejectionReason;
  final String? rejectionCategory;
  final String? verifierNotes;
  final String? verifierId;
  final DateTime? verifiedAt;

  const ClaimLineItem({
    required this.incentiveEventId,
    required this.activityCode,
    required this.activityName,
    required this.memberCodedId,
    required this.serviceDate,
    required this.amount,
    required this.evidenceRecordId,
    this.status = 'pending',
    this.rejectionReason,
    this.rejectionCategory,
    this.verifierNotes,
    this.verifierId,
    this.verifiedAt,
  });

  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isPending => status == 'pending';

  Map<String, dynamic> toJson() => {
        'incentive_event_id': incentiveEventId,
        'activity_code': activityCode,
        'activity_name': activityName,
        'member_coded_id': memberCodedId,
        'service_date': serviceDate.toIso8601String(),
        'amount': amount,
        'evidence_record_id': evidenceRecordId,
        'status': status,
        'rejection_reason': rejectionReason,
        'rejection_category': rejectionCategory,
        'verifier_notes': verifierNotes,
        'verifier_id': verifierId,
        'verified_at': verifiedAt?.toIso8601String(),
      };

  factory ClaimLineItem.fromJson(Map<String, dynamic> json) => ClaimLineItem(
        incentiveEventId: json['incentive_event_id'] as String,
        activityCode: json['activity_code'] as String,
        activityName: json['activity_name'] as String? ?? json['activity_code'] as String,
        memberCodedId: json['member_coded_id'] as String,
        serviceDate: DateTime.parse(json['service_date'] as String),
        amount: (json['amount'] as num).toDouble(),
        evidenceRecordId: json['evidence_record_id'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        rejectionReason: json['rejection_reason'] as String?,
        rejectionCategory: json['rejection_category'] as String?,
        verifierNotes: json['verifier_notes'] as String?,
        verifierId: json['verifier_id'] as String?,
        verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at'] as String) : null,
      );

  ClaimLineItem copyWith({
    String? status,
    String? rejectionReason,
    String? rejectionCategory,
    String? verifierNotes,
    String? verifierId,
    DateTime? verifiedAt,
    bool clearRejection = false,
  }) {
    return ClaimLineItem(
      incentiveEventId: incentiveEventId,
      activityCode: activityCode,
      activityName: activityName,
      memberCodedId: memberCodedId,
      serviceDate: serviceDate,
      amount: amount,
      evidenceRecordId: evidenceRecordId,
      status: status ?? this.status,
      rejectionReason: clearRejection ? null : (rejectionReason ?? this.rejectionReason),
      rejectionCategory: clearRejection ? null : (rejectionCategory ?? this.rejectionCategory),
      verifierNotes: verifierNotes ?? this.verifierNotes,
      verifierId: verifierId ?? this.verifierId,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }
}

/// Official monthly claim voucher representation (Requirement 56.1).
class IncentiveClaimModel {
  final String id;
  final String workerId;
  final String claimPeriod; // e.g. "2024-04"
  final String status; // generated, submitted, verified, approved, paid, rejected
  final List<ClaimLineItem> lineItems;
  final double totalAmount;
  final String? pdfPath;
  final String? paymentReference;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final DateTime? paidAt;

  const IncentiveClaimModel({
    required this.id,
    required this.workerId,
    required this.claimPeriod,
    required this.status,
    required this.lineItems,
    required this.totalAmount,
    this.pdfPath,
    this.paymentReference,
    this.submittedAt,
    this.verifiedAt,
    this.paidAt,
  });

  double get approvedAmount => lineItems
      .where((item) => item.status == 'approved')
      .fold(0.0, (sum, item) => sum + item.amount);

  double get rejectedAmount => lineItems
      .where((item) => item.status == 'rejected')
      .fold(0.0, (sum, item) => sum + item.amount);

  int get approvedCount => lineItems.where((i) => i.status == 'approved').length;
  int get rejectedCount => lineItems.where((i) => i.status == 'rejected').length;
  int get pendingCount => lineItems.where((i) => i.status == 'pending').length;

  /// De-identifies beneficiary ID using SHA-256 (Req 56.7).
  static String deidentifyMember(String memberId, String period) {
    final raw = '${memberId}_$period';
    final hash = sha256.convert(utf8.encode(raw)).toString();
    return 'BEN-${hash.substring(0, 8).toUpperCase()}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'worker_id': workerId,
        'claim_period': claimPeriod,
        'status': status,
        'line_items': lineItems.map((e) => e.toJson()).toList(),
        'total_amount': totalAmount,
        'pdf_path': pdfPath,
        'payment_reference': paymentReference,
        'submitted_at': submittedAt?.toIso8601String(),
        'verified_at': verifiedAt?.toIso8601String(),
        'paid_at': paidAt?.toIso8601String(),
      };

  factory IncentiveClaimModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['line_items'] as List<dynamic>? ?? [];
    return IncentiveClaimModel(
      id: json['id'] as String,
      workerId: json['worker_id'] as String,
      claimPeriod: json['claim_period'] as String,
      status: json['status'] as String? ?? 'generated',
      lineItems: rawItems
          .map((i) => ClaimLineItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      pdfPath: json['pdf_path'] as String?,
      paymentReference: json['payment_reference'] as String?,
      submittedAt: json['submitted_at'] != null ? DateTime.parse(json['submitted_at'] as String) : null,
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at'] as String) : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
    );
  }
}

/// Bank details for an ASHA worker (Requirement 57.1).
class BankDetails {
  final String accountHolderName;
  final String accountNumber;
  final String ifscCode;
  final String bankName;
  final String? branch;
  final bool isAadhaarSeeded;

  const BankDetails({
    required this.accountHolderName,
    required this.accountNumber,
    required this.ifscCode,
    required this.bankName,
    this.branch,
    this.isAadhaarSeeded = true,
  });
}

/// Result of validating bank details prior to payment cycle (Requirement 57.1).
class BankValidationResult {
  final bool isValid;
  final bool ifscValid;
  final bool accountValid;
  final bool nameMatchValid;
  final double nameMatchScore; // 0.0 to 1.0
  final bool isAadhaarSeeded;
  final List<String> errors;
  final List<String> warnings;

  const BankValidationResult({
    required this.isValid,
    required this.ifscValid,
    required this.accountValid,
    required this.nameMatchValid,
    required this.nameMatchScore,
    required this.isAadhaarSeeded,
    this.errors = const [],
    this.warnings = const [],
  });
}

/// Bank and IFSC validator adhering to RBI & PFMS standards (Requirement 57.1).
class BankValidator {
  static final RegExp _ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  static final RegExp _accountRegex = RegExp(r'^\d{9,18}$');

  /// Validates bank details against RBI formatting and cross-checks name matching.
  static BankValidationResult validate({
    required BankDetails bankDetails,
    required String registeredWorkerName,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. IFSC Code Format (4 letters, '0', 6 alphanumeric characters)
    final trimmedIfsc = bankDetails.ifscCode.trim().toUpperCase();
    final bool ifscValid = _ifscRegex.hasMatch(trimmedIfsc);
    if (!ifscValid) {
      errors.add('Invalid IFSC code format. Must be 11 characters: 4 letters, 0, and 6 letters/digits.');
    }

    // 2. Account Number Format (9 to 18 digits)
    final trimmedAcc = bankDetails.accountNumber.trim();
    final bool accountValid = _accountRegex.hasMatch(trimmedAcc);
    if (!accountValid) {
      errors.add('Invalid account number. Must contain between 9 and 18 numeric digits.');
    }

    // 3. Name matching check (Jaro-Winkler / Token Overlap)
    final score = _calculateNameMatchScore(bankDetails.accountHolderName, registeredWorkerName);
    final bool nameMatchValid = score >= 0.70;
    if (!nameMatchValid) {
      warnings.add('Account holder name "${bankDetails.accountHolderName}" differs significantly from registered name "$registeredWorkerName" (match score: ${(score * 100).toStringAsFixed(0)}%). Likely mismatch flag.');
    }

    // 4. Aadhaar Seeding Check
    if (!bankDetails.isAadhaarSeeded) {
      warnings.add('Bank account is not Aadhaar-seeded. DBT payments via APBS may fail.');
    }

    final bool overallValid = ifscValid && accountValid && errors.isEmpty;

    return BankValidationResult(
      isValid: overallValid,
      ifscValid: ifscValid,
      accountValid: accountValid,
      nameMatchValid: nameMatchValid,
      nameMatchScore: score,
      isAadhaarSeeded: bankDetails.isAadhaarSeeded,
      errors: errors,
      warnings: warnings,
    );
  }

  static double _calculateNameMatchScore(String name1, String name2) {
    final n1 = name1.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final n2 = name2.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    if (n1 == n2) return 1.0;

    final tokens1 = n1.split(' ').toSet();
    final tokens2 = n2.split(' ').toSet();

    final intersection = tokens1.intersection(tokens2).length;
    final union = tokens1.union(tokens2).length;

    if (union == 0) return 0.0;
    return intersection / union.toDouble();
  }
}
