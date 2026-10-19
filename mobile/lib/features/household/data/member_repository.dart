import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../shared/providers/core_providers.dart';
import 'household_dao.dart';
import 'member_dao.dart';

/// Supported beneficiary life events.
/// Requirements: 4.5
enum LifeEventType {
  birth,
  death,
  migration,
  marriage,
  householdTransfer,
}

/// Result of recording a life event on a beneficiary.
class LifeEventResult {
  final String memberId;
  final LifeEventType eventType;
  final int timestamp;
  final String newLifecycleStatus;
  final int cancelledTasksCount;
  final List<String> generatedTaskIds;
  final String? oldHouseholdId;
  final String? newHouseholdId;
  final String? notes;

  const LifeEventResult({
    required this.memberId,
    required this.eventType,
    required this.timestamp,
    required this.newLifecycleStatus,
    this.cancelledTasksCount = 0,
    this.generatedTaskIds = const [],
    this.oldHouseholdId,
    this.newHouseholdId,
    this.notes,
  });
}

/// Repository coordinating member lifecycle transitions, task suppression,
/// and life event recording.
///
/// Requirements: 4.5
class MemberRepository {
  final MemberDao memberDao;
  final HouseholdDao householdDao;
  final SyncEngine? syncEngine;
  final AppDatabase db;
  static const _uuid = Uuid();

  MemberRepository({
    required this.memberDao,
    required this.householdDao,
    required this.db,
    this.syncEngine,
  });

  /// Records a life event on [memberId] with [timestamp], updating `lifecycle_status`,
  /// recomputing household membership, and suppressing open tasks where applicable.
  ///
  /// Supported events:
  /// - `death`: updates status to `deceased`, cancels all open visit schedules.
  /// - `migration`: updates status to `migrated`, cancels all open visit schedules.
  /// - `marriage`: if moving out, updates status to `married_out` and cancels open visit schedules;
  ///   if staying/transferring within area to [targetHouseholdId], updates household.
  /// - `householdTransfer`: updates member's household to [targetHouseholdId];
  ///   if [isMovingOut] is true (outside catchment), sets `migrated` and cancels open tasks.
  /// - `birth`: registers/activates newborn, updates household counts, and generates initial HBNC visit schedules.
  ///
  /// Requirements: 4.5
  Future<LifeEventResult> recordLifeEvent({
    required String memberId,
    required LifeEventType eventType,
    required int timestamp,
    String? reason,
    String? notes,
    String? targetHouseholdId,
    bool isMovingOut = true,
    String recordedBy = 'asha_worker_1',
    // Newborn registration fields for birth event:
    String? newbornName,
    String? newbornSex,
    String? newbornHouseholdId,
  }) async {
    final member = await memberDao.getById(memberId);
    if (member == null && eventType != LifeEventType.birth) {
      throw ArgumentError('Member not found with ID: $memberId');
    }

    switch (eventType) {
      case LifeEventType.death:
        return _recordDeath(
          member: member!,
          timestamp: timestamp,
          reason: reason,
          notes: notes,
        );

      case LifeEventType.migration:
        return _recordMigration(
          member: member!,
          timestamp: timestamp,
          reason: reason,
          notes: notes,
        );

      case LifeEventType.marriage:
        return _recordMarriage(
          member: member!,
          timestamp: timestamp,
          isMovingOut: isMovingOut,
          targetHouseholdId: targetHouseholdId,
          reason: reason,
          notes: notes,
        );

      case LifeEventType.householdTransfer:
        return _recordHouseholdTransfer(
          member: member!,
          timestamp: timestamp,
          targetHouseholdId: targetHouseholdId,
          isMovingOut: isMovingOut,
          reason: reason,
          notes: notes,
        );

      case LifeEventType.birth:
        return _recordBirth(
          existingMember: member,
          timestamp: timestamp,
          newbornName: newbornName,
          newbornSex: newbornSex,
          newbornHouseholdId: newbornHouseholdId,
          notes: notes,
          recordedBy: recordedBy,
        );
    }
  }

  // ── Event Handlers ─────────────────────────────────────────────────────────

