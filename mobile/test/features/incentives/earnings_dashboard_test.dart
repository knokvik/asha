import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/pdf/pdf_generator.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/features/incentives/data/earnings_repository.dart';
import 'package:asha_platform/features/incentives/domain/incentive_models.dart';
import 'package:asha_platform/features/incentives/domain/incentive_service.dart';
import 'package:asha_platform/features/incentives/presentation/earnings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 13.3: Earnings Dashboard and Transparency (Requirements 55.1–55.6)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late IncentiveService incentiveService;
    late EarningsRepository repository;

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
        {
          'activity_code': 'CBAC_SCREENING',
          'activity_name': 'NCD CBAC Screening',
          'rates': {'performance_incentive': 20.0, 'state_top_up': 10.0},
        },
      ],
    });

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      incentiveService = IncentiveService(db: db, syncEngine: syncEngine);
      incentiveService.loadCatalogueFromJson(testCatalogueJson);
      repository = EarningsRepository(db: db, incentiveService: incentiveService);

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

      // Seed Household & Member
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

      // Seed Events in April 2024 with different statuses
      final apr10 = DateTime(2024, 4, 10).millisecondsSinceEpoch;
      final apr12 = DateTime(2024, 4, 12).millisecondsSinceEpoch;
      final apr15 = DateTime(2024, 4, 15).millisecondsSinceEpoch;
      final apr18 = DateTime(2024, 4, 18).millisecondsSinceEpoch;
      final apr20 = DateTime(2024, 4, 20).millisecondsSinceEpoch;
      final apr22 = DateTime(2024, 4, 22).millisecondsSinceEpoch;

      // 1. Paid event (₹600)
      await db.into(db.incentiveEvents).insert(
            IncentiveEventsCompanion.insert(
              id: 'ev_paid_01',
              memberId: 'member_priya',
              activityCode: 'INST_DELIVERY_ESCORT',
              catalogueVersionId: 'NHM_TEST_2024',
              eventDate: apr10,
              status: const Value('paid'),
              idempotencyKey: 'idemp_paid_01',
              createdAt: apr10,
            ),
          );

      // 2. Approved event (₹150)
      await db.into(db.incentiveEvents).insert(
            IncentiveEventsCompanion.insert(
              id: 'ev_approved_01',
              memberId: 'member_priya',
              activityCode: 'ANC_REG_EARLY',
              catalogueVersionId: 'NHM_TEST_2024',
              eventDate: apr12,
              status: const Value('approved'),
              idempotencyKey: 'idemp_app_01',
              createdAt: apr12,
            ),
          );

      // 3. Verified event (₹30)
      await db.into(db.incentiveEvents).insert(
            IncentiveEventsCompanion.insert(
              id: 'ev_verified_01',
              memberId: 'member_priya',
              activityCode: 'CBAC_SCREENING',
              catalogueVersionId: 'NHM_TEST_2024',
              eventDate: apr15,
              status: const Value('verified'),
              idempotencyKey: 'idemp_ver_01',
              createdAt: apr15,
            ),
          );

      // 4. Claimed event (₹150)
      await db.into(db.incentiveEvents).insert(
            IncentiveEventsCompanion.insert(
              id: 'ev_claimed_01',
              memberId: 'member_priya',
              activityCode: 'ANC_REG_EARLY',
              catalogueVersionId: 'NHM_TEST_2024',
              eventDate: apr18,
              status: const Value('claimed'),
              idempotencyKey: 'idemp_clm_01',
              createdAt: apr18,
            ),
          );

      // 5. Eligible event (₹30)
      await db.into(db.incentiveEvents).insert(
            IncentiveEventsCompanion.insert(
              id: 'ev_eligible_01',
              memberId: 'member_priya',
              activityCode: 'CBAC_SCREENING',
              catalogueVersionId: 'NHM_TEST_2024',
              eventDate: apr20,
              status: const Value('eligible'),
              idempotencyKey: 'idemp_elg_01',
              createdAt: apr20,
            ),
          );

      // 6. Rejected event (₹150) with reason
      await db.into(db.incentiveEvents).insert(
            IncentiveEventsCompanion.insert(
              id: 'ev_rejected_01',
              memberId: 'member_priya',
              activityCode: 'ANC_REG_EARLY',
              catalogueVersionId: 'NHM_TEST_2024',
              eventDate: apr22,
              status: const Value('rejected'),
              ineligibilityReason: const Value('Registered after 14 weeks. Late ANC registration is not eligible.'),
              idempotencyKey: 'idemp_rej_01',
              createdAt: apr22,
            ),
          );

      // 7. Deferred event (potential ₹300) for projection
      await db.into(db.incentiveEvents).insert(
            IncentiveEventsCompanion.insert(
              id: 'ev_deferred_01',
              memberId: 'member_priya',
              activityCode: 'HBNC_COMPLETE',
              catalogueVersionId: 'NHM_TEST_2024',
              eventDate: apr22,
              status: const Value(IncentiveStatus.deferred),
              ineligibilityReason: const Value('3 of 6 visits completed'),
              idempotencyKey: 'idemp_def_01',
              createdAt: apr22,
            ),
          );

      // Seed IncentiveClaim with payment reference for reconciliation
      await db.into(db.incentiveClaims).insert(
            IncentiveClaimsCompanion.insert(
              id: 'claim_2024_04',
              workerId: testWorkerId,
              claimPeriod: testPeriod,
              status: const Value('paid'),
              totalAmount: const Value(600.0),
              paymentReference: const Value('PFMS-UTR-20240415-998811'),
              paidAt: Value(DateTime(2024, 4, 25).millisecondsSinceEpoch),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    // ── 1. Status Totals & Breakdown (Requirement 55.1) ────────────────────────
    test('getStatusTotals computes monthly breakdown by status correctly', () async {
      final totals = await repository.getStatusTotals(testPeriod);

      // Paid: INST_DELIVERY_ESCORT (₹600)
      expect(totals.paidCount, equals(1));
      expect(totals.paidAmount, equals(600.0));

      // Approved: ANC_REG_EARLY (₹150)
      expect(totals.approvedCount, equals(1));
      expect(totals.approvedAmount, equals(150.0));

      // Verified: CBAC_SCREENING (₹30)
      expect(totals.verifiedCount, equals(1));
      expect(totals.verifiedAmount, equals(30.0));

      // Claimed: ANC_REG_EARLY (₹150)
      expect(totals.claimedCount, equals(1));
      expect(totals.claimedAmount, equals(150.0));

      // Eligible: CBAC_SCREENING (₹30)
      expect(totals.eligibleCount, equals(1));
      expect(totals.eligibleAmount, equals(30.0));

      // Rejected: ANC_REG_EARLY (₹150)
      expect(totals.rejectedCount, equals(1));
      expect(totals.rejectedAmount, equals(150.0));

      // Total Earned (Paid + Approved) = 600 + 150 = 750
      expect(totals.totalEarned, equals(750.0));

      // Total Pipeline (Eligible + Claimed + Verified + Approved + Paid) = 30 + 150 + 30 + 150 + 600 = 960
      expect(totals.totalPipeline, equals(960.0));
    });

    // ── 2. Delay & Rejection Transparency (Requirement 55.2) ──────────────────
    test('getLineItems includes stage, responsible person, and rejection reason', () async {
      final items = await repository.getLineItems(testPeriod);
      expect(items.length, greaterThanOrEqualTo(6));

      // Verify rejected item contains reason and responsible review role
      final rejectedItem = items.firstWhere((i) => i.status == 'rejected');
      expect(rejectedItem.delayOrRejectionReason, contains('Late ANC registration'));
      expect(rejectedItem.stage, contains('Correction Required'));
      expect(rejectedItem.responsibleRole, isNotNull);

      // Verify claimed item is in ANM verification queue
      final claimedItem = items.firstWhere((i) => i.status == 'claimed');
      expect(claimedItem.stage, contains('Verification Queue'));
      expect(claimedItem.responsibleRole, contains('ANM'));

      // Verify de-identified beneficiary reference
      for (final item in items) {
        expect(item.memberCodedId, startsWith('BEN-'));
      }
    });

    // ── 3. Payment & Bank Reconciliation (Requirement 55.3) ───────────────────
    test('getReconciliations reconciles paid amount with bank reference and flags status', () async {
      final recs = await repository.getReconciliations(testWorkerId, period: testPeriod);
      expect(recs.length, equals(1));

      final rec = recs.first;
      expect(rec.claimPeriod, equals(testPeriod));
      expect(rec.approvedAmount, equals(600.0));
      expect(rec.paidAmount, equals(600.0));
      expect(rec.bankReference, equals('PFMS-UTR-20240415-998811'));
      expect(rec.hasDiscrepancy, isFalse);
      expect(rec.reconciliationStatus, equals('Fully Reconciled'));
    });

    // ── 4. Earnings Projection (Requirement 55.4) ─────────────────────────────
    test('getEarningsProjection estimates earnings from deferred in-progress tasks', () async {
      final proj = await repository.getEarningsProjection(testWorkerId, testPeriod);

      expect(proj.currentMonth, equals(testPeriod));
      expect(proj.currentEarned, equals(750.0));
      // Incomplete HBNC potential = ₹300
      expect(proj.projectedAdditionalAmount, equals(300.0));
      expect(proj.totalProjected, equals(1050.0));
      expect(proj.pendingTasks.length, equals(1));
      expect(proj.pendingTasks.first.activityCode, equals('HBNC_COMPLETE'));
      expect(proj.pendingTasks.first.remainingDescription, contains('3 of 6 visits'));
    });

    // ── 5. Printable PDF Earnings Statement (Requirement 55.5) ────────────────
    test('generateEarningsStatementPdf produces valid non-empty PDF bytes', () async {
      final statement = await repository.generateStatement(testWorkerId, testPeriod);
      expect(statement.workerName, equals('Sunita Devi'));
      expect(statement.ashaId, equals('ASHA-MH-1024'));

      final pdfBytes = await PdfGenerator.generateEarningsStatementPdf(statement);
      expect(pdfBytes, isA<Uint8List>());
      expect(pdfBytes.length, greaterThan(1000));

      // PDF signature bytes: %PDF-
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    // ── 6. EarningsScreen Widget & Privacy Shield (Requirements 55.1, 55.6) ───
    testWidgets('EarningsScreen renders totals and toggles privacy shield', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: EarningsScreen(
            repository: repository,
            workerId: testWorkerId,
            initialPeriod: testPeriod,
            language: 'en',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Earnings & Incentives'), findsOneWidget);

      // Verify Total Earned Hero Card rendered (₹750.00)
      expect(find.text('₹750.00'), findsOneWidget);

      // Verify Projection Banner rendered
      expect(find.textContaining('Earnings Projection'), findsOneWidget);

      // Verify Status Badges rendered
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Approved'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);

      // Toggle Privacy Shield (Req 55.6)
      final privacyButton = find.byKey(const Key('earnings_privacy_toggle'));
      expect(privacyButton, findsOneWidget);

      await tester.tap(privacyButton);
      await tester.pumpAndSettle();

      // Amounts should now be obscured with ₹****
      expect(find.text('₹****'), findsWidgets);
      expect(find.text('Shielded'), findsOneWidget);

      // Toggle Privacy Shield back to reveal
      await tester.tap(privacyButton);
      await tester.pumpAndSettle();

      expect(find.text('₹750.00'), findsOneWidget);
    });
  });
}
