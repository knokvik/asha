import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' hide TriageResult;
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/triage/models/models.dart';
import '../../../../core/triage/triage_engine.dart';
import '../../../../shared/providers/core_providers.dart';
import '../domain/immunization_models.dart';

/// Repository managing the National Immunization Schedule (NIS), dose recording,
/// defaulter tracking, catch-up calculations, AEFI surveillance, and VHSND session execution.
///
/// Implements Requirements 16.1 – 16.7.
class ImmunizationRepository {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;
  final TriageEngine? _triageEngine;
  static const _uuid = Uuid();

  ImmunizationRepository(this._db, [this._syncEngine, this._triageEngine]);

  // ── 1. Schedule Generation (Requirement 16.1) ──────────────────────────────

  /// Generates the complete national immunization schedule from date of birth.
  Future<List<VisitSchedule>> generateScheduleForChild({
    required String memberId,
    required DateTime dateOfBirth,
    required String ashaId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final generated = <VisitSchedule>[];

    for (final def in NationalImmunizationCatalog.infantAndChildSchedule) {
      final targetDueDate = dateOfBirth.add(Duration(days: def.targetAgeDays));
      final windowStartDate = dateOfBirth.add(Duration(days: def.windowStartDays));
      final windowEndDate = dateOfBirth.add(Duration(days: def.windowEndDays));

      final taskId = 'imm_${memberId}_${def.code.toLowerCase()}';

      final companion = VisitSchedulesCompanion.insert(
        id: taskId,
        memberId: memberId,
        programCode: 'immunization',
        visitType: '${def.code}: ${def.name}',
        dueDate: targetDueDate.millisecondsSinceEpoch,
        dueWindowStart: Value(windowStartDate.millisecondsSinceEpoch),
        dueWindowEnd: Value(windowEndDate.millisecondsSinceEpoch),
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
            'member_id': memberId,
            'program_code': 'immunization',
            'visit_type': '${def.code}: ${def.name}',
            'due_date': targetDueDate.millisecondsSinceEpoch,
            'status': 'pending',
          },
        );
      }

      final created = await (_db.select(_db.visitSchedules)..where((t) => t.id.equals(taskId))).getSingle();
      generated.add(created);
    }

