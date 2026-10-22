import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/l10n/language_selector_dialog.dart';
import '../../../shared/shell/shell_copy.dart';

/// Small, light-mode settings surface. Optional downloads are intentionally
/// managed on the dedicated Packs page rather than scattered across settings.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).languageCode;
    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Text(shellText(lang, 'settings')),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        children: [
          _SectionLabel(shellText(lang, 'appearance')),
          const Card(
            child: ListTile(
              leading: Icon(Icons.light_mode_outlined, color: Color(0xFF2D5F47)),
              title: Text('Light mode'),
              subtitle: Text('The app uses a clear light interface.'),
              trailing: Icon(Icons.check_circle, color: Color(0xFF16A34A)),
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel(shellText(lang, 'appLanguage')),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_rounded, color: Color(0xFF2563EB)),
              title: Text(shellText(lang, 'appLanguage')),
              subtitle: Text(shellText(lang, 'appLanguageDesc')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => const LanguageSelectorDialog(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Storage and offline use'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF7C3AED)),
              title: const Text('Offline packs'),
              subtitle: const Text('Language, map and interpreter downloads'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/packs'),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Privacy'),
          const Card(
            color: Color(0xFFF8F9FA),
            child: ListTile(
              leading: Icon(Icons.lock_outline_rounded, color: Color(0xFF6B7280)),
              title: Text('Private on this phone'),
              subtitle: Text('Patient records and installed packs stay in protected app storage.'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111815),
          ),
        ),
      );
}
