import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/sync/sync_coordinator.dart';
import '../../shared/providers/core_providers.dart';

/// Compact top-bar entry point for the offline packet queue.
/// Shows:
/// - A cloud icon with a bright green dot when connected to server and all synced.
/// - A yellow/amber sync icon and badge when offline, pending sync, or syncing.
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
        icon: const Icon(
          Icons.cloud_queue_outlined,
          size: 24,
          color: Color(0xFFD97706),
        ),
      );
    }
    return ListenableBuilder(
      listenable: coordinator,
      builder: (context, _) => _buildButton(context, coordinator.snapshot),
    );
  }

  Widget _buildButton(BuildContext context, SyncSnapshot snapshot) {
    final pending = snapshot.pendingCount;
    final isSyncing = snapshot.state == SyncConnectionState.syncing;
    final isConnected = snapshot.isConnectedToServer;
    final isOffline = !isConnected || snapshot.state == SyncConnectionState.offline;

    // Connected = Green dot on cloud.
    // Offline / Syncing / Pending = Yellow/Amber sync icon.
    final iconColor = isConnected && pending == 0
        ? const Color(0xFF1E4231)
        : isSyncing
            ? const Color(0xFF2563EB)
            : const Color(0xFFD97706); // Amber / Yellow

    final icon = isSyncing
        ? Icons.sync_rounded
        : isConnected && pending == 0
            ? Icons.cloud_outlined
            : pending > 0
                ? Icons.cloud_upload_outlined
                : Icons.cloud_queue_outlined;

    return IconButton(
      key: const Key('sync_status_button'),
      tooltip: isSyncing
          ? 'Syncing with server…'
          : isConnected && pending == 0
              ? 'Server Connected (Online) • Tap to sync'
              : isOffline
                  ? 'Offline • Tap to connect'
                  : '$pending packets waiting to sync',
      visualDensity: VisualDensity.compact,
      onPressed: () => context.push('/sync'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 24, color: iconColor),
          // Green dot when connected to server
          if (isConnected && pending == 0)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A), // Bright green dot
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x4016A34A),
                      blurRadius: 3,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          // Yellow/Amber badge when packets are waiting to sync
          if (pending > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B), // Yellow/Amber badge
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  pending > 99 ? '99+' : '$pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            )
          else if (!isConnected)
            // Yellow dot when disconnected/offline
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B), // Yellow dot
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
