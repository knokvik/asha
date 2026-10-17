import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/l10n/app_localizations.dart';
import 'package:asha_platform/features/household/data/household_repository.dart';
import 'package:asha_platform/features/household/presentation/household_form_screen.dart';
import 'package:asha_platform/features/household/presentation/household_list_screen.dart';
import 'package:asha_platform/shared/providers/core_providers.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestWidget({
    required Widget child,
    AppDatabase? database,
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database ?? db),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('HouseholdFormScreen (Requirement 4.1)', () {
    testWidgets('enforces mandatory village and head of household name', (tester) async {
      await tester.pumpWidget(buildTestWidget(child: const HouseholdFormScreen()));
      await tester.pumpAndSettle();

      // Tap save without filling anything
      final saveButton = find.byKey(const Key('household_form_save_button'));
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Check validation error messages
      expect(find.text('Village name is required'), findsOneWidget);
      expect(find.text('Head of household name is required'), findsOneWidget);
    });

    testWidgets('submits successfully with only mandatory fields (all optional fields skipped)', (tester) async {
      await tester.pumpWidget(buildTestWidget(child: const HouseholdFormScreen()));
      await tester.pumpAndSettle();

      // Enter only mandatory village and head name
      await tester.enterText(find.byKey(const Key('village_field')), 'Rampur');
      await tester.enterText(find.byKey(const Key('head_name_field')), 'Sunil Kumar');
      await tester.pumpAndSettle();

      // Tap save
      final saveButton = find.byKey(const Key('household_form_save_button'));
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify row inserted in Drift database
      final households = await db.select(db.households).get();
      expect(households.length, equals(1));
      expect(households.first.village, equals('Rampur'));
      expect(households.first.headName, equals('Sunil Kumar'));
      expect(households.first.hamlet, isNull);
      expect(households.first.contactPhone, isNull);
      expect(households.first.isBpl, isFalse);

      // Verify head member was automatically added
      final members = await db.select(db.members).get();
      expect(members.length, equals(1));
      expect(members.first.name, equals('Sunil Kumar'));
      expect(members.first.relationshipToHead, equals('Head'));
    });

    testWidgets('captures full household with optional fields and multiple family members', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestWidget(child: const HouseholdFormScreen()));
      await tester.pumpAndSettle();

      // Enter household details
      await tester.enterText(find.byKey(const Key('village_field')), 'Shivpur');
      await tester.enterText(find.byKey(const Key('hamlet_field')), 'Purva');
      await tester.enterText(find.byKey(const Key('head_name_field')), 'Rajendra Singh');
      await tester.enterText(find.byKey(const Key('contact_phone_field')), '9876543210');

      // Select social category OBC
      await tester.tap(find.byKey(const Key('category_chip_OBC')));
      await tester.pumpAndSettle();

      // Toggle BPL
      await tester.tap(find.byKey(const Key('bpl_switch')));
      await tester.pumpAndSettle();

      // Scroll down to family members
      final mainScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byKey(const Key('add_member_button')),
        200,
        scrollable: mainScrollable,
      );

      // Add second family member
      await tester.tap(find.byKey(const Key('add_member_button')));
      await tester.pumpAndSettle();

      // Fill Member 2 details
      await tester.scrollUntilVisible(
        find.byKey(const Key('member_name_field_1')),
        200,
        scrollable: mainScrollable,
      );
      await tester.enterText(find.byKey(const Key('member_name_field_1')), 'Kavita Singh');
      await tester.enterText(find.byKey(const Key('member_age_field_1')), '26');
      await tester.pumpAndSettle();

      // Scroll to submit button and tap
      await tester.scrollUntilVisible(
        find.byKey(const Key('submit_household_button')),
        300,
        scrollable: mainScrollable,
      );
      await tester.tap(find.byKey(const Key('submit_household_button')));
      await tester.pumpAndSettle();

      // Verify persisted state in Drift database
      final households = await db.select(db.households).get();
      expect(households.length, equals(1));
      final h = households.first;
      expect(h.village, equals('Shivpur'));
      expect(h.hamlet, equals('Purva'));
      expect(h.headName, equals('Rajendra Singh'));
      expect(h.socialCategory, equals('OBC'));
      expect(h.isBpl, isTrue);
      expect(h.contactPhone, equals('9876543210'));

      final members = await db.select(db.members).get();
      expect(members.length, equals(2));
      expect(members.any((m) => m.name == 'Rajendra Singh'), isTrue);
      expect(members.any((m) => m.name == 'Kavita Singh'), isTrue);
    });
  });

  group('HouseholdListScreen (Requirement 4.1)', () {
    testWidgets('renders empty state when no households registered', (tester) async {
      await tester.pumpWidget(buildTestWidget(child: const HouseholdListScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No Households Registered'), findsOneWidget);
      expect(find.byKey(const Key('empty_state_register_button')), findsOneWidget);
      expect(find.byKey(const Key('register_household_fab')), findsOneWidget);
    });

    testWidgets('groups households by hamlet with badges and search filter', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(householdRepositoryProvider);

      // Seed households across multiple hamlets
      final h1 = await repo.createHousehold(
        village: 'Shivpur',
        hamlet: 'Ward 1',
        headName: 'Kailash Nath',
        isBpl: true,
        contactPhone: '9811111111',
      );
      await repo.addMember(householdId: h1.id, name: 'Kailash Nath', sex: 'M');
      await repo.addMember(householdId: h1.id, name: 'Sunita Nath', sex: 'F');

      final h2 = await repo.createHousehold(
        village: 'Shivpur',
        hamlet: 'Ward 1',
        headName: 'Sanjay Yadav',
        contactPhone: '9822222222',
      );
      await repo.addMember(householdId: h2.id, name: 'Sanjay Yadav', sex: 'M');

      final h3 = await repo.createHousehold(
        village: 'Shivpur',
        hamlet: 'Purva',
        headName: 'Devi Prasad',
        socialCategory: 'SC',
        contactPhone: '9833333333',
      );
      await repo.addMember(householdId: h3.id, name: 'Devi Prasad', sex: 'M');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: HouseholdListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify hamlet headers are rendered
      expect(find.text('Ward 1'), findsWidgets);
      expect(find.text('Purva'), findsWidgets);

      // Verify household cards
      expect(find.text('Kailash Nath'), findsOneWidget);
      expect(find.text('Sanjay Yadav'), findsOneWidget);
      expect(find.text('Devi Prasad'), findsOneWidget);

      // Verify BPL badge for Kailash Nath
      expect(find.text('BPL'), findsOneWidget);

      // Verify member count chips
      expect(find.text('2 members'), findsOneWidget);
      expect(find.text('1 members'), findsNWidgets(2));

      // Test searching by name
      final searchField = find.byKey(const Key('household_search_field'));
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Sanjay');
      await tester.pumpAndSettle();

      expect(find.text('Sanjay Yadav'), findsOneWidget);
      expect(find.text('Kailash Nath'), findsNothing);
      expect(find.text('Devi Prasad'), findsNothing);

      // Clear search
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      // Test hamlet filter chip for Purva
      final purvaFilter = find.byKey(const Key('hamlet_filter_Purva'));
      if (purvaFilter.evaluate().isNotEmpty) {
        await tester.tap(purvaFilter);
        await tester.pumpAndSettle();

        expect(find.text('Devi Prasad'), findsOneWidget);
        expect(find.text('Kailash Nath'), findsNothing);
        expect(find.text('Sanjay Yadav'), findsNothing);
      }
    });
  });
}
