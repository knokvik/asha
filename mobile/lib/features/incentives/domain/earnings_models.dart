/// Domain models for ASHA Earnings Dashboard, reconciliation, projections,
/// and official printable statements (Requirements 55.1–55.6).
library;

class EarningsStatusTotals {
  final double eligibleAmount;
  final int eligibleCount;

  final double claimedAmount;
  final int claimedCount;

  final double verifiedAmount;
  final int verifiedCount;

  final double approvedAmount;
  final int approvedCount;

  final double paidAmount;
  final int paidCount;

  final double rejectedAmount;
  final int rejectedCount;

  const EarningsStatusTotals({
    this.eligibleAmount = 0.0,
    this.eligibleCount = 0,
    this.claimedAmount = 0.0,
    this.claimedCount = 0,
    this.verifiedAmount = 0.0,
    this.verifiedCount = 0,
    this.approvedAmount = 0.0,
    this.approvedCount = 0,
    this.paidAmount = 0.0,
    this.paidCount = 0,
    this.rejectedAmount = 0.0,
    this.rejectedCount = 0,
  });

  /// Total money received (Paid) + guaranteed awaiting disbursement (Approved).
  double get totalEarned => paidAmount + approvedAmount;

  /// Total pipeline including eligible not-yet-claimed and under verification.
  double get totalPipeline =>
      eligibleAmount +
      claimedAmount +
      verifiedAmount +
      approvedAmount +
      paidAmount;

  int get totalTasksCount =>
      eligibleCount +
      claimedCount +
      verifiedCount +
      approvedCount +
      paidCount +
      rejectedCount;
}

class EarningsLineItem {
  final String eventId;
  final String activityCode;
  final String activityName;
  final String memberCodedId;
  final String? memberId;
  final String? memberName;
  final String? householdId;
  final String? householdArea;
  final DateTime serviceDate;
  final double amount;
  final String status; // eligible, claimed, verified, approved, paid, rejected
  final String stage;
  final String? responsibleRole;
  final String? responsiblePerson;
  final String? delayOrRejectionReason;
  final String? evidenceRecordId;
  final String? bankReference;
  final DateTime? paymentDate;

  const EarningsLineItem({
    required this.eventId,
    required this.activityCode,
    required this.activityName,
    required this.memberCodedId,
    this.memberId,
    this.memberName,
    this.householdId,
    this.householdArea,
    required this.serviceDate,
    required this.amount,
    required this.status,
    required this.stage,
    this.responsibleRole,
    this.responsiblePerson,
    this.delayOrRejectionReason,
    this.evidenceRecordId,
    this.bankReference,
    this.paymentDate,
  });

  bool get isDelayedOrRejected =>
      status == 'rejected' ||
      (status == 'claimed' &&
          DateTime.now().difference(serviceDate).inDays > 30) ||
      (status == 'verified' &&
          DateTime.now().difference(serviceDate).inDays > 45);
}

class PaymentReconciliation {
  final String claimPeriod;
  final double approvedAmount;
  final double paidAmount;
  final String bankReference;
  final DateTime paymentDate;
  final String? note;

  const PaymentReconciliation({
    required this.claimPeriod,
    required this.approvedAmount,
    required this.paidAmount,
    required this.bankReference,
    required this.paymentDate,
    this.note,
  });

  double get discrepancy => (paidAmount - approvedAmount);
  bool get hasDiscrepancy => discrepancy.abs() > 0.01;
  bool get isShortfall => discrepancy < -0.01;
  bool get isExcess => discrepancy > 0.01;

  String get reconciliationStatus {
    if (!hasDiscrepancy) return 'Fully Reconciled';
    if (isShortfall) {
      return 'Shortfall of ₹${(-discrepancy).toStringAsFixed(2)}';
    }
    return 'Excess Payment of ₹${discrepancy.toStringAsFixed(2)}';
  }
}

class ProjectedTask {
  final String activityCode;
  final String activityName;
  final String memberCodedId;
  final double currentProgress;
  final String remainingDescription;
  final double potentialAmount;

  const ProjectedTask({
    required this.activityCode,
    required this.activityName,
    required this.memberCodedId,
    required this.currentProgress,
    required this.remainingDescription,
    required this.potentialAmount,
  });
}

class EarningsProjection {
  final String currentMonth;
  final double currentEarned;
  final List<ProjectedTask> pendingTasks;
  final double projectedAdditionalAmount;

  const EarningsProjection({
    required this.currentMonth,
    required this.currentEarned,
    required this.pendingTasks,
    required this.projectedAdditionalAmount,
  });

  double get totalProjected => currentEarned + projectedAdditionalAmount;
}

class EarningsStatement {
  final String workerId;
  final String workerName;
  final String ashaId;
  final String village;
  final String subcentre;
  final String phc;
  final String block;
  final String district;
  final String state;
  final String period;
  final EarningsStatusTotals totals;
  final List<EarningsLineItem> lineItems;
  final List<PaymentReconciliation> reconciliations;
  final DateTime generatedAt;

  const EarningsStatement({
    required this.workerId,
    required this.workerName,
    required this.ashaId,
    required this.village,
    required this.subcentre,
    required this.phc,
    required this.block,
    required this.district,
    required this.state,
    required this.period,
    required this.totals,
    required this.lineItems,
    required this.reconciliations,
    required this.generatedAt,
  });
}
