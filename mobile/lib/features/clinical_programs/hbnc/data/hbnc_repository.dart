import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' hide TriageResult;
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/triage/models/models.dart';
import '../../../../shared/providers/core_providers.dart';
import '../domain/hbnc_models.dart';

/// Repository managing Home Based Newborn Care (HBNC) protocols, visit scheduling,
/// clinical checklist observations, danger sign escalation, and incentive completion.
///
/// Implements Requirements 12.1 – 12.7.
class HbncRepository {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;
  static const _uuid = Uuid();

  HbncRepository(this._db, [this._syncEngine]);

  /// 1. Generates HBNC visit schedule upon delivery record (Requirement 12.1, 12.4).
  ///
  /// - Home delivery: Days 1, 3, 7, 14, 21, 28, 42.
  /// - Institutional delivery: Days 3, 7, 14, 21, 28, 42 (Day 1 was in hospital).
  /// - Low Birth Weight (< 2.5 kg) or Preterm: adds high-risk KMC visits on Days 2, 5, 9, 11, 18, 25.
  Future<List<VisitSchedule>> generateSchedule(HbncDeliveryRecord delivery) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final deliveryMs = delivery.deliveryDate.millisecondsSinceEpoch;
    const dayMs = 24 * 60 * 60 * 1000;

    final standardDays = delivery.place == DeliveryPlace.home
        ? [1, 3, 7, 14, 21, 28, 42]
        : [3, 7, 14, 21, 28, 42];

    // High-risk additional visits for LBW or preterm (Requirement 12.4)
    final highRiskDays = delivery.isHighRisk ? [2, 5, 9, 11, 18, 25] : <int>[];

    final allDays = {...standardDays, ...highRiskDays}.toList()..sort();
    final generatedSchedules = <VisitSchedule>[];

    for (final day in allDays) {
      final isHighRiskExtra = highRiskDays.contains(day) && !standardDays.contains(day);
      final targetDueMs = deliveryMs + (day * dayMs);

      // Window margins:
      // Early days (1-3): -0 / +1 day. Mid days (5-14): ±1 day. Late days (18+): -1 / +2 days.
      int windowStartMs;
      int windowEndMs;
      if (day <= 3) {
        windowStartMs = targetDueMs;
        windowEndMs = targetDueMs + (1 * dayMs);
      } else if (day <= 14) {
        windowStartMs = targetDueMs - (1 * dayMs);
        windowEndMs = targetDueMs + (1 * dayMs);
      } else {
        windowStartMs = targetDueMs - (1 * dayMs);
        windowEndMs = targetDueMs + (2 * dayMs);
      }

      final label = isHighRiskExtra
          ? 'HBNC Day $day — High Risk KMC Monitoring'
          : 'HBNC Day $day Visit';

      final taskId = 'hbnc_${delivery.newbornId}_d$day';

      final companion = VisitSchedulesCompanion.insert(
        id: taskId,
        memberId: delivery.newbornId,
        programCode: 'hbnc',
        visitType: label,
        dueDate: targetDueMs,
        dueWindowStart: Value(windowStartMs),
        dueWindowEnd: Value(windowEndMs),
        status: const Value('pending'),
        createdAt: now,
      );

      await _db.into(_db.visitSchedules).insert(
            companion,
            mode: InsertMode.insertOrReplace,
          );

      if (_syncEngine != null) {
        await _syncEngine.enqueue(
          table: 'visit_schedules',
          recordId: taskId,
          operation: 'insert',
          priority: SyncPriority.metadata,
          payload: {
            'id': taskId,
            'member_id': delivery.newbornId,
            'program_code': 'hbnc',
            'visit_type': label,
            'due_date': targetDueMs,
            'due_window_start': windowStartMs,
            'due_window_end': windowEndMs,
            'status': 'pending',
            'created_at': now,
          },
        );
      }

      final created = await (_db.select(_db.visitSchedules)..where((t) => t.id.equals(taskId))).getSingle();
      generatedSchedules.add(created);
    }

