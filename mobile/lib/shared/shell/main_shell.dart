import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/language_provider.dart';
import '../../core/sync/sync_coordinator.dart';
import '../../shared/providers/core_providers.dart';
import '../widgets/sync_status_button.dart';
import '../../features/due_list/presentation/due_list_screen.dart';
import '../../features/home/presentation/dashboard_screen.dart';
import '../../features/home/presentation/profile_screen.dart';
import '../../features/map/presentation/field_map_screen.dart';
import '../widgets/asha_bottom_nav.dart';
import '../widgets/asha_search_bar.dart';
import '../widgets/asha_svg_illustrations.dart';
import 'shell_copy.dart';
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
            _ShellHeader(lang: lang),
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
    final shellWithBackStack = PopScope<void>(
      // The shell tabs are kept in one route, so handle the first back press
      // by returning to Home instead of letting Android close the app while a
      // worker is on Map, Tasks, or Profile.
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && index != 0) {
          ref.read(shellTabProvider.notifier).select(0);
        }
      },
      child: shell,
    );
    if (sync == null) return shellWithBackStack;
    return _SyncToastListener(sync: sync, child: shellWithBackStack);
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
  const _ShellHeader({required this.lang});

  final String lang;

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
            const Center(child: AshaLogo(height: 27)),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SyncStatusButton(),
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

class _ShellSearchBar extends ConsumerStatefulWidget {
  const _ShellSearchBar();

  @override
  ConsumerState<_ShellSearchBar> createState() => _ShellSearchBarState();
}

class _ShellSearchBarState extends ConsumerState<_ShellSearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).languageCode;
    return AshaSearchBar(
      key: const Key('home_search_bar'),
      controller: _controller,
      hintText: shellText(lang, 'searchHint'),
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
