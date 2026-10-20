import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/asha_bottom_nav.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const tools = <_Tool>[
      _Tool(
        Icons.medical_services_outlined,
        'Clinical triage',
        'Start with name, age and location',
        '/triage',
      ),
      _Tool(
        Icons.translate,
        'Interpreter',
        'They speak / I ask',
        '/triage/language',
      ),
      _Tool(Icons.checklist_rtl, 'Due list', 'Visits due today', '/due-list'),
      _Tool(Icons.calendar_month, 'Calendar', 'Visits by day', '/calendar'),
      _Tool(
        Icons.pie_chart_outline,
        'Coverage',
        'Programme reach',
        '/coverage',
      ),
      _Tool(Icons.people_alt_outlined, 'Households', 'Registry', '/households'),
      _Tool(
        Icons.medical_information_outlined,
        'Clinical programs',
        'ANC, immunisation, NCD, TB',
        '/programs',
      ),
      _Tool(
        Icons.calculate_outlined,
        'Calculators',
        'EDD, BMI, breath count',
        '/calculators',
      ),
    ];
    return Scaffold(
      key: const Key('tools_screen'),
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        title: const Text('Tools'),
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
