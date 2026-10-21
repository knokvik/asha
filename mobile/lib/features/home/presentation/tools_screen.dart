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
      ),
      _Tool(
        Icons.translate,
        shellText(lang, 'interpreterTool'),
        shellText(lang, 'interpreterToolSub'),
        '/triage/language',
      ),
      _Tool(
        Icons.checklist_rtl,
        shellText(lang, 'dueListTool'),
        shellText(lang, 'dueListToolSub'),
        '/due-list',
      ),
      _Tool(
        Icons.calendar_month,
        shellText(lang, 'calendarTool'),
        shellText(lang, 'calendarToolSub'),
        '/calendar',
      ),
      _Tool(
        Icons.pie_chart_outline,
        shellText(lang, 'coverageTool'),
        shellText(lang, 'coverageToolSub'),
        '/coverage',
      ),
      _Tool(
        Icons.people_alt_outlined,
        shellText(lang, 'householdsTool'),
        shellText(lang, 'householdsToolSub'),
        '/households',
      ),
      _Tool(
        Icons.medical_information_outlined,
        shellText(lang, 'clinicalProgramsTool'),
        shellText(lang, 'clinicalProgramsToolSub'),
        '/programs',
      ),
      _Tool(
        Icons.calculate_outlined,
        shellText(lang, 'calculatorsTool'),
        shellText(lang, 'calculatorsToolSub'),
        '/calculators',
      ),
    ];
    return Scaffold(
      key: const Key('tools_screen'),
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        title: Text(shellText(lang, 'toolsTitle')),
      ),
      bottomNavigationBar: const AshaBottomNav(index: 2),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: [
          for (final tool in tools)
            Material(
              color: AshaColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push(tool.route),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(tool.icon, color: AshaColors.primary),
                      const Spacer(),
                      Text(
                        tool.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        tool.subtitle,
                        style: const TextStyle(
                          fontSize: 12,
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
  const _Tool(this.icon, this.title, this.subtitle, this.route);
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}
