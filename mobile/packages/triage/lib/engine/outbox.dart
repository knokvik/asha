/// Stub of the offline outbox. The server module owns the real queue.
///
/// Each finished assessment is appended here while the phone is offline.
/// When the network returns, that module posts the queue. The server adds the
/// week's ward counts and publishes the next pack version. [AdaptiveTriage.updateContextPack]
/// then drops the cached flow so the following assessment uses the new modules.
class OutboxItem {
  const OutboxItem({
    required this.packVersion,
    required this.districtId,
    required this.wardId,
    required this.flag,
    required this.referralSms,
  });

  final int packVersion;
  final String districtId;
  final String wardId;
  final String flag;
  final String referralSms;
}

class OutboxSink {
  final List<OutboxItem> pending = [];

  void add(OutboxItem item) => pending.add(item);
}
