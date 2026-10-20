import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/app/theme/app_theme.dart';
import 'package:asha_platform/features/home/presentation/dashboard_screen.dart';

void main() {
  testWidgets('dashboard exposes the reference field-work hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.light, home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard_screen')), findsOneWidget);
    expect(find.text('Sunita Sharma'), findsOneWidget);
    expect(find.text('Offline mode'), findsOneWidget);
    expect(find.text('Continue today\'s work'), findsOneWidget);
    expect(find.byKey(const Key('home_continue_work_card')), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.byKey(const Key('home_triage_button')), findsOneWidget);
    expect(find.byKey(const Key('asha_bottom_nav')), findsOneWidget);
  });
}
