import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' hide TriageResult;
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/triage/models/models.dart';
import '../../../../shared/providers/core_providers.dart';
import '../domain/cbac_calculator.dart';
import '../domain/cbac_models.dart';

/// Repository managing Community Based Assessment Checklist (CBAC) screenings,
/// NCD triage, chronic care registration (Hypertension & Diabetes), medication
/// refill tracking, overdue tracing, and National NCD portal export.
///
/// Implements Requirements 19.1 – 19.7.
class NcdRepository {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;
  static const _uuid = Uuid();

  NcdRepository(this._db, [this._syncEngine]);

  // ── 1. CBAC Screening & Triage (Requirement 19.1 – 19.3) ───────────────────

  /// Records a complete CBAC assessment, classifies risk & clinical measurements offline,
  /// records discrete clinical observations, generates referrals, schedules follow-ups,
  /// and writes incentive events.
  Future<CbacAssessment> recordCbacScreening({
    required String memberId,
    required TobaccoUse tobaccoUse,
    required AlcoholConsumption alcoholConsumption,
    required double waistCircumferenceCm,
    required PhysicalActivity physicalActivity,
    required FamilyHistoryNcd familyHistory,
    required CancerWarningSigns warningSigns,
    int? systolicBp,
    int? diastolicBp,
    double? bloodGlucoseMgDl,
    GlucoseType? glucoseType,
    required String ashaId,
    DateTime? screenedAt,
  }) async {
    final now = screenedAt ?? DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    // 1. Fetch beneficiary details
    final member = await (_db.select(
      _db.members,
    )..where((t) => t.id.equals(memberId))).getSingle();
    final dob = member.dobApprox != null
        ? DateTime.fromMillisecondsSinceEpoch(member.dobApprox!)
        : now.subtract(const Duration(days: 365 * 35));
    final ageYears = (now.difference(dob).inDays / 365.25).floor();
    final sex = member.sex;

    // 2. Evaluate CBAC and clinical measurements offline
    final assessment = CbacCalculator.evaluateAssessment(
      id: encounterId,
      memberId: memberId,
      screenedAt: now,
      ageYears: ageYears,
      sex: sex,
      tobaccoUse: tobaccoUse,
      alcoholConsumption: alcoholConsumption,
      waistCircumferenceCm: waistCircumferenceCm,
      physicalActivity: physicalActivity,
      familyHistory: familyHistory,
      warningSigns: warningSigns,
      systolicBp: systolicBp,
      diastolicBp: diastolicBp,
      bloodGlucoseMgDl: bloodGlucoseMgDl,
      glucoseType: glucoseType,
    );

    // 3. Insert ClinicalEncounter
    await _db
        .into(_db.clinicalEncounters)
        .insert(
          ClinicalEncountersCompanion.insert(
            id: encounterId,
            memberId: memberId,
            encounterType: 'NCD_CBAC_SCREENING',
            programCode: 'ncd',
            encounterDate: nowMs,
            ashaId: ashaId,
            status: const Value('completed'),
            visitNotes: Value(
              'CBAC Score: ${assessment.totalCbacScore}/10 | High Risk: ${assessment.isHighRiskScore} | Triage: ${assessment.triageFlag.name}',
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
        observationCode: 'CBAC_SCORE',
        valueNumeric: Value(assessment.totalCbacScore.toDouble()),
        source: const Value('CBAC_CALCULATOR'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'IS_HIGH_RISK_CBAC',
        valueEnum: Value(assessment.isHighRiskScore ? 'YES' : 'NO'),
        source: const Value('CBAC_CALCULATOR'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'WAIST_CIRCUMFERENCE_CM',
        valueNumeric: Value(waistCircumferenceCm),
        valueUnit: const Value('cm'),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'CANCER_WARNING_SIGNS_JSON',
        valueText: Value(jsonEncode(warningSigns.toJson())),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
    ];

    if (systolicBp != null && diastolicBp != null) {
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'SYSTOLIC_BP',
          valueNumeric: Value(systolicBp.toDouble()),
          valueUnit: const Value('mmHg'),
          source: const Value('MANUAL'),
          observedAt: nowMs,
        ),
      );
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'DIASTOLIC_BP',
          valueNumeric: Value(diastolicBp.toDouble()),
          valueUnit: const Value('mmHg'),
          source: const Value('MANUAL'),
          observedAt: nowMs,
        ),
      );
      if (assessment.bpCategory != null) {
        obs.add(
          ClinicalObservationsCompanion.insert(
            id: _uuid.v4(),
            encounterId: encounterId,
            observationCode: 'BP_CATEGORY',
            valueText: Value(assessment.bpCategory!.name),
            source: const Value('NCD_GUIDELINES'),
            observedAt: nowMs,
          ),
        );
      }
    }

    if (bloodGlucoseMgDl != null && glucoseType != null) {
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'BLOOD_GLUCOSE_MG_DL',
          valueNumeric: Value(bloodGlucoseMgDl),
          valueUnit: const Value('mg/dL'),
          source: const Value('MANUAL'),
          observedAt: nowMs,
        ),
      );
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'GLUCOSE_TYPE',
          valueText: Value(glucoseType.name),
          source: const Value('MANUAL'),
          observedAt: nowMs,
        ),
      );
      if (assessment.glucoseCategory != null) {
        obs.add(
          ClinicalObservationsCompanion.insert(
            id: _uuid.v4(),
            encounterId: encounterId,
            observationCode: 'GLUCOSE_CATEGORY',
            valueText: Value(assessment.glucoseCategory!.name),
            source: const Value('NCD_GUIDELINES'),
            observedAt: nowMs,
          ),
        );
      }
    }

    for (final o in obs) {
      await _db.into(_db.clinicalObservations).insert(o);
    }

    // 5. Insert TriageResults
    await _db
        .into(_db.triageResults)
        .insert(
          TriageResultsCompanion.insert(
            id: _uuid.v4(),
            encounterId: encounterId,
            flag: assessment.triageFlag.name.toUpperCase(),
            ruleVersionId: '1.0.0',
            findingsJson: jsonEncode(assessment.clinicalFindings),
            evaluatedAt: nowMs,
          ),
        );

    // 6. Referral Generation for High Risk, Warning Signs, or Abnormal Readings
    if (assessment.requiresFacilityConfirmation ||
        assessment.triageFlag != TriageFlag.green) {
      final referralId = _uuid.v4();
      final isRed = assessment.triageFlag == TriageFlag.red;

      await _db
          .into(_db.referralRecords)
          .insert(
            ReferralRecordsCompanion.insert(
              id: referralId,
              encounterId: encounterId,
              memberId: memberId,
              triageFlag: assessment.triageFlag.name.toUpperCase(),
              destinationLevel: Value(
                assessment.referralDestination ?? 'PHC_CHC',
              ),
              transportArranged: Value(isRed ? '108_AMBULANCE' : null),
              status: const Value('created'),
              referralNoteText: Value(
                'NCD/CBAC SCREENING: ${assessment.clinicalFindings.join("; ")}. Recommended confirmation & care.',
              ),
              createdAt: nowMs,
              updatedAt: nowMs,
            ),
          );

      // Enqueue sync alert
      if (_syncEngine != null) {
        await _syncEngine.enqueue(
          table: 'referral_records',
          recordId: referralId,
          operation: 'insert',
          priority: isRed ? SyncPriority.critical : SyncPriority.clinical,
          payload: {
            'member_id': memberId,
            'type': isRed ? 'NCD_RED_ALERT' : 'NCD_REFERRAL',
            'cbac_score': assessment.totalCbacScore,
            'findings': assessment.clinicalFindings,
          },
        );
      }

      // Schedule follow-up task to track referral confirmation (in 14 days)
      final followUpDueDate = now
          .add(const Duration(days: 14))
          .millisecondsSinceEpoch;
      await _db
          .into(_db.visitSchedules)
          .insert(
            VisitSchedulesCompanion.insert(
              id: 'ncd_referral_followup_${memberId}_$nowMs',
              memberId: memberId,
              programCode: 'ncd',
              visitType: 'NCD Confirmatory Screening Follow-Up',
              dueDate: followUpDueDate,
              dueWindowStart: Value(followUpDueDate - (3 * 24 * 3600 * 1000)),
              dueWindowEnd: Value(followUpDueDate + (7 * 24 * 3600 * 1000)),
              status: const Value('pending'),
              createdAt: nowMs,
            ),
            mode: InsertMode.insertOrReplace,
          );
    }

    // 7. Write CBAC screening incentive event (Activity code: CBAC_SCREENING_COMPLETE)
    await _db
        .into(_db.incentiveEvents)
        .insert(
          IncentiveEventsCompanion.insert(
            id: _uuid.v4(),
            memberId: memberId,
            encounterId: Value(encounterId),
            activityCode: 'CBAC_SCREENING_COMPLETE',
            catalogueVersionId: '1.0.0',
            idempotencyKey: 'cbac_${memberId}_$encounterId',
            status: const Value('eligible'),
            eventDate: nowMs,
            createdAt: nowMs,
          ),
        );

    // Enqueue clinical encounter sync
    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'clinical_encounters',
        recordId: encounterId,
        operation: 'insert',
        priority: assessment.triageFlag == TriageFlag.red
            ? SyncPriority.critical
            : SyncPriority.clinical,
        payload: assessment.toJson(),
      );
    }

    return assessment;
  }

  // ── 2. NCD Chronic Care Patient Register (Requirement 19.4) ─────────────────

  /// Enrols a beneficiary confirmed to have hypertension and/or diabetes into the
  /// chronic care follow-up pathway, sets up recurring medication refill reminders,
  /// and schedules monthly adherence visits.
  Future<NcdPatientRecord> enrolNcdPatient({
    required String memberId,
    required NcdDiagnosisType diagnosis,
    required List<String> prescribedMedications,
    required String ashaId,
    DateTime? enrolledAt,
  }) async {
    final now = enrolledAt ?? DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    final member = await (_db.select(
      _db.members,
    )..where((t) => t.id.equals(memberId))).getSingle();
    final household = await (_db.select(
      _db.households,
    )..where((t) => t.id.equals(member.householdId))).getSingleOrNull();
    // 1. Record enrolment encounter
    await _db
        .into(_db.clinicalEncounters)
        .insert(
          ClinicalEncountersCompanion.insert(
            id: encounterId,
            memberId: memberId,
            encounterType: 'NCD_ENROLMENT',
            programCode: 'ncd',
            encounterDate: nowMs,
            ashaId: ashaId,
            status: const Value('completed'),
            visitNotes: Value(
              'Enrolled in NCD Register: ${diagnosis.label} | Meds: ${prescribedMedications.join(", ")}',
            ),
            createdAt: nowMs,
            updatedAt: nowMs,
            syncStatus: const Value('pending'),
          ),
        );

    // 2. Observations
    await _db
        .into(_db.clinicalObservations)
        .insert(
          ClinicalObservationsCompanion.insert(
            id: _uuid.v4(),
            encounterId: encounterId,
            observationCode: 'NCD_DIAGNOSIS',
            valueText: Value(diagnosis.name),
            source: const Value('CLINICAL_CONFIRMATION'),
            observedAt: nowMs,
          ),
        );

    await _db
        .into(_db.clinicalObservations)
        .insert(
          ClinicalObservationsCompanion.insert(
            id: _uuid.v4(),
            encounterId: encounterId,
            observationCode: 'PRESCRIBED_MEDICATIONS',
            valueText: Value(jsonEncode(prescribedMedications)),
            source: const Value('PRESCRIPTION'),
            observedAt: nowMs,
          ),
        );

    // 3. Schedule 30-day Medication Refill Reminder
    final nextRefillMs = now
        .add(const Duration(days: 30))
        .millisecondsSinceEpoch;
    await _db
        .into(_db.visitSchedules)
        .insert(
          VisitSchedulesCompanion.insert(
            id: 'ncd_refill_${memberId}_$nextRefillMs',
            memberId: memberId,
            programCode: 'ncd',
            visitType: 'NCD Medication Refill Reminder (${diagnosis.label})',
            dueDate: nextRefillMs,
            dueWindowStart: Value(nextRefillMs - (3 * 24 * 3600 * 1000)),
            dueWindowEnd: Value(nextRefillMs + (7 * 24 * 3600 * 1000)),
            status: const Value('pending'),
            createdAt: nowMs,
          ),
          mode: InsertMode.insertOrReplace,
        );

    // 4. Schedule 30-day Monthly Adherence & Clinical Checkup Visit
    await _db
        .into(_db.visitSchedules)
        .insert(
          VisitSchedulesCompanion.insert(
            id: 'ncd_checkup_${memberId}_$nextRefillMs',
            memberId: memberId,
            programCode: 'ncd',
            visitType: 'NCD Monthly Adherence & BP/Glucose Checkup',
            dueDate: nextRefillMs,
            dueWindowStart: Value(nextRefillMs - (3 * 24 * 3600 * 1000)),
            dueWindowEnd: Value(nextRefillMs + (7 * 24 * 3600 * 1000)),
            status: const Value('pending'),
            createdAt: nowMs,
          ),
          mode: InsertMode.insertOrReplace,
        );

    return NcdPatientRecord(
      id: encounterId,
      memberId: memberId,
      beneficiaryName: member.name,
      hamlet: household?.hamlet ?? household?.village ?? 'Unknown',
      diagnosis: diagnosis,
      enrolledAt: now,
      prescribedMedications: prescribedMedications,
      lastVisitDate: now,
      nextRefillDueDate: DateTime.fromMillisecondsSinceEpoch(nextRefillMs),
      nextCheckupDueDate: DateTime.fromMillisecondsSinceEpoch(nextRefillMs),
    );
  }

  // ── 3. Follow-Up Visit & Repeat Measurements (Requirement 19.4) ─────────────

  /// Records an adherence check visit, repeat BP / blood glucose measurement,
  /// medication refill distribution, and resets the next refill schedule.
  Future<NcdFollowUpRecord> recordFollowUpVisit({
    required String memberId,
    int? systolicBp,
    int? diastolicBp,
    double? bloodGlucoseMgDl,
    GlucoseType? glucoseType,
    required MedicationAdherence adherence,
    bool medicinesRefilled = true,
    int daysOfRefillProvided = 30,
    String? sideEffectsNoted,
    List<String> lifestyleCounsellingTopics = const [],
    required String ashaId,
    DateTime? visitDate,
  }) async {
    final now = visitDate ?? DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    // 1. Insert Encounter
    await _db
        .into(_db.clinicalEncounters)
        .insert(
          ClinicalEncountersCompanion.insert(
            id: encounterId,
            memberId: memberId,
            encounterType: 'NCD_FOLLOW_UP',
            programCode: 'ncd',
            encounterDate: nowMs,
            ashaId: ashaId,
            status: const Value('completed'),
            visitNotes: Value(
              'BP: ${systolicBp ?? "-"}/${diastolicBp ?? "-"} | Glucose: ${bloodGlucoseMgDl ?? "-"} | Adherence: ${adherence.name} | Refilled: $medicinesRefilled',
            ),
            createdAt: nowMs,
            updatedAt: nowMs,
            syncStatus: const Value('pending'),
          ),
        );

    // 2. Observations
    final obs = <ClinicalObservationsCompanion>[
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'MEDICATION_ADHERENCE',
        valueText: Value(adherence.name),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'MEDICINES_REFILLED',
        valueEnum: Value(medicinesRefilled ? 'YES' : 'NO'),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
    ];

    if (systolicBp != null && diastolicBp != null) {
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'SYSTOLIC_BP',
          valueNumeric: Value(systolicBp.toDouble()),
          valueUnit: const Value('mmHg'),
          source: const Value('MANUAL'),
          observedAt: nowMs,
        ),
      );
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'DIASTOLIC_BP',
          valueNumeric: Value(diastolicBp.toDouble()),
          valueUnit: const Value('mmHg'),
          source: const Value('MANUAL'),
          observedAt: nowMs,
        ),
      );
    }

    if (bloodGlucoseMgDl != null && glucoseType != null) {
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'BLOOD_GLUCOSE_MG_DL',
          valueNumeric: Value(bloodGlucoseMgDl),
          valueUnit: const Value('mg/dL'),
          source: const Value('MANUAL'),
          observedAt: nowMs,
        ),
      );
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'GLUCOSE_TYPE',
          valueText: Value(glucoseType.name),
          source: const Value('MANUAL'),
          observedAt: nowMs,
        ),
      );
    }

    for (final o in obs) {
      await _db.into(_db.clinicalObservations).insert(o);
    }

    // 3. Mark current pending checkup / refill schedules completed
    await (_db.update(_db.visitSchedules)..where(
          (t) =>
              t.memberId.equals(memberId) &
              t.programCode.equals('ncd') &
              t.status.equals('pending') &
              t.visitType.like('%Checkup%'),
        ))
        .write(
          VisitSchedulesCompanion(
            status: const Value('completed'),
            completedEncounterId: Value(encounterId),
          ),
        );

    // 4. If refilled, schedule the NEXT refill and checkup date
    if (medicinesRefilled) {
      final nextRefillMs = now
          .add(Duration(days: daysOfRefillProvided))
          .millisecondsSinceEpoch;

      await _db
          .into(_db.visitSchedules)
          .insert(
            VisitSchedulesCompanion.insert(
              id: 'ncd_refill_${memberId}_$nextRefillMs',
              memberId: memberId,
              programCode: 'ncd',
              visitType: 'NCD Medication Refill Reminder',
              dueDate: nextRefillMs,
              dueWindowStart: Value(nextRefillMs - (3 * 24 * 3600 * 1000)),
              dueWindowEnd: Value(nextRefillMs + (7 * 24 * 3600 * 1000)),
              status: const Value('pending'),
              createdAt: nowMs,
            ),
            mode: InsertMode.insertOrReplace,
          );

      await _db
          .into(_db.visitSchedules)
          .insert(
            VisitSchedulesCompanion.insert(
              id: 'ncd_checkup_${memberId}_$nextRefillMs',
              memberId: memberId,
              programCode: 'ncd',
              visitType: 'NCD Monthly Adherence & BP/Glucose Checkup',
              dueDate: nextRefillMs,
              dueWindowStart: Value(nextRefillMs - (3 * 24 * 3600 * 1000)),
              dueWindowEnd: Value(nextRefillMs + (7 * 24 * 3600 * 1000)),
              status: const Value('pending'),
              createdAt: nowMs,
            ),
            mode: InsertMode.insertOrReplace,
          );
    }

    final record = NcdFollowUpRecord(
      encounterId: encounterId,
      memberId: memberId,
      visitDate: now,
      systolicBp: systolicBp,
      diastolicBp: diastolicBp,
      bloodGlucoseMgDl: bloodGlucoseMgDl,
      glucoseType: glucoseType,
      adherence: adherence,
      medicinesRefilled: medicinesRefilled,
      daysOfRefillProvided: daysOfRefillProvided,
      sideEffectsNoted: sideEffectsNoted,
      lifestyleCounsellingTopics: lifestyleCounsellingTopics,
      ashaId: ashaId,
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

  // ── 4. Overdue Tracing Task Generation (Requirement 19.5) ───────────────────

  /// Generates tracing tasks for NCD patients who have missed scheduled visits
  /// or are overdue for medication refills by more than [overdueDaysThreshold].
  Future<List<VisitSchedule>> generateOverdueTracingTasks({
    int overdueDaysThreshold = 14,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoffMs = nowMs - (overdueDaysThreshold * 24 * 3600 * 1000);

    // Find overdue pending NCD schedules
    final overdueSchedules =
        await (_db.select(_db.visitSchedules)..where(
              (t) =>
                  t.programCode.equals('ncd') &
                  t.status.equals('pending') &
                  t.dueDate.isSmallerThanValue(cutoffMs),
            ))
            .get();

    final createdTracingTasks = <VisitSchedule>[];

    for (final schedule in overdueSchedules) {
      final tracingId = 'ncd_tracing_${schedule.memberId}_${schedule.id}';

      // Check if tracing task already exists
      final existing = await (_db.select(
        _db.visitSchedules,
      )..where((t) => t.id.equals(tracingId))).getSingleOrNull();
      if (existing != null) continue;

      await _db
          .into(_db.visitSchedules)
          .insert(
            VisitSchedulesCompanion.insert(
              id: tracingId,
              memberId: schedule.memberId,
              programCode: 'ncd',
              visitType:
                  'URGENT NCD Tracing: Overdue for Meds/Checkup (>14 days)',
              dueDate: nowMs, // Due immediately
              dueWindowStart: Value(nowMs),
              dueWindowEnd: Value(nowMs + (3 * 24 * 3600 * 1000)),
              status: const Value('pending'),
              createdAt: nowMs,
            ),
            mode: InsertMode.insertOrReplace,
          );

      final task = await (_db.select(
        _db.visitSchedules,
      )..where((t) => t.id.equals(tracingId))).getSingle();
      createdTracingTasks.add(task);
    }

    return createdTracingTasks;
  }

  // ── 5. National NCD Portal CSV Export (Requirement 19.6) ─────────────────────

  /// Exports all CBAC screenings formatted for the National NCD Application Portal.
  Future<String> exportNationalNcdPortalCsv() async {
    final encounters =
        await (_db.select(_db.clinicalEncounters)
              ..where((t) => t.encounterType.equals('NCD_CBAC_SCREENING'))
              ..orderBy([(t) => OrderingTerm.desc(t.encounterDate)]))
            .get();

    final rows = <Map<String, dynamic>>[];

    for (final enc in encounters) {
      final member = await (_db.select(
        _db.members,
      )..where((t) => t.id.equals(enc.memberId))).getSingleOrNull();
      if (member == null) continue;

      final household = await (_db.select(
        _db.households,
      )..where((t) => t.id.equals(member.householdId))).getSingleOrNull();
      final observations = await (_db.select(
        _db.clinicalObservations,
      )..where((t) => t.encounterId.equals(enc.id))).get();

      final obsMap = {for (final o in observations) o.observationCode: o};

      final dob = member.dobApprox != null
          ? DateTime.fromMillisecondsSinceEpoch(member.dobApprox!)
          : DateTime.fromMillisecondsSinceEpoch(enc.encounterDate)
                .subtract(const Duration(days: 365 * 35));
      final age =
          (DateTime.fromMillisecondsSinceEpoch(enc.encounterDate)
                      .difference(dob)
                      .inDays /
                  365.25)
              .floor();

      // Parse warning signs
      bool oralSigns = false;
      bool breastSigns = false;
      bool cervicalSigns = false;
      bool coughSigns = false;

      final warningJsonStr = obsMap['CANCER_WARNING_SIGNS_JSON']?.valueText;
      if (warningJsonStr != null) {
        try {
          final map = jsonDecode(warningJsonStr) as Map<String, dynamic>;
          oralSigns =
              map['oral_ulcer'] == true ||
              map['oral_patch'] == true ||
              map['oral_difficulty'] == true ||
              map['oral_growth'] == true;
          breastSigns =
              map['breast_lump'] == true ||
              map['breast_discharge'] == true ||
              map['breast_shape'] == true;
          cervicalSigns =
              map['cervical_intermenstrual'] == true ||
              map['cervical_postcoital'] == true ||
              map['cervical_foul_discharge'] == true;
          coughSigns = map['persistent_cough'] == true;
        } catch (_) {}
      }

      final triageResult = await (_db.select(
        _db.triageResults,
      )..where((t) => t.encounterId.equals(enc.id))).getSingleOrNull();
      final referral = await (_db.select(
        _db.referralRecords,
      )..where((t) => t.encounterId.equals(enc.id))).getSingleOrNull();

      rows.add({
        'member_id': member.id,
        'household_id': member.householdId,
        'name': member.name,
        'age': age,
        'sex': member.sex,
        'village': household?.village ?? '',
        'cbac_score': obsMap['CBAC_SCORE']?.valueNumeric?.toInt() ?? 0,
        'is_high_risk': obsMap['IS_HIGH_RISK_CBAC']?.valueEnum == 'YES',
        'tobacco': 'STANDARD',
        'alcohol': 'STANDARD',
        'waist_cm': obsMap['WAIST_CIRCUMFERENCE_CM']?.valueNumeric ?? '',
        'physical_activity': '>=150min',
        'family_history': false,
        'systolic_bp': obsMap['SYSTOLIC_BP']?.valueNumeric?.toInt(),
        'diastolic_bp': obsMap['DIASTOLIC_BP']?.valueNumeric?.toInt(),
        'bp_category': obsMap['BP_CATEGORY']?.valueText ?? '',
        'glucose_val': obsMap['BLOOD_GLUCOSE_MG_DL']?.valueNumeric,
        'glucose_type': obsMap['GLUCOSE_TYPE']?.valueText ?? '',
        'glucose_category': obsMap['GLUCOSE_CATEGORY']?.valueText ?? '',
        'oral_signs': oralSigns,
        'breast_signs': breastSigns,
        'cervical_signs': cervicalSigns,
        'cough_signs': coughSigns,
        'referral_required':
            referral != null ||
            triageResult?.flag == 'RED' ||
            triageResult?.flag == 'YELLOW',
        'referral_dest': referral?.destinationLevel ?? '',
        'asha_id': enc.ashaId,
        'screened_date': DateTime.fromMillisecondsSinceEpoch(enc.encounterDate)
            .toIso8601String()
            .split('T')
            .first,
      });
    }

    return CbacCalculator.generateNationalNcdPortalCsv(rows);
  }
}

/// Riverpod provider for [NcdRepository].
final ncdRepositoryProvider = Provider<NcdRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return NcdRepository(db, syncEngine);
});
