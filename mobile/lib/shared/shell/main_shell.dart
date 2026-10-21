import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/language_provider.dart';
import '../../core/sync/sync_coordinator.dart';
import '../../shared/providers/core_providers.dart';
import '../../features/due_list/presentation/due_list_screen.dart';
import '../../features/home/presentation/dashboard_screen.dart';
import '../../features/home/presentation/profile_screen.dart';
import '../../features/map/presentation/field_map_screen.dart';
import '../widgets/asha_bottom_nav.dart';
import '../widgets/asha_search_bar.dart';
import 'shell_tab.dart';

/// One scaffold for Home, Map, Tasks, and Profile.
/// The header and the bottom dock stay put. Only the middle page changes.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellTabProvider);
    final lang = ref.watch(languageProvider).languageCode;
    final sync = ref.watch(syncCoordinatorProvider);
    final shell = Scaffold(
      backgroundColor: Colors.white,
      drawer: const AshaNavigationDrawer(),
      bottomNavigationBar: AshaBottomNav(
        key: const Key('asha_bottom_nav'),
        index: index,
        onTap: (next) => ref.read(shellTabProvider.notifier).select(next),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (sync == null)
              _ShellHeader(lang: lang, snapshot: null)
            else
              ListenableBuilder(
                listenable: sync,
                builder: (context, _) =>
                    _ShellHeader(lang: lang, snapshot: sync.snapshot),
              ),
            if (index == 0)
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 4, 18, 8),
                child: _ShellSearchBar(),
              ),
            Expanded(child: _ShellPageView(index: index)),
          ],
        ),
      ),
    );
    if (sync == null) return shell;
    return _SyncToastListener(sync: sync, child: shell);
  }
}

class _SyncToastListener extends StatefulWidget {
  const _SyncToastListener({required this.sync, required this.child});

  final SyncCoordinator sync;
  final Widget child;

  @override
  State<_SyncToastListener> createState() => _SyncToastListenerState();
}

class _SyncToastListenerState extends State<_SyncToastListener> {
  DateTime? _shownSync;

  @override
  void initState() {
    super.initState();
    _shownSync = widget.sync.snapshot.lastSyncedAt;
    widget.sync.addListener(_onSyncChanged);
  }

  @override
  void didUpdateWidget(covariant _SyncToastListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sync != widget.sync) {
      oldWidget.sync.removeListener(_onSyncChanged);
      _shownSync = widget.sync.snapshot.lastSyncedAt;
      widget.sync.addListener(_onSyncChanged);
    }
  }

  void _onSyncChanged() {
    final snapshot = widget.sync.snapshot;
    final syncedAt = snapshot.lastSyncedAt;
    if (!mounted || syncedAt == null || syncedAt == _shownSync) return;
    _shownSync = syncedAt;
    if (snapshot.state != SyncConnectionState.ready) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Synced to server'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  void dispose() {
    widget.sync.removeListener(_onSyncChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _ShellHeader extends StatelessWidget {
  const _ShellHeader({required this.lang, required this.snapshot});

  final String lang;
  final SyncSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
      child: SizedBox(
        height: 36,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Builder(
                builder: (scaffoldContext) => InkWell(
                  key: const Key('home_menu_button'),
                  onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.menu_rounded,
                      size: 26,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ),
            ),
            const Center(
              child: Text(
                'asha',
                style: TextStyle(
                  fontFamily: 'SF Pro Display',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E4231),
                  letterSpacing: -1.0,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SyncHeaderButton(snapshot: snapshot),
                  InkWell(
                    onTap: () {
                      context.push('/triage/history');
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 24,
                        color: Color(0xFF111827),
                      ),
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

class _SyncHeaderButton extends StatelessWidget {
  const _SyncHeaderButton({required this.snapshot});

  final SyncSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final pending = snapshot?.pendingCount ?? 0;
    final isSyncing = snapshot?.state == SyncConnectionState.syncing;
    final isConnected = snapshot?.isConnectedToServer ?? false;
    final isOffline =
        !isConnected || snapshot?.state == SyncConnectionState.offline;

    // Connected = Green dot on cloud.
    // Offline / Syncing / Pending = Yellow/Amber sync icon.
    final iconColor = isConnected && pending == 0
        ? const Color(0xFF1E4231)
        : isSyncing
        ? const Color(0xFF2563EB)
        : const Color(0xFFD97706); // Amber/Yellow

    return IconButton(
      key: const Key('shell_sync_button'),
      tooltip: isSyncing
          ? 'Syncing with server…'
          : isConnected && pending == 0
          ? 'Server Connected (Online) • Tap to sync'
          : isOffline
          ? 'Offline • Tap to connect'
          : '$pending packets waiting to sync',
      onPressed: () => context.push('/sync'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            isSyncing
                ? Icons.sync_rounded
                : isConnected && pending == 0
                ? Icons.cloud_outlined
                : pending > 0
                ? Icons.cloud_upload_outlined
                : Icons.cloud_queue_outlined,
            color: iconColor,
            size: 24,
          ),
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
          // Yellow/Amber badge when packets are waiting to sync or offline
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
                  pending > 9 ? '9+' : '$pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          // Yellow dot when offline without pending packets
          if (isOffline && pending == 0 && !isSyncing)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B), // Yellow offline dot
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

class _ShellPageView extends StatefulWidget {
  const _ShellPageView({required this.index});

  final int index;

  @override
  State<_ShellPageView> createState() => _ShellPageViewState();
}

class _ShellPageViewState extends State<_ShellPageView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    value: 1,
  );

  @override
  void didUpdateWidget(covariant _ShellPageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.035, 0),
          end: Offset.zero,
        ).animate(animation),
        child: IndexedStack(
          index: widget.index,
          children: const [
            DashboardScreen(embedded: true),
            FieldMapScreen(embedded: true),
            DueListScreen(embedded: true),
            ProfileScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}

class _ShellSearchBar extends StatefulWidget {
  const _ShellSearchBar();

  @override
  State<_ShellSearchBar> createState() => _ShellSearchBarState();
}

class _ShellSearchBarState extends State<_ShellSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AshaSearchBar(
      key: const Key('home_search_bar'),
      controller: _controller,
      hintText: 'Search people, medicines, guides...',
      onTap: () => context.push('/search'),
      onChanged: (_) => setState(() {}),
      onSubmitted: (query) {
        final value = query.trim();
        final suffix = value.isEmpty
            ? ''
            : '?q=${Uri.encodeQueryComponent(value)}';
        context.push('/search$suffix');
      },
    );
  }
}