  Future<LifeEventResult> _recordDeath({
    required Member member,
    required int timestamp,
    String? reason,
    String? notes,
  }) async {
    // 1. Update lifecycle status
    await memberDao.updateLifecycleStatus(member.id, 'deceased', timestamp: timestamp);

    // 2. Suppress future tasks (cancel open visit schedules)
    final cancelledCount = await memberDao.cancelOpenVisitSchedules(
      member.id,
      reason: reason ?? 'Deceased',
    );

    // 3. Update household active member count
    final activeCount = await memberDao.countActiveMembers(member.householdId);
    await householdDao.updateMemberCount(member.householdId, activeCount);

    // 4. Enqueue sync
    await _enqueueSyncUpdate(member.id, 'deceased', timestamp);

    return LifeEventResult(
      memberId: member.id,
      eventType: LifeEventType.death,
      timestamp: timestamp,
      newLifecycleStatus: 'deceased',
      cancelledTasksCount: cancelledCount,
      oldHouseholdId: member.householdId,
      notes: notes,
    );
  }

  Future<LifeEventResult> _recordMigration({
    required Member member,
    required int timestamp,
    String? reason,
    String? notes,
  }) async {
    // 1. Update lifecycle status
    await memberDao.updateLifecycleStatus(member.id, 'migrated', timestamp: timestamp);

    // 2. Suppress future tasks
    final cancelledCount = await memberDao.cancelOpenVisitSchedules(
      member.id,
      reason: reason ?? 'Migrated out',
    );

    // 3. Update household active member count
    final activeCount = await memberDao.countActiveMembers(member.householdId);
    await householdDao.updateMemberCount(member.householdId, activeCount);

    // 4. Enqueue sync
    await _enqueueSyncUpdate(member.id, 'migrated', timestamp);

    return LifeEventResult(
      memberId: member.id,
      eventType: LifeEventType.migration,
      timestamp: timestamp,
      newLifecycleStatus: 'migrated',
      cancelledTasksCount: cancelledCount,
      oldHouseholdId: member.householdId,
      notes: notes,
    );
  }

  Future<LifeEventResult> _recordMarriage({
    required Member member,
    required int timestamp,
    required bool isMovingOut,
    String? targetHouseholdId,
    String? reason,
    String? notes,
  }) async {
    if (isMovingOut) {
      // Moving out of area
      await memberDao.updateLifecycleStatus(member.id, 'married_out', timestamp: timestamp);
      final cancelledCount = await memberDao.cancelOpenVisitSchedules(
        member.id,
        reason: reason ?? 'Married out of area',
      );
      final activeCount = await memberDao.countActiveMembers(member.householdId);
      await householdDao.updateMemberCount(member.householdId, activeCount);

      await _enqueueSyncUpdate(member.id, 'married_out', timestamp);

      return LifeEventResult(
        memberId: member.id,
        eventType: LifeEventType.marriage,
        timestamp: timestamp,
        newLifecycleStatus: 'married_out',
        cancelledTasksCount: cancelledCount,
        oldHouseholdId: member.householdId,
        notes: notes,
      );
    } else {
      // Married but transferred to another local household
      final targetHh = targetHouseholdId ?? member.householdId;
      if (targetHouseholdId != null && targetHouseholdId != member.householdId) {
        await memberDao.transferHousehold(member.id, targetHh, timestamp: timestamp);
        final oldActive = await memberDao.countActiveMembers(member.householdId);
        await householdDao.updateMemberCount(member.householdId, oldActive);
        final newActive = await memberDao.countActiveMembers(targetHh);
        await householdDao.updateMemberCount(targetHh, newActive);
      }

      return LifeEventResult(
        memberId: member.id,
        eventType: LifeEventType.marriage,
        timestamp: timestamp,
        newLifecycleStatus: 'active',
        cancelledTasksCount: 0,
        oldHouseholdId: member.householdId,
        newHouseholdId: targetHh,
        notes: notes,
      );
    }
  }

  Future<LifeEventResult> _recordHouseholdTransfer({
    required Member member,
    required int timestamp,
    String? targetHouseholdId,
    required bool isMovingOut,
    String? reason,
    String? notes,
  }) async {
    if (isMovingOut) {
      // Transferred outside worker's catchment area
      await memberDao.updateLifecycleStatus(member.id, 'migrated', timestamp: timestamp);
      final cancelledCount = await memberDao.cancelOpenVisitSchedules(
        member.id,
        reason: reason ?? 'Transferred outside catchment',
      );
      final activeCount = await memberDao.countActiveMembers(member.householdId);
      await householdDao.updateMemberCount(member.householdId, activeCount);

      await _enqueueSyncUpdate(member.id, 'migrated', timestamp);

      return LifeEventResult(
        memberId: member.id,
        eventType: LifeEventType.householdTransfer,
        timestamp: timestamp,
        newLifecycleStatus: 'migrated',
        cancelledTasksCount: cancelledCount,
        oldHouseholdId: member.householdId,
        notes: notes,
      );
    }

    if (targetHouseholdId == null || targetHouseholdId.isEmpty) {
      throw ArgumentError('targetHouseholdId is required for internal household transfer');
    }

    // Transfer member within catchment area
    await memberDao.transferHousehold(member.id, targetHouseholdId, timestamp: timestamp);

    // Update active member counts for both households
    final oldActive = await memberDao.countActiveMembers(member.householdId);
    await householdDao.updateMemberCount(member.householdId, oldActive);

    final newActive = await memberDao.countActiveMembers(targetHouseholdId);
    await householdDao.updateMemberCount(targetHouseholdId, newActive);

    // Open visit schedules remain active (not cancelled)
    return LifeEventResult(
      memberId: member.id,
      eventType: LifeEventType.householdTransfer,
      timestamp: timestamp,
      newLifecycleStatus: 'active',
      cancelledTasksCount: 0,
      oldHouseholdId: member.householdId,
      newHouseholdId: targetHouseholdId,
      notes: notes,
    );
  }

