import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/triage/models/models.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/referral_models.dart';

/// Repository managing referral records, offline persistence, and synchronization.
///
/// Implements Requirements 10.1, 10.2, 10.4, 10.5:
/// - Persists structured referral note and metadata to SQLite.
/// - Enqueues P1 critical sync event for Red referrals (Requirement 31.1).
/// - Tracks referral lifecycle: `created` -> `en_route` -> `arrived` -> `outcome_recorded`.
class ReferralRepository {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;

  ReferralRepository(this._db, [this._syncEngine]);

  /// Saves a newly created [StructuredReferralNote] and returns the persisted record.
  Future<ReferralRecord> createReferral({
    required StructuredReferralNote note,
    String? pdfPath,
    String? transportArranged,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final qrData = note.toQrPayload();
    final noteText = note.formatSummary(english: true);

    // A clinical encounter can have only one referral on the backend. Reusing
    // the existing local record makes repeated taps/reopens idempotent and
    // prevents duplicate referral packets from being rejected during sync.
    final existingForEncounter = await (_db.select(
      _db.referralRecords,
    )..where((t) => t.encounterId.equals(note.encounterId))).getSingleOrNull();
    if (existingForEncounter != null) return existingForEncounter;

    // Ensure parent encounter exists in DB to satisfy foreign key constraint
    final encounter = await (_db.select(
      _db.clinicalEncounters,
    )..where((t) => t.id.equals(note.encounterId))).getSingleOrNull();

    if (encounter == null) {
      final memberId = note.patient.memberId;
      final member = await (_db.select(
        _db.members,
      )..where((t) => t.id.equals(memberId))).getSingleOrNull();
      if (member == null) {
        final hhId = note.patient.householdId ?? 'hh_ref_default';
        final hh = await (_db.select(
          _db.households,
        )..where((t) => t.id.equals(hhId))).getSingleOrNull();
        if (hh == null) {
          await _db
              .into(_db.households)
              .insert(
                HouseholdsCompanion.insert(
                  id: hhId,
                  village: note.patient.village ?? 'Community',
                  headName: note.patient.headName ?? 'Community Household',
                  createdAt: now,
                  updatedAt: now,
                  createdBy: note.asha.id,
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
        await _db
            .into(_db.members)
            .insert(
              MembersCompanion.insert(
                id: memberId,
                householdId: hhId,
                name: note.patient.name,
                sex: note.patient.sex,
                createdAt: now,
                updatedAt: now,
                createdBy: note.asha.id,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }

      await _db
          .into(_db.clinicalEncounters)
          .insert(
            ClinicalEncountersCompanion.insert(
              id: note.encounterId,
              memberId: memberId,
              encounterType: 'referral_triage',
              programCode: 'EMERGENCY',
              encounterDate: now,
              ashaId: note.asha.id,
              createdAt: now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }

    final companion = ReferralRecordsCompanion.insert(
      id: note.referralId,
      encounterId: note.encounterId,
      memberId: note.patient.memberId,
      triageFlag: note.triageFlag.label,
      destinationFacilityId: Value(note.destinationFacility?.id),
      destinationLevel: Value(note.destinationFacility?.level.value),
      transportArranged: Value(transportArranged ?? note.transportArranged),
      status: const Value('created'),
      referralNoteText: Value(noteText),
      referralPdfPath: Value(pdfPath),
      referralQrData: Value(qrData),
      createdAt: now,
      updatedAt: now,
      syncStatus: const Value('pending'),
    );

    await _db
        .into(_db.referralRecords)
        .insert(companion, mode: InsertMode.insertOrReplace);

    // Enqueue to SyncEngine: RED is P1 Critical, other flags are P2 Clinical
    if (_syncEngine != null) {
      final priority = note.triageFlag == TriageFlag.red
          ? SyncPriority.critical
          : SyncPriority.clinical;

      await _syncEngine.enqueue(
        table: 'referral_records',
        recordId: note.referralId,
        operation: 'insert',
        priority: priority,
        payload: {
          'id': note.referralId,
          'encounter_id': note.encounterId,
          'member_id': note.patient.memberId,
          'triage_flag': note.triageFlag.label,
          'destination_facility_id': note.destinationFacility?.id,
          'destination_level': note.destinationFacility?.level.value,
          'transport_arranged': transportArranged ?? note.transportArranged,
          'status': 'created',
          'referral_note_text': noteText,
          'referral_pdf_path': pdfPath,
          'referral_qr_data': qrData,
          'created_at': now,
          'updated_at': now,
        },
      );
    }

    return (await (_db.select(
      _db.referralRecords,
    )..where((t) => t.id.equals(note.referralId))).getSingle());
  }

  /// Updates referral status (e.g. en_route or arrived).
  Future<void> updateStatus({
    required String referralId,
    required ReferralStatus newStatus,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(
      _db.referralRecords,
    )..where((t) => t.id.equals(referralId))).write(
      ReferralRecordsCompanion(
        status: Value(newStatus.value),
        updatedAt: Value(now),
      ),
    );

    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'referral_records',
        recordId: referralId,
        operation: 'update',
        priority: SyncPriority.clinical,
        payload: {
          'id': referralId,
          'status': newStatus.value,
          'updated_at': now,
        },
      );
    }
  }

  /// Records referral clinical outcome (Requirement 10.5).
  Future<void> recordOutcome({
    required String referralId,
    required OutcomeType outcomeType,
    required String recordedBy,
    String? notes,
    DateTime? recordedAt,
  }) async {
    final now = (recordedAt ?? DateTime.now()).millisecondsSinceEpoch;

    await (_db.update(
      _db.referralRecords,
    )..where((t) => t.id.equals(referralId))).write(
      ReferralRecordsCompanion(
        status: const Value('outcome_recorded'),
        outcome: Value(outcomeType.value),
        outcomeRecordedBy: Value(recordedBy),
        outcomeRecordedAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'referral_records',
        recordId: referralId,
        operation: 'update',
        priority: SyncPriority.clinical,
        payload: {
          'id': referralId,
          'status': 'outcome_recorded',
          'outcome': outcomeType.value,
          'outcome_recorded_by': recordedBy,
          'outcome_recorded_at': now,
          'notes': notes,
          'updated_at': now,
        },
      );
    }
  }

  /// Retrieves a referral by ID.
  Future<ReferralRecord?> getReferral(String id) async {
    return (_db.select(
      _db.referralRecords,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Retrieves all referrals for a given beneficiary member.
  Future<List<ReferralRecord>> getReferralsForMember(String memberId) async {
    return (_db.select(_db.referralRecords)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }
}

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return ReferralRepository(db, syncEngine);
});
