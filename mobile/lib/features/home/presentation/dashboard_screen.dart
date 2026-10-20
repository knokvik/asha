import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/asha_bottom_nav.dart';
import '../../../shared/widgets/asha_svg_illustrations.dart';
import '../../../shared/widgets/sync_status_button.dart';

/// Screen 1: Home / Dashboard matching the exact Asha Platform mobile design.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('dashboard_screen'),
      backgroundColor: AshaColors.screenBg,
      drawer: const AppDrawer(),
      bottomNavigationBar: const AshaBottomNav(index: 0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            // Top App Bar: Menu, Logo, Bell
            const _DashboardHeader(),
            const SizedBox(height: 14),

            // Worker Profile Card: SS | Sunita Sharma | ASHA Worker • Rampur PHC | Offline Mode
            const _WorkerProfileCard(),
            const SizedBox(height: 14),

            // 4 Metrics Grid: 12 Today | 3 Overdue | 8 Completed | 2 Follow-ups
            const _MetricStrip(),
            const SizedBox(height: 18),

            // Continue Today's Work Banner with SVG Illustration
            const _ContinueWorkBanner(),
            const SizedBox(height: 22),

            // Quick Actions: 2x2 Grid
            const Text(
              'Quick actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AshaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const _QuickActionsGrid(),
            const SizedBox(height: 20),

            // Field Desk & Operational Overview
            const AshaOverviewBanner(),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Builder(
          builder: (context) => IconButton(
            key: const Key('home_menu_button'),
            tooltip: 'Open menu',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.menu_rounded,
              size: 26,
              color: AshaColors.carbonBlack,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        const Expanded(child: Center(child: AshaLogo(height: 32))),
        const SyncStatusButton(),
        IconButton(
          key: const Key('home_notifications_button'),
          tooltip: 'Notifications',
          visualDensity: VisualDensity.compact,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                size: 26,
                color: AshaColors.carbonBlack,
              ),
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AshaColors.alertHighRisk,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Offline Queue: All 3 sync records verified locally.',
                ),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WorkerProfileCard extends StatelessWidget {
  const _WorkerProfileCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AshaColors.cardSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const Key('home_worker_summary_card'),
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/profile'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AshaColors.borderSubtle, width: 0.9),
          ),
          child: Row(
            children: [
              // Avatar SS
              CircleAvatar(
                radius: 24,
                backgroundColor: AshaColors.primary,
                child: const Text(
                  'SS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Sunita Sharma',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AshaColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: AshaColors.leafMint,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'ASHA Worker • Rampur PHC',
                      style: TextStyle(
                        fontSize: 12,
                        color: AshaColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Offline Mode pill badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: AshaColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AshaColors.borderSubtle,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.circle,
                            size: 7,
                            color: AshaColors.vitalNormal,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Offline mode',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AshaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildMetric(
          context: context,
          value: '12',
          label: 'Today',
          color: AshaColors.primary,
          route: '/due-list',
        ),
        const SizedBox(width: 8),
        _buildMetric(
          context: context,
          value: '3',
          label: 'Overdue',
          color: AshaColors.alertHighRisk,
          route: '/due-list',
        ),
        const SizedBox(width: 8),
        _buildMetric(
          context: context,
          value: '8',
          label: 'Completed',
          color: AshaColors.vitalNormal,
          route: '/due-list',
        ),
        const SizedBox(width: 8),
        _buildMetric(
          context: context,
          value: '2',
          label: 'Follow-ups',
          color: AshaColors.warningPending,
          route: '/due-list',
        ),
      ],
    );
  }

  Widget _buildMetric({
    required BuildContext context,
    required String value,
    required String label,
    required Color color,
    required String route,
  }) {
    return Expanded(
      child: Material(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(route),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AshaColors.borderSubtle, width: 0.9),
            ),
            child: Column(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AshaColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueWorkBanner extends StatelessWidget {
  const _ContinueWorkBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('home_continue_work_card'),
      color: const Color(0xFFE5F2EE),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.push('/due-list'),
        child: Container(
          height: 120,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFCBE3D9), width: 1),
          ),
          child: Stack(
            children: [
              // Background vector illustration
              Positioned(
                right: -10,
                bottom: 0,
                top: 0,
                width: 170,
                child: const AshaFieldWorkerIllustrationWidget(height: 120),
              ),
              // Left text content
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 150, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "Continue today's work",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AshaColors.primaryDark,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '5 households • 2 follow-ups',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AshaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.55,
      children: [
        _QuickActionCard(
          iconWidget: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AshaColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add_home_work_rounded,
              color: AshaColors.primary,
              size: 20,
            ),
          ),
          title: 'Add Household',
          onTap: () => context.push('/household/new'),
        ),
        _QuickActionCard(
          key: const Key('home_triage_button'),
          iconWidget: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.emergency_rounded,
              color: AshaColors.alertHighRisk,
              size: 20,
            ),
          ),
          title: 'Triage Assessment',
          onTap: () => context.push('/triage/assessment'),
        ),
        _QuickActionCard(
          iconWidget: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.translate_rounded,
              color: Color(0xFF0284C7),
              size: 20,
            ),
          ),
          title: 'Speak / Interpreter',
          onTap: () => context.push('/interpreter'),
        ),
        _QuickActionCard(
          iconWidget: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: AshaColors.teleConsultBlue,
              size: 20,
            ),
          ),
          title: 'Clinical Programs',
          onTap: () => context.push('/clinical-programs'),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    super.key,
    required this.iconWidget,
    required this.title,
    required this.onTap,
  });

  final Widget iconWidget;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AshaColors.cardSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AshaColors.borderSubtle, width: 0.9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AshaColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
