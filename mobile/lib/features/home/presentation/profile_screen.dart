import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/language_selector_dialog.dart';
import '../../../shared/widgets/asha_bottom_nav.dart';
import 'dashboard_screen.dart';

/// Screen 9: Profile matching the master reference image.
/// Top Bar: [ ☰ ]  Profile  [ ⚙ ]
/// Header: SS avatar, Sunita Sharma ✓, ASHA Worker • Rampur PHC, 🔒 Offline Mode >
/// Performance: This Month (28 Visits | 24 Completed | 4 Pending)
/// Options List: Earnings & Incentives, Reports, App Settings
/// Fixed 4-item bottom navigation dock (Profile active).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),
      drawer: const AshaNavigationDrawer(),
      bottomNavigationBar: const AshaBottomNav(index: 3),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top App Bar: [ ☰ ]  Profile  [ ⚙ ]
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

                  const Text(
                    'Profile',
                    style: TextStyle(
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
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                children: [
                  // Worker Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF1E4231),
                          child: const Text(
                            'SS',
                            style: TextStyle(
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
                                children: const [
                                  Text(
                                    'Sunita Sharma',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF111827),
                                      fontFamily: 'SF Pro Display',
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 16,
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
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                                      'Offline Mode',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF4B5563),
                                        fontFamily: 'SF Pro Display',
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 14,
                                      color: Color(0xFF9CA3AF),
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
                  const SizedBox(height: 18),

                  // Performance Metric: "This Month"
                  const Text(
                    'This Month',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      _buildMonthStat('28', 'Visits', const Color(0xFF111827)),
                      const SizedBox(width: 8),
                      _buildMonthStat('24', 'Completed', const Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      _buildMonthStat('4', 'Pending', const Color(0xFFEF4444)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Menu Options List matching Screen 9:
                  // 1. Earnings & Incentives (₹4,200 claimed)
                  _buildListOption(
                    icon: Icons.receipt_long_outlined,
                    title: 'Earnings & Incentives',
                    subtitle: '₹4,200 claimed',
                    onTap: () => context.push('/reports'),
                  ),
                  const SizedBox(height: 10),

                  // 2. Reports (Monthly summary)
                  _buildListOption(
                    icon: Icons.bar_chart_rounded,
                    title: 'Reports',
                    subtitle: 'Monthly summary',
                    onTap: () => context.push('/reports'),
                  ),
                  const SizedBox(height: 10),

                  // 3. App Settings (Language, sync, help)
                  _buildListOption(
                    icon: Icons.settings_outlined,
                    title: 'App Settings',
                    subtitle: 'Language, sync, help',
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const LanguageSelectorDialog(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
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
              Icon(
                icon,
                color: const Color(0xFF16A34A),
                size: 22,
              ),
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
