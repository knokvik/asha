import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/l10n/app_localizations.dart';
import 'package:asha_platform/features/household/data/household_dao.dart';
import 'package:asha_platform/features/household/data/household_repository.dart';
import 'package:asha_platform/features/household/data/member_dao.dart';
import 'package:asha_platform/features/household/data/member_search_repository.dart';
import 'package:asha_platform/features/household/presentation/beneficiary_search_screen.dart';
import 'package:asha_platform/shared/providers/core_providers.dart';

void main() {
  late AppDatabase db;
  late HouseholdRepository householdRepo;
  late MemberSearchRepository searchRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    householdRepo = HouseholdRepository(
      householdDao: HouseholdDao(db),
      memberDao: MemberDao(db),
    );
    searchRepo = MemberSearchRepository(db);

    // Seed test beneficiaries across villages and hamlets
    final h1 = await householdRepo.createHousehold(
      village: 'Shivpur',
      hamlet: 'Purva',
      headName: 'Rameshwar Yadav',
    );
    await householdRepo.addMember(
      householdId: h1.id,
      name: 'Sunita Devi',
      sex: 'F',
      relationshipToHead: 'Spouse',
      phone: '9876543210',
      abhaId: '14-1111-2222-3333',
    );
    await householdRepo.addMember(
      householdId: h1.id,
      name: 'Pooja Yadav',
      sex: 'F',
      relationshipToHead: 'Daughter',
      phone: '9876543211',
    );

    final h2 = await householdRepo.createHousehold(
      village: 'Rampur',
      hamlet: 'Dakshin',
      headName: 'Vikram Singh',
    );
    await householdRepo.addMember(
      householdId: h2.id,
      name: 'Sunita Kumari',
      sex: 'F',
      relationshipToHead: 'Spouse',
      phone: '9811112222',
    );
    await householdRepo.addMember(
      householdId: h2.id,
      name: 'Amit Singh',
      sex: 'M',
      relationshipToHead: 'Son',
      phone: '9811113333',
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('MemberSearchRepository (Requirement 4.7)', () {
    test('returns empty list for empty or whitespace query', () async {
      expect(await searchRepo.search(''), isEmpty);
      expect(await searchRepo.search('   '), isEmpty);
    });

    test('finds beneficiary by partial prefix name', () async {
      final results = await searchRepo.search('Sun');
      expect(results.length, equals(2));
      final names = results.map((r) => r.member.name).toList();
      expect(names, containsAll(['Sunita Devi', 'Sunita Kumari']));
    });

    test('finds beneficiary case-insensitively', () async {
      final results = await searchRepo.search('pooja');
      expect(results.length, equals(1));
      expect(results.first.member.name, equals('Pooja Yadav'));
      expect(results.first.village, equals('Shivpur'));
      expect(results.first.hamlet, equals('Purva'));
    });

    test('finds beneficiary via phonetic soundex match (Puja matches Pooja)', () async {
      // Searching "Puja" matches "Pooja Yadav" via soundex P200
      final results = await searchRepo.search('Puja');
      expect(results.any((r) => r.member.name == 'Pooja Yadav'), isTrue);
    });

    test('finds beneficiary by ABHA ID prefix or full number', () async {
      final results = await searchRepo.search('14-1111');
      expect(results.length, equals(1));
      expect(results.first.member.name, equals('Sunita Devi'));
      expect(results.first.member.abhaId, equals('14-1111-2222-3333'));
    });

    test('finds beneficiary by phone number partial digits', () async {
      final results = await searchRepo.search('9876543211');
      expect(results.length, equals(1));
      expect(results.first.member.name, equals('Pooja Yadav'));
    });

    test('restricts matches to ASHA area when village parameter is specified', () async {
      // Unscoped query returns Sunita Devi (Shivpur) and Sunita Kumari (Rampur)
      final allSunitas = await searchRepo.search('Sunita');
      expect(allSunitas.length, equals(2));

      // Area-scoped to Shivpur only returns Sunita Devi
      final shivpurOnly = await searchRepo.search('Sunita', village: 'Shivpur');
      expect(shivpurOnly.length, equals(1));
      expect(shivpurOnly.first.member.name, equals('Sunita Devi'));
      expect(shivpurOnly.first.village, equals('Shivpur'));

      // Area-scoped to Rampur only returns Sunita Kumari
      final rampurOnly = await searchRepo.search('Sunita', village: 'Rampur');
      expect(rampurOnly.length, equals(1));
      expect(rampurOnly.first.member.name, equals('Sunita Kumari'));
      expect(rampurOnly.first.village, equals('Rampur'));
    });
  });

  group('BeneficiarySearchScreen Widget Tests (Requirement 4.7)', () {
    testWidgets('renders search field and empty state guide prompt', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BeneficiarySearchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('beneficiary_search_text_field')), findsOneWidget);
      expect(find.text('Offline Beneficiary Search'), findsOneWidget);
      expect(find.text('By Name or Phonetic Variant'), findsOneWidget);
    });

    testWidgets('typing query displays matching beneficiary cards with details', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BeneficiarySearchScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byKey(const Key('beneficiary_search_text_field'));
      await tester.enterText(searchField, 'Sunita');
      await tester.pumpAndSettle();

      // Check results
      expect(find.text('Sunita Devi'), findsOneWidget);
      expect(find.text('Sunita Kumari'), findsOneWidget);
      expect(find.textContaining('Head: Rameshwar Yadav'), findsOneWidget);

      // Tap clear button
      final clearButton = find.byKey(const Key('search_clear_button'));
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Returns to empty prompt
      expect(find.text('Offline Beneficiary Search'), findsOneWidget);
      expect(find.text('Sunita Devi'), findsNothing);
    });
  });
}