    return generated;
  }

  // ── 2. Dose Recording & Beneficiary Card View (Requirement 16.2) ───────────

  /// Records a vaccine dose administration, creates clinical encounters & observations,
  /// completes the corresponding visit schedule, and logs incentive events if applicable.
  Future<ClinicalEncounter> recordDose({
    required String memberId,
    required VaccineDoseRecord record,
    required String ashaId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final encounterId = record.encounterId ?? _uuid.v4();

    // 1. Create clinical encounter
    final encounterCompanion = ClinicalEncountersCompanion.insert(
      id: encounterId,
      memberId: memberId,
      encounterType: 'IMMUNIZATION_DOSE',
      programCode: 'immunization',
      encounterDate: record.administeredDate.millisecondsSinceEpoch,
      ashaId: ashaId,
      status: const Value('completed'),
      visitNotes: Value(record.notes),
      createdAt: now,
      updatedAt: now,
      syncStatus: const Value('pending'),
    );

    await _db.into(_db.clinicalEncounters).insert(encounterCompanion, mode: InsertMode.insertOrReplace);

    // 2. Insert discrete clinical observations
    final obs = <ClinicalObservationsCompanion>[
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'VACCINE_CODE',
        valueText: Value(record.vaccineCode),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'ADMINISTERED_DATE',
        valueText: Value(record.administeredDate.toIso8601String()),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'BODY_SITE',
        valueText: Value(record.bodySite.name),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'SESSION_TYPE',
        valueText: Value(record.sessionType.name),
        source: const Value('MANUAL'),
        observedAt: now,
      ),
    ];

    if (record.batchNumber != null) {
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'BATCH_NUMBER',
          valueText: Value(record.batchNumber),
          source: const Value('MANUAL'),
          observedAt: now,
        ),
      );
    }

    if (record.administeredBy != null) {
      obs.add(
        ClinicalObservationsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          observationCode: 'ADMINISTERED_BY',
          valueText: Value(record.administeredBy),
          source: const Value('MANUAL'),
          observedAt: now,
        ),
      );
    }

    for (final o in obs) {
      await _db.into(_db.clinicalObservations).insert(o);
    }

    // 3. Mark corresponding visit schedule completed
    final specificTaskId = 'imm_${memberId}_${record.vaccineCode.toLowerCase()}';
    final existingSchedule = await (_db.select(_db.visitSchedules)
          ..where((t) => t.id.equals(specificTaskId) | (t.memberId.equals(memberId) & t.visitType.like('${record.vaccineCode}%'))))
        .get();

    if (existingSchedule.isNotEmpty) {
      final schedule = existingSchedule.first;
      await (_db.update(_db.visitSchedules)..where((t) => t.id.equals(schedule.id))).write(
        VisitSchedulesCompanion(
          status: const Value('completed'),
          completedAt: Value(now),
          completedEncounterId: Value(encounterId),
        ),
      );
    }

    // 4. Check for full immunization milestones (e.g. at 1 year with VitA-1 / MR-1)
    final def = NationalImmunizationCatalog.findByCode(record.vaccineCode);
    if (def?.incentiveEventCode != null) {
      await _recordImmunizationIncentiveEvent(
        memberId: memberId,
        ashaId: ashaId,
        encounterId: encounterId,
        eventCode: def!.incentiveEventCode!,
      );
    }

    // 5. Sync queue enqueue
    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'clinical_encounters',
        recordId: encounterId,
        operation: 'insert',
        priority: SyncPriority.clinical,
        payload: {
          'id': encounterId,
          'member_id': memberId,
          'vaccine_code': record.vaccineCode,
          'date': record.administeredDate.toIso8601String(),
          'site': record.bodySite.name,
          'batch': record.batchNumber,
        },
      );
    }

    return (_db.select(_db.clinicalEncounters)..where((t) => t.id.equals(encounterId))).getSingle();
  }

  /// Retrieves the complete immunization matrix for a child, computing current status
  /// (given, due, overdue, defaulter, expired) and applicable catch-up guidance.
  Future<List<ImmunizationCardItem>> getImmunizationCard({
    required String memberId,
    required DateTime dateOfBirth,
  }) async {
    // 1. Fetch all completed immunization encounters for this member
    final encounters = await (_db.select(_db.clinicalEncounters)
          ..where((t) => t.memberId.equals(memberId) & t.encounterType.equals('IMMUNIZATION_DOSE'))
          ..orderBy([(t) => OrderingTerm.asc(t.encounterDate)]))
        .get();

    final administeredDoses = <VaccineDoseRecord>[];

    for (final enc in encounters) {
      final observations = await (_db.select(_db.clinicalObservations)
            ..where((t) => t.encounterId.equals(enc.id)))
          .get();

      final obsMap = <String, String>{};
      for (final o in observations) {
        if (o.valueText != null) {
          obsMap[o.observationCode] = o.valueText!;
        }
      }

      final vaccineCode = obsMap['VACCINE_CODE'];
      if (vaccineCode != null) {
        final dateStr = obsMap['ADMINISTERED_DATE'];
        final siteStr = obsMap['BODY_SITE'];
        final sessionTypeStr = obsMap['SESSION_TYPE'];
        final batch = obsMap['BATCH_NUMBER'];
        final by = obsMap['ADMINISTERED_BY'];

        administeredDoses.add(
          VaccineDoseRecord(
            vaccineCode: vaccineCode,
            administeredDate: dateStr != null ? DateTime.parse(dateStr) : DateTime.fromMillisecondsSinceEpoch(enc.encounterDate),
            bodySite: AdministrationSite.values.firstWhere(
              (s) => s.name == siteStr,
              orElse: () => AdministrationSite.other,
            ),
            sessionType: ImmunizationSessionType.values.firstWhere(
              (st) => st.name == sessionTypeStr,
              orElse: () => ImmunizationSessionType.vhsnd,
            ),
            batchNumber: batch,
            administeredBy: by,
            encounterId: enc.id,
            notes: enc.visitNotes,
          ),
        );
      }
    }

    return ImmunizationCalculator.evaluateMatrix(
      dateOfBirth: dateOfBirth,
      administeredDoses: administeredDoses,
    );
  }

  // ── 3. Defaulter List & Catch-Up Schedule (Requirement 16.3) ───────────────

  /// Fetches beneficiaries overdue for vaccines or flagged as defaulters,
  /// including recorded skip reasons and catch-up schedules.
  Future<List<DefaulterBeneficiary>> getDefaulterList({String? hamlet}) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Find all pending immunization schedules past dueWindowEnd
    final query = _db.select(_db.visitSchedules).join([
      innerJoin(_db.members, _db.members.id.equalsExp(_db.visitSchedules.memberId)),
      leftOuterJoin(_db.households, _db.households.id.equalsExp(_db.members.householdId)),
    ])
      ..where(_db.visitSchedules.programCode.equals('immunization'))
      ..where(_db.visitSchedules.status.equals('pending'))
      ..where(_db.visitSchedules.dueWindowEnd.isSmallerThan(Variable<int>(now)));

    if (hamlet != null && hamlet.isNotEmpty) {
      query.where(_db.households.hamlet.equals(hamlet));
    }

    final rows = await query.get();

    // Group by child
    final childIds = <String>{};
    final memberRows = <String, Member>{};
    final householdRows = <String, Household?>{};
    final skipReasons = <String, String?>{};

    for (final row in rows) {
      final schedule = row.readTable(_db.visitSchedules);
      final member = row.readTable(_db.members);
      final household = row.readTableOrNull(_db.households);

      childIds.add(member.id);
      memberRows[member.id] = member;
      householdRows[member.id] = household;
      if (schedule.skipReason != null && schedule.skipReason!.isNotEmpty) {
        skipReasons[member.id] = schedule.skipReason;
      }
    }

    final defaulters = <DefaulterBeneficiary>[];

    for (final childId in childIds) {
      final member = memberRows[childId]!;
      final household = householdRows[childId];
      final dob = member.dobApprox != null
          ? DateTime.fromMillisecondsSinceEpoch(member.dobApprox!)
          : DateTime.now().subtract(const Duration(days: 90));

      final matrix = await getImmunizationCard(memberId: childId, dateOfBirth: dob);
      final missedDoses = matrix.where((item) => item.isOverdue || item.isDefaulter).toList();

      if (missedDoses.isNotEmpty) {
        final adviceParts = missedDoses
            .where((d) => d.catchUpGuidance != null)
            .map((d) => '${d.definition.code}: ${d.catchUpGuidance}')
            .toList();

        defaulters.add(
          DefaulterBeneficiary(
            memberId: childId,
            childName: member.name,
            dateOfBirth: dob,
            guardianName: household?.headName,
            contactPhone: member.phone ?? household?.contactPhone,
            hamlet: household?.hamlet,
            missedDoses: missedDoses,
            recordedSkipReason: skipReasons[childId],
            overallCatchUpAdvice: adviceParts.isNotEmpty
                ? adviceParts.join('; ')
                : 'Mobilize for immediate catch-up at upcoming VHSND.',
          ),
        );
      }
    }

    return defaulters;
  }

  // ── 4. VHSND Session & Mobilisation (Requirement 16.4, 27) ─────────────────

  /// Generates the due beneficiary list and mobilization roster for a planned VHSND session.
  Future<VhsndSession> planVhsndSession({
    required DateTime sessionDate,
    required String villageName,
    String? hamlet,
    required String anganwadiCenterName,
    required String ashaId,
  }) async {
    final sessionId = _uuid.v4();
    final targetMs = sessionDate.millisecondsSinceEpoch;
    // Window: due on or within 7 days of sessionDate
    final lookaheadMs = targetMs + (7 * 24 * 60 * 60 * 1000);

    final schedulesQuery = _db.select(_db.visitSchedules).join([
      innerJoin(_db.members, _db.members.id.equalsExp(_db.visitSchedules.memberId)),
      leftOuterJoin(_db.households, _db.households.id.equalsExp(_db.members.householdId)),
    ])
      ..where(_db.visitSchedules.status.equals('pending'))
      ..where(_db.visitSchedules.dueDate.isSmallerOrEqual(Variable<int>(lookaheadMs)));

    if (hamlet != null && hamlet.isNotEmpty) {
      schedulesQuery.where(_db.households.hamlet.equals(hamlet));
    }

    final rows = await schedulesQuery.get();

    final beneficiariesMap = <String, VhsndBeneficiaryDue>{};

    for (final row in rows) {
      final schedule = row.readTable(_db.visitSchedules);
      final member = row.readTable(_db.members);
      final household = row.readTableOrNull(_db.households);

      final isChild = member.sex != 'F' || (member.dobApprox != null && (DateTime.now().millisecondsSinceEpoch - member.dobApprox!) < (5 * 365 * 24 * 3600 * 1000));
      final beneficiaryType = isChild ? 'CHILD' : (schedule.programCode == 'anc' ? 'PREGNANT_WOMAN' : 'BENEFICIARY');

      final existing = beneficiariesMap[member.id];
      if (existing == null) {
        beneficiariesMap[member.id] = VhsndBeneficiaryDue(
          memberId: member.id,
          beneficiaryName: member.name,
          beneficiaryType: beneficiaryType,
          hamlet: household?.hamlet,
          contactPhone: member.phone ?? household?.contactPhone,
          dueVaccines: schedule.programCode == 'immunization' ? [schedule.visitType] : [],
          dueOtherServices: schedule.programCode != 'immunization' ? [schedule.visitType] : [],
        );
      } else {
        final updatedVaccines = List<String>.from(existing.dueVaccines);
        final updatedOther = List<String>.from(existing.dueOtherServices);
        if (schedule.programCode == 'immunization') {
          updatedVaccines.add(schedule.visitType);
        } else {
          updatedOther.add(schedule.visitType);
        }
        beneficiariesMap[member.id] = VhsndBeneficiaryDue(
          memberId: existing.memberId,
          beneficiaryName: existing.beneficiaryName,
          beneficiaryType: existing.beneficiaryType,
          hamlet: existing.hamlet,
          contactPhone: existing.contactPhone,
          dueVaccines: updatedVaccines,
          dueOtherServices: updatedOther,
        );
      }
    }

    return VhsndSession(
      id: sessionId,
      sessionDate: sessionDate,
      villageName: villageName,
      hamlet: hamlet,
      anganwadiCenterName: anganwadiCenterName,
      ashaId: ashaId,
      status: 'planned',
      beneficiariesDue: beneficiariesMap.values.toList(),
    );
  }

  /// Batch-records services administered during a VHSND session.
  Future<void> recordVhsndSessionOutcomes({
    required String sessionId,
    required String ashaId,
    required List<VhsndBeneficiaryDue> completedRoster,
    required DateTime sessionDate,
  }) async {
    for (final beneficiary in completedRoster) {
      if (beneficiary.attended && beneficiary.servicesDelivered.isNotEmpty) {
        for (final service in beneficiary.servicesDelivered) {
          // Check if service matches a known vaccine code
          final code = service.split(':').first.trim().toUpperCase();
          final def = NationalImmunizationCatalog.findByCode(code);
          if (def != null) {
            await recordDose(
              memberId: beneficiary.memberId,
              record: VaccineDoseRecord(
                vaccineCode: def.code,
                administeredDate: sessionDate,
                bodySite: def.standardSite,
                sessionType: ImmunizationSessionType.vhsnd,
                notes: 'Administered at VHSND session $sessionId',
              ),
              ashaId: ashaId,
            );
          }
        }
      }
    }
  }

  // ── 5. AEFI Surveillance & Triage (Requirement 16.6) ───────────────────────

  /// Captures an AEFI report, evaluates emergency triage, flags RED if urgent,
  /// generates facility referral, and enqueues high-priority sync alert for ANM & MO.
  Future<AefiRecord> recordAefi({
    required String memberId,
    required String vaccineCode,
    required DateTime sessionDate,
    required int onsetHoursAfterDose,
    required List<String> symptoms,
    required AefiSeverity severity,
    String? actionTaken,
    required String ashaId,
    String? childName,
  }) async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final encounterId = _uuid.v4();
    final aefiId = 'aefi_${_uuid.v4().substring(0, 8)}';

    // 1. Clinical urgency evaluation
    final hasUrgentSymptom = symptoms.any((s) => AefiSymptoms.isUrgent(s));
    final isUrgent = hasUrgentSymptom || severity == AefiSeverity.severe || severity == AefiSeverity.serious;
    final triageFlag = isUrgent ? TriageFlag.red : TriageFlag.green;

    // 2. Insert AEFI Clinical Encounter
    await _db.into(_db.clinicalEncounters).insert(
      ClinicalEncountersCompanion.insert(
        id: encounterId,
        memberId: memberId,
        encounterType: 'AEFI_REPORT',
        programCode: 'immunization',
        encounterDate: nowMs,
        ashaId: ashaId,
        status: const Value('completed'),
        visitNotes: Value('AEFI for $vaccineCode: ${symptoms.join(", ")} | Severity: ${severity.name}'),
        createdAt: nowMs,
        updatedAt: nowMs,
        syncStatus: const Value('pending'),
      ),
    );

    // 3. Insert discrete observations
    final obs = <ClinicalObservationsCompanion>[
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'AEFI_VACCINE_CODE',
        valueText: Value(vaccineCode),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'AEFI_ONSET_HOURS',
        valueNumeric: Value(onsetHoursAfterDose.toDouble()),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'AEFI_SEVERITY',
        valueText: Value(severity.name),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'AEFI_SYMPTOMS',
        valueText: Value(jsonEncode(symptoms)),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
      ClinicalObservationsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        observationCode: 'AEFI_URGENT',
        valueEnum: Value(isUrgent ? 'YES' : 'NO'),
        source: const Value('MANUAL'),
        observedAt: nowMs,
      ),
    ];

    for (final o in obs) {
      await _db.into(_db.clinicalObservations).insert(o);
    }

    // 4. Record TriageResult in database
    final triageRuleVersionId = _triageEngine?.ruleSet.versionString ?? '1.0.0';
    await _db.into(_db.triageResults).insert(
      TriageResultsCompanion.insert(
        id: _uuid.v4(),
        encounterId: encounterId,
        flag: triageFlag.name.toUpperCase(),
        ruleVersionId: triageRuleVersionId,
        findingsJson: jsonEncode([
          {
            'ruleId': 'AEFI_URGENT_FLAG',
            'severity': triageFlag.name.toUpperCase(),
            'finding': isUrgent
                ? 'Urgent AEFI symptoms detected ($symptoms) following $vaccineCode administration'
                : 'Minor AEFI symptoms reported',
            'action': isUrgent ? 'REFER_IMMEDIATELY' : 'PROVIDE_HOME_CARE_AND_OBSERVE',
          }
        ]),
        evaluatedAt: nowMs,
      ),
    );

    // 5. If urgent RED flag, generate emergency referral record
    if (isUrgent) {
      await _db.into(_db.referralRecords).insert(
        ReferralRecordsCompanion.insert(
          id: _uuid.v4(),
          encounterId: encounterId,
          memberId: memberId,
          triageFlag: 'RED',
          destinationLevel: const Value('PHC_CHC'),
          transportArranged: const Value('108_AMBULANCE'),
          status: const Value('created'),
          referralNoteText: Value(
            'URGENT AEFI: Child experienced severe adverse event ($symptoms) $onsetHoursAfterDose hrs post $vaccineCode vaccine.',
          ),
          createdAt: nowMs,
          updatedAt: nowMs,
        ),
      );
    }

    final record = AefiRecord(
      id: aefiId,
      memberId: memberId,
      childName: childName,
      vaccineCode: vaccineCode,
      sessionDate: sessionDate,
      onsetHoursAfterDose: onsetHoursAfterDose,
      symptoms: symptoms,
      severity: severity,
      isUrgent: isUrgent,
      actionTaken: actionTaken,
      ashaId: ashaId,
      reportedAt: now,
      notifiedAnm: true,
      notifiedMo: true,
      triageFlag: triageFlag,
    );

    // 6. Enqueue Critical Sync Alert to ANM & Medical Officer
    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'aefi_records',
        recordId: aefiId,
        operation: 'insert',
        priority: isUrgent ? SyncPriority.critical : SyncPriority.clinical,
        payload: record.toJson(),
      );
    }

    return record;
  }

  // ── 6. Pregnant Women Td Schedule (Requirement 16.7) ───────────────────────

  /// Ensures Td-1 and Td-2 schedules exist for a registered pregnant woman.
  Future<List<VisitSchedule>> ensurePregnantWomanTdSchedule({
    required String womanId,
    required DateTime lmp,
    required String ashaId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lmpMs = lmp.millisecondsSinceEpoch;
    const weekMs = 7 * 24 * 60 * 60 * 1000;

    final td1Ms = lmpMs + (10 * weekMs); // 10 weeks gestation
    final td2Ms = td1Ms + (4 * weekMs); // 4 weeks after Td-1

    final schedules = <VisitSchedule>[];

    final td1Id = 'anc_td1_$womanId';
    final td2Id = 'anc_td2_$womanId';

    final td1Companion = VisitSchedulesCompanion.insert(
      id: td1Id,
      memberId: womanId,
      programCode: 'anc',
      visitType: 'Td-1 Vaccination Contact (Early Pregnancy)',
      dueDate: td1Ms,
      dueWindowStart: Value(td1Ms - (14 * 24 * 60 * 60 * 1000)),
      dueWindowEnd: Value(td1Ms + (14 * 24 * 60 * 60 * 1000)),
      status: const Value('pending'),
      createdAt: now,
    );
    await _db.into(_db.visitSchedules).insert(td1Companion, mode: InsertMode.insertOrReplace);
    schedules.add(await (_db.select(_db.visitSchedules)..where((t) => t.id.equals(td1Id))).getSingle());

    final td2Companion = VisitSchedulesCompanion.insert(
      id: td2Id,
      memberId: womanId,
      programCode: 'anc',
      visitType: 'Td-2 Vaccination Contact (4 Weeks Post Td-1)',
      dueDate: td2Ms,
      dueWindowStart: Value(td2Ms - (14 * 24 * 60 * 60 * 1000)),
      dueWindowEnd: Value(td2Ms + (14 * 24 * 60 * 60 * 1000)),
      status: const Value('pending'),
      createdAt: now,
    );
    await _db.into(_db.visitSchedules).insert(td2Companion, mode: InsertMode.insertOrReplace);
    schedules.add(await (_db.select(_db.visitSchedules)..where((t) => t.id.equals(td2Id))).getSingle());

    return schedules;
  }

  // ── Helper: Record Immunization Incentive Event ────────────────────────────

  Future<void> _recordImmunizationIncentiveEvent({
    required String memberId,
    required String ashaId,
    required String encounterId,
    required String eventCode,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final eventId = _uuid.v4();
    final idempotencyKey = 'imm_${eventCode}_$memberId';

    final incCompanion = IncentiveEventsCompanion.insert(
      id: eventId,
      memberId: memberId,
      encounterId: Value(encounterId),
      activityCode: eventCode,
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

    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'incentive_events',
        recordId: eventId,
        operation: 'insert',
        priority: SyncPriority.metadata,
        payload: {
          'id': eventId,
          'activity_code': eventCode,
          'member_id': memberId,
          'encounter_id': encounterId,
          'event_date': now,
        },
      );
    }
  }
}

/// Riverpod provider for [ImmunizationRepository].
final immunizationRepositoryProvider = Provider<ImmunizationRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  final triageEngine = ref.watch(triageEngineProvider);
  return ImmunizationRepository(db, syncEngine, triageEngine);
});