  Future<LifeEventResult> _recordBirth({
    Member? existingMember,
    required int timestamp,
    String? newbornName,
    String? newbornSex,
    String? newbornHouseholdId,
    String? notes,
    required String recordedBy,
  }) async {
    String infantId;
    String householdId;

    if (existingMember != null && newbornName == null) {
      // Existing newborn record confirmed
      infantId = existingMember.id;
      householdId = existingMember.householdId;
      await memberDao.updateLifecycleStatus(infantId, 'active', timestamp: timestamp);
    } else {
      // Register a new infant member record
      householdId = newbornHouseholdId ?? (existingMember?.householdId ?? '');
      if (householdId.isEmpty) {
        throw ArgumentError('Household ID is required to register newborn');
      }

      infantId = _uuid.v4();
      final name = newbornName ?? 'Newborn of ${existingMember?.name ?? "Household"}';
      final sex = newbornSex ?? 'O';

      await memberDao.insertMember(
        MembersCompanion.insert(
          id: infantId,
          householdId: householdId,
          name: name,
          sex: sex,
          dobApprox: Value(timestamp),
          relationshipToHead: const Value('Child'),
          lifecycleStatus: const Value('active'),
          createdAt: timestamp,
          updatedAt: timestamp,
          createdBy: recordedBy,
        ),
      );
    }

    // Update household member count
    final activeCount = await memberDao.countActiveMembers(householdId);
    await householdDao.updateMemberCount(householdId, activeCount);

    // Automatically generate HBNC visit schedules for the newborn (Days 1, 3, 7, 14, 21, 28, 42)
    final hbncDays = [1, 3, 7, 14, 21, 28, 42];
    const dayMs = 24 * 60 * 60 * 1000;
    final generatedTaskIds = <String>[];

    for (final day in hbncDays) {
      final taskId = _uuid.v4();
      final dueDate = timestamp + (day * dayMs);
      await memberDao.insertVisitSchedule(
        VisitSchedulesCompanion.insert(
          id: taskId,
          memberId: infantId,
          programCode: 'hbnc',
          visitType: 'HBNC Day $day',
          dueDate: dueDate,
          createdAt: timestamp,
        ),
      );
      generatedTaskIds.add(taskId);
    }

    return LifeEventResult(
      memberId: infantId,
      eventType: LifeEventType.birth,
      timestamp: timestamp,
      newLifecycleStatus: 'active',
      cancelledTasksCount: 0,
      generatedTaskIds: generatedTaskIds,
      newHouseholdId: householdId,
      notes: notes,
    );
  }

  Future<void> _enqueueSyncUpdate(
    String memberId,
    String status,
    int timestamp,
  ) async {
    if (syncEngine != null) {
      await syncEngine!.enqueue(
        table: 'members',
        recordId: memberId,
        operation: 'update',
        priority: SyncPriority.metadata,
        payload: {
          'id': memberId,
          'lifecycle_status': status,
          'updated_at': timestamp,
          'dirty_flag': 1,
          'sync_version': 1,
        },
      );
    }
  }

  /// Convenience lookup of member by ID.
  Future<Member?> getMember(String id) => memberDao.getById(id);

  /// Convenience lookup of members in household.
  Future<List<Member>> getMembersByHousehold(String householdId) =>
      memberDao.getByHousehold(householdId);
}

// ── Riverpod Provider ─────────────────────────────────────────────────────────

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final memberDao = MemberDao(db);
  final householdDao = HouseholdDao(db);
  final syncEngine = ref.watch(syncEngineProvider);

  return MemberRepository(
    memberDao: memberDao,
    householdDao: householdDao,
    db: db,
    syncEngine: syncEngine,
  );
});
