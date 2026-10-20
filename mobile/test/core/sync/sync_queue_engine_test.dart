import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';

void main() {
  late AppDatabase database;
  late SyncEngine engine;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    engine = SyncEngine(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('failed packets increment attempts and requeue after backoff', () async {
    await engine.enqueue(
      table: 'members',
      recordId: 'member-1',
      operation: 'update',
      payload: const {'name': 'Sunita Sharma'},
    );

    final queued = await engine.fetchPendingBatch();
    expect(queued, hasLength(1));

    await engine.markFailed([queued.single.id], 'network unavailable');
    final failed = await engine.fetchQueue();
    expect(failed.single.attemptCount, 1);
    expect(failed.single.syncStatus, 'failed');

    final retryAt = DateTime.fromMillisecondsSinceEpoch(
      failed.single.lastAttemptAt! + SyncBackoff.forAttempt(1).inMilliseconds,
    );
    expect(await engine.requeueRetryable(now: retryAt), 1);
    expect((await engine.fetchPendingBatch()).single.id, queued.single.id);
  });
}
