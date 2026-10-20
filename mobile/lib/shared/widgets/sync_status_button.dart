import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/sync/sync_coordinator.dart';
import '../../shared/providers/core_providers.dart';

/// Compact top-bar entry point for the offline packet queue.
class SyncStatusButton extends ConsumerWidget {
  const SyncStatusButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.watch(syncCoordinatorProvider);
    if (coordinator == null) {
      return IconButton(
        key: const Key('sync_status_button'),
        tooltip: 'Offline sync queue',
        visualDensity: VisualDensity.compact,
        onPressed: () => context.push('/sync'),
        icon: Icon(
          Icons.cloud_queue_outlined,
          size: 25,
          color: Colors.grey.shade700,
        ),
      );
    }
    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) => _buildButton(context, coordinator.snapshot),
    );
  }

  Widget _buildButton(BuildContext context, SyncSnapshot snapshot) {
    final icon = switch (snapshot.state) {
      SyncConnectionState.syncing => Icons.sync_rounded,
      SyncConnectionState.ready => Icons.cloud_done_outlined,
      SyncConnectionState.error => Icons.cloud_off_rounded,
      SyncConnectionState.offline => Icons.cloud_queue_outlined,
    };
    final color = switch (snapshot.state) {
      SyncConnectionState.syncing => Colors.blue.shade700,
      SyncConnectionState.ready => Colors.teal.shade700,
      SyncConnectionState.error => Colors.orange.shade800,
      SyncConnectionState.offline => Colors.grey.shade700,
    };

    return IconButton(
      key: const Key('sync_status_button'),
      tooltip: 'Offline sync queue',
      visualDensity: VisualDensity.compact,
      onPressed: () => context.push('/sync'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 25, color: color),
          if (snapshot.pendingCount > 0)
            Positioned(
              top: -5,
              right: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: snapshot.failedCount > 0
                      ? Colors.orange.shade800
                      : Colors.teal.shade800,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  snapshot.pendingCount > 99
                      ? '99+'
                      : '${snapshot.pendingCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
