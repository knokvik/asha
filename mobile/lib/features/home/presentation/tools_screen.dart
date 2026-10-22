import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../shared/shell/shell_copy.dart';
import '../../../shared/widgets/asha_bottom_nav.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).languageCode;

    final tools = <_Tool>[
      _Tool(
        Icons.medical_services_outlined,
        shellText(lang, 'clinicalTriageTool'),
        shellText(lang, 'clinicalTriageSub'),
        '/triage',
        const Color(0xFFDCFCE7),
        const Color(0xFF15803D),
      ),
      _Tool(
        Icons.translate_rounded,
        shellText(lang, 'interpreterTool'),
        shellText(lang, 'interpreterToolSub'),
        '/triage/language',
        const Color(0xFFE0F2FE),
        const Color(0xFF0284C7),
      ),
      _Tool(
        Icons.people_alt_outlined,
        shellText(lang, 'householdsTool'),
        shellText(lang, 'householdsToolSub'),
        '/households',
        const Color(0xFFF3E8FF),
        const Color(0xFF7E22CE),
      ),
      _Tool(
        Icons.medical_information_outlined,
        shellText(lang, 'clinicalProgramsTool'),
        shellText(lang, 'clinicalProgramsToolSub'),
        '/programs',
        const Color(0xFFFFEDD5),
        const Color(0xFFC2410C),
      ),
      _Tool(
        Icons.inventory_2_outlined,
        shellText(lang, 'stock'),
        shellText(lang, 'stockSub'),
        '/devices/stock',
        const Color(0xFFFEF3C7),
        const Color(0xFFB45309),
      ),
      _Tool(
        Icons.menu_book_outlined,
        shellText(lang, 'jobAidsLibrary'),
        'Multimedia counseling & guidelines',
        '/education',
        const Color(0xFFFCE7F3),
        const Color(0xFFBE185D),
      ),
      _Tool(
        Icons.map_outlined,
        shellText(lang, 'maps'),
        shellText(lang, 'mapsSub'),
        '/map',
        const Color(0xFFE0E7FF),
        const Color(0xFF4338CA),
      ),
      _Tool(
        Icons.school_outlined,
        shellText(lang, 'learning'),
        shellText(lang, 'learningSub'),
        '/learning',
        const Color(0xFFCCFBF1),
        const Color(0xFF0F766E),
      ),
      _Tool(
        Icons.calculate_outlined,
        shellText(lang, 'calculatorsTool'),
        shellText(lang, 'calculatorsToolSub'),
        '/calculators',
        const Color(0xFFF1F5F9),
        const Color(0xFF475569),
      ),
    ];

    return Scaffold(
      key: const Key('tools_screen'),
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        title: Text(
          shellText(lang, 'toolsTitle'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      bottomNavigationBar: const AshaBottomNav(index: 2),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.18,
        children: [
          for (final tool in tools)
            Material(
              color: AshaColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push(tool.route),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AshaColors.borderSubtle,
                      width: 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: tool.iconBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(tool.icon, color: tool.iconColor, size: 22),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AshaColors.textMuted,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        tool.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AshaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tool.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.25,
                          color: AshaColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tool {
  const _Tool(
    this.icon,
    this.title,
    this.subtitle,
    this.route,
    this.iconBg,
    this.iconColor,
  );
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color iconBg;
  final Color iconColor;
}
