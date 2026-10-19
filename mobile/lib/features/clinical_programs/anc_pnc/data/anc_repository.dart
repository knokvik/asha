import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' hide TriageResult;
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/triage/models/models.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../hbnc/data/hbnc_repository.dart';
import '../../hbnc/domain/hbnc_models.dart';
import '../domain/anc_models.dart';

/// Repository managing Antenatal Care (ANC) protocols, high-risk pregnancy flagging,
/// schedule generation, birth preparedness plans, and pregnancy outcome routing.
///
/// Implements Requirements 14.1 – 14.7.
class AncRepository {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;
  final HbncRepository? _hbncRepository;
  static const _uuid = Uuid();

  AncRepository(this._db, [this._syncEngine, this._hbncRepository]);

  /// 1. Registers a pregnancy, records obstetric history, evaluates baseline high risk,
  /// and generates complete ANC schedule (Requirements 14.1, 14.2, 14.3, 14.4).
  Future<List<VisitSchedule>> registerPregnancy({
    required PregnancyRegistration registration,
    required String ashaId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    // 1. Create registration ClinicalEncounter
    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: registration.womanId,
        encounterType: 'ANC_REGISTRATION',
        programCode: 'anc',
        encounterDate: now,
        ashaId: ashaId,
        status: const Value('completed'),
        createdAt: now,
        updatedAt: now,
        syncStatus: const Value('pending'),
      ),
    );

    // 2. Insert discrete ClinicalObservations for baseline obstetric profile
    final observations = <ClinicalObservationsCompanion>[
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'LMP',
        valueText: Value(registration.lmp.toIso8601String()),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'EDD',
        valueText: Value(registration.edd.toIso8601String()),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'GRAVIDA',
        valueNumeric: Value(registration.gravida.toDouble()),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'PARA',
        valueNumeric: Value(registration.para.toDouble()),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'PREVIOUS_CESAREAN',
        valueEnum: Value(registration.previousCesarean ? 'YES' : 'NO'),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
    ];

