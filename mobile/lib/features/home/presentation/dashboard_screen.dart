import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/l10n/language_provider.dart';
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

  String get _lang => ref.watch(languageProvider).languageCode;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
              hintText: 'Search households, beneficiaries, ABHA...',
              onTap: () => context.push('/search'),
              onChanged: (_) => setState(() {}),
              onSubmitted: (query) {
                final value = query.trim();
                final suffix = value.isEmpty
                    ? ''
                    : '?q=${Uri.encodeQueryComponent(value)}';
                context.push('/households$suffix');
              },
            ),
            const SizedBox(height: 16),
          ],

          // 2. Compact field map preview replaces the profile block.
          _buildMapPreview(context),
          const SizedBox(height: 16),

          // 3. 4 Metric Blocks: 12 Today | 3 Overdue | 8 Completed | 2 Follow-ups
          _buildMetricStrip(context),
          const SizedBox(height: 16),

          // 4. Continue today's work Card: 5 households • 2 follow-ups + SVG illustration
          _buildContinueWorkCard(context),
          const SizedBox(height: 14),

          // 5. Quick actions Section: 2x2 Grid
          Text(
            shellText(_lang, 'quick'),
            style: TextStyle(
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
    );
  }

  /// Top App Bar matching Screen 1:
  /// Far-left hamburger menu ☰, centered 'asha' wordmark, notification bell 🔔 with unread badge.
  Widget _buildTopBar(BuildContext context) {
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
          const Text(
            'asha',
            style: TextStyle(
              fontFamily: 'SF Pro Display',
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E4231),
              letterSpacing: -1.0,
            ),
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
                FlutterMap(
                  options: const MapOptions(
                    initialCenter: currentLocation,
                    initialZoom: 14.8,
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.nhm.asha.asha_platform',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 16,
                          color: Color(0xFF166534),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'My area',
                          style: TextStyle(
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
                          child: const Text(
                            '5 households today · 3 due',
                            style: TextStyle(
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

  /// 4 Metric Blocks in a row: 12 Today (green) | 3 Overdue (red) | 8 Completed (green) | 2 Follow-ups (amber)
  Widget _buildMetricStrip(BuildContext context) {
    return Row(
      children: [
        _buildMetricBlock(
          count: '12',
          label: shellText(_lang, 'today'),
          color: const Color(0xFF6B7280),
          onTap: () => ref.read(shellTabProvider.notifier).select(2),
        ),
        const SizedBox(width: 8),
        _buildMetricBlock(
          count: '3',
          label: shellText(_lang, 'overdue'),
          color: const Color(0xFF6B7280),
          onTap: () => ref.read(shellTabProvider.notifier).select(2),
        ),
        const SizedBox(width: 8),
        _buildMetricBlock(
          count: '8',
          label: shellText(_lang, 'completed'),
          color: const Color(0xFF6B7280),
          onTap: () => ref.read(shellTabProvider.notifier).select(2),
        ),
        const SizedBox(width: 8),
        _buildMetricBlock(
          count: '2',
          label: shellText(_lang, 'followUps'),
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

  /// "Continue Today's Work" Card matching Screen 1:
  /// Title, subtitle, chevron, and the exact village hills + ASHA worker SVG illustration.
  Widget _buildContinueWorkCard(BuildContext context) {
    return Material(
      color: const Color(0xFFEAF7F0),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const Key('home_continue_work_card'),
        onTap: () => ref.read(shellTabProvider.notifier).select(2),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFFF1FAF4), Color(0xFFD8F0E1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFFB9DDC5), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shellText(_lang, 'continueWork'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          shellText(_lang, 'continueSub'),
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              // Vector illustration of village hills & ASHA worker
              const AshaFieldWorkerIllustrationWidget(height: 82),
            ],
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
                title: shellText(_lang, 'interpreter'),
                iconWidget: _quickActionIcon(
                  Icons.translate_rounded,
                  const Color(0xFF2563EB),
                ),
                onTap: () => context.push('/interpreter'),
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

/// Screen 2: Master Navigation Drawer
/// Exact replica of Screen 2 in reference image.
/// Deep Forest Green background (#1A402D), SS avatar, offline pill, 8 items.
class AshaNavigationDrawer extends ConsumerWidget {
  const AshaNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).languageCode;
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
                        child: const Text(
                          'SS',
                          style: TextStyle(
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
                              children: const [
                                Text(
                                  'Sunita Sharma',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'SF Pro Display',
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFF22C55E),
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'ASHA Worker • Rampur PHC',
                              style: TextStyle(
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

                  // Pill: 🔒 Offline • Data Encrypted
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
                          Icons.lock_rounded,
                          size: 13,
                          color: Color(0xFF22C55E),
                        ),
                        SizedBox(width: 6),
                        Text(
                          shellText(lang, 'encrypted'),
                          style: TextStyle(
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

            // 8 Menu Items
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

                    // 2. Today's Due List with red badge 3
                    _buildDrawerItem(
                      context: context,
                      icon: Icons.checklist_rounded,
                      title: shellText(lang, 'drawerDue'),
                      subtitle: shellText(lang, 'drawerDueSub'),
                      badgeCount: '3',
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
