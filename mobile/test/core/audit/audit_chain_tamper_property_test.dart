import 'dart:math';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/database/audit_chain_service.dart';

/// Property-Based Test: Audit Hash-Chain Tamper Detection (Property 14)
/// and Event-Log Replay Consistency (Property 15).
///
/// **Property 14: Audit Hash-Chain Tamper Detection**
/// For any synced audit log chain, modifying any byte of any historical entry
/// (field value, timestamp, user ID, or record ID) must cause chain-hash verification to fail.
///
/// **Property 15: Event-Log Replay Consistency**
/// Replaying the ordered event log from the beginning must reproduce the current field values.
///
/// **Validates: Requirements 1.2, 5.2, 33.2, 33.3**
void main() {
  final random = Random(4242);
  const iterations = 500;

  String randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_';
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  group('Property 14: Audit Hash-Chain Tamper Detection (500 iterations)', () {
    test('Modifying any single byte or field of any historical entry breaks chain verification', () {
      for (var t = 0; t < iterations; t++) {
        final chainLength = random.nextInt(10) + 3; // 3 to 12 entries
        final recordId = 'rec_${random.nextInt(10000)}';
        final table = 'members';
        final entries = <AuditLogData>[];
        var prevHash = AuditChainService.genesisHash;
        var currentTs = 1700000000000;

        for (var i = 0; i < chainLength; i++) {
          final id = 'audit_${t}_$i';
          final field = 'field_${random.nextInt(5)}';
          final oldVal = 'val_${random.nextInt(100)}';
          final newVal = 'val_${random.nextInt(100) + 200}';
          final changedBy = 'asha_${random.nextInt(50)}';
          currentTs += random.nextInt(10000) + 100;

          final hash = AuditChainService.computeChainHash(
            previousHash: prevHash,
            tableName: table,
            recordId: recordId,
            fieldName: field,
            oldValue: oldVal,
            newValue: newVal,
            changedBy: changedBy,
            deviceTimestamp: currentTs,
          );

          final entry = AuditLogData(
            id: id,
            entityTable: table,
            recordId: recordId,
            fieldName: field,
            oldValue: oldVal,
            newValue: newVal,
            changedBy: changedBy,
            deviceId: 'dev_1',
            appVersion: '1.0.0',
            deviceTimestamp: currentTs,
            chainHash: hash,
          );

          entries.add(entry);
          prevHash = hash;
        }

        // 1. Untampered chain MUST verify successfully
        expect(
          AuditChainService.verifyChain(entries),
          isTrue,
          reason: 'Trial $t: untampered chain of length $chainLength should verify',
        );

        // 2. Select a random historical entry to tamper
        final tamperIdx = random.nextInt(chainLength);
        final target = entries[tamperIdx];

        // Tamper one property
        final tamperField = random.nextInt(6);
        late AuditLogData tamperedEntry;

        switch (tamperField) {
          case 0: // Tamper old value
            tamperedEntry = target.copyWith(oldValue: Value('${target.oldValue}_X'));
          case 1: // Tamper new value
            tamperedEntry = target.copyWith(newValue: Value('${target.newValue}_TAMPERED'));
          case 2: // Tamper user who changed it
            tamperedEntry = target.copyWith(changedBy: 'attacker_user');
          case 3: // Tamper timestamp
            tamperedEntry = target.copyWith(deviceTimestamp: target.deviceTimestamp + 1);
          case 4: // Tamper record ID
            tamperedEntry = target.copyWith(recordId: '${target.recordId}_hack');
          case 5: // Tamper field name
          default:
            tamperedEntry = target.copyWith(fieldName: Value('${target.fieldName}_bad'));
        }

        final tamperedChain = List<AuditLogData>.from(entries);
        tamperedChain[tamperIdx] = tamperedEntry;

        // 3. Chain verification MUST fail on tampered chain
        expect(
          AuditChainService.verifyChain(tamperedChain),
          isFalse,
          reason: 'Trial $t: verification must fail after tampering entry $tamperIdx field $tamperField',
        );
      }
    });
  });

  group('Property 15: Event-Log Replay Consistency (500 iterations)', () {
    test('Replaying ordered audit event log reproduces current record values exactly', () {
      for (var t = 0; t < iterations; t++) {
        // Initial beneficiary record
        final initialState = <String, dynamic>{
          'name': 'Original Name ${randomString(5)}',
          'phone': '9800000000',
          'consent_status': 'pending',
          'lifecycle_status': 'active',
          'weight_kg': '55.0',
        };

        final currentState = Map<String, dynamic>.from(initialState);
        final eventLog = <AuditLogData>[];
        final eventCount = random.nextInt(10) + 2;
        var ts = 1700000000000;

        final modifiableFields = ['name', 'phone', 'consent_status', 'lifecycle_status', 'weight_kg'];

        for (var e = 0; e < eventCount; e++) {
          final field = modifiableFields[random.nextInt(modifiableFields.length)];
          final oldVal = currentState[field]?.toString();
          final newVal = 'val_${e}_${randomString(6)}';

          // Apply to ground truth
          currentState[field] = newVal;
          ts += random.nextInt(5000) + 100;

          final entry = AuditLogData(
            id: 'evt_${t}_$e',
            entityTable: 'members',
            recordId: 'mem_$t',
            fieldName: field,
            oldValue: oldVal,
            newValue: newVal,
            changedBy: 'worker_${random.nextInt(10)}',
            deviceId: 'dev_1',
            appVersion: '1.0.0',
            deviceTimestamp: ts,
            chainHash: 'hash_$e',
          );
          eventLog.add(entry);
        }

        // Shuffle events before replay to verify replay orders them chronologically
        final shuffledLog = List<AuditLogData>.from(eventLog)..shuffle(random);

        // Reconstruct state via replay
        final reconstructedState = AuditChainService.replayEventLog(
          initialState: initialState,
          eventLog: shuffledLog,
        );

        // Assert reconstructed state matches current ground-truth state
        expect(
          reconstructedState,
          equals(currentState),
          reason: 'Trial $t: Replay must exactly reproduce current record state after $eventCount events',
        );

        // Verify that omitting the final event causes state divergence
        if (eventLog.isNotEmpty) {
          final incompleteLog = List<AuditLogData>.from(eventLog)..removeLast();
          final incompleteState = AuditChainService.replayEventLog(
            initialState: initialState,
            eventLog: incompleteLog,
          );
          final lastEvent = eventLog.last;
          if (lastEvent.oldValue != lastEvent.newValue) {
            expect(
              incompleteState[lastEvent.fieldName!],
              isNot(equals(currentState[lastEvent.fieldName!])),
              reason: 'Trial $t: Incomplete event log must not match final state for field ${lastEvent.fieldName}',
            );
          }
        }
      }
    });
  });
}
