import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:asha_platform/core/database/app_database.dart';

/// Service implementing SHA-256 hash-chaining over audit log entries
/// and event-log replay consistency.
///
/// Validates:
/// - Requirement 33.1: Author user ID, device ID, app version, timestamps.
/// - Requirement 33.2: Tamper-evident SHA-256 hash chain over event log.
/// - Requirement 33.3: Event-log replay consistency (reconstruct(eventLog) == currentRecord).
/// - Properties 14 & 15.
class AuditChainService {
  final AppDatabase db;
  static const String genesisHash = '0000000000000000000000000000000000000000000000000000000000000000';

  AuditChainService(this.db);

  /// Computes the cryptographic SHA-256 chain hash for a log entry.
  ///
  /// H_i = SHA-256(H_{i-1} || table_name || record_id || field_name || old_val || new_val || changed_by || device_ts)
  static String computeChainHash({
    required String previousHash,
    required String tableName,
    required String recordId,
    required String? fieldName,
    required String? oldValue,
    required String? newValue,
    required String changedBy,
    required int deviceTimestamp,
  }) {
    final payload = '$previousHash|$tableName|$recordId|${fieldName ?? ''}|${oldValue ?? ''}|${newValue ?? ''}|$changedBy|$deviceTimestamp';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// Appends an audit log entry with continuous hash-chaining to the database.
  Future<AuditLogData> appendEntry({
    required String id,
    required String tableName,
    required String recordId,
    String? fieldName,
    String? oldValue,
    String? newValue,
    required String changedBy,
    required String deviceId,
    required String appVersion,
    String? ruleVersionId,
    required int deviceTimestamp,
    int? serverTimestamp,
  }) async {
    // 1. Find the most recent audit entry for this record to obtain the previous hash
    final existingEntries = await (db.select(db.auditLog)
          ..where((tbl) => tbl.recordId.equals(recordId))
          ..orderBy([
            (tbl) => OrderingTerm.asc(tbl.deviceTimestamp),
            (tbl) => OrderingTerm.asc(tbl.id),
          ]))
        .get();

    final previousHash = existingEntries.isEmpty
        ? genesisHash
        : existingEntries.last.chainHash;

    final chainHash = computeChainHash(
      previousHash: previousHash,
      tableName: tableName,
      recordId: recordId,
      fieldName: fieldName,
      oldValue: oldValue,
      newValue: newValue,
      changedBy: changedBy,
      deviceTimestamp: deviceTimestamp,
    );

    final companion = AuditLogCompanion.insert(
      id: id,
      entityTable: tableName,
      recordId: recordId,
      fieldName: Value(fieldName),
      oldValue: Value(oldValue),
      newValue: Value(newValue),
      changedBy: changedBy,
      deviceId: deviceId,
      appVersion: appVersion,
      ruleVersionId: Value(ruleVersionId),
      deviceTimestamp: deviceTimestamp,
      serverTimestamp: Value(serverTimestamp),
      chainHash: chainHash,
    );

    await db.into(db.auditLog).insert(companion);

    return (await (db.select(db.auditLog)..where((tbl) => tbl.id.equals(id))).getSingle());
  }

  /// Verifies the cryptographic integrity of an audit chain.
  ///
  /// Returns `true` if every entry's chain hash matches the recomputed hash
  /// from the previous link in the chain. Modifying even 1 byte anywhere breaks verification.
  static bool verifyChain(List<AuditLogData> entries, {String initialHash = genesisHash}) {
    if (entries.isEmpty) return true;

    var currentPrevHash = initialHash;

    for (final entry in entries) {
      final expectedHash = computeChainHash(
        previousHash: currentPrevHash,
        tableName: entry.entityTable,
        recordId: entry.recordId,
        fieldName: entry.fieldName,
        oldValue: entry.oldValue,
        newValue: entry.newValue,
        changedBy: entry.changedBy,
        deviceTimestamp: entry.deviceTimestamp,
      );

      if (entry.chainHash != expectedHash) {
        return false;
      }
      currentPrevHash = entry.chainHash;
    }

    return true;
  }

  /// Property 15: Reconstructs current record fields by replaying the ordered event log.
  ///
  /// Replaying the ordered event log from beginning must reproduce the current state.
  static Map<String, dynamic> replayEventLog({
    required Map<String, dynamic> initialState,
    required List<AuditLogData> eventLog,
  }) {
    // Sort chronologically
    final sorted = List<AuditLogData>.from(eventLog)
      ..sort((a, b) {
        final c = a.deviceTimestamp.compareTo(b.deviceTimestamp);
        if (c != 0) return c;
        return a.id.compareTo(b.id);
      });

    final state = Map<String, dynamic>.from(initialState);

    for (final event in sorted) {
      if (event.fieldName != null) {
        state[event.fieldName!] = event.newValue;
      }
    }

    return state;
  }
}
