import 'package:sync_outbox/sync_outbox.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 19, 12);

  test('enqueue survives with no network and dedups the idempotency key', () {
    final box = Outbox();
    final first = box.enqueue(
      id: '1',
      payloadJson: '{"flag":"RED"}',
      type: 'referral',
      createdAt: now,
      idempotencyKey: 'case-1',
    );
    final second = box.enqueue(
      id: '2',
      payloadJson: '{"flag":"RED"}',
      type: 'referral',
      createdAt: now,
      idempotencyKey: 'case-1',
    );
    expect(identical(first, second), isTrue);
    expect(box.items, hasLength(1));
    expect(box.nextBatch(now).single.status, OutboxStatus.pending);
  });

  test('a batch stops at 50 and keeps older items first', () {
    final box = Outbox();
    for (var i = 0; i < 55; i++) {
      box.enqueue(
        id: '$i',
        payloadJson: '{}',
        type: 'assessment',
        createdAt: now.add(Duration(minutes: 55 - i)),
        idempotencyKey: 'k$i',
      );
    }
    final batch = box.nextBatch(now);
    expect(batch, hasLength(50));
    expect(batch.first.createdAt.isBefore(batch.last.createdAt), isTrue);
  });

  test('sent items leave the batch and failures wait out the backoff', () {
    final box = Outbox();
    box.enqueue(id: 'a', payloadJson: '{}', type: 'referral', createdAt: now, idempotencyKey: 'a');
    box.enqueue(id: 'b', payloadJson: '{}', type: 'referral', createdAt: now, idempotencyKey: 'b');
    box.markSent(['a']);
    box.markFailed('b', now);
    expect(box.nextBatch(now), isEmpty);
    expect(Outbox.backoff(1), const Duration(seconds: 30));
    expect(Outbox.backoff(2), const Duration(seconds: 60));
    expect(box.nextBatch(now.add(const Duration(seconds: 30))).single.id, 'b');
  });
}
