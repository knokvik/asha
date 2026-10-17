import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart' hide TriageResult;
import 'package:asha_platform/core/pdf/pdf_generator.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/features/household/data/timeline_repository.dart';
import 'package:asha_platform/features/referral/data/referral_repository.dart';
import 'package:asha_platform/features/referral/domain/facility_matcher.dart';
import 'package:asha_platform/features/referral/domain/referral_models.dart';
import 'package:asha_platform/features/referral/domain/referral_note_generator.dart';
import 'package:asha_platform/features/referral/domain/sms_fallback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 8.6: Full Referral Lifecycle & Integration Tests', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late ReferralRepository referralRepo;
    late TimelineRepository timelineRepo;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('referral_lifecycle_test_');
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      referralRepo = ReferralRepository(db, syncEngine);
      timelineRepo = TimelineRepository(db);

      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed local facility directory with various tiers
      await db.into(db.facilityDirectory).insert(
            FacilityDirectoryCompanion.insert(
              id: 'fac_sc_rampur',
              name: 'Rampur Health Sub-Centre',
              facilityLevel: 'SUB_CENTRE',
              district: const Value('Gopalganj'),
              latitude: const Value(26.40),
              longitude: const Value(84.40),
              servicesJson: const Value('["OPD", "IMMUNIZATION"]'),
              isActive: const Value(true),
              lastUpdatedAt: now,
            ),
          );

      await db.into(db.facilityDirectory).insert(
            FacilityDirectoryCompanion.insert(
              id: 'fac_chc_gopalganj',
              name: 'Gopalganj Community Health Centre',
              facilityLevel: 'CHC',
              district: const Value('Gopalganj'),
              latitude: const Value(26.48),
              longitude: const Value(84.45),
              contactPhone: const Value('06156-225010'),
              servicesJson: const Value('["EMERGENCY", "FRU", "24x7_DELIVERY", "BLOOD_STORAGE"]'),
              isActive: const Value(true),
              lastUpdatedAt: now,
            ),
          );

      await db.into(db.facilityDirectory).insert(
            FacilityDirectoryCompanion.insert(
              id: 'fac_dh_sadar',
              name: 'District Sadar Hospital & SNCU',
              facilityLevel: 'SNCU',
              district: const Value('Gopalganj'),
              latitude: const Value(26.56),
              longitude: const Value(84.52),
              contactPhone: const Value('06156-222100'),
              servicesJson: const Value('["SNCU", "ICU", "SURGERY", "SPECIALTY_OBSTETRICS"]'),
              isActive: const Value(true),
              lastUpdatedAt: now,
            ),
          );
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
        'Complete Lifecycle: RED triage -> offline match -> PDF generated -> P1 sync -> '
        'status transit -> outcome recorded -> timeline updated (Requirements 10.1, 10.4, 10.5)',
        () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final dob22YearsAgo = DateTime.now().subtract(const Duration(days: 22 * 366)).millisecondsSinceEpoch;

      // 1. Beneficiary & ASHA Setup
      final member = Member(
        id: 'mem_lifecycle_1',
        householdId: 'hh_lifecycle_1',
        name: 'Priyanka Devi',
        sex: 'F',
        dobApprox: dob22YearsAgo,
        isDobApprox: false,
        relationshipToHead: 'Wife',
        phone: '9876543210',
        abhaId: 'ABHA-1234-5678-9012',
        lifecycleStatus: 'active',
        consentStatus: 'granted',
        syncStatus: 'pending',
        createdAt: now,
        updatedAt: now,
        createdBy: 'asha_01',
      );

      final household = Household(
        id: 'hh_lifecycle_1',
        headName: 'Vijay Kumar',
        village: 'Rampur',
        hamlet: 'West Tola',
        isBpl: true,
        memberCount: 3,
        createdAt: now,
        updatedAt: now,
        createdBy: 'asha_01',
        syncStatus: 'pending',
      );

      final ashaUser = User(
        id: 'asha_user_01',
        ashaId: 'ASHA-001',
        name: 'Sunita Sharma',
        role: 'ASHA',
        areaVillage: 'Rampur',
        areaSubcentre: 'Rampur SC',
        failedPinAttempts: 0,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      // 2. RED Triage Assessment
      final redTriage = TriageResult(
        id: 'tri_lifecycle_1',
        flag: TriageFlag.red,
        ruleFlag: TriageFlag.red,
        ruleVersionId: '1.0.0',
        evaluatedAt: DateTime.now(),
        findings: const [
          TriageFinding(
            ruleId: 'MATERNAL_POSTPARTUM_HEMORRHAGE',
            severity: TriageFlag.red,
            findingText: 'Severe postpartum hemorrhage with tachycardia and hypotension',
            action: 'EMERGENCY_TRANSFER_TO_FRU_OR_CHC',
            triggeringValues: {'pulse': 130, 'blood_loss': 'severe'},
          ),
        ],
      );

      // 3. Offline Nearest Facility Matching (Requirement 10.3)
      final matchedFacilities = await FacilityMatcher.matchFromDb(
        db: db,
        triageFlag: redTriage.flag,
        ashaLatitude: 26.40,
        ashaLongitude: 84.40,
      );

      expect(matchedFacilities.isNotEmpty, isTrue);
      // RED case must recommend CHC / SNCU, never Sub-Centre
      expect(matchedFacilities.first.level, FacilityLevel.chc);
      expect(matchedFacilities.first.name, 'Gopalganj Community Health Centre');
      expect(matchedFacilities.first.distanceKm, isNotNull);
      expect(matchedFacilities.first.distanceKm!, greaterThan(0));

      final selectedFacility = matchedFacilities.first;

      // 4. Assemble Structured Referral Note (Requirement 10.1, 10.7)
      final note = ReferralNoteGenerator.generate(
        triageResult: redTriage,
        member: member,
        household: household,
        ashaUser: ashaUser,
        destinationFacility: selectedFacility,
        transportArranged: '108 Emergency Ambulance',
        rawVitals: {'pulse': '130 bpm', 'bp': '85/55 mmHg'},
      );

      expect(note.triageFlag, TriageFlag.red);
      expect(note.patient.name, 'Priyanka Devi');
      expect(note.destinationFacility?.name, 'Gopalganj Community Health Centre');
      expect(note.toQrPayload(), contains('"flag":"RED"'));

      // 5. Generate Print-Ready PDF in Standard and Thermal Receipt Formats (Requirement 10.2)
      final standardPdfBytes = await PdfGenerator.generateReferralPdf(note, thermalLayout: false);
      final thermalPdfBytes = await PdfGenerator.generateReferralPdf(note, thermalLayout: true);

      expect(standardPdfBytes.length, greaterThan(1000));
      expect(thermalPdfBytes.length, greaterThan(1000));

      final pdfFile = await PdfGenerator.savePdfToFile(
        standardPdfBytes,
        note.referralId,
        overrideDirectory: tempDir,
      );
      expect(pdfFile.existsSync(), isTrue);

      // 6. Persist to Local SQLite Database via ReferralRepository
      final record = await referralRepo.createReferral(
        note: note,
        pdfPath: pdfFile.path,
        transportArranged: '108 Emergency Ambulance',
      );

      expect(record.id, note.referralId);
      expect(record.status, 'created');
      expect(record.triageFlag, 'RED');

      // 7. Verify P1 Critical Sync Queueing for RED Referral (Requirement 31.1)
      final queueEntries = await db.select(db.syncQueue).get();
      final referralSyncEntry = queueEntries.firstWhere((q) => q.recordId == record.id);
      expect(referralSyncEntry.priority, 1, reason: 'RED referrals must be queued at P1 Critical priority');
      expect(referralSyncEntry.targetTable, 'referral_records');

      // 8. Referral Lifecycle Transit: created -> en_route -> arrived
      await referralRepo.updateStatus(
        referralId: record.id,
        newStatus: ReferralStatus.enRoute,
      );
      var current = await referralRepo.getReferral(record.id);
      expect(current?.status, 'en_route');

      await referralRepo.updateStatus(
        referralId: record.id,
        newStatus: ReferralStatus.arrived,
      );
      current = await referralRepo.getReferral(record.id);
      expect(current?.status, 'arrived');

      // 9. Hospital Outcome Recording (Requirement 10.5)
      await referralRepo.recordOutcome(
        referralId: record.id,
        outcomeType: OutcomeType.admitted,
        recordedBy: 'dr_sharma_chc',
        notes: 'Patient admitted to maternity ICU; transfused 2 units PRBC; condition stable.',
      );

      final finalRecord = await referralRepo.getReferral(record.id);
      expect(finalRecord?.status, 'outcome_recorded');
      expect(finalRecord?.outcome, 'admitted');
      expect(finalRecord?.outcomeRecordedBy, 'dr_sharma_chc');
      expect(finalRecord?.outcomeRecordedAt, isNotNull);

      // 10. Beneficiary Timeline Reflection (Requirement 10.4, 10.5)
      final timelineEvents = await timelineRepo.getTimeline(member.id);
      expect(timelineEvents.isNotEmpty, isTrue);

      final referralEvent = timelineEvents.firstWhere((e) => e.id == record.id);
      expect(referralEvent.type, TimelineEventType.referral);
      expect(referralEvent.badgeText, 'OUTCOME: ADMITTED');
      expect(referralEvent.title, contains('RED'));
      expect(referralEvent.title, contains('ADMITTED'));
      expect(referralEvent.metadata['outcome'], 'admitted');
    });

    test('SMS Fallback Formatter strictly conforms to <= 160 chars across multiple languages (Property 19)', () {
      final names = [
        'Ananya Sharma',
        'Shreemati Parmeshwari Devi Choudhary',
        'फ़ातिमा ख़ातून (Fatima Khatoon)',
        'லட்சுமி அம்மாள் (Lakshmi Ammal)',
        'సుమలత గారు (Sumalatha Garu)',
      ];

      for (final name in names) {
        final note = StructuredReferralNote(
          referralId: 'REF-${DateTime.now().millisecondsSinceEpoch}',
          encounterId: 'enc_test_sms',
          patient: ReferralPatientInfo(
            memberId: 'mem_sms',
            name: name,
            sex: 'F',
            ageInDays: 24 * 365,
            village: 'Rampur Uttar Tola',
            contactPhone: '9876543210',
          ),
          triageFlag: TriageFlag.red,
          primaryReason: 'Postpartum hemorrhage with acute tachycardia',
          triggeringReasons: const ['Pulse 130 bpm', 'Heavy bleeding'],
          destinationFacility: const FacilityInfo(
            id: 'fac_chc',
            name: 'Gopalganj Community Health Centre',
            level: FacilityLevel.chc,
            distanceKm: 14.2,
          ),
          transportArranged: '108 Ambulance',
          createdAt: DateTime.now(),
          asha: const ReferralAshaInfo(
            id: 'asha_1',
            name: 'Sunita Verma',
            phone: '9876500000',
          ),
        );

        final sms = SmsFallbackFormatter.formatSms(note);
        expect(sms.length, lessThanOrEqualTo(160),
            reason: 'SMS for $name exceeds 160 characters: "${sms.length}" chars');
      }
    });
  });
}
