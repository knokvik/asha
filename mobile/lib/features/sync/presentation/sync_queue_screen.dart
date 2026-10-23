import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/shell/shell_copy.dart';

class SyncQueueScreen extends ConsumerWidget {
  const SyncQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).languageCode;
    final coordinator = ref.watch(syncCoordinatorProvider);
    if (coordinator == null) {
      return Scaffold(
        appBar: AppBar(title: Text(shellText(lang, 'syncQueueTitle'))),
        body: Center(child: Text(shellText(lang, 'syncUnlockMsg'))),
      );
    }
    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) => _buildScaffold(context, coordinator, lang),
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    SyncCoordinator coordinator,
    String lang,
  ) {
    final snapshot = coordinator.snapshot;
    final totalSynced = snapshot.records.where((r) => r.syncStatus == 'synced').length;
    final pendingCount = snapshot.pendingCount;
    final failedCount = snapshot.failedCount;

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Text(
          shellText(lang, 'syncQueueTitle'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('sync_refresh_button'),
            tooltip: shellText(lang, 'syncRefresh'),
            onPressed: coordinator.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: coordinator.refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _SyncSummaryCard(snapshot: snapshot, lang: lang),
            const SizedBox(height: 12),

            // Quick Metrics Stat Row
            Row(
              children: [
                Expanded(
                  child: _SyncStatPill(
                    label: 'In Queue',
                    count: pendingCount,
                    icon: Icons.schedule_rounded,
                    color: const Color(0xFF2563EB),
                    bgColor: const Color(0xFFEFF6FF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SyncStatPill(
                    label: 'Synced',
                    count: totalSynced,
                    icon: Icons.cloud_done_rounded,
                    color: const Color(0xFF16A34A),
                    bgColor: const Color(0xFFF0FDF4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SyncStatPill(
                    label: 'Failed',
                    count: failedCount,
                    icon: Icons.error_outline_rounded,
                    color: const Color(0xFFDC2626),
                    bgColor: const Color(0xFFFEF2F2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _ConflictSummarySection(snapshot: snapshot),
            const SizedBox(height: 12),

            // Peer-to-Peer Nearby Exchange Banner
            Container(
              decoration: BoxDecoration(
                color: AshaColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AshaColors.borderSubtle),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.connect_without_contact_rounded,
                    color: Color(0xFF15803D),
                    size: 24,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      shellText(lang, 'peerSyncTitle'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'OFFLINE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15803D),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  shellText(lang, 'peerSyncSub'),
                  style: const TextStyle(fontSize: 12, color: AshaColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF9CA3AF)),
                onTap: () => context.push('/peer-sync'),
              ),
            ),
            if (snapshot.state == SyncConnectionState.syncing)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: LinearProgressIndicator(),
              ),
            if (snapshot.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          snapshot.errorMessage!,
                          style: const TextStyle(color: Color(0xFF991B1B), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 18),
            if (snapshot.records.isEmpty)
              const _EmptyQueue()
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${shellText(lang, 'syncStoredPackets')} (${snapshot.records.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AshaColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Total Packets',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AshaColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...snapshot.records.map(
                (record) => _QueuePacketTile(record: record),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('sync_now_fab'),
        onPressed: snapshot.state == SyncConnectionState.syncing
            ? null
            : coordinator.syncNow,
        backgroundColor: AshaColors.primary,
        foregroundColor: Colors.white,
        icon: snapshot.state == SyncConnectionState.syncing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.cloud_upload_outlined, size: 20),
        label: Text(
          snapshot.state == SyncConnectionState.syncing ? 'Syncing…' : 'Sync Now',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SyncStatPill extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _SyncStatPill({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncSummaryCard extends StatelessWidget {
  final SyncSnapshot snapshot;
  final String lang;

  const _SyncSummaryCard({required this.snapshot, required this.lang});

  @override
  Widget build(BuildContext context) {
    final isHealthy = snapshot.state == SyncConnectionState.ready;
    final isSyncing = snapshot.state == SyncConnectionState.syncing;
    final isError = snapshot.state == SyncConnectionState.error;

    final Color statusColor;
    final IconData statusIcon;

    if (isSyncing) {
      statusColor = const Color(0xFF2563EB);
      statusIcon = Icons.sync_rounded;
    } else if (isHealthy) {
      statusColor = const Color(0xFF16A34A);
      statusIcon = Icons.cloud_done_rounded;
    } else if (isError) {
      statusColor = const Color(0xFFEA580C);
      statusIcon = Icons.sync_problem_rounded;
    } else {
      statusColor = const Color(0xFF4B5563);
      statusIcon = Icons.cloud_off_rounded;
    }

    final title = switch (snapshot.state) {
      SyncConnectionState.syncing => shellText(lang, 'syncingPackets'),
      SyncConnectionState.ready => shellText(lang, 'syncAllUpToDate'),
      SyncConnectionState.error => shellText(lang, 'syncWaitingReconnect'),
      SyncConnectionState.offline => shellText(lang, 'syncWorkingOffline'),
    };

    return Container(
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isHealthy ? const Color(0xFFE8F5E9) : statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(statusIcon, color: isHealthy ? const Color(0xFF1B5E20) : statusColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    snapshot.pendingCount == 0
                        ? 'All local health packets are preserved and acknowledged.'
                        : '${snapshot.pendingCount} packet${snapshot.pendingCount == 1 ? '' : 's'} queued for secure server dispatch.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
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

  IconData _getIconForTable(String table) {
    final lower = table.toLowerCase();
    if (lower.contains('triage')) return Icons.local_hospital_rounded;
    if (lower.contains('encounter')) return Icons.medical_services_rounded;
    if (lower.contains('schedule') || lower.contains('visit')) return Icons.event_available_rounded;
    if (lower.contains('household')) return Icons.home_work_rounded;
    if (lower.contains('member')) return Icons.person_rounded;
    if (lower.contains('incentive') || lower.contains('claim')) return Icons.payments_rounded;
    if (lower.contains('referral')) return Icons.share_location_rounded;
    return Icons.folder_shared_rounded;
  }

  Color _getColorForTable(String table) {
    final lower = table.toLowerCase();
    if (lower.contains('triage')) return const Color(0xFFDC2626);
    if (lower.contains('encounter')) return const Color(0xFF0D9488);
    if (lower.contains('schedule') || lower.contains('visit')) return const Color(0xFF2563EB);
    if (lower.contains('household')) return const Color(0xFF7C3AED);
    if (lower.contains('member')) return const Color(0xFF4F46E5);
    if (lower.contains('incentive') || lower.contains('claim')) return const Color(0xFFD97706);
    return const Color(0xFF4B5563);
  }

  @override
  Widget build(BuildContext context) {
    final summary = _PacketSummary.fromRecord(record);
    final isFailed = record.syncStatus == 'failed';
    final isSynced = record.syncStatus == 'synced';
    final timestamp = DateTime.fromMillisecondsSinceEpoch(record.createdAt);

    final statusColor = isFailed
        ? const Color(0xFFDC2626)
        : isSynced
            ? const Color(0xFF16A34A)
            : const Color(0xFF2563EB);

    final statusBg = isFailed
        ? const Color(0xFFFEF2F2)
        : isSynced
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFEFF6FF);

    final tableIcon = _getIconForTable(record.targetTable);
    final tableColor = _getColorForTable(record.targetTable);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFailed ? const Color(0xFFFCA5A5) : AshaColors.borderSubtle,
          width: isFailed ? 1.4 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPacketDetails(context, summary),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tableColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(tableIcon, color: tableColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              summary.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AshaColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              record.syncStatus.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summary.subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AshaColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'P${record.priority}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.schedule_rounded, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(timestamp),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    required this.targetTable,
    required this.operation,
    required this.payload,
    required this.attachments,
  });

  final String recordId;
  final String targetTable;
  final String operation;
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
      targetTable: record.targetTable,
      operation: record.operation,
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
    return '${operation.toUpperCase()} ${targetTable.replaceAll('_', ' ')}';
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

/// Surfaces any failed sync packets that need human review — either because
/// the server returned a conflict it could not auto-merge (duplicate_identity)
/// or because the packet has failed its maximum retry attempts.
///
/// This section is intentionally read-only: it shows what happened and what
/// value was kept, so the ASHA or supervisor can make an informed decision.
/// Silent auto-merges on clinical data are a patient-safety risk — the worker
/// must always know when a conflict occurred.
class _ConflictSummarySection extends StatelessWidget {
  const _ConflictSummarySection({required this.snapshot});

  final SyncSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final conflicts = snapshot.records
        .where(
          (r) =>
              r.syncStatus == 'failed' &&
              r.errorMessage != null &&
              r.errorMessage!.isNotEmpty,
        )
        .toList();

    if (conflicts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFB45309),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Needs review (${conflicts.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFFB45309),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'These packets failed to sync. Review each one before retrying to '
          'avoid overwriting newer data on the server.',
          style: TextStyle(fontSize: 11, color: AshaColors.textSecondary),
        ),
        const SizedBox(height: 8),
        for (final record in conflicts)
          _ConflictTile(record: record),
      ],
    );
  }
}

class _ConflictTile extends StatelessWidget {
  const _ConflictTile({required this.record});

  final SyncQueueData record;

  @override
  Widget build(BuildContext context) {
    final table = record.targetTable.replaceAll('_', ' ');
    final errorMsg = record.errorMessage ?? 'Unknown error';
    final isDuplicate = errorMsg.contains('duplicate_identity');

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: const Color(0xFFFFFBEB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFFCD34D)),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDuplicate
                      ? Icons.people_alt_outlined
                      : Icons.sync_problem_rounded,
                  size: 15,
                  color: const Color(0xFFB45309),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isDuplicate
                        ? 'Duplicate identity — $table'
                        : 'Sync failed — $table',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Attempt ${record.attemptCount}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AshaColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Record: ${record.recordId}',
              style: const TextStyle(
                fontSize: 10,
                color: AshaColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isDuplicate
                  ? 'A beneficiary with matching identity already exists on '
                    'the server. This cannot be auto-merged. Please contact '
                    'your supervisor to resolve the duplicate manually.'
                  : errorMsg,
              style: const TextStyle(fontSize: 11, color: Color(0xFF78350F)),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.day}/${value.month} $hour:$minute';
}
