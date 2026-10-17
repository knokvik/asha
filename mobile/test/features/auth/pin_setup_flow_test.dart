import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:asha_platform/app/router.dart';
import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/l10n/app_localizations.dart';
import 'package:asha_platform/core/security/auth_service.dart';
import 'package:asha_platform/core/security/key_manager.dart';
import 'package:asha_platform/features/auth/presentation/pin_setup_screen.dart';
import 'package:asha_platform/features/due_list/presentation/due_list_screen.dart';
import 'package:asha_platform/shared/providers/core_providers.dart';

class MockLocalAuth extends Mock implements LocalAuthentication {}

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
  }) async =>
      _store[key];

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

  @override
  Future<void> delete({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store.remove(key);
}

void main() {
  late FakeSecureStorage storage;
  late MockLocalAuth mockAuth;
  late AuthService authServiceInstance;
  late AppDatabase db;

  setUp(() {
    storage = FakeSecureStorage();
    mockAuth = MockLocalAuth();
    authServiceInstance = AuthService(storage: storage, localAuth: mockAuth);
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget createTestApp(ProviderContainer container) {
    final router = container.read(routerProvider);
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  group('Task 3 Checkpoint: PIN Setup and App Integration', () {
    testWidgets(
        'Launch app -> presents PIN setup screen -> enter PIN -> creates DB -> reaches home screen',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(authServiceInstance),
          appDatabaseProvider.overrideWithValue(db),
          keyManagerProvider.overrideWithValue(KeyManager(secureStorage: storage)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // 1. Should present PIN setup screen initially
      expect(find.byType(PinSetupScreen), findsOneWidget);
      expect(find.text('Security Setup'), findsOneWidget);
      expect(find.byKey(const Key('pin_input_field')), findsOneWidget);
      expect(find.byKey(const Key('confirm_pin_input_field')), findsOneWidget);
      expect(find.byKey(const Key('submit_pin_button')), findsOneWidget);

      // 2. Enter PIN and matching confirm PIN
      await tester.enterText(find.byKey(const Key('pin_input_field')), '1234');
      await tester.enterText(
          find.byKey(const Key('confirm_pin_input_field')), '1234');
      await tester.pumpAndSettle();

      // 3. Tap "Set PIN & Initialize"
      await tester.tap(find.byKey(const Key('submit_pin_button')));
      await tester.pumpAndSettle();

      // 4. Verify user reaches placeholder home screen (DueListScreen)
      expect(find.byType(DueListScreen), findsOneWidget);
      expect(find.text("Today's Tasks"), findsOneWidget);

      // 5. Verify database is alive and can execute queries
      final users = await db.select(db.users).get();
      expect(users, isEmpty);
    });

    testWidgets(
        'PIN mismatch displays validation error and stays on setup screen',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(authServiceInstance),
          appDatabaseProvider.overrideWithValue(db),
          keyManagerProvider.overrideWithValue(KeyManager(secureStorage: storage)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Enter mismatched PINs
      await tester.enterText(find.byKey(const Key('pin_input_field')), '1234');
      await tester.enterText(
          find.byKey(const Key('confirm_pin_input_field')), '5678');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_pin_button')));
      await tester.pumpAndSettle();

      expect(find.text('PINs do not match. Please re-enter.'), findsOneWidget);
      expect(find.byType(DueListScreen), findsNothing);
    });

    testWidgets(
        'When PIN already configured -> presents unlock screen -> enter PIN -> reaches home screen',
        (tester) async {
      // Pre-configure PIN
      await authServiceInstance.setupPin('4321');

      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(authServiceInstance),
          appDatabaseProvider.overrideWithValue(db),
          keyManagerProvider.overrideWithValue(KeyManager(secureStorage: storage)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestApp(container));
      await tester.pumpAndSettle();

      // Should show unlock mode
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byKey(const Key('confirm_pin_input_field')), findsNothing);
      expect(find.text('Unlock Database'), findsOneWidget);

      // Enter correct PIN
      await tester.enterText(find.byKey(const Key('pin_input_field')), '4321');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_pin_button')));
      await tester.pumpAndSettle();

      // Should reach home screen
      expect(find.byType(DueListScreen), findsOneWidget);
    });
  });
}
