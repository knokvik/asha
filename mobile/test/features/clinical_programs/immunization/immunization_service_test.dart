import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart' hide TriageResult;
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/core/triage/triage_engine.dart';
import 'package:asha_platform/features/clinical_programs/immunization/data/immunization_repository.dart';
import 'package:asha_platform/features/clinical_programs/immunization/domain/immunization_models.dart';

void main() {
  group('Task 10.1: National Immunization Schedule & Dose Recording (Requirements 16.1 – 16.7)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late TriageEngine triageEngine;
    late ImmunizationRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      triageEngine = const TriageEngine();
      repo = ImmunizationRepository(db, syncEngine, triageEngine);

      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed Household
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_imm_1',
              village: 'Rampur',
              hamlet: const Value('North Hamlet'),
              headName: 'Ramesh Kumar',
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      // Seed Child Member (DOB: 6 weeks ago)
      final sixWeeksAgo = DateTime.now().subtract(const Duration(days: 42)).millisecondsSinceEpoch;
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'child_aarav_1',
              householdId: 'hh_imm_1',
              name: 'Aarav Kumar',
              sex: 'M',
              dobApprox: Value(sixWeeksAgo),
              relationshipToHead: const Value('Son'),
              phone: const Value('9876543210'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      // Seed Pregnant Mother Member
      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'woman_priya_1',
              householdId: 'hh_imm_1',
              name: 'Priya Devi',
              sex: 'F',
              relationshipToHead: const Value('Wife'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. Schedule Generation from DOB (Requirement 16.1) ────────────────────
    test('16.1: Generates complete National Immunization Schedule from DOB with accurate windows', () async {
      final dob = DateTime(2025, 1, 1);
      final schedules = await repo.generateScheduleForChild(
        memberId: 'child_aarav_1',
        dateOfBirth: dob,
        ashaId: 'asha_01',
      );

      // Total catalog items generated
      expect(schedules.length, equals(NationalImmunizationCatalog.infantAndChildSchedule.length));

      // Verify birth doses: BCG, OPV-0, HEPB-0
      final bcgTask = schedules.firstWhere((s) => s.id.contains('bcg'));
      expect(bcgTask.programCode, equals('immunization'));
      expect(bcgTask.visitType, contains('BCG'));
      expect(bcgTask.dueDate, equals(dob.millisecondsSinceEpoch));
      expect(bcgTask.status, equals('pending'));

      // Verify 6 weeks doses: OPV-1, PENTA-1, ROTA-1, FIPV-1, PCV-1
      final penta1Task = schedules.firstWhere((s) => s.id.contains('penta_1'));
      final expected6wMs = dob.add(const Duration(days: 42)).millisecondsSinceEpoch;
      expect(penta1Task.dueDate, equals(expected6wMs));

      // Verify 10 weeks doses: PENTA-2
      final penta2Task = schedules.firstWhere((s) => s.id.contains('penta_2'));
      final expected10wMs = dob.add(const Duration(days: 70)).millisecondsSinceEpoch;
      expect(penta2Task.dueDate, equals(expected10wMs));

      // Verify 14 weeks doses: PENTA-3
      final penta3Task = schedules.firstWhere((s) => s.id.contains('penta_3'));
      final expected14wMs = dob.add(const Duration(days: 98)).millisecondsSinceEpoch;
      expect(penta3Task.dueDate, equals(expected14wMs));

      // Verify 9-12 months doses: MR-1, VitA-1
      final mr1Task = schedules.firstWhere((s) => s.id.contains('mr_1'));
      final expected9mMs = dob.add(const Duration(days: 270)).millisecondsSinceEpoch;
      expect(mr1Task.dueDate, equals(expected9mMs));

      // Verify sync queue enqueued
      final syncItems = await db.select(db.syncQueue).get();
      expect(syncItems.any((item) => item.recordId == bcgTask.id), isTrue);
    });

    // ── 2. Dose Recording & Immunization Card View (Requirement 16.2) ──────────
    test('16.2: Records dose administration, writes observations, completes schedule, and updates card', () async {
      final dob = DateTime(2025, 1, 1);
      await repo.generateScheduleForChild(
        memberId: 'child_aarav_1',
        dateOfBirth: dob,
        ashaId: 'asha_01',
      );

      // Record BCG dose
      final adminDate = DateTime(2025, 1, 2);
      final encounter = await repo.recordDose(
        memberId: 'child_aarav_1',
        record: VaccineDoseRecord(
          vaccineCode: 'BCG',
          administeredDate: adminDate,
          bodySite: AdministrationSite.leftUpperArm,
          batchNumber: 'BCG-2025-BATCH01',
          sessionType: ImmunizationSessionType.vhsnd,
          administeredBy: 'ANM Maya',
          notes: 'Normal wheal formed at site',
        ),
        ashaId: 'asha_01',
      );

      expect(encounter.status, equals('completed'));
      expect(encounter.encounterType, equals('IMMUNIZATION_DOSE'));

      // Check discrete clinical observations
      final obs = await (db.select(db.clinicalObservations)..where((t) => t.encounterId.equals(encounter.id))).get();
      final obsMap = {for (final o in obs) o.observationCode: o.valueText};
      expect(obsMap['VACCINE_CODE'], equals('BCG'));
      expect(obsMap['BATCH_NUMBER'], equals('BCG-2025-BATCH01'));
      expect(obsMap['BODY_SITE'], equals(AdministrationSite.leftUpperArm.name));
      expect(obsMap['SESSION_TYPE'], equals(ImmunizationSessionType.vhsnd.name));
      expect(obsMap['ADMINISTERED_BY'], equals('ANM Maya'));

      // Verify VisitSchedule for BCG is marked completed
      final bcgSchedule = await (db.select(db.visitSchedules)..where((t) => t.id.equals('imm_child_aarav_1_bcg'))).getSingle();
      expect(bcgSchedule.status, equals('completed'));
      expect(bcgSchedule.completedEncounterId, equals(encounter.id));

      // Check immunization matrix card view
      final card = await repo.getImmunizationCard(memberId: 'child_aarav_1', dateOfBirth: dob);
      final bcgCardItem = card.firstWhere((c) => c.definition.code == 'BCG');
      expect(bcgCardItem.status, equals(VaccineDoseStatus.given));
      expect(bcgCardItem.isCompleted, isTrue);
      expect(bcgCardItem.doseRecord?.batchNumber, equals('BCG-2025-BATCH01'));
    });

    // ── 3. Defaulter Tracking & Catch-Up Schedule (Requirement 16.3) ───────────
    test('16.3: Identifies defaulters, enforces minimum intervals, and computes catch-up schedule', () async {
      // Child born 5 months ago (~150 days) with no vaccines
      final dob = DateTime.now().subtract(const Duration(days: 150));
      await repo.generateScheduleForChild(
        memberId: 'child_aarav_1',
        dateOfBirth: dob,
        ashaId: 'asha_01',
      );

      // Record a skip reason on one overdue schedule
      await (db.update(db.visitSchedules)..where((t) => t.id.equals('imm_child_aarav_1_penta_1'))).write(
        const VisitSchedulesCompanion(
          skipReason: Value('Family travelled out of station'),
        ),
      );

      final defaulters = await repo.getDefaulterList(hamlet: 'North Hamlet');
      expect(defaulters.length, equals(1));
      final defaulter = defaulters.first;
      expect(defaulter.childName, equals('Aarav Kumar'));
      expect(defaulter.recordedSkipReason, equals('Family travelled out of station'));
      expect(defaulter.missedDoses.isNotEmpty, isTrue);

      // Matrix evaluation checks:
      final card = await repo.getImmunizationCard(memberId: 'child_aarav_1', dateOfBirth: dob);

      // OPV-0 upper limit is 15 days -> At 150 days, OPV-0 must be EXPIRED
      final opv0 = card.firstWhere((c) => c.definition.code == 'OPV_0');
      expect(opv0.status, equals(VaccineDoseStatus.expired));
      expect(opv0.catchUpGuidance, contains('Omit dose'));

      // HepB-0 upper limit is 1 day -> Must be EXPIRED
      final hepB0 = card.firstWhere((c) => c.definition.code == 'HEPB_0');
      expect(hepB0.status, equals(VaccineDoseStatus.expired));

      // BCG can be given up to 1 year -> At 150 days, it is overdue/defaulter and eligible now
      final bcg = card.firstWhere((c) => c.definition.code == 'BCG');
      expect(bcg.status, equals(VaccineDoseStatus.defaulter));
      expect(bcg.catchUpGuidance, contains('Eligible for administration now'));

      // Penta-2 has prerequisite Penta-1 -> When Penta-1 is not given, catch-up advises giving Penta-1 first
      final penta2 = card.firstWhere((c) => c.definition.code == 'PENTA_2');
      expect(penta2.catchUpGuidance, contains('Administer PENTA_1 first, then wait 28 days'));

      // Now administer Penta-1 today, and test spacing advice for Penta-2
      await repo.recordDose(
        memberId: 'child_aarav_1',
        record: VaccineDoseRecord(
          vaccineCode: 'PENTA_1',
          administeredDate: DateTime.now(),
          bodySite: AdministrationSite.leftMidThigh,
        ),
        ashaId: 'asha_01',
      );

      final updatedCard = await repo.getImmunizationCard(memberId: 'child_aarav_1', dateOfBirth: dob);
      final updatedPenta2 = updatedCard.firstWhere((c) => c.definition.code == 'PENTA_2');
      expect(updatedPenta2.catchUpGuidance, contains('Minimum interval not reached. Administer PENTA_2 in 28 days'));
    });

    // ── 4. VHSND Session & Mobilisation (Requirement 16.4, 27) ─────────────────
    test('16.4 & 27: Plans VHSND session, generates due roster, and batch records outcomes', () async {
      final dob = DateTime.now().subtract(const Duration(days: 42)); // 6 weeks
      await repo.generateScheduleForChild(
        memberId: 'child_aarav_1',
        dateOfBirth: dob,
        ashaId: 'asha_01',
      );

      final session = await repo.planVhsndSession(
        sessionDate: DateTime.now(),
        villageName: 'Rampur',
        hamlet: 'North Hamlet',
        anganwadiCenterName: 'AWC Rampur 1',
        ashaId: 'asha_01',
      );

      expect(session.villageName, equals('Rampur'));
      expect(session.beneficiariesDue.isNotEmpty, isTrue);

      final aaravDue = session.beneficiariesDue.firstWhere((b) => b.memberId == 'child_aarav_1');
      expect(aaravDue.beneficiaryName, equals('Aarav Kumar'));
      expect(aaravDue.dueVaccines.isNotEmpty, isTrue);

      // Simulate mobilisation and attendance: mark attended and services delivered
      final completedRoster = [
        aaravDue.copyWith(
          isMobilized: true,
          attended: true,
          servicesDelivered: ['OPV_1: OPV-1', 'PENTA_1: Pentavalent-1'],
        ),
      ];

      await repo.recordVhsndSessionOutcomes(
        sessionId: session.id,
        ashaId: 'asha_01',
        completedRoster: completedRoster,
        sessionDate: DateTime.now(),
      );

      // Verify that OPV-1 and PENTA-1 doses were recorded into Aarav's card
      final card = await repo.getImmunizationCard(memberId: 'child_aarav_1', dateOfBirth: dob);
      final opv1 = card.firstWhere((c) => c.definition.code == 'OPV_1');
      final penta1 = card.firstWhere((c) => c.definition.code == 'PENTA_1');
      expect(opv1.isCompleted, isTrue);
      expect(penta1.isCompleted, isTrue);
    });

    // ── 5. AEFI Surveillance & Urgent Triage (Requirement 16.6) ────────────────
    test('16.6: Urgent AEFI triggers RED flag, generates emergency referral, and critical sync alert', () async {
      final aefi = await repo.recordAefi(
        memberId: 'child_aarav_1',
        childName: 'Aarav Kumar',
        vaccineCode: 'PENTA_1',
        sessionDate: DateTime.now(),
        onsetHoursAfterDose: 3,
        symptoms: [AefiSymptoms.anaphylaxis, AefiSymptoms.highFeverGt39c],
        severity: AefiSeverity.serious,
        actionTaken: 'First aid given, 108 ambulance called',
        ashaId: 'asha_01',
      );

      expect(aefi.isUrgent, isTrue);
      expect(aefi.triageFlag, equals(TriageFlag.red));

      // Verify RED flag in TriageResults table
      final triage = await (db.select(db.triageResults)..where((t) => t.flag.equals('RED'))).get();
      expect(triage.isNotEmpty, isTrue);
      expect(triage.first.findingsJson, contains('Urgent AEFI symptoms'));

      // Verify Emergency Referral Record created in referral_records
      final referrals = await (db.select(db.referralRecords)..where((t) => t.memberId.equals('child_aarav_1'))).get();
      expect(referrals.isNotEmpty, isTrue);
      expect(referrals.first.triageFlag, equals('RED'));
      expect(referrals.first.transportArranged, equals('108_AMBULANCE'));

      // Verify Critical P1 Sync alert enqueued
      final syncItems = await (db.select(db.syncQueue)..where((t) => t.recordId.equals(aefi.id))).get();
      expect(syncItems.isNotEmpty, isTrue);
      expect(syncItems.first.priority, equals(1)); // P1 Critical
    });

    test('16.6: Minor AEFI records GREEN triage and does not generate emergency referral', () async {
      final aefi = await repo.recordAefi(
        memberId: 'child_aarav_1',
        childName: 'Aarav Kumar',
        vaccineCode: 'OPV_1',
        sessionDate: DateTime.now(),
        onsetHoursAfterDose: 12,
        symptoms: [AefiSymptoms.mildFever, AefiSymptoms.localSwelling],
        severity: AefiSeverity.minor,
        actionTaken: 'Advised paracetamol and cold compress',
        ashaId: 'asha_01',
      );

      expect(aefi.isUrgent, isFalse);
      expect(aefi.triageFlag, equals(TriageFlag.green));

      // Check that NO new emergency referral was created
      final redReferrals = await (db.select(db.referralRecords)..where((t) => t.memberId.equals('child_aarav_1') & t.referralNoteText.like('%OPV_1%'))).get();
      expect(redReferrals.isEmpty, isTrue);

      // Verify P2 sync queue priority
      final syncItems = await (db.select(db.syncQueue)..where((t) => t.recordId.equals(aefi.id))).get();
      expect(syncItems.first.priority, equals(2)); // P2 Clinical
    });

    // ── 6. Pregnant Women Td Schedule (Requirement 16.7) ───────────────────────
    test('16.7: Ensures Td-1 and Td-2 schedules are included in ANC due list', () async {
      final lmp = DateTime(2025, 3, 1);
      final schedules = await repo.ensurePregnantWomanTdSchedule(
        womanId: 'woman_priya_1',
        lmp: lmp,
        ashaId: 'asha_01',
      );

      expect(schedules.length, equals(2));
      final td1 = schedules.firstWhere((s) => s.id.contains('td1'));
      final td2 = schedules.firstWhere((s) => s.id.contains('td2'));

      expect(td1.programCode, equals('anc'));
      expect(td1.visitType, contains('Td-1'));

      expect(td2.programCode, equals('anc'));
      expect(td2.visitType, contains('Td-2'));

      // Td-2 due date is 4 weeks after Td-1
      final diffDays = (td2.dueDate - td1.dueDate) / (24 * 60 * 60 * 1000);
      expect(diffDays, closeTo(28, 0.1));
    });

    // ── 7. Full Immunization Incentive Event (Requirement 16.2, Task 10.1) ──────
    test('Full Immunization at 1 year generates FULL_IMMUNIZATION_1YR incentive event', () async {
      await repo.recordDose(
        memberId: 'child_aarav_1',
        record: VaccineDoseRecord(
          vaccineCode: 'VITA_1',
          administeredDate: DateTime.now(),
          bodySite: AdministrationSite.oral,
        ),
        ashaId: 'asha_01',
      );

      final incentives = await (db.select(db.incentiveEvents)..where((t) => t.memberId.equals('child_aarav_1'))).get();
      expect(incentives.isNotEmpty, isTrue);
      expect(incentives.first.activityCode, equals('FULL_IMMUNIZATION_1YR'));
      expect(incentives.first.status, equals('eligible'));
    });
  });
}
