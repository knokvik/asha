import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/l10n/language_selector_dialog.dart';

/// Global Navigation Drawer providing direct one-tap access to all core
/// operational modules of the ASHA Digital Platform with AshaSetu Unified styling.
class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  final _open = <String, bool>{
    'field': true,
    'admin': true,
    'clinical': true,
  };

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final currentRole = ref.watch(userRoleProvider);

    return Drawer(
      backgroundColor: AshaColors.cardSurface,
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Drawer Header (DocSpot Forest Gradient + Zevoa Mint) ───────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AshaColors.primary,
                    AshaColors.primaryDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        child: Text(
                          'SS',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AshaColors.primaryDark,
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
                                const Flexible(
                                  child: Text(
                                    'Sunita Sharma',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.verified,
                                  size: 18,
                                  color: AshaColors.leafMint,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'ASHA Worker • Rampur PHC',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Offline • AES-256 SQLCipher Encrypted',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Section 1: Field Operations ────────────────────────────────
            _section('field', 'FIELD OPERATIONS', [
            _buildDrawerTile(
              context: context,
              icon: Icons.dashboard_outlined,
              title: 'Home',
              subtitle: 'Dashboard, map, and field desk',
              route: '/home',
            ),
            _buildDrawerTile(
              context: context,
              icon: Icons.checklist_rtl,
              title: "Today's Due List & Scheduler",
              subtitle: 'Red follow-ups, overdue, upcoming',
              route: '/due-list',
            ),
            _buildDrawerTile(
              context: context,
              icon: Icons.people_alt_outlined,
              title: 'Household & Population Registry',
              subtitle: 'Village census, ABHA IDs, consent',
              route: '/households',
            ),
            _buildDrawerTile(
              context: context,
              icon: Icons.medical_services_outlined,
              title: 'Clinical Programs Hub',
              subtitle: 'ANC, PNC, HBNC, HBYC, NCD, TB, Immunization',
              route: '/programs',
            ),
            _buildDrawerTile(
              context: context,
              icon: Icons.emergency_outlined,
              title: 'Emergency Triage & Danger Signs',
              subtitle: 'IMNCI & maternal red alert triage',
              route: '/triage',
              highlightColor: AshaColors.alertHighRisk.withValues(alpha: 0.08),
              iconColor: AshaColors.alertHighRisk,
            ),
            _buildDrawerTile(
              context: context,
              icon: Icons.fact_check_outlined,
              title: 'Setu triage questions',
              subtitle: 'One question at a time, then a referral QR',
              route: '/triage/questions',
            ),
            _buildDrawerTile(
              context: context,
              icon: Icons.translate,
              title: 'They speak / I ask',
              subtitle: 'Hear the family, or ask in their language',
              route: '/triage/language',
            ),
            ]),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Divider(color: AshaColors.borderSubtle),
            ),

            // ── Section 2: Administrative & Earnings ───────────────────────
            _section('admin', 'ADMINISTRATIVE & REPORTING', [
            _buildDrawerTile(
              context: context,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Earnings & Monthly Incentives',
              subtitle: '₹4,200 claimed • Direct benefit transfer',
              route: '/incentives',
              badge: '₹4,200',
              badgeColor: AshaColors.vitalNormal,
            ),
            _buildDrawerTile(
              context: context,
              icon: Icons.medication_liquid_outlined,
              title: 'Medicine & Equipment Stock',
              subtitle: 'ASHA drug kit, IFA, BP monitor',
              route: '/stock',
            ),
            _buildDrawerTile(
              context: context,
              icon: Icons.menu_book_outlined,
              title: 'Government Registers & PDF Reports',
              subtitle: 'RCH, ANC, PNC, HBNC, CBAC registers',
              route: '/reports',
            ),
            ]),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Divider(color: AshaColors.borderSubtle),
            ),

            // ── Section 3: Clinical Tools & Job Aids ───────────────────────
            _section('clinical', 'CLINICAL AIDS & TOOLS', [
            _buildDrawerTile(
              context: context,
              icon: Icons.calculate_outlined,
              title: 'Clinical Calculators & Timers',
              subtitle: 'EDD, BMI, MUAC, 60s breath counter',
              route: '/calculators',
            ),
            _buildDrawerTile(
              context: context,
              icon: Icons.school_outlined,
              title: 'Training & Micro-Learning',
              subtitle: 'Video modules, quizzes & job aids',
              route: '/learning',
            ),
            _buildDrawerTile(
              context: context,
              icon: Icons.video_library_outlined,
              title: 'Health Education Media Library',
              subtitle: 'Community awareness audio & posters',
              route: '/education',
            ),
            _buildDrawerTile(
              context: context,
              icon: Icons.map_outlined,
              title: 'Visit Route & Hamlet Map',
              subtitle: 'Offline nearest-neighbor routing',
              route: '/route-map',
            ),
            _buildDrawerTile(
              context: context,
              icon: Icons.public_off,
              title: 'Offline field map',
              subtitle: 'Facilities, disease radar, today\'s route',
              route: '/geo-map',
            ),
            _buildDrawerTile(
              context: context,
              icon: Icons.support_agent_outlined,
              title: 'Teleconsultation & Helpline',
              subtitle: 'Doctor connect & emergency 108',
              route: '/support',
              iconColor: AshaColors.teleConsultBlue,
            ),
            ]),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Divider(color: AshaColors.borderSubtle),
            ),

            // ── Settings & Language ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AshaColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.language, color: AshaColors.textSecondary, size: 20),
                ),
                title: const Text(
                  'Change Language / भाषा बदलें',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AshaColors.textPrimary),
                ),
                subtitle: const Text(
                  '12 Indian Regional Languages',
                  style: TextStyle(fontSize: 12, color: AshaColors.textSecondary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => const LanguageSelectorDialog(),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AshaColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.swap_horiz, color: AshaColors.primary, size: 20),
                ),
                title: const Text(
                  'Active Role Switcher',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AshaColors.textPrimary),
                ),
                subtitle: Text(
                  'Current: ${currentRole.toUpperCase()} (Tap to toggle ASHA / AF)',
                  style: const TextStyle(fontSize: 12, color: AshaColors.textSecondary),
                ),
                onTap: () {
                  final newRole = currentRole == 'asha' ? 'af' : 'asha';
                  ref.read(userRoleProvider.notifier).setRole(newRole);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Switched active role to: ${newRole.toUpperCase()}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: Text(
                'ASHA Setu Platform • NHM India v1.0.0',
                style: AshaTypography.subtitleSmall.copyWith(
                  color: AshaColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _section(String id, String title, List<Widget> children) {
    final open = _open[id] ?? true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open[id] = !open),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 12, top: 12, bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: AshaColors.textMuted,
                    ),
                  ),
                ),
                Icon(open ? Icons.expand_less : Icons.expand_more, size: 18, color: AshaColors.textMuted),
              ],
            ),
          ),
        ),
        if (open) ...children,
      ],
    );
  }

  Widget _buildDrawerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
    String? badge,
    Color? badgeColor,
    Color? highlightColor,
    Color? iconColor,
  }) {
    final effectiveIconColor = iconColor ?? AshaColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: highlightColor,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (highlightColor != null)
                ? effectiveIconColor.withValues(alpha: 0.12)
                : AshaColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: effectiveIconColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AshaColors.textPrimary,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor ?? AshaColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AshaColors.textSecondary,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (route == '/home') {
            context.go(route);
          } else {
            context.push(route);
          }
        },
      ),
    );
  }
}
