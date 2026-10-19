import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Data Access Object for the [Members] Drift table.
/// Requirements: 4.1, 4.2
class MemberDao {
  final AppDatabase db;

  MemberDao(this.db);

  /// Inserts a new member record.
  Future<void> insertMember(MembersCompanion companion) async {
    await db.into(db.members).insert(companion);
  }

  /// Retrieves a member by UUID [id].
  Future<Member?> getById(String id) {
    return (db.select(db.members)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Lists all members belonging to [householdId].
  Future<List<Member>> getByHousehold(String householdId) {
    return (db.select(db.members)
          ..where((t) => t.householdId.equals(householdId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Updates an existing member row.
  Future<bool> updateMember(MembersCompanion companion) {
    return (db.update(db.members)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Deletes a member by [id].
  Future<int> deleteMember(String id) {
    return (db.delete(db.members)..where((t) => t.id.equals(id))).go();
  }

  /// Updates the lifecycle status of a member (active, deceased, migrated, married_out).
  Future<void> updateLifecycleStatus(
    String memberId,
    String status, {
    int? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    await (db.update(db.members)..where((t) => t.id.equals(memberId))).write(
      MembersCompanion(
        lifecycleStatus: Value(status),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  /// Cancels all open/pending visit schedules for [memberId] with [reason].
  /// Requirements: 4.5
  Future<int> cancelOpenVisitSchedules(
    String memberId, {
    required String reason,
  }) async {
    return (db.update(db.visitSchedules)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.status.isIn(['pending', 'overdue', 'due'])))
        .write(
      VisitSchedulesCompanion(
        status: const Value('cancelled'),
        skipReason: Value(reason),
      ),
    );
  }

  /// Transfers a member to [newHouseholdId] with updated timestamp.
  /// Requirements: 4.5
  Future<void> transferHousehold(
    String memberId,
    String newHouseholdId, {
    int? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    await (db.update(db.members)..where((t) => t.id.equals(memberId))).write(
      MembersCompanion(
        householdId: Value(newHouseholdId),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
  }

  /// Counts the active members in a household (excluding deceased, migrated, married_out).
  Future<int> countActiveMembers(String householdId) async {
    final countExp = db.members.id.count();
    final query = db.selectOnly(db.members)
      ..addColumns([countExp])
      ..where(db.members.householdId.equals(householdId) &
          db.members.lifecycleStatus.equals('active'));
    final result = await query.map((row) => row.read(countExp)).getSingle();
    return result ?? 0;
  }

  /// Retrieves open/pending visit schedules for a member.
  Future<List<VisitSchedule>> getActiveVisitSchedules(String memberId) {
    return (db.select(db.visitSchedules)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.status.isIn(['pending', 'overdue', 'due'])))
        .get();
  }

  /// Inserts a visit schedule record.
  Future<void> insertVisitSchedule(VisitSchedulesCompanion companion) async {
    await db.into(db.visitSchedules).insert(companion);
  }

  /// Searches members by substring on name.
  Future<List<Member>> searchByName(String query) {
    return (db.select(db.members)
          ..where((t) => t.name.like('%$query%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }
}
