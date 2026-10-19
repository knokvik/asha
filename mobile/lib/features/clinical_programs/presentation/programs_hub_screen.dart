import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/asha_badge.dart';
import '../../../shared/widgets/asha_card.dart';

/// Central Hub for all National Health Mission (NHM) clinical programs.
/// Provides direct access to clinical checklists, screening tools, and registers.
class ProgramsHubScreen extends ConsumerStatefulWidget {
  const ProgramsHubScreen({super.key});

  @override
  ConsumerState<ProgramsHubScreen> createState() => _ProgramsHubScreenState();
}

class _ProgramsHubScreenState extends ConsumerState<ProgramsHubScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Programs & Protocols'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Beneficiary',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner (DocSpot Forest Gradient + Zevoa Leaf Mint)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AshaColors.primary,
                  AshaColors.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AshaShapes.cardRadius,
            ),
            child: const Row(
              children: [
                Icon(Icons.health_and_safety, color: AshaColors.leafMint, size: 38),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'National Health Mission (NHM)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'All clinical checklists operate offline with automated danger-sign triage & eligibility tracking.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Section 1: Maternal Health (RCH / ANC / PNC) ─────────────────
          _buildSectionHeader(
            context,
            'MATERNAL & REPRODUCTIVE HEALTH',
            Icons.pregnant_woman,
            Colors.purple,
          ),
          _buildProgramCard(
            context: context,
            title: 'ANC Pregnancy Registration',
            subtitle: 'First trimester MCP card booking, LMP, EDD calculation, High-Risk flag',
            code: 'ANC-REG',
            badge: 'Req 14.1',
            badgeColor: Colors.purple.shade700,
            icon: Icons.app_registration,
            onTap: () => context.push('/programs/anc-register'),
          ),
          _buildProgramCard(
            context: context,
            title: 'Antenatal Care (ANC) Contact Visit',
            subtitle: '4-visit protocol: BP, Hb, IFA, TT, fundal height, pre-eclampsia red alert',
            code: 'ANC',
            badge: 'Req 14.2',
            badgeColor: Colors.purple.shade700,
            icon: Icons.checklist_outlined,
            onTap: () => context.push('/programs/anc-visit'),
          ),
          _buildProgramCard(
            context: context,
            title: 'Postnatal Care (PNC) Maternal Visit',
            subtitle: 'Day 1, 3, 7, 14, 21, 28, 42 postpartum visits, lochia, breast care, PPH',
            code: 'PNC',
            badge: 'Req 15.1',
            badgeColor: Colors.pink.shade700,
            icon: Icons.child_friendly_outlined,
            onTap: () => context.push('/programs/pnc-visit'),
          ),

          const SizedBox(height: 16),

          // ── Section 2: Child Health (HBNC / HBYC / Immunization) ─────────
          _buildSectionHeader(
            context,
            'NEWBORN & CHILD HEALTH',
            Icons.child_care,
            Colors.blue,
          ),
          _buildProgramCard(
            context: context,
            title: 'Home Based Newborn Care (HBNC)',
            subtitle: 'Day 1 to 42 newborn checkup, birth weight, KMC guidance, sepsis triage',
            code: 'HBNC',
            badge: 'Req 12.2',
            badgeColor: Colors.blue.shade700,
            icon: Icons.baby_changing_station,
            onTap: () => context.push('/programs/hbnc-visit'),
          ),
          _buildProgramCard(
            context: context,
            title: 'Home Based Care for Young Child (HBYC)',
            subtitle: 'Months 3 to 15 checkup, feeding, milestone delays (RBSK/DEIC), illness triage',
            code: 'HBYC',
            badge: 'Req 13.1',
            badgeColor: Colors.cyan.shade700,
            icon: Icons.escalator_warning,
            onTap: () => context.push('/programs/hbyc-visit'),
          ),
          _buildProgramCard(
            context: context,
            title: 'Child Immunization & MCP Matrix',
            subtitle: 'BCG, OPV, Pentavalent, Rota, MR, PCV, DPT, AEFI adverse event report',
            code: 'IMMUNIZATION',
            badge: 'Req 16.1',
            badgeColor: Colors.indigo.shade700,
            icon: Icons.vaccines,
            onTap: () => context.push('/programs/immunization'),
          ),
          _buildProgramCard(
            context: context,
            title: 'Growth & Malnutrition Monitoring',
            subtitle: 'WHO Z-scores (WAZ, HAZ, WHZ), MUAC tape, SAM/MAM staging, NRC referral',
            code: 'GROWTH',
            badge: 'Req 17.1',
            badgeColor: Colors.teal.shade700,
            icon: Icons.monitor_weight_outlined,
            onTap: () => context.push('/programs/growth'),
          ),

          const SizedBox(height: 16),

          // ── Section 3: Non-Communicable Diseases (NCD & CBAC) ───────────
          _buildSectionHeader(
            context,
            'NON-COMMUNICABLE DISEASES (NCD)',
            Icons.favorite_outline,
            Colors.red,
          ),
          _buildProgramCard(
            context: context,
            title: 'CBAC Risk Assessment Checklist',
            subtitle: 'Adults >= 30: tobacco, alcohol, waist circumference, cancer warning signs',
            code: 'CBAC',
            badge: 'Req 19.1',
            badgeColor: Colors.red.shade700,
            icon: Icons.fact_check_outlined,
            onTap: () => context.push('/programs/cbac'),
          ),
          _buildProgramCard(
            context: context,
            title: 'NCD Chronic Care Register',
            subtitle: 'Hypertension & Diabetes monthly refill tracking, overdue tracing, CSV export',
            code: 'NCD-REG',
            badge: 'Req 19.4',
            badgeColor: Colors.deepOrange.shade700,
            icon: Icons.assignment_outlined,
            onTap: () => context.push('/programs/ncd-register'),
          ),

          const SizedBox(height: 16),

          // ── Section 4: Communicable Diseases & Outreach ──────────────────
          _buildSectionHeader(
            context,
            'COMMUNICABLE DISEASE & COMMUNITY',
            Icons.coronavirus_outlined,
            Colors.amber.shade900,
          ),
          _buildProgramCard(
            context: context,
            title: 'Presumptive TB Screening & Sputum',
            subtitle: 'Cough >= 2 weeks, Nikshay sputum collection, strict anti-stigma privacy filter',
            code: 'TB',
            badge: 'Req 20.1',
            badgeColor: Colors.amber.shade900,
            icon: Icons.medical_information_outlined,
            onTap: () => context.push('/programs/tb-presumptive'),
          ),
          _buildProgramCard(
            context: context,
            title: 'TB DOTS Treatment Card',
            subtitle: 'Daily medication observation, consecutive missed-dose alert, Poshan Yojana',
            code: 'TB-DOTS',
            badge: 'Req 20.3',
            badgeColor: Colors.amber.shade900,
            icon: Icons.medication_outlined,
            onTap: () => context.push('/programs/tb-card'),
          ),
          _buildProgramCard(
            context: context,
            title: 'VHSND Session Planner & Mobilisation',
            subtitle: 'Village Health Sanitation & Nutrition Day mobilisation, attendance, service delivery',
            code: 'VHSND',
            badge: 'Req 27.1',
            badgeColor: Colors.brown.shade700,
            icon: Icons.groups_outlined,
            onTap: () => context.push('/programs/vhsnd'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgramCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String code,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AshaCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: badgeColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AshaColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AshaColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.arrow_forward_ios, size: 14, color: AshaColors.textMuted),
          ),
        ],
      ),
    );
  }
}
