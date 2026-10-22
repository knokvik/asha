import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../core/l10n/language_provider.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// Root application widget.
///
/// Wraps [MaterialApp.router] with go_router navigation, runtime language switching
/// via [languageProvider], and the 12 supported Indian regional locales (Requirement 3.1).
class AshaApp extends ConsumerWidget {
  const AshaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(languageProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appTitle ?? 'Asha',
      theme: AppTheme.light,
      // Keep the first release intentionally simple and predictable. The
      // dark theme remains available for the future low-power mode, but it is
      // not selectable in the current app shell.
      themeMode: ThemeMode.light,
      routerConfig: ref.watch(routerProvider),
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }
}
