import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/app/app.dart';
import 'package:asha_platform/core/l10n/app_localizations.dart';
import 'package:asha_platform/core/l10n/language_provider.dart';
import 'package:asha_platform/core/l10n/language_selector_dialog.dart';
import 'package:asha_platform/core/packs/pack_manager.dart';
import 'package:asha_platform/shared/shell/shell_copy.dart';

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async => _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) _store[key] = value;
  }
}

void main() {
  group('Task 4.1: Multilingual Framework & 12 Regional Languages', () {
    test('All 12 required Indian regional languages are registered', () {
      final expectedCodes = [
        'en',
        'hi',
        'mr',
        'bn',
        'te',
        'ta',
        'kn',
        'ml',
        'or',
        'gu',
        'pa',
        'as',
      ];

      expect(supportedLanguages.length, 12);
      for (final code in expectedCodes) {
        expect(
          supportedLanguages.any((lang) => lang.code == code),
          isTrue,
          reason: 'Language $code must be in supportedLanguages',
        );
        expect(
          LanguageNotifier.isSupported(code),
          isTrue,
          reason: 'LanguageNotifier.isSupported must return true for $code',
        );
      }
    });

    test(
      'AppLocalizations supports all 12 locales and provides localized values',
      () async {
        for (final lang in supportedLanguages) {
          final loc = await AppLocalizations.delegate.load(Locale(lang.code));
          expect(
            loc.appTitle,
            isNotEmpty,
            reason: '${lang.code} appTitle should not be empty',
          );
          expect(
            loc.dueList,
            isNotEmpty,
            reason: '${lang.code} dueList should not be empty',
          );
          expect(
            loc.triageFlagRed,
            isNotEmpty,
            reason: '${lang.code} triageFlagRed should not be empty',
          );
          expect(
            loc.triageFlagYellow,
            isNotEmpty,
            reason: '${lang.code} triageFlagYellow should not be empty',
          );
          expect(
            loc.triageFlagGreen,
            isNotEmpty,
            reason: '${lang.code} triageFlagGreen should not be empty',
          );
          expect(
            loc.muac,
            isNotEmpty,
            reason: '${lang.code} muac should not be empty',
          );
          expect(
            loc.tapToListen,
            isNotEmpty,
            reason: '${lang.code} tapToListen should not be empty',
          );
          expect(
            loc.jaundice,
            isNotEmpty,
            reason: '${lang.code} jaundice should not be empty',
          );
        }
      },
    );

    test(
      'Shared page labels use the selected locale where catalog entries exist',
      () {
        expect(shellText('hi', 'drawerHome'), 'होम');
        expect(shellText('mr', 'drawerDue'), 'आजची कार्ये');
        expect(shellText('te', 'drawerSettings'), 'సెట్టింగ్‌లు');
        expect(shellText('fr', 'drawerHome'), 'Home');

        // Verify settings and new keys for Hindi
        expect(shellText('hi', 'appearance'), 'थीम और दिखावट');
        expect(shellText('hi', 'mapNav'), 'नक्शा और नेविगेशन');
        expect(shellText('hi', 'voicePacks'), 'आवाज़ दुभाषिया पैक');
        expect(shellText('hi', 'clinicalVoicePacks'), 'क्लिनिकल आवाज़ इनपुट पैक');
        expect(shellText('hi', 'mapBasemapStyle'), 'नक्शा आधार शैली');
        expect(shellText('hi', 'interpreterCorePack'), 'दुभाषिया मुख्य पैक');
        expect(shellText('hi', 'signOut'), 'लॉग आउट / आशा बदलें');

        // Verify shared area signals & peer sync for Marathi
        expect(shellText('mr', 'sharedAreaSignals'), 'सामायिक क्षेत्र संकेत');
        expect(shellText('mr', 'peerSyncTitle'), 'सहकारी क्षेत्र सिंक (पीअर)');
        expect(shellText('mr', 'directNearbyExchange'), 'जवळपास थेट देवाणघेवाण');
        expect(shellText('mr', 'myArea'), 'माझा परिसर');
        expect(shellText('mr', 'revenue'), 'मानधन (उत्पन्न)');

        // Verify clinical programs & learning for Bengali & Telugu
        expect(shellText('bn', 'clinicalPrograms'), 'ক্লিনিকাল প্রোগ্রাম');
        expect(shellText('te', 'clinicalPrograms'), 'క్లినికల్ ప్రోగ్రామ్‌లు');
        expect(shellText('bn', 'microLearningTitle'), 'আশা মাইক্রো-লার্নিং ও সহায়িকা');
        expect(shellText('te', 'microLearningTitle'), 'ఆశా మైక్రో-లెర్నింగ్ & జాబ్ ఎయిడ్స్');
      },
    );

    test('LanguageNotifier switches locale and persists to storage', () async {
      final fakeStorage = FakeSecureStorage();
      final container = ProviderContainer(
        overrides: [
          languageProvider.overrideWith(
            () => LanguageNotifier(storage: fakeStorage),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(languageProvider), const Locale('en'));

      await container.read(languageProvider.notifier).setLanguageCode('hi');
      expect(container.read(languageProvider), const Locale('hi'));
      expect(await fakeStorage.read(key: LanguageNotifier.storageKey), 'hi');

      await container.read(languageProvider.notifier).setLanguageCode('mr');
      expect(container.read(languageProvider), const Locale('mr'));
      expect(await fakeStorage.read(key: LanguageNotifier.storageKey), 'mr');

      // Unsupported language code should be ignored
      await container.read(languageProvider.notifier).setLanguageCode('fr');
      expect(container.read(languageProvider), const Locale('mr'));
    });

    testWidgets(
      'Runtime language switch updates MaterialApp without data loss',
      (tester) async {
        final fakeStorage = FakeSecureStorage();
        final container = ProviderContainer(
          overrides: [
            languageProvider.overrideWith(
              () => LanguageNotifier(storage: fakeStorage),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const AshaApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Initially in English
        expect(find.text('Security Setup'), findsOneWidget);

        // Switch to Hindi at runtime
        await container.read(languageProvider.notifier).setLanguageCode('hi');
        await tester.pumpAndSettle();

        // UI should now show Hindi text
        expect(find.text('सुरक्षा सेटअप'), findsOneWidget);
        expect(find.text('पिन बनाएं (4-8 अंक)'), findsOneWidget);

        // Switch to Marathi at runtime
        await container.read(languageProvider.notifier).setLanguageCode('mr');
        await tester.pumpAndSettle();

        // UI should now show Marathi text
        expect(find.text('सुरक्षा सेटअप'), findsOneWidget);
        expect(find.text('पिन तयार करा (4-8 अंक)'), findsOneWidget);

        // Switch back to English
        await container.read(languageProvider.notifier).setLanguageCode('en');
        await tester.pumpAndSettle();

        expect(find.text('Security Setup'), findsOneWidget);
      },
    );

    testWidgets(
      'LanguageSelectorDialog displays all 12 options and updates language on selection',
      (tester) async {
        final fakeStorage = FakeSecureStorage();
        final container = ProviderContainer(
          overrides: [
            languageProvider.overrideWith(
              () => LanguageNotifier(storage: fakeStorage),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => const LanguageSelectorDialog(
                        availableLanguages: supportedLanguages,
                      ),
                    ),
                    child: const Text('Open Picker'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Open dialog
        await tester.tap(find.text('Open Picker'));
        await tester.pumpAndSettle();

        // The dialog list should be present and visible
        expect(find.byType(LanguageSelectorDialog), findsOneWidget);
        expect(find.byKey(const Key('lang_option_en')), findsOneWidget);
        expect(find.byKey(const Key('lang_option_hi')), findsOneWidget);

        // Tap Hindi option
        await tester.tap(find.byKey(const Key('lang_option_hi')));
        await tester.pumpAndSettle();

        // Dialog closed and state is Hindi
        expect(find.byType(LanguageSelectorDialog), findsNothing);
        expect(container.read(languageProvider), const Locale('hi'));
        expect(await fakeStorage.read(key: LanguageNotifier.storageKey), 'hi');
      },
    );

    testWidgets(
      'LanguageSelectorDialog hides language packs that are not installed',
      (tester) async {
        final storage = FakeSecureStorage();
        final container = ProviderContainer(
          overrides: [
            offlinePackProvider.overrideWith(
              () => OfflinePackNotifier(storage: storage),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const LanguageSelectorDialog(),
                  ),
                  child: const Text('Open Picker'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open Picker'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('lang_option_en')), findsOneWidget);
        expect(find.byKey(const Key('lang_option_hi')), findsNothing);
      },
    );
  });
}
