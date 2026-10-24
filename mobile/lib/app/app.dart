import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../core/l10n/language_provider.dart';
import '../shared/shell/shell_tab.dart';
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
    final router = ref.watch(routerProvider);

    return PopScope<void>(
      // Route popping is handled explicitly so Android back cannot exit while
      // a pushed detail/form page is still on the GoRouter stack.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (router.canPop()) {
          router.pop();
          return;
        }
        if (router.state.uri.path == '/home') {
          final shellTab = ref.read(shellTabProvider.notifier);
          if (ref.read(shellTabProvider) != 0) shellTab.select(0);
        }
      },
      child: MaterialApp.router(
        onGenerateTitle: (context) =>
            AppLocalizations.of(context)?.appTitle ?? 'Asha',
        theme: AppTheme.light,
        // Keep the first release intentionally simple and predictable. The
        // dark theme remains available for the future low-power mode, but it is
        // not selectable in the current app shell.
        themeMode: ThemeMode.light,
        routerConfig: router,
        locale: currentLocale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
