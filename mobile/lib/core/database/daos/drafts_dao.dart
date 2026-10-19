import 'dart:convert';
import 'package:drift/drift.dart';
import '../app_database.dart';

part 'drafts_dao.g.dart';

/// Data access object for the [Drafts] table.
///
/// Provides upsert, lookup, delete, and list operations used by
/// [DraftRecoveryService] to persist and recover in-progress form state.
///
/// Requirements: 1.3
@DriftAccessor(tables: [Drafts])
class DraftsDao extends DatabaseAccessor<AppDatabase> with _$DraftsDaoMixin {
  DraftsDao(super.db);

  /// Upsert a draft for [formType] and optional [memberId].
  ///
  /// Uses [insertOnConflictUpdate] so repeated calls with the same [id]
  /// (produced by [DraftRecoveryService._stableId]) update `partialDataJson`
  /// and `lastModifiedAt` in place — idempotence guarantee.
  Future<void> saveDraft({
    required String id,
    required String formType,
    String? memberId,
    required Map<String, dynamic> partialData,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await into(drafts).insertOnConflictUpdate(
      DraftsCompanion(
        id: Value(id),
        formType: Value(formType),
        memberId: Value(memberId),
        partialDataJson: Value(jsonEncode(partialData)),
        lastModifiedAt: Value(now),
        // recoveryCount is managed by the application layer, not the upsert.
      ),
    );
  }

  /// Retrieve the most recent draft for [formType], optionally filtered by
  /// [memberId]. Returns null when no matching draft exists.
  Future<Draft?> getDraft({
    required String formType,
    String? memberId,
  }) {
    final query = select(drafts)
      ..where((t) => t.formType.equals(formType))
      ..orderBy([(t) => OrderingTerm.desc(t.lastModifiedAt)])
      ..limit(1);

    if (memberId != null) {
      query.where((t) => t.memberId.equals(memberId));
    }

    return query.getSingleOrNull();
  }

  /// Delete the draft for [formType] and optional [memberId] after a
  /// successful form submission.
  Future<void> deleteDraft({
    required String formType,
    String? memberId,
  }) async {
    final q = delete(drafts)
      ..where((t) => t.formType.equals(formType));
    if (memberId != null) {
      q.where((t) => t.memberId.equals(memberId));
    }
    await q.go();
  }

  /// List all pending drafts, ordered most-recently-modified first.
  ///
  /// Used on app launch to present a recovery prompt.
  Future<List<Draft>> listAllDrafts() => (select(drafts)
        ..orderBy([(t) => OrderingTerm.desc(t.lastModifiedAt)]))
      .get();

  /// Decode a [Draft]'s JSON payload back into a [Map].
  Map<String, dynamic> decodeData(Draft draft) =>
      jsonDecode(draft.partialDataJson) as Map<String, dynamic>;
}
