import 'dart:math';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/database/daos/drafts_dao.dart';
import 'package:asha_platform/core/database/daos/draft_recovery_service.dart';

/// Property-Based Test: Draft Recovery Idempotence (Property 2)
///
/// **Property 2: Draft Recovery Idempotence**
/// For any in-progress form draft stored in the Local_Store, applying the draft
/// recovery sequence (read draft → populate form) any number of times must produce
/// the same form state and must never create more than one draft record per form session.
///
/// **Validates: Requirements 1.3**
void main() {
  late AppDatabase db;
  late DraftsDao dao;
  late DraftRecoveryService svc;
  final random = Random(42); // Deterministic seed for reproducible property runs

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = DraftsDao(db);
    svc = DraftRecoveryService(dao);
  });

  tearDown(() async => db.close());

  // Generator helper for arbitrary nested JSON-compatible test data
  dynamic generateArbitraryValue(int depth) {
    if (depth > 3) {
      return random.nextBool()
          ? 'leaf_${random.nextInt(1000)}'
          : random.nextInt(10000);
    }

    switch (random.nextInt(5)) {
      case 0:
        return random.nextInt(50000) - 25000;
      case 1:
        return (random.nextDouble() * 200 - 100).toStringAsFixed(2);
      case 2:
        return random.nextBool();
      case 3:
        final len = random.nextInt(4);
        return List.generate(
            len, (_) => generateArbitraryValue(depth + 1));
      case 4:
      default:
        final len = random.nextInt(4) + 1;
        return {
          for (var i = 0; i < len; i++)
            'k_${depth}_$i': generateArbitraryValue(depth + 1),
        };
    }
  }

  Map<String, dynamic> generateArbitraryFormData() {
    final fieldCount = random.nextInt(10) + 1;
    final map = <String, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      map['field_$i'] = generateArbitraryValue(0);
    }
    return map;
  }

  test('Property 2: N repeated saveDraft calls produce exactly 1 record and identical recovered state across 100 randomized trials', () async {
    const trials = 100;

    for (var t = 0; t < trials; t++) {
      final formType = 'form_${random.nextInt(10)}';
      final memberId = random.nextBool() ? 'member_${random.nextInt(50)}' : null;
      final arbitraryData = generateArbitraryFormData();
      final nRepeats = random.nextInt(8) + 2; // N in range 2..10

      // Apply saveDraft N times with the same session key
      for (var n = 0; n < nRepeats; n++) {
        await svc.saveDraft(
          formType: formType,
          memberId: memberId,
          partialData: arbitraryData,
        );
      }

      // 1. Recover draft multiple times and verify exact data state
      final recovered1 = await svc.recoverDraft(formType: formType, memberId: memberId);
      final recovered2 = await svc.recoverDraft(formType: formType, memberId: memberId);

      expect(recovered1, isNotNull, reason: 'Trial $t: recovered draft should not be null');
      expect(recovered2, isNotNull, reason: 'Trial $t: second recovery should not be null');
      expect(recovered1, equals(recovered2), reason: 'Trial $t: repeated recoveries must produce identical state');
      expect(recovered1, equals(arbitraryData), reason: 'Trial $t: recovered data must match original arbitrary input');

      // 2. Verify invariant: exactly ONE draft record exists in Local_Store for this form session
      final allDrafts = await dao.listAllDrafts();
      final matchingRecords = allDrafts.where(
        (d) => d.formType == formType && d.memberId == memberId,
      ).toList();

      expect(
        matchingRecords.length,
        1,
        reason: 'Trial $t: Expected exactly 1 draft record after $nRepeats saves, found ${matchingRecords.length}',
      );

      // Clean up for next trial
      await svc.clearDraft(formType: formType, memberId: memberId);
      expect(
        await svc.recoverDraft(formType: formType, memberId: memberId),
        isNull,
        reason: 'Trial $t: cleared draft should be null',
      );
    }
  });
}
