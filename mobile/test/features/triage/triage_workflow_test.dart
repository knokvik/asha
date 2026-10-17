import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart' hide TriageResult;
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/core/triage/rule_loader.dart';
import 'package:asha_platform/core/triage/triage_engine.dart';
import 'package:asha_platform/core/voice/tts_service.dart';
import 'package:asha_platform/features/triage/data/triage_repository.dart';
import 'package:asha_platform/features/triage/domain/triage_service.dart';
import 'package:asha_platform/features/triage/presentation/triage_assessment_screen.dart';
import 'package:asha_platform/features/triage/presentation/triage_result_screen.dart';
import 'package:asha_platform/shared/providers/core_providers.dart';

class FakeTtsService extends TtsService {
  String? lastSpoken;
  int speakCount = 0;

  @override
  Future<AudioSourceType> speak({
    required String text,
    String language = 'en',
    String? clipId,
  }) async {
    lastSpoken = text;
    speakCount++;
    return AudioSourceType.onDeviceSynthesis;
  }
}

void main() {
  group('Triage Flow, Persistence, ML Hook & Overrides (Tasks 6.3 & 6.4)', () {
    late Directory tempDir;
    late AppDatabase db;
    late SyncEngine syncEngine;
    late RuleLoader ruleLoader;
    late TriageRepository repository;
    late FakeTtsService fakeTts;
    late TriageService triageService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('rules_workflow_test_');
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      ruleLoader = RuleLoader(db, storageDirectory: tempDir);
      await ruleLoader.loadActiveRuleSet();
      repository = TriageRepository(db, syncEngine);
      fakeTts = FakeTtsService();
      triageService = TriageService(
        ruleLoader: ruleLoader,
        repository: repository,
        ttsService: fakeTts,
      );
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('TriageRepository persists TriageResult and records clinical override', () async {
      const inputs = TriageInputs(
        encounterId: 'enc_test_01',
        ageInDays: 30,
        values: {'respiratory_rate': 65, 'temperature': 37.0},
      );
      final ruleSet = await ruleLoader.loadActiveRuleSet();
      final engine = TriageEngine(ruleSet: ruleSet);
      final result = engine.evaluate(inputs, ruleSet);

      // 1. Save triage result
      await repository.saveTriageResult(result, memberId: 'member_01');

      final fetched = await repository.getTriageResult(result.id);
      expect(fetched, isNotNull);
      expect(fetched!.flag, equals(TriageFlag.red));
      expect(fetched.findings.first.ruleId, equals('INFANT_FAST_BREATHING'));

      // Verify sync queue contains P1 critical entry
      final queueEntries = await db.select(db.syncQueue).get();
      expect(queueEntries.length, equals(1));
      expect(queueEntries.first.priority, equals(1)); // P1 Critical for RED
      expect(queueEntries.first.targetTable, equals('triage_results'));

      // 2. Record clinical override (Requirement 8.6)
      final override = TriageOverride(
        encounterId: 'enc_test_01',
        originalFlag: TriageFlag.red,
        overrideFlag: TriageFlag.yellow,
        reason: 'Infant was agitated and crying during initial measurement; recount shows calm breathing',
        overridingUserId: 'asha_101',
      );

      await repository.recordOverride(
        triageResultId: result.id,
        override: override,
      );

      // Verify DB row has both engine original output and override
      final row = await (db.select(db.triageResults)..where((t) => t.id.equals(result.id))).getSingle();
      expect(row.flag, equals('RED')); // Original engine output
      expect(row.overrideFlag, equals('YELLOW')); // Override flag
      expect(row.overrideReason, contains('agitated and crying'));
      expect(row.overridingUserId, equals('asha_101'));
      expect(row.overriddenAt, isNotNull);
    });

    test('TriageService evaluates under 1 second and speaks audio feedback', () async {
      const inputs = TriageInputs(
        encounterId: 'enc_speed_test',
        ageInDays: 25,
        values: {'respiratory_rate': 62, 'temperature': 37.1},
      );

      final sw = Stopwatch()..start();
      final result = await triageService.evaluateAssessment(
        inputs,
        memberId: 'mem_speed',
        speakAudio: true,
      );
      sw.stop();

      // Benchmark Requirement 8.1: < 1 second
      expect(sw.elapsedMilliseconds, lessThan(1000));
      expect(result.flag, equals(TriageFlag.red));

      // Audio readout Requirement 46.1, 46.2: Colour + primary reason + action
      expect(fakeTts.speakCount, equals(1));
      expect(fakeTts.lastSpoken, contains('Flag RED'));
      expect(fakeTts.lastSpoken, contains('Breathing rate 62/min in infant 25 days'));
      expect(fakeTts.lastSpoken, contains('refer immediately'));
    });

    testWidgets('TriageResultScreen renders disclaimer, findings, ML contribution, and performs override', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final triageResult = TriageResult(
        id: 'res_ui_test',
        encounterId: 'enc_ui_test',
        flag: TriageFlag.red,
        ruleFlag: TriageFlag.yellow,
        ruleVersionId: '1.0.0',
        evaluatedAt: DateTime.now(),
        findings: const [
          TriageFinding(
            ruleId: 'INFANT_FAST_BREATHING',
            severity: TriageFlag.yellow,
            findingText: 'Breathing rate 52/min in infant',
            triggeringValues: {'respiratory_rate': 52},
            action: 'MONITOR_CLOSELY',
            sourceCitation: 'IMNCI 2014, p.12',
          ),
        ],
        mlContribution: const MLTriageContribution(
          mlFlag: TriageFlag.red,
          featureWeights: {'respiratory_rate': 0.70, 'temperature': 0.30},
          confidenceScore: 0.92,
        ),
      );

      bool referralOpened = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            syncEngineProvider.overrideWithValue(syncEngine),
            triageServiceProvider.overrideWithValue(triageService),
          ],
          child: MaterialApp(
            home: TriageResultScreen(
              initialResult: triageResult,
              onReferralRequested: () => referralOpened = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Prominent Decision Support Disclaimer (Requirement 8.7)
      expect(find.byKey(const Key('triage_disclaimer_banner')), findsOneWidget);
      expect(find.text(TriageResult.disclaimer), findsOneWidget);
      // Ensure "diagnosis" and "prescription" are excluded
      expect(find.textContaining('diagnosis', findRichText: true), findsNothing);
      expect(find.textContaining('prescription', findRichText: true), findsNothing);

      // 2. Main Severity Flag Card
      expect(find.byKey(const Key('triage_flag_card')), findsOneWidget);
      expect(find.text('RED — Refer immediately'), findsOneWidget);

      // 3. Contributing Findings
      expect(find.byKey(const Key('finding_INFANT_FAST_BREATHING')), findsOneWidget);
      expect(find.text('Breathing rate 52/min in infant'), findsOneWidget);

      // 4. ML Contribution Card (Requirement 8.9)
      expect(find.byKey(const Key('ml_contribution_card')), findsOneWidget);
      expect(find.text('Machine Learning Risk Score (Advisory)'), findsOneWidget);
      expect(find.textContaining('Confidence: 92.0%'), findsOneWidget);
      expect(find.text('respiratory_rate'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);

      // 5. Automatic Referral callback invoked on RED
      expect(referralOpened, isTrue);

      // 6. Test Audio Speech Button (Requirement 46.1, 46.2)
      final speakButton = find.byKey(const Key('speak_result_button'));
      expect(speakButton, findsOneWidget);
      await tester.tap(speakButton);
      await tester.pumpAndSettle();
      expect(fakeTts.speakCount, greaterThan(0));

      // 7. Clinical Override Flow (Requirement 8.6)
      final overrideButton = find.byKey(const Key('triage_override_button'));
      expect(overrideButton, findsOneWidget);
      await tester.ensureVisible(overrideButton);
      await tester.tap(overrideButton);
      await tester.pumpAndSettle();

      // Bottom sheet is now open
      expect(find.text('Clinical Decision Override'), findsOneWidget);

      // Try short reason (< 10 chars) -> Confirm button is disabled
      final reasonField = find.byKey(const Key('override_reason_field'));
      await tester.enterText(reasonField, 'Too short');
      await tester.pumpAndSettle();

      final confirmButton = find.byKey(const Key('confirm_override_button'));
      expect(tester.widget<ElevatedButton>(confirmButton).enabled, isFalse);

      // Enter valid reason (>= 10 chars)
      await tester.enterText(
        reasonField,
        'Recounted breathing rate while calm: 42 breaths per min, child drinking well',
      );
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(confirmButton).enabled, isTrue);

      // Submit override
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verify override banner appears on screen showing both engine output and ASHA override
      expect(find.textContaining('Overridden by ASHA (Engine output: RED)'), findsOneWidget);
      expect(find.textContaining('Recounted breathing rate while calm'), findsOneWidget);
    });

    testWidgets('TriageAssessmentScreen full form submission and evaluation flow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            syncEngineProvider.overrideWithValue(syncEngine),
            triageServiceProvider.overrideWithValue(triageService),
          ],
          child: const MaterialApp(
            home: TriageAssessmentScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter vitals for young infant with fast breathing
      await tester.enterText(find.byKey(const Key('age_days_field')), '45');
      await tester.enterText(find.byKey(const Key('respiratory_rate_field')), '68');
      await tester.enterText(find.byKey(const Key('temperature_field')), '37.0');

      // Submit assessment
      final submitButton = find.byKey(const Key('submit_triage_button'));
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Navigates to result screen with RED flag
      expect(find.text('RED — Refer immediately'), findsOneWidget);
      expect(find.textContaining('Breathing rate 68/min in infant 45 days — refer now'), findsOneWidget);
      expect(find.byKey(const Key('referral_action_button')), findsOneWidget);
    });
  });
}
