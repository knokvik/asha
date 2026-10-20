import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

import '../database/app_database.dart';

/// Priority levels for the sync queue.
///
/// Lower numeric value = higher priority.
enum SyncPriority {
  /// P1 — Red referrals, consent withdrawals, remote-wipe acknowledgements.
  critical(1),

  /// P2 — Clinical encounters, triage results, visit completions.
  clinical(2),

  /// P3 — Metadata, stock updates, learning progress.
  metadata(3),

  /// P4 — Analytics, map cache, rule bundle pulls.
  analytics(4);

  const SyncPriority(this.value);
  final int value;
}

/// BitChat-style priority-queue sync engine.
///
/// Every write to the Local_Store calls [enqueue] with the appropriate
/// priority level. A WorkManager job (see [SyncWorker]) drains the queue
/// and POSTs gzip-compressed delta payloads to `POST /api/v1/sync/push`.
///
/// Requirements: 31.1, 31.2, 31.3
class SyncEngine {
  final AppDatabase _db;
  static const _uuid = Uuid();

  SyncEngine(this._db);

  // ── Public API ────────────────────────────────────────────────────────────

  /// Enqueue a record change for background sync.
  ///
  /// [table]     — drift table name (snake_case, matching backend).
  /// [recordId]  — UUID of the affected row.
  /// [operation] — 'insert', 'update', or 'delete'.
  /// [payload]   — Full row for insert; changed fields only for update.
  /// [eventLog]  — Append-only provenance entries for the changed fields.
  /// [priority]  — Sync priority level (default: metadata / P3).
  Future<void> enqueue({
    required String table,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
    List<Map<String, dynamic>> eventLog = const [],
    SyncPriority priority = SyncPriority.metadata,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db
        .into(_db.syncQueue)
        .insertOnConflictUpdate(
          SyncQueueCompanion.insert(
            id: _uuid.v4(),
            targetTable: table,
            recordId: recordId,
            priority: Value(priority.value),
            operation: operation,
            payloadJson: jsonEncode(payload),
            eventLogJson: Value(jsonEncode(eventLog)),
            syncStatus: const Value('pending'),
            createdAt: now,
          ),
        );
    if (priority == SyncPriority.critical) {
      // Safety-critical records should not wait for the 15-minute periodic
      // window. WorkManager preserves the same device-health constraints.
      try {
        await Workmanager().registerOneOffTask(
          'asha-urgent-sync',
          'asha-urgent-sync',
          expedited: true,
          existingWorkPolicy: ExistingWorkPolicy.replace,
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: true,
            requiresStorageNotLow: true,
          ),
          backoffPolicy: BackoffPolicy.exponential,
          backoffPolicyDelay: const Duration(seconds: 30),
        );
      } catch (_) {
        // Headless scheduling is unavailable in widget/unit tests; the queued
        // P1 record remains first in order and is picked up on next sync.
      }
    }
  }

  /// Returns a batch of up to [limit] pending records ordered by
  /// (priority ASC, created_at ASC) — highest priority first.
  Future<List<SyncQueueData>> fetchPendingBatch({int limit = 50}) async {
    return (_db.select(_db.syncQueue)
          ..where((t) => t.syncStatus.equals('pending'))
          ..orderBy([
            (t) => OrderingTerm.asc(t.priority),
            (t) => OrderingTerm.asc(t.createdAt),
          ])
          ..limit(limit))
        .get();
  }

  /// Requeues failed packets whose exponential backoff window has elapsed.
  Future<int> requeueRetryable({DateTime? now}) async {
    final currentMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final failed = await (_db.select(
      _db.syncQueue,
    )..where((t) => t.syncStatus.equals('failed'))).get();
    var requeued = 0;
    for (final record in failed) {
      final lastAttempt = record.lastAttemptAt;
      final wait = SyncBackoff.forAttempt(record.attemptCount).inMilliseconds;
      if (lastAttempt == null || currentMs - lastAttempt >= wait) {
        await (_db.update(
          _db.syncQueue,
        )..where((t) => t.id.equals(record.id))).write(
          const SyncQueueCompanion(
            syncStatus: Value('pending'),
            errorMessage: Value(null),
          ),
        );
        requeued++;
      }
    }
    return requeued;
  }

  /// Returns the newest queue entries for the in-app sync monitor.
  Future<List<SyncQueueData>> fetchQueue({int limit = 100}) {
    return (_db.select(_db.syncQueue)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Build a gzip-compressed JSON payload from a batch of sync queue records.
  ///
  /// Returns the compressed bytes ready for `POST /api/v1/sync/push`.
  Future<List<int>> buildGzipPayload({
    required String workerId,
    required String deviceId,
    required String appVersion,
    required String batchId,
    required List<SyncQueueData> records,
  }) async {
    final body = {
      'device_id': deviceId,
      'worker_id': workerId,
      'app_version': appVersion,
      'batch_id': batchId,
      'sent_at': DateTime.now().millisecondsSinceEpoch,
      'records': records.map((r) {
        Map<String, dynamic> payload = {};
        List<dynamic> eventLog = [];
        try {
          payload = jsonDecode(r.payloadJson) as Map<String, dynamic>;
          eventLog = jsonDecode(r.eventLogJson) as List<dynamic>;
        } catch (_) {}
        return {
          'table': r.targetTable,
          'record_id': r.recordId,
          'operation': r.operation,
          'priority': r.priority,
          'payload': payload,
          'event_log': eventLog,
          'device_timestamp': r.createdAt,
          'client_watermark': 0,
        };
      }).toList(),
    };

    final jsonBytes = utf8.encode(jsonEncode(body));
    return gzip.encode(jsonBytes);
  }

  /// Mark records as synced after a successful push.
  Future<void> markSynced(List<String> recordIds) async {
    await (_db.update(_db.syncQueue)..where((t) => t.id.isIn(recordIds))).write(
      const SyncQueueCompanion(syncStatus: Value('synced')),
    );
  }

  /// Mark records as failed and increment attempt count.
  Future<void> markFailed(List<String> queueIds, String errorMessage) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final qid in queueIds) {
      final record = await (_db.select(
        _db.syncQueue,
      )..where((t) => t.id.equals(qid))).getSingleOrNull();
      if (record == null) continue;
      await (_db.update(_db.syncQueue)..where((t) => t.id.equals(qid))).write(
        SyncQueueCompanion(
          syncStatus: const Value('failed'),
          lastAttemptAt: Value(now),
          attemptCount: Value(record.attemptCount + 1),
          errorMessage: Value(errorMessage),
        ),
      );
    }
  }

  /// Delete all synced entries (housekeeping).
  Future<void> purgeSynced() async {
    await (_db.delete(
      _db.syncQueue,
    )..where((t) => t.syncStatus.equals('synced'))).go();
  }
}

/// Shared retry schedule used by both foreground and WorkManager sync.
class SyncBackoff {
  static const _seconds = [30, 60, 120, 300];

  const SyncBackoff._();

  static Duration forAttempt(int attemptCount) {
    final index = attemptCount.clamp(0, _seconds.length - 1);
    return Duration(seconds: _seconds[index]);
  }
}
