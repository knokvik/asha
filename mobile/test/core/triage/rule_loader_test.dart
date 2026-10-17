import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/core/triage/rule_loader.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  group('RuleLoader - OTA Versioning, Integrity Hash & Rollback (Task 6.2, Req 9.2-9.4)', () {
    late AppDatabase db;
    late MockHttpClient mockClient;
    late Directory tempDir;
    late RuleLoader ruleLoader;

    setUpAll(() {
      registerFallbackValue(Uri.parse('https://example.com'));
    });

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      mockClient = MockHttpClient();
      tempDir = await Directory.systemTemp.createTemp('rules_test_');

      ruleLoader = RuleLoader(
        db,
        httpClient: mockClient,
        storageDirectory: tempDir,
      );
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Loads national base rule set on fresh install and caches in memory (sub-10ms)', () async {
      final sw = Stopwatch()..start();
      final initialRuleSet = await ruleLoader.loadActiveRuleSet();
      sw.stop();

      expect(initialRuleSet.versionString, equals('1.0.0'));
      expect(initialRuleSet.rules.isNotEmpty, isTrue);

      // Verify DB row exists and isActive is true
      final rows = await db.select(db.ruleVersions).get();
      expect(rows.length, equals(1));
      expect(rows.first.isActive, isTrue);
      expect(rows.first.versionString, equals('1.0.0'));

      // Verify sub-10ms in-memory cache
      final cacheSw = Stopwatch()..start();
      final cached = await ruleLoader.loadActiveRuleSet();
      cacheSw.stop();

      expect(cached, equals(initialRuleSet));
      expect(cacheSw.elapsedMilliseconds, lessThan(10));
    });

    test('checkForUpdates queries backend metadata endpoint', () async {
      when(() => mockClient.get(Uri.parse('https://api.test/api/v1/rules/latest'))).thenAnswer(
        (_) async => http.Response(
          jsonEncode({
            'id': 'ruleset-v1.1.0',
            'version_string': '1.1.0',
            'published_at': 1720000000000,
            'bundle_hash': 'abc123hash',
            'download_url': '/api/v1/rules/1.1.0/bundle.json.gz',
            'clinical_lead_id': 'lead_1',
            'approval_signature': 'SIG_TEST',
            'is_active': true,
          }),
          200,
        ),
      );

      final meta = await ruleLoader.checkForUpdates(baseUrl: 'https://api.test');
      expect(meta, isNotNull);
      expect(meta!.versionString, equals('1.1.0'));
      expect(meta.bundleHash, equals('abc123hash'));
      expect(meta.downloadUrl, equals('/api/v1/rules/1.1.0/bundle.json.gz'));
    });

    test('downloadAndActivate downloads gzip, verifies hash, activates and retains previous for rollback', () async {
      // 1. First ensure base 1.0.0 is active
      await ruleLoader.loadActiveRuleSet();

      // 2. Prepare new 1.1.0 rule set bundle
      final newRuleSet = RuleSet(
        id: 'ruleset-national-v1.1.0',
        versionString: '1.1.0',
        publishedAt: 1720000000000,
        clinicalLeadId: 'lead_clinician_01',
        approvalSignature: 'SIG_VALIDATED_BUNDLE_V11',
        bundleHash: '',
        ageBands: [
          for (final code in AgeBandCode.values) AgeBand.defaultFor(code),
        ],
        rules: [
          const TriageRule(
            ruleId: 'INFANT_FAST_BREATHING_UPDATED',
            ageBand: AgeBandCode.infant02m,
            severity: TriageFlag.red,
            sourceCitation: 'IMNCI Updated 2024, p.15',
            condition: Condition(
              op: ConditionOp.gte,
              field: 'respiratory_rate',
              value: 60,
            ),
            findingTemplate: 'Infant fast breathing {respiratory_rate}/min',
            action: 'REFER_IMMEDIATELY',
          ),
        ],
      );

      final canonicalJson = jsonEncode(newRuleSet.toJson());
      final uncompressedBytes = utf8.encode(canonicalJson);
      final expectedHash = sha256.convert(uncompressedBytes).toString();
      final gzippedBytes = gzip.encode(uncompressedBytes);

      final metadata = RuleVersionMetadata(
        id: newRuleSet.id,
        versionString: '1.1.0',
        publishedAt: 1720000000000,
        bundleHash: expectedHash,
        downloadUrl: '/api/v1/rules/1.1.0/bundle.json.gz',
        clinicalLeadId: 'lead_clinician_01',
        approvalSignature: 'SIG_VALIDATED_BUNDLE_V11',
      );

      when(() => mockClient.get(Uri.parse('https://api.test/api/v1/rules/1.1.0/bundle.json.gz'))).thenAnswer(
        (_) async => http.Response.bytes(gzippedBytes, 200),
      );

      // 3. Download and activate
      final activated = await ruleLoader.downloadAndActivate(
        baseUrl: 'https://api.test',
        metadata: metadata,
      );

      expect(activated.versionString, equals('1.1.0'));
      expect(ruleLoader.cachedRuleSet?.versionString, equals('1.1.0'));

      // Verify DB: 1.1.0 is active, 1.0.0 is retained as inactive
      final allRows = await db.select(db.ruleVersions).get();
      expect(allRows.length, equals(2));

      final activeRow = allRows.firstWhere((r) => r.isActive);
      expect(activeRow.versionString, equals('1.1.0'));

      final inactiveRow = allRows.firstWhere((r) => !r.isActive);
      expect(inactiveRow.versionString, equals('1.0.0'));

      // 4. Test Rollback to previous version (Requirement 9.3: retain previous version for rollback)
      final rolledBack = await ruleLoader.rollbackToPreviousVersion();
      expect(rolledBack, isNotNull);
      expect(rolledBack!.versionString, equals('1.0.0'));
      expect(ruleLoader.cachedRuleSet?.versionString, equals('1.0.0'));

      final afterRollbackRows = await db.select(db.ruleVersions).get();
      final restoredActiveRow = afterRollbackRows.firstWhere((r) => r.isActive);
      expect(restoredActiveRow.versionString, equals('1.0.0'));
    });

    test('downloadAndActivate rejects corrupted bundle with hash mismatch and does not activate', () async {
      await ruleLoader.loadActiveRuleSet();

      final corruptedBytes = gzip.encode(utf8.encode('{"corrupted": true}'));
      const wrongHash = 'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

      final metadata = const RuleVersionMetadata(
        id: 'corrupted-ruleset',
        versionString: '2.0.0',
        publishedAt: 1730000000000,
        bundleHash: wrongHash,
        downloadUrl: '/api/v1/rules/2.0.0/bundle.json.gz',
      );

      when(() => mockClient.get(Uri.parse('https://api.test/api/v1/rules/2.0.0/bundle.json.gz'))).thenAnswer(
        (_) async => http.Response.bytes(corruptedBytes, 200),
      );

      expect(
        () => ruleLoader.downloadAndActivate(
          baseUrl: 'https://api.test',
          metadata: metadata,
        ),
        throwsA(isA<StateError>()),
      );

      // Verify active version is still 1.0.0 (corrupted version was NOT activated)
      final rows = await db.select(db.ruleVersions).get();
      expect(rows.length, equals(1));
      expect(rows.first.isActive, isTrue);
      expect(rows.first.versionString, equals('1.0.0'));
      expect(ruleLoader.cachedRuleSet?.versionString, equals('1.0.0'));
    });
  });
}
