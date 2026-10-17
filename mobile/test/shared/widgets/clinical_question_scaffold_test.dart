import 'package:asha_platform/core/l10n/ota_string_service.dart';
import 'package:asha_platform/core/voice/vosk_service.dart';
import 'package:asha_platform/shared/widgets/clinical_question_scaffold.dart';
import 'package:asha_platform/shared/widgets/voice_form_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OtaStringService Dynamic Bundle Updates (Requirement 3.6)', () {
    test('Falls back to default text when key has no OTA override', () {
      final otaService = OtaStringService();

      final text = otaService.lookup(
        'fastBreathing',
        language: 'hi',
        fallback: 'तेज सांस',
      );

      expect(text, equals('तेज सांस'));
      expect(otaService.hasOverride('fastBreathing', language: 'hi'), isFalse);
    });

    test('applyBundle dynamically updates strings without APK update', () async {
      final otaService = OtaStringService();

      await otaService.applyBundle({
        'language': 'hi',
        'version': '2024.2_ota',
        'strings': {
          'fastBreathing': 'साँस तेज़ चलना (अपडेटेड)',
          'fever': 'तेज़ बुखार (अपडेटेड)',
        },
      });

      expect(otaService.hasOverride('fastBreathing', language: 'hi'), isTrue);
      expect(
        otaService.lookup('fastBreathing', language: 'hi', fallback: 'पुराना'),
        equals('साँस तेज़ चलना (अपडेटेड)'),
      );
      expect(
        otaService.lookup('fever', language: 'hi'),
        equals('तेज़ बुखार (अपडेटेड)'),
      );
      expect(otaService.getVersion('hi'), equals('2024.2_ota'));
    });
  });

  group('ClinicalQuestionScaffold Framework (Requirements 3.2, 3.3, 3.4, 49.1, 49.4)', () {
    testWidgets('Renders one question per screen with title, progress, and clinical icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ClinicalQuestionScaffold(
              currentQuestionIndex: 1,
              totalQuestions: 5,
              questionTitle: 'Is the baby breathing fast?',
              questionSubtitle: 'Count breaths for one minute when the child is calm.',
              clinicalIcon: Icons.air,
              child: Text('Input content'),
            ),
          ),
        ),
      );

      expect(find.text('Question 1 of 5'), findsOneWidget);
      expect(find.text('Is the baby breathing fast?'), findsOneWidget);
      expect(find.text('Count breaths for one minute when the child is calm.'), findsOneWidget);
      expect(find.byIcon(Icons.air), findsOneWidget);
      expect(find.text('Input content'), findsOneWidget);
      expect(find.byKey(const Key('scaffold_audio_prompt_button')), findsOneWidget);
    });

    testWidgets('Navigation controls execute callbacks and respect state', (tester) async {
      bool nextFired = false;
      bool prevFired = false;
      bool skipFired = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ClinicalQuestionScaffold(
              currentQuestionIndex: 2,
              totalQuestions: 5,
              questionTitle: 'Question 2',
              isSkippable: true,
              onNext: () => nextFired = true,
              onPrevious: () => prevFired = true,
              onSkip: () => skipFired = true,
              child: const SizedBox(),
            ),
          ),
        ),
      );

      // Previous button exists on question 2
      final prevFinder = find.byKey(const Key('scaffold_prev_button'));
      expect(prevFinder, findsOneWidget);
      await tester.tap(prevFinder);
      expect(prevFired, isTrue);

      // Skip button exists when isSkippable = true
      final skipFinder = find.byKey(const Key('scaffold_skip_button'));
      expect(skipFinder, findsOneWidget);
      await tester.tap(skipFinder);
      expect(skipFired, isTrue);

      // Next button
      final nextFinder = find.byKey(const Key('scaffold_next_button'));
      expect(nextFinder, findsOneWidget);
      await tester.tap(nextFinder);
      expect(nextFired, isTrue);
    });

    testWidgets('Changes next button label to Submit on last question', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ClinicalQuestionScaffold(
              currentQuestionIndex: 5,
              totalQuestions: 5,
              questionTitle: 'Final Question',
              isLastQuestion: true,
              child: SizedBox(),
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('All interactive controls meet WCAG AA minimum 48x48 dp touch target', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ClinicalQuestionScaffold(
              currentQuestionIndex: 2,
              totalQuestions: 5,
              questionTitle: 'Touch Target Test',
              isSkippable: true,
              audioPromptText: 'Audio prompt',
              child: SizedBox(),
            ),
          ),
        ),
      );

      final nextSize = tester.getSize(find.byKey(const Key('scaffold_next_button')));
      final prevSize = tester.getSize(find.byKey(const Key('scaffold_prev_button')));
      final skipSize = tester.getSize(find.byKey(const Key('scaffold_skip_button')));

      expect(nextSize.height, greaterThanOrEqualTo(48.0));
      expect(nextSize.width, greaterThanOrEqualTo(48.0));
      expect(prevSize.height, greaterThanOrEqualTo(48.0));
      expect(prevSize.width, greaterThanOrEqualTo(48.0));
      expect(skipSize.height, greaterThanOrEqualTo(48.0));
      expect(skipSize.width, greaterThanOrEqualTo(48.0));
    });
  });

  group('VoiceFormField Integration (Requirements 6.1, 6.2, 6.3, 6.5, 6.7, 49.4)', () {
    testWidgets('Renders input field and microphone button with >= 48x48 dp touch target', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceFormField(
              controller: controller,
              label: 'Respiratory Rate',
              hintText: 'Enter breaths per minute',
            ),
          ),
        ),
      );

      final micFinder = find.byKey(const Key('voice_field_mic_button'));
      expect(micFinder, findsOneWidget);

      final micSize = tester.getSize(micFinder);
      expect(micSize.height, greaterThanOrEqualTo(48.0));
      expect(micSize.width, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Low RAM (< 1GB) warns and falls back to tap entry without crash', (tester) async {
      final controller = TextEditingController();
      final lowRamVosk = VoskService(deviceRamMb: 512);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceFormField(
              controller: controller,
              label: 'Symptom Flag',
              voskService: lowRamVosk,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('voice_field_mic_button')));
      await tester.pumpAndSettle();

      expect(
        find.text('Voice input disabled for low memory. Please use tap/keyboard entry.'),
        findsOneWidget,
      );
    });

    testWidgets('High confidence transcript canonicalises and updates controller automatically', (tester) async {
      final controller = TextEditingController();
      final formFieldKey = GlobalKey<State<VoiceFormField>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceFormField(
              key: formFieldKey,
              controller: controller,
              label: 'Symptom',
              language: 'hi',
            ),
          ),
        ),
      );

      final formFieldState = formFieldKey.currentState as dynamic;
      await formFieldState.processVoiceResult(
        rawTranscript: 'साँस तेज़',
        confidence: 0.85,
        rms: 0.20,
      );
      await tester.pumpAndSettle();

      expect(controller.text, equals('FAST_BREATHING'));
    });

    testWidgets('Low confidence (< 0.70) surfaces confirmation dialog before updating controller', (tester) async {
      final controller = TextEditingController();
      final formFieldKey = GlobalKey<State<VoiceFormField>>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoiceFormField(
              key: formFieldKey,
              controller: controller,
              label: 'Symptom',
              language: 'hi',
            ),
          ),
        ),
      );

      final formFieldState = formFieldKey.currentState as dynamic;

      // Asynchronously trigger low-confidence result
      formFieldState.processVoiceResult(
        rawTranscript: 'पीलिया',
        confidence: 0.55, // Below 0.70 threshold
        rms: 0.20,
      );
      await tester.pumpAndSettle();

      // Dialog should be presented
      expect(find.text('Confirm Voice Input'), findsOneWidget);
      expect(controller.text, isEmpty); // Not yet applied!

      // Confirm dialog
      await tester.tap(find.byKey(const Key('confirm_voice_button')));
      await tester.pumpAndSettle();

      // Now value is applied
      expect(controller.text, equals('JAUNDICE'));
    });
  });
}
