import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/sync/conflict_resolver.dart';

/// Property-Based Test: Conflict Merge Confluence (Property 16)
///
/// **Property 16: Conflict Merge Confluence**
/// For any two independent sets of offline edits A and B applied to the same base record,
/// merging A into B must produce the same result as merging B into A for all
/// non-conflicting fields (fields edited by at most one of A or B):
/// `merge(A, merge(B, base)) == merge(B, merge(A, base))`
///
/// **Validates: Requirements 32.2**
void main() {
  final random = Random(5555);
  const iterations = 500;

  String randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_';
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  group('Property 16: Conflict Merge Confluence (500 iterations)', () {
    test('Merging independent edit sets A and B is confluent for all non-conflicting and conflicting fields', () {
      final allPossibleFields = [
        'name',
        'phone',
        'dob_approx',
        'is_bpl',
        'social_category',
        'address',
        'consent_status',
        'lifecycle_status',
        'village_code',
        'hamlet',
      ];

      for (var t = 0; t < iterations; t++) {
        // 1. Generate base record
        final base = <String, dynamic>{
          'name': 'Base Beneficiary ${randomString(5)}',
          'phone': '9800000000',
          'dob_approx': 946684800000,
          'is_bpl': true,
          'social_category': 'OBC',
          'address': 'House 12, Ward 3',
          'consent_status': 'given',
          'lifecycle_status': 'active',
          'village_code': 'VIL_101',
          'hamlet': 'Upper Tola',
        };

        // 2. Partition fields randomly into:
        // - edited only in A
        // - edited only in B
        // - edited in both A and B (conflicting)
        // - edited in neither (unchanged)
        final shuffledFields = List<String>.from(allPossibleFields)..shuffle(random);
        final nEditsA = random.nextInt(4) + 1; // 1 to 4
        final nEditsB = random.nextInt(4) + 1; // 1 to 4

        final fieldsA = shuffledFields.take(nEditsA).toSet();
        final fieldsB = shuffledFields.skip(random.nextInt(3)).take(nEditsB).toSet();

        final nonConflictingAOnly = fieldsA.difference(fieldsB);
        final nonConflictingBOnly = fieldsB.difference(fieldsA);
        final uneditedFields = allPossibleFields.toSet().difference(fieldsA.union(fieldsB));
        final conflictingFields = fieldsA.intersection(fieldsB);

        final editsA = <String, FieldUpdate>{};
        final editsB = <String, FieldUpdate>{};

        for (final field in fieldsA) {
          editsA[field] = FieldUpdate(
            value: 'val_A_${field}_${randomString(4)}',
            timestamp: 1700000000000 + random.nextInt(10000),
            changedBy: 'worker_A_${random.nextInt(5)}',
          );
        }

        for (final field in fieldsB) {
          editsB[field] = FieldUpdate(
            value: 'val_B_${field}_${randomString(4)}',
            timestamp: 1700000000000 + random.nextInt(10000),
            changedBy: 'worker_B_${random.nextInt(5)}',
          );
        }

        // 3. Apply in order A then B: merge(B, merge(A, base))
        final stateAfterA = ConflictResolver.applyFieldEdits(base, editsA);
        final stateAB = ConflictResolver.applyFieldEdits(stateAfterA, editsB);

        // 4. Apply in order B then A: merge(A, merge(B, base))
        final stateAfterB = ConflictResolver.applyFieldEdits(base, editsB);
        final stateBA = ConflictResolver.applyFieldEdits(stateAfterB, editsA);

        // 5. Invariant Assertion: Non-conflicting fields edited by A only MUST match
        for (final field in nonConflictingAOnly) {
          expect(
            stateAB[field],
            equals(editsA[field]!.value),
            reason: 'Trial $t: Field $field edited only by A must equal A value in AB',
          );
          expect(
            stateBA[field],
            equals(editsA[field]!.value),
            reason: 'Trial $t: Field $field edited only by A must equal A value in BA',
          );
          expect(
            stateAB[field],
            equals(stateBA[field]),
            reason: 'Trial $t: Non-conflicting field $field must be confluent',
          );
        }

        // 6. Invariant Assertion: Non-conflicting fields edited by B only MUST match
        for (final field in nonConflictingBOnly) {
          expect(
            stateAB[field],
            equals(editsB[field]!.value),
            reason: 'Trial $t: Field $field edited only by B must equal B value in AB',
          );
          expect(
            stateBA[field],
            equals(editsB[field]!.value),
            reason: 'Trial $t: Field $field edited only by B must equal B value in BA',
          );
          expect(
            stateAB[field],
            equals(stateBA[field]),
            reason: 'Trial $t: Non-conflicting field $field must be confluent',
          );
        }

        // 7. Invariant Assertion: Unedited fields must preserve base value
        for (final field in uneditedFields) {
          expect(
            stateAB[field],
            equals(base[field]),
            reason: 'Trial $t: Unedited field $field must retain base value in AB',
          );
          expect(
            stateBA[field],
            equals(base[field]),
            reason: 'Trial $t: Unedited field $field must retain base value in BA',
          );
          expect(
            stateAB[field],
            equals(stateBA[field]),
            reason: 'Trial $t: Unedited field $field must be confluent',
          );
        }

        // 8. Invariant Assertion: Conflicting fields also resolve identically due to LWW confluence
        for (final field in conflictingFields) {
          expect(
            stateAB[field],
            equals(stateBA[field]),
            reason: 'Trial $t: Conflicting field $field must converge deterministically in both merge orders',
          );
        }

        // 9. Full record confluence check
        for (final field in allPossibleFields) {
          expect(
            stateAB[field],
            equals(stateBA[field]),
            reason: 'Trial $t: Total confluence violated for field $field',
          );
        }

        // 10. Verify mergeIndependentEdits helper
        final mergedDirect = ConflictResolver.mergeIndependentEdits(base, editsA, editsB);
        for (final field in allPossibleFields) {
          expect(mergedDirect[field], equals(stateAB[field]));
        }
      }
    });

    test('Edge cases: disjoint, empty, and exact timestamp collisions with tie-breaker', () {
      final base = {'status': 'active', 'score': 10};

      // Empty edits
      final r1 = ConflictResolver.mergeIndependentEdits(base, {}, {});
      expect(r1['status'], 'active');
      expect(r1['score'], 10);

      // Disjoint edits
      final editsA = {
        'status': const FieldUpdate(value: 'pending', timestamp: 100, changedBy: 'u1'),
      };
      final editsB = {
        'score': const FieldUpdate(value: 20, timestamp: 200, changedBy: 'u2'),
      };
      final ab = ConflictResolver.applyFieldEdits(ConflictResolver.applyFieldEdits(base, editsA), editsB);
      final ba = ConflictResolver.applyFieldEdits(ConflictResolver.applyFieldEdits(base, editsB), editsA);
      expect(ab['status'], ba['status']);
      expect(ab['score'], ba['score']);
      expect(ab['status'], 'pending');
      expect(ab['score'], 20);

      // Same timestamp collision — deterministic tie breaker by changedBy
      final collisionA = {
        'status': const FieldUpdate(value: 'status_from_A', timestamp: 500, changedBy: 'user_alice'),
      };
      final collisionB = {
        'status': const FieldUpdate(value: 'status_from_Z', timestamp: 500, changedBy: 'user_zack'),
      };
      final collAB = ConflictResolver.applyFieldEdits(ConflictResolver.applyFieldEdits(base, collisionA), collisionB);
      final collBA = ConflictResolver.applyFieldEdits(ConflictResolver.applyFieldEdits(base, collisionB), collisionA);
      expect(collAB['status'], collBA['status']);
      expect(collAB['status'], 'status_from_Z'); // user_zack wins tie-breaker alphabetically
    });
  });
}
