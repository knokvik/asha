import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/shell/shell_copy.dart';
import '../../../shared/widgets/asha_bottom_nav.dart';
import '../../../shared/widgets/asha_svg_illustrations.dart';

/// Screen 7: Clinical Programs matching the exact Asha Platform mobile design.
class ProgramsHubScreen extends ConsumerWidget {
  const ProgramsHubScreen({super.key});

  void _openEntryMode(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required ClinicalProgramType type,
    required String registrationRoute,
    required String visitRouteBase,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ProgramEntrySelectionSheet(
        title: title,
        subtitle: subtitle,
        type: type,
        registrationRoute: registrationRoute,
        visitRouteBase: visitRouteBase,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).languageCode;
    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      bottomNavigationBar: const AshaBottomNav(index: 2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
        title: Text(
          shellText(lang, 'clinicalPrograms'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AshaColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.88,
          children: [
            _ClinicalCard(
              title: 'ANC',
              subtitle: shellText(lang, 'ancSubtitle'),
              type: ClinicalProgramType.anc,
              bgColor: const Color(0xFFF0FDF4),
              onTap: () => _openEntryMode(
                context,
                ref,
                title: 'ANC (Antenatal Care)',
                subtitle: shellText(lang, 'ancSubtitle'),
                type: ClinicalProgramType.anc,
                registrationRoute: '/programs/anc-register',
                visitRouteBase: '/programs/anc-visit',
              ),
            ),
            _ClinicalCard(
              title: 'PNC',
              subtitle: shellText(lang, 'pncSubtitle'),
              type: ClinicalProgramType.pnc,
              bgColor: const Color(0xFFEFF6FF),
              onTap: () => _openEntryMode(
                context,
                ref,
                title: 'PNC (Postnatal Care)',
                subtitle: shellText(lang, 'pncSubtitle'),
                type: ClinicalProgramType.pnc,
                registrationRoute: '/programs/anc-register',
                visitRouteBase: '/programs/pnc-visit',
              ),
            ),
            _ClinicalCard(
              title: 'Immunization',
              subtitle: shellText(lang, 'immunizationSubtitle'),
              type: ClinicalProgramType.immunization,
              bgColor: const Color(0xFFFEF3C7),
              onTap: () => _openEntryMode(
                context,
                ref,
                title: 'Child Immunization',
                subtitle: shellText(lang, 'immunizationSubtitle'),
                type: ClinicalProgramType.immunization,
                registrationRoute: '/household/add',
                visitRouteBase: '/programs/immunization',
              ),
            ),
            _ClinicalCard(
              title: 'NCD',
              subtitle: shellText(lang, 'ncdSubtitle'),
              type: ClinicalProgramType.ncd,
              bgColor: const Color(0xFFFEE2E2),
              onTap: () => _openEntryMode(
                context,
                ref,
                title: 'NCD & CBAC Screening',
                subtitle: shellText(lang, 'ncdSubtitle'),
                type: ClinicalProgramType.ncd,
                registrationRoute: '/household/add',
                visitRouteBase: '/programs/cbac',
              ),
            ),
            _ClinicalCard(
              title: 'HBNC',
              subtitle: shellText(lang, 'hbncSubtitle'),
              type: ClinicalProgramType.hbnc,
              bgColor: const Color(0xFFECFDF5),
              onTap: () => _openEntryMode(
                context,
                ref,
                title: 'HBNC (Home Newborn Care)',
                subtitle: shellText(lang, 'hbncSubtitle'),
                type: ClinicalProgramType.hbnc,
                registrationRoute: '/programs/anc-register',
                visitRouteBase: '/programs/hbnc-visit',
              ),
            ),
            _ClinicalCard(
              title: 'TB',
              subtitle: shellText(lang, 'tbSubtitle'),
              type: ClinicalProgramType.tb,
              bgColor: const Color(0xFFFFF1F2),
              onTap: () => _openEntryMode(
                context,
                ref,
                title: 'TB Screening & Nikshay',
                subtitle: shellText(lang, 'tbSubtitle'),
                type: ClinicalProgramType.tb,
                registrationRoute: '/household/add',
                visitRouteBase: '/programs/tb-presumptive',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramEntrySelectionSheet extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final ClinicalProgramType type;
  final String registrationRoute;
  final String visitRouteBase;

  const _ProgramEntrySelectionSheet({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.registrationRoute,
    required this.visitRouteBase,
  });

  @override
  ConsumerState<_ProgramEntrySelectionSheet> createState() =>
      _ProgramEntrySelectionSheetState();
}

class _ProgramEntrySelectionSheetState
    extends ConsumerState<_ProgramEntrySelectionSheet> {
  final _searchController = TextEditingController();
  List<Map<String, String>> _beneficiaries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBeneficiaries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBeneficiaries() async {
    final db = ref.read(appDatabaseProvider);
    try {
      final members = await db.select(db.members).get();
      if (members.isNotEmpty) {
        setState(() {
          _beneficiaries = members.map((m) {
            return {
              'id': m.id,
              'name': m.name,
              'sex': m.sex,
              'phone': m.phone ?? '',
              'rch': m.rchId ?? m.abhaId ?? 'Registered Village Member',
            };
          }).toList();
          _loading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback default field beneficiaries
    setState(() {
      _beneficiaries = [
        {'id': 'mem_pooja_01', 'name': 'Pooja Devi', 'sex': 'F', 'phone': '9876501122', 'rch': 'RCH-2026-90123 · ANC Contact 3 Due'},
        {'id': 'mem_kavita_02', 'name': 'Kavita Singh', 'sex': 'F', 'phone': '9876512345', 'rch': 'RCH-2026-88124 · Postpartum Day 7'},
        {'id': 'mem_aarav_02', 'name': 'Baby Aarav', 'sex': 'M', 'phone': '9876512345', 'rch': 'HBNC Series · Day 7 Newborn'},
        {'id': 'mem_priya_04', 'name': 'Priya Yadav', 'sex': 'F', 'phone': '9876543210', 'rch': 'RCH-2025-44551 · Immunization MR-1'},
        {'id': 'mem_ramprasad_03', 'name': 'Ramprasad Verma', 'sex': 'M', 'phone': '9811223344', 'rch': 'NCD CBAC Screening · Age 48'},
        {'id': 'mem_shanti_05', 'name': 'Shanti Devi', 'sex': 'F', 'phone': '9833445566', 'rch': 'Presumptive TB Follow-up'},
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _beneficiaries
        : _beneficiaries.where((b) {
            return b['name']!.toLowerCase().contains(query) ||
                b['phone']!.contains(query) ||
                b['rch']!.toLowerCase().contains(query);
          }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AshaColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  color: AshaColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AshaColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose an existing patient for regular visit or make first-time registration.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AshaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Option 1: First-time entry button
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AshaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              context.push(widget.registrationRoute);
            },
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
            label: const Text(
              '+ First-Time Entry / Register New Patient',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
          const SizedBox(height: 18),

          // Option 2: Choose existing patient for regular follow-up visit
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, size: 16, color: AshaColors.textSecondary),
              const SizedBox(width: 6),
              const Text(
                'Select Registered Beneficiary (Regular Visit)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AshaColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search input
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by name, RCH, or mobile number...',
              hintStyle: const TextStyle(fontSize: 13, color: AshaColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AshaColors.borderSubtle),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Beneficiary list
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No matching beneficiary found.\nUse the button above to register as a first-time entry.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final b = filtered[idx];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: CircleAvatar(
                              radius: 18,
                              backgroundColor: AshaColors.surfaceMuted,
                              child: Icon(
                                b['sex'] == 'F' ? Icons.face_3_rounded : Icons.face_rounded,
                                color: AshaColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              b['name']!,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AshaColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              b['rch']!,
                              style: const TextStyle(fontSize: 11, color: AshaColors.textSecondary),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'Regular Visit',
                                    style: TextStyle(
                                      color: Color(0xFF15803D),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF15803D)),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.of(context).pop();
                              final suffix = '?memberId=${Uri.encodeComponent(b['id']!)}&name=${Uri.encodeComponent(b['name']!)}';
                              context.push('${widget.visitRouteBase}$suffix');
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalCard extends StatelessWidget {
  const _ClinicalCard({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.bgColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final ClinicalProgramType type;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AshaColors.cardSurface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AshaColors.borderSubtle, width: 0.9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bundled clinical-program illustration and navigation affordance.
              Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 112,
                    child: AshaClinicalProgramIllustrationWidget(
                      type: type,
                      size: 112,
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: AshaColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Title: ANC, PNC, etc.
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AshaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              // Subtitle
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AshaColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
