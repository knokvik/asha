import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/voice/too_noisy_dialog.dart';
import 'package:asha_platform/core/voice/vosk_service.dart';

void main() {
  group('VoskService RAM-Based Model Footprint Selection (Requirement 6.7)', () {
    test('Selects full 40 MB model when RAM >= 1500 MB', () {
      final service2gb = VoskService(deviceRamMb: 2048);
      expect(service2gb.recommendedModelType, VoskModelType.full);
      expect(service2gb.isTapOnlyFallback, isFalse);

      final serviceExact1500 = VoskService(deviceRamMb: 1500);
      expect(serviceExact1500.recommendedModelType, VoskModelType.full);
      expect(serviceExact1500.isTapOnlyFallback, isFalse);
    });

    test('Selects compressed 15 MB model when RAM is between 1000 MB and 1499 MB', () {
      final service1gb = VoskService(deviceRamMb: 1024);
      expect(service1gb.recommendedModelType, VoskModelType.compressed);
      expect(service1gb.isTapOnlyFallback, isFalse);

      final service1499 = VoskService(deviceRamMb: 1499);
      expect(service1499.recommendedModelType, VoskModelType.compressed);
      expect(service1499.isTapOnlyFallback, isFalse);
    });

    test('Falls back to tap-only entry when RAM < 1000 MB', () {
      final service512mb = VoskService(deviceRamMb: 512);
      expect(service512mb.recommendedModelType, VoskModelType.tapOnly);
      expect(service512mb.isTapOnlyFallback, isTrue);

      final service999mb = VoskService(deviceRamMb: 999);
      expect(service999mb.recommendedModelType, VoskModelType.tapOnly);
      expect(service999mb.isTapOnlyFallback, isTrue);
    });

    test('initModel returns false and does not initialize when device is in tap-only mode', () async {
      final service = VoskService(deviceRamMb: 800);
      final initialized = await service.initModel(language: 'hi');
      expect(initialized, isFalse);
      expect(service.isInitialized, isFalse);
    });
  });

  group('VoskGrammar Closed-Vocabulary Constraints (Requirement 6.2)', () {
    test('yesNo grammar includes English, Hindi, and regional terms plus [unk]', () {
      final grammar = VoskGrammar.yesNo();
      final words = grammar.toList();

      expect(words, contains('yes'));
      expect(words, contains('no'));
      expect(words, contains('हाँ'));
      expect(words, contains('नहीं'));
      expect(words, contains('haan'));
      expect(words, contains('nahi'));
      expect(words, contains('[unk]'));

      final jsonStr = grammar.toJsonString();
      final decoded = jsonDecode(jsonStr) as List;
      expect(decoded.length, words.length);
    });

    test('numeric grammar includes requested range, number words, and [unk]', () {
      final grammar = VoskGrammar.numeric(min: 0, max: 20);
      final words = grammar.toList();

      expect(words, contains('0'));
      expect(words, contains('20'));
      expect(words, contains('zero'));
      expect(words, contains('एक'));
      expect(words, contains('बीस'));
      expect(words, contains('[unk]'));
    });

    test('enumeration grammar includes custom options and [unk]', () {
      final grammar = VoskGrammar.enumeration(['mild', 'moderate', 'severe']);
      final words = grammar.toList();

      expect(words, contains('[unk]'));
      expect(words, contains('mild'));
      expect(words, contains('moderate'));
      expect(words, contains('severe'));
    });
  });

  group('VoskService Ambient Noise & Confidence Processing (Requirements 6.2, 6.5)', () {
    test('computeRms returns 0.0 for empty or silent PCM samples', () {
      expect(VoskService.computeRms(Int16List(0)), 0.0);

      final silence = Int16List(1600); // 100ms at 16kHz
      expect(VoskService.computeRms(silence), 0.0);
    });

    test('computeRms computes correct normalized RMS for non-zero PCM audio', () {
      // Create alternating half-scale signal: 16384 (0.5 normalized)
      final samples = Int16List.fromList([16384, -16384, 16384, -16384]);
      final rms = VoskService.computeRms(samples);
      expect(rms, closeTo(0.5, 0.01));
    });

    test('isNoiseExcessive triggers when RMS exceeds noiseThreshold', () {
      final service = VoskService(noiseThreshold: 0.65);
      expect(service.isNoiseExcessive(0.50), isFalse);
      expect(service.isNoiseExcessive(0.65), isFalse);
      expect(service.isNoiseExcessive(0.66), isTrue);
      expect(service.isNoiseExcessive(0.95), isTrue);
    });

    test('evaluateResult marks low confidence when score is below threshold', () {
      final service = VoskService(confidenceThreshold: 0.70);

      final lowRes = service.evaluateResult(
        transcript: 'fever',
        confidence: 0.55,
      );
      expect(lowRes.isLowConfidence, isTrue);
      expect(lowRes.isExcessiveNoise, isFalse);

      final highRes = service.evaluateResult(
        transcript: 'fever',
        confidence: 0.85,
      );
      expect(highRes.isLowConfidence, isFalse);
      expect(highRes.isExcessiveNoise, isFalse);
    });

    test('evaluateResult marks excessive noise and low confidence when RMS exceeds threshold', () {
      final service = VoskService(noiseThreshold: 0.65);

      final noisyRes = service.evaluateResult(
        transcript: 'cough',
        confidence: 0.90,
        rms: 0.80,
      );
      expect(noisyRes.isExcessiveNoise, isTrue);
      expect(noisyRes.isLowConfidence, isTrue);
    });

    test('dispose resets initialization flag', () async {
      final service = VoskService(deviceRamMb: 2048);
      await service.dispose();
      expect(service.isInitialized, isFalse);
    });
  });

  group('TooNoisyDialog Widget Tests (Requirement 6.5)', () {
    testWidgets('Renders noise alert message, retry button, and tap entry button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TooNoisyDialog(),
          ),
        ),
      );

      expect(find.text('High Background Noise'), findsOneWidget);
      expect(
        find.text('The ambient noise in your surroundings is too high for accurate voice recognition.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('too_noisy_retry_button')), findsOneWidget);
      expect(find.byKey(const Key('too_noisy_tap_entry_button')), findsOneWidget);
    });

    testWidgets('Tapping Use Tap Entry invokes callback and dismisses dialog with true', (tester) async {
      bool tapCallbackFired = false;
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await TooNoisyDialog.show(
                    context,
                    onTapEntry: () {
                      tapCallbackFired = true;
                    },
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(TooNoisyDialog), findsOneWidget);

      await tester.tap(find.byKey(const Key('too_noisy_tap_entry_button')));
      await tester.pumpAndSettle();

      expect(find.byType(TooNoisyDialog), findsNothing);
      expect(tapCallbackFired, isTrue);
      expect(dialogResult, isTrue);
    });

    testWidgets('Tapping Try Again invokes callback and dismisses dialog with false', (tester) async {
      bool retryCallbackFired = false;
      bool? dialogResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  dialogResult = await TooNoisyDialog.show(
                    context,
                    onRetry: () {
                      retryCallbackFired = true;
                    },
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('too_noisy_retry_button')));
      await tester.pumpAndSettle();

      expect(find.byType(TooNoisyDialog), findsNothing);
      expect(retryCallbackFired, isTrue);
      expect(dialogResult, isFalse);
    });

    testWidgets('Buttons meet WCAG AA minimum 48x48 dp touch target size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TooNoisyDialog(),
          ),
        ),
      );

      final retrySize = tester.getSize(find.byKey(const Key('too_noisy_retry_button')));
      final tapSize = tester.getSize(find.byKey(const Key('too_noisy_tap_entry_button')));

      expect(retrySize.height, greaterThanOrEqualTo(48.0));
      expect(retrySize.width, greaterThanOrEqualTo(48.0));
      expect(tapSize.height, greaterThanOrEqualTo(48.0));
      expect(tapSize.width, greaterThanOrEqualTo(48.0));
    });
  });
}
