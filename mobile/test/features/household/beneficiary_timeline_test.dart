import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/l10n/app_localizations.dart';
import 'package:asha_platform/features/household/data/timeline_repository.dart';
import 'package:asha_platform/features/household/presentation/beneficiary_timeline_screen.dart';
import 'package:asha_platform/shared/providers/core_providers.dart';

void main() {
  late AppDatabase db;
  late TimelineRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TimelineRepository(db);
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

  group('TimelineRepository (Requirement 4.4)', () {
    test('getTimeline returns events sorted in reverse-chronological order', () async {
      const memberId = 'member-001';
      const householdId = 'hh-001';

      // Insert household and member to satisfy foreign key constraints
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: householdId,
              village: 'Shivpur',
              headName: 'Rameshwar',
              createdAt: 1000,
              updatedAt: 1000,
              createdBy: 'asha-1',
            ),
          );
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: memberId,
              householdId: householdId,
              name: 'Radha Devi',
              sex: 'F',
              createdAt: 1000,
              updatedAt: 1000,
              createdBy: 'asha-1',
            ),
          );

      // Insert encounter at t=1000
      await db.into(db.clinicalEncounters).insert(
            ClinicalEncountersCompanion.insert(
              id: 'enc-1',
              memberId: memberId,
              ashaId: 'asha-1',
              programCode: 'anc',
              encounterType: 'ANC Visit 1',
              encounterDate: 1000,
              createdAt: 1000,
              updatedAt: 1000,
            ),
          );

      // Insert referral at t=3000
      await db.into(db.referralRecords).insert(
            ReferralRecordsCompanion.insert(
              id: 'ref-1',
              encounterId: 'enc-1',
              memberId: memberId,
              triageFlag: 'RED',
              createdAt: 3000,
              updatedAt: 3000,
            ),
          );

      // Insert incentive event at t=2000
      await db.into(db.incentiveEvents).insert(
            IncentiveEventsCompanion.insert(
              id: 'inc-1',
              memberId: memberId,
              activityCode: 'ANC_REG',
              catalogueVersionId: 'v1',
              eventDate: 2000,
              createdAt: 2000,
              idempotencyKey: 'idemp-1',
            ),
          );

      final timeline = await repository.getTimeline(memberId);

      expect(timeline.length, 3);
      // Sorted reverse-chronologically: ref-1 (3000), inc-1 (2000), enc-1 (1000)
      expect(timeline[0].id, 'ref-1');
      expect(timeline[0].type, TimelineEventType.referral);
      expect(timeline[0].title, contains('RED FLAG'));

      expect(timeline[1].id, 'inc-1');
      expect(timeline[1].type, TimelineEventType.incentive);
      expect(timeline[1].title, contains('ANC_REG'));

      expect(timeline[2].id, 'enc-1');
      expect(timeline[2].type, TimelineEventType.encounter);
      expect(timeline[2].title, contains('ANC Encounter'));
    });

    test('watchTimeline emits reactive updates when new events are added to Drift', () async {
      const memberId = 'member-002';
      const householdId = 'hh-002';

      // Insert household and member to satisfy foreign key constraints
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: householdId,
              village: 'Shivpur',
              headName: 'Sohan',
              createdAt: 1000,
              updatedAt: 1000,
              createdBy: 'asha-1',
            ),
          );
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: memberId,
              householdId: householdId,
              name: 'Meena',
              sex: 'F',
              createdAt: 1000,
              updatedAt: 1000,
              createdBy: 'asha-1',
            ),
          );

      final stream = repository.watchTimeline(memberId);
      final expectation = expectLater(
        stream,
        emitsInOrder([
          isEmpty, // initial empty emission
          hasLength(1), // after inserting encounter
          hasLength(2), // after inserting referral
        ]),
      );

      // Allow initial yield
      await pumpEventQueue();

      await db.into(db.clinicalEncounters).insert(
            ClinicalEncountersCompanion.insert(
              id: 'enc-2',
              memberId: memberId,
              ashaId: 'asha-1',
              programCode: 'hbnc',
              encounterType: 'HBNC Day 3',
              encounterDate: 1500,
              createdAt: 1500,
              updatedAt: 1500,
            ),
          );

      await pumpEventQueue();

      await db.into(db.referralRecords).insert(
            ReferralRecordsCompanion.insert(
              id: 'ref-2',
              encounterId: 'enc-2',
              memberId: memberId,
              triageFlag: 'YELLOW',
              createdAt: 2500,
              updatedAt: 2500,
            ),
          );

      await expectation;
    });
  });

  group('BeneficiaryTimelineScreen Widget (Requirement 4.4)', () {
    testWidgets('renders empty state when beneficiary has no clinical events', (tester) async {
      const memberId = 'mem-empty-1';
      const householdId = 'hh-empty-1';

      // Insert household & member
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: householdId,
              village: 'Shivpur',
              headName: 'Ramesh Kumar',
              createdAt: 1000,
              updatedAt: 1000,
              createdBy: 'asha_1',
            ),
          );

      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: memberId,
              householdId: householdId,
              name: 'Sunita Devi',
              sex: 'F',
              relationshipToHead: const Value('Wife'),
              lifecycleStatus: const Value('active'),
              createdAt: 1000,
              updatedAt: 1000,
              createdBy: 'asha_1',
            ),
          );

      await tester.pumpWidget(
        buildTestWidget(
          child: const BeneficiaryTimelineScreen(memberId: memberId),
        ),
      );
      await tester.pumpAndSettle();

      // Check header details
      expect(find.text('Sunita Devi'), findsOneWidget);
      expect(find.textContaining('F • Age unrecorded • Wife'), findsOneWidget);

      // Check empty state
      expect(find.text('No Clinical Events Recorded'), findsOneWidget);
      expect(find.byKey(const Key('empty_timeline_record_button')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    });

    testWidgets('renders timeline nodes and event cards with filter chips', (tester) async {
      const memberId = 'mem-events-1';
      const householdId = 'hh-events-1';

      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: householdId,
              village: 'Shivpur',
              headName: 'Ramesh Kumar',
              createdAt: 1000,
              updatedAt: 1000,
              createdBy: 'asha_1',
            ),
          );

      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: memberId,
              householdId: householdId,
              name: 'Pooja Verma',
              sex: 'F',
              phone: const Value('9876543210'),
              abhaId: const Value('14-1234-5678-9012'),
              relationshipToHead: const Value('Daughter-in-law'),
              lifecycleStatus: const Value('active'),
              createdAt: 1000,
              updatedAt: 1000,
              createdBy: 'asha_1',
            ),
          );

      // Encounter
      await db.into(db.clinicalEncounters).insert(
            ClinicalEncountersCompanion.insert(
              id: 'enc-widget-1',
              memberId: memberId,
              ashaId: 'asha-1',
              programCode: 'anc',
              encounterType: 'ANC Checkup',
              encounterDate: 1000000000,
              visitNotes: const Value('BP 120/80, normal fundal height'),
              status: const Value('completed'),
              createdAt: 1000000000,
              updatedAt: 1000000000,
            ),
          );

      // Referral
      await db.into(db.referralRecords).insert(
            ReferralRecordsCompanion.insert(
              id: 'ref-widget-1',
              encounterId: 'enc-widget-1',
              memberId: memberId,
              triageFlag: 'RED',
              referralNoteText: const Value('Severe pallor, Hb < 7g/dL'),
              createdAt: 1100000000,
              updatedAt: 1100000000,
            ),
          );

      // Incentive
      await db.into(db.incentiveEvents).insert(
            IncentiveEventsCompanion.insert(
              id: 'inc-widget-1',
              memberId: memberId,
              activityCode: 'ANC_FIRST_TRIMESTER',
              catalogueVersionId: 'v1',
              eventDate: 1200000000,
              status: const Value('eligible'),
              createdAt: 1200000000,
              idempotencyKey: 'idemp-widget-1',
            ),
          );

      await tester.pumpWidget(
        buildTestWidget(
          child: const BeneficiaryTimelineScreen(memberId: memberId),
        ),
      );
      await tester.pumpAndSettle();

      // Check header ABHA and phone
      expect(find.text('Pooja Verma'), findsOneWidget);
      expect(find.text('ABHA: 14-1234-5678-9012'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);

      // Check cards rendered
      expect(find.byKey(const Key('timeline_card_enc-widget-1')), findsOneWidget);
      expect(find.byKey(const Key('timeline_card_ref-widget-1')), findsOneWidget);
      expect(find.byKey(const Key('timeline_card_inc-widget-1')), findsOneWidget);

      // Check filter: Tap 'Referrals' chip
      await tester.tap(find.byKey(const Key('timeline_filter_referrals')));
      await tester.pumpAndSettle();

      // Only referral card should remain visible
      expect(find.byKey(const Key('timeline_card_ref-widget-1')), findsOneWidget);
      expect(find.byKey(const Key('timeline_card_enc-widget-1')), findsNothing);
      expect(find.byKey(const Key('timeline_card_inc-widget-1')), findsNothing);

      // Tap 'All Events' chip
      await tester.tap(find.byKey(const Key('timeline_filter_all')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('timeline_card_enc-widget-1')), findsOneWidget);
      expect(find.byKey(const Key('timeline_card_ref-widget-1')), findsOneWidget);
      expect(find.byKey(const Key('timeline_card_inc-widget-1')), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    });
  });
}
