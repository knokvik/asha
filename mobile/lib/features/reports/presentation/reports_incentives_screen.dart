import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';

/// Screen 9: Reports & Incentives matching the exact Asha Platform mobile design.
class ReportsIncentivesScreen extends StatefulWidget {
  const ReportsIncentivesScreen({super.key});

  @override
  State<ReportsIncentivesScreen> createState() => _ReportsIncentivesScreenState();
}

class _ReportsIncentivesScreenState extends State<ReportsIncentivesScreen> {
  final String _selectedPeriod = 'This Month';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: AshaColors.cardSurface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AshaColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Reports & Incentives',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AshaColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Period Filter Dropdown / Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedPeriod,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AshaColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AshaColors.borderSubtle),
                  ),
                  child: Row(
                    children: const [
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AshaColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AshaColors.textMuted),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 3 Stat Cards: 28 Visits | 24 Completed | 4 Pending
            Row(
              children: [
                _buildStatCard(
                  count: '28',
                  label: 'Visits',
                  bgColor: const Color(0xFFEFF6FF),
                  textColor: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  count: '24',
                  label: 'Completed',
                  bgColor: const Color(0xFFF0FDF4),
                  textColor: const Color(0xFF16A34A),
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  count: '4',
                  label: 'Pending',
                  bgColor: const Color(0xFFFEF2F2),
                  textColor: const Color(0xFFDC2626),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 1. Earnings & Incentives
            _buildActionTile(
              icon: Icons.payments_outlined,
              iconColor: AshaColors.vitalNormal,
              iconBgColor: const Color(0xFFDCFCE7),
              title: 'Earnings & Incentives',
              subtitle: '₹4,200 claimed',
              onTap: () => context.push('/incentives'),
            ),

            const SizedBox(height: 12),

            // 2. Monthly Summary
            _buildActionTile(
              icon: Icons.bar_chart_rounded,
              iconColor: const Color(0xFF0284C7),
              iconBgColor: const Color(0xFFE0F2FE),
              title: 'Monthly Summary',
              subtitle: 'Visit reports, coverage',
              onTap: () => context.push('/coverage'),
            ),

            const SizedBox(height: 12),

            // 3. Submit Reports
            _buildActionTile(
              icon: Icons.sync_rounded,
              iconColor: AshaColors.primary,
              iconBgColor: AshaColors.primaryLight,
              title: 'Submit Reports',
              subtitle: 'Sync when online',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reports verified. 12 encounters queued for background sync.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String count,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AshaColors.cardSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AshaColors.borderSubtle, width: 0.9),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
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
                        fontWeight: FontWeight.w700,
                        color: AshaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AshaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AshaColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
