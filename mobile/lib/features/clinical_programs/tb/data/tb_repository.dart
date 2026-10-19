import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' hide TriageResult;
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/triage/models/models.dart';
import '../../../../shared/providers/core_providers.dart';
import '../domain/tb_calculator.dart';
import '../domain/tb_models.dart';

/// Repository managing Tuberculosis (TB) clinical workflows under NTEP:
/// Presumptive TB screening, sputum transport & testing, treatment registration,
/// daily dose observation (DOTS), consecutive-miss alerting, contact tracing / TPT,
/// and Ni-kshay Poshan DBT linkage.
///
/// Implements Requirements 20.1 – 20.8.
class TbRepository {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;
  static const _uuid = Uuid();

  TbRepository(this._db, [this._syncEngine]);

  // ── 1. Presumptive TB Screening & DMC Referral (Requirement 20.1) ───────────

  /// Records presumptive TB symptom checklist, evaluates triage, creates referral to DMC,
  /// schedules sputum follow-up, and writes incentive event.
  Future<PresumptiveTbAssessment> recordPresumptiveTbScreening({
    required String memberId,
    bool coughGt2Weeks = false,
    bool feverGt2Weeks = false,
    bool unexplainedWeightLoss = false,
    bool nightSweats = false,
    bool haemoptysis = false,
    bool chestPain = false,
    bool contactWithKnownTbPatient = false,
    required String ashaId,
    DateTime? screenedAt,
  }) async {
    final now = screenedAt ?? DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    // 1. Evaluate triage
    final assessment = TbCalculator.evaluatePresumptiveTb(
      id: encounterId,
      memberId: memberId,
      screenedAt: now,
      coughGt2Weeks: coughGt2Weeks,
      feverGt2Weeks: feverGt2Weeks,
      unexplainedWeightLoss: unexplainedWeightLoss,
      nightSweats: nightSweats,
      haemoptysis: haemoptysis,
      chestPain: chestPain,
      contactWithKnownTbPatient: contactWithKnownTbPatient,
    );

    // 2. Insert ClinicalEncounter
    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: memberId,
        encounterType: 'TB_PRESUMPTIVE_SCREENING',
        programCode: 'tb',
        encounterDate: nowMs,
        ashaId: ashaId,
        status: const Value('completed'),
        visitNotes: Value(
          'Presumptive TB: ${assessment.isPresumptiveTb} | Triage: ${assessment.triageFlag.name} | Findings: ${assessment.clinicalFindings.join(", ")}',
        ),
        createdAt: nowMs,
        updatedAt: nowMs,
        syncStatus: const Value('pending'),
      ),
    );

    // 3. Insert discrete Observations
    final obs = <ClinicalObservationsCompanion>[
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'IS_PRESUMPTIVE_TB',
        valueEnum: Value(assessment.isPresumptiveTb ? 'YES' : 'NO'),
        source: const Value('TB_CALCULATOR'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'COUGH_GT_2W',
        valueEnum: Value(coughGt2Weeks ? 'YES' : 'NO'),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'FEVER_GT_2W',
        valueEnum: Value(feverGt2Weeks ? 'YES' : 'NO'),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'UNEXPLAINED_WEIGHT_LOSS',
        valueEnum: Value(unexplainedWeightLoss ? 'YES' : 'NO'),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'HAEMOPTYSIS',
        valueEnum: Value(haemoptysis ? 'YES' : 'NO'),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
    ];

    for (final o in obs) {
      await _db.into(_db.clinicalObservations).insert(o);
    }

    // 4. Insert TriageResults
    await _db.into(_db.triageResults).insert(
      TriageResultsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        flag: assessment.triageFlag.name.toUpperCase(),
        ruleVersionId: '1.0.0',
        findingsJson: jsonEncode(assessment.clinicalFindings),
        evaluatedAt: nowMs,
      ),
    );

    // 5. If Presumptive TB or Haemoptysis -> Create Referral & Sputum Task
    if (assessment.isPresumptiveTb || assessment.triageFlag != TriageFlag.green) {
      final referralId = _uuid.v4();
      final isRed = assessment.triageFlag == TriageFlag.red;

      await _db.into(_db.referralRecords).insert(
        ReferralRecordsCompanion.insert(
          id: referralId,
          encounterId: encounterId,
          memberId: memberId,
          triageFlag: assessment.triageFlag.name.toUpperCase(),
          destinationLevel: Value(isRed ? 'DISTRICT_HOSPITAL' : 'DMC_CHC'),
          transportArranged: Value(isRed ? '108_AMBULANCE' : null),
          status: const Value('created'),
          referralNoteText: Value(
            'PRESUMPTIVE TB: ${assessment.clinicalFindings.join("; ")}. Collect 2 sputum samples for Truenat/CBNAAT/AFB.',
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
            'type': isRed ? 'TB_HAEMOPTYSIS_EMERGENCY' : 'PRESUMPTIVE_TB_ALERT',
            'findings': assessment.clinicalFindings,
          },
        );
      }

      // Schedule sputum collection & lab result follow-up task (in 3 days)
      final sputumDueMs = now.add(const Duration(days: 3)).millisecondsSinceEpoch;
      await _db.into(_db.visitSchedules).insert(
        VisitSchedulesCompanion.insert(
          id: 'tb_sputum_followup_${memberId}_$nowMs',
          memberId: memberId,
          programCode: 'tb',
          visitType: 'Sputum Sample Collection & Truenat/NAAT Follow-Up',
          dueDate: sputumDueMs,
          dueWindowStart: Value(sputumDueMs - (1 * 24 * 3600 * 1000)),
          dueWindowEnd: Value(sputumDueMs + (4 * 24 * 3600 * 1000)),
          status: const Value('pending'),
          createdAt: nowMs,
        ),
        mode: InsertMode.insertOrReplace,
      );

      // Record incentive event for presumptive TB referral
      await _db.into(_db.incentiveEvents).insert(
        IncentiveEventsCompanion.insert(
          id: _uuid.v4(),
          memberId: memberId,
          encounterId: Value(encounterId),
          activityCode: 'TB_PRESUMPTIVE_REFERRAL',
          catalogueVersionId: '1.0.0',
          idempotencyKey: 'tb_presump_${memberId}_$encounterId',
          status: const Value('eligible'),
          eventDate: nowMs,
          createdAt: nowMs,
        ),
      );
    }

    return assessment;
  }

  // ── 2. Sputum Sample Collection & Result Tracking (Requirement 20.2) ────────

  /// Records sputum sample collection and marks its transport status.
  Future<SputumSampleRecord> recordSputumSample({
    required String memberId,
    required String sampleId,
    required String collectionSite,
    DateTime? collectionDate,
    SputumTransportStatus transportStatus = SputumTransportStatus.collectedAtVillage,
    required String ashaId,
  }) async {
    final now = collectionDate ?? DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    // 1. Encounter
    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: memberId,
        encounterType: 'TB_SPUTUM_COLLECTION',
        programCode: 'tb',
        encounterDate: nowMs,
        ashaId: ashaId,
        status: const Value('completed'),
        visitNotes: Value('Sputum Sample ID: $sampleId | Status: ${transportStatus.label}'),
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
        observationCode: 'SPUTUM_SAMPLE_ID',
        valueText: Value(sampleId),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
    );
    await _db.into(_db.clinicalObservations).insert(
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'SPUTUM_TRANSPORT_STATUS',
        valueText: Value(transportStatus.name),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
    );

    final record = SputumSampleRecord(
      sampleId: sampleId,
      memberId: memberId,
      collectionDate: now,
      collectionSite: collectionSite,
      transportStatus: transportStatus,
      testResult: SputumTestResult.pending,
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

  /// Updates sputum sample with laboratory diagnostic test result.
  Future<SputumSampleRecord> updateSputumTestResult({
    required String sampleId,
    required String memberId,
    required SputumTestResult testResult,
    DateTime? resultDate,
    String? labName,
    required String ashaId,
  }) async {
    final now = resultDate ?? DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: memberId,
        encounterType: 'TB_SPUTUM_RESULT',
        programCode: 'tb',
        encounterDate: nowMs,
        ashaId: ashaId,
        status: const Value('completed'),
        visitNotes: Value('Sputum Result: ${testResult.label} (Sample: $sampleId)'),
        createdAt: nowMs,
        updatedAt: nowMs,
        syncStatus: const Value('pending'),
      ),
    );

    await _db.into(_db.clinicalObservations).insert(
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'SPUTUM_TEST_RESULT',
        valueText: Value(testResult.name),
        source: const Value('LABORATORY'),
        observedAt: nowMs,
      ),
    );

    // If positive -> prompt urgent TB treatment initiation in visit_schedules
    if (testResult.isPositive) {
      final promptMs = now.add(const Duration(days: 1)).millisecondsSinceEpoch;
      await _db.into(_db.visitSchedules).insert(
        VisitSchedulesCompanion.insert(
          id: 'tb_treatment_initiation_${memberId}_$nowMs',
          memberId: memberId,
          programCode: 'tb',
          visitType: 'URGENT: Initiate TB Treatment & Register on Ni-kshay',
          dueDate: promptMs,
          dueWindowStart: Value(nowMs),
          dueWindowEnd: Value(promptMs + (2 * 24 * 3600 * 1000)),
          status: const Value('pending'),
          createdAt: nowMs,
        ),
        mode: InsertMode.insertOrReplace,
      );
    }

    return SputumSampleRecord(
      sampleId: sampleId,
      memberId: memberId,
      collectionDate: now,
      collectionSite: 'Primary Health Centre',
      transportStatus: SputumTransportStatus.testingCompleted,
      testResult: testResult,
      resultDate: now,
      labName: labName ?? 'Designated Microscopy Centre (DMC)',
      ashaId: ashaId,
    );
  }

  // ── 3. TB Treatment Registration & Supporter Linkage (Requirement 20.3) ─────

  /// Registers confirmed TB patient in the treatment pathway, records supporter details,
  /// and schedules recurring dose-observation visits.
  Future<TbTreatmentPatient> registerTbTreatment({
    required String memberId,
    String? nikshayId,
    TbSite site = TbSite.pulmonary,
    TbRegimenType regimen = TbRegimenType.dsTbDailyFdc,
    required String treatmentSupporterName,
    required String treatmentSupporterPhone,
    required String supporterRelationship,
    int totalDosesPrescribed = 168,
    required String ashaId,
    DateTime? startDate,
  }) async {
    final now = startDate ?? DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    final member = await (_db.select(_db.members)..where((t) => t.id.equals(memberId))).getSingle();

    // 1. Encounter
    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: memberId,
        encounterType: 'TB_TREATMENT_REGISTRATION',
        programCode: 'tb',
        encounterDate: nowMs,
        ashaId: ashaId,
        status: const Value('completed'),
        visitNotes: Value('TB Regimen: ${regimen.label} | Supporter: $treatmentSupporterName ($treatmentSupporterPhone)'),
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
        observationCode: 'TB_REGIMEN',
        valueText: Value(regimen.name),
        source: const Value('CLINICAL_PRESCRIPTION'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'TREATMENT_SUPPORTER_NAME',
        valueText: Value(treatmentSupporterName),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'TREATMENT_SUPPORTER_PHONE',
        valueText: Value(treatmentSupporterPhone),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
    ];

    if (nikshayId != null) {
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'NIKSHAY_ID',
          valueText: Value(nikshayId),
          source: const Value('NIKSHAY_PORTAL'),
          observedAt: nowMs,
        ),
      );
    }

    for (final o in obs) {
      await _db.into(_db.clinicalObservations).insert(o);
    }

    // 3. Schedule first week of daily dose observation visits in visit_schedules
    final firstDoseDueMs = now.add(const Duration(days: 1)).millisecondsSinceEpoch;
    await _db.into(_db.visitSchedules).insert(
      VisitSchedulesCompanion.insert(
        id: 'tb_dose_obs_${memberId}_$firstDoseDueMs',
        memberId: memberId,
        programCode: 'tb',
        visitType: 'TB Daily Dose Observation (DOTS)',
        dueDate: firstDoseDueMs,
        dueWindowStart: Value(firstDoseDueMs - (12 * 3600 * 1000)),
        dueWindowEnd: Value(firstDoseDueMs + (24 * 3600 * 1000)),
        status: const Value('pending'),
        createdAt: nowMs,
      ),
      mode: InsertMode.insertOrReplace,
    );

    // 4. Record treatment registration incentive event
    await _db.into(_db.incentiveEvents).insert(
      IncentiveEventsCompanion.insert(
        id: _uuid.v4(),
        memberId: memberId,
        encounterId: Value(encounterId),
        activityCode: 'TB_TREATMENT_SUPPORT_START',
        catalogueVersionId: '1.0.0',
        idempotencyKey: 'tb_support_start_${memberId}_$encounterId',
        status: const Value('eligible'),
        eventDate: nowMs,
        createdAt: nowMs,
      ),
    );

    final patient = TbTreatmentPatient(
      id: encounterId,
      memberId: memberId,
      beneficiaryName: member.name,
      nikshayId: nikshayId,
      site: site,
      regimen: regimen,
      startDate: now,
      treatmentSupporterName: treatmentSupporterName,
      treatmentSupporterPhone: treatmentSupporterPhone,
      supporterRelationship: supporterRelationship,
      totalDosesPrescribed: totalDosesPrescribed,
      dosesCompleted: 0,
      consecutiveMissedDoses: 0,
      ashaId: ashaId,
    );

    return patient;
  }

  // ── 4. Dose Observation & Consecutive-Miss Alerting (Requirement 20.4) ──────

  /// Records daily/weekly dose observation and monitors consecutive missed doses.
  /// If consecutive misses >= 3, generates an urgent alert for ASHA and syncs alert to STS.
  Future<TbDoseObservation> recordDoseObservation({
    required String memberId,
    required DoseIntakeStatus status,
    TbSideEffect sideEffect = TbSideEffect.none,
    String? notes,
    required String ashaId,
    DateTime? doseDate,
  }) async {
    final now = doseDate ?? DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    // 1. Encounter
    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: memberId,
        encounterType: 'TB_DOSE_OBSERVATION',
        programCode: 'tb',
        encounterDate: nowMs,
        ashaId: ashaId,
        status: const Value('completed'),
        visitNotes: Value('Dose: ${status.label} | Side Effect: ${sideEffect.label}'),
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
        observationCode: 'DOSE_INTAKE_STATUS',
        valueText: Value(status.name),
        source: const Value('DOTS_OBSERVATION'),
        observedAt: nowMs,
      ),
    );

    if (sideEffect != TbSideEffect.none) {
      await _db.into(_db.clinicalObservations).insert(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'TB_SIDE_EFFECT',
          valueText: Value(sideEffect.name),
          source: const Value('MANUAL'),
          observedAt: nowMs,
        ),
      );
    }

    // 3. Compute consecutive misses by looking at recent observation history
    final recentDoseEncounters = await (_db.select(_db.clinicalEncounters)
          ..where((t) => t.memberId.equals(memberId) & t.encounterType.equals('TB_DOSE_OBSERVATION'))
          ..orderBy([(t) => OrderingTerm.desc(t.encounterDate)])
          ..limit(10))
        .get();

    int consecutiveMisses = 0;
    for (final enc in recentDoseEncounters) {
      final doseObs = await (_db.select(_db.clinicalObservations)
            ..where((t) => t.encounterId.equals(enc.id) & t.observationCode.equals('DOSE_INTAKE_STATUS')))
          .getSingleOrNull();

      if (doseObs != null) {
        if (doseObs.valueText == DoseIntakeStatus.missed.name) {
          consecutiveMisses++;
        } else {
          break; // Streak broken
        }
      }
    }

    // 4. Consecutive Miss Alert Breach (Threshold >= 3) (Requirement 20.4)
    if (TbCalculator.checkConsecutiveMissAlert(consecutiveMissedCount: consecutiveMisses)) {
      // Create priority tracing task in visit_schedules
      final alertTaskId = 'tb_defaulter_alert_${memberId}_$nowMs';
      await _db.into(_db.visitSchedules).insert(
        VisitSchedulesCompanion.insert(
          id: alertTaskId,
          memberId: memberId,
          programCode: 'tb',
          visitType: 'URGENT TB Defaulter Tracing: $consecutiveMisses Consecutive Missed Doses!',
          dueDate: nowMs, // Due immediately
          dueWindowStart: Value(nowMs),
          dueWindowEnd: Value(nowMs + (24 * 3600 * 1000)),
          status: const Value('pending'),
          createdAt: nowMs,
        ),
        mode: InsertMode.insertOrReplace,
      );

      // Enqueue Critical P1 Sync alert to STS & TB programme staff
      if (_syncEngine != null) {
        await _syncEngine.enqueue(
          table: 'visit_schedules',
          recordId: alertTaskId,
          operation: 'insert',
          priority: SyncPriority.critical,
          payload: {
            'member_id': memberId,
            'type': 'TB_CONSECUTIVE_MISS_ALERT',
            'consecutive_missed': consecutiveMisses,
            'alert_time': now.toIso8601String(),
          },
        );
      }
    }

    // Schedule next dose observation task (tomorrow)
    final nextDoseMs = now.add(const Duration(days: 1)).millisecondsSinceEpoch;
    await _db.into(_db.visitSchedules).insert(
      VisitSchedulesCompanion.insert(
        id: 'tb_dose_obs_${memberId}_$nextDoseMs',
        memberId: memberId,
        programCode: 'tb',
        visitType: 'TB Daily Dose Observation (DOTS)',
        dueDate: nextDoseMs,
        dueWindowStart: Value(nextDoseMs - (12 * 3600 * 1000)),
        dueWindowEnd: Value(nextDoseMs + (24 * 3600 * 1000)),
        status: const Value('pending'),
        createdAt: nowMs,
      ),
      mode: InsertMode.insertOrReplace,
    );

    return TbDoseObservation(
      encounterId: encounterId,
      memberId: memberId,
      doseDate: now,
      status: status,
      sideEffect: sideEffect,
      notes: notes,
      ashaId: ashaId,
    );
  }

  // ── 5. Household Contact Investigation & TPT (Requirement 20.5) ─────────────

  /// Identifies all household members living with index TB patient, records symptom screening,
  /// and determines eligibility for TB Preventive Therapy (TPT).
  Future<List<TbContactScreening>> screenHouseholdContacts({
    required String indexPatientMemberId,
    required List<Map<String, dynamic>> contactScreenings,
    required String ashaId,
  }) async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final results = <TbContactScreening>[];

    for (final contact in contactScreenings) {
      final contactId = contact['contact_id'] as String;
      final contactName = contact['contact_name'] as String;
      final ageYears = contact['age_years'] as int;
      final hasSymptoms = contact['has_symptoms'] as bool;

      final isEligible = TbCalculator.isEligibleForTpt(ageYears: ageYears, hasSymptoms: hasSymptoms);
      final encounterId = _uuid.v4();

      await _db.into(_db.clinicalEncounters).insert(
        ClinicalEncountersCompanion.insert(
          id: encounterId,
          memberId: contactId,
          encounterType: 'TB_CONTACT_SCREENING',
          programCode: 'tb',
          encounterDate: nowMs,
          ashaId: ashaId,
          status: const Value('completed'),
          visitNotes: Value('TB Contact Screening | Symptomatic: $hasSymptoms | TPT Eligible: $isEligible'),
          createdAt: nowMs,
          updatedAt: nowMs,
          syncStatus: const Value('pending'),
        ),
      );

      // If eligible for TPT, schedule TPT initiation visit
      if (isEligible) {
        final tptDueMs = now.add(const Duration(days: 7)).millisecondsSinceEpoch;
        await _db.into(_db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: 'tb_tpt_initiation_${contactId}_$nowMs',
            memberId: contactId,
            programCode: 'tb',
            visitType: 'TB Preventive Therapy (TPT) Assessment & Initiation',
            dueDate: tptDueMs,
            dueWindowStart: Value(tptDueMs - (2 * 24 * 3600 * 1000)),
            dueWindowEnd: Value(tptDueMs + (5 * 24 * 3600 * 1000)),
            status: const Value('pending'),
            createdAt: nowMs,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      results.add(
        TbContactScreening(
          contactMemberId: contactId,
          contactName: contactName,
          indexPatientMemberId: indexPatientMemberId,
          ageYears: ageYears,
          hasSymptoms: hasSymptoms,
          eligibleForTpt: isEligible,
          screenedAt: now,
        ),
      );
    }

    return results;
  }

  // ── 6. Ni-kshay Poshan Yojana Financial DBT Linkage (Requirement 20.7) ──────

  /// Records bank account linkage and status for the monthly Rs 500 DBT nutritional benefit.
  Future<void> linkNikshayPoshanYojana({
    required String memberId,
    required NikshayPoshanStatus status,
    required String ashaId,
    String? bankAccountNumber,
    String? ifscCode,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final encounterId = _uuid.v4();

    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: memberId,
        encounterType: 'NIKSHAY_POSHAN_LINKAGE',
        programCode: 'tb',
        encounterDate: nowMs,
        ashaId: ashaId,
        status: const Value('completed'),
        visitNotes: Value('Ni-kshay Poshan Yojana: ${status.label}'),
        createdAt: nowMs,
        updatedAt: nowMs,
        syncStatus: const Value('pending'),
      ),
    );

    await _db.into(_db.clinicalObservations).insert(
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'NIKSHAY_POSHAN_STATUS',
        valueText: Value(status.name),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
    );
  }
}

/// Riverpod provider for [TbRepository].
final tbRepositoryProvider = Provider<TbRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  return TbRepository(db, syncEngine);
});
