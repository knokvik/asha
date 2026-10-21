import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../../../shared/shell/shell_copy.dart';
import '../../../shared/widgets/asha_bottom_nav.dart';
import 'dashboard_screen.dart';

/// Screen 9: Profile matching the master reference design.
/// Fetches real ASHA worker credentials, online/offline sync status,
/// dynamic visit performance metrics, and supports switching ASHA accounts.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).languageCode;
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    final body = _body(context, ref, lang, scaffoldKey);
    if (embedded) return body;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AshaColors.screenBg,
      drawer: const AshaNavigationDrawer(),
      bottomNavigationBar: const AshaBottomNav(index: 3),
      body: SafeArea(child: body),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    String lang,
    GlobalKey<ScaffoldState> scaffoldKey,
  ) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.value;
    final syncCoordinator = ref.watch(syncCoordinatorProvider);
    final isConnected = syncCoordinator?.snapshot.isConnectedToServer ?? false;

    final initials = profile?.initials ?? 'AS';
    final name = profile?.name ?? 'ASHA Worker';
    final ashaId = profile?.ashaId ?? '';
    final roleFacility =
        profile?.facilityDisplay ?? 'ASHA Worker • Primary Health Centre';
    final totalVisits = profile?.totalVisits ?? 0;
    final completedVisits = profile?.completedVisits ?? 0;
    final pendingVisits = profile?.pendingVisits ?? 0;

    return Column(
      children: [
        if (!embedded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.menu_rounded,
                    size: 26,
                    color: Color(0xFF111827),
                  ),
                  onPressed: () => scaffoldKey.currentState?.openDrawer(),
                ),

                Text(
                  shellText(lang, 'profile'),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    fontFamily: 'SF Pro Display',
                  ),
                ),

                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    size: 24,
                    color: Color(0xFF111827),
                  ),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
          ),

        // 2. Profile Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(userProfileProvider.notifier).loadProfile();
              await syncCoordinator?.checkServerConnectivity();
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              children: [
                // Worker Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AshaColors.cardSurface,
                    borderRadius: AshaShapes.cardRadius,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFF1E4231),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

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
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 16,
                                  color: Color(0xFF16A34A),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ashaId.isNotEmpty
                                  ? '$ashaId • $roleFacility'
                                  : roleFacility,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => context.push('/sync'),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isConnected
                                      ? const Color(0xFFF0FDF4)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isConnected
                                        ? const Color(0xFFBBF7D0)
                                        : const Color(0xFFE5E7EB),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isConnected
                                          ? Icons.cloud_done_rounded
                                          : Icons.lock_outline_rounded,
                                      size: 11,
                                      color: isConnected
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isConnected
                                          ? 'Server Online • Sync Active'
                                          : shellText(lang, 'offline'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isConnected
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFF4B5563),
                                        fontFamily: 'SF Pro Display',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 14,
                                      color: isConnected
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFF9CA3AF),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Performance Metric: "This Month"
                Text(
                  shellText(lang, 'thisMonth'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    _buildMonthStat(
                      '$totalVisits',
                      shellText(lang, 'visits'),
                      const Color(0xFF111827),
                    ),
                    const SizedBox(width: 8),
                    _buildMonthStat(
                      '$completedVisits',
                      shellText(lang, 'completed'),
                      const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    _buildMonthStat(
                      '$pendingVisits',
                      shellText(lang, 'pending'),
                      const Color(0xFFEF4444),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Menu Options List matching Screen 9:
                // 1. Earnings & Incentives
                _buildListOption(
                  icon: Icons.receipt_long_outlined,
                  title: shellText(lang, 'earnings'),
                  subtitle: shellText(lang, 'earningsSub'),
                  onTap: () => context.push('/incentives'),
                ),
                const SizedBox(height: 10),

                // 2. Reports (Monthly summary)
                _buildListOption(
                  icon: Icons.bar_chart_rounded,
                  title: shellText(lang, 'reports'),
                  subtitle: shellText(lang, 'reportsSub'),
                  onTap: () => context.push('/reports'),
                ),
                const SizedBox(height: 10),

                // 3. App Settings (Language, sync, help)
                _buildListOption(
                  icon: Icons.settings_outlined,
                  title: shellText(lang, 'settings'),
                  subtitle: shellText(lang, 'settingsSub'),
                  onTap: () => context.push('/settings'),
                ),
                const SizedBox(height: 10),

                // 4. Server Sync & Connectivity
                _buildListOption(
                  icon: Icons.cloud_sync_outlined,
                  title: shellText(lang, 'sync'),
                  subtitle: isConnected
                      ? 'Connected to server (${profile?.apiBaseUrl ?? "Online"})'
                      : 'Offline • Tap to view packets & retry connection',
                  iconColor: isConnected
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706),
                  onTap: () => context.push('/sync'),
                ),
                const SizedBox(height: 22),

                Text(
                  shellText(lang, 'moreFeatures'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    fontFamily: 'SF Pro Display',
                  ),
                ),
                const SizedBox(height: 10),
                _buildListOption(
                  icon: Icons.grid_view_rounded,
                  title: shellText(lang, 'allTools'),
                  subtitle: shellText(lang, 'allToolsSub'),
                  onTap: () => context.push('/tools'),
                ),
                const SizedBox(height: 10),
                _buildListOption(
                  icon: Icons.school_outlined,
                  title: shellText(lang, 'learning'),
                  subtitle: shellText(lang, 'learningSub'),
                  onTap: () => context.push('/learning'),
                ),
                const SizedBox(height: 10),
                _buildListOption(
                  icon: Icons.inventory_2_outlined,
                  title: shellText(lang, 'stock'),
                  subtitle: shellText(lang, 'stockSub'),
                  onTap: () => context.push('/stock'),
                ),
                const SizedBox(height: 10),
                _buildListOption(
                  icon: Icons.map_outlined,
                  title: shellText(lang, 'maps'),
                  subtitle: shellText(lang, 'mapsSub'),
                  onTap: () => context.push('/map-packs'),
                ),
                const SizedBox(height: 10),
                _buildListOption(
                  icon: Icons.assignment_outlined,
                  title: shellText(lang, 'registers'),
                  subtitle: shellText(lang, 'registersSub'),
                  onTap: () => context.push('/reports/registers'),
                ),
                const SizedBox(height: 10),
                _buildListOption(
                  icon: Icons.menu_book_outlined,
                  title: shellText(lang, 'education'),
                  subtitle: shellText(lang, 'educationSub'),
                  onTap: () => context.push('/education'),
                ),
                const SizedBox(height: 10),
                _buildListOption(
                  icon: Icons.support_agent_outlined,
                  title: shellText(lang, 'support'),
                  subtitle: shellText(lang, 'supportSub'),
                  onTap: () => context.push('/support'),
                ),
                const SizedBox(height: 20),

                // Account / Sign Out Section
                _buildListOption(
                  icon: Icons.logout_rounded,
                  title: 'Sign Out / Switch ASHA',
                  subtitle: 'Change worker login or reset credentials',
                  iconColor: const Color(0xFFDC2626),
                  onTap: () => _confirmSignOut(context, ref),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(
          'Sign Out?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Are you sure you want to sign out? You will need to enter your ASHA ID and PIN to access the application again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ref.read(userProfileProvider.notifier).logout(context);
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStat(String count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
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
    );
  }

  Widget _buildListOption({
    required IconData icon,
    required String title,
    required String subtitle,
    Color iconColor = const Color(0xFF16A34A),
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
