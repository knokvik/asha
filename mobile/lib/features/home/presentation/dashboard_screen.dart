import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/language_selector_dialog.dart';
import '../../../shared/widgets/app_drawer.dart';

/// Field home. Sidebar items open their own routes, so this page stays put.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const _pcmc = LatLng(18.6298, 73.7997);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('dashboard_screen'),
      backgroundColor: AshaColors.screenBg,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AshaColors.cardSurface,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: Image.asset(
          'assets/branding/asha_logo.jpg',
          height: 36,
          fit: BoxFit.contain,
          semanticLabel: 'asha',
        ),
        actions: [
          IconButton(
            key: const Key('home_search_button'),
            icon: const Icon(Icons.search),
            tooltip: 'Search beneficiaries',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            key: const Key('home_households_button'),
            icon: const Icon(Icons.people_outline),
            tooltip: 'Households',
            onPressed: () => context.push('/households'),
          ),
          IconButton(
            key: const Key('home_language_selector_button'),
            icon: const Icon(Icons.language),
            tooltip: 'Language',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const LanguageSelectorDialog(),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _MapWindow(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MainAction(
                  icon: Icons.medical_services_outlined,
                  title: 'Clinical triage',
                  subtitle: 'Assess and classify',
                  onTap: () => context.push('/triage/questions'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MainAction(
                  icon: Icons.translate,
                  title: 'Interpreter',
                  subtitle: 'They speak / I ask',
                  onTap: () => context.push('/triage/language'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'FIELD DESK',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: AshaColors.textMuted),
          ),
          const SizedBox(height: 8),
          _DeskTile(icon: Icons.checklist_rtl, title: 'Due list', subtitle: 'Overdue and upcoming visits', onTap: () => context.push('/due-list')),
          _DeskTile(icon: Icons.calendar_month, title: 'Calendar', subtitle: 'Visits by day', onTap: () => context.push('/calendar')),
          _DeskTile(icon: Icons.pie_chart_outline, title: 'Coverage', subtitle: 'Programme reach', onTap: () => context.push('/coverage')),
          _DeskTile(icon: Icons.people_alt_outlined, title: 'Household registry', subtitle: 'Census and ABHA', onTap: () => context.push('/households')),
          _DeskTile(icon: Icons.medical_information_outlined, title: 'Clinical programs', subtitle: 'ANC, immunisation, NCD, TB', onTap: () => context.push('/programs')),
          _DeskTile(icon: Icons.map_outlined, title: 'Visit route', subtitle: 'Hamlet map', onTap: () => context.push('/route-map')),
        ],
      ),
    );
  }
}

class _MapWindow extends StatelessWidget {
  const _MapWindow();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 168,
        child: FlutterMap(
          options: const MapOptions(
            initialCenter: DashboardScreen._pcmc,
            initialZoom: 12,
            interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.nhm.asha.asha_platform',
            ),
            const MarkerLayer(
              markers: [
                Marker(
                  point: DashboardScreen._pcmc,
                  width: 16,
                  height: 16,
                  child: Icon(Icons.location_on, color: AshaColors.primary, size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MainAction extends StatelessWidget {
  const _MainAction({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AshaColors.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeskTile extends StatelessWidget {
  const _DeskTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          leading: Icon(icon, color: AshaColors.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, color: AshaColors.textMuted),
          onTap: onTap,
        ),
      ),
    );
  }
}
