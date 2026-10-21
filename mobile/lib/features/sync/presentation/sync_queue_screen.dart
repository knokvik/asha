import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../shared/providers/core_providers.dart';

class SyncQueueScreen extends ConsumerWidget {
  const SyncQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(syncCoordinatorProvider);
    if (coordinator == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Offline Sync')),
        body: Center(
          child: Text('Unlock the app to view the local sync queue.'),
        ),
      );
    }
    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) => _buildScaffold(context, coordinator),
    );
  }

  Widget _buildScaffold(BuildContext context, SyncCoordinator coordinator) {
    final snapshot = coordinator.snapshot;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync'),
        actions: [
          IconButton(
            key: const Key('sync_refresh_button'),
            tooltip: 'Refresh queue',
            onPressed: coordinator.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            key: const Key('sync_now_button'),
            tooltip: 'Sync now',
            onPressed: snapshot.state == SyncConnectionState.syncing
                ? null
                : coordinator.syncNow,
            icon: const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: coordinator.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _SyncSummaryCard(snapshot: snapshot),
            if (snapshot.state == SyncConnectionState.syncing)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: LinearProgressIndicator(),
              ),
            if (snapshot.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  snapshot.errorMessage!,
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                ),
              ),
            const SizedBox(height: 18),
            if (snapshot.records.isEmpty)
              const _EmptyQueue()
            else ...[
              Text(
                'Stored packets (${snapshot.records.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...snapshot.records.map(
                (record) => _QueuePacketTile(record: record),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SyncSummaryCard extends StatelessWidget {
  final SyncSnapshot snapshot;

  const _SyncSummaryCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final isHealthy = snapshot.state == SyncConnectionState.ready;
    final color = isHealthy ? Colors.teal.shade800 : Colors.orange.shade900;
    final title = switch (snapshot.state) {
      SyncConnectionState.syncing => 'Syncing packets…',
      SyncConnectionState.ready => 'All packets are up to date',
      SyncConnectionState.error => 'Waiting to reconnect',
      SyncConnectionState.offline => 'Working offline',
    };
    return Card(
      margin: EdgeInsets.zero,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isHealthy ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: color,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.w700, color: color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.pendingCount == 0
                        ? 'No packets are waiting on this device.'
                        : '${snapshot.pendingCount} packet${snapshot.pendingCount == 1 ? '' : 's'} waiting to send',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueuePacketTile extends StatelessWidget {
  final SyncQueueData record;

  const _QueuePacketTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final summary = _PacketSummary.fromRecord(record);
    final isFailed = record.syncStatus == 'failed';
    final isSynced = record.syncStatus == 'synced';
    final color = isFailed
        ? Colors.orange.shade800
        : isSynced
        ? Colors.teal.shade700
        : Colors.blue.shade700;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _showPacketDetails(context, summary),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isFailed
                ? Icons.warning_amber_rounded
                : isSynced
                ? Icons.check_rounded
                : Icons.outbox_rounded,
            color: color,
          ),
        ),
        title: Text(
          summary.title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${summary.subtitle}\nP${record.priority} • ${_formatTime(timestamp)}',
          style: const TextStyle(fontSize: 11),
        ),
        isThreeLine: true,
        trailing: Text(
          record.syncStatus,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  void _showPacketDetails(BuildContext context, _PacketSummary summary) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _PacketDetailSheet(record: record, summary: summary),
    );
  }
}

class _PacketSummary {
  const _PacketSummary({
    required this.recordId,
    required this.payload,
    required this.attachments,
  });

  final String recordId;
  final Map<String, dynamic> payload;
  final List<_PacketAttachment> attachments;

  factory _PacketSummary.fromRecord(SyncQueueData record) {
    Map<String, dynamic> payload = const {};
    try {
      final decoded = jsonDecode(record.payloadJson);
      if (decoded is Map<String, dynamic>) payload = decoded;
    } on FormatException {
      // Older queue records may not have JSON payloads.
    }
    final rawAttachments = payload['attachments_json'];
    List<dynamic> items = const [];
    try {
      items = rawAttachments is String
          ? jsonDecode(rawAttachments) as List<dynamic>
          : rawAttachments as List<dynamic>? ?? const [];
    } on FormatException {
      // No usable evidence is safer than exposing an unreadable raw payload.
    }
    return _PacketSummary(
      recordId: record.recordId,
      payload: payload,
      attachments: [
        for (var index = 0; index < items.length; index++)
          if (items[index] is Map)
            _PacketAttachment.fromJson(
              Map<String, dynamic>.from(items[index] as Map),
              index,
            ),
      ],
    );
  }

  String get title {
    if (payload.isNotEmpty && payload.containsKey('flag')) {
      final name = _text(payload['name'], fallback: 'unnamed patient');
      return 'Triage ticket · $name';
    }
    return '${_text(payload['operation'], fallback: 'Sync').toUpperCase()} packet';
  }

  String get subtitle {
    final caseId = _text(payload['case_id'], fallback: '');
    final details = <String>[
      if (caseId.isNotEmpty) 'Case $caseId',
      if (recordId.isNotEmpty) 'Ticket $recordId',
      if (attachments.isNotEmpty)
        '${attachments.length} attachment${attachments.length == 1 ? '' : 's'}',
    ];
    return details.isEmpty ? 'Record details available' : details.join(' · ');
  }

  static String _text(Object? value, {required String fallback}) {
    final valueText = value?.toString().trim() ?? '';
    return valueText.isEmpty ? fallback : valueText;
  }
}

class _PacketAttachment {
  const _PacketAttachment({
    required this.index,
    required this.type,
    required this.mimeType,
    required this.dataBase64,
    required this.originalBytes,
  });

  final int index;
  final String type;
  final String mimeType;
  final String dataBase64;
  final int? originalBytes;

  factory _PacketAttachment.fromJson(Map<String, dynamic> json, int index) =>
      _PacketAttachment(
        index: index,
        type: json['type']?.toString() ?? 'file',
        mimeType: json['mime_type']?.toString() ?? 'application/octet-stream',
        dataBase64: json['data_base64']?.toString() ?? '',
        originalBytes: (json['original_bytes'] as num?)?.toInt(),
      );

  Uint8List? decodedBytes() {
    if (dataBase64.isEmpty) return null;
    try {
      return Uint8List.fromList(
        GZipDecoder().decodeBytes(base64Decode(dataBase64)),
      );
    } on FormatException {
      return null;
    }
  }
}

class _PacketDetailSheet extends StatelessWidget {
  const _PacketDetailSheet({required this.record, required this.summary});

  final SyncQueueData record;
  final _PacketSummary summary;

  @override
  Widget build(BuildContext context) {
    final details = Map<String, dynamic>.from(summary.payload)
      ..remove('attachments_json')
      ..remove('data_base64');
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              summary.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('Ticket ID: ${record.recordId}'),
            Text('Packet ID: ${record.id}'),
            Text('Status: ${record.syncStatus}'),
            if (record.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                record.errorMessage!,
                style: TextStyle(color: Colors.orange.shade900),
              ),
            ],
            if (summary.attachments.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Attached evidence',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              for (final attachment in summary.attachments)
                _AttachmentPreview(attachment: attachment),
            ],
            const SizedBox(height: 20),
            const Text(
              'Ticket details',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            for (final entry in details.entries)
              if (entry.value != null && entry.value.toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${entry.key.replaceAll('_', ' ')}: ${entry.value}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatefulWidget {
  const _AttachmentPreview({required this.attachment});

  final _PacketAttachment attachment;

  @override
  State<_AttachmentPreview> createState() => _AttachmentPreviewState();
}

class _AttachmentPreviewState extends State<_AttachmentPreview> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _playAudio(Uint8List bytes) async {
    setState(() => _playing = true);
    await _player.play(BytesSource(bytes));
    _player.onPlayerComplete.first.then((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.attachment;
    final bytes = attachment.decodedBytes();
    final label =
        '${attachment.type == 'image' ? 'Photo' : 'Voice note'}'
        '${attachment.originalBytes == null ? '' : ' · ${attachment.originalBytes} bytes'}';
    if (bytes == null) {
      return ListTile(
        leading: const Icon(Icons.broken_image_outlined),
        title: Text(label),
        subtitle: const Text('Evidence could not be decoded on this device.'),
      );
    }
    if (attachment.type == 'image') {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.memory(
              bytes,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(label, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }
    return ListTile(
      leading: const Icon(Icons.mic_rounded),
      title: Text(label),
      subtitle: Text(attachment.mimeType),
      trailing: IconButton(
        tooltip: _playing ? 'Playing voice note' : 'Play voice note',
        onPressed: _playing ? null : () => _playAudio(bytes),
        icon: Icon(
          _playing
              ? Icons.volume_up_rounded
              : Icons.play_circle_outline_rounded,
        ),
      ),
    );
  }
}

class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 64),
    child: Column(
      children: [
        Icon(Icons.cloud_done_outlined, size: 58, color: Colors.teal),
        SizedBox(height: 12),
        Text(
          'No offline packets yet',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 4),
        Text(
          'New records will appear here until the server acknowledges them.',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.day}/${value.month} $hour:$minute';
}