    return generatedSchedules;
  }

  /// 2. Records an HBNC visit with full guided clinical observations (Requirements 12.2, 12.3, 12.7).
  Future<HbncVisitResult> recordVisit({
    required String newbornId,
    required String visitScheduleId,
    required HbncChecklistData checklist,
    required String ashaId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    // 1. Create parent clinical encounter
    await _db.into(_db.clinicalEncounters).insert(
          ClinicalEncountersCompanion.insert(
            id: encounterId,
            memberId: newbornId,
            encounterType: 'HBNC',
            programCode: 'hbnc',
            encounterDate: now,
            ashaId: ashaId,
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );

    // 2. Persist all checklist items as discrete ClinicalObservation rows
    final observations = <ClinicalObservationsCompanion>[];

    void addObs({
      required String code,
      String? valueText,
      double? valueNumeric,
      String? valueUnit,
      String? valueEnum,
    }) {
      observations.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: code,
          valueText: Value(valueText),
          valueNumeric: Value(valueNumeric),
          valueUnit: Value(valueUnit),
          valueEnum: Value(valueEnum),
          observedAt: now,
        ),
      );
    }

    if (checklist.currentWeightKg != null) {
      addObs(code: 'WEIGHT_KG', valueNumeric: checklist.currentWeightKg, valueUnit: 'kg');
    }
    if (checklist.temperatureC != null) {
      addObs(code: 'TEMP_C', valueNumeric: checklist.temperatureC, valueUnit: 'celsius');
    }
    if (checklist.respiratoryRate != null) {
      addObs(code: 'RESPIRATORY_RATE', valueNumeric: checklist.respiratoryRate?.toDouble(), valueUnit: 'breaths/min');
    }
    addObs(code: 'CHEST_INDRAWING', valueText: checklist.chestIndrawing ? 'YES' : 'NO');
    addObs(code: 'GRUNTING', valueText: checklist.grunting ? 'YES' : 'NO');
    addObs(code: 'FEEDING_STATUS', valueEnum: checklist.feedingStatus.code, valueText: checklist.feedingStatus.label);
    addObs(code: 'CORD_STATUS', valueEnum: checklist.cordStatus.code, valueText: checklist.cordStatus.label);
    addObs(code: 'SKIN_STATUS', valueEnum: checklist.skinStatus.code, valueText: checklist.skinStatus.label);
    addObs(code: 'EYE_STATUS', valueEnum: checklist.eyeStatus.code, valueText: checklist.eyeStatus.label);
    addObs(code: 'ACTIVITY_STATUS', valueEnum: checklist.activityStatus.code, valueText: checklist.activityStatus.label);
    addObs(code: 'JAUNDICE_STATUS', valueEnum: checklist.jaundiceStatus.code, valueText: checklist.jaundiceStatus.label);
    addObs(code: 'KMC_PRACTICED', valueText: checklist.kmcPracticed ? 'YES' : 'NO');
    if (checklist.kmcHoursPerDay != null) {
      addObs(code: 'KMC_HOURS_PER_DAY', valueNumeric: checklist.kmcHoursPerDay, valueUnit: 'hours/day');
    }
    addObs(code: 'MATERNAL_BLEEDING', valueEnum: checklist.maternalBleeding.code, valueText: checklist.maternalBleeding.label);
    addObs(code: 'MATERNAL_FEVER', valueText: checklist.maternalFever ? 'YES' : 'NO');
    addObs(code: 'MATERNAL_HEADACHE', valueText: checklist.maternalSevereHeadache ? 'YES' : 'NO');
    if (checklist.maternalWoundHealing != null) {
      addObs(code: 'MATERNAL_WOUND', valueText: checklist.maternalWoundHealing);
    }

    for (final obs in observations) {
      await _db.into(_db.clinicalObservations).insert(obs);
    }

    // 3. Update the VisitSchedule row to completed
    await (_db.update(_db.visitSchedules)..where((t) => t.id.equals(visitScheduleId))).write(
      VisitSchedulesCompanion(
        status: const Value('completed'),
        completedAt: Value(now),
        completedEncounterId: Value(encounterId),
      ),
    );

    // 4. Danger Sign Evaluation (Requirement 12.3)
    TriageResult? triageResult;
    final dangerSigns = checklist.newbornDangerSigns;
    final maternalDangerSigns = checklist.maternalDangerSigns;
    final hasDangerSigns = dangerSigns.isNotEmpty || maternalDangerSigns.isNotEmpty;

    if (hasDangerSigns) {
      final allFindings = <TriageFinding>[];
      for (final s in dangerSigns) {
        allFindings.add(
          TriageFinding(
            ruleId: 'HBNC_NEWBORN_DANGER_SIGN',
            severity: TriageFlag.red,
            findingText: s,
            action: 'REFER_IMMEDIATELY_TO_FRU_OR_SNCU',
            triggeringValues: {'danger_sign': s},
          ),
        );
      }
      for (final m in maternalDangerSigns) {
        allFindings.add(
          TriageFinding(
            ruleId: 'HBNC_MATERNAL_POSTPARTUM_DANGER_SIGN',
            severity: TriageFlag.red,
            findingText: m,
            action: 'REFER_IMMEDIATELY_TO_FRU_OR_CHC',
            triggeringValues: {'maternal_danger_sign': m},
          ),
        );
      }

      triageResult = TriageResult(
        id: _uuid.v4(),
        flag: TriageFlag.red,
        ruleFlag: TriageFlag.red,
        ruleVersionId: 'HBNC-1.0.0',
        evaluatedAt: DateTime.now(),
        findings: allFindings,
      );
    }

    // 5. Episode Completion Check (Requirement 12.7)
    // If all required visits for this newborn are completed, write IncentiveEvent HBNC_COMPLETE
    bool episodeCompleted = false;
    IncentiveEvent? incentiveEvent;

    final allMemberVisits = await (_db.select(_db.visitSchedules)
          ..where((t) => t.memberId.equals(newbornId) & t.programCode.equals('hbnc')))
        .get();

    final remainingPending = allMemberVisits.where((v) => v.status == 'pending' || v.status == 'overdue').toList();

    if (remainingPending.isEmpty && allMemberVisits.isNotEmpty) {
      episodeCompleted = true;
      final incentiveId = _uuid.v4();
      final idempotencyKey = 'hbnc_complete_$newbornId';

      final incCompanion = IncentiveEventsCompanion.insert(
        id: incentiveId,
        memberId: newbornId,
        encounterId: Value(encounterId),
        activityCode: 'HBNC_COMPLETE',
        catalogueVersionId: 'NHM_ASHA_2024',
        eventDate: now,
        status: const Value('eligible'),
        idempotencyKey: idempotencyKey,
        createdAt: now,
      );

      await _db.into(_db.incentiveEvents).insert(
            incCompanion,
            mode: InsertMode.insertOrIgnore,
          );

      incentiveEvent = await (_db.select(_db.incentiveEvents)..where((t) => t.id.equals(incentiveId))).getSingleOrNull();

      if (_syncEngine != null) {
        await _syncEngine.enqueue(
          table: 'incentive_events',
          recordId: incentiveId,
          operation: 'insert',
          priority: SyncPriority.clinical,
          payload: {
            'id': incentiveId,
            'member_id': newbornId,
            'encounter_id': encounterId,
            'activity_code': 'HBNC_COMPLETE',
            'event_date': now,
            'status': 'eligible',
            'idempotency_key': idempotencyKey,
          },
        );
      }
    }

    return HbncVisitResult(
      encounterId: encounterId,
      visitScheduleId: visitScheduleId,
      newbornId: newbornId,
      checklist: checklist,
      triageResult: triageResult,
      isEpisodeCompleted: episodeCompleted,
      incentiveEvent: incentiveEvent,
    );
  }

  /// 3. Identifies missed HBNC visits, marks overdue, reschedules within allowed window,
  /// and triggers supervisor escalation alerts (Requirement 12.5).
  Future<List<VisitSchedule>> checkAndRescheduleMissedVisits({int graceDays = 2}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final graceMs = graceDays * 24 * 60 * 60 * 1000;

    final pendingHbncVisits = await (_db.select(_db.visitSchedules)
          ..where((t) => t.programCode.equals('hbnc') & (t.status.equals('pending') | t.status.equals('overdue'))))
        .get();

    final overdueList = <VisitSchedule>[];

    for (final v in pendingHbncVisits) {
      final windowEnd = v.dueWindowEnd ?? v.dueDate;
      if (now > windowEnd) {
        // Visit has lapsed beyond permitted window
        final currentCount = v.rescheduledCount;
        if (currentCount < 1) {
          // Allowed 1st rescheduling within grace window (+2 days)
          final newDueDate = now + graceMs;
          final newWindowEnd = newDueDate + graceMs;

          await (_db.update(_db.visitSchedules)..where((t) => t.id.equals(v.id))).write(
            VisitSchedulesCompanion(
              status: const Value('overdue'),
              dueDate: Value(newDueDate),
              dueWindowEnd: Value(newWindowEnd),
              rescheduledCount: Value(currentCount + 1),
            ),
          );
        } else {
          // Rescheduled window also lapsed -> Mark permanently overdue and alert supervisor (AF)
          await (_db.update(_db.visitSchedules)..where((t) => t.id.equals(v.id))).write(
            const VisitSchedulesCompanion(
              status: Value('overdue'),
            ),
          );

          // Enqueue supervisor alert to sync queue for AF/ANM notification on next sync
          if (_syncEngine != null) {
            await _syncEngine.enqueue(
              table: 'audit_log',
              recordId: _uuid.v4(),
              operation: 'insert',
              priority: SyncPriority.clinical,
              payload: {
                'table_name': 'visit_schedules',
                'record_id': v.id,
                'field_name': 'escalation',
                'old_value': 'overdue',
                'new_value': 'SUPERVISOR_ALERT_MISSED_HBNC',
                'member_id': v.memberId,
                'visit_type': v.visitType,
              },
            );
          }
        }

        final updated = await (_db.select(_db.visitSchedules)..where((t) => t.id.equals(v.id))).getSingle();
        overdueList.add(updated);
      }
    }

    return overdueList;
  }

  /// 4. Records maternal or neonatal death review and alerts AF, ANM, and MO (Requirement 12.6).
  Future<void> recordDeathReview({
    required HbncDeathReview review,
    required String ashaId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    // 1. Update member lifecycle status to deceased
    await (_db.update(_db.members)..where((t) => t.id.equals(review.deceasedMemberId))).write(
      const MembersCompanion(
        lifecycleStatus: Value('deceased'),
      ),
    );

    // 2. Create clinical encounter for death review
    await _db.into(_db.clinicalEncounters).insert(
          ClinicalEncountersCompanion.insert(
            id: encounterId,
            memberId: review.deceasedMemberId,
            encounterType: 'DEATH_REVIEW',
            programCode: 'hbnc',
            encounterDate: now,
            ashaId: ashaId,
            createdAt: now,
            updatedAt: now,
          ),
          mode: InsertMode.insertOrReplace,
        );

    // 3. Store death review clinical observations
    final obs = <ClinicalObservationsCompanion>[
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'DEATH_CATEGORY',
        valueText: Value(review.isNewbornDeath ? 'NEONATAL_DEATH' : 'MATERNAL_DEATH'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'DEATH_DATE',
        valueNumeric: Value(review.deathDate.millisecondsSinceEpoch.toDouble()),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'DEATH_PLACE',
        valueText: Value(review.placeOfDeath),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'PROBABLE_CAUSE',
        valueText: Value(review.probableCause),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'DELAYS_IDENTIFIED',
        valueText: Value(jsonEncode(review.delaysIdentified)),
        observedAt: now,
      ),
    ];

    for (final o in obs) {
      await _db.into(_db.clinicalObservations).insert(o);
    }

    // 4. Cancel any remaining pending visits for deceased member
    await (_db.update(_db.visitSchedules)..where((t) => t.memberId.equals(review.deceasedMemberId))).write(
      const VisitSchedulesCompanion(
        status: Value('cancelled_deceased'),
      ),
    );

    // 5. Enqueue high-priority emergency alert to AF, ANM, and MO (Requirement 12.6)
    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'audit_log',
        recordId: _uuid.v4(),
        operation: 'insert',
        priority: SyncPriority.critical,
        payload: {
          'table_name': 'members',
          'record_id': review.deceasedMemberId,
          'field_name': 'death_review_alert',
          'category': review.isNewbornDeath ? 'NEONATAL_DEATH' : 'MATERNAL_DEATH',
          'probable_cause': review.probableCause,
          'place_of_death': review.placeOfDeath,
          'death_date': review.deathDate.toIso8601String(),
          'alert_recipients': ['AF', 'ANM', 'MO'],
        },
      );
    }
  }

  /// Fetches all HBNC visit schedules for a newborn member.
  Future<List<VisitSchedule>> getMemberHbncVisits(String memberId) async {
    return (_db.select(_db.visitSchedules)
          ..where((t) => t.memberId.equals(memberId) & t.programCode.equals('hbnc'))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .get();
  }
}

/// Result returned after conducting an HBNC visit.
class HbncVisitResult {
  final String encounterId;
  final String visitScheduleId;
  final String newbornId;
  final HbncChecklistData checklist;
  final TriageResult? triageResult;
  final bool isEpisodeCompleted;
  final IncentiveEvent? incentiveEvent;

  const HbncVisitResult({
    required this.encounterId,
    required this.visitScheduleId,
    required this.newbornId,
    required this.checklist,
    this.triageResult,
    required this.isEpisodeCompleted,
    this.incentiveEvent,
  });

  bool get hasDangerSign => triageResult != null && triageResult!.flag == TriageFlag.red;
}

final hbncRepositoryProvider = Provider<HbncRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return HbncRepository(db, syncEngine);
});
