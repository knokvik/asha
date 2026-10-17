import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/features/household/data/household_dao.dart';
import 'package:asha_platform/features/household/data/household_repository.dart';
import 'package:asha_platform/features/household/data/member_dao.dart';

void main() {
  late AppDatabase db;
  late HouseholdDao householdDao;
  late MemberDao memberDao;
  late SyncEngine syncEngine;
  late HouseholdRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    householdDao = HouseholdDao(db);
    memberDao = MemberDao(db);
    syncEngine = SyncEngine(db);
    repository = HouseholdRepository(
      householdDao: householdDao,
      memberDao: memberDao,
      syncEngine: syncEngine,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('HouseholdRepository - Offline Creation & UUID v4', () {
    test('creates household offline with client-generated UUID v4', () async {
      final household = await repository.createHousehold(
        village: 'Shivpur',
        hamlet: 'Purva',
        headName: 'Rameshwar Yadav',
        socialCategory: 'OBC',
        isBpl: true,
        contactPhone: '9876543210',
        latitude: '25.3176',
        longitude: '82.9739',
        landmarkNotes: 'Near primary school handpump',
        createdBy: 'asha_worker_1',
      );

      // Verify UUID v4 format: 8-4-4-4-12 hex characters
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(household.id), isTrue);

      // Verify persisted state in Drift database
      final fetched = await householdDao.getById(household.id);
      expect(fetched, isNotNull);
      expect(fetched!.village, equals('Shivpur'));
      expect(fetched.headName, equals('Rameshwar Yadav'));
      expect(fetched.memberCount, equals(0));
      expect(fetched.syncStatus, equals('pending'));
      expect(fetched.serverVersion, equals(1));

      // Verify sync metadata: dirty_flag = 1, sync_version = 1
      final metadata = repository.getSyncMetadata(household.id);
      expect(metadata, isNotNull);
      expect(metadata!.targetTable, equals('households'));
      expect(metadata.dirtyFlag, equals(1));
      expect(metadata.syncVersion, equals(1));

      // Verify enqueued into SyncQueue table
      final queued = await db.select(db.syncQueue).get();
      expect(queued.length, equals(1));
      expect(queued.first.targetTable, equals('households'));
      expect(queued.first.recordId, equals(household.id));
      expect(queued.first.priority, equals(SyncPriority.metadata.value));
    });

    test('adds member offline with UUID v4 and updates household member count', () async {
      final household = await repository.createHousehold(
        village: 'Shivpur',
        headName: 'Rameshwar Yadav',
      );

      final member1 = await repository.addMember(
        householdId: household.id,
        name: 'Sunita Yadav',
        sex: 'F',
        relationshipToHead: 'Spouse',
        phone: '9876543211',
      );

      final member2 = await repository.addMember(
        householdId: household.id,
        name: 'Amit Yadav',
        sex: 'M',
        relationshipToHead: 'Son',
        dobApprox: 1609459200000, // 2021-01-01
      );

      // Verify UUID v4
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(member1.id), isTrue);
      expect(uuidRegex.hasMatch(member2.id), isTrue);
      expect(member1.id, isNot(equals(member2.id)));

      // Verify member records in Drift
      final members = await repository.listMembers(household.id);
      expect(members.length, equals(2));
      expect(members[0].name, equals('Sunita Yadav'));
      expect(members[1].name, equals('Amit Yadav'));

      // Verify member count updated in household
      final updatedHousehold = await repository.getHousehold(household.id);
      expect(updatedHousehold!.memberCount, equals(2));

      // Verify sync metadata for members
      final meta1 = repository.getSyncMetadata(member1.id);
      final meta2 = repository.getSyncMetadata(member2.id);
      expect(meta1!.dirtyFlag, equals(1));
      expect(meta1.syncVersion, equals(1));
      expect(meta2!.dirtyFlag, equals(1));
      expect(meta2.syncVersion, equals(1));

      // Verify sync queue entries (1 household + 2 members = 3 entries)
      final queueItems = await db.select(db.syncQueue).get();
      expect(queueItems.length, equals(3));
    });
  });

  group('HouseholdRepository - Updates & Composite Query', () {
    test('updates household details and sync metadata version', () async {
      final household = await repository.createHousehold(
        village: 'Shivpur',
        headName: 'Kailash Nath',
      );

      final updateSuccess = await repository.updateHousehold(
        HouseholdsCompanion(
          id: Value(household.id),
          contactPhone: const Value('9998887776'),
          village: Value(household.village),
          headName: Value(household.headName),
          createdAt: Value(household.createdAt),
          updatedAt: Value(household.updatedAt),
          createdBy: Value(household.createdBy),
          serverVersion: const Value(1),
        ),
      );
      expect(updateSuccess, isTrue);

      final updated = await repository.getHousehold(household.id);
      expect(updated!.contactPhone, equals('9998887776'));
      expect(updated.syncStatus, equals('pending'));

      final metadata = repository.getSyncMetadata(household.id);
      expect(metadata!.dirtyFlag, equals(1));
      expect(metadata.syncVersion, equals(2));
    });

    test('updates member details and sync metadata version', () async {
      final household = await repository.createHousehold(
        village: 'Shivpur',
        headName: 'Kailash Nath',
      );
      final member = await repository.addMember(
        householdId: household.id,
        name: 'Gita Devi',
        sex: 'F',
      );

      final updateSuccess = await repository.updateMember(
        MembersCompanion(
          id: Value(member.id),
          householdId: Value(household.id),
          name: Value(member.name),
          sex: Value(member.sex),
          phone: const Value('9123456780'),
          createdAt: Value(member.createdAt),
          updatedAt: Value(member.updatedAt),
          createdBy: Value(member.createdBy),
          serverVersion: const Value(1),
        ),
      );
      expect(updateSuccess, isTrue);

      final updated = await repository.getMember(member.id);
      expect(updated!.phone, equals('9123456780'));
      expect(updated.syncStatus, equals('pending'));

      final metadata = repository.getSyncMetadata(member.id);
      expect(metadata!.dirtyFlag, equals(1));
      expect(metadata.syncVersion, equals(2));
    });

    test('getHouseholdWithMembers returns composite model', () async {
      final household = await repository.createHousehold(
        village: 'Shivpur',
        headName: 'Anil Kumar',
      );

      await repository.addMember(
        householdId: household.id,
        name: 'Anil Kumar',
        sex: 'M',
        relationshipToHead: 'Head',
      );
      await repository.addMember(
        householdId: household.id,
        name: 'Pooja Kumar',
        sex: 'F',
        relationshipToHead: 'Spouse',
      );

      final composite = await repository.getHouseholdWithMembers(household.id);
      expect(composite, isNotNull);
      expect(composite!.household.id, equals(household.id));
      expect(composite.members.length, equals(2));
      expect(composite.members.map((m) => m.name), containsAll(['Anil Kumar', 'Pooja Kumar']));
    });

    test('getHouseholdWithMembers returns null for non-existent household', () async {
      final composite = await repository.getHouseholdWithMembers('non-existent-uuid');
      expect(composite, isNull);
    });
  });

  group('HouseholdDao & MemberDao Direct Tests', () {
    test('HouseholdDao filters by village and orders by createdAt desc', () async {
      await repository.createHousehold(village: 'VillageA', headName: 'Person 1');
      await repository.createHousehold(village: 'VillageB', headName: 'Person 2');
      await repository.createHousehold(village: 'VillageA', headName: 'Person 3');

      final villageAHouseholds = await householdDao.getAll(village: 'VillageA');
      expect(villageAHouseholds.length, equals(2));

      final allHouseholds = await householdDao.getAll();
      expect(allHouseholds.length, equals(3));
    });

    test('MemberDao searchByName finds partial matches', () async {
      final household = await repository.createHousehold(
        village: 'Shivpur',
        headName: 'Test Head',
      );
      await repository.addMember(
        householdId: household.id,
        name: 'Priya Sharma',
        sex: 'F',
      );
      await repository.addMember(
        householdId: household.id,
        name: 'Rahul Sharma',
        sex: 'M',
      );
      await repository.addMember(
        householdId: household.id,
        name: 'Anita Verma',
        sex: 'F',
      );

      final results = await memberDao.searchByName('Sharma');
      expect(results.length, equals(2));
      expect(results.map((m) => m.name), containsAll(['Priya Sharma', 'Rahul Sharma']));
    });

    test('MemberDao updateLifecycleStatus updates lifecycle and marks pending', () async {
      final household = await repository.createHousehold(
        village: 'Shivpur',
        headName: 'Test Head',
      );
      final member = await repository.addMember(
        householdId: household.id,
        name: 'Old Resident',
        sex: 'M',
      );

      await memberDao.updateLifecycleStatus(member.id, 'migrated');

      final updated = await memberDao.getById(member.id);
      expect(updated!.lifecycleStatus, equals('migrated'));
      expect(updated.syncStatus, equals('pending'));
    });

    test('HouseholdDao and MemberDao delete cascades or removes rows', () async {
      final household = await repository.createHousehold(
        village: 'Shivpur',
        headName: 'Test Head',
      );
      final member = await repository.addMember(
        householdId: household.id,
        name: 'Member 1',
        sex: 'F',
      );

      await memberDao.deleteMember(member.id);
      final fetchedMember = await memberDao.getById(member.id);
      expect(fetchedMember, isNull);

      await householdDao.deleteHousehold(household.id);
      final fetchedHousehold = await householdDao.getById(household.id);
      expect(fetchedHousehold, isNull);
    });
  });
}
