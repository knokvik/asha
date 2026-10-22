import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/app/theme/app_theme.dart';
import 'package:asha_platform/features/home/presentation/profile_screen.dart';

void main() {
  testWidgets('profile screen renders modernized UI cards, badges, and icons', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Header and Title
    expect(find.text('Profile'), findsOneWidget);

    // Verify Modernized Performance Strip
    expect(find.text('This Month'), findsOneWidget);
    expect(find.text('Visits'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    // Verify Modernized Icons
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
    expect(find.byIcon(Icons.analytics_rounded), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
    expect(find.byIcon(Icons.medical_services_rounded), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    expect(find.byIcon(Icons.medication_rounded), findsOneWidget);
    expect(find.byIcon(Icons.map_rounded), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byIcon(Icons.logout_rounded),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.byIcon(Icons.campaign_rounded), findsOneWidget);
    expect(find.byIcon(Icons.support_agent_rounded), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
  });
}
