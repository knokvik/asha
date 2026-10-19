import 'package:uuid/uuid.dart';
import 'drafts_dao.dart';
import '../app_database.dart';

/// High-level draft persistence and recovery service.
///
/// Wraps [DraftsDao] with auto-save and recovery logic:
/// - Call [saveDraft] on every form field change (debounced in the UI layer)
///   to preserve partial form state in the [Local_Store].
/// - Call [recoverDraft] on app launch (or when navigating to a form) to
///   detect an existing draft and offer the user a "Resume?" prompt.
/// - Call [clearDraft] after a successful form submission to remove the
///   draft from the store.
///
/// **Idempotence guarantee:** saving the same (formType, memberId) pair N
/// times produces exactly one draft record with the latest [partialData]
/// — duplicates are prevented by the stable deterministic ID passed to the
/// underlying [DraftsDao.saveDraft] upsert.
///
/// Requirements: 1.3
class DraftRecoveryService {
  final DraftsDao _dao;
  final _uuid = const Uuid();

  DraftRecoveryService(this._dao);

  /// Save partial form state.
  ///
  /// Should be called on every field change, debounced in the UI layer
  /// (e.g. 500 ms debounce via a Riverpod listener) to avoid excessive
  /// database writes.
  Future<void> saveDraft({
    required String formType,
    String? memberId,
    required Map<String, dynamic> partialData,
  }) {
    return _dao.saveDraft(
      id: _stableId(formType, memberId),
      formType: formType,
      memberId: memberId,
      partialData: partialData,
    );
  }

  /// Retrieve the draft on app re-launch.
  ///
  /// Returns the decoded partial data map, or null if no draft exists for
  /// the given (formType, memberId) pair.
  Future<Map<String, dynamic>?> recoverDraft({
    required String formType,
    String? memberId,
  }) async {
    final draft = await _dao.getDraft(
      formType: formType,
      memberId: memberId,
    );
    if (draft == null) return null;
    return _dao.decodeData(draft);
  }

  /// Clear the draft after a successful form submission.
  ///
  /// Idempotent — calling this when no draft exists is a safe no-op.
  Future<void> clearDraft({
    required String formType,
    String? memberId,
  }) {
    return _dao.deleteDraft(formType: formType, memberId: memberId);
  }

  /// List all pending drafts.
  ///
  /// Used on app launch to present a recovery prompt listing all forms with
  /// unsaved state, ordered most-recently-modified first.
  Future<List<Draft>> listPendingDrafts() => _dao.listAllDrafts();

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Derives a stable, deterministic UUID v5 from (formType + memberId).
  ///
  /// Using a deterministic ID ensures that repeated [saveDraft] calls for
  /// the same form session map to the same primary key in the database,
  /// enabling the upsert to update rather than insert — achieving idempotence.
  String _stableId(String formType, String? memberId) {
    return _uuid.v5(Namespace.url.value, 'draft:$formType:${memberId ?? ''}');
  }
}
