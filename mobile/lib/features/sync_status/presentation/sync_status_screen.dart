import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../shared/providers/core_providers.dart';

/// Sync Status screen.
///
/// A lightweight summary of the current sync health — how many packets are
/// waiting, whether the server is reachable, and the last successful sync time.
/// Tapping "View queue" navigates to the full [SyncQueueScreen] at `/sync`.
///
/// Route: `/sync-status`
class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).languageCode;
    final coordinator = ref.watch(syncCoordinatorProvider);

    final title = lang == 'hi'
        ? 'सिंक स्थिति'
        : lang == 'mr'
        ? 'सिंक स्थिती'
        : 'Sync Status';

    if (coordinator == null) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(
          child: Text('Unlock the app first to view sync status.'),
        ),
      );
    }

    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) {
        final snapshot = coordinator.snapshot;
        return Scaffold(
          backgroundColor: AshaColors.screenBg,
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            backgroundColor: AshaColors.cardSurface,
            foregroundColor: AshaColors.textPrimary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatusCard(snapshot: snapshot),
              const SizedBox(height: 16),
              _StatRow(
                label: 'Packets waiting',
                value: '${snapshot.pendingCount}',
                icon: Icons.outbox_rounded,
                highlight: snapshot.pendingCount > 0,
              ),
              _StatRow(
                label: 'Needs review',
                value: '${snapshot.failedCount}',
                icon: Icons.warning_amber_rounded,
                highlight: snapshot.failedCount > 0,
                highlightColor: Colors.orange.shade700,
              ),
              _StatRow(
                label: 'Total in queue',
                value: '${snapshot.records.length}',
                icon: Icons.list_alt_rounded,
              ),
              _StatRow(
                label: 'Last synced',
                value: snapshot.lastSyncedAt != null
                    ? _formatDateTime(snapshot.lastSyncedAt!)
                    : 'Never',
                icon: Icons.schedule_rounded,
              ),
              _StatRow(
                label: 'Server connection',
                value: snapshot.isConnectedToServer ? 'Online' : 'Offline',
                icon: snapshot.isConnectedToServer
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
                highlight: !snapshot.isConnectedToServer,
                highlightColor: Colors.grey.shade600,
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.push('/sync'),
                icon: const Icon(Icons.queue_rounded),
                label: const Text('View full sync queue'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: snapshot.state == SyncConnectionState.syncing
                    ? null
                    : coordinator.syncNow,
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Sync now'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    final t = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$d at $t';
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.snapshot});

  final SyncSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final isHealthy = snapshot.state == SyncConnectionState.ready;
    final isSyncing = snapshot.state == SyncConnectionState.syncing;
    final color = isHealthy
        ? Colors.teal.shade700
        : isSyncing
        ? Colors.blue.shade700
        : Colors.orange.shade700;

    final statusText = switch (snapshot.state) {
      SyncConnectionState.ready => 'All data is up to date',
      SyncConnectionState.syncing => 'Syncing in progress…',
      SyncConnectionState.offline => 'Working offline — data will sync when connected',
      SyncConnectionState.error => snapshot.errorMessage ?? 'Sync error — will retry automatically',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          if (isSyncing)
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: color,
              ),
            )
          else
            Icon(
              isHealthy ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: color,
              size: 28,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
    this.highlightColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? (highlightColor ?? Colors.teal.shade700)
        : AshaColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AshaColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AshaColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
