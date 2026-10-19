import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/household_dao.dart';
import '../data/member_dao.dart';

/// Provenance audit record representing a hand-over between two healthcare workers.
/// Requirements: 4.8
class HandoverAuditRecord {
  final String auditLogId;
  final String entityType; // 'households' | 'members'
  final String recordId;
  final String transferringWorker;
  final String receivingWorker;
  final int timestamp;
  final String reason;
  final String chainHash;
  final int affectedTasksCount;

  const HandoverAuditRecord({
    required this.auditLogId,
    required this.entityType,
    required this.recordId,
    required this.transferringWorker,
    required this.receivingWorker,
    required this.timestamp,
    required this.reason,
    required this.chainHash,
    required this.affectedTasksCount,
  });
}

/// Service managing the hand-over workflow between ASHAs for boundary overlap,
/// worker transfer, or migration, ensuring full tamper-evident audit logging.
///
/// Requirements: 4.8
class HandoverService {
  final AppDatabase db;
  final HouseholdDao householdDao;
  final MemberDao memberDao;
  final SyncEngine? syncEngine;
  static const _uuid = Uuid();

  HandoverService({
    required this.db,
    required this.householdDao,
    required this.memberDao,
    this.syncEngine,
  });

  /// Computes a tamper-evident audit chain hash for the hand-over event.
  static String computeChainHash({
    required String recordId,
    required String transferringWorker,
    required String receivingWorker,
    required int timestamp,
    required String reason,
  }) {
    final payload = '$recordId$transferringWorker$receivingWorker$timestamp$reason';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// Hands over an entire household and all its open tasks to a successor ASHA.
  ///
  /// Requirements: 4.8
  Future<HandoverAuditRecord> handoverHousehold({
    required String householdId,
    required String transferringWorker,
    required String receivingWorker,
    required String reason,
    String deviceId = 'device_local',
    String appVersion = '1.0.0',
    int? timestamp,
  }) async {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;

    // 1. Verify household exists
    final household = await householdDao.getById(householdId);
    if (household == null) {
      throw ArgumentError('Household not found with ID: $householdId');
    }

    // 2. Fetch household members and their open tasks
    final members = await memberDao.getByHousehold(householdId);
    int totalOpenTasks = 0;

    for (final member in members) {
      final tasks = await memberDao.getActiveVisitSchedules(member.id);
      totalOpenTasks += tasks.length;
    }

    // 3. Update household ownership / assignment
    await (db.update(db.households)..where((t) => t.id.equals(householdId))).write(
      HouseholdsCompanion(
        createdBy: Value(receivingWorker),
        updatedAt: Value(ts),
        syncStatus: const Value('pending'),
      ),
    );

    // 4. Update members provenance
    for (final member in members) {
      await (db.update(db.members)..where((t) => t.id.equals(member.id))).write(
        MembersCompanion(
          createdBy: Value(receivingWorker),
          updatedAt: Value(ts),
          syncStatus: const Value('pending'),
        ),
      );
    }

    // 5. Generate Tamper-Evident Audit Log Entry (Requirement 4.8)
    final auditId = _uuid.v4();
    final chainHash = computeChainHash(
      recordId: householdId,
      transferringWorker: transferringWorker,
      receivingWorker: receivingWorker,
      timestamp: ts,
      reason: reason,
    );

    await db.into(db.auditLog).insert(
      AuditLogCompanion.insert(
        id: auditId,
        entityTable: 'households',
        recordId: householdId,
        fieldName: const Value('assigned_worker'),
        oldValue: Value(transferringWorker),
        newValue: Value(receivingWorker),
        changedBy: transferringWorker,
        deviceId: deviceId,
        appVersion: appVersion,
        deviceTimestamp: ts,
        chainHash: chainHash,
      ),
    );

    // 6. Enqueue Hand-Over event to BitChat SyncEngine
    if (syncEngine != null) {
      await syncEngine!.enqueue(
        table: 'audit_log',
        recordId: auditId,
        operation: 'handover_household',
        priority: SyncPriority.clinical,
        payload: {
          'id': auditId,
          'household_id': householdId,
          'transferring_worker': transferringWorker,
          'receiving_worker': receivingWorker,
          'timestamp': ts,
          'reason': reason,
          'chain_hash': chainHash,
          'affected_members_count': members.length,
          'affected_tasks_count': totalOpenTasks,
          'dirty_flag': 1,
          'sync_version': 1,
        },
      );
    }

    return HandoverAuditRecord(
      auditLogId: auditId,
      entityType: 'households',
      recordId: householdId,
      transferringWorker: transferringWorker,
      receivingWorker: receivingWorker,
      timestamp: ts,
      reason: reason,
      chainHash: chainHash,
      affectedTasksCount: totalOpenTasks,
    );
  }

  /// Hands over an individual beneficiary to a successor ASHA / area.
  ///
  /// Requirements: 4.8
  Future<HandoverAuditRecord> handoverBeneficiary({
    required String memberId,
    required String transferringWorker,
    required String receivingWorker,
    required String reason,
    String? targetHouseholdId,
    String deviceId = 'device_local',
    String appVersion = '1.0.0',
    int? timestamp,
  }) async {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;

    final member = await memberDao.getById(memberId);
    if (member == null) {
      throw ArgumentError('Member not found with ID: $memberId');
    }

    final openTasks = await memberDao.getActiveVisitSchedules(memberId);

    // Update target household if beneficiary is transferred to an existing household
    if (targetHouseholdId != null && targetHouseholdId != member.householdId) {
      await memberDao.transferHousehold(memberId, targetHouseholdId, timestamp: ts);
      final oldActive = await memberDao.countActiveMembers(member.householdId);
      await householdDao.updateMemberCount(member.householdId, oldActive);
      final newActive = await memberDao.countActiveMembers(targetHouseholdId);
      await householdDao.updateMemberCount(targetHouseholdId, newActive);
    } else {
      await (db.update(db.members)..where((t) => t.id.equals(memberId))).write(
        MembersCompanion(
          createdBy: Value(receivingWorker),
          updatedAt: Value(ts),
          syncStatus: const Value('pending'),
        ),
      );
    }

    // Generate Audit Log
    final auditId = _uuid.v4();
    final chainHash = computeChainHash(
      recordId: memberId,
      transferringWorker: transferringWorker,
      receivingWorker: receivingWorker,
      timestamp: ts,
      reason: reason,
    );

    await db.into(db.auditLog).insert(
      AuditLogCompanion.insert(
        id: auditId,
        entityTable: 'members',
        recordId: memberId,
        fieldName: const Value('assigned_worker'),
        oldValue: Value(transferringWorker),
        newValue: Value(receivingWorker),
        changedBy: transferringWorker,
        deviceId: deviceId,
        appVersion: appVersion,
        deviceTimestamp: ts,
        chainHash: chainHash,
      ),
    );

    // Enqueue to BitChat SyncEngine
    if (syncEngine != null) {
      await syncEngine!.enqueue(
        table: 'audit_log',
        recordId: auditId,
        operation: 'handover_beneficiary',
        priority: SyncPriority.clinical,
        payload: {
          'id': auditId,
          'member_id': memberId,
          'transferring_worker': transferringWorker,
          'receiving_worker': receivingWorker,
          'timestamp': ts,
          'reason': reason,
          'chain_hash': chainHash,
          'target_household_id': targetHouseholdId,
          'open_tasks_count': openTasks.length,
          'dirty_flag': 1,
          'sync_version': 1,
        },
      );
    }

    return HandoverAuditRecord(
      auditLogId: auditId,
      entityType: 'members',
      recordId: memberId,
      transferringWorker: transferringWorker,
      receivingWorker: receivingWorker,
      timestamp: ts,
      reason: reason,
      chainHash: chainHash,
      affectedTasksCount: openTasks.length,
    );
  }
}

// ── Riverpod Provider ─────────────────────────────────────────────────────────

final handoverServiceProvider = Provider<HandoverService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final householdDao = HouseholdDao(db);
  final memberDao = MemberDao(db);
  final syncEngine = ref.watch(syncEngineProvider);

  return HandoverService(
    db: db,
    householdDao: householdDao,
    memberDao: memberDao,
    syncEngine: syncEngine,
  );
});
