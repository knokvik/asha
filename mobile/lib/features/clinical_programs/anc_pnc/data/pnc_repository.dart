import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' hide TriageResult;
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/triage/models/models.dart';
import '../../../../shared/providers/core_providers.dart';
import '../domain/pnc_models.dart';

/// Repository managing Postnatal Care (PNC) maternal monitoring, postpartum depression
/// screening, danger sign escalation, and institutional delivery escort incentives.
///
/// Implements Requirements 15.1 – 15.6.
class PncRepository {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;
  static const _uuid = Uuid();

  PncRepository(this._db, [this._syncEngine]);

  /// 1. Generates maternal PNC visit schedule upon delivery record (Requirement 15.3).
  ///
  /// Standard schedule: Days 3, 7, 14, 21, 28, 42 (plus Day 1 for home delivery).
  Future<List<VisitSchedule>> generatePncSchedule({
    required String motherId,
    required DateTime deliveryDate,
    bool isHomeDelivery = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final deliveryMs = deliveryDate.millisecondsSinceEpoch;
    const dayMs = 24 * 60 * 60 * 1000;

    final visitDays = isHomeDelivery ? [1, 3, 7, 14, 21, 28, 42] : [3, 7, 14, 21, 28, 42];
    final generatedSchedules = <VisitSchedule>[];

    for (final day in visitDays) {
      final targetDueMs = deliveryMs + (day * dayMs);
      final taskId = 'pnc_${motherId}_d$day';

      // Window margins: ±2 days
      final windowStartMs = targetDueMs - (1 * dayMs);
      final windowEndMs = targetDueMs + (2 * dayMs);

      final companion = VisitSchedulesCompanion.insert(
        id: taskId,
        memberId: motherId,
        programCode: 'pnc',
        visitType: 'Maternal PNC Day $day Visit',
        dueDate: targetDueMs,
        dueWindowStart: Value(windowStartMs),
        dueWindowEnd: Value(windowEndMs),
        status: const Value('pending'),
        createdAt: now,
      );

      await _db.into(_db.visitSchedules).insert(companion, mode: InsertMode.insertOrReplace);

      if (_syncEngine != null) {
        await _syncEngine.enqueue(
          table: 'visit_schedules',
          recordId: taskId,
          operation: 'insert',
          priority: SyncPriority.metadata,
          payload: {
            'id': taskId,
            'member_id': motherId,
            'program_code': 'pnc',
            'visit_type': 'Maternal PNC Day $day Visit',
            'due_date': targetDueMs,
            'status': 'pending',
          },
        );
      }

      final created = await (_db.select(_db.visitSchedules)..where((t) => t.id.equals(taskId))).getSingle();
      generatedSchedules.add(created);
    }

    return generatedSchedules;
  }

  /// 2. Records maternal PNC contact with full checklist, depression screening,
  /// and danger sign evaluation (Requirements 15.3, 15.4, 15.5).
  Future<PncVisitResult> recordPncVisit({
    required String motherId,
    required String visitScheduleId,
    required PncChecklistData checklist,
    required String ashaId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    // 1. Create ClinicalEncounter
    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: motherId,
        encounterType: 'PNC_VISIT',
        programCode: 'pnc',
        encounterDate: now,
        ashaId: ashaId,
        status: const Value('completed'),
        visitNotes: Value(checklist.generalNotes),
        createdAt: now,
        updatedAt: now,
        syncStatus: const Value('pending'),
      ),
    );

    // 2. Insert discrete ClinicalObservations
    final observations = <ClinicalObservationsCompanion>[
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'MATERNAL_BLEEDING',
        valueEnum: Value(checklist.bleedingStatus.code),
        valueText: Value(checklist.bleedingStatus.label),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'BREAST_EXAMINATION',
        valueEnum: Value(checklist.breastStatus.code),
        valueText: Value(checklist.breastStatus.label),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'WOUND_HEALING',
        valueEnum: Value(checklist.woundStatus.code),
        valueText: Value(checklist.woundStatus.label),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'PPD_SCREENING',
        valueEnum: Value(checklist.hasPpd ? 'POSITIVE' : 'NEGATIVE'),
        valueText: Value(checklist.depressionScreening.ppdFindings.join('; ')),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'PPFP_CONTRACEPTION',
        valueEnum: Value(checklist.postpartumContraceptionCounseled ? 'COUNSELED' : 'NOT_COUNSELED'),
        valueText: Value(checklist.chosenContraceptionMethod),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
    ];

    if (checklist.temperatureC != null) {
      observations.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'TEMPERATURE',
          valueNumeric: Value(checklist.temperatureC!),
          valueUnit: const Value('°C'),
          source: const Value('MANUAL'),
          observedAt: now,
        ),
      );
    }

    if (checklist.systolicBp != null && checklist.diastolicBp != null) {
      observations.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'BLOOD_PRESSURE',
          valueText: Value('${checklist.systolicBp}/${checklist.diastolicBp}'),
          valueNumeric: Value(checklist.systolicBp!.toDouble()),
          valueUnit: const Value('mmHg'),
          source: const Value('MANUAL'),
          observedAt: now,
        ),
      );
    }

    for (final obs in observations) {
      await _db.into(_db.clinicalObservations).insert(obs);
    }

    // 3. Mark VisitSchedule row as completed
    await (_db.update(_db.visitSchedules)..where((t) => t.id.equals(visitScheduleId))).write(
      VisitSchedulesCompanion(
        status: const Value('completed'),
        completedAt: Value(now),
        completedEncounterId: Value(encounterId),
      ),
    );

    // 4. Maternal Danger Signs & PPD Evaluation (Requirements 15.4, 15.5)
    final dangerSigns = checklist.maternalDangerSigns;
    final isRedFlag = dangerSigns.isNotEmpty;
    final hasPpd = checklist.hasPpd;
    final ppdFindings = checklist.depressionScreening.ppdFindings;

    TriageResult? triageResult;
    String? suggestedReferral;
    String? prePopulatedReferralReason;

    if (isRedFlag) {
      suggestedReferral = 'Community Health Centre (CHC) / First Referral Unit (FRU)';
      prePopulatedReferralReason = 'Postpartum Maternal Danger Signs: ${dangerSigns.join("; ")}';

      final triageId = _uuid.v4();
      await _db.into(_db.triageResults).insert(
        TriageResultsCompanion.insert(
          id: triageId,
          encounterId: encounterId,
          flag: 'RED',
          ruleVersionId: '1.0.0',
          findingsJson: jsonEncode([
            {
              'rule_id': 'PNC_MATERNAL_DANGER_SIGNS',
              'severity': 'RED',
              'finding_text': prePopulatedReferralReason,
              'action': 'REFER_TO_FRU_IMMEDIATELY',
              'source_citation': 'Postpartum Care Guidelines, MoHFW',
            }
          ]),
          missingFieldsJson: const Value('[]'),
          escalatedForMissingData: const Value(false),
          evaluatedAt: now,
        ),
      );

      triageResult = TriageResult(
        id: triageId,
        encounterId: encounterId,
        flag: TriageFlag.red,
        ruleFlag: TriageFlag.red,
        ruleVersionId: '1.0.0',
        findings: [
          TriageFinding(
            ruleId: 'PNC_MATERNAL_DANGER_SIGNS',
            severity: TriageFlag.red,
            findingText: prePopulatedReferralReason,
            action: 'REFER_TO_FRU_IMMEDIATELY',
            triggeringValues: {'danger_signs': dangerSigns},
            sourceCitation: 'Postpartum Care Guidelines, MoHFW',
          ),
        ],
        evaluatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );

      if (_syncEngine != null) {
        await _syncEngine.enqueue(
          table: 'alerts',
          recordId: 'alert_pnc_red_$encounterId',
          operation: 'insert',
          priority: SyncPriority.critical,
          payload: {
            'type': 'PNC_MATERNAL_RED_FLAG',
            'mother_id': motherId,
            'danger_signs': dangerSigns,
            'timestamp': now,
          },
        );
      }
    } else if (hasPpd) {
      // Requirement 15.5: Supportive counselling pathway and mental health referral
      suggestedReferral = 'Tele-MANAS (Toll-Free 14416) / PHC Medical Officer Mental Health Counselling';
      prePopulatedReferralReason =
          'Postpartum Depression (PPD) Screening Positive: ${ppdFindings.join("; ")}';

      triageResult = TriageResult(
        id: _uuid.v4(),
        encounterId: encounterId,
        flag: TriageFlag.yellow,
        ruleFlag: TriageFlag.yellow,
        ruleVersionId: '1.0.0',
        findings: [
          TriageFinding(
            ruleId: 'PNC_POSTPARTUM_DEPRESSION',
            severity: TriageFlag.yellow,
            findingText: prePopulatedReferralReason,
            action: 'REFER_TO_MENTAL_HEALTH_COUNSELLOR',
            triggeringValues: {'ppd_findings': ppdFindings},
            sourceCitation: 'MoHFW Maternal Mental Health Guidelines / Tele-MANAS',
          ),
        ],
        evaluatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );
    }

    return PncVisitResult(
      encounterId: encounterId,
      visitScheduleId: visitScheduleId,
      motherId: motherId,
      visitDay: checklist.visitDay,
      isRedFlag: isRedFlag,
      dangerSigns: dangerSigns,
      hasPpd: hasPpd,
      ppdFindings: ppdFindings,
      triageResult: triageResult,
      suggestedReferral: suggestedReferral,
      prePopulatedReferralReason: prePopulatedReferralReason,
    );
  }

  /// 3. Confirms facilitated institutional delivery and writes incentive event (Requirement 15.6, 54.1).
  ///
  /// Activity code: INSTITUTIONAL_DELIVERY_ESCORT (JSY Scheme).
  Future<String?> confirmInstitutionalDelivery({
    required String motherId,
    required String placeOfDelivery,
    required String ashaId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final isInstitutional = placeOfDelivery != 'home';

    if (!isInstitutional) return null;

    final incentiveId = _uuid.v4();
    final idempotencyKey = 'incentive_inst_delivery_$motherId';

    try {
      await _db.into(_db.incentiveEvents).insert(
        IncentiveEventsCompanion.insert(
          id: incentiveId,
          memberId: motherId,
          activityCode: 'INSTITUTIONAL_DELIVERY_ESCORT',
          catalogueVersionId: 'v2024.1',
          eventDate: now,
          status: const Value('eligible'),
          createdAt: now,
          idempotencyKey: idempotencyKey,
          syncStatus: const Value('pending'),
        ),
      );

      if (_syncEngine != null) {
        await _syncEngine.enqueue(
          table: 'incentive_events',
          recordId: incentiveId,
          operation: 'insert',
          priority: SyncPriority.clinical,
          payload: {
            'id': incentiveId,
            'member_id': motherId,
            'activity_code': 'INSTITUTIONAL_DELIVERY_ESCORT',
            'status': 'eligible',
            'event_date': now,
          },
        );
      }
      return incentiveId;
    } catch (_) {
      // Idempotency constraint prevents duplicate claim
      return null;
    }
  }
}

/// Riverpod provider for PncRepository.
final pncRepositoryProvider = Provider<PncRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncEngineProvider);
  return PncRepository(db, sync);
});
