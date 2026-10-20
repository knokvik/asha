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
        onTap: () => _showPacketDetails(context),
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
          '${record.operation.toUpperCase()}  ${record.targetTable}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${record.recordId}\nPriority P${record.priority} • ${_formatTime(timestamp)}',
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

  void _showPacketDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${record.operation} ${record.targetTable}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Packet ID: ${record.id}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Status: ${record.syncStatus}',
                style: const TextStyle(fontSize: 12),
              ),
              if (record.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  record.errorMessage!,
                  style: TextStyle(color: Colors.orange.shade900),
                ),
              ],
              const SizedBox(height: 12),
              SelectableText(
                record.payloadJson,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ],
          ),
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
