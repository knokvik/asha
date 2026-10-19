import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/pdf/pdf_generator.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/claim_models.dart';
import '../domain/incentive_service.dart';

/// Exception thrown when claim operations fail.
class ClaimServiceException implements Exception {
  final String message;
  ClaimServiceException(this.message);

  @override
  String toString() => 'ClaimServiceException: $message';
}

/// Service handling monthly claim voucher generation, verification routing,
/// rejected line resubmission, and pre-payment bank validation.
///
/// Implements Requirements 56.1, 56.2, 56.3, 56.4, 56.7, 57.1.
class ClaimService {
  final AppDatabase db;
  final IncentiveService incentiveService;
  final SyncEngine? syncEngine;
  static const _uuid = Uuid();

  ClaimService({
    required this.db,
    required this.incentiveService,
    this.syncEngine,
  });

  /// Automatically generates the monthly claim voucher at period close or on ASHA request (Req 56.1).
  ///
  /// Enforces idempotency (Req 56.1, Property Note):
  /// Repeated generation for the same worker and period produces the identical voucher
  /// without duplicate line items or multiple claim records.
  Future<IncentiveClaimModel> generateClaimVoucher({
    required String workerId,
    required String period, // Format: "YYYY-MM" e.g. "2024-04"
  }) async {
    // 1. Check if claim voucher already exists for this period (Idempotency)
    final existing = await (db.select(db.incentiveClaims)
          ..where((t) => t.workerId.equals(workerId) & t.claimPeriod.equals(period)))
        .getSingleOrNull();

    if (existing != null) {
      return _mapRowToModel(existing);
    }

    // 2. Determine period start and end bounds
    final dateRange = _getPeriodDateRange(period);
    final startMs = dateRange.$1.millisecondsSinceEpoch;
    final endMs = dateRange.$2.millisecondsSinceEpoch;

    // 3. Query all eligible incentive events within the period
    final events = await (db.select(db.incentiveEvents)
          ..where((t) =>
              t.eventDate.isBiggerOrEqualValue(startMs) &
              t.eventDate.isSmallerOrEqualValue(endMs) &
              t.status.equals('eligible')))
        .get();

    // 4. Construct de-identified claim line items (Req 56.1, 56.7)
    final lineItems = <ClaimLineItem>[];
    double totalAmount = 0.0;

    for (final ev in events) {
      final eventDate = DateTime.fromMillisecondsSinceEpoch(ev.eventDate);
      final catalogue = incentiveService.getCatalogueForDate(eventDate);
      final item = catalogue?.getItem(ev.activityCode);
      final rate = item?.rates.totalRate ?? 0.0;
      final activityName = item?.activityName ?? ev.activityCode;

      // De-identify beneficiary reference: hash(memberId + claimPeriod) -> BEN-XXXX (Req 56.7)
      final memberCodedId = IncentiveClaimModel.deidentifyMember(ev.memberId, period);

      final lineItem = ClaimLineItem(
        incentiveEventId: ev.id,
        activityCode: ev.activityCode,
        activityName: activityName,
        memberCodedId: memberCodedId,
        serviceDate: eventDate,
        amount: rate,
        evidenceRecordId: ev.evidenceRecordId ?? ev.encounterId ?? ev.id,
        status: 'pending',
      );

      lineItems.add(lineItem);
      totalAmount += rate;
    }

    // 5. Insert new claim voucher record
    final claimId = _uuid.v4();
    final lineItemsJson = jsonEncode(lineItems.map((e) => e.toJson()).toList());

    await db.into(db.incentiveClaims).insert(
          IncentiveClaimsCompanion.insert(
            id: claimId,
            workerId: workerId,
            claimPeriod: period,
            status: const Value('generated'),
            lineItemsJson: Value(lineItemsJson),
            totalAmount: Value(totalAmount),
            syncStatus: const Value('pending'),
          ),
        );

    // 6. Mark included incentive events as claimed
    for (final ev in events) {
      await (db.update(db.incentiveEvents)..where((t) => t.id.equals(ev.id))).write(
        const IncentiveEventsCompanion(status: Value('claimed')),
      );
    }

    final claimModel = IncentiveClaimModel(
      id: claimId,
      workerId: workerId,
      claimPeriod: period,
      status: 'generated',
      lineItems: lineItems,
      totalAmount: totalAmount,
    );

    // 7. Enqueue for background sync if engine available
    await syncEngine?.enqueue(
      table: 'incentive_claims',
      recordId: claimId,
      operation: 'insert',
      payload: claimModel.toJson(),
      priority: SyncPriority.metadata,
    );

    return claimModel;
  }

  /// Submits the claim voucher for ANM / AF line-item verification (Req 56.2).
  Future<IncentiveClaimModel> submitClaim(String claimId) async {
    final existing = await (db.select(db.incentiveClaims)..where((t) => t.id.equals(claimId)))
        .getSingleOrNull();

    if (existing == null) {
      throw ClaimServiceException('Claim with ID $claimId does not exist');
    }

    final now = DateTime.now();
    await (db.update(db.incentiveClaims)..where((t) => t.id.equals(claimId))).write(
      IncentiveClaimsCompanion(
        status: const Value('submitted'),
        submittedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
      ),
    );

    final updated = await (db.select(db.incentiveClaims)..where((t) => t.id.equals(claimId)))
        .getSingle();

    final model = _mapRowToModel(updated);

    await syncEngine?.enqueue(
      table: 'incentive_claims',
      recordId: claimId,
      operation: 'update',
      payload: model.toJson(),
      priority: SyncPriority.metadata,
    );

    return model;
  }

