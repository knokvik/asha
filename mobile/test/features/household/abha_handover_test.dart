import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/features/household/data/household_dao.dart';
import 'package:asha_platform/features/household/data/member_dao.dart';
import 'package:asha_platform/features/household/domain/abha_service.dart';
import 'package:asha_platform/features/household/domain/consent_service.dart';
import 'package:asha_platform/features/household/domain/handover_service.dart';

void main() {
  late AppDatabase db;
  late MemberDao memberDao;
  late HouseholdDao householdDao;
  late ConsentService consentService;
  late SyncEngine syncEngine;
  late AbhaService abhaService;
  late HandoverService handoverService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    memberDao = MemberDao(db);
    householdDao = HouseholdDao(db);
    syncEngine = SyncEngine(db);
    consentService = ConsentService(
      db: db,
      memberDao: memberDao,
      syncEngine: syncEngine,
    );
    abhaService = AbhaService(
      db: db,
      memberDao: memberDao,
      consentService: consentService,
      syncEngine: syncEngine,
    );
    handoverService = HandoverService(
      db: db,
      householdDao: householdDao,
      memberDao: memberDao,
      syncEngine: syncEngine,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedMember({
    required String householdId,
    required String memberId,
    String village = 'Shivpur',
    String memberName = 'Rekha Devi',
    String consentStatus = 'pending',
  }) async {
    await db.into(db.households).insert(
          HouseholdsCompanion.insert(
            id: householdId,
            village: village,
            headName: 'Head Person',
            memberCount: const Value(1),
            createdAt: 1000,
            updatedAt: 1000,
            createdBy: 'asha-original',
          ),
        );

    await db.into(db.members).insert(
          MembersCompanion.insert(
            id: memberId,
            householdId: householdId,
            name: memberName,
            sex: 'F',
            consentStatus: Value(consentStatus),
            createdAt: 1000,
            updatedAt: 1000,
            createdBy: 'asha-original',
          ),
        );
  }

  group('AbhaService - Offline Capture & Consent Enforcement (Requirements 4.6, 36.1)', () {
    test('validateAbhaFormat validates hyphenated, continuous, and ABHA addresses', () {
      // Valid formats
      expect(AbhaService.validateAbhaFormat('14-1234-5678-9012'), isTrue);
      expect(AbhaService.validateAbhaFormat('14123456789012'), isTrue);
      expect(AbhaService.validateAbhaFormat('rekha.devi@abdm'), isTrue);
      expect(AbhaService.validateAbhaFormat('sunita123@sbx'), isTrue);

      // Invalid formats
      expect(AbhaService.validateAbhaFormat('12345'), isFalse);
      expect(AbhaService.validateAbhaFormat('invalid-format'), isFalse);
      expect(AbhaService.validateAbhaFormat(''), isFalse);
      expect(AbhaService.validateAbhaFormat('14-1234-5678-901'), isFalse); // 13 digits
    });

    test('normalizeAbhaNumber standardizes continuous digits into canonical format', () {
      expect(
        AbhaService.normalizeAbhaNumber('14123456789012'),
        equals('14-1234-5678-9012'),
      );
      expect(
        AbhaService.normalizeAbhaNumber('rekha@abdm'),
        equals('rekha@abdm'),
      );
    });

    test('captureAbhaOffline throws StateError if beneficiary has not given consent', () async {
      const hhId = 'hh-abha-1';
      const memId = 'mem-abha-1';
      await seedMember(householdId: hhId, memberId: memId, consentStatus: 'pending');

      expect(
        () => abhaService.captureAbhaOffline(
          memberId: memId,
          rawAbhaId: '14-1234-5678-9012',
        ),
        throwsStateError,
      );
    });

    test('captureAbhaOffline stores formatted ABHA offline with abha_linked=false when consent is given', () async {
      const hhId = 'hh-abha-2';
      const memId = 'mem-abha-2';
      await seedMember(householdId: hhId, memberId: memId);

      // Grant consent first
      await consentService.grantConsent(
        memberId: memId,
        ashaId: 'asha-original',
      );

      final result = await abhaService.captureAbhaOffline(
        memberId: memId,
        rawAbhaId: '14123456789012', // unformatted
        timestamp: 5000,
      );

      expect(result.isLinked, isFalse);
      expect(result.abhaId, '14-1234-5678-9012');
      expect(result.consentArtifactId, isNotEmpty);

      // Verify stored on Member in DB
      final member = await memberDao.getById(memId);
      expect(member!.abhaId, '14-1234-5678-9012');

      // Verify enqueued to SyncEngine for ABDM verification
      final queueItems = await db.select(db.syncQueue).get();
      final linkItem = queueItems.firstWhere((i) => i.operation == 'link_abha');
      expect(linkItem.recordId, memId);

      // Confirm backend sync reconciliation
      await abhaService.confirmAbhaLinked(
        memberId: memId,
        verifiedAbhaId: '14-1234-5678-9012',
      );
      final verifiedMember = await memberDao.getById(memId);
      expect(verifiedMember!.syncStatus, 'synced');
    });
  });

  group('HandoverService - Area Transfer & Tamper-Evident Audit Trail (Requirement 4.8)', () {
    test('handoverHousehold transfers household and records audit log entry with chain hash', () async {
      const hhId = 'hh-handover-1';
      const memId = 'mem-handover-1';
      await seedMember(householdId: hhId, memberId: memId);

      // Seed an open task
      await db.into(db.visitSchedules).insert(
            VisitSchedulesCompanion.insert(
              id: 'task-handover-1',
              memberId: memId,
              programCode: 'anc',
              visitType: 'ANC Visit 2',
              dueDate: 7000,
              createdAt: 1000,
            ),
          );

      final record = await handoverService.handoverHousehold(
        householdId: hhId,
        transferringWorker: 'asha_village_A',
        receivingWorker: 'asha_village_B',
        reason: 'Boundary demarcation adjustment',
        timestamp: 8000,
      );

      expect(record.transferringWorker, 'asha_village_A');
      expect(record.receivingWorker, 'asha_village_B');
      expect(record.affectedTasksCount, 1);
      expect(record.chainHash.length, 64);

      // Verify household ownership updated in DB
      final household = await householdDao.getById(hhId);
      expect(household!.createdBy, 'asha_village_B');

      // Verify member ownership updated
      final member = await memberDao.getById(memId);
      expect(member!.createdBy, 'asha_village_B');

      // Verify audit log entry stored in DB
      final auditLogs = await db.select(db.auditLog).get();
      expect(auditLogs.length, 1);
      final log = auditLogs.first;
      expect(log.entityTable, 'households');
      expect(log.recordId, hhId);
      expect(log.oldValue, 'asha_village_A');
      expect(log.newValue, 'asha_village_B');
      expect(log.chainHash, record.chainHash);

      // Verify task still active
      final tasks = await memberDao.getActiveVisitSchedules(memId);
      expect(tasks.length, 1);
    });

    test('handoverBeneficiary transfers beneficiary and logs audit provenance', () async {
      const hhOld = 'hh-old-ind';
      const hhNew = 'hh-new-ind';
      const memId = 'mem-ind-1';

      await seedMember(householdId: hhOld, memberId: memId);

      // Seed receiving household
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: hhNew,
              village: 'Shivpur North',
              headName: 'New Head',
              memberCount: const Value(1),
              createdAt: 1000,
              updatedAt: 1000,
              createdBy: 'asha_village_B',
            ),
          );

      final record = await handoverService.handoverBeneficiary(
        memberId: memId,
        transferringWorker: 'asha_village_A',
        receivingWorker: 'asha_village_B',
        reason: 'Inter-hamlet marriage and relocation',
        targetHouseholdId: hhNew,
        timestamp: 9000,
      );

      expect(record.entityType, 'members');
      expect(record.recordId, memId);

      // Member now in new household
      final member = await memberDao.getById(memId);
      expect(member!.householdId, hhNew);

      // Audit log entry verified
      final auditLogs = await db.select(db.auditLog).get();
      final log = auditLogs.firstWhere((l) => l.recordId == memId);
      expect(log.entityTable, 'members');
      expect(log.oldValue, 'asha_village_A');
      expect(log.newValue, 'asha_village_B');
    });
  });
}
