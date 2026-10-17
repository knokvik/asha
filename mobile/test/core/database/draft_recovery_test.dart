import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/database/daos/drafts_dao.dart';
import 'package:asha_platform/core/database/daos/draft_recovery_service.dart';

/// Tests for [DraftRecoveryService] and [DraftsDao].
///
/// Requirements: 1.3 — In-progress form draft persisted to Local_Store;
/// restoring the same draft twice produces the same state with no
/// duplicate draft records (idempotence guarantee).
void main() {
  late AppDatabase db;
  late DraftRecoveryService svc;

  setUp(() {
    // Use an in-memory SQLite database so tests are fast and isolated.
    db = AppDatabase.forTesting(NativeDatabase.memory());
    svc = DraftRecoveryService(DraftsDao(db));
  });

  tearDown(() async => db.close());

  // ── Core CRUD ─────────────────────────────────────────────────────────────

  test('saveDraft then recoverDraft returns same data', () async {
    await svc.saveDraft(
      formType: 'hbnc_visit',
      memberId: 'member-1',
      partialData: {'weight': 2.4, 'temp': 36.5},
    );

    final recovered = await svc.recoverDraft(
      formType: 'hbnc_visit',
      memberId: 'member-1',
    );

    expect(recovered, isNotNull);
    expect(recovered!['weight'], 2.4);
    expect(recovered['temp'], 36.5);
  });

  test('recoverDraft returns null when no draft exists', () async {
    final result = await svc.recoverDraft(formType: 'no_such_form');
    expect(result, isNull);
  });

  test('clearDraft removes draft from store', () async {
    await svc.saveDraft(formType: 'triage', partialData: {'age': 3});
    await svc.clearDraft(formType: 'triage');
    final result = await svc.recoverDraft(formType: 'triage');
    expect(result, isNull);
  });

  test('listPendingDrafts returns all saved drafts', () async {
    await svc.saveDraft(
      formType: 'hbnc_visit',
      memberId: 'm1',
      partialData: {'step': 1},
    );
    await svc.saveDraft(
      formType: 'anc_visit',
      memberId: 'm2',
      partialData: {'step': 2},
    );

    final all = await svc.listPendingDrafts();
    expect(all.length, 2);
    final formTypes = all.map((d) => d.formType).toSet();
    expect(formTypes, containsAll(['hbnc_visit', 'anc_visit']));
  });

  // ── Idempotence (Property 2 — Requirement 1.3) ───────────────────────────

  test('saveDraft is idempotent — N saves produce exactly 1 draft record', () async {
    for (var i = 0; i < 5; i++) {
      await svc.saveDraft(
        formType: 'anc_visit',
        memberId: 'member-2',
        partialData: {'lmp': '2024-01-01', 'attempt': i},
      );
    }

    final all = await svc.listPendingDrafts();
    final matching = all
        .where((d) => d.formType == 'anc_visit' && d.memberId == 'member-2')
        .toList();

    // Exactly one record — no duplicates.
    expect(matching.length, 1);

    // Last-write wins — the final attempt value is 4.
    final dao = DraftsDao(db);
    final data = dao.decodeData(matching.first);
    expect(data['attempt'], 4);
  });

  test('recovering a draft N times returns same data each time', () async {
    await svc.saveDraft(
      formType: 'triage',
      memberId: 'member-3',
      partialData: {'respiratoryRate': 62, 'age_days': 30},
    );

    // Recover three times.
    final r1 = await svc.recoverDraft(formType: 'triage', memberId: 'member-3');
    final r2 = await svc.recoverDraft(formType: 'triage', memberId: 'member-3');
    final r3 = await svc.recoverDraft(formType: 'triage', memberId: 'member-3');

    expect(r1, isNotNull);
    expect(r1, equals(r2));
    expect(r2, equals(r3));

    // Still only one draft record after repeated reads.
    final all = await svc.listPendingDrafts();
    final matching = all
        .where((d) => d.formType == 'triage' && d.memberId == 'member-3')
        .toList();
    expect(matching.length, 1);
  });

  // ── JSON round-trip ───────────────────────────────────────────────────────

  test('draft round-trip preserves nested data types', () async {
    final originalData = {
      'stringField': 'hello',
      'intField': 42,
      'doubleField': 3.14,
      'boolField': true,
      'nullField': null,
      'listField': [1, 2, 3],
      'mapField': {'nested': 'value'},
    };

    await svc.saveDraft(
      formType: 'complex_form',
      partialData: originalData,
    );

    final recovered = await svc.recoverDraft(formType: 'complex_form');
    expect(recovered, isNotNull);
    expect(recovered!['stringField'], 'hello');
    expect(recovered['intField'], 42);
    expect(recovered['doubleField'], closeTo(3.14, 0.0001));
    expect(recovered['boolField'], true);
    expect(recovered['nullField'], isNull);
    expect(recovered['listField'], [1, 2, 3]);
    expect((recovered['mapField'] as Map)['nested'], 'value');
  });

  // ── Isolation between form types ─────────────────────────────────────────

  test('drafts are isolated by formType and memberId', () async {
    await svc.saveDraft(
      formType: 'form_a',
      memberId: 'member-x',
      partialData: {'value': 'a'},
    );
    await svc.saveDraft(
      formType: 'form_b',
      memberId: 'member-x',
      partialData: {'value': 'b'},
    );
    await svc.saveDraft(
      formType: 'form_a',
      memberId: 'member-y',
      partialData: {'value': 'c'},
    );

    final draftAX = await svc.recoverDraft(formType: 'form_a', memberId: 'member-x');
    final draftBX = await svc.recoverDraft(formType: 'form_b', memberId: 'member-x');
    final draftAY = await svc.recoverDraft(formType: 'form_a', memberId: 'member-y');

    expect(draftAX!['value'], 'a');
    expect(draftBX!['value'], 'b');
    expect(draftAY!['value'], 'c');

    // Three distinct drafts.
    final all = await svc.listPendingDrafts();
    expect(all.length, 3);
  });

  test('clearDraft only removes the specified formType', () async {
    await svc.saveDraft(formType: 'form_a', partialData: {'x': 1});
    await svc.saveDraft(formType: 'form_b', partialData: {'y': 2});

    await svc.clearDraft(formType: 'form_a');

    expect(await svc.recoverDraft(formType: 'form_a'), isNull);
    expect(await svc.recoverDraft(formType: 'form_b'), isNotNull);
  });
}
