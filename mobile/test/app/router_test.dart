import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:asha_platform/app/router.dart';
import 'package:asha_platform/core/l10n/app_localizations.dart';

class _FakeUserRoleNotifier extends UserRoleNotifier {
  final String _role;
  _FakeUserRoleNotifier(this._role);

  @override
  String build() => _role;
}

void main() {
  Widget buildTestApp(GoRouter router) {
    return MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  group('Router and Navigation Guards (Requirement 2.3)', () {
    testWidgets('Router initializes with /auth as default location', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: buildTestApp(router),
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/auth');
    });

    testWidgets('Non-AF role is redirected away from /af to /home', (tester) async {
      final container = ProviderContainer(
        overrides: [
          userRoleProvider.overrideWith(() => _FakeUserRoleNotifier('asha')),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: buildTestApp(router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/af/supervision');
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/home');
    });

    testWidgets('AF role is permitted to access /af routes', (tester) async {
      final container = ProviderContainer(
        overrides: [
          userRoleProvider.overrideWith(() => _FakeUserRoleNotifier('af')),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: buildTestApp(router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/af/supervision');
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/af/supervision');
    });

    testWidgets('Admin role is permitted to access /af routes', (tester) async {
      final container = ProviderContainer(
        overrides: [
          userRoleProvider.overrideWith(() => _FakeUserRoleNotifier('admin')),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: buildTestApp(router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/af/metrics');
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/af/metrics');
    });

    testWidgets('Root / redirects to /home', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final router = container.read(routerProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: buildTestApp(router),
        ),
      );
      await tester.pumpAndSettle();

      router.go('/');
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/home');
    });
  });
}
