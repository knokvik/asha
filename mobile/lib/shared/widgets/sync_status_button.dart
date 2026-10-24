import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/providers/core_providers.dart';

bool _linkUp(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}

/// Cloud on the title bar. A green dot means Wi-Fi or mobile data is on.
/// A red dot means the phone has no network link.
class SyncStatusButton extends ConsumerStatefulWidget {
  const SyncStatusButton({super.key});

  @override
  ConsumerState<SyncStatusButton> createState() => _SyncStatusButtonState();
}

class _SyncStatusButtonState extends ConsumerState<SyncStatusButton> {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _linkSub;
  var _online = false;

  @override
  void initState() {
    super.initState();
    _readLink();
    _linkSub = _connectivity.onConnectivityChanged.listen((results) {
      if (!mounted) return;
      setState(() => _online = _linkUp(results));
    });
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  Future<void> _readLink() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (!mounted) return;
      setState(() => _online = _linkUp(results));
    } catch (_) {
      if (!mounted) return;
      setState(() => _online = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coordinator = ref.watch(syncCoordinatorProvider);
    final pending = coordinator?.snapshot.pendingCount ?? 0;
    final dot = _online ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    return IconButton(
      key: const Key('sync_status_button'),
      tooltip: _online
          ? 'Connected · Wi-Fi or mobile data is on'
          : 'No internet or Wi-Fi',
      visualDensity: VisualDensity.compact,
      onPressed: () => context.push('/sync'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.cloud_outlined,
            size: 24,
            color: _online ? const Color(0xFF1E4231) : const Color(0xFFDC2626),
          ),
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dot,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
          if (pending > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                padding: const EdgeInsets.symmetric(horizontal: 3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: dot,
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
            ),
        ],
      ),
    );
  }
}
