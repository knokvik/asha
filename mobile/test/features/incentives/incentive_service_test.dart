import 'dart:convert';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/features/incentives/domain/incentive_models.dart';
import 'package:asha_platform/features/incentives/domain/incentive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 13.2: Incentive Catalogue and Auto-Event Logging (Requirements 53.1–53.4, 54.1–54.6)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late IncentiveService incentiveService;

    const testMemberId = 'member_priya_01';
    const testEncounterId = 'enc_anc_01';

    final testCatalogue2023Json = json.encode({
      'version_id': 'NHM_NAT_2023_V1',
      'state_code': 'DEFAULT',
      'effective_from': '2023-01-01T00:00:00.000Z',
      'effective_to': '2023-12-31T23:59:59.000Z',
      'description': 'Catalogue 2023',
      'items': [
        {
          'activity_code': 'ANC_REG_EARLY',
          'activity_name': 'Early ANC Registration',
          'category': 'RCH_MATERNAL',
          'rates': {
            'fixed_honorarium': 0.0,
            'performance_incentive': 75.0,
            'state_top_up': 25.0,
            'connectivity_allowance': 0.0,
          },
          'submission_window_days': 60,
          'required_evidence_type': 'CLINICAL_ENCOUNTER',
          'eligibility_conditions': {'max_gestational_weeks': 12},
          'descriptions': {'en': 'Early ANC 2023', 'hi': 'प्रारंभिक एएनसी २०२३'},
        },
        {
          'activity_code': 'HBNC_COMPLETE',
          'activity_name': 'Complete HBNC Series',
          'category': 'RCH_CHILD',
          'rates': {
            'fixed_honorarium': 0.0,
            'performance_incentive': 200.0,
            'state_top_up': 0.0,
            'connectivity_allowance': 0.0,
          },
          'submission_window_days': 60,
          'required_evidence_type': 'VISIT_SERIES',
          'eligibility_conditions': {
            'institutional_visits_required': 6,
            'home_visits_required': 7,
          },
        },
      ],
    });

    final testCatalogue2024Json = json.encode({
      'version_id': 'NHM_NAT_2024_V1',
      'state_code': 'DEFAULT',
      'effective_from': '2024-01-01T00:00:00.000Z',
      'effective_to': null,
      'description': 'Catalogue 2024',
      'items': [
        {
          'activity_code': 'ANC_REG_EARLY',
          'activity_name': 'Early ANC Registration',
          'category': 'RCH_MATERNAL',
          'rates': {
            'fixed_honorarium': 0.0,
            'performance_incentive': 100.0,
            'state_top_up': 50.0,
            'connectivity_allowance': 0.0,
          },
          'submission_window_days': 60,
          'required_evidence_type': 'CLINICAL_ENCOUNTER',
          'eligibility_conditions': {'max_gestational_weeks': 12},
          'descriptions': {
            'en': 'Registration within first trimester (<= 12 weeks)',
            'hi': 'पहली तिमाही (12 सप्ताह के भीतर) में पंजीकरण',
            'mr': 'पहिल्या तिमाहीत नोंदणी',
          },
          'audio_clips': {
            'en': 'assets/audio/anc_early_en.mp3',
            'hi': 'assets/audio/anc_early_hi.mp3',
          },
          'ineligibility_messages': {
            'LATE_REGISTRATION': {
              'en': 'Registration completed after 12 weeks of pregnancy.',
              'hi': 'गर्भावस्था के 12 सप्ताह बाद पंजीकरण।',
            },
          },
          'ineligibility_audio_clips': {
            'LATE_REGISTRATION': {
              'en': 'assets/audio/inelig_anc_en.mp3',
              'hi': 'assets/audio/inelig_anc_hi.mp3',
            },
          },
        },
        {
          'activity_code': 'HBNC_COMPLETE',
          'activity_name': 'Complete HBNC Series',
          'category': 'RCH_CHILD',
          'rates': {
            'fixed_honorarium': 0.0,
            'performance_incentive': 250.0,
            'state_top_up': 50.0,
            'connectivity_allowance': 0.0,
          },
          'submission_window_days': 60,
          'required_evidence_type': 'VISIT_SERIES',
          'eligibility_conditions': {
            'institutional_visits_required': 6,
            'home_visits_required': 7,
          },
          'ineligibility_messages': {
            'INCOMPLETE_VISITS': {
              'en': 'Incomplete HBNC visit series.',
              'hi': 'एचबीएनसी गृह भ्रमण अधूरा है।',
            },
          },
        },
        {
          'activity_code': 'INST_DELIVERY_ESCORT',
          'activity_name': 'Institutional Delivery Escort (JSY)',
          'category': 'RCH_MATERNAL',
          'rates': {
            'fixed_honorarium': 0.0,
            'performance_incentive': 300.0,
            'state_top_up': 300.0,
            'connectivity_allowance': 0.0,
          },
          'submission_window_days': 45,
          'required_evidence_type': 'FACILITY_VERIFICATION',
          'eligibility_conditions': {'delivery_location': 'FACILITY'},
          'ineligibility_messages': {
            'HOME_DELIVERY': {
              'en': 'Delivery occurred at home. JSY requires facility delivery.',
              'hi': 'प्रसव घर पर हुआ। जेएसवाई हेतु संस्थागत प्रसव आवश्यक है।',
            },
          },
        },
        {
          'activity_code': 'IMMUNIZATION_FULL_1YR',
          'activity_name': 'Full Immunization at 1 Year',
          'category': 'IMMUNIZATION',
          'rates': {
            'fixed_honorarium': 0.0,
            'performance_incentive': 100.0,
            'state_top_up': 50.0,
            'connectivity_allowance': 0.0,
          },
          'submission_window_days': 60,
          'required_evidence_type': 'VACCINATION_RECORD',
          'eligibility_conditions': {
            'required_antigens': ['BCG', 'OPV_3', 'PENTA_3', 'MR_1'],
          },
        },
        {
          'activity_code': 'CBAC_SCREENING',
          'activity_name': 'NCD CBAC Screening',
          'category': 'NCD',
          'rates': {
            'fixed_honorarium': 0.0,
            'performance_incentive': 20.0,
            'state_top_up': 10.0,
            'connectivity_allowance': 0.0,
          },
          'submission_window_days': 30,
          'required_evidence_type': 'CLINICAL_ENCOUNTER',
          'eligibility_conditions': {'min_age_years': 30},
          'ineligibility_messages': {
            'AGE_UNDER_30': {
              'en': 'Individual is under 30 years of age.',
              'hi': 'व्यक्ति की आयु 30 वर्ष से कम है।',
            },
          },
        },
      ],
    });

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      incentiveService = IncentiveService(db: db, syncEngine: syncEngine);

      // Register both catalogues for version testing
      incentiveService.loadCatalogueFromJson(testCatalogue2023Json);
      incentiveService.loadCatalogueFromJson(testCatalogue2024Json);

      // Seed Household and Member for clinical provenance
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_test_01',
              village: 'Rampur',
              hamlet: const Value('North'),
              headName: 'Suresh Devi',
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: testMemberId,
              householdId: 'hh_test_01',
              name: 'Priya Sharma',
              sex: 'F',
              dobApprox: Value(DateTime.now().subtract(const Duration(days: 9000)).millisecondsSinceEpoch),
              relationshipToHead: const Value('Wife'),
              createdAt: now,
              updatedAt: now,
              createdBy: 'asha_01',
            ),
          );

      await db.into(db.clinicalEncounters).insert(
            ClinicalEncountersCompanion.insert(
              id: testEncounterId,
              memberId: testMemberId,
              ashaId: 'asha_01',
              encounterDate: now,
              programCode: 'ANC',
              encounterType: 'REGISTRATION',
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. Catalogue Loading & Multi-Component Rates (Req 53.1, 53.3) ─────────
    group('Incentive Catalogue & Multi-Component Rates (Requirements 53.1, 53.3)', () {
      test('parses catalogue JSON and computes multi-component rates without hardcoding', () {
        final cat = incentiveService.getCatalogueForDate(DateTime(2024, 6, 15));
        expect(cat, isNotNull);
        expect(cat!.versionId, equals('NHM_NAT_2024_V1'));

        final item = cat.getItem('ANC_REG_EARLY');
        expect(item, isNotNull);
        expect(item!.rates.fixedHonorarium, equals(0.0));
        expect(item.rates.performanceIncentive, equals(100.0));
        expect(item.rates.stateTopUp, equals(50.0));
        expect(item.rates.connectivityAllowance, equals(0.0));
        expect(item.rates.totalRate, equals(150.0));
      });

      test('represents JSY escort with separate base performance and state top-up', () {
        final cat = incentiveService.getCatalogueForDate(DateTime(2024, 6, 15));
        final jsy = cat!.getItem('INST_DELIVERY_ESCORT');
        expect(jsy, isNotNull);
        expect(jsy!.rates.performanceIncentive, equals(300.0));
        expect(jsy.rates.stateTopUp, equals(300.0));
        expect(jsy.rates.totalRate, equals(600.0));
      });
    });

    // ── 2. Historical Rate Invariant (Req 53.2, Property 11) ───────────────────
    group('Historical Rate Versioning (Property 11, Requirement 53.2)', () {
      test('computes rate using catalogue active at event date', () {
        // Event date in 2023 -> 2023 catalogue
        final date2023 = DateTime(2023, 10, 15);
        final cat2023 = incentiveService.getCatalogueForDate(date2023);
        expect(cat2023?.versionId, equals('NHM_NAT_2023_V1'));
        expect(cat2023?.getItem('ANC_REG_EARLY')?.rates.totalRate, equals(100.0));
        expect(cat2023?.getItem('HBNC_COMPLETE')?.rates.totalRate, equals(200.0));

        // Event date in 2024 -> 2024 catalogue
        final date2024 = DateTime(2024, 4, 10);
        final cat2024 = incentiveService.getCatalogueForDate(date2024);
        expect(cat2024?.versionId, equals('NHM_NAT_2024_V1'));
        expect(cat2024?.getItem('ANC_REG_EARLY')?.rates.totalRate, equals(150.0));
        expect(cat2024?.getItem('HBNC_COMPLETE')?.rates.totalRate, equals(300.0));
      });
    });

    // ── 3. Eligibility Criteria & Plain Language / Audio (Req 53.4, 54.4) ──────
    group('Eligibility Evaluation & Multilingual Explanations (Requirements 53.4, 54.4)', () {
      test('marks early ANC eligible within 12 weeks', () {
        final result = incentiveService.evaluateEligibility(
          activityCode: 'ANC_REG_EARLY',
          memberId: testMemberId,
          eventDate: DateTime(2024, 5, 1),
          eventData: {'gestational_weeks': 10},
        );
        expect(result.isEligible, isTrue);
        expect(result.isDeferred, isFalse);
      });

      test('marks late ANC ineligible with localized plain language and audio cue', () {
        final result = incentiveService.evaluateEligibility(
          activityCode: 'ANC_REG_EARLY',
          memberId: testMemberId,
          eventDate: DateTime(2024, 5, 1),
          eventData: {'gestational_weeks': 16},
          language: 'hi',
        );
        expect(result.isEligible, isFalse);
        expect(result.ineligibilityReasonCode, equals('LATE_REGISTRATION'));
        expect(result.ineligibilityReasonText, contains('12 सप्ताह बाद पंजीकरण'));
        expect(result.audioClipPath, equals('assets/audio/inelig_anc_hi.mp3'));
      });

      test('evaluates institutional delivery escort: facility delivery is eligible, home is not', () {
        final facResult = incentiveService.evaluateEligibility(
          activityCode: 'INST_DELIVERY_ESCORT',
          memberId: testMemberId,
          eventDate: DateTime(2024, 5, 1),
          eventData: {'delivery_location': 'FACILITY'},
        );
        expect(facResult.isEligible, isTrue);

        final homeResult = incentiveService.evaluateEligibility(
          activityCode: 'INST_DELIVERY_ESCORT',
          memberId: testMemberId,
          eventDate: DateTime(2024, 5, 1),
          eventData: {'delivery_location': 'HOME'},
          language: 'hi',
        );
        expect(homeResult.isEligible, isFalse);
        expect(homeResult.ineligibilityReasonCode, equals('HOME_DELIVERY'));
        expect(homeResult.ineligibilityReasonText, contains('प्रसव घर पर हुआ'));
      });

      test('evaluates CBAC screening: age under 30 is ineligible', () {
        final youngResult = incentiveService.evaluateEligibility(
          activityCode: 'CBAC_SCREENING',
          memberId: testMemberId,
          eventDate: DateTime(2024, 5, 1),
          eventData: {'age_years': 24},
        );
        expect(youngResult.isEligible, isFalse);
        expect(youngResult.ineligibilityReasonCode, equals('AGE_UNDER_30'));

        final adultResult = incentiveService.evaluateEligibility(
          activityCode: 'CBAC_SCREENING',
          memberId: testMemberId,
          eventDate: DateTime(2024, 5, 1),
          eventData: {'age_years': 38},
        );
        expect(adultResult.isEligible, isTrue);
      });
    });

    // ── 4. Auto-Event Logging, Provenance & Deduplication (Req 54.1, Property 10, 12)
    group('Auto-Event Logging & Deduplication (Property 10, Property 12)', () {
      test('records incentive event linked to clinical record without separate ASHA entry', () async {
        final eventDate = DateTime(2024, 5, 10);
        final event = await incentiveService.recordEvent(
          memberId: testMemberId,
          activityCode: 'ANC_REG_EARLY',
          eventDate: eventDate,
          encounterId: testEncounterId,
          eventData: {'gestational_weeks': 8},
        );

        expect(event.memberId, equals(testMemberId));
        expect(event.encounterId, equals(testEncounterId));
        expect(event.activityCode, equals('ANC_REG_EARLY'));
        expect(event.status, equals(IncentiveStatus.eligible));
        expect(event.catalogueVersionId, equals('NHM_NAT_2024_V1'));
      });

      test('Property 10: recording eligible event N times produces exactly one record', () async {
        final eventDate = DateTime(2024, 5, 15);

        // Record the same event 5 times (network retries)
        final results = <IncentiveEvent>[];
        for (int i = 0; i < 5; i++) {
          final res = await incentiveService.recordEvent(
            memberId: testMemberId,
            activityCode: 'ANC_REG_EARLY',
            eventDate: eventDate,
            encounterId: testEncounterId,
            eventData: {'gestational_weeks': 9},
          );
          results.add(res);
        }

        // All returned objects should share the same ID and idempotencyKey
        final firstId = results.first.id;
        final firstKey = results.first.idempotencyKey;
        for (final r in results) {
          expect(r.id, equals(firstId));
          expect(r.idempotencyKey, equals(firstKey));
        }

        // Database should contain exactly 1 event
        final count = await (db.select(db.incentiveEvents)
              ..where((t) => t.idempotencyKey.equals(firstKey)))
            .get();
        expect(count.length, equals(1));
      });

      test('Property 12: throws OrphanedIncentiveException if member ID does not exist', () async {
        expect(
          () => incentiveService.recordEvent(
            memberId: 'non_existent_member_999',
            activityCode: 'ANC_REG_EARLY',
            eventDate: DateTime(2024, 5, 10),
            eventData: {'gestational_weeks': 8},
          ),
          throwsA(isA<OrphanedIncentiveException>()),
        );
      });
    });

    // ── 5. Deferred Eligibility Tracking & Resolution (Req 54.2, 54.3) ────────
    group('Deferred Eligibility & Progress Tracking (Requirements 54.2, 54.3)', () {
      test('partially complete HBNC visit series shows progress and records as deferred', () async {
        final eval = incentiveService.evaluateEligibility(
          activityCode: 'HBNC_COMPLETE',
          memberId: testMemberId,
          eventDate: DateTime(2024, 6, 1),
          eventData: {
            'hbnc_visits_completed': 3,
            'is_home_delivery': false,
          },
        );

        expect(eval.isEligible, isFalse);
        expect(eval.isDeferred, isTrue);
        expect(eval.completionProgress, equals(0.5));
        expect(eval.completedCount, equals(3));
        expect(eval.requiredCount, equals(6));
        expect(eval.isPartiallyComplete, isTrue);

        // Record as deferred event in database
        final event = await incentiveService.recordEvent(
          memberId: testMemberId,
          activityCode: 'HBNC_COMPLETE',
          eventDate: DateTime(2024, 6, 1),
          eventData: {'hbnc_visits_completed': 3, 'is_home_delivery': false},
        );

        expect(event.status, equals(IncentiveStatus.deferred));

        // When 6th visit is completed, condition is satisfied and deferred event resolves
        final resolved = await incentiveService.checkAndResolveDeferredConditions(
          memberId: testMemberId,
          activityCode: 'HBNC_COMPLETE',
          updatedContext: {'hbnc_visits_completed': 6, 'is_home_delivery': false},
        );

        expect(resolved.length, equals(1));
        expect(resolved.first.id, equals(event.id));
        expect(resolved.first.status, equals(IncentiveStatus.eligible));

        // Verify in DB
        final inDb = await (db.select(db.incentiveEvents)..where((t) => t.id.equals(event.id))).getSingle();
        expect(inDb.status, equals(IncentiveStatus.eligible));
      });

      test('immunization full 1 year tracks pending antigens and marks eligible on final vaccine', () {
        // Missing MR_1 -> deferred
        final partialImm = incentiveService.evaluateEligibility(
          activityCode: 'IMMUNIZATION_FULL_1YR',
          memberId: testMemberId,
          eventDate: DateTime(2024, 7, 1),
          eventData: {
            'completed_antigens': ['BCG', 'OPV_3', 'PENTA_3'],
          },
        );
        expect(partialImm.isEligible, isFalse);
        expect(partialImm.isDeferred, isTrue);
        expect(partialImm.completionProgress, equals(0.75));

        // All 4 antigens complete -> eligible
        final fullImm = incentiveService.evaluateEligibility(
          activityCode: 'IMMUNIZATION_FULL_1YR',
          memberId: testMemberId,
          eventDate: DateTime(2024, 7, 1),
          eventData: {
            'completed_antigens': ['BCG', 'OPV_3', 'PENTA_3', 'MR_1'],
          },
        );
        expect(fullImm.isEligible, isTrue);
        expect(fullImm.completionProgress, equals(1.0));
      });
    });

    // ── 6. External Confirmatory Event (Req 54.5) ──────────────────────────────
    group('External Confirmatory Event (Requirement 54.5)', () {
      test('records external facility confirmation and links evidence record', () async {
        final confirmationDate = DateTime(2024, 5, 20);
        final event = await incentiveService.recordExternalConfirmation(
          memberId: testMemberId,
          activityCode: 'INST_DELIVERY_ESCORT',
          externalReferenceId: 'FACILITY_ADM_REC_9874',
          confirmationDate: confirmationDate,
        );

        expect(event.status, equals(IncentiveStatus.eligible));
        expect(event.evidenceRecordId, equals('FACILITY_ADM_REC_9874'));
      });
    });
  });
}
