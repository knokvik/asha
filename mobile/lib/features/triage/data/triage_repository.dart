import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart' as db_schema;
import '../../../core/sync/sync_engine.dart';
import '../../../core/triage/models/models.dart';
import '../../../shared/providers/core_providers.dart';

/// Repository for persisting and retrieving triage evaluation results and overrides.
///
/// Implements Requirements 8.1, 8.6, 8.9:
/// - Persists original triage engine outputs and ML contributions.
/// - Stores clinical overrides (upward or downward) alongside original output with reasons.
/// - Enqueues writes to [SyncEngine] (P1 for RED referrals, P2 for clinical encounters).
class TriageRepository {
  final db_schema.AppDatabase _db;
  final SyncEngine? _syncEngine;

  TriageRepository(this._db, [this._syncEngine]);

  /// Saves a newly computed [TriageResult] to the database.
  Future<void> saveTriageResult(TriageResult result, {String? memberId}) async {
    final findingsJson = jsonEncode(result.findings.map((f) => f.toJson()).toList());
    final missingJson = jsonEncode(result.missingFields);
    final mlJson = result.mlContribution != null
        ? jsonEncode(result.mlContribution!.toJson())
        : null;

    final evaluatedAtMs = result.evaluatedAt.millisecondsSinceEpoch;
    final encounterId = result.encounterId ?? 'enc_${result.id}';

    // Ensure parent encounter exists in DB to satisfy foreign key constraint
    final encounter = await (_db.select(_db.clinicalEncounters)
          ..where((t) => t.id.equals(encounterId)))
        .getSingleOrNull();

    if (encounter == null) {
      final actualMemberId = memberId ?? 'unregistered_member';
      final member = await (_db.select(_db.members)..where((t) => t.id.equals(actualMemberId))).getSingleOrNull();
      if (member == null) {
        const hhId = 'hh_triage_default';
        final hh = await (_db.select(_db.households)..where((t) => t.id.equals(hhId))).getSingleOrNull();
        if (hh == null) {
          await _db.into(_db.households).insert(
                db_schema.HouseholdsCompanion.insert(
                  id: hhId,
                  village: 'Community',
                  headName: 'Community Household',
                  createdAt: evaluatedAtMs,
                  updatedAt: evaluatedAtMs,
                  createdBy: 'asha_system',
                ),
                mode: InsertMode.insertOrIgnore,
              );
        }
        await _db.into(_db.members).insert(
              db_schema.MembersCompanion.insert(
                id: actualMemberId,
                householdId: hhId,
                name: 'Assessment Subject',
                sex: 'U',
                createdAt: evaluatedAtMs,
                updatedAt: evaluatedAtMs,
                createdBy: 'asha_system',
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }

      await _db.into(_db.clinicalEncounters).insert(
            db_schema.ClinicalEncountersCompanion.insert(
              id: encounterId,
              memberId: actualMemberId,
              encounterType: 'triage_assessment',
              programCode: 'GENERAL',
              encounterDate: evaluatedAtMs,
              ashaId: 'asha_system',
              createdAt: evaluatedAtMs,
              updatedAt: evaluatedAtMs,
            ),
            mode: InsertMode.insertOrIgnore,
          );
    }

    await _db.into(_db.triageResults).insert(
          db_schema.TriageResultsCompanion.insert(
            id: result.id,
            encounterId: encounterId,
            flag: result.flag.label,
            ruleVersionId: result.ruleVersionId,
            findingsJson: findingsJson,
            missingFieldsJson: Value(missingJson),
            escalatedForMissingData: Value(result.escalatedForMissingData),
            mlContributionJson: Value(mlJson),
            evaluatedAt: evaluatedAtMs,
          ),
          mode: InsertMode.insertOrReplace,
        );

    // Enqueue sync: RED triage is P1 critical; others are P2 clinical
    if (_syncEngine != null) {
      final priority = result.flag == TriageFlag.red
          ? SyncPriority.critical
          : SyncPriority.clinical;

      await _syncEngine.enqueue(
        table: 'triage_results',
        recordId: result.id,
        operation: 'insert',
        priority: priority,
        payload: {
          'id': result.id,
          'encounter_id': result.encounterId ?? 'enc_${result.id}',
          'member_id': memberId,
          'flag': result.flag.label,
          'rule_version_id': result.ruleVersionId,
          'findings_json': findingsJson,
          'missing_fields_json': missingJson,
          'escalated_for_missing_data': result.escalatedForMissingData,
          'ml_contribution_json': mlJson,
          'evaluated_at': evaluatedAtMs,
        },
      );
    }
  }

  /// Records an ASHA worker's clinical override for a triage assessment.
  ///
  /// Requirement 8.6: Stores both the engine's original output and the override,
  /// including the required 10–500 character reason and optional voice note.
  Future<void> recordOverride({
    required String triageResultId,
    required TriageOverride override,
  }) async {
    final overriddenAtMs = override.overriddenAt.millisecondsSinceEpoch;

    await (_db.update(_db.triageResults)..where((t) => t.id.equals(triageResultId)))
        .write(
      db_schema.TriageResultsCompanion(
        overrideFlag: Value(override.overrideFlag.label),
        overrideReason: Value(override.reason),
        overrideVoiceNotePath: Value(override.voiceNotePath),
        overridingUserId: Value(override.overridingUserId),
        overriddenAt: Value(overriddenAtMs),
      ),
    );

    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'triage_results',
        recordId: triageResultId,
        operation: 'update',
        priority: override.overrideFlag == TriageFlag.red
            ? SyncPriority.critical
            : SyncPriority.clinical,
        payload: {
          'id': triageResultId,
          'override_flag': override.overrideFlag.label,
          'override_reason': override.reason,
          'override_voice_note_path': override.voiceNotePath,
          'overriding_user_id': override.overridingUserId,
          'overridden_at': overriddenAtMs,
        },
      );
    }
  }

  /// Retrieves a triage result record by ID.
  Future<TriageResult?> getTriageResult(String id) async {
    final row = await (_db.select(_db.triageResults)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _mapRowToTriageResult(row);
  }

  /// Retrieves the triage result for an encounter.
  Future<TriageResult?> getTriageResultByEncounter(String encounterId) async {
    final row = await (_db.select(_db.triageResults)..where((t) => t.encounterId.equals(encounterId))).getSingleOrNull();
    if (row == null) return null;
    return _mapRowToTriageResult(row);
  }

  TriageResult _mapRowToTriageResult(db_schema.TriageResult row) {
    final findingsList = (jsonDecode(row.findingsJson) as List<dynamic>?)
            ?.map((e) => TriageFinding.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final missingList = (jsonDecode(row.missingFieldsJson) as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];

    final ml = row.mlContributionJson != null
        ? MLTriageContribution.fromJson(
            jsonDecode(row.mlContributionJson!) as Map<String, dynamic>,
          )
        : null;

    final flag = TriageFlag.fromString(row.flag);

    return TriageResult(
      id: row.id,
      encounterId: row.encounterId,
      flag: flag,
      ruleFlag: flag,
      ruleVersionId: row.ruleVersionId,
      findings: findingsList,
      missingFields: missingList,
      escalatedForMissingData: row.escalatedForMissingData,
      mlContribution: ml,
      evaluatedAt: DateTime.fromMillisecondsSinceEpoch(row.evaluatedAt),
    );
  }
}

final triageRepositoryProvider = Provider<TriageRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncEngineProvider);
  return TriageRepository(db, sync);
});
