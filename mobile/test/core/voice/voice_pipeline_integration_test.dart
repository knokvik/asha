import 'dart:typed_data';

import 'package:asha_platform/core/voice/confidence_confirmation_dialog.dart';
import 'package:asha_platform/core/voice/lexicon_service.dart';
import 'package:asha_platform/core/voice/too_noisy_dialog.dart';
import 'package:asha_platform/core/voice/tts_service.dart';
import 'package:asha_platform/core/voice/vosk_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task 4.7: Voice Pipeline Acceptance Tests (Requirements 6.2, 6.3, 6.5, 7.3)', () {
    late LexiconService lexicon;
    late VoskService vosk;
    late TtsService tts;

    setUp(() {
      lexicon = LexiconService();
      vosk = VoskService(noiseThreshold: 0.65, confidenceThreshold: 0.70);
      tts = TtsService();
    });

    test('Test: Lexicon maps dialect variant to canonical concept (Hindi, Marathi, English)', () {
      // Hindi variants
      expect(
        lexicon.lookup('साँस तेज़', language: 'hi')?.canonicalConcept,
        equals('FAST_BREATHING'),
      );
      expect(
        lexicon.lookup('पीलिया', language: 'hi')?.canonicalConcept,
        equals('JAUNDICE'),
      );
      expect(
        lexicon.lookup('तेज बुखार', language: 'hi')?.canonicalConcept,
        equals('FEVER'),
      );

      // Marathi variants
      lexicon.registerBundle(
        const LexiconBundle(
          language: 'mr',
          version: '1.0',
          entries: [
            LexiconEntry(
              spokenVariants: ['श्वास जलद', 'दम लागणे'],
              canonicalConcept: 'FAST_BREATHING',
            ),
            LexiconEntry(
              spokenVariants: ['कावीळ'],
              canonicalConcept: 'JAUNDICE',
            ),
          ],
        ),
      );
      expect(
        lexicon.lookup('श्वास जलद', language: 'mr')?.canonicalConcept,
        equals('FAST_BREATHING'),
      );
      expect(
        lexicon.lookup('कावीळ', language: 'mr')?.canonicalConcept,
        equals('JAUNDICE'),
      );

      // English variants
      expect(
        lexicon.lookup('fast breathing', language: 'en')?.canonicalConcept,
        equals('FAST_BREATHING'),
      );
    });

    test('Property test: canonicalise is idempotent — canonicalise(canonicalise(x)) == canonicalise(x)', () {
      final terms = [
        'साँस तेज़',
        'सांस फूलना',
        'पीलिया',
        'बुखार',
        'FAST_BREATHING',
        'JAUNDICE',
        'FEVER',
        'YES',
        'NO',
        '30',
        'unrecognized colloquial phrase',
        '1234',
      ];

      for (final term in terms) {
        final once = lexicon.canonicalise(term, language: 'hi');
        final twice = lexicon.canonicalise(once, language: 'hi');
        expect(
          twice,
          equals(once),
          reason: 'Property 13 (Idempotence) violated for term "$term"',
        );
      }
    });

    test('Test: noise RMS above threshold triggers tap-only offer', () {
      // Silence
      final silenceRms = VoskService.computeRms(Int16List(800));
      expect(vosk.isNoiseExcessive(silenceRms), isFalse);

      // Excessive noise RMS (e.g. 0.85 > 0.65)
      expect(vosk.isNoiseExcessive(0.85), isTrue);

      final noisyResult = vosk.evaluateResult(
        transcript: 'fever',
        confidence: 0.90,
        rms: 0.85,
      );
      expect(noisyResult.isExcessiveNoise, isTrue);
      expect(noisyResult.isLowConfidence, isTrue);
    });

    testWidgets('Test: noise RMS above threshold surfaces TooNoisyDialog offering tap entry', (tester) async {
      bool tapEntrySelected = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  TooNoisyDialog.show(
                    context,
                    onTapEntry: () {
                      tapEntrySelected = true;
                    },
                  );
                },
                child: const Text('Simulate Excessive Noise'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Simulate Excessive Noise'));
      await tester.pumpAndSettle();

      expect(find.byType(TooNoisyDialog), findsOneWidget);
      expect(find.byKey(const Key('too_noisy_tap_entry_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('too_noisy_tap_entry_button')));
      await tester.pumpAndSettle();

      expect(find.byType(TooNoisyDialog), findsNothing);
      expect(tapEntrySelected, isTrue);
    });

    testWidgets('Test: low confidence triggers confirmation dialog before accepting', (tester) async {
      bool confirmationGiven = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  ConfidenceConfirmationDialog.show(
                    context,
                    spokenText: 'साँस तेज़',
                    canonicalValue: 'FAST_BREATHING',
                    confidence: 0.58, // Below 0.70 threshold
                    onConfirm: () {
                      confirmationGiven = true;
                    },
                  );
                },
                child: const Text('Simulate Low Confidence'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Simulate Low Confidence'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfidenceConfirmationDialog), findsOneWidget);
      expect(find.textContaining('58%'), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm_voice_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ConfidenceConfirmationDialog), findsNothing);
      expect(confirmationGiven, isTrue);
    });

    test('Test: TTS service falls back to synthesis when pre-recorded clip absent', () async {
      expect(tts.isClipAvailable('missing_clip_123', 'hi'), isFalse);

      final source = await tts.speak(
        text: 'Standard care follow-up',
        language: 'hi',
        clipId: 'missing_clip_123',
      );

      expect(source, equals(AudioSourceType.onDeviceSynthesis));
      expect(tts.lastAudioSource, equals(AudioSourceType.onDeviceSynthesis));
      expect(tts.lastSpokenText, equals('Standard care follow-up'));
    });
  });
}
