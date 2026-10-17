import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/features/incentives/data/claim_service.dart';
import 'package:asha_platform/features/incentives/domain/claim_models.dart';
import 'package:asha_platform/features/incentives/domain/incentive_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 13.4: Claim Voucher Generation and Submission (Requirements 56.1–56.7, 57.1)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late IncentiveService incentiveService;
    late ClaimService claimService;

    const testWorkerId = 'worker_asha_01';
    const testPeriod = '2024-04';

    final testCatalogueJson = json.encode({
      'version_id': 'NHM_TEST_2024',
      'state_code': 'DEFAULT',
      'effective_from': '2024-01-01T00:00:00.000Z',
      'items': [
        {
          'activity_code': 'ANC_REG_EARLY',
          'activity_name': 'Early ANC Registration',
          'rates': {'performance_incentive': 100.0, 'state_top_up': 50.0},
        },
        {
          'activity_code': 'INST_DELIVERY_ESCORT',
          'activity_name': 'Institutional Delivery Escort (JSY)',
          'rates': {'performance_incentive': 300.0, 'state_top_up': 300.0},
        },
        {
          'activity_code': 'HBNC_COMPLETE',
          'activity_name': 'Home-Based Newborn Care Complete',
          'rates': {'performance_incentive': 250.0, 'state_top_up': 50.0},
        },
      ],
    });

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      incentiveService = IncentiveService(db: db, syncEngine: syncEngine);
      incentiveService.loadCatalogueFromJson(testCatalogueJson);
      claimService = ClaimService(db: db, incentiveService: incentiveService, syncEngine: syncEngine);

      final now = DateTime.now().millisecondsSinceEpoch;

      // Seed ASHA Worker
      await db.into(db.users).insert(
            UsersCompanion.insert(
              id: testWorkerId,
              name: 'Sunita Devi',
              role: 'ASHA',
              ashaId: 'ASHA-MH-1024',
              areaVillage: const Value('Rampur'),
              areaSubcentre: const Value('Rampur SC'),
              areaPhc: const Value('Shirur PHC'),
              areaBlock: const Value('Shirur'),
              areaDistrict: const Value('Pune'),
              areaState: const Value('Maharashtra'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Seed Households & Members
      await db.into(db.households).insert(
            HouseholdsCompanion.insert(
              id: 'hh_01',
              village: 'Rampur',
              headName: 'Kailash Devi',
              createdAt: now,
              updatedAt: now,
              createdBy: testWorkerId,
            ),
          );

      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'member_priya',
              householdId: 'hh_01',
              name: 'Priya',
              sex: 'F',
              createdAt: now,
              updatedAt: now,
              createdBy: testWorkerId,
            ),
          );

      await db.into(db.members).insert(
            MembersCompanion.insert(
              id: 'member_kavita',
              householdId: 'hh_01',
              name: 'Kavita',
              sex: 'F',
              createdAt: now,
              updatedAt: now,
              createdBy: testWorkerId,
            ),
          );

      // Seed eligible incentive events for April 2024
      final april10 = DateTime(2024, 4, 10).millisecondsSinceEpoch;
      final april15 = DateTime(2024, 4, 15).millisecondsSinceEpoch;

      await db.into(db.incentiveEvents).insert(
            IncentiveEventsCompanion.insert(
              id: 'ev_01',
              memberId: 'member_priya',
              activityCode: 'ANC_REG_EARLY',
              catalogueVersionId: 'NHM_TEST_2024',
              eventDate: april10,
              status: const Value('eligible'),
              evidenceRecordId: const Value('enc_anc_01'),
              createdAt: april10,
              idempotencyKey: 'key_ev_01',
            ),
          );

      await db.into(db.incentiveEvents).insert(
            IncentiveEventsCompanion.insert(
              id: 'ev_02',
              memberId: 'member_kavita',
              activityCode: 'INST_DELIVERY_ESCORT',
              catalogueVersionId: 'NHM_TEST_2024',
              eventDate: april15,
              status: const Value('eligible'),
              evidenceRecordId: const Value('enc_deliv_01'),
              createdAt: april15,
              idempotencyKey: 'key_ev_02',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('generates monthly claim voucher with de-identified beneficiary IDs (Req 56.1, 56.7)', () async {
      final claim = await claimService.generateClaimVoucher(
        workerId: testWorkerId,
        period: testPeriod,
      );

      expect(claim.workerId, equals(testWorkerId));
      expect(claim.claimPeriod, equals(testPeriod));
      expect(claim.status, equals('generated'));
      expect(claim.lineItems.length, equals(2));

      // Check rates: ANC_REG_EARLY (100+50=150) + INST_DELIVERY_ESCORT (300+300=600) = 750
      expect(claim.totalAmount, equals(750.0));

      // Verify de-identification format (BEN-XXXXXXXX) (Req 56.7)
      for (final item in claim.lineItems) {
        expect(item.memberCodedId, startsWith('BEN-'));
        expect(item.memberCodedId.length, equals(12)); // 'BEN-' + 8 chars
        expect(item.status, equals('pending'));
      }

      // Check events updated to 'claimed'
      final events = await db.select(db.incentiveEvents).get();
      for (final ev in events) {
        expect(ev.status, equals('claimed'));
      }
    });

    test('enforces idempotency on claim voucher generation (Req 56.1, Property Note)', () async {
      // First generation
      final claim1 = await claimService.generateClaimVoucher(
        workerId: testWorkerId,
        period: testPeriod,
      );

      // Repeated generation for the same worker & period
      final claim2 = await claimService.generateClaimVoucher(
        workerId: testWorkerId,
        period: testPeriod,
      );

      expect(claim2.id, equals(claim1.id));
      expect(claim2.totalAmount, equals(claim1.totalAmount));
      expect(claim2.lineItems.length, equals(claim1.lineItems.length));

      // Ensure no duplicate claims were created in database
      final allClaims = await db.select(db.incentiveClaims).get();
      expect(allClaims.length, equals(1));
    });

    test('submits claim voucher for verification (Req 56.2)', () async {
      final claim = await claimService.generateClaimVoucher(
        workerId: testWorkerId,
        period: testPeriod,
      );

      final submitted = await claimService.submitClaim(claim.id);

      expect(submitted.status, equals('submitted'));
      expect(submitted.submittedAt, isNotNull);

      // Verify in DB
      final dbRow = await claimService.getClaim(claim.id);
      expect(dbRow?.status, equals('submitted'));
      expect(dbRow?.submittedAt, isNotNull);
    });

    test('supports resubmission of rejected lines (Req 56.4)', () async {
      final claim = await claimService.generateClaimVoucher(
        workerId: testWorkerId,
        period: testPeriod,
      );

      // Simulate ANM rejecting one line
      final rejectedLines = [
        claim.lineItems[0].copyWith(
          status: 'rejected',
          rejectionReason: 'Missing registration date stamp',
          rejectionCategory: RejectionCategory.documentationDeficit,
        ),
        claim.lineItems[1].copyWith(status: 'approved'),
      ];

      await (db.update(db.incentiveClaims)..where((t) => t.id.equals(claim.id))).write(
        IncentiveClaimsCompanion(
          lineItemsJson: Value(jsonEncode(rejectedLines.map((e) => e.toJson()).toList())),
          status: const Value('partially_approved'),
        ),
      );

      // ASHA corrects documentation and resubmits ev_01
      final resubmitted = await claimService.resubmitRejectedLines(
        claimId: claim.id,
        eventIdsToResubmit: ['ev_01'],
      );

      expect(resubmitted.status, equals('submitted'));
      final line0 = resubmitted.lineItems.firstWhere((i) => i.incentiveEventId == 'ev_01');
      expect(line0.status, equals('pending'));
      expect(line0.rejectionReason, isNull);

      final line1 = resubmitted.lineItems.firstWhere((i) => i.incentiveEventId == 'ev_02');
      expect(line1.status, equals('approved'));
    });

    test('generates printable claim voucher PDF (Req 56.1, Property 12)', () async {
      final claim = await claimService.generateClaimVoucher(
        workerId: testWorkerId,
        period: testPeriod,
      );

      final pdfBytes = await claimService.generateVoucherPdf(
        claim: claim,
        workerName: 'Sunita Devi',
        workerAshaId: 'ASHA-MH-1024',
        village: 'Rampur',
        phc: 'Shirur PHC',
        subCenter: 'Rampur SC',
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
      // PDF starts with standard %PDF magic header bytes [37, 80, 68, 70]
      expect(pdfBytes.sublist(0, 4), equals([37, 80, 68, 70]));
    });

    test('pre-validates bank details with RBI IFSC and account standards (Req 57.1)', () {
      // 1. Valid details
      final validBank = const BankDetails(
        accountHolderName: 'Sunita Devi',
        accountNumber: '123456789012',
        ifscCode: 'SBIN0001234',
        bankName: 'State Bank of India',
        isAadhaarSeeded: true,
      );

      final result1 = claimService.validateBankDetails(
        bankDetails: validBank,
        registeredWorkerName: 'Sunita Devi',
      );

      expect(result1.isValid, isTrue);
      expect(result1.ifscValid, isTrue);
      expect(result1.accountValid, isTrue);
      expect(result1.nameMatchValid, isTrue);
      expect(result1.nameMatchScore, equals(1.0));
      expect(result1.errors, isEmpty);
      expect(result1.warnings, isEmpty);

      // 2. Invalid IFSC and short account number
      final invalidBank = const BankDetails(
        accountHolderName: 'Kavita Kumari',
        accountNumber: '12345', // too short (< 9 digits)
        ifscCode: 'INVALID_IFSC', // not 11 chars RBI pattern
        bankName: 'Test Bank',
        isAadhaarSeeded: false,
      );

      final result2 = claimService.validateBankDetails(
        bankDetails: invalidBank,
        registeredWorkerName: 'Sunita Devi',
      );

      expect(result2.isValid, isFalse);
      expect(result2.ifscValid, isFalse);
      expect(result2.accountValid, isFalse);
      expect(result2.nameMatchValid, isFalse);
      expect(result2.errors.length, equals(2));
      expect(result2.warnings.length, equals(2)); // Name mismatch warning + Aadhaar warning
    });
  });
}
