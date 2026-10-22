import 'package:asha_platform/core/voice/procedure_guidance_sheet.dart';
import 'package:asha_platform/core/voice/tap_to_hear_button.dart';
import 'package:asha_platform/core/voice/tts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'TtsService Audio Fallback & Clip Handling (Requirements 7.1, 7.3)',
    () {
      test(
        'Falls back to on-device synthesis when pre-recorded clip is absent',
        () async {
          final tts = TtsService();

          expect(tts.isClipAvailable('non_existent_clip', 'hi'), isFalse);

          final sourceType = await tts.speak(
            text: 'This is a test prompt',
            language: 'hi',
            clipId: 'non_existent_clip',
          );

          expect(sourceType, AudioSourceType.onDeviceSynthesis);
          expect(tts.lastAudioSource, AudioSourceType.onDeviceSynthesis);
          expect(tts.lastSpokenText, 'This is a test prompt');
        },
      );

      test('Uses pre-recorded clip when registered for language', () async {
        final tts = TtsService();

        tts.registerClip(
          clipId: 'triage_red_clip',
          language: 'hi',
          assetPath: 'assets/audio/hi/triage_red.mp3',
        );

        expect(tts.isClipAvailable('triage_red_clip', 'hi'), isTrue);
        expect(tts.isClipAvailable('triage_red_clip', 'hi-IN'), isTrue);
        expect(tts.isClipAvailable('triage_red_clip', 'mr'), isFalse);

        final sourceType = await tts.speak(
          text: 'Emergency flag red',
          language: 'hi',
          clipId: 'triage_red_clip',
        );

        expect(sourceType, AudioSourceType.preRecordedClip);
        expect(tts.lastAudioSource, AudioSourceType.preRecordedClip);
      });

      test('Formats triage speech with color, reason, and recommended action (Requirement 7.1)', () async {
        final tts = TtsService();

        await tts.speakTriageResult(
          flagColor: 'RED',
          reason: 'Infant respiratory rate 64/min',
          action: 'Refer immediately to CHC',
          language: 'en',
        );

        expect(
          tts.lastSpokenText,
          'Triage Flag RED. Reason: Infant respiratory rate 64/min. Recommended Action: Refer immediately to CHC.',
        );
      });

      test('Formats family-facing explanation distinct from clinical text (Requirement 7.4)', () async {
        final tts = TtsService();

        await tts.speakTriageResult(
          flagColor: 'RED',
          reason: 'Fast breathing',
          action: 'Immediate referral',
          language: 'en',
          isFamilyFacing: true,
        );

        expect(
          tts.lastSpokenText,
          contains('Alert: The baby needs urgent medical care'),
        );
      });
    },
  );

  group('Clinical Procedure Guidance Sequences (Requirement 7.2)', () {
    test('Breath counting procedure has 3 steps including 60-second timer', () {
      final steps = TtsService.getProcedureSteps(
        ClinicalProcedure.breathCounting,
      );
      expect(steps.length, 3);
      expect(steps[0].title, 'Prepare Infant');
      expect(steps[2].title, 'Count for 60 Seconds');
      expect(steps[2].timerDuration, const Duration(seconds: 60));
    });

    test('MUAC measurement procedure has 3 steps with color zone guidance', () {
      final steps = TtsService.getProcedureSteps(ClinicalProcedure.muac);
      expect(steps.length, 3);
      expect(steps[0].title, 'Select Left Arm');
      expect(steps[2].title, 'Read Color Zone');
      expect(steps[2].instructionText, contains('Red (<115mm SAM)'));
    });

    test('ORS preparation procedure has 4 steps with 1-litre measurement instructions', () {
      final steps = TtsService.getProcedureSteps(
        ClinicalProcedure.orsPreparation,
      );
      expect(steps.length, 4);
      expect(steps[0].title, 'Wash Hands');
      expect(steps[1].title, 'Measure 1 Litre Clean Water');
      expect(steps[2].title, 'Add Full ORS Packet');
      expect(steps[3].title, 'Stir & Administer');
    });
  });

  group('TapToHearButton Widget Tests (Requirements 7.1, 7.3, 7.4)', () {
    testWidgets('Renders speaker button and triggers audio on tap', (
      tester,
    ) async {
      final tts = TtsService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [ttsServiceProvider.overrideWithValue(tts)],
          child: const MaterialApp(
            home: Scaffold(
              body: TapToHearButton(
                text: 'Please set your 4-digit PIN',
                language: 'en',
              ),
            ),
          ),
        ),
      );

      final speakerFinder = find.byKey(const Key('tap_to_hear_speaker_button'));
      expect(speakerFinder, findsOneWidget);

      await tester.tap(speakerFinder);
      await tester.pump();

      expect(tts.lastSpokenText, 'Please set your 4-digit PIN');
    });

    testWidgets('Toggles family-facing explanation when available', (
      tester,
    ) async {
      final tts = TtsService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [ttsServiceProvider.overrideWithValue(tts)],
          child: const MaterialApp(
            home: Scaffold(
              body: TapToHearButton(
                text: 'Severe acute malnutrition detected',
                familyExplanation:
                    'Your child needs nutrition support at the clinic',
                language: 'en',
              ),
            ),
          ),
        ),
      );

      final familyToggleFinder = find.byKey(
        const Key('family_mode_toggle_button'),
      );
      expect(familyToggleFinder, findsOneWidget);
      expect(find.text('Clinician View'), findsOneWidget);

      // Toggle to Family View
      await tester.tap(familyToggleFinder);
      await tester.pump();

      expect(find.text('Family View'), findsOneWidget);

      // Tap speaker
      await tester.tap(find.byKey(const Key('tap_to_hear_speaker_button')));
      await tester.pump();

      expect(
        tts.lastSpokenText,
        'Your child needs nutrition support at the clinic',
      );
    });

    testWidgets('TapToHearButton adheres to WCAG AA 48x48 dp touch target', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: TapToHearButton(text: 'Touch test')),
          ),
        ),
      );

      final speakerSize = tester.getSize(
        find.byKey(const Key('tap_to_hear_speaker_button')),
      );
      expect(speakerSize.height, greaterThanOrEqualTo(48.0));
      expect(speakerSize.width, greaterThanOrEqualTo(48.0));
    });
  });

  group('ProcedureGuidanceSheet Widget Tests (Requirements 7.2, 7.4)', () {
    testWidgets(
      'Renders procedure sheet, displays step 1 and advances to next step',
      (tester) async {
        final tts = TtsService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [ttsServiceProvider.overrideWithValue(tts)],
            child: const MaterialApp(
              home: Scaffold(
                body: ProcedureGuidanceSheet(
                  procedure: ClinicalProcedure.breathCounting,
                  language: 'en',
                  enableTimer: false,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Breath Counting Procedure'), findsOneWidget);
        expect(find.text('Step 1 of 3'), findsOneWidget);
        expect(find.text('Prepare Infant'), findsOneWidget);

        // Advance to step 2
        final nextButton = find.byKey(const Key('next_step_button'));
        await tester.tap(nextButton);
        await tester.pump();

        expect(find.text('Step 2 of 3'), findsOneWidget);
        expect(find.text('Locate Chest Movement'), findsOneWidget);

        // Previous button should now be available
        final prevButton = find.byKey(const Key('prev_step_button'));
        expect(prevButton, findsOneWidget);
        await tester.tap(prevButton);
        await tester.pump();

        expect(find.text('Step 1 of 3'), findsOneWidget);
      },
    );

    testWidgets(
      'Guidance sheet buttons adhere to WCAG AA 48x48 dp touch targets',
      (tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: ProcedureGuidanceSheet(
                  procedure: ClinicalProcedure.muac,
                  enableTimer: false,
                ),
              ),
            ),
          ),
        );

        final listenSize = tester.getSize(
          find.byKey(const Key('repeat_audio_button')),
        );
        final nextSize = tester.getSize(
          find.byKey(const Key('next_step_button')),
        );

        expect(listenSize.height, greaterThanOrEqualTo(48.0));
        expect(listenSize.width, greaterThanOrEqualTo(48.0));
        expect(nextSize.height, greaterThanOrEqualTo(48.0));
        expect(nextSize.width, greaterThanOrEqualTo(48.0));
      },
    );
  });
}