    if (registration.bloodGroup != null) {
      observations.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'BLOOD_GROUP',
          valueText: Value(registration.bloodGroup!),
          source: const Value('MANUAL'),
          observedAt: now,
        ),
      );
    }

    if (registration.mcpCardNumber != null) {
      observations.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'MCP_CARD_NUMBER',
          valueText: Value(registration.mcpCardNumber!),
          source: const Value('MANUAL'),
          observedAt: now,
        ),
      );
    }

    for (final obs in observations) {
      await _db.into(_db.clinicalObservations).insert(obs);
    }

    // 3. Update Member's RCH/ABHA identifiers if provided
    if (registration.rchId != null || registration.abhaId != null) {
      await (_db.update(_db.members)..where((t) => t.id.equals(registration.womanId))).write(
        MembersCompanion(
          rchId: registration.rchId != null ? Value(registration.rchId) : const Value.absent(),
          abhaId: registration.abhaId != null ? Value(registration.abhaId) : const Value.absent(),
        ),
      );
    }

    // 4. Generate ANC Schedule (Requirement 14.2)
    // - Contacts: ANC-1 (10 wks), ANC-2 (20 wks), ANC-3 (30 wks), ANC-4 (36 wks)
    // - If High Risk: additional contacts (26 wks, 34 wks, 38 wks) (Requirement 14.4)
    // - Td Doses: Td-1 (10 wks), Td-2 (14 wks)
    // - Supplements: IFA check (14 wks), Calcium check (14 wks)
    // - Birth plan: 34 weeks (Requirement 14.5)
    final lmpMs = registration.lmp.millisecondsSinceEpoch;
    const weekMs = 7 * 24 * 60 * 60 * 1000;

    final standardContactWeeks = [10, 20, 30, 36];
    final isHighRisk = registration.isBaselineHighRisk;
    final highRiskExtraWeeks = isHighRisk ? [26, 34, 38] : <int>[];

    final allContactWeeks = {...standardContactWeeks, ...highRiskExtraWeeks}.toList()..sort();
    final generatedSchedules = <VisitSchedule>[];

    for (final week in allContactWeeks) {
      final isExtra = highRiskExtraWeeks.contains(week) && !standardContactWeeks.contains(week);
      final targetDueMs = lmpMs + (week * weekMs);
      final taskId = 'anc_${registration.womanId}_w$week';

      final title = isExtra
          ? 'ANC High-Risk Review ($week Weeks Gestation)'
          : (week == 30
              ? 'ANC Contact 3 ($week Weeks) — Review & Birth Plan Preparation'
              : 'ANC Contact ($week Weeks Gestation)');

      // Window margins: ±14 days
      final windowStartMs = targetDueMs - (14 * 24 * 60 * 60 * 1000);
      final windowEndMs = targetDueMs + (14 * 24 * 60 * 60 * 1000);

      final companion = VisitSchedulesCompanion.insert(
        id: taskId,
        memberId: registration.womanId,
        programCode: 'anc',
        visitType: title,
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
            'member_id': registration.womanId,
            'program_code': 'anc',
            'visit_type': title,
            'due_date': targetDueMs,
            'status': 'pending',
          },
        );
      }

      final created = await (_db.select(_db.visitSchedules)..where((t) => t.id.equals(taskId))).getSingle();
      generatedSchedules.add(created);
    }

    // Schedule Td-1 and Td-2 doses
    final td1Ms = lmpMs + (10 * weekMs);
    final td2Ms = td1Ms + (4 * weekMs); // 4 weeks after Td-1

    final td1Companion = VisitSchedulesCompanion.insert(
      id: 'anc_td1_${registration.womanId}',
      memberId: registration.womanId,
      programCode: 'anc',
      visitType: 'Td-1 Vaccination Contact (Early Pregnancy)',
      dueDate: td1Ms,
      dueWindowStart: Value(td1Ms - (14 * 24 * 60 * 60 * 1000)),
      dueWindowEnd: Value(td1Ms + (14 * 24 * 60 * 60 * 1000)),
      status: const Value('pending'),
      createdAt: now,
    );
    await _db.into(_db.visitSchedules).insert(td1Companion, mode: InsertMode.insertOrReplace);

    final td2Companion = VisitSchedulesCompanion.insert(
      id: 'anc_td2_${registration.womanId}',
      memberId: registration.womanId,
      programCode: 'anc',
      visitType: 'Td-2 Vaccination Contact (4 weeks after Td-1)',
      dueDate: td2Ms,
      dueWindowStart: Value(td2Ms - (14 * 24 * 60 * 60 * 1000)),
      dueWindowEnd: Value(td2Ms + (14 * 24 * 60 * 60 * 1000)),
      status: const Value('pending'),
      createdAt: now,
    );
    await _db.into(_db.visitSchedules).insert(td2Companion, mode: InsertMode.insertOrReplace);

    // Schedule Birth Plan prompt at 34 weeks (Requirement 14.5)
    final birthPlanDueMs = lmpMs + (34 * weekMs);
    final birthPlanCompanion = VisitSchedulesCompanion.insert(
      id: 'anc_birthplan_${registration.womanId}',
      memberId: registration.womanId,
      programCode: 'anc',
      visitType: 'Birth Preparedness & Complication Readiness Plan (34 Weeks)',
      dueDate: birthPlanDueMs,
      dueWindowStart: Value(birthPlanDueMs - (7 * 24 * 60 * 60 * 1000)),
      dueWindowEnd: Value(birthPlanDueMs + (14 * 24 * 60 * 60 * 1000)),
      status: const Value('pending'),
      createdAt: now,
    );
    await _db.into(_db.visitSchedules).insert(birthPlanCompanion, mode: InsertMode.insertOrReplace);

    final createdTd1 = await (_db.select(_db.visitSchedules)..where((t) => t.id.equals('anc_td1_${registration.womanId}'))).getSingle();
    generatedSchedules.add(createdTd1);

    final createdTd2 = await (_db.select(_db.visitSchedules)..where((t) => t.id.equals('anc_td2_${registration.womanId}'))).getSingle();
    generatedSchedules.add(createdTd2);

    final createdBirthPlan = await (_db.select(_db.visitSchedules)..where((t) => t.id.equals('anc_birthplan_${registration.womanId}'))).getSingle();
    generatedSchedules.add(createdBirthPlan);

    // 5. If High-Risk at baseline, enqueue alert for ANM & AF (Requirement 14.4)
    if (isHighRisk && _syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'alerts',
        recordId: 'alert_hrp_${registration.womanId}',
        operation: 'insert',
        priority: SyncPriority.critical,
        payload: {
          'type': 'HIGH_RISK_PREGNANCY_ALERT',
          'woman_id': registration.womanId,
          'reasons': registration.baselineHighRiskReasons,
          'lmp': registration.lmp.toIso8601String(),
          'edd': registration.edd.toIso8601String(),
          'timestamp': now,
        },
      );
    }

    return generatedSchedules;
  }

  /// 2. Records an ANC contact with clinical observations, high-risk triage,
  /// and birth plan readiness prompt (Requirements 14.2, 14.3, 14.4, 14.5).
  Future<AncVisitResult> recordAncVisit({
    required String womanId,
    required String visitScheduleId,
    required AncContactData visitData,
    required String ashaId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    // 1. Create ClinicalEncounter
    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: womanId,
        encounterType: 'ANC_CONTACT',
        programCode: 'anc',
        encounterDate: now,
        ashaId: ashaId,
        status: const Value('completed'),
        visitNotes: Value(visitData.generalNotes),
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
        observationCode: 'GESTATION_WEEKS',
        valueNumeric: Value(visitData.gestationWeeks.toDouble()),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'FETAL_MOVEMENT',
        valueEnum: Value(visitData.fetalMovementPresent ? 'PRESENT' : 'ABSENT'),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'IFA_SUPPLEMENTATION',
        valueNumeric: Value(visitData.ifaCount.toDouble()),
        valueEnum: Value(visitData.ifaTabletsGiven ? 'GIVEN' : 'NOT_GIVEN'),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
    ];

    if (visitData.weightKg != null) {
      observations.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'WEIGHT',
          valueNumeric: Value(visitData.weightKg!),
          valueUnit: const Value('kg'),
          source: const Value('MANUAL'),
          observedAt: now,
        ),
      );
    }

    if (visitData.systolicBp != null && visitData.diastolicBp != null) {
      observations.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'BLOOD_PRESSURE',
          valueText: Value('${visitData.systolicBp}/${visitData.diastolicBp}'),
          valueNumeric: Value(visitData.systolicBp!.toDouble()),
          valueUnit: const Value('mmHg'),
          source: const Value('MANUAL'),
          observedAt: now,
        ),
      );
    }

    if (visitData.haemoglobin != null) {
      observations.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'HAEMOGLOBIN',
          valueNumeric: Value(visitData.haemoglobin!),
          valueUnit: const Value('g/dL'),
          source: const Value('MANUAL'),
          observedAt: now,
        ),
      );
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

    // 4. High-Risk Pregnancy & Danger Sign Evaluation (Requirement 14.3)
    final dangerSigns = visitData.clinicalDangerSigns;
    final moderateSigns = visitData.moderateRiskSigns;
    final isRedFlag = dangerSigns.isNotEmpty;
    final isHighRisk = isRedFlag || moderateSigns.isNotEmpty;
    final allRiskReasons = [...dangerSigns, ...moderateSigns];

    TriageResult? triageResult;
    String? suggestedReferralFacility;
    String? prePopulatedReferralReason;

    if (isRedFlag) {
      suggestedReferralFacility = 'Community Health Centre (CHC) / District Hospital (FRU)';
      prePopulatedReferralReason = 'High-Risk Pregnancy Danger Signs: ${dangerSigns.join("; ")}';

      final triageId = _uuid.v4();
      await _db.into(_db.triageResults).insert(
        TriageResultsCompanion.insert(
          id: triageId,
          encounterId: encounterId,
          flag: 'RED',
          ruleVersionId: '1.0.0',
          findingsJson: jsonEncode([
            {
              'rule_id': 'ANC_DANGER_SIGNS',
              'severity': 'RED',
              'finding_text': prePopulatedReferralReason,
              'action': 'REFER_TO_FRU_IMMEDIATELY',
              'source_citation': 'Pradhan Mantri Surakshit Matritva Abhiyan (PMSMA), MoHFW',
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
            ruleId: 'ANC_DANGER_SIGNS',
            severity: TriageFlag.red,
            findingText: prePopulatedReferralReason,
            action: 'REFER_TO_FRU_IMMEDIATELY',
            triggeringValues: {'danger_signs': dangerSigns},
            sourceCitation: 'Pradhan Mantri Surakshit Matritva Abhiyan (PMSMA), MoHFW',
          ),
        ],
        evaluatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );

      // Enqueue critical sync alert for ANM & AF (Requirement 14.4)
      if (_syncEngine != null) {
        await _syncEngine.enqueue(
          table: 'alerts',
          recordId: 'alert_red_anc_$encounterId',
          operation: 'insert',
          priority: SyncPriority.critical,
          payload: {
            'type': 'ANC_RED_FLAG_ALERT',
            'woman_id': womanId,
            'encounter_id': encounterId,
            'danger_signs': dangerSigns,
            'timestamp': now,
          },
        );
      }
    } else if (moderateSigns.isNotEmpty) {
      suggestedReferralFacility = 'Primary Health Centre (PHC) / PMSMA Clinic';
      prePopulatedReferralReason = 'ANC Moderate High-Risk Signs: ${moderateSigns.join("; ")}';

      triageResult = TriageResult(
        id: _uuid.v4(),
        encounterId: encounterId,
        flag: TriageFlag.yellow,
        ruleFlag: TriageFlag.yellow,
        ruleVersionId: '1.0.0',
        findings: [
          TriageFinding(
            ruleId: 'ANC_MODERATE_HIGH_RISK',
            severity: TriageFlag.yellow,
            findingText: prePopulatedReferralReason,
            action: 'SCHEDULE_PMSMA_CLINIC_VISIT',
            triggeringValues: {'risk_factors': moderateSigns},
            sourceCitation: 'PMSMA Guidelines, MoHFW',
          ),
        ],
        evaluatedAt: DateTime.fromMillisecondsSinceEpoch(now),
      );
    }

    // 5. Birth plan prompt at 34 weeks (Requirement 14.5)
    final birthPlanPromptNeeded = visitData.gestationWeeks >= 34;

    return AncVisitResult(
      encounterId: encounterId,
      visitScheduleId: visitScheduleId,
      womanId: womanId,
      contactNumber: visitData.contactNumber,
      isHighRisk: isHighRisk,
      highRiskReasons: allRiskReasons,
      isRedFlag: isRedFlag,
      triageResult: triageResult,
      birthPlanPromptNeeded: birthPlanPromptNeeded,
      suggestedReferralFacility: suggestedReferralFacility,
      prePopulatedReferralReason: prePopulatedReferralReason,
    );
  }

  /// 3. Records Birth Preparedness & Complication Readiness Plan at 34 weeks (Requirement 14.5).
  Future<String> recordBirthPlan({
    required BirthPlan plan,
    required String ashaId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: plan.womanId,
        encounterType: 'BIRTH_PLAN',
        programCode: 'anc',
        encounterDate: now,
        ashaId: ashaId,
        status: const Value('completed'),
        createdAt: now,
        updatedAt: now,
        syncStatus: const Value('pending'),
      ),
    );

    final observations = [
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'DELIVERY_FACILITY',
        valueText: Value('${plan.chosenDeliveryFacility} (${plan.facilityType})'),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'TRANSPORT_ARRANGEMENT',
        valueText: Value(plan.transportArrangement),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'NAMED_ESCORT',
        valueText: Value('${plan.namedEscortName} (${plan.escortRelationship}) - ${plan.namedEscortPhone}'),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'BLOOD_DONOR',
        valueText: Value(
          plan.bloodDonorName != null
              ? '${plan.bloodDonorName} (${plan.bloodDonorGroup ?? "unknown"}) - ${plan.bloodDonorPhone}'
              : 'None identified yet',
        ),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'EMERGENCY_SAVINGS_CONFIRMED',
        valueEnum: Value(plan.emergencySavingsConfirmed ? 'YES' : 'NO'),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
    ];

    for (final obs in observations) {
      await _db.into(_db.clinicalObservations).insert(obs);
    }

    // Mark birth plan visit schedule completed
    await (_db.update(_db.visitSchedules)
          ..where((t) => t.id.equals('anc_birthplan_${plan.womanId}')))
        .write(
      VisitSchedulesCompanion(
        status: const Value('completed'),
        completedAt: Value(now),
        completedEncounterId: Value(encounterId),
      ),
    );

    return encounterId;
  }

  /// 4. Records pregnancy outcome and triggers downstream PNC, HBNC, or Death Review (Requirement 14.7).
  Future<Map<String, dynamic>> recordPregnancyOutcome({
    required PregnancyOutcome outcome,
    required String ashaId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    // 1. Create outcome encounter
    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: outcome.womanId,
        encounterType: 'PREGNANCY_OUTCOME',
        programCode: 'anc',
        encounterDate: now,
        ashaId: ashaId,
        status: const Value('completed'),
        visitNotes: Value(outcome.complicationsNotes),
        createdAt: now,
        updatedAt: now,
        syncStatus: const Value('pending'),
      ),
    );

    // 2. Observations for delivery outcome
    final observations = [
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'PREGNANCY_OUTCOME_TYPE',
        valueEnum: Value(outcome.outcomeType.code),
        valueText: Value(outcome.outcomeType.label),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'PLACE_OF_DELIVERY',
        valueText: Value(outcome.placeOfDelivery),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'DELIVERY_TYPE',
        valueText: Value(outcome.deliveryType),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
    ];

    if (outcome.birthWeightKg != null) {
      observations.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'BIRTH_WEIGHT',
          valueNumeric: Value(outcome.birthWeightKg!),
          valueUnit: const Value('kg'),
          source: const Value('MANUAL'),
          observedAt: now,
        ),
      );
    }

    for (final obs in observations) {
      await _db.into(_db.clinicalObservations).insert(obs);
    }

    // 3. Cancel remaining pending or overdue ANC visits
    await (_db.update(_db.visitSchedules)
          ..where((t) =>
              t.memberId.equals(outcome.womanId) &
              t.programCode.equals('anc') &
              (t.status.equals('pending') | t.status.equals('overdue'))))
        .write(
      const VisitSchedulesCompanion(
        status: Value('cancelled'),
        skipReason: Value('Pregnancy concluded'),
      ),
    );

    final downstreamResults = <String, dynamic>{
      'encounter_id': encounterId,
      'outcome_type': outcome.outcomeType.code,
    };

    // 4. Downstream routing (Requirement 14.7)
    if (outcome.isLiveBirth) {
      // Trigger HBNC schedule generation if HbncRepository is supplied
      String? newbornId;
      // Fetch mother's household to link newborn
      final mother = await (_db.select(_db.members)..where((t) => t.id.equals(outcome.womanId))).getSingle();

      newbornId = 'nb_${outcome.womanId}_${now % 100000}';
      await _db.into(_db.members).insert(
        MembersCompanion.insert(
          id: newbornId,
          householdId: mother.householdId,
          name: 'Baby of ${mother.name}',
          sex: outcome.newbornSex ?? 'M',
          dobApprox: Value(outcome.outcomeDate.millisecondsSinceEpoch),
          relationshipToHead: const Value('Child'),
          createdAt: now,
          updatedAt: now,
          createdBy: ashaId,
        ),
      );

      downstreamResults['newborn_id'] = newbornId;

      if (_hbncRepository != null) {
        final deliveryPlace = outcome.placeOfDelivery == 'home'
            ? DeliveryPlace.home
            : DeliveryPlace.institutionalPhc;

        final hbncRecord = HbncDeliveryRecord(
          newbornId: newbornId,
          motherId: outcome.womanId,
          householdId: mother.householdId,
          deliveryDate: outcome.outcomeDate,
          place: deliveryPlace,
          deliveryType: DeliveryType.normalVaginal,
          birthWeightKg: outcome.birthWeightKg ?? 2.8,
          gestationalAgeWeeks: outcome.gestationalWeeksAtDelivery ?? 40,
          ashaId: ashaId,
        );

        final hbncSchedules = await _hbncRepository.generateSchedule(hbncRecord);
        downstreamResults['hbnc_visits_scheduled'] = hbncSchedules.length;
      }
    } else if (outcome.outcomeType == PregnancyOutcomeType.maternalDeath) {
      // Launch death review alert
      if (_syncEngine != null) {
        await _syncEngine.enqueue(
          table: 'alerts',
          recordId: 'alert_mat_death_${outcome.womanId}',
          operation: 'insert',
          priority: SyncPriority.critical,
          payload: {
            'type': 'MATERNAL_DEATH_REVIEW_REQUIRED',
            'woman_id': outcome.womanId,
            'outcome_date': outcome.outcomeDate.toIso8601String(),
            'notes': outcome.complicationsNotes,
            'timestamp': now,
          },
        );
      }
      downstreamResults['death_review_alert_enqueued'] = true;
    }

    return downstreamResults;
  }

  /// 5. Overdue ANC contact tracking (Requirement 14.6).
  Future<List<String>> checkAndMarkOverdueVisits(String womanId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final overdueSchedules = await (_db.select(_db.visitSchedules)
          ..where((t) =>
              t.memberId.equals(womanId) &
              t.programCode.equals('anc') &
              t.status.equals('pending') &
              t.dueWindowEnd.isSmallerThanValue(now)))
        .get();

    final overdueIds = <String>[];
    for (final schedule in overdueSchedules) {
      overdueIds.add(schedule.id);
      await (_db.update(_db.visitSchedules)..where((t) => t.id.equals(schedule.id))).write(
        const VisitSchedulesCompanion(
          status: Value('overdue'),
        ),
      );
    }
    return overdueIds;
  }
}

/// Riverpod provider for AncRepository.
final ancRepositoryProvider = Provider<AncRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncEngineProvider);
  final hbnc = ref.watch(hbncRepositoryProvider);
  return AncRepository(db, sync, hbnc);
});
