import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../core/packs/pack_manager.dart';
import '../../../core/sync/sync_coordinator.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../../../shared/shell/shell_copy.dart';
import '../../../shared/shell/shell_tab.dart';
import '../../../shared/widgets/asha_bottom_nav.dart';
import '../../../shared/widgets/asha_search_bar.dart';
import '../../../shared/widgets/asha_svg_illustrations.dart';

/// Screen 1 & Screen 2: Master Home Dashboard & Navigation Drawer
/// Exact replica of Screen 1 and Screen 2 from reference design.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
  int _sharedSignalCount = 0;
  String? _sharedSignalPeerWorker;
  bool _hasServerContext = false;

  String get _lang => ref.watch(languageProvider).languageCode;

  String _getSharedSignalSubtitle(String lang) {
    if (_sharedSignalPeerWorker != null) {
      return '${shellText(lang, 'peerSignalFrom')} $_sharedSignalPeerWorker';
    }
    if (_hasServerContext) {
      return shellText(lang, 'serverSyncedContext');
    }
    return shellText(lang, 'noSharedSignals');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSharedSignals();
  }

  Future<void> _loadSharedSignals() async {
    try {
      const storage = FlutterSecureStorage();
      final raw = await storage.read(key: 'triage_hotspot_context_json');
      final history = await storage.read(key: 'peer_sync_history_json');
      if (!mounted) return;
      final context = raw == null ? null : jsonDecode(raw);
      final hotspots = context is Map && context['hotspots'] is List
          ? (context['hotspots'] as List)
                .where((item) => item is Map && item['active'] == true)
                .length
          : 0;
      final historyItems = history == null
          ? const <dynamic>[]
          : jsonDecode(history);
      final latestSource = historyItems is List && historyItems.isNotEmpty
          ? (historyItems.first['source_worker_id'] ?? 'nearby ASHA').toString()
          : null;
      setState(() {
        _sharedSignalCount = hotspots;
        _sharedSignalPeerWorker = latestSource;
        _hasServerContext = hotspots > 0;
      });
    } catch (_) {
      // The dashboard remains usable if secure storage has no context yet.
    }
  }

  Future<void> _refreshDashboard() async {
    // Keep refresh lightweight and offline-safe: reload local shared context
    // immediately. The sync worker continues pulling server deltas separately.
    await _loadSharedSignals();
  }

  @override
  Widget build(BuildContext context) {
    final body = _body(context);
    if (widget.embedded) {
      return KeyedSubtree(key: const Key('dashboard_screen'), child: body);
    }
    return Scaffold(
      key: const Key('dashboard_screen'),
      backgroundColor: Colors.white,
      drawer: const AshaNavigationDrawer(),
      bottomNavigationBar: const AshaBottomNav(
        key: Key('asha_bottom_nav'),
        index: 0,
      ),
      body: SafeArea(child: body),
    );
  }

  Widget _body(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      color: const Color(0xFF1E4231),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.embedded) ...[
              _buildTopBar(context),
              const SizedBox(height: 16),
            ],

            if (!widget.embedded) ...[
              AshaSearchBar(
                key: const Key('home_search_bar'),
                controller: _searchController,
                hintText: shellText(_lang, 'searchHint'),
                onTap: () => context.push('/search'),
                onChanged: (_) => setState(() {}),
                onSubmitted: (query) {
                  final value = query.trim();
                  final suffix = value.isEmpty
                      ? ''
                      : '?q=${Uri.encodeQueryComponent(value)}';
                  context.push('/search$suffix');
                },
              ),
              const SizedBox(height: 16),
            ],

            // 2. Compact field map preview replaces the profile block.
            _buildMapPreview(context),
            const SizedBox(height: 16),
            _buildSharedSignalCard(context),
            const SizedBox(height: 16),

            // 3. 4 Metric Blocks: 12 Today | 3 Overdue | 8 Completed | 2 Follow-ups
            _buildMetricStrip(context),
            const SizedBox(height: 16),

            // 4. Quick actions Section:
            Text(
              shellText(_lang, 'quick'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedSignalCard(BuildContext context) {
    final hasSignals = _sharedSignalCount > 0;
    return Container(
      decoration: BoxDecoration(
        color: hasSignals ? const Color(0xFFFFFBEB) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSignals ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await context.push('/peer-sync');
            _loadSharedSignals();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasSignals ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.radar_rounded,
                    color: hasSignals ? const Color(0xFFD97706) : const Color(0xFF15803D),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _sharedSignalCount == 0
                                  ? shellText(_lang, 'sharedAreaSignals')
                                  : '$_sharedSignalCount ${_sharedSignalCount == 1 ? shellText(_lang, 'activeAreaSignalSingular') : shellText(_lang, 'activeAreaSignals')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: hasSignals ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              hasSignals ? 'ALERT ACTIVE' : 'BEAT SYNCED',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _getSharedSignalSubtitle(_lang),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasSignals ? const Color(0xFF92400E) : const Color(0xFF166534),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top App Bar matching Screen 1:
  /// Far-left hamburger menu ☰, centered 'asha' wordmark, notification bell 🔔 with unread badge.
  Widget _buildTopBar(BuildContext context) {
    final syncCoordinator = ref.watch(syncCoordinatorProvider);
    final isReceiving =
        syncCoordinator?.snapshot.state == SyncConnectionState.syncing;
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Builder(
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
          const SizedBox(width: 10),

          // Keep the title bar focused on the ASHA wordmark.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AshaLogo(height: 24),
              if (isReceiving) ...[
                const SizedBox(width: 7),
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),

          const Spacer(),

          // Notification Bell with unread indicator dot
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(shellText(_lang, 'notif')),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 24,
                    color: Color(0xFF111827),
                  ),
                ),
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview(BuildContext context) {
    const currentLocation = LatLng(18.6279, 73.8131);
    final markers = [
      Marker(
        point: currentLocation,
        width: 42,
        height: 42,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x332563EB),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Center(
            child: CircleAvatar(radius: 7, backgroundColor: Color(0xFF2563EB)),
          ),
        ),
      ),
      for (final entry in const [
        (18.6304, 73.8101, Color(0xFFEF4444)),
        (18.6251, 73.8105, Color(0xFFF59E0B)),
        (18.6327, 73.8093, Color(0xFF16A34A)),
        (18.6299, 73.8165, Color(0xFFF59E0B)),
      ])
        Marker(
          point: LatLng(entry.$1, entry.$2),
          width: 30,
          height: 30,
          child: Icon(Icons.home_rounded, color: entry.$3, size: 25),
        ),
    ];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const Key('home_map_preview'),
        onTap: () => ref.read(shellTabProvider.notifier).select(1),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 184,
          padding: const EdgeInsets.all(4),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                _DashboardOsmMap(markers: markers),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x330F5138), Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          size: 16,
                          color: Color(0xFF166534),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          shellText(_lang, 'myArea'),
                          style: const TextStyle(
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.94),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            () {
                              final p = ref.watch(userProfileProvider).value;
                              final pending = p?.pendingVisits ?? 0;
                              final overdue = p?.overdueVisits ?? 0;
                              return '$pending ${shellText(_lang, 'pendingVisitsPending')} · $overdue ${shellText(_lang, 'overdueVisits')}';
                            }(),
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFF166534),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
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

  /// 4 Metric Blocks in a row: Today | Overdue | Completed | Total
  Widget _buildMetricStrip(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final todayCount = profile != null ? '${profile.pendingVisits}' : '0';
    final overdueCount = profile != null ? '${profile.overdueVisits}' : '0';
    final completedCount = profile != null ? '${profile.completedVisits}' : '0';
    final totalCount = profile != null ? '${profile.totalVisits}' : '0';

    return Row(
      children: [
        _buildMetricBlock(
          count: todayCount,
          label: shellText(_lang, 'today'),
          color: const Color(0xFF6B7280),
          onTap: () => ref.read(shellTabProvider.notifier).select(2),
        ),
        const SizedBox(width: 8),
        _buildMetricBlock(
          count: overdueCount,
          label: shellText(_lang, 'overdue'),
          color: const Color(0xFFEF4444),
          onTap: () => ref.read(shellTabProvider.notifier).select(2),
        ),
        const SizedBox(width: 8),
        _buildMetricBlock(
          count: completedCount,
          label: shellText(_lang, 'completed'),
          color: const Color(0xFF16A34A),
          onTap: () => ref.read(shellTabProvider.notifier).select(2),
        ),
        const SizedBox(width: 8),
        _buildMetricBlock(
          count: totalCount,
          label: shellText(_lang, 'visits'),
          color: const Color(0xFF6B7280),
          onTap: () => ref.read(shellTabProvider.notifier).select(2),
        ),
      ],
    );
  }

  Widget _buildMetricBlock({
    required String count,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
            ),
            child: Column(
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Quick Actions 2x2 Grid matching Screen 1:
  /// - Add Household (green group icon)
  /// - Triage Assessment (red emergency square)
  /// - Speak / Interpreter (green translation icon)
  /// - Clinical Programs (blue medical bag)
  Widget _buildQuickActionsGrid(BuildContext context) {
    final hasInterpreter = ref
        .watch(offlinePackProvider)
        .interpreterLanguageCodes
        .isNotEmpty;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: shellText(_lang, 'addHousehold'),
                iconWidget: _quickActionIcon(
                  Icons.group_add_rounded,
                  const Color(0xFF15803D),
                ),
                onTap: () => context.push('/households/new'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                key: const Key('home_triage_button'),
                title: shellText(_lang, 'triage'),
                iconWidget: _quickActionIcon(
                  Icons.emergency_rounded,
                  const Color(0xFFDC2626),
                ),
                onTap: () => context.push('/triage'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: hasInterpreter
                    ? shellText(_lang, 'interpreter')
                    : shellText(_lang, 'voicePacks'),
                iconWidget: _quickActionIcon(
                  hasInterpreter ? Icons.translate_rounded : Icons.download_rounded,
                  const Color(0xFF2563EB),
                ),
                onTap: () => context.push(hasInterpreter ? '/interpreter' : '/packs'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                title: shellText(_lang, 'programs'),
                iconWidget: _quickActionIcon(
                  Icons.medical_services_rounded,
                  const Color(0xFF7C3AED),
                ),
                onTap: () => context.push('/clinical-programs'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: 'Tracking',
                iconWidget: _quickActionIcon(
                  Icons.track_changes_rounded,
                  const Color(0xFF0F766E),
                ),
                onTap: () => context.push('/tracking'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                key: const Key('home_revenue_button'),
                title: shellText(_lang, 'revenue'),
                iconWidget: _quickActionIcon(
                  Icons.payments_outlined,
                  const Color(0xFF15803D),
                ),
                onTap: () => context.push('/incentives'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildQuickActionCard(
          key: const Key('home_reports_button'),
          title: shellText(_lang, 'reports'),
          iconWidget: _quickActionIcon(
            Icons.assessment_outlined,
            const Color(0xFF2563EB),
          ),
          onTap: () => context.push('/reports'),
        ),
      ],
    );
  }

  Widget _quickActionIcon(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 32),
    );
  }

  Widget _buildQuickActionCard({
    Key? key,
    required String title,
    required Widget iconWidget,
    required VoidCallback onTap,
  }) {
    return Material(
      key: key,
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 116),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  iconWidget,
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFD1D5DB),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardOsmMap extends StatelessWidget {
  const _DashboardOsmMap({required this.markers});

  final List<Marker> markers;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(18.6279, 73.8131),
        initialZoom: 14.8,
        interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'org.mohfw.asha_platform',
          minZoom: 3,
          maxZoom: 19,
        ),
        MarkerLayer(markers: markers),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}

/// Screen 2: Master Navigation Drawer
/// Exact replica of Screen 2 in reference image.
/// Deep Forest Green background (#1A402D), SS avatar, offline pill, 8 items.
class AshaNavigationDrawer extends ConsumerWidget {
  const AshaNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).languageCode;
    final profile = ref.watch(userProfileProvider).value;
    final syncCoordinator = ref.watch(syncCoordinatorProvider);
    final isConnected = syncCoordinator?.snapshot.isConnectedToServer ?? false;

    final rawName = profile?.name ?? '';
    final isDefaultName =
        rawName.isEmpty ||
        rawName == 'Sunita Devi' ||
        rawName == 'Sunita Sharma' ||
        rawName == 'ASHA Worker';
    final name = isDefaultName ? shellText(lang, 'workerName') : rawName;
    final facility = shellText(lang, 'worker');
    final initials = isDefaultName
        ? (lang == 'en' ? 'SS' : name.characters.take(2).toString())
        : (profile?.initials ?? 'AS');
    final pendingCount = profile?.pendingVisits ?? 0;

    return Drawer(
      backgroundColor: const Color(0xFF183D2B),
      child: SafeArea(
        child: Column(
          children: [
            // Header: SS Avatar | Sunita Sharma ✓ | ASHA Worker • Rampur PHC | Close ✕
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF183D2B),
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF22C55E),
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              facility,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFA7C7B7),
                                fontSize: 12,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Pill: 🔒 Offline • Data Encrypted or Online
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF112E20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF29563E),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isConnected
                              ? Icons.cloud_done_rounded
                              : Icons.lock_rounded,
                          size: 13,
                          color: const Color(0xFF22C55E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isConnected
                              ? shellText(lang, 'serverOnline')
                              : shellText(lang, 'encrypted'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 8 Menu Items + Sign Out
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                  children: [
                    // 1. Home (Active white card)
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.home_rounded,
                      title: shellText(lang, 'drawerHome'),
                      subtitle: shellText(lang, 'drawerHomeSub'),
                      isActive: true,
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(shellTabProvider.notifier).select(0);
                      },
                    ),
                    const SizedBox(height: 6),

                    // 2. Today's Due List with badge
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.checklist_rounded,
                      title: shellText(lang, 'drawerDue'),
                      subtitle: shellText(lang, 'drawerDueSub'),
                      badgeCount: pendingCount > 0 ? '$pendingCount' : null,
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(shellTabProvider.notifier).select(2);
                      },
                    ),
                    const SizedBox(height: 6),

                    // 3. Household Registry
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.people_alt_outlined,
                      title: shellText(lang, 'drawerHomes'),
                      subtitle: shellText(lang, 'drawerHomesSub'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/households');
                      },
                    ),
                    const SizedBox(height: 6),

                    // 4. Clinical Programs
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.medical_information_outlined,
                      title: shellText(lang, 'drawerPrograms'),
                      subtitle: shellText(lang, 'drawerProgramsSub'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/clinical-programs');
                      },
                    ),
                    const SizedBox(height: 6),

                    // 5. Emergency Triage (Red asterisk icon)
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.emergency_rounded,
                      title: shellText(lang, 'drawerTriage'),
                      subtitle: shellText(lang, 'drawerTriageSub'),
                      iconColor: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/triage');
                      },
                    ),
                    const SizedBox(height: 6),

                    // 6. Interpreter
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.translate_rounded,
                      title: shellText(lang, 'drawerInterp'),
                      subtitle: shellText(lang, 'drawerInterpSub'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/interpreter');
                      },
                    ),
                    const SizedBox(height: 6),

                    // 7. Reports & Incentives
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.receipt_long_outlined,
                      title: shellText(lang, 'drawerReports'),
                      subtitle: shellText(lang, 'drawerReportsSub'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/reports');
                      },
                    ),
                    const SizedBox(height: 6),

                    // 8. Settings
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.settings_outlined,
                      title: shellText(lang, 'drawerSettings'),
                      subtitle: shellText(lang, 'drawerSettingsSub'),
                      onTap: () {
                        Navigator.pop(context);
                        context.push('/settings');
                      },
                    ),
                    const SizedBox(height: 6),

                    // 9. Sign Out / Switch Account
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.logout_rounded,
                      title: shellText(lang, 'signOut'),
                      subtitle: shellText(lang, 'signOutSub'),
                      iconColor: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(context);
                        showDialog<void>(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            title: Text(
                              shellText(lang, 'signOutConfirm'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            content: Text(
                              shellText(lang, 'signOutConfirmDesc'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                child: Text(shellText(lang, 'cancel')),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  ref
                                      .read(userProfileProvider.notifier)
                                      .logout(context);
                                },
                                child: Text(shellText(lang, 'signOut')),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    bool isActive = false,
    String? badgeCount,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    final isEmergency = iconColor == const Color(0xFFEF4444);
    final surfaceColor = isActive
        ? const Color(0xFFEAF7F0)
        : isEmergency
        ? const Color(0xFFFFF0EF)
        : Colors.transparent;
    final resolvedIconColor = iconColor ?? const Color(0xFF087F5B);
    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isEmergency
                      ? const Color(0xFFFFE1DF)
                      : const Color(0xFFF0F7F3),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: resolvedIconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF111815),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF68756E),
                        fontSize: 11,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeCount != null) ...[
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF5A7265),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
