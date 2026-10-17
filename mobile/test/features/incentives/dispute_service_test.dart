import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/features/incentives/data/dispute_service.dart';
import 'package:asha_platform/features/incentives/domain/dispute_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 13.5: Dispute Resolution and Payment Tracking (Requirements 57.2–57.6)', () {
    late AppDatabase db;
    late SyncEngine syncEngine;
    late DisputeService disputeService;

    const testWorkerId = 'worker_asha_01';
    const testPeriod = '2024-04';

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      disputeService = DisputeService(db: db, syncEngine: syncEngine);
    });

    tearDown(() async {
      await db.close();
    });

    test('submits payment dispute with default 15-day SLA and initial AF owner (Req 57.3)', () async {
      final dispute = await disputeService.submitDispute(
        workerId: testWorkerId,
        claimPeriod: testPeriod,
        activityCode: 'ANC_REG_EARLY',
        disputeType: DisputeType.technicalError,
        description: 'Payment for Priya ANC registration was not included in approved voucher.',
        evidenceEventIds: ['ev_01', 'enc_anc_01'],
        slaDays: 15,
      );

      expect(dispute.id, isNotEmpty);
      expect(dispute.workerId, equals(testWorkerId));
      expect(dispute.claimPeriod, equals(testPeriod));
      expect(dispute.activityCode, equals('ANC_REG_EARLY'));
      expect(dispute.status, equals('submitted'));
      expect(dispute.assignedRole, equals('AF'));
      expect(dispute.isEscalated, isFalse);
      expect(dispute.evidenceEventIds, equals(['ev_01', 'enc_anc_01']));

      // Verify SLA deadline is ~15 days in the future
      final daysDiff = dispute.slaDeadline!.difference(dispute.createdAt).inDays;
      expect(daysDiff, equals(15));
      expect(dispute.isBreachedSla, isFalse);

      // Verify listing for worker
      final list = await disputeService.getDisputesForWorker(testWorkerId);
      expect(list.length, equals(1));
      expect(list.first.id, equals(dispute.id));
    });

    test('rejects empty dispute description with DisputeServiceException', () async {
      expect(
        () => disputeService.submitDispute(
          workerId: testWorkerId,
          claimPeriod: testPeriod,
          description: '   ',
        ),
        throwsA(isA<DisputeServiceException>()),
      );
    });

    test('interprets bank/PFMS rejection codes into plain language and steps (Req 57.2)', () {
      // 1. R01: Invalid / closed account
      final r01 = disputeService.explainBankRejection('R01');
      expect(r01.code, equals('R01'));
      expect(r01.requiresBranchVisit, isTrue);
      expect(r01.plainLanguageReason, contains('closed'));
      expect(r01.correctionSteps, isNotEmpty);

      // 2. R02: IFSC mismatch due to bank mergers
      final r02 = disputeService.explainBankRejection('R02');
      expect(r02.code, equals('R02'));
      expect(r02.plainLanguageReason, contains('IFSC'));
      expect(r02.correctionSteps.first, contains('IFSC'));

      // 3. R03: Aadhaar not seeded (APBS failure)
      final r03 = disputeService.explainBankRejection('ERR_AADHAAR_NOT_SEEDED');
      expect(r03.code, equals('R03'));
      expect(r03.title, contains('Aadhaar Not Seeded'));
      expect(r03.requiresBranchVisit, isTrue);
      expect(r03.correctionSteps.any((s) => s.contains('NPCI')), isTrue);

      // 4. R04: Name mismatch
      final r04 = disputeService.explainBankRejection('R04');
      expect(r04.title, contains('Name Mismatch'));

      // 5. R05: Dormant account
      final r05 = disputeService.explainBankRejection('R05');
      expect(r05.title, contains('Dormant'));

      // 6. Generic/Unknown code
      final unk = disputeService.explainBankRejection('CODE_999_MISC');
      expect(unk.title, equals('Payment Processing Hold'));
      expect(unk.correctionSteps, isNotEmpty);
    });

    test('PaymentDisputeModel evaluates SLA breach correctly', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 20));
      final pastSla = DateTime.now().subtract(const Duration(days: 5));

      final overdueDispute = PaymentDisputeModel(
        id: 'd_overdue',
        workerId: testWorkerId,
        claimPeriod: testPeriod,
        description: 'Overdue dispute',
        status: 'submitted',
        slaDeadline: pastSla,
        createdAt: pastDate,
        updatedAt: pastDate,
      );

      expect(overdueDispute.isBreachedSla, isTrue);

      final resolvedDispute = PaymentDisputeModel(
        id: 'd_resolved',
        workerId: testWorkerId,
        claimPeriod: testPeriod,
        description: 'Resolved dispute',
        status: 'resolved',
        slaDeadline: pastSla,
        createdAt: pastDate,
        updatedAt: pastDate,
      );

      // Resolved dispute cannot be breached
      expect(resolvedDispute.isBreachedSla, isFalse);
    });
  });
}
