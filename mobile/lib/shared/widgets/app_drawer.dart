import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';

/// Screen 2: Side Menu (Drawer) matching the exact Asha Platform mobile design.
///
/// Features deep forest green background, worker profile header with encrypted
/// offline badge, and high-contrast navigational cards with clear clinical icons.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: const Color(0xFF1E4231),
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row with Avatar, Name, and Close X button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar: White circle with green SS
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        child: Text(
                          'SS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E4231),
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
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Colors.white,
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
                                color: Color(0xFFB7D5C6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 24,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Offline - Data Encrypted Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.lock_rounded,
                          size: 12,
                          color: AshaColors.leafMint,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Offline • Data Encrypted',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF2D5F47), height: 1),

            // Navigation Menu Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                children: [
                  // 1. Home (Active state)
                  _buildMenuItem(
                    context: context,
                    icon: Icons.home_rounded,
                    title: 'Home',
                    subtitle: 'Dashboard, map, and field desk',
                    route: '/home',
                    isSelected: true,
                  ),
                  const SizedBox(height: 6),

                  // 2. Today's Due List
                  _buildMenuItem(
                    context: context,
                    icon: Icons.checklist_rtl_rounded,
                    title: "Today's Due List",
                    subtitle: 'Overdue, upcoming visits',
                    route: '/due-list',
                    trailingBadge: '3',
                    badgeColor: AshaColors.alertHighRisk,
                  ),
                  const SizedBox(height: 6),

                  // 3. Household Registry
                  _buildMenuItem(
                    context: context,
                    icon: Icons.people_alt_outlined,
                    title: 'Household Registry',
                    subtitle: 'Census, ABHA IDs',
                    route: '/households',
                  ),
                  const SizedBox(height: 6),

                  // 4. Clinical Programs
                  _buildMenuItem(
                    context: context,
                    icon: Icons.medical_services_outlined,
                    title: 'Clinical Programs',
                    subtitle: 'ANC, PNC, Immunization',
                    route: '/clinical-programs',
                  ),
                  const SizedBox(height: 6),

                  // 5. Emergency Triage
                  _buildMenuItem(
                    context: context,
                    icon: Icons.emergency_rounded,
                    title: 'Emergency Triage',
                    subtitle: 'Maternal & child danger signs',
                    route: '/triage',
                    iconColor: AshaColors.alertHighRisk,
                    showRedChevron: true,
                  ),
                  const SizedBox(height: 6),

                  // 6. Interpreter
                  _buildMenuItem(
                    context: context,
                    icon: Icons.translate_rounded,
                    title: 'Interpreter',
                    subtitle: 'They speak / I ask',
                    route: '/interpreter',
                  ),
                  const SizedBox(height: 6),

                  // 7. Reports & Incentives
                  _buildMenuItem(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    title: 'Reports & Incentives',
                    subtitle: 'Earnings, monthly reports',
                    route: '/reports',
                  ),
                  const SizedBox(height: 6),

                  // 8. Settings
                  _buildMenuItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'App settings, language, help',
                    route: '/profile',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    bool isSelected = false,
    String? trailingBadge,
    Color? badgeColor,
    Color? iconColor,
    bool showRedChevron = false,
  }) {
    final bgColor = isSelected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.08);
    final titleColor = isSelected ? const Color(0xFF1E4231) : Colors.white;
    final subtitleColor = isSelected
        ? AshaColors.textSecondary
        : const Color(0xFFB7D5C6);
    final effectiveIconColor =
        iconColor ?? (isSelected ? const Color(0xFF1E4231) : Colors.white);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).pop();
          if (route == '/home') {
            context.go(route);
          } else {
            context.push(route);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: effectiveIconColor, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              if (trailingBadge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AshaColors.alertHighRisk,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    trailingBadge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: showRedChevron
                    ? AshaColors.alertHighRisk
                    : (isSelected ? const Color(0xFF1E4231) : Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
