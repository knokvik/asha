import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/features/vhsnd/data/vhsnd_repository.dart';
import 'package:asha_platform/features/vhsnd/domain/vhsnd_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 12.3: VHSND Session Planning, Health Education & Campaigns (Requirements 27.1 – 27.6)', () {
    // ── 1. Domain Models ─────────────────────────────────────────────────────
    group('VHSND Domain Models', () {
      test('maps service types and beneficiary models cleanly', () {
        expect(VhsndServiceType.fromCode('immunization'), equals(VhsndServiceType.immunization));
        expect(VhsndServiceType.fromCode('anc'), equals(VhsndServiceType.anc));
        expect(VhsndServiceType.fromCode('cbac'), equals(VhsndServiceType.cbac));
        expect(VhsndServiceType.fromCode('family_planning'), equals(VhsndServiceType.familyPlanning));

        const beneficiary = VhsndDueBeneficiary(
          memberId: 'm_01',
          memberName: 'Aarti Devi',
          householdId: 'hh_01',
          hamlet: 'North Tola',
          sex: 'F',
          ageMonths: 288,
          serviceType: VhsndServiceType.anc,
          dueServiceDetails: 'ANC Checkup 3 & Td-2',
        );

        final json = beneficiary.toJson();
        final restored = VhsndDueBeneficiary.fromJson(json);

        expect(restored.memberId, equals('m_01'));
        expect(restored.serviceType, equals(VhsndServiceType.anc));
        expect(restored.dueServiceDetails, equals('ANC Checkup 3 & Td-2'));
        expect(restored.isMobilised, isFalse);

        final mobilised = beneficiary.copyWith(isMobilised: true, hasAttended: true);
        expect(mobilised.isMobilised, isTrue);
        expect(mobilised.hasAttended, isTrue);
      });

      test('calculates session attendance metrics and services map correctly', () {
        final session = VhsndSession(
          id: 'sess_01',
          village: 'Devpur',
          anganwadiCenter: 'AWC Center 1',
          sessionDate: DateTime(2025, 5, 15),
          anmName: 'ANM Sunita',
          ashaName: 'ASHA Suman',
          anganwadiWorkerName: 'AWW Rekha',
          beneficiaries: [
            const VhsndDueBeneficiary(
              memberId: 'm_1',
              memberName: 'Rohan',
              householdId: 'hh_1',
              hamlet: 'North Tola',
              sex: 'M',
              serviceType: VhsndServiceType.immunization,
              dueServiceDetails: 'Pentavalent 1',
              isMobilised: true,
              hasAttended: true,
              servicesDelivered: ['Pentavalent 1', 'Rota 1'],
            ),
            const VhsndDueBeneficiary(
              memberId: 'm_2',
              memberName: 'Pooja',
              householdId: 'hh_1',
              hamlet: 'North Tola',
              sex: 'F',
              serviceType: VhsndServiceType.anc,
              dueServiceDetails: 'ANC Checkup 2',
              isMobilised: true,
              hasAttended: true,
              servicesDelivered: ['ANC-2', 'IFA 100 Tablets'],
            ),
            const VhsndDueBeneficiary(
              memberId: 'm_3',
              memberName: 'Ramesh',
              householdId: 'hh_2',
              hamlet: 'South Basti',
              sex: 'M',
              serviceType: VhsndServiceType.cbac,
              dueServiceDetails: 'CBAC Assessment',
              isMobilised: false,
              hasAttended: false,
            ),
          ],
          mobilisationChecklist: const [
            MobilisationChecklistItem(
              id: 'c_1',
              title: 'Check Vaccine Carrier',
              description: 'Inspect ice packs',
              isCompleted: true,
            ),
          ],
        );

        expect(session.totalMobilised, equals(2));
        expect(session.totalAttended, equals(2));
        expect(session.totalUnservedGaps, equals(0));

        final perService = session.attendancePerService;
        expect(perService[VhsndServiceType.immunization], equals(1));
        expect(perService[VhsndServiceType.anc], equals(1));
        expect(perService[VhsndServiceType.cbac], isNull);
      });

      test('validates active campaign date intervals', () {
        final campaign = CommunityCampaign(
          id: 'camp_01',
          campaignCode: 'pulse_polio',
          title: 'Pulse Polio NID',
          startDate: DateTime(2025, 1, 1),
          endDate: DateTime(2025, 12, 31),
          checklistItems: ['Mark fingers', 'Check VVM'],
          targetDescription: '0-5 years',
        );

        expect(campaign.isActiveOn(DateTime(2025, 6, 1)), isTrue);
        expect(campaign.isActiveOn(DateTime(2024, 12, 31)), isFalse);
        expect(campaign.isActiveOn(DateTime(2026, 1, 1)), isFalse);
      });
    });

    // ── 2. VHSND Repository, Beneficiary Discovery & Timelines ───────────────
    group('VhsndRepository Execution & Timelines (Req 27.1, 27.2)', () {
      late AppDatabase db;
      late SyncEngine syncEngine;
      late VhsndRepository repository;

      final sessionDate = DateTime(2025, 5, 15, 10, 0);
      final sessionMs = sessionDate.millisecondsSinceEpoch;

      setUp(() async {
        db = AppDatabase.forTesting(NativeDatabase.memory());
        syncEngine = SyncEngine(db);
        repository = VhsndRepository(db, syncEngine);

        // Seed Household
        await db.into(db.households).insert(
              HouseholdsCompanion.insert(
                id: 'hh_devpur_10',
                village: 'Devpur',
                hamlet: const Value('East Purwa'),
                headName: 'Kailash Prasad',
                createdAt: sessionMs,
                updatedAt: sessionMs,
                createdBy: 'asha_01',
              ),
            );

        // Seed Member 1: Pregnant Mother (ANC Due)
        await db.into(db.members).insert(
              MembersCompanion.insert(
                id: 'member_anita_anc',
                householdId: 'hh_devpur_10',
                name: 'Anita Devi',
                sex: 'F',
                createdAt: sessionMs,
                updatedAt: sessionMs,
                createdBy: 'asha_01',
              ),
            );

        // Seed Member 2: Infant (Immunization Due)
        await db.into(db.members).insert(
              MembersCompanion.insert(
                id: 'member_baby_immu',
                householdId: 'hh_devpur_10',
                name: 'Sonu',
                sex: 'M',
                createdAt: sessionMs,
                updatedAt: sessionMs,
                createdBy: 'asha_01',
              ),
            );

        // Seed Visit Schedule for Mother (ANC Checkup on Session Date)
        await db.into(db.visitSchedules).insert(
              VisitSchedulesCompanion.insert(
                id: 'sched_vhsnd_anc_01',
                memberId: 'member_anita_anc',
                programCode: 'anc',
                visitType: 'ANC Checkup 3',
                dueDate: sessionMs,
                createdAt: sessionMs,
              ),
            );

        // Seed Visit Schedule for Baby (Pentavalent 1 on Session Date)
        await db.into(db.visitSchedules).insert(
              VisitSchedulesCompanion.insert(
                id: 'sched_vhsnd_immu_01',
                memberId: 'member_baby_immu',
                programCode: 'immunization',
                visitType: 'Pentavalent 1 + OPV 1',
                dueDate: sessionMs,
                createdAt: sessionMs,
              ),
            );
      });

      tearDown(() async {
        await db.close();
      });

      test('generates VHSND plan discovering due beneficiaries across services (Req 27.1)', () async {
        final plan = await repository.generateVhsndPlan(
          village: 'Devpur',
          anganwadiCenter: 'AWC Center East Purwa',
          sessionDate: sessionDate,
        );

        expect(plan.village, equals('Devpur'));
        expect(plan.anganwadiCenter, equals('AWC Center East Purwa'));
        expect(plan.beneficiaries.length, equals(2));

        final ancBeneficiary = plan.beneficiaries.firstWhere((b) => b.serviceType == VhsndServiceType.anc);
        expect(ancBeneficiary.memberId, equals('member_anita_anc'));
        expect(ancBeneficiary.dueServiceDetails, equals('ANC Checkup 3'));

        final immuBeneficiary = plan.beneficiaries.firstWhere((b) => b.serviceType == VhsndServiceType.immunization);
        expect(immuBeneficiary.memberId, equals('member_baby_immu'));
        expect(immuBeneficiary.dueServiceDetails, contains('Pentavalent 1'));

        // Check mobilisation checklist is populated
        expect(plan.mobilisationChecklist.length, greaterThanOrEqualTo(5));
      });

      test('records attendance, services given, and updates beneficiary timelines (Req 27.2)', () async {
        final plan = await repository.generateVhsndPlan(
          village: 'Devpur',
          anganwadiCenter: 'AWC Center East Purwa',
          sessionDate: sessionDate,
        );

        // Mark Mother as Attended with delivered services
        final updatedAnita = plan.beneficiaries
            .firstWhere((b) => b.memberId == 'member_anita_anc')
            .copyWith(
              isMobilised: true,
              hasAttended: true,
              servicesDelivered: ['ANC Checkup 3', 'Td Booster', 'IFA Tablets'],
            );

        // Mark Baby as Mobilised but Not Attended (Service gap)
        final updatedSonu = plan.beneficiaries
            .firstWhere((b) => b.memberId == 'member_baby_immu')
            .copyWith(
              isMobilised: true,
              hasAttended: false,
              serviceGapNotes: 'Child had mild fever; deferred to next session',
            );

        await repository.recordSessionAttendanceAndServices(
          sessionId: plan.id,
          attendances: [updatedAnita, updatedSonu],
          sessionSummaryNotes: 'Successful session with ANM Sunita; 1 child missed due to fever',
          communityFeedbackNotes: 'Villagers requested additional water purification tablets',
        );

        // 1. Verify Clinical Encounter was created for Anita (Timeline update)
        final encounters = await (db.select(db.clinicalEncounters)
              ..where((e) => e.memberId.equals('member_anita_anc')))
            .get();
        expect(encounters.length, equals(1));
        expect(encounters.first.encounterType, equals('vhsnd_service'));
        expect(encounters.first.status, equals('completed'));

        // 2. Verify Visit Schedule for Anita was marked completed
        final anitaSchedule = await (db.select(db.visitSchedules)
              ..where((s) => s.id.equals('sched_vhsnd_anc_01')))
            .getSingle();
        expect(anitaSchedule.status, equals('completed'));
        expect(anitaSchedule.completedEncounterId, equals(encounters.first.id));
        expect(anitaSchedule.completedAt, isNotNull);

        // 3. Verify Baby schedule remains open / pending
        final sonuSchedule = await (db.select(db.visitSchedules)
              ..where((s) => s.id.equals('sched_vhsnd_immu_01')))
            .getSingle();
        expect(sonuSchedule.status, equals('pending'));
        expect(sonuSchedule.completedAt, isNull);

        // 4. Verify sync queue contains clinical encounter
        final syncItems = await db.select(db.syncQueue).get();
        expect(syncItems.any((i) => i.targetTable == 'clinical_encounters'), isTrue);
      });
    });

    // ── 3. VHSNC Meetings, Health Education & Campaigns (Req 27.3 – 27.6) ────
    group('VHSNC Meetings, Multimedia Education & Campaigns (Req 27.3 – 27.6)', () {
      late AppDatabase db;
      late SyncEngine syncEngine;
      late VhsndRepository repository;

      setUp(() async {
        db = AppDatabase.forTesting(NativeDatabase.memory());
        syncEngine = SyncEngine(db);
        repository = VhsndRepository(db, syncEngine);
      });

      tearDown(() async {
        await db.close();
      });

      test('records VHSNC meeting and enqueues for supervisor sync (Req 27.3, 27.6)', () async {
        final meeting = await repository.recordVhsncMeeting(
          village: 'Devpur',
          meetingDate: DateTime(2025, 5, 20),
          participantsCount: 18,
          decisionsMade: [
            'Repair handpump near Anganwadi Center',
            'Conduct bleaching powder spray in open drains',
          ],
          agreedFollowUpActions: [
            'Panchayat Pradhan to allocate 5000 INR from untied funds',
            'ASHA Suman to inspect water sample after bleaching',
          ],
          communityFeedbackSummary: 'Residents concerned about mosquito breeding in South Basti ditch.',
        );

        expect(meeting.id, isNotEmpty);
        expect(meeting.participantsCount, equals(18));
        expect(meeting.decisionsMade.length, equals(2));

        // Verify record in SQLite table
        final rows = await db.customSelect('SELECT * FROM vhsnc_meetings WHERE id = ?;', variables: [Variable.withString(meeting.id)]).get();
        expect(rows.length, equals(1));
        expect(rows.first.read<String>('village'), equals('Devpur'));

        // Verify sync queue enqueues meeting to route to AF and VHSNC (Req 27.6)
        final syncItems = await db.select(db.syncQueue).get();
        expect(syncItems.any((i) => i.targetTable == 'vhsnc_meetings'), isTrue);
      });

      test('searches offline multimedia health education assets (Req 27.4)', () async {
        await repository.ensureVhsndTablesExist();

        // 1. Filter by topic: Maternal Health
        final maternalAssets = await repository.searchHealthEducationAssets(
          topic: HealthEducationTopic.maternalHealth,
        );
        expect(maternalAssets, isNotEmpty);
        expect(maternalAssets.first.topic, equals(HealthEducationTopic.maternalHealth));

        // 2. Filter by media type: illustrated_card
        final cards = await repository.searchHealthEducationAssets(
          mediaType: 'illustrated_card',
        );
        expect(cards, isNotEmpty);
        expect(cards.every((c) => c.mediaType == 'illustrated_card'), isTrue);

        // 3. Free text search: 'handwashing' or 'wash'
        final washAssets = await repository.searchHealthEducationAssets(searchQuery: 'handwashing');
        expect(washAssets, isNotEmpty);
        expect(washAssets.first.title.toLowerCase(), contains('handwashing'));
      });

      test('provides active public health campaigns with operational checklists (Req 27.5)', () {
        final campaigns = repository.getActiveCampaigns(DateTime(2025, 5, 10));

        expect(campaigns, isNotEmpty);
        final codes = campaigns.map((c) => c.campaignCode).toList();

        // Must include all core national programs
        expect(codes, contains('pulse_polio'));
        expect(codes, contains('mda'));
        expect(codes, contains('ifa_week'));
        expect(codes, contains('tb_active_case'));

        final tbCampaign = campaigns.firstWhere((c) => c.campaignCode == 'tb_active_case');
        expect(tbCampaign.checklistItems.any((i) => i.contains('sputum')), isTrue);
      });
    });
  });
}
