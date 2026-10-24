import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a PHC review ticket.
enum TicketStatus {
  pending,
  underReview,
  approved,
  rejected;

  String get label {
    switch (this) {
      case TicketStatus.pending:
        return 'Pending Review';
      case TicketStatus.underReview:
        return 'Under Review';
      case TicketStatus.approved:
        return 'Approved';
      case TicketStatus.rejected:
        return 'Needs Correction';
    }
  }

  String get shortLabel {
    switch (this) {
      case TicketStatus.pending:
        return 'Pending';
      case TicketStatus.underReview:
        return 'Review';
      case TicketStatus.approved:
        return 'Approved';
      case TicketStatus.rejected:
        return 'Rejected';
    }
  }
}

/// Canonical program codes used for routing and display.
class ClinicalProgramMeta {
  final String code;
  final String displayName;

  const ClinicalProgramMeta({required this.code, required this.displayName});

  static const anc =
      ClinicalProgramMeta(code: 'anc', displayName: 'ANC (Antenatal Care)');
  static const pnc =
      ClinicalProgramMeta(code: 'pnc', displayName: 'PNC (Postnatal Care)');
  static const hbnc = ClinicalProgramMeta(
      code: 'hbnc', displayName: 'HBNC (Home Newborn Care)');
  static const hbyc = ClinicalProgramMeta(
      code: 'hbyc', displayName: 'HBYC (Home-Based Young Child Care)');
  static const ncd =
      ClinicalProgramMeta(code: 'ncd', displayName: 'NCD & CBAC Screening');
  static const immunization = ClinicalProgramMeta(
      code: 'immunization', displayName: 'Child Immunization');
  static const tb =
      ClinicalProgramMeta(code: 'tb', displayName: 'TB Screening');

  static const all = [anc, pnc, hbnc, hbyc, ncd, immunization, tb];

  static ClinicalProgramMeta? fromCode(String code) {
    try {
      return all.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }
}

/// A PHC review ticket written to Firestore when an ASHA submits a clinical form.
///
/// Firestore path: `phc_review_tickets/{ticketId}`
class PhcReviewTicket {
  final String ticketId;

  /// Clinical program code: 'anc', 'pnc', 'hbnc', 'hbyc', 'ncd', 'immunization', 'tb'.
  final String programCode;
  final String programDisplayName;

  /// Local drift encounter ID.
  final String encounterId;

  /// Member (beneficiary) ID.
  final String memberId;
  final String memberName;

  /// ASHA worker ID.
  final String ashaId;
  final String ashaName;

  final DateTime submittedAt;
  final TicketStatus status;
  final String? reviewerNote;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  /// Key clinical data captured from the form, stored as a flat string map
  /// for display in the ticket detail screen.
  final Map<String, String> formDataSummary;

  const PhcReviewTicket({
    required this.ticketId,
    required this.programCode,
    required this.programDisplayName,
    required this.encounterId,
    required this.memberId,
    required this.memberName,
    required this.ashaId,
    required this.ashaName,
    required this.submittedAt,
    required this.status,
    this.reviewerNote,
    this.reviewedAt,
    this.reviewedBy,
    this.formDataSummary = const {},
  });

  factory PhcReviewTicket.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PhcReviewTicket(
      ticketId: doc.id,
      programCode: d['programCode'] as String? ?? '',
      programDisplayName: d['programDisplayName'] as String? ?? '',
      encounterId: d['encounterId'] as String? ?? '',
      memberId: d['memberId'] as String? ?? '',
      memberName: d['memberName'] as String? ?? '',
      ashaId: d['ashaId'] as String? ?? '',
      ashaName: d['ashaName'] as String? ?? '',
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: _parseStatus(d['status'] as String? ?? 'pending'),
      reviewerNote: d['reviewerNote'] as String?,
      reviewedAt: (d['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: d['reviewedBy'] as String?,
      formDataSummary: Map<String, String>.from(
        (d['formDataSummary'] as Map<Object?, Object?>? ?? {})
            .map((k, v) => MapEntry(k.toString(), v.toString())),
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'programCode': programCode,
      'programDisplayName': programDisplayName,
      'encounterId': encounterId,
      'memberId': memberId,
      'memberName': memberName,
      'ashaId': ashaId,
      'ashaName': ashaName,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status.name,
      'reviewerNote': reviewerNote,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'formDataSummary': formDataSummary,
    };
  }

  PhcReviewTicket copyWith({
    TicketStatus? status,
    String? reviewerNote,
    DateTime? reviewedAt,
    String? reviewedBy,
  }) {
    return PhcReviewTicket(
      ticketId: ticketId,
      programCode: programCode,
      programDisplayName: programDisplayName,
      encounterId: encounterId,
      memberId: memberId,
      memberName: memberName,
      ashaId: ashaId,
      ashaName: ashaName,
      submittedAt: submittedAt,
      status: status ?? this.status,
      reviewerNote: reviewerNote ?? this.reviewerNote,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      formDataSummary: formDataSummary,
    );
  }

  static TicketStatus _parseStatus(String s) {
    switch (s) {
      case 'underReview':
        return TicketStatus.underReview;
      case 'approved':
        return TicketStatus.approved;
      case 'rejected':
        return TicketStatus.rejected;
      default:
        return TicketStatus.pending;
    }
  }
}
