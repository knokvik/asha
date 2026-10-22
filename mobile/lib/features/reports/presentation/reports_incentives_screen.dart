import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/providers/core_providers.dart';
import '../../incentives/data/earnings_repository.dart';
import '../../incentives/domain/earnings_models.dart';
import '../../incentives/domain/incentive_service.dart';

/// Screen 9: Reports & Incentives matching the exact Asha Platform mobile design.
class ReportsIncentivesScreen extends ConsumerStatefulWidget {
  const ReportsIncentivesScreen({super.key});

  @override
  ConsumerState<ReportsIncentivesScreen> createState() =>
      _ReportsIncentivesScreenState();
}

class _ReportsIncentivesScreenState
    extends ConsumerState<ReportsIncentivesScreen> {
  late final String _selectedPeriod;
  bool _loading = true;
  int _visits = 0;
  int _completed = 0;
  int _pending = 0;
  EarningsStatusTotals _earnings = const EarningsStatusTotals();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedPeriod = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _loadLiveData();
  }

  Future<void> _loadLiveData() async {
    setState(() => _loading = true);
    final db = ref.read(appDatabaseProvider);
    final rangeStart = DateTime(DateTime.now().year, DateTime.now().month);
    final rangeEnd = DateTime(DateTime.now().year, DateTime.now().month + 1);
    final encounters = await (db.select(db.clinicalEncounters)
          ..where((row) => row.encounterDate.isBiggerOrEqualValue(
                rangeStart.millisecondsSinceEpoch,
              ) & row.encounterDate.isSmallerThanValue(
                rangeEnd.millisecondsSinceEpoch,
              )))
        .get();
    final service = IncentiveService(
      db: db,
      syncEngine: ref.read(syncEngineProvider),
    );
    await service.loadDefaultCatalogueFromAssets();
    final repository = EarningsRepository(db: db, incentiveService: service);
    final earnings = await repository.getStatusTotals(_selectedPeriod);
    if (!mounted) return;
    setState(() {
      _visits = encounters.length;
      _completed = encounters.where((row) => row.status == 'completed').length;
      _pending = encounters.length - _completed;
      _earnings = earnings;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: AshaColors.cardSurface,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AshaColors.textPrimary,
          ),
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadLiveData,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
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
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AshaColors.textMuted,
                      ),
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
                  count: '$_visits',
                  label: 'Visits',
                  bgColor: const Color(0xFFEFF6FF),
                  textColor: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  count: '$_completed',
                  label: 'Completed',
                  bgColor: const Color(0xFFF0FDF4),
                  textColor: const Color(0xFF16A34A),
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  count: '$_pending',
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
              subtitle:
                  '₹${(_earnings.approvedAmount + _earnings.paidAmount).toStringAsFixed(0)} approved / paid',
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
              onTap: () => context.push(
                '/reports/registers?register=monthly_report&view=pdf',
              ),
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
                  SnackBar(
                    content: Text(
                      '$_pending encounters are pending completion or sync.',
                    ),
                  ),
                );
              },
            ),
          ],
                ),
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
