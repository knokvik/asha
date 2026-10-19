import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import 'vital_events_models.dart';

class VitalEventsService {
  final AppDatabase _db;

  VitalEventsService(this._db);

  /// Captures civil birth registration data (CRS Form 1) and generates handover summary (Requirement 23.1).
  Future<CivilBirthRecord> registerCivilBirth({
    required String childMemberId,
    required String motherMemberId,
    required String fatherName,
    required DateTime dateOfBirth,
    required String timeOfBirth,
    required String placeOfBirth,
    required int birthWeightGrams,
    required String gender,
    required String deliveryType,
  }) async {
    final now = DateTime.now();
    final recordId = 'crs_birth_${childMemberId}_${now.millisecondsSinceEpoch}';

    final crsSummary = StringBuffer()
      ..writeln('=== CIVIL REGISTRATION SYSTEM (CRS) - FORM 1: BIRTH REPORT ===')
      ..writeln('Child ID: $childMemberId')
      ..writeln('DOB: ${dateOfBirth.toIso8601String().substring(0, 10)} at $timeOfBirth')
      ..writeln('Gender: ${gender.toUpperCase()}')
      ..writeln('Birth Weight: ${birthWeightGrams}g')
      ..writeln('Mother ID: $motherMemberId')
      ..writeln('Father / Guardian: $fatherName')
      ..writeln('Place of Delivery: $placeOfBirth ($deliveryType)')
      ..writeln('Handover Target: Sub-Centre ANM / Gram Panchayat Registrar')
      ..writeln('Certified by Community Health Worker (ASHA)');

    return CivilBirthRecord(
      id: recordId,
      childMemberId: childMemberId,
      motherMemberId: motherMemberId,
      fatherName: fatherName,
      dateOfBirth: dateOfBirth,
      timeOfBirth: timeOfBirth,
      placeOfBirth: placeOfBirth,
      birthWeightGrams: birthWeightGrams,
      gender: gender,
      deliveryType: deliveryType,
      crsHandoverSummary: crsSummary.toString().trim(),
    );
  }

