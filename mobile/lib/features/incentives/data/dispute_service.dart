import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/dispute_models.dart';

/// Exception thrown when dispute validation fails.
class DisputeServiceException implements Exception {
  final String message;
  DisputeServiceException(this.message);

  @override
  String toString() => 'DisputeServiceException: $message';
}

/// Service handling dispute submission, SLA tracking, bank rejection interpretation,
/// and audit trail coordination (Requirements 57.2, 57.3, 57.6).
class DisputeService {
  final AppDatabase db;
  final SyncEngine? syncEngine;
  static const _uuid = Uuid();

  // Local cache of submitted disputes for offline viewing
  final Map<String, PaymentDisputeModel> _disputeCache = {};

  DisputeService({
    required this.db,
    this.syncEngine,
  });

  /// Submits a payment dispute for a specific period and task (Requirement 57.3).
  ///
  /// Attaches event log evidence IDs, assigns initial owner (ASHA Facilitator),
  /// sets default SLA deadline (15 days), and queues for synchronization.
  Future<PaymentDisputeModel> submitDispute({
    required String workerId,
    required String claimPeriod,
    String? claimId,
    String? activityCode,
    String disputeType = DisputeType.technicalError,
    required String description,
    List<String> evidenceEventIds = const [],
    int slaDays = 15,
  }) async {
    final trimmedDesc = description.trim();
    if (trimmedDesc.isEmpty) {
      throw DisputeServiceException('Dispute description cannot be empty');
    }

    final now = DateTime.now();
    final slaDeadline = now.add(Duration(days: slaDays));
    final disputeId = _uuid.v4();

    final dispute = PaymentDisputeModel(
      id: disputeId,
      workerId: workerId,
      claimPeriod: claimPeriod,
      claimId: claimId,
      activityCode: activityCode,
      disputeType: disputeType,
      description: trimmedDesc,
      evidenceEventIds: evidenceEventIds,
      status: 'submitted',
      assignedRole: 'AF', // Initially assigned to ASHA Facilitator
      slaDeadline: slaDeadline,
      isEscalated: false,
      escalationLevel: 0,
      createdAt: now,
      updatedAt: now,
    );

    _disputeCache[disputeId] = dispute;

    // Enqueue to Priority Queue Sync Engine (Req 31.1, 57.3)
    await syncEngine?.enqueue(
      table: 'payment_disputes',
      recordId: disputeId,
      operation: 'insert',
      payload: dispute.toJson(),
      priority: SyncPriority.metadata,
    );

    return dispute;
  }

  /// Lists all disputes submitted by a specific ASHA worker.
  Future<List<PaymentDisputeModel>> getDisputesForWorker(String workerId) async {
    return _disputeCache.values
        .where((d) => d.workerId == workerId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Interprets bank/PFMS rejection reason code into plain language with actionable steps (Req 57.2).
  BankRejectionInfo explainBankRejection(String code) {
    return BankRejectionInterpreter.interpret(code);
  }
}
