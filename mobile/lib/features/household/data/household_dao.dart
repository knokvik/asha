import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

/// Data Access Object for the [Households] Drift table.
/// Requirements: 4.1, 4.2
class HouseholdDao {
  final AppDatabase db;

  HouseholdDao(this.db);

  /// Inserts a new household record.
  Future<void> insertHousehold(HouseholdsCompanion companion) async {
    await db.into(db.households).insert(companion);
  }

  /// Retrieves a household by its UUID [id].
  Future<Household?> getById(String id) {
    return (db.select(db.households)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Lists all households, optionally filtered by [village].
  Future<List<Household>> getAll({String? village}) {
    final query = db.select(db.households);
    if (village != null && village.isNotEmpty) {
      query.where((t) => t.village.equals(village));
    }
    return (query..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  /// Updates an existing household row.
  Future<bool> updateHousehold(HouseholdsCompanion companion) {
    return (db.update(db.households)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// Deletes a household by [id].
  Future<int> deleteHousehold(String id) {
    return (db.delete(db.households)..where((t) => t.id.equals(id))).go();
  }

  /// Updates the cached member count for a household.
  Future<void> updateMemberCount(String householdId, int count) async {
    await (db.update(db.households)..where((t) => t.id.equals(householdId)))
        .write(
      HouseholdsCompanion(
        memberCount: Value(count),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}