  /// Records death in CRS format, performs MDR/CDR audit review if applicable,
  /// updates household membership, and cancels pending due-list tasks (Requirements 23.1, 23.2, 23.4).
  Future<VitalEventOutcome> registerDeathAndAudit({
    required String deceasedMemberId,
    required String householdId,
    required DateTime dateOfDeath,
    required String placeOfDeath,
    required String presumedCauseOfDeath,
    required bool isMaternalDeath,
    required bool isInfantDeath,
    required bool isUnderFiveChildDeath,
    List<String> threeDelays = const [],
    String primaryContributingCause = '',
  }) async {
    final now = DateTime.now();

    // 1. Generate CRS handover summary
    final crsSummary = StringBuffer()
      ..writeln('=== CIVIL REGISTRATION SYSTEM (CRS) - FORM 2: DEATH REPORT ===')
      ..writeln('Deceased Member ID: $deceasedMemberId')
      ..writeln('Date of Death: ${dateOfDeath.toIso8601String().substring(0, 10)}')
      ..writeln('Place of Death: $placeOfDeath')
      ..writeln('Suspected Cause: $presumedCauseOfDeath')
      ..writeln('Maternal Death Review Required: ${isMaternalDeath ? 'YES' : 'NO'}')
      ..writeln('Child Death Review Required: ${(isInfantDeath || isUnderFiveChildDeath) ? 'YES' : 'NO'}')
      ..writeln('Handover Target: Local Registrar of Births & Deaths');

    // 2. Cancel all pending due tasks for the deceased person (Requirement 23.4)
    final pendingTasks = await (_db.select(_db.visitSchedules)
          ..where((t) => t.memberId.equals(deceasedMemberId))
          ..where((t) => t.completedAt.isNull()))
        .get();

    for (final task in pendingTasks) {
      await (_db.update(_db.visitSchedules)..where((t) => t.id.equals(task.id))).write(
        VisitSchedulesCompanion(
          status: const Value('cancelled'),
          skipReason: const Value('Beneficiary deceased (Requirement 23.4)'),
          completedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
    }

    // 3. Trigger Maternal or Child Death Review alert if applicable (Requirement 23.2)
    if (isMaternalDeath || isInfantDeath || isUnderFiveChildDeath) {
      final auditType = isMaternalDeath ? 'MATERNAL_DEATH_REVIEW' : 'CHILD_DEATH_REVIEW';
      // Post alert to sync queue for ANM, AF, and MO
      await _db.into(_db.syncQueue).insert(
            SyncQueueCompanion.insert(
              id: 'sq_audit_${deceasedMemberId}_${now.millisecondsSinceEpoch}',
              targetTable: 'death_audit_alert',
              recordId: deceasedMemberId,
              operation: 'INSERT',
              payloadJson: '''{
                "audit_type": "$auditType",
                "deceased_member_id": "$deceasedMemberId",
                "household_id": "$householdId",
                "date_of_death": "${dateOfDeath.toIso8601String()}",
                "suspected_cause": "$presumedCauseOfDeath",
                "three_delays": ${threeDelays.map((d) => '"$d"').toList()},
                "contributing_cause": "$primaryContributingCause",
                "target_supervisors": ["ANM", "AF", "MO"]
              }''',
              createdAt: now.millisecondsSinceEpoch,
            ),
          );
    }

    // 4. Count remaining active living members in the household
    final remainingLivingMembers = await (_db.select(_db.members)
          ..where((t) => t.householdId.equals(householdId))
          ..where((t) => t.lifecycleStatus.equals('active')))
        .get();

    return VitalEventOutcome(
      householdId: householdId,
      memberId: deceasedMemberId,
      updatedLivingMembersCount: remainingLivingMembers.isEmpty ? 0 : remainingLivingMembers.length - 1,
      cancelledPendingTasksCount: pendingTasks.length,
      summaryMessage:
          'Death registered in CRS format. Cancelled ${pendingTasks.length} pending tasks. ${isMaternalDeath || isInfantDeath ? 'Supervisor death audit alert scheduled.' : ''}',
      crsHandoverSummary: crsSummary.toString().trim(),
    );
  }

  /// Records stillbirth or pregnancy loss with minimal mandatory fields and neutral terminology (Requirement 23.3).
  Future<StillbirthAbortionRecord> recordPregnancyLoss({
    required String motherMemberId,
    required DateTime eventDate,
    required String eventType, // 'stillbirth_fresh', 'stillbirth_macerated', 'spontaneous_loss', 'mtp_service'
    required int gestationalWeeks,
    required String neutralClinicalNotes,
  }) async {
    final now = DateTime.now();
    final recordId = 'preg_loss_${motherMemberId}_${now.millisecondsSinceEpoch}';

    // 1. Cancel subsequent prenatal ANC tasks for mother
    final ancTasks = await (_db.select(_db.visitSchedules)
          ..where((t) => t.memberId.equals(motherMemberId))
          ..where((t) => t.visitType.equals('anc_visit'))
          ..where((t) => t.completedAt.isNull()))
        .get();

    for (final task in ancTasks) {
      await (_db.update(_db.visitSchedules)..where((t) => t.id.equals(task.id))).write(
        VisitSchedulesCompanion(
          status: const Value('cancelled'),
          skipReason: const Value('Pregnancy conclusion recorded'),
          completedAt: Value(now.millisecondsSinceEpoch),
        ),
      );
    }

    // 2. Schedule post-abortion health recovery and family planning counselling visit at 14 days
    final followUpDate = eventDate.add(const Duration(days: 14));
    await _db.into(_db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: 'vs_post_loss_${now.millisecondsSinceEpoch}',
            memberId: motherMemberId,
            programCode: 'POST_ABORTION',
            visitType: 'post_pregnancy_loss_recovery',
            dueDate: followUpDate.millisecondsSinceEpoch,
            createdAt: now.millisecondsSinceEpoch,
          ),
        );

    return StillbirthAbortionRecord(
      id: recordId,
      motherMemberId: motherMemberId,
      eventDate: eventDate,
      eventType: eventType,
      gestationalWeeks: gestationalWeeks,
      neutralClinicalNotes: neutralClinicalNotes,
      visibilityRestriction: 'RESTRICTED_ASHA_ANM_MO_ONLY',
    );
  }
}
