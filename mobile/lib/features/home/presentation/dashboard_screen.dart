import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/asha_bottom_nav.dart';
import '../../../shared/widgets/asha_svg_illustrations.dart';

/// Screen 1 & Screen 2: Master Home Dashboard & Navigation Drawer
/// Exact replica of Screen 1 and Screen 2 from reference design.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('dashboard_screen'),
      backgroundColor: const Color(0xFFF9FAFB),
      drawer: const AshaNavigationDrawer(),
      bottomNavigationBar: const AshaBottomNav(key: Key('asha_bottom_nav'), index: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top App Bar: [ ☰ ]  [logo] asha        [ 🔔 ]
              _buildTopBar(context),
              const SizedBox(height: 16),

              // 2. Worker Profile Card: SS | Sunita Sharma ✓ | ASHA Worker • Rampur PHC | 🔒 Offline mode >
              _buildWorkerProfileCard(context),
              const SizedBox(height: 16),

              // 3. 4 Metric Blocks: 12 Today | 3 Overdue | 8 Completed | 2 Follow-ups
              _buildMetricStrip(context),
              const SizedBox(height: 16),

              // 4. Continue today's work Card: 5 households • 2 follow-ups + SVG illustration
              _buildContinueWorkCard(context),
              const SizedBox(height: 20),

              // 5. Quick actions Section: 2x2 Grid
              const Text(
                'Quick actions',
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
        ),
      ),
    );
  }

  /// Top App Bar matching Screen 1:
  /// Far-left hamburger menu ☰, 'asha' logo with favicon emblem, notification bell 🔔 with unread badge.
  Widget _buildTopBar(BuildContext context) {
    return Row(
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

        // Logo with favicon emblem + bold lowercase asha
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/branding/favicon.png',
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
            const SizedBox(width: 6),
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
          ],
        ),

        const Spacer(),

        // Notification Bell with unread indicator dot
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications: 2 pending immunizations & 1 overdue ANC visit.'),
                duration: Duration(seconds: 2),
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
    );
  }

  /// Worker Profile Card matching Screen 1:
  /// Dark green SS avatar, Sunita Sharma verified badge, ASHA Worker subtitle, Offline Mode pill, and chevron.
  Widget _buildWorkerProfileCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.go('/profile'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          ),
          child: Row(
            children: [
              // Avatar SS
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF1E4231),
                child: const Text(
                  'SS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name, designation, offline pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Sunita Sharma',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: Color(0xFF16A34A),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'ASHA Worker • Rampur PHC',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 11,
                            color: Color(0xFF6B7280),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Offline mode',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4B5563),
                              fontFamily: 'SF Pro Display',
                            ),
                          ),
                        ],
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

  /// 4 Metric Blocks in a row: 12 Today (green) | 3 Overdue (red) | 8 Completed (green) | 2 Follow-ups (amber)
  Widget _buildMetricStrip(BuildContext context) {
    return Row(
      children: [
        _buildMetricBlock(
          count: '12',
          label: 'Today',
          color: const Color(0xFF16A34A),
          onTap: () => context.go('/due-list'),
        ),
        const SizedBox(width: 8),
        _buildMetricBlock(
          count: '3',
          label: 'Overdue',
          color: const Color(0xFFEF4444),
          onTap: () => context.go('/due-list'),
        ),
        const SizedBox(width: 8),
        _buildMetricBlock(
          count: '8',
          label: 'Completed',
          color: const Color(0xFF16A34A),
          onTap: () => context.go('/due-list'),
        ),
        const SizedBox(width: 8),
        _buildMetricBlock(
          count: '2',
          label: 'Follow-ups',
          color: const Color(0xFFF59E0B),
          onTap: () => context.go('/due-list'),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        key: const Key('home_continue_work_card'),
        onTap: () => context.go('/due-list'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Continue today's work",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '5 households • 2 follow-ups',
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
              const SizedBox(height: 4),
              // Vector illustration of village hills & ASHA worker
              const AshaFieldWorkerIllustrationWidget(height: 105),
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
                title: 'Add Household',
                iconWidget: const Icon(
                  Icons.group_add_rounded,
                  color: Color(0xFF16A34A),
                  size: 22,
                ),
                onTap: () => context.push('/households/new'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                key: const Key('home_triage_button'),
                title: 'Triage Assessment',
                iconWidget: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    color: Color(0xFFDC2626),
                    size: 18,
                  ),
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
                title: 'Speak / Interpreter',
                iconWidget: const Icon(
                  Icons.translate_rounded,
                  color: Color(0xFF16A34A),
                  size: 22,
                ),
                onTap: () => context.push('/interpreter'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionCard(
                title: 'Clinical Programs',
                iconWidget: const Icon(
                  Icons.medical_services_rounded,
                  color: Color(0xFF2563EB),
                  size: 22,
                ),
                onTap: () => context.push('/clinical-programs'),
              ),
            ),
          ],
        ),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
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
class AshaNavigationDrawer extends StatelessWidget {
  const AshaNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF112E20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF29563E), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.lock_rounded,
                          size: 13,
                          color: Color(0xFF22C55E),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Offline • Data Encrypted',
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  // 1. Home (Active white card)
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.home_rounded,
                    title: 'Home',
                    subtitle: 'Dashboard, map, and field desk',
                    isActive: true,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/home');
                    },
                  ),
                  const SizedBox(height: 6),

                  // 2. Today's Due List with red badge 3
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.checklist_rounded,
                    title: "Today's Due List",
                    subtitle: 'Overdue, upcoming visits',
                    badgeCount: '3',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/due-list');
                    },
                  ),
                  const SizedBox(height: 6),

                  // 3. Household Registry
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.people_alt_outlined,
                    title: 'Household Registry',
                    subtitle: 'Census, ABHA IDs',
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
                    title: 'Clinical Programs',
                    subtitle: 'ANC, PNC, Immunization',
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
                    title: 'Emergency Triage',
                    subtitle: 'Maternal & child danger signs',
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
                    title: 'Interpreter',
                    subtitle: 'They speak / I ask',
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
                    title: 'Reports & Incentives',
                    subtitle: 'Earnings, monthly reports',
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
                    title: 'Settings',
                    subtitle: 'App settings, language, help',
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/settings');
                    },
                  ),
                  const SizedBox(height: 16),
                ],
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
    if (isActive) {
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF183D2B), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF183D2B),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF5A7A6A),
                          fontSize: 11,
                          fontFamily: 'SF Pro Display',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF183D2B),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF26563E), width: 0.8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFFA7C7B7),
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
                color: Color(0xFF7CA692),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
