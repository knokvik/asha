import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' hide TriageResult;
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/triage/models/models.dart';
import '../../../../shared/providers/core_providers.dart';
import '../domain/hbyc_models.dart';

/// Repository managing Home Based Care for Young Child (HBYC) protocols,
/// visit scheduling at 3, 6, 9, 12, 15 months, developmental milestone evaluation,
/// SAM detection & nutrition pathway triggers, and incentive events.
///
/// Implements Requirements 13.1 – 13.5.
class HbycRepository {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;
  static const _uuid = Uuid();

  HbycRepository(this._db, [this._syncEngine]);

  /// 1. Generates HBYC visit schedule upon infant registration or HBNC graduation (Requirement 13.1).
  ///
  /// Schedules visits at 3, 6, 9, 12, and 15 months (NHSRC HBYC guideline).
  Future<List<VisitSchedule>> generateSchedule({
    required String childId,
    required DateTime dob,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final dobMs = dob.millisecondsSinceEpoch;
    const dayMs = 24 * 60 * 60 * 1000;

    final generatedSchedules = <VisitSchedule>[];

    for (final milestone in HbycMilestone.values) {
      final targetDueMs = dobMs + (milestone.ageInDays * dayMs);

      // Window margins for young child visits: ±15 days
      final windowStartMs = targetDueMs - (15 * dayMs);
      final windowEndMs = targetDueMs + (15 * dayMs);

      final taskId = 'hbyc_${childId}_${milestone.code}';

      final companion = VisitSchedulesCompanion.insert(
        id: taskId,
        memberId: childId,
        programCode: 'hbyc',
        visitType: milestone.visitTitle,
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
            'member_id': childId,
            'program_code': 'hbyc',
            'visit_type': milestone.visitTitle,
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

  /// 2. Records an HBYC visit with full clinical observations, developmental milestones,
  /// SAM detection, referral suggestions, and incentive events (Requirements 13.2 – 13.5).
  Future<HbycVisitResult> recordVisit({
    required String childId,
    required String visitScheduleId,
    required HbycChecklistData checklist,
    required String ashaId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    // 1. Create ClinicalEncounter record
    final encounterCompanion = ClinicalEncountersCompanion.insert(
      id: encounterId,
      memberId: childId,
      encounterType: 'HBYC',
      programCode: 'hbyc',
      encounterDate: now,
      ashaId: ashaId,
      status: const Value('completed'),
      visitNotes: Value(checklist.generalNotes),
      createdAt: now,
      updatedAt: now,
      syncStatus: const Value('pending'),
    );
    await _db.into(_db.clinicalEncounters).insert(encounterCompanion);

    // 2. Insert discrete ClinicalObservations
    final observations = <ClinicalObservationsCompanion>[
      // Weight
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'WEIGHT',
        valueNumeric: Value(checklist.growth.weightKg),
        valueUnit: const Value('kg'),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      // Feeding practice
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'FEEDING_PRACTICE',
        valueEnum: Value(checklist.feedingPractice.code),
        valueText: Value(checklist.feedingPractice.label),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      // Immunization check
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'IMMUNIZATION_STATUS',
        valueEnum: Value(checklist.immunizationUpToDate ? 'UP_TO_DATE' : 'DEFICIT'),
        valueText: Value(checklist.missingVaccinesNotes),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      // Bilateral oedema check
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'BILATERAL_OEDEMA',
        valueEnum: Value(checklist.growth.hasBilateralOedema ? 'YES' : 'NO'),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      // Developmental milestones summary
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'DEVELOPMENTAL_MILESTONES',
        valueEnum: Value(checklist.hasMilestoneDelay ? 'DELAY_DETECTED' : 'NORMAL_DEVELOPMENT'),
        valueText: Value(jsonEncode(checklist.milestoneAchievements)),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      // Responsive caregiving & counselling
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'RESPONSIVE_CAREGIVING_COUNSELING',
        valueEnum: const Value('COMPLETED'),
        valueText: Value(
          'counselled:${checklist.responsiveCaregivingCounseled};wash:${checklist.hygieneWashCounseled};storyboard:${checklist.storyboardShown};audio:${checklist.audioMessagePlayed}',
        ),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
    ];

    if (checklist.growth.lengthCm != null) {
      observations.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'LENGTH',
          valueNumeric: Value(checklist.growth.lengthCm),
          valueUnit: const Value('cm'),
          source: const Value('MANUAL'),
          observedAt: now,
        ),
      );
    }

    if (checklist.growth.muacCm != null) {
      observations.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'MUAC',
          valueNumeric: Value(checklist.growth.muacCm),
          valueUnit: const Value('cm'),
          source: const Value('MANUAL'),
          observedAt: now,
        ),
      );
    }

    if (checklist.complementaryFeedingStarted) {
      observations.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'COMPLEMENTARY_FEEDING',
          valueText: Value(
            'mealsPerDay:${checklist.mealsPerDay};foodGroups:${checklist.foodGroupsCount};handwash:${checklist.washedHandsBeforeFeeding}',
          ),
          source: const Value('MANUAL'),
          observedAt: now,
        ),
      );
    }

