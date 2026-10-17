import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:asha_platform/core/database/app_database.dart' hide TriageResult;
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/core/triage/rule_loader.dart';
import 'package:asha_platform/core/voice/tts_service.dart';
import 'package:asha_platform/features/due_list/presentation/due_list_screen.dart';
import 'package:asha_platform/features/household/data/household_dao.dart';
import 'package:asha_platform/features/household/data/household_repository.dart';
import 'package:asha_platform/features/household/data/member_dao.dart';
import 'package:asha_platform/features/triage/data/triage_repository.dart';
import 'package:asha_platform/features/triage/domain/triage_service.dart';
import 'package:asha_platform/features/triage/presentation/triage_assessment_screen.dart';
import 'package:asha_platform/shared/providers/core_providers.dart';

class CheckpointFakeTts extends TtsService {
  @override
  String? lastSpokenText;
  int speakCalls = 0;

  @override
  Future<AudioSourceType> speak({
    required String text,
    String language = 'en',
    String? clipId,
  }) async {
    lastSpokenText = text;
    speakCalls++;
    return AudioSourceType.onDeviceSynthesis;
  }
}

void main() {
  group('Task 7 Checkpoint: Triage Engine End-to-End Correctness', () {
    late Directory tempDir;
    late AppDatabase db;
    late SyncEngine syncEngine;
    late RuleLoader ruleLoader;
    late TriageRepository triageRepo;
    late HouseholdRepository householdRepo;
    late CheckpointFakeTts fakeTts;
    late TriageService triageService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('triage_checkpoint_');
      db = AppDatabase.forTesting(NativeDatabase.memory());
      syncEngine = SyncEngine(db);
      ruleLoader = RuleLoader(db, storageDirectory: tempDir);
      await ruleLoader.loadActiveRuleSet();
      triageRepo = TriageRepository(db, syncEngine);
      householdRepo = HouseholdRepository(
        householdDao: HouseholdDao(db),
        memberDao: MemberDao(db),
        syncEngine: syncEngine,
      );
      fakeTts = CheckpointFakeTts();
      triageService = TriageService(
        ruleLoader: ruleLoader,
        repository: triageRepo,
        ttsService: fakeTts,
      );
    });

    tearDown(() async {
      await db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    testWidgets('Complete journey: Household Registration -> Clinical Triage -> RED Result < 1s -> Audio Readout',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Pre-register household and beneficiary member
      final now = DateTime.now().millisecondsSinceEpoch;
      final hh = await householdRepo.createHousehold(
        village: 'Rampur',
        hamlet: 'Purva',
        headName: 'Suresh Kumar',
        createdBy: 'asha_test_01',
      );

      final member = await householdRepo.addMember(
        householdId: hh.id,
        name: 'Aarav Kumar',
        sex: 'M',
        dobApprox: now - (20 * 24 * 60 * 60 * 1000), // 20 days old infant
        relationshipToHead: 'Son',
        createdBy: 'asha_test_01',
      );

      // 2. Launch App Screen with TriageAssessmentScreen bound to the member
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            syncEngineProvider.overrideWithValue(syncEngine),
            triageServiceProvider.overrideWithValue(triageService),
          ],
          child: MaterialApp(
            home: TriageAssessmentScreen(memberId: member.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify assessment form is rendered with vitals and danger sign options
      expect(find.text('Clinical Assessment'), findsOneWidget);
      expect(find.byKey(const Key('age_days_field')), findsOneWidget);
      expect(find.byKey(const Key('respiratory_rate_field')), findsOneWidget);

      // Enter fast breathing for 20-day-old infant (RR = 64/min > 60/min threshold)
      await tester.enterText(find.byKey(const Key('age_days_field')), '20');
      await tester.enterText(find.byKey(const Key('respiratory_rate_field')), '64');
      await tester.enterText(find.byKey(const Key('temperature_field')), '37.2');

      // 3. Sub-second clinical engine evaluation benchmark (Requirement 8.1)
      final inputs = TriageInputs(
        memberId: member.id,
        ageInDays: 20,
        values: const {'respiratory_rate': 64, 'temperature': 37.2},
      );
      final sw = Stopwatch()..start();
      final benchmarkResult = await triageService.evaluateAssessment(
        inputs,
        memberId: member.id,
        speakAudio: false,
      );
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(1000));
      expect(benchmarkResult.flag, equals(TriageFlag.red));

      // Submit assessment in UI
      final submitButton = find.byKey(const Key('submit_triage_button'));
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // 4. Verify TriageResultScreen displays RED result immediately
      expect(find.byKey(const Key('triage_flag_card')), findsOneWidget);
      expect(find.text('RED — Refer immediately'), findsOneWidget);
      expect(find.textContaining('Breathing rate 64/min in infant 20 days — refer now'), findsOneWidget);

      // Decision support disclaimer present (without forbidden words "diagnosis"/"prescription")
      expect(find.byKey(const Key('triage_disclaimer_banner')), findsOneWidget);
      expect(find.text(TriageResult.disclaimer), findsOneWidget);
      expect(find.textContaining('diagnosis', findRichText: true), findsNothing);
      expect(find.textContaining('prescription', findRichText: true), findsNothing);

      // Referral button is visible
      expect(find.byKey(const Key('referral_action_button')), findsOneWidget);

      // 4. Verify Audio Readout (Requirement 46.1, 46.2)
      // TriageService evaluated assessment with speakAudio: true
      expect(fakeTts.speakCalls, greaterThanOrEqualTo(1));
      expect(fakeTts.lastSpokenText, contains('Flag RED'));
      expect(fakeTts.lastSpokenText, contains('refer immediately'));

      // 5. Verify database persistence & sync queue prioritization
      final savedResults = await db.select(db.triageResults).get();
      expect(savedResults.isNotEmpty, isTrue);
      expect(savedResults.first.flag, equals('RED'));

      final syncEntries = await db.select(db.syncQueue).get();
      // Expect P1 critical entry for RED referral
      final p1Entries = syncEntries.where((e) => e.priority == 1).toList();
      expect(p1Entries.isNotEmpty, isTrue);
      expect(p1Entries.first.targetTable, equals('triage_results'));
    });

    testWidgets('Home DueListScreen navigation button reaches Triage Assessment', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const DueListScreen(),
          ),
          GoRoute(
            path: '/triage',
            builder: (context, state) => const TriageAssessmentScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            syncEngineProvider.overrideWithValue(syncEngine),
            triageServiceProvider.overrideWithValue(triageService),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Home screen has the Clinical Triage & Assessment button
      final triageButton = find.byKey(const Key('home_triage_button'));
      expect(triageButton, findsOneWidget);

      await tester.tap(triageButton);
      await tester.pumpAndSettle();

      // Navigated to TriageAssessmentScreen
      expect(find.text('Clinical Assessment'), findsOneWidget);
      expect(find.byKey(const Key('submit_triage_button')), findsOneWidget);
    });
  });
}
