import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/l10n/language_selector_dialog.dart';

/// Global Navigation Drawer providing direct one-tap access to all 10+ core
/// operational modules of the ASHA Digital Platform.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentRole = ref.watch(userRoleProvider);

    return Drawer(
      child: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Drawer Header ──────────────────────────────────────────────
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  'SS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              accountName: const Row(
                children: [
                  Text(
                    'Sunita Sharma',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.verified, size: 16, color: Colors.amberAccent),
                ],
              ),
              accountEmail: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ASHA Worker • Rampur / Seorahi PHC',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 10, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Offline • AES-256 Encrypted',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Section 1: Field Operations ────────────────────────────────
            _buildSectionHeader(context, 'FIELD OPERATIONS'),
            _buildDrawerTile(
              context: context,
              icon: Icons.checklist_rtl,
              title: "Today's Due List & Scheduler",
              subtitle: 'Red follow-ups, overdue, upcoming',
              route: '/home',
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
              highlightColor: Colors.red.shade100,
              iconColor: Colors.red.shade700,
            ),

            const Divider(),

            // ── Section 2: Administrative & Earnings ───────────────────────
            _buildSectionHeader(context, 'ADMINISTRATIVE & REPORTING'),
            _buildDrawerTile(
              context: context,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Earnings & Monthly Incentives',
              subtitle: '₹4,200 claimed • Direct benefit transfer',
              route: '/incentives',
              badge: '₹4,200',
              badgeColor: Colors.green.shade700,
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

            const Divider(),

            // ── Section 3: Clinical Tools & Job Aids ───────────────────────
            _buildSectionHeader(context, 'CLINICAL AIDS & TOOLS'),
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
              icon: Icons.support_agent_outlined,
              title: 'Teleconsultation & Helpline',
              subtitle: 'Doctor connect & emergency 108',
              route: '/support',
            ),

            const Divider(),

            // ── Settings & Language ────────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.language, color: Colors.blueGrey),
              title: const Text('Change Language / भाषा बदलें'),
              subtitle: const Text('12 Indian Regional Languages'),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (_) => const LanguageSelectorDialog(),
                );
              },
            ),

            // Role toggle for supervision demonstration
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.deepPurple),
              title: const Text('Active Role Switcher'),
              subtitle: Text('Current: ${currentRole.toUpperCase()} (Tap to toggle ASHA / AF)'),
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

            const SizedBox(height: 16),
            const Center(
              child: Text(
                'ASHA Setu Platform • NHM India v1.0.0',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Colors.blueGrey.shade700,
        ),
      ),
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
    return ListTile(
      tileColor: highlightColor,
      leading: Icon(
        icon,
        color: iconColor ?? Theme.of(context).colorScheme.primary,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
      onTap: () {
        Navigator.pop(context); // Close drawer
        context.push(route);
      },
    );
  }
}