    for (final obs in observations) {
      await _db.into(_db.clinicalObservations).insert(obs);
    }

    // 3. Mark VisitSchedule as completed
    await (_db.update(_db.visitSchedules)..where((t) => t.id.equals(visitScheduleId))).write(
      VisitSchedulesCompanion(
        status: const Value('completed'),
        completedAt: Value(now),
        completedEncounterId: Value(encounterId),
      ),
    );

    // 4. Evaluate SAM & Danger Signs (Requirements 13.3, 13.4)
    final isSam = checklist.isSam;
    final isMam = checklist.isMam;
    final hasMilestoneDelay = checklist.hasMilestoneDelay;
    final delayedMilestones = checklist.delayedMilestones;
    final delayedMilestoneNames = delayedMilestones.map((e) => '${e.domain}: ${e.prompt}').toList();

    String? suggestedReferralDestination;
    String? prePopulatedReferralReason;
    final isRedFlag = checklist.hasRedFlag;
    TriageResult? triageResult;

    if (isSam) {
      // Requirement 13.4: Auto-trigger nutrition pathway for SAM
      suggestedReferralDestination = 'Nutritional Rehabilitation Centre (NRC) / First Referral Unit (FRU)';
      final samDetails = <String>[];
      if (checklist.growth.muacCm != null && checklist.growth.muacCm! < 11.5) {
        samDetails.add('MUAC ${checklist.growth.muacCm} cm (< 11.5 cm threshold)');
      }
      if (checklist.growth.hasBilateralOedema) {
        samDetails.add('Bilateral pitting oedema of feet/legs');
      }
      if (checklist.growth.hasSevereWasting) {
        samDetails.add('Visible severe muscle wasting');
      }
      if (!checklist.growth.appetiteTestPassed) {
        samDetails.add('Appetite test failed / Unable to consume home feed');
      }
      prePopulatedReferralReason = 'Severe Acute Malnutrition (SAM) at ${checklist.milestone.label} visit: ${samDetails.join(', ')}';

      // Persist RED triage result
      final triageId = _uuid.v4();
      await _db.into(_db.triageResults).insert(
        TriageResultsCompanion.insert(
          id: triageId,
          encounterId: encounterId,
          flag: 'RED',
          ruleVersionId: '1.0.0',
          findingsJson: jsonEncode([
            {
              'rule_id': 'CHILD_SAM_NUTRITION_PATHWAY',
              'severity': 'RED',
              'finding_text': prePopulatedReferralReason,
              'action': 'REFER_TO_NRC_IMMEDIATELY',
              'source_citation': 'Facility Based Management of SAM Operational Guidelines, MoHFW',
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
            ruleId: 'CHILD_SAM_NUTRITION_PATHWAY',
            severity: TriageFlag.red,
            findingText: prePopulatedReferralReason,
            action: 'REFER_TO_NRC_IMMEDIATELY',
            triggeringValues: {
              'muac': checklist.growth.muacCm,
              'oedema': checklist.growth.hasBilateralOedema,
            },
            sourceCitation: 'Facility Based Management of SAM Operational Guidelines, MoHFW',
          ),
        ],
        evaluatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );
    } else if (checklist.clinicalDangerSigns.isNotEmpty) {
      suggestedReferralDestination = 'Primary Health Centre (PHC) / Community Health Centre (CHC)';
      prePopulatedReferralReason = 'HBYC Danger Signs: ${checklist.clinicalDangerSigns.join('; ')}';

      final triageId = _uuid.v4();
      await _db.into(_db.triageResults).insert(
        TriageResultsCompanion.insert(
          id: triageId,
          encounterId: encounterId,
          flag: 'RED',
          ruleVersionId: '1.0.0',
          findingsJson: jsonEncode([
            {
              'rule_id': 'CHILD_ACUTE_DANGER_SIGNS',
              'severity': 'RED',
              'finding_text': prePopulatedReferralReason,
              'action': 'REFER_IMMEDIATELY',
              'source_citation': 'IMNCI Chart Booklet, MoHFW',
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
            ruleId: 'CHILD_ACUTE_DANGER_SIGNS',
            severity: TriageFlag.red,
            findingText: prePopulatedReferralReason,
            action: 'REFER_IMMEDIATELY',
            triggeringValues: {'danger_signs': checklist.clinicalDangerSigns},
            sourceCitation: 'IMNCI Chart Booklet, MoHFW',
          ),
        ],
        evaluatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );
    } else if (hasMilestoneDelay) {
      // Requirement 13.3: Suggest referral to Anganwadi / RBSK / DEIC with pre-populated reason
      suggestedReferralDestination = 'RBSK / District Early Intervention Centre (DEIC) or Anganwadi';
      prePopulatedReferralReason =
          'Developmental delay observed at ${checklist.milestone.label} HBYC assessment: ${delayedMilestoneNames.join('; ')}';

      triageResult = TriageResult(
        id: _uuid.v4(),
        encounterId: encounterId,
        flag: TriageFlag.yellow,
        ruleFlag: TriageFlag.yellow,
        ruleVersionId: '1.0.0',
        findings: [
          TriageFinding(
            ruleId: 'HBYC_DEVELOPMENTAL_DELAY',
            severity: TriageFlag.yellow,
            findingText: prePopulatedReferralReason,
            action: 'REFER_TO_RBSK_DEIC',
            triggeringValues: {'delayed_milestones': delayedMilestoneNames},
            sourceCitation: 'RBSK / HBYC Operational Guidelines, MoHFW',
          ),
        ],
        evaluatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );
    }

    // 5. Incentive Generation (Requirement 54 / HBYC Guidelines)
    String? incentiveEventId;
    bool incentiveEligible = false;

    // Check completed count
    final completedCountQuery = _db.select(_db.visitSchedules)
      ..where((t) => t.memberId.equals(childId) & t.programCode.equals('hbyc') & t.status.equals('completed'));
    final completedSchedules = await completedCountQuery.get();

    final isAllCompleted = completedSchedules.length >= HbycMilestone.values.length;
    final activityCode = isAllCompleted ? 'HBYC_COMPLETE' : 'HBYC_VISIT';

    incentiveEventId = _uuid.v4();
    final idempotencyKey = 'incentive_${childId}_${visitScheduleId}_$activityCode';

    try {
      await _db.into(_db.incentiveEvents).insert(
        IncentiveEventsCompanion.insert(
          id: incentiveEventId,
          memberId: childId,
          encounterId: Value(encounterId),
          activityCode: activityCode,
          catalogueVersionId: 'v2024.1',
          eventDate: now,
          status: const Value('eligible'),
          createdAt: now,
          idempotencyKey: idempotencyKey,
          syncStatus: const Value('pending'),
        ),
      );
      incentiveEligible = true;

      if (_syncEngine != null) {
        await _syncEngine.enqueue(
          table: 'incentive_events',
          recordId: incentiveEventId,
          operation: 'insert',
          priority: SyncPriority.clinical,
          payload: {
            'id': incentiveEventId,
            'member_id': childId,
            'encounter_id': encounterId,
            'activity_code': activityCode,
            'status': 'eligible',
            'event_date': now,
          },
        );
      }
    } catch (_) {
      // If already recorded with idempotency key, keep existing
    }

    // Enqueue encounter & observations to sync queue
    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'clinical_encounters',
        recordId: encounterId,
        operation: 'insert',
        priority: isRedFlag ? SyncPriority.critical : SyncPriority.clinical,
        payload: {
          'id': encounterId,
          'member_id': childId,
          'encounter_type': 'HBYC',
          'program_code': 'hbyc',
          'encounter_date': now,
          'asha_id': ashaId,
          'status': 'completed',
        },
      );
    }

    return HbycVisitResult(
      encounterId: encounterId,
      visitScheduleId: visitScheduleId,
      childId: childId,
      milestone: checklist.milestone,
      isSam: isSam,
      isMam: isMam,
      hasMilestoneDelay: hasMilestoneDelay,
      delayedMilestoneNames: delayedMilestoneNames,
      suggestedReferralDestination: suggestedReferralDestination,
      prePopulatedReferralReason: prePopulatedReferralReason,
      isRedFlag: isRedFlag,
      triageResult: triageResult,
      incentiveEligible: incentiveEligible,
      incentiveEventId: incentiveEventId,
    );
  }

  /// 3. Overdue tracking and rescheduling within grace window (Requirement 13.1, 24.3).
  Future<List<String>> checkAndRescheduleMissedVisits(String childId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final overdueSchedules = await (_db.select(_db.visitSchedules)
          ..where((t) =>
              t.memberId.equals(childId) &
              t.programCode.equals('hbyc') &
              (t.status.equals('pending') | t.status.equals('overdue')) &
              t.dueWindowEnd.isSmallerThanValue(now)))
        .get();

    final escalatedTaskIds = <String>[];
    const graceWindowMs = 14 * 24 * 60 * 60 * 1000; // 14-day grace window

    for (final schedule in overdueSchedules) {
      final newRescheduledCount = schedule.rescheduledCount + 1;

      if (newRescheduledCount >= 2) {
        // Repeated lapse: escalate alert for ASHA Facilitator (AF)
        escalatedTaskIds.add(schedule.id);
        if (_syncEngine != null) {
          await _syncEngine.enqueue(
            table: 'alerts',
            recordId: 'alert_missed_${schedule.id}',
            operation: 'insert',
            priority: SyncPriority.critical,
            payload: {
              'type': 'MISSED_HBYC_VISIT_ESCALATION',
              'child_id': childId,
              'schedule_id': schedule.id,
              'visit_type': schedule.visitType,
              'rescheduled_count': newRescheduledCount,
              'timestamp': now,
            },
          );
        }
      }

      // Reschedule visit within grace window
      await (_db.update(_db.visitSchedules)..where((t) => t.id.equals(schedule.id))).write(
        VisitSchedulesCompanion(
          status: const Value('overdue'),
          dueWindowEnd: Value(now + graceWindowMs),
          rescheduledCount: Value(newRescheduledCount),
        ),
      );
    }

    return escalatedTaskIds;
  }

  /// 4. Retrieves all HBYC schedules for a beneficiary.
  Future<List<VisitSchedule>> getSchedulesForChild(String childId) async {
    return (_db.select(_db.visitSchedules)
          ..where((t) => t.memberId.equals(childId) & t.programCode.equals('hbyc'))
          ..orderBy([(t) => OrderingTerm(expression: t.dueDate)]))
        .get();
  }
}

/// Riverpod provider for HbycRepository.
final hbycRepositoryProvider = Provider<HbycRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncEngineProvider);
  return HbycRepository(db, sync);
});