  /// Resubmits rejected line items after ASHA has corrected the underlying data (Req 56.4).
  Future<IncentiveClaimModel> resubmitRejectedLines({
    required String claimId,
    required List<String> eventIdsToResubmit,
  }) async {
    final existing = await (db.select(db.incentiveClaims)..where((t) => t.id.equals(claimId)))
        .getSingleOrNull();

    if (existing == null) {
      throw ClaimServiceException('Claim with ID $claimId does not exist');
    }

    final currentModel = _mapRowToModel(existing);
    final updatedLines = <ClaimLineItem>[];

    for (final item in currentModel.lineItems) {
      if (eventIdsToResubmit.contains(item.incentiveEventId)) {
        // Reset status to pending/corrected for verifier re-evaluation
        updatedLines.add(item.copyWith(
          status: 'pending',
          clearRejection: true,
        ));
      } else {
        updatedLines.add(item);
      }
    }

    final now = DateTime.now();
    final lineItemsJson = jsonEncode(updatedLines.map((e) => e.toJson()).toList());

    await (db.update(db.incentiveClaims)..where((t) => t.id.equals(claimId))).write(
      IncentiveClaimsCompanion(
        status: const Value('submitted'),
        lineItemsJson: Value(lineItemsJson),
        submittedAt: Value(now.millisecondsSinceEpoch),
        syncStatus: const Value('pending'),
      ),
    );

    // Ensure corresponding local incentive events are restored to claimed status
    for (final eventId in eventIdsToResubmit) {
      await (db.update(db.incentiveEvents)..where((t) => t.id.equals(eventId))).write(
        const IncentiveEventsCompanion(status: Value('claimed')),
      );
    }

    final updatedRow = await (db.select(db.incentiveClaims)..where((t) => t.id.equals(claimId)))
        .getSingle();

    final model = _mapRowToModel(updatedRow);

    await syncEngine?.enqueue(
      table: 'incentive_claims',
      recordId: claimId,
      operation: 'update',
      payload: model.toJson(),
      priority: SyncPriority.metadata,
    );

    return model;
  }

  /// Fetches a claim by ID.
  Future<IncentiveClaimModel?> getClaim(String claimId) async {
    final row = await (db.select(db.incentiveClaims)..where((t) => t.id.equals(claimId)))
        .getSingleOrNull();
    return row != null ? _mapRowToModel(row) : null;
  }

  /// Fetches a claim for a given worker and claim period.
  Future<IncentiveClaimModel?> getClaimForPeriod(String workerId, String period) async {
    final row = await (db.select(db.incentiveClaims)
          ..where((t) => t.workerId.equals(workerId) & t.claimPeriod.equals(period)))
        .getSingleOrNull();
    return row != null ? _mapRowToModel(row) : null;
  }

  /// Fetches all claims for a given worker.
  Future<List<IncentiveClaimModel>> getClaimsForWorker(String workerId) async {
    final rows = await (db.select(db.incentiveClaims)
          ..where((t) => t.workerId.equals(workerId))
          ..orderBy([(t) => OrderingTerm.desc(t.claimPeriod)]))
        .get();

    return rows.map(_mapRowToModel).toList();
  }

  /// Generates the printable PDF voucher in official state format (Req 56.1, Property 12).
  Future<Uint8List> generateVoucherPdf({
    required IncentiveClaimModel claim,
    required String workerName,
    required String workerAshaId,
    String village = 'Rampur',
    String phc = 'PHC Rampur',
    String subCenter = 'SC Rampur-A',
  }) {
    return PdfGenerator.generateClaimVoucherPdf(
      claim: claim,
      workerName: workerName,
      workerAshaId: workerAshaId,
      village: village,
      phc: phc,
      subCenter: subCenter,
    );
  }

  /// Pre-validates bank details according to RBI formatting and name matching (Req 57.1).
  BankValidationResult validateBankDetails({
    required BankDetails bankDetails,
    required String registeredWorkerName,
  }) {
    return BankValidator.validate(
      bankDetails: bankDetails,
      registeredWorkerName: registeredWorkerName,
    );
  }

  // ── Helper Methods ─────────────────────────────────────────────────────────

  IncentiveClaimModel _mapRowToModel(IncentiveClaim row) {
    List<ClaimLineItem> lineItems = [];
    if (row.lineItemsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(row.lineItemsJson) as List<dynamic>;
        lineItems = decoded
            .map((item) => ClaimLineItem.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        lineItems = [];
      }
    }

    return IncentiveClaimModel(
      id: row.id,
      workerId: row.workerId,
      claimPeriod: row.claimPeriod,
      status: row.status,
      lineItems: lineItems,
      totalAmount: row.totalAmount,
      pdfPath: row.pdfPath,
      paymentReference: row.paymentReference,
      submittedAt: row.submittedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.submittedAt!)
          : null,
      verifiedAt: row.verifiedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.verifiedAt!)
          : null,
      paidAt: row.paidAt != null
          ? DateTime.fromMillisecondsSinceEpoch(row.paidAt!)
          : null,
    );
  }

  (DateTime, DateTime) _getPeriodDateRange(String period) {
    final parts = period.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);

    final start = DateTime(year, month, 1);
    final nextMonth = month == 12 ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final end = nextMonth.subtract(const Duration(milliseconds: 1));

    return (start, end);
  }
}
