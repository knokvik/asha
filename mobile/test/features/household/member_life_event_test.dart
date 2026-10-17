import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/features/household/data/household_dao.dart';
import 'package:asha_platform/features/household/data/member_dao.dart';
import 'package:asha_platform/features/household/data/member_repository.dart';

void main() {
  late AppDatabase db;
  late MemberDao memberDao;
  late HouseholdDao householdDao;
  late MemberRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    memberDao = MemberDao(db);
    householdDao = HouseholdDao(db);
    repository = MemberRepository(
      memberDao: memberDao,
      householdDao: householdDao,
      db: db,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedHouseholdAndMember({
    required String householdId,
    required String memberId,
    String village = 'Shivpur',
    String headName = 'Rameshwar',
    String memberName = 'Sunita',
  }) async {
    await db.into(db.households).insert(
          HouseholdsCompanion.insert(
            id: householdId,
            village: village,
            headName: headName,
            memberCount: const Value(1),
            createdAt: 1000,
            updatedAt: 1000,
            createdBy: 'asha-1',
          ),
        );

    await db.into(db.members).insert(
          MembersCompanion.insert(
            id: memberId,
            householdId: householdId,
            name: memberName,
            sex: 'F',
            lifecycleStatus: const Value('active'),
            createdAt: 1000,
            updatedAt: 1000,
            createdBy: 'asha-1',
          ),
        );
  }

  Future<void> seedVisitSchedule({
    required String id,
    required String memberId,
    required String status,
    String visitType = 'ANC Visit 1',
    int dueDate = 5000,
  }) async {
    await db.into(db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: id,
            memberId: memberId,
            programCode: 'anc',
            visitType: visitType,
            dueDate: dueDate,
            status: Value(status),
            createdAt: 1000,
          ),
        );
  }

  group('MemberRepository - Life Event Recording & Task Suppression (Requirement 4.5)', () {
    test('death event sets lifecycle_status to deceased and cancels open visit schedules', () async {
      const hhId = 'hh-death-1';
      const memId = 'mem-death-1';

      await seedHouseholdAndMember(householdId: hhId, memberId: memId);

      // Open schedules
      await seedVisitSchedule(id: 'task-1', memberId: memId, status: 'pending');
      await seedVisitSchedule(id: 'task-2', memberId: memId, status: 'overdue');
      // Completed schedule (must NOT be cancelled)
      await seedVisitSchedule(id: 'task-3', memberId: memId, status: 'completed');

      final result = await repository.recordLifeEvent(
        memberId: memId,
        eventType: LifeEventType.death,
        timestamp: 2000,
        reason: 'Natural causes',
      );

      expect(result.newLifecycleStatus, 'deceased');
      expect(result.cancelledTasksCount, 2);

      // Verify member record
      final member = await memberDao.getById(memId);
      expect(member!.lifecycleStatus, 'deceased');
      expect(member.updatedAt, 2000);

      // Verify visit schedules: pending/overdue cancelled, completed preserved
      final task1 = await (db.select(db.visitSchedules)..where((t) => t.id.equals('task-1'))).getSingle();
      expect(task1.status, 'cancelled');
      expect(task1.skipReason, 'Natural causes');

      final task2 = await (db.select(db.visitSchedules)..where((t) => t.id.equals('task-2'))).getSingle();
      expect(task2.status, 'cancelled');

      final task3 = await (db.select(db.visitSchedules)..where((t) => t.id.equals('task-3'))).getSingle();
      expect(task3.status, 'completed');

      // Household active count updated to 0
      final hh = await householdDao.getById(hhId);
      expect(hh!.memberCount, 0);
    });

    test('migration event sets lifecycle_status to migrated and suppresses open tasks', () async {
      const hhId = 'hh-mig-1';
      const memId = 'mem-mig-1';

      await seedHouseholdAndMember(householdId: hhId, memberId: memId);
      await seedVisitSchedule(id: 'task-mig-1', memberId: memId, status: 'pending');

      final result = await repository.recordLifeEvent(
        memberId: memId,
        eventType: LifeEventType.migration,
        timestamp: 3000,
      );

      expect(result.newLifecycleStatus, 'migrated');
      expect(result.cancelledTasksCount, 1);

      final member = await memberDao.getById(memId);
      expect(member!.lifecycleStatus, 'migrated');

      final task = await (db.select(db.visitSchedules)..where((t) => t.id.equals('task-mig-1'))).getSingle();
      expect(task.status, 'cancelled');
      expect(task.skipReason, 'Migrated out');

      final hh = await householdDao.getById(hhId);
      expect(hh!.memberCount, 0);
    });

    test('marriage event moving out of area sets married_out and suppresses open tasks', () async {
      const hhId = 'hh-marr-1';
      const memId = 'mem-marr-1';

      await seedHouseholdAndMember(householdId: hhId, memberId: memId);
      await seedVisitSchedule(id: 'task-marr-1', memberId: memId, status: 'due');

      final result = await repository.recordLifeEvent(
        memberId: memId,
        eventType: LifeEventType.marriage,
        timestamp: 4000,
        isMovingOut: true,
      );

      expect(result.newLifecycleStatus, 'married_out');
      expect(result.cancelledTasksCount, 1);

      final member = await memberDao.getById(memId);
      expect(member!.lifecycleStatus, 'married_out');

      final task = await (db.select(db.visitSchedules)..where((t) => t.id.equals('task-marr-1'))).getSingle();
      expect(task.status, 'cancelled');
      expect(task.skipReason, contains('Married out'));
    });

    test('marriage within catchment area transfers member without cancelling tasks', () async {
      const hhOld = 'hh-old-1';
      const hhNew = 'hh-new-1';
      const memId = 'mem-marr-local';

      await seedHouseholdAndMember(householdId: hhOld, memberId: memId);
      // Seed target household
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: hhNew,
              village: 'Shivpur',
              headName: 'Sasural Head',
              memberCount: const Value(2),
              createdAt: 1000,
              updatedAt: 1000,
              createdBy: 'asha-1',
            ),
          );

      await seedVisitSchedule(id: 'task-local-1', memberId: memId, status: 'pending');

      final result = await repository.recordLifeEvent(
        memberId: memId,
        eventType: LifeEventType.marriage,
        timestamp: 5000,
        isMovingOut: false,
        targetHouseholdId: hhNew,
      );

      expect(result.newLifecycleStatus, 'active');
      expect(result.cancelledTasksCount, 0);

      // Member should now belong to hhNew
      final member = await memberDao.getById(memId);
      expect(member!.householdId, hhNew);
      expect(member.lifecycleStatus, 'active');

      // Schedule remains pending
      final task = await (db.select(db.visitSchedules)..where((t) => t.id.equals('task-local-1'))).getSingle();
      expect(task.status, 'pending');

      // Household counts updated
      final oldHh = await householdDao.getById(hhOld);
      expect(oldHh!.memberCount, 0);
      final newHh = await householdDao.getById(hhNew);
      expect(newHh!.memberCount, 1);
    });

    test('householdTransfer within catchment area transfers member and preserves open tasks', () async {
      const hh1 = 'hh-xfer-1';
      const hh2 = 'hh-xfer-2';
      const memId = 'mem-xfer-1';

      await seedHouseholdAndMember(householdId: hh1, memberId: memId);
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: hh2,
              village: 'Shivpur',
              headName: 'New Family Head',
              memberCount: const Value(1),
              createdAt: 1000,
              updatedAt: 1000,
              createdBy: 'asha-1',
            ),
          );

      await seedVisitSchedule(id: 'task-xfer-1', memberId: memId, status: 'pending');

      final result = await repository.recordLifeEvent(
        memberId: memId,
        eventType: LifeEventType.householdTransfer,
        timestamp: 6000,
        targetHouseholdId: hh2,
        isMovingOut: false,
      );

      expect(result.newLifecycleStatus, 'active');
      expect(result.cancelledTasksCount, 0);

      final member = await memberDao.getById(memId);
      expect(member!.householdId, hh2);

      // Tasks still active
      final task = await (db.select(db.visitSchedules)..where((t) => t.id.equals('task-xfer-1'))).getSingle();
      expect(task.status, 'pending');
    });

    test('birth event creates newborn member and generates HBNC visit schedule milestones', () async {
      const hhId = 'hh-birth-1';
      const motherId = 'mother-1';

      await seedHouseholdAndMember(householdId: hhId, memberId: motherId, memberName: 'Kavita');

      final result = await repository.recordLifeEvent(
        memberId: motherId,
        eventType: LifeEventType.birth,
        timestamp: 1000000000,
        newbornName: 'Baby of Kavita',
        newbornSex: 'F',
      );

      expect(result.newLifecycleStatus, 'active');
      expect(result.cancelledTasksCount, 0);
      expect(result.generatedTaskIds.length, 7); // HBNC Days 1, 3, 7, 14, 21, 28, 42

      // Verify newborn member was created in DB
      final newborn = await memberDao.getById(result.memberId);
      expect(newborn, isNotNull);
      expect(newborn!.name, 'Baby of Kavita');
      expect(newborn.sex, 'F');
      expect(newborn.householdId, hhId);
      expect(newborn.relationshipToHead, 'Child');

      // Verify generated visit schedules in DB
      final schedules = await (db.select(db.visitSchedules)
            ..where((t) => t.memberId.equals(result.memberId))
            ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
          .get();

      expect(schedules.length, 7);
      expect(schedules[0].visitType, 'HBNC Day 1');
      expect(schedules[1].visitType, 'HBNC Day 3');
      expect(schedules[2].visitType, 'HBNC Day 7');
      expect(schedules[3].visitType, 'HBNC Day 14');
      expect(schedules[4].visitType, 'HBNC Day 21');
      expect(schedules[5].visitType, 'HBNC Day 28');
      expect(schedules[6].visitType, 'HBNC Day 42');

      // Household member count now 2 (mother + newborn)
      final hh = await householdDao.getById(hhId);
      expect(hh!.memberCount, 2);
    });
  });
}
