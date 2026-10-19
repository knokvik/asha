/// Local queue that survives a down server.
///
/// The phone already has a Drift `SyncQueue` and a WorkManager task. This
/// type is the policy those call: one local write, batches of at most 50,
/// idempotency keys, and exponential backoff. It does not open a socket.
enum OutboxStatus { pending, sent, failed }

class OutboxItem {
  OutboxItem({
    required this.id,
    required this.payloadJson,
    required this.type,
    required this.createdAt,
    required this.idempotencyKey,
    this.attempts = 0,
    this.status = OutboxStatus.pending,
    this.nextAttemptAt,
  });

  final String id;
  final String payloadJson;
  final String type;
  final DateTime createdAt;
  int attempts;
  final String idempotencyKey;
  OutboxStatus status;
  DateTime? nextAttemptAt;
}

class Outbox {
  Outbox({this.batchSize = 50});

  final int batchSize;
  final List<OutboxItem> _items = [];

  List<OutboxItem> get items => List.unmodifiable(_items);

  /// Returns the existing row when the idempotency key was already queued.
  OutboxItem enqueue({
    required String id,
    required String payloadJson,
    required String type,
    required DateTime createdAt,
    required String idempotencyKey,
  }) {
    for (final item in _items) {
      if (item.idempotencyKey == idempotencyKey) return item;
    }
    final item = OutboxItem(
      id: id,
      payloadJson: payloadJson,
      type: type,
      createdAt: createdAt,
      idempotencyKey: idempotencyKey,
    );
    _items.add(item);
    return item;
  }

  List<OutboxItem> nextBatch(DateTime now) {
    final due = _items.where((item) {
      if (item.status == OutboxStatus.sent) return false;
      final next = item.nextAttemptAt;
      return next == null || !next.isAfter(now);
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (due.length <= batchSize) return due;
    return due.sublist(0, batchSize);
  }

  void markSent(Iterable<String> ids) {
    final wanted = ids.toSet();
    for (final item in _items) {
      if (wanted.contains(item.id)) item.status = OutboxStatus.sent;
    }
  }

  void markFailed(String id, DateTime now) {
    final item = _items.firstWhere((row) => row.id == id);
    item.attempts += 1;
    item.status = OutboxStatus.failed;
    item.nextAttemptAt = now.add(backoff(item.attempts));
  }

  /// 30s, 60s, 120s, … capped at 15 minutes.
  static Duration backoff(int attempts) {
    final seconds = 30 * (1 << (attempts - 1).clamp(0, 5));
    final capped = seconds > 900 ? 900 : seconds;
    return Duration(seconds: capped);
  }
}
