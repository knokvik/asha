import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' hide TriageResult;
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/triage/models/models.dart';
import '../../../../shared/providers/core_providers.dart';
import '../domain/growth_models.dart';
import '../domain/who_growth_calculator.dart';
import '../domain/who_standards_data.dart';

/// Repository managing child growth monitoring, WHO Z-score computation,
/// malnutrition triage & NRC referral, supplementation schedules, and CMAM exit tracking.
///
/// Implements Requirements 17.1 – 17.6.
class NutritionRepository {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;
  static const _uuid = Uuid();

  NutritionRepository(this._db, [this._syncEngine]);

  // ── 1. SQLite Standard Table Embedding (Requirement 17.1) ───────────────────

  /// Embeds and seeds WHO Child Growth Standard tables in SQLite.
  Future<void> ensureSqliteStandardsTablePopulated() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS who_growth_standards (
        id TEXT PRIMARY KEY,
        standard_type TEXT NOT NULL,
        sex TEXT NOT NULL,
        x_value REAL NOT NULL,
        l_value REAL NOT NULL,
        m_value REAL NOT NULL,
        s_value REAL NOT NULL,
        sd3neg REAL NOT NULL,
        sd2neg REAL NOT NULL,
        sd1neg REAL NOT NULL,
        sd0 REAL NOT NULL,
        sd1pos REAL NOT NULL,
        sd2pos REAL NOT NULL,
        sd3pos REAL NOT NULL
      );
    ''');

    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_who_standards_lookup
      ON who_growth_standards(standard_type, sex, x_value);
    ''');

    // Check if table is already seeded
    final countResult = await _db.customSelect('SELECT COUNT(*) as count FROM who_growth_standards').getSingle();
    final count = countResult.read<int>('count');
    if (count > 0) return;

    // Seed standards
    await _db.transaction(() async {
      for (final p in WhoStandardsData.wazBoys) {
        await _insertStandardRow('WAZ', 'M', p);
      }
      for (final p in WhoStandardsData.wazGirls) {
        await _insertStandardRow('WAZ', 'F', p);
      }
      for (final p in WhoStandardsData.hazBoys) {
        await _insertStandardRow('HAZ', 'M', p);
      }
      for (final p in WhoStandardsData.hazGirls) {
        await _insertStandardRow('HAZ', 'F', p);
      }
      for (final p in WhoStandardsData.wfhzBoys) {
        await _insertStandardRow('WFHZ', 'M', p);
      }
      for (final p in WhoStandardsData.wfhzGirls) {
        await _insertStandardRow('WFHZ', 'F', p);
      }
    });
  }

  Future<void> _insertStandardRow(String type, String sex, LmsPoint p) async {
    await _db.customStatement(
      '''
      INSERT OR REPLACE INTO who_growth_standards
      (id, standard_type, sex, x_value, l_value, m_value, s_value, sd3neg, sd2neg, sd1neg, sd0, sd1pos, sd2pos, sd3pos)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    ''',
      [
        '${type}_${sex}_${p.x}',
        type,
        sex,
        p.x,
        p.l,
        p.m,
        p.s,
        p.sd3neg,
        p.sd2neg,
        p.sd1neg,
        p.sd0,
        p.sd1pos,
        p.sd2pos,
        p.sd3pos,
      ],
    );
  }

  // ── 2. Growth Measurement & Classification (Requirement 17.1, 17.2, 17.3) ───

  /// Records an anthropometric measurement, evaluates offline against WHO standards,
  /// triggers RED / YELLOW triage flags, and generates referral or follow-up schedules.
  Future<GrowthMeasurement> recordGrowthMeasurement({
    required String memberId,
    required double weightKg,
    double? heightCm,
    double? muacCm,
    bool bilateralOedema = false,
    bool? appetiteTestPassed,
    double? haemoglobinGdl,
    required String ashaId,
    DateTime? measuredAt,
  }) async {
    final now = measuredAt ?? DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    // 1. Fetch beneficiary DOB and sex
    final member = await (_db.select(_db.members)..where((t) => t.id.equals(memberId))).getSingle();
    final dob = member.dobApprox != null
        ? DateTime.fromMillisecondsSinceEpoch(member.dobApprox!)
        : now.subtract(const Duration(days: 365));
    final sex = member.sex;

    // 2. Compute WHO Z-scores and clinical status offline
    final measurement = WhoGrowthCalculator.evaluateNutritionalStatus(
      id: encounterId,
      memberId: memberId,
      measuredAt: now,
      dateOfBirth: dob,
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
      muacCm: muacCm,
      bilateralOedema: bilateralOedema,
      appetiteTestPassed: appetiteTestPassed,
      haemoglobinGdl: haemoglobinGdl,
    );

    // 3. Create ClinicalEncounter
    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: memberId,
        encounterType: 'GROWTH_MONITORING',
        programCode: 'nutrition',
        encounterDate: nowMs,
        ashaId: ashaId,
        status: const Value('completed'),
        visitNotes: Value(
          'Weight: ${weightKg}kg | WAZ: ${measurement.waz} | Wasting: ${measurement.wastingStatus.name} | Triage: ${measurement.triageFlag.name}',
        ),
        createdAt: nowMs,
        updatedAt: nowMs,
        syncStatus: const Value('pending'),
      ),
    );

    // 4. Insert discrete ClinicalObservations
    final obs = <ClinicalObservationsCompanion>[
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'WEIGHT_KG',
        valueNumeric: Value(weightKg),
        valueUnit: const Value('kg'),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'WAZ',
        valueNumeric: Value(measurement.waz),
        source: const Value('WHO_STANDARDS'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'WASTING_STATUS',
        valueText: Value(measurement.wastingStatus.name),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'UNDERWEIGHT_STATUS',
        valueText: Value(measurement.underweightStatus.name),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'BILATERAL_OEDEMA',
        valueEnum: Value(bilateralOedema ? 'YES' : 'NO'),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
    ];

    if (heightCm != null) {
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'HEIGHT_CM',
          valueNumeric: Value(heightCm),
          valueUnit: const Value('cm'),
          source: const Value('MANUAL'),
          observedAt: nowMs,
        ),
      );
      if (measurement.haz != null) {
        obs.add(
          ClinicalObservationsCompanion.insert(
            id: _uuid.v4(),
            encounterId: encounterId,
            observationCode: 'HAZ',
            valueNumeric: Value(measurement.haz!),
            source: const Value('WHO_STANDARDS'),
            observedAt: nowMs,
          ),
        );
      }
      if (measurement.wfhz != null) {
        obs.add(
          ClinicalObservationsCompanion.insert(
            id: _uuid.v4(),
            encounterId: encounterId,
            observationCode: 'WFHZ',
            valueNumeric: Value(measurement.wfhz!),
            source: const Value('WHO_STANDARDS'),
            observedAt: nowMs,
          ),
        );
      }
    }

    if (muacCm != null) {
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'MUAC_CM',
          valueNumeric: Value(muacCm),
          valueUnit: const Value('cm'),
          source: const Value('MANUAL'),
          observedAt: nowMs,
        ),
      );
    }

    if (appetiteTestPassed != null) {
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'APPETITE_TEST',
          valueEnum: Value(appetiteTestPassed ? 'PASSED' : 'FAILED'),
          source: const Value('MANUAL'),
          observedAt: nowMs,
        ),
      );
    }

    if (haemoglobinGdl != null) {
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'HAEMOGLOBIN_GDL',
          valueNumeric: Value(haemoglobinGdl),
          valueUnit: const Value('g/dL'),
          source: const Value('MANUAL'),
          observedAt: nowMs,
        ),
      );
    }

    for (final o in obs) {
      await _db.into(_db.clinicalObservations).insert(o);
    }

    // 5. Record TriageResult
    await _db.into(_db.triageResults).insert(
      TriageResultsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        flag: measurement.triageFlag.name.toUpperCase(),
        ruleVersionId: '1.0.0',
        findingsJson: jsonEncode(measurement.clinicalFindings),
        evaluatedAt: nowMs,
      ),
    );

    // 6. RED Flag: SAM / Bilateral Oedema / Appetite Failure -> NRC Referral (Requirement 17.2)
    if (measurement.triageFlag == TriageFlag.red) {
      await _db.into(_db.referralRecords).insert(
        ReferralRecordsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          memberId: memberId,
          triageFlag: 'RED',
          destinationLevel: const Value('NRC_CHC'),
          transportArranged: const Value('108_AMBULANCE'),
          status: const Value('created'),
          referralNoteText: Value(
            'URGENT MALNUTRITION: ${measurement.clinicalFindings.join("; ")}. Recommended NRC admission.',
          ),
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      );

      // Enqueue Critical Sync Alert to ANM & MO
      if (_syncEngine != null) {
        await _syncEngine.enqueue(
          table: 'referral_records',
          recordId: encounterId,
          operation: 'insert',
          priority: SyncPriority.critical,
          payload: {
            'member_id': memberId,
            'type': 'SAM_RED_ALERT',
            'findings': measurement.clinicalFindings,
            'weight_kg': weightKg,
            'waz': measurement.waz,
          },
        );
      }
    } else if (measurement.wastingStatus == WastingStatus.mam) {
      // 7. YELLOW Flag: MAM -> Linkage to Anganwadi & Closer Follow-Up Schedule (Requirement 17.3)
      final followUpDueDate = now.add(const Duration(days: 14)).millisecondsSinceEpoch;
      final followUpTaskId = 'mam_followup_${memberId}_$nowMs';

      await _db.into(_db.visitSchedules).insert(
        VisitSchedulesCompanion.insert(
          id: followUpTaskId,
          memberId: memberId,
          programCode: 'nutrition',
          visitType: 'MAM Bi-Weekly Growth Follow-Up & Anganwadi Linkage',
          dueDate: followUpDueDate,
          dueWindowStart: Value(followUpDueDate - (3 * 24 * 3600 * 1000)),
          dueWindowEnd: Value(followUpDueDate + (3 * 24 * 3600 * 1000)),
          status: const Value('pending'),
          createdAt: nowMs,
        ),
        mode: InsertMode.insertOrReplace,
      );
    }

    // Enqueue clinical encounter
    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'clinical_encounters',
        recordId: encounterId,
        operation: 'insert',
        priority: measurement.triageFlag == TriageFlag.red ? SyncPriority.critical : SyncPriority.clinical,
        payload: measurement.toJson(),
      );
    }

    return measurement;
  }

  /// Fetches historical growth measurements for plotting on growth charts.
  Future<List<GrowthMeasurement>> getGrowthHistory(String memberId) async {
    final member = await (_db.select(_db.members)..where((t) => t.id.equals(memberId))).getSingle();
    final dob = member.dobApprox != null
        ? DateTime.fromMillisecondsSinceEpoch(member.dobApprox!)
        : DateTime.now().subtract(const Duration(days: 365));
    final sex = member.sex;

    final encounters = await (_db.select(_db.clinicalEncounters)
          ..where((t) => t.memberId.equals(memberId) & t.encounterType.equals('GROWTH_MONITORING'))
          ..orderBy([(t) => OrderingTerm.asc(t.encounterDate)]))
        .get();

    final results = <GrowthMeasurement>[];

    for (final enc in encounters) {
      final observations = await (_db.select(_db.clinicalObservations)..where((t) => t.encounterId.equals(enc.id))).get();

      double weightKg = 0.0;
      double? heightCm;
      double? muacCm;
      bool oedema = false;
      bool? appetite;
      double? hb;

      for (final o in observations) {
        if (o.observationCode == 'WEIGHT_KG') weightKg = o.valueNumeric ?? 0.0;
        if (o.observationCode == 'HEIGHT_CM') heightCm = o.valueNumeric;
        if (o.observationCode == 'MUAC_CM') muacCm = o.valueNumeric;
        if (o.observationCode == 'BILATERAL_OEDEMA') oedema = o.valueEnum == 'YES';
        if (o.observationCode == 'APPETITE_TEST') appetite = o.valueEnum == 'PASSED';
        if (o.observationCode == 'HAEMOGLOBIN_GDL') hb = o.valueNumeric;
      }

      if (weightKg > 0) {
        results.add(
          WhoGrowthCalculator.evaluateNutritionalStatus(
            id: enc.id,
            memberId: memberId,
            measuredAt: DateTime.fromMillisecondsSinceEpoch(enc.encounterDate),
            dateOfBirth: dob,
            sex: sex,
            weightKg: weightKg,
            heightCm: heightCm,
            muacCm: muacCm,
            bilateralOedema: oedema,
            appetiteTestPassed: appetite,
            haemoglobinGdl: hb,
          ),
        );
      }
    }

    return results;
  }

  // ── 3. Supplementation Tracking (Requirement 17.4) ──────────────────────────

  /// Records administration of IFA, Vitamin A, or Deworming.
  Future<SupplementationRecord> recordSupplementation({
    required String memberId,
    required SupplementType type,
    required String doseAmount,
    required String ashaId,
    DateTime? date,
    String? notes,
  }) async {
    final now = date ?? DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final encounterId = _uuid.v4();
    final recordId = 'sup_${_uuid.v4().substring(0, 8)}';

    // 1. Create Encounter
    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: memberId,
        encounterType: 'SUPPLEMENTATION_DOSE',
        programCode: 'nutrition',
        encounterDate: nowMs,
        ashaId: ashaId,
        status: const Value('completed'),
        visitNotes: Value('${type.displayName}: $doseAmount'),
        createdAt: nowMs,
        updatedAt: nowMs,
        syncStatus: const Value('pending'),
      ),
    );

    // 2. Observations
    await _db.into(_db.clinicalObservations).insert(
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'SUPPLEMENT_TYPE',
        valueText: Value(type.name),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
    );
    await _db.into(_db.clinicalObservations).insert(
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'DOSE_AMOUNT',
        valueText: Value(doseAmount),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
    );

    final record = SupplementationRecord(
      id: recordId,
      memberId: memberId,
      supplementType: type,
      dateAdministered: now,
      doseAmount: doseAmount,
      ashaId: ashaId,
      notes: notes,
    );

    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'clinical_encounters',
        recordId: encounterId,
        operation: 'insert',
        priority: SyncPriority.clinical,
        payload: record.toJson(),
      );
    }

    return record;
  }

  // ── 4. Malnutrition Treatment Follow-Up & Exit Criteria (Requirement 17.6) ──

  /// Records weekly/monthly malnutrition follow-up visit and evaluates exit criteria
  /// (cured/defaulted/died/non-responder).
  Future<MalnutritionExitOutcome?> evaluateMalnutritionVisit({
    required String memberId,
    required double weightKg,
    double? heightCm,
    double? muacCm,
    bool bilateralOedema = false,
    int consecutiveCureVisitsSoFar = 0,
    int weeksInProgramme = 1,
    bool isDeceased = false,
    bool missedTwoConsecutiveVisits = false,
  }) async {
    if (isDeceased) {
      return MalnutritionExitOutcome.died;
    }

    if (missedTwoConsecutiveVisits) {
      return MalnutritionExitOutcome.defaulted;
    }

    final member = await (_db.select(_db.members)..where((t) => t.id.equals(memberId))).getSingle();
    final sex = member.sex;

    final wfhz = heightCm != null ? WhoGrowthCalculator.calculateWfhz(weightKg: weightKg, heightCm: heightCm, sex: sex) : null;
    final isMuacNormal = muacCm != null && muacCm >= 12.5;
    final isWfhzNormal = wfhz != null && wfhz >= -2.0;

    // Cure criteria: WFHZ >= -2 and MUAC >= 12.5 cm with NO oedema for 2 consecutive visits
    if (!bilateralOedema && (isMuacNormal || isWfhzNormal)) {
      if (consecutiveCureVisitsSoFar + 1 >= 2) {
        return MalnutritionExitOutcome.cured;
      }
    }

    // Non-responder criteria: In programme for >= 16 weeks (4 months) without reaching cure
    if (weeksInProgramme >= 16) {
      return MalnutritionExitOutcome.nonResponder;
    }

    return null; // Still in active treatment
  }
}

/// Riverpod provider for [NutritionRepository].
final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return NutritionRepository(db, syncEngine);
});
