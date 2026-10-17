import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/l10n/app_localizations.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/voice/tts_service.dart';
import 'package:asha_platform/features/household/data/member_dao.dart';
import 'package:asha_platform/features/household/domain/consent_service.dart';
import 'package:asha_platform/features/household/presentation/consent_screen.dart';
import 'package:asha_platform/shared/providers/core_providers.dart';

void main() {
  late AppDatabase db;
  late MemberDao memberDao;
  late SyncEngine syncEngine;
  late ConsentService consentService;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    memberDao = MemberDao(db);
    syncEngine = SyncEngine(db);
    consentService = ConsentService(
      db: db,
      memberDao: memberDao,
      syncEngine: syncEngine,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedMember({
    required String memberId,
    String householdId = 'hh-1',
    String name = 'Aarti Devi',
    int? dobApprox,
    String sex = 'F',
    String consentStatus = 'pending',
  }) async {
    await db.into(db.households).insert(
          HouseholdsCompanion.insert(
            id: householdId,
            village: 'Shivpur',
            headName: 'Rameshwar',
            createdAt: 1000,
            updatedAt: 1000,
            createdBy: 'asha-1',
          ),
        );

    await db.into(db.members).insert(
          MembersCompanion.insert(
            id: memberId,
            householdId: householdId,
            name: name,
            sex: sex,
            dobApprox: Value(dobApprox),
            consentStatus: Value(consentStatus),
            createdAt: 1000,
            updatedAt: 1000,
            createdBy: 'asha-1',
          ),
        );
  }

  Widget buildTestWidget({
    required Widget child,
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        consentServiceProvider.overrideWithValue(consentService),
        ttsServiceProvider.overrideWithValue(TtsService()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  group('ConsentService Cryptographic Integrity (Requirements 5.1, 5.2)', () {
    test('computes exact SHA-256 signature hash of canonical parameters', () {
      const memberId = 'mem-101';
      const consentVersion = 'v1.0';
      const timestamp = 1700000000;
      const ashaId = 'asha-test-01';

      final hash = ConsentService.computeSignatureHash(
        memberId: memberId,
        consentVersion: consentVersion,
        timestamp: timestamp,
        ashaId: ashaId,
      );

      final expected = sha256.convert(utf8.encode('$memberId$consentVersion$timestamp$ashaId')).toString();
      expect(hash, equals(expected));
      expect(hash.length, 64);
    });

    test('verifyTamperEvidence detects unmodified vs tampered consent records', () async {
      const memberId = 'mem-tamper-1';
      await seedMember(memberId: memberId);

      final record = await consentService.grantConsent(
        memberId: memberId,
        ashaId: 'asha-witness',
        consentVersion: 'v1.0',
        timestamp: 1600000000,
      );

      // 1. Clean record passes verification
      expect(ConsentService.verifyTamperEvidence(record), isTrue);

      // 2. Tampered signatureHash fails verification
      final tamperedSig = record.copyWith(signatureHash: '0000000000000000000000000000000000000000000000000000000000000000');
      expect(ConsentService.verifyTamperEvidence(tamperedSig), isFalse);

      // 3. Altered consent version fails verification
      final tamperedVer = record.copyWith(consentVersion: 'v2.0');
      expect(ConsentService.verifyTamperEvidence(tamperedVer), isFalse);
    });
  });

  group('Consent Workflow & Guardian Branches (Requirements 5.3, 5.4, 5.5, 5.6)', () {
    test('enforces guardian branch for minors under 18 years old', () async {
      const memberId = 'minor-001';
      // 10 years old
      final tenYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 10)).millisecondsSinceEpoch;
      await seedMember(memberId: memberId, dobApprox: tenYearsAgo);

      final member = (await memberDao.getById(memberId))!;
      expect(ConsentService.isMemberMinor(member), isTrue);

      // Attempting to grant consent without guardian relationship fails
      expect(
        () => consentService.grantConsent(
          memberId: memberId,
          ashaId: 'asha-1',
          isGuardianConsent: false,
          guardianRelationship: null,
        ),
        throwsArgumentError,
      );

      // Providing guardian relationship succeeds
      final record = await consentService.grantConsent(
        memberId: memberId,
        ashaId: 'asha-1',
        isGuardianConsent: true,
        guardianRelationship: 'Mother',
      );

      expect(record.isGuardianConsent, isTrue);
      expect(record.guardianRelationship, 'Mother');

      final updatedMember = (await memberDao.getById(memberId))!;
      expect(updatedMember.consentStatus, 'given');
      expect(await consentService.hasValidConsent(memberId), isTrue);
    });

    test('declineConsent sets emergency-only mode and restricts non-emergency storage', () async {
      const memberId = 'mem-decline-1';
      await seedMember(memberId: memberId);

      await consentService.declineConsent(
        memberId: memberId,
        ashaId: 'asha-1',
        reason: 'Beneficiary prefers not to share optional data',
      );

      final member = (await memberDao.getById(memberId))!;
      expect(member.consentStatus, 'declined');
      expect(await consentService.isEmergencyOnlyMode(memberId), isTrue);
      expect(await consentService.hasValidConsent(memberId), isFalse);
    });

    test('withdrawConsent flags record and enqueues high-priority P1 sync', () async {
      const memberId = 'mem-withdraw-1';
      await seedMember(memberId: memberId);

      // First grant consent
      await consentService.grantConsent(
        memberId: memberId,
        ashaId: 'asha-1',
        timestamp: 1000,
      );

      expect(await consentService.hasValidConsent(memberId), isTrue);

      // Now withdraw consent
      await consentService.withdrawConsent(
        memberId: memberId,
        reason: 'Privacy concerns',
        ashaId: 'asha-1',
        timestamp: 2000,
      );

      final member = (await memberDao.getById(memberId))!;
      expect(member.consentStatus, 'withdrawn');
      expect(await consentService.hasValidConsent(memberId), isFalse);

      final latest = await consentService.getLatestConsent(memberId);
      expect(latest!.withdrawnAt, 2000);
      expect(latest.withdrawalReason, 'Privacy concerns');

      // Verify immediate P1 sync item was queued
      final syncQueueItems = await db.select(db.syncQueue).get();
      final withdrawItems = syncQueueItems.where((i) => i.operation == 'withdraw').toList();
      expect(withdrawItems, isNotEmpty);
      expect(withdrawItems.first.priority, 1); // P1 Critical Priority
    });

    test('checkNeedsReconsent flags outdated versions or unconsented records', () async {
      const memberId = 'mem-reconsent-1';
      await seedMember(memberId: memberId);

      // Unconsented needs consent
      expect(await consentService.checkNeedsReconsent(memberId: memberId), isTrue);

      // Consented to v1.0
      await consentService.grantConsent(
        memberId: memberId,
        ashaId: 'asha-1',
        consentVersion: 'v1.0',
      );
      expect(await consentService.checkNeedsReconsent(memberId: memberId, currentVersion: 'v1.0'), isFalse);

      // When policy changes to v2.0, re-consent is required
      expect(await consentService.checkNeedsReconsent(memberId: memberId, currentVersion: 'v2.0'), isTrue);
    });
  });

  group('ConsentScreen Widget (Requirement 5.1, 5.2, 5.3, 5.4)', () {
    testWidgets('renders plain-language statement, audio read-aloud button, and grants consent', (tester) async {
      const memberId = 'mem-ui-adult';
      await seedMember(memberId: memberId, name: 'Sunita Sharma');

      await tester.pumpWidget(
        buildTestWidget(
          child: const ConsentScreen(memberId: memberId),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and statement
      expect(find.text('Sunita Sharma'), findsOneWidget);
      expect(find.textContaining('Consent Statement'), findsOneWidget);
      expect(find.byKey(const Key('read_aloud_consent_button')), findsOneWidget);
      expect(find.byKey(const Key('grant_consent_button')), findsOneWidget);
      expect(find.byKey(const Key('decline_consent_button')), findsOneWidget);

      // Scroll to button and tap Grant Consent
      await tester.ensureVisible(find.byKey(const Key('grant_consent_button')));
      await tester.tap(find.byKey(const Key('grant_consent_button')));
      await tester.pumpAndSettle();

      // Verify in DB
      final member = (await memberDao.getById(memberId))!;
      expect(member.consentStatus, 'given');
      final record = await consentService.getLatestConsent(memberId);
      expect(record, isNotNull);
      expect(ConsentService.verifyTamperEvidence(record!), isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    });

    testWidgets('displays minor warning and guardian branch for minor beneficiary', (tester) async {
      const memberId = 'mem-ui-minor';
      final fiveYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 5)).millisecondsSinceEpoch;
      await seedMember(memberId: memberId, name: 'Rahul Kumar', dobApprox: fiveYearsAgo);

      await tester.pumpWidget(
        buildTestWidget(
          child: const ConsentScreen(memberId: memberId),
        ),
      );
      await tester.pumpAndSettle();

      // Check minor banner is present
      expect(find.textContaining('under 18 years old'), findsOneWidget);
      expect(find.byKey(const Key('guardian_relationship_dropdown')), findsOneWidget);

      // Scroll to button and grant consent with default guardian relationship ('Parent')
      await tester.ensureVisible(find.byKey(const Key('grant_consent_button')));
      await tester.tap(find.byKey(const Key('grant_consent_button')));
      await tester.pumpAndSettle();

      final record = await consentService.getLatestConsent(memberId);
      expect(record, isNotNull);
      expect(record!.isGuardianConsent, isTrue);
      expect(record.guardianRelationship, 'Parent');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    });

    testWidgets('allows declining consent into Emergency-Only Mode via dialog', (tester) async {
      const memberId = 'mem-ui-decline';
      await seedMember(memberId: memberId, name: 'Deepa Verma');

      await tester.pumpWidget(
        buildTestWidget(
          child: const ConsentScreen(memberId: memberId),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to Decline button and tap
      await tester.ensureVisible(find.byKey(const Key('decline_consent_button')));
      await tester.tap(find.byKey(const Key('decline_consent_button')));
      await tester.pumpAndSettle();

      // Check dialog
      expect(find.text('Decline Full Consent?'), findsOneWidget);
      expect(find.text('Confirm Emergency-Only Mode'), findsOneWidget);

      // Confirm
      await tester.tap(find.text('Confirm Emergency-Only Mode'));
      await tester.pumpAndSettle();

      final member = (await memberDao.getById(memberId))!;
      expect(member.consentStatus, 'declined');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
    });
  });
}
