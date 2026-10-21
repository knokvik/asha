import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../shared/shell/shell_copy.dart';
import '../../../shared/widgets/asha_bottom_nav.dart';
import '../../../shared/widgets/asha_svg_illustrations.dart';

/// Screen 7: Clinical Programs matching the exact Asha Platform mobile design.
class ProgramsHubScreen extends ConsumerWidget {
  const ProgramsHubScreen({super.key});

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
              onTap: () => context.push('/programs/anc-register'),
            ),
            _ClinicalCard(
              title: 'PNC',
              subtitle: shellText(lang, 'pncSubtitle'),
              type: ClinicalProgramType.pnc,
              bgColor: const Color(0xFFEFF6FF),
              onTap: () => context.push('/programs/pnc-visit'),
            ),
            _ClinicalCard(
              title: 'Immunization',
              subtitle: shellText(lang, 'immunizationSubtitle'),
              type: ClinicalProgramType.immunization,
              bgColor: const Color(0xFFFEF3C7),
              onTap: () => context.push('/programs/immunization'),
            ),
            _ClinicalCard(
              title: 'NCD',
              subtitle: shellText(lang, 'ncdSubtitle'),
              type: ClinicalProgramType.ncd,
              bgColor: const Color(0xFFFEE2E2),
              onTap: () => context.push('/programs/cbac'),
            ),
            _ClinicalCard(
              title: 'HBNC',
              subtitle: shellText(lang, 'hbncSubtitle'),
              type: ClinicalProgramType.hbnc,
              bgColor: const Color(0xFFECFDF5),
              onTap: () => context.push('/programs/hbnc-visit'),
            ),
            _ClinicalCard(
              title: 'TB',
              subtitle: shellText(lang, 'tbSubtitle'),
              type: ClinicalProgramType.tb,
              bgColor: const Color(0xFFFFF1F2),
              onTap: () => context.push('/programs/tb-presumptive'),
            ),
          ],
        ),
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
              // Top Vector SVG Illustration & Chevron
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    alignment: Alignment.center,
                    child: AshaClinicalProgramIllustrationWidget(
                      type: type,
                      size: 54,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AshaColors.textMuted,
                  ),
                ],
              ),
              const Spacer(),
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
