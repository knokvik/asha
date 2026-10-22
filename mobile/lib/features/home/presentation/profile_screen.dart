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
    final rawName = profile?.name ?? '';
    final isDefaultName = rawName.isEmpty ||
        rawName == 'Sunita Devi' ||
        rawName == 'Sunita Sharma' ||
        rawName == 'ASHA Worker';
    final name = isDefaultName ? shellText(lang, 'workerName') : rawName;
    final ashaId = profile?.ashaId ?? '';
    final facilityDisplay = profile?.facilityDisplay ?? '';
    final isDefaultFacility = facilityDisplay.isEmpty ||
        facilityDisplay == 'ASHA Worker • Primary Health Centre' ||
        facilityDisplay.contains('ASHA Worker');
    final roleFacility = isDefaultFacility
        ? shellText(lang, 'worker')
        : facilityDisplay;
    final totalVisits = profile?.totalVisits ?? 0;
    final completedVisits = profile?.completedVisits ?? 0;
    final pendingVisits = profile?.pendingVisits ?? 0;

    return Column(
      children: [
        if (!embedded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(
                        Icons.menu_rounded,
                        size: 22,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ),

                Text(
                  shellText(lang, 'profile'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    fontFamily: 'SF Pro Display',
                    letterSpacing: -0.3,
                  ),
                ),

                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push('/settings'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(
                        Icons.settings_outlined,
                        size: 22,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
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
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              children: [
                // Worker Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AshaColors.cardSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E4231), Color(0xFF166534)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF166534).withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  fontFamily: 'SF Pro Display',
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isConnected
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),

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
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                      fontFamily: 'SF Pro Display',
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(
                                  Icons.verified_rounded,
                                  size: 17,
                                  color: Color(0xFF16A34A),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              ashaId.isNotEmpty
                                  ? '$ashaId • $roleFacility'
                                  : roleFacility,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => context.push('/sync'),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isConnected
                                      ? const Color(0xFFF0FDF4)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isConnected
                                        ? const Color(0xFFBBF7D0)
                                        : const Color(0xFFFDE68A),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isConnected
                                          ? Icons.cloud_done_rounded
                                          : Icons.cloud_off_rounded,
                                      size: 14,
                                      color: isConnected
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFD97706),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isConnected
                                          ? shellText(lang, 'serverOnline')
                                          : shellText(lang, 'offline'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isConnected
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFFB45309),
                                        fontFamily: 'SF Pro Display',
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 15,
                                      color: isConnected
                                          ? const Color(0xFF16A34A)
                                          : const Color(0xFFD97706),
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
                const SizedBox(height: 20),

                // Performance Metric: "This Month"
                Text(
                  shellText(lang, 'thisMonth'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4B5563),
                    fontFamily: 'SF Pro Display',
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    _buildMonthStat(
                      count: '$totalVisits',
                      label: shellText(lang, 'visits'),
                      color: const Color(0xFF1E293B),
                      bgColor: const Color(0xFFF8FAFC),
                      borderColor: const Color(0xFFE2E8F0),
                      icon: Icons.event_note_rounded,
                      onTap: () => context.push('/due-list'),
                    ),
                    const SizedBox(width: 8),
                    _buildMonthStat(
                      count: '$completedVisits',
                      label: shellText(lang, 'completed'),
                      color: const Color(0xFF15803D),
                      bgColor: const Color(0xFFF0FDF4),
                      borderColor: const Color(0xFFBBF7D0),
                      icon: Icons.task_alt_rounded,
                      onTap: () => context.push('/due-list'),
                    ),
                    const SizedBox(width: 8),
                    _buildMonthStat(
                      count: '$pendingVisits',
                      label: shellText(lang, 'pending'),
                      color: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEF2F2),
                      borderColor: const Color(0xFFFECACA),
                      icon: Icons.pending_actions_rounded,
                      onTap: () => context.push('/due-list'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ── SECTION 1: Quick Actions & Finance ──────────────────────
                Text(
                  shellText(lang, 'quick'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4B5563),
                    fontFamily: 'SF Pro Display',
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),

                _buildListOption(
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: const Color(0xFF15803D),
                  iconBgColor: const Color(0xFFDCFCE7),
                  title: shellText(lang, 'earnings'),
                  subtitle: shellText(lang, 'earningsSub'),
                  onTap: () => context.push('/incentives'),
                ),
                const SizedBox(height: 10),

                _buildListOption(
                  icon: Icons.analytics_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFDBEAFE),
                  title: shellText(lang, 'reports'),
                  subtitle: shellText(lang, 'reportsSub'),
                  onTap: () => context.push('/reports'),
                ),
                const SizedBox(height: 10),

                _buildListOption(
                  icon: Icons.cloud_sync_rounded,
                  iconColor: isConnected
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706),
                  iconBgColor: isConnected
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  title: shellText(lang, 'sync'),
                  subtitle: isConnected
                      ? shellText(lang, 'serverOnline')
                      : shellText(lang, 'offlineSyncSub'),
                  onTap: () => context.push('/sync'),
                ),
                const SizedBox(height: 10),

                _buildListOption(
                  icon: Icons.tune_rounded,
                  iconColor: const Color(0xFF475569),
                  iconBgColor: const Color(0xFFF1F5F9),
                  title: shellText(lang, 'settings'),
                  subtitle: shellText(lang, 'settingsSub'),
                  onTap: () => context.push('/settings'),
                ),
                const SizedBox(height: 22),

                _buildListOption(
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFF7C3AED),
                  iconBgColor: const Color(0xFFF3E8FF),
                  title: 'Offline packs',
                  subtitle: 'Language, map and interpreter downloads',
                  onTap: () => context.push('/packs'),
                ),
                const SizedBox(height: 22),

                // ── SECTION 2: Clinical Tools & Field Operations ────────────
                Text(
                  shellText(lang, 'moreFeatures'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4B5563),
                    fontFamily: 'SF Pro Display',
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),

                _buildListOption(
                  icon: Icons.medical_services_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  iconBgColor: const Color(0xFFEDE9FE),
                  title: shellText(lang, 'allTools'),
                  subtitle: shellText(lang, 'allToolsSub'),
                  onTap: () => context.push('/tools'),
                ),
                const SizedBox(height: 10),

                _buildListOption(
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF0284C7),
                  iconBgColor: const Color(0xFFE0F2FE),
                  title: shellText(lang, 'registers'),
                  subtitle: shellText(lang, 'registersSub'),
                  onTap: () => context.push('/reports/registers'),
                ),
                const SizedBox(height: 10),

                _buildListOption(
                  icon: Icons.medication_rounded,
                  iconColor: const Color(0xFF0D9488),
                  iconBgColor: const Color(0xFFCCFBF1),
                  title: shellText(lang, 'stock'),
                  subtitle: shellText(lang, 'stockSub'),
                  onTap: () => context.push('/stock'),
                ),
                const SizedBox(height: 10),

                _buildListOption(
                  icon: Icons.map_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBgColor: const Color(0xFFD1FAE5),
                  title: shellText(lang, 'maps'),
                  subtitle: shellText(lang, 'mapsSub'),
                  onTap: () => context.push('/packs'),
                ),
                const SizedBox(height: 10),

                _buildListOption(
                  icon: Icons.auto_stories_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBgColor: const Color(0xFFFEF3C7),
                  title: shellText(lang, 'learning'),
                  subtitle: shellText(lang, 'learningSub'),
                  onTap: () => context.push('/learning'),
                ),
                const SizedBox(height: 10),

                _buildListOption(
                  icon: Icons.campaign_rounded,
                  iconColor: const Color(0xFFEA580C),
                  iconBgColor: const Color(0xFFFFEDD5),
                  title: shellText(lang, 'education'),
                  subtitle: shellText(lang, 'educationSub'),
                  onTap: () => context.push('/education'),
                ),
                const SizedBox(height: 10),

                _buildListOption(
                  icon: Icons.support_agent_rounded,
                  iconColor: const Color(0xFF9333EA),
                  iconBgColor: const Color(0xFFF3E8FF),
                  title: shellText(lang, 'support'),
                  subtitle: shellText(lang, 'supportSub'),
                  onTap: () => context.push('/support'),
                ),
                const SizedBox(height: 22),

                // ── SECTION 3: Account & Session ────────────────────────────
                _buildListOption(
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFFDC2626),
                  iconBgColor: const Color(0xFFFEE2E2),
                  title: shellText(lang, 'signOut'),
                  subtitle: shellText(lang, 'signOutSub'),
                  onTap: () => _confirmSignOut(context, ref, lang),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref, String lang) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFDC2626),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                shellText(lang, 'signOutConfirm'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ),
          ],
        ),
        content: Text(
          shellText(lang, 'signOutConfirmDesc'),
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              shellText(lang, 'cancel'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              ref.read(userProfileProvider.notifier).logout(context);
            },
            child: Text(
              shellText(lang, 'signOut'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStat({
    required String count,
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 5),
                    Text(
                      count,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
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

  Widget _buildListOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required Color iconBgColor,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: AshaColors.cardSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                        fontFamily: 'SF Pro Display',
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
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
              trailing ??
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
