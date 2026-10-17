import 'package:asha_platform/core/voice/confidence_confirmation_dialog.dart';
import 'package:asha_platform/core/voice/lexicon_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LexiconService lexicon;

  setUp(() {
    lexicon = LexiconService();
  });

  group('LexiconService Dialect Variant Mapping (Requirements 6.2, 6.6)', () {
    test('Maps Hindi dialect variants to standard canonical concepts', () {
      final breathing1 = lexicon.lookup('साँस तेज़', language: 'hi');
      expect(breathing1?.canonicalConcept, 'FAST_BREATHING');
      expect(breathing1?.confidenceBoost, 0.1);

      final breathing2 = lexicon.lookup('सांस फूलना', language: 'hi');
      expect(breathing2?.canonicalConcept, 'FAST_BREATHING');

      final breathing3 = lexicon.lookup('हाँफना', language: 'hi');
      expect(breathing3?.canonicalConcept, 'FAST_BREATHING');

      final jaundice = lexicon.lookup('पीलिया', language: 'hi');
      expect(jaundice?.canonicalConcept, 'JAUNDICE');

      final fever = lexicon.lookup('तेज बुखार', language: 'hi');
      expect(fever?.canonicalConcept, 'FEVER');

      final diarrhea = lexicon.lookup('पतले दस्त', language: 'hi');
      expect(diarrhea?.canonicalConcept, 'DIARRHEA');

      final convulsions = lexicon.lookup('झटके', language: 'hi');
      expect(convulsions?.canonicalConcept, 'CONVULSIONS');

      final chest = lexicon.lookup('छाती धंसना', language: 'hi');
      expect(chest?.canonicalConcept, 'CHEST_INDRAWING');
    });

    test('Maps English terms to canonical concepts', () {
      final breathing = lexicon.lookup('fast breathing', language: 'en');
      expect(breathing?.canonicalConcept, 'FAST_BREATHING');

      final fever = lexicon.lookup('high temperature', language: 'en');
      expect(fever?.canonicalConcept, 'FEVER');

      final yes = lexicon.lookup('correct', language: 'en');
      expect(yes?.canonicalConcept, 'YES');
      expect(yes?.fieldType, 'boolean');

      final no = lexicon.lookup('nope', language: 'en');
      expect(no?.canonicalConcept, 'NO');
    });

    test('Maps registered Marathi bundle terms to canonical concepts', () {
      lexicon.registerBundle(
        const LexiconBundle(
          language: 'mr',
          version: '1.0',
          entries: [
            LexiconEntry(
              spokenVariants: ['श्वास जलद', 'दम लागणे'],
              canonicalConcept: 'FAST_BREATHING',
              confidenceBoost: 0.1,
            ),
            LexiconEntry(
              spokenVariants: ['कावीळ', 'डोळे पिवळे'],
              canonicalConcept: 'JAUNDICE',
            ),
            LexiconEntry(
              spokenVariants: ['होय', 'हो'],
              canonicalConcept: 'YES',
              fieldType: 'boolean',
            ),
          ],
        ),
      );

      expect(lexicon.lookup('श्वास जलद', language: 'mr')?.canonicalConcept, 'FAST_BREATHING');
      expect(lexicon.lookup('दम लागणे', language: 'mr')?.canonicalConcept, 'FAST_BREATHING');
      expect(lexicon.lookup('कावीळ', language: 'mr')?.canonicalConcept, 'JAUNDICE');
      expect(lexicon.lookup('होय', language: 'mr')?.canonicalConcept, 'YES');
    });

    test('Applies confidence boost correctly', () {
      final result = lexicon.lookup('साँस तेज़', language: 'hi', rawConfidence: 0.65);
      expect(result, isNotNull);
      // Raw 0.65 + boost 0.10 = 0.75
      expect(result!.adjustedConfidence, closeTo(0.75, 0.001));
    });
  });

  group('Property 13: Idempotence of canonicalise (Requirement 6.2, Design 2.5)', () {
    test('canonicalise(canonicalise(term)) == canonicalise(term) for colloquial variants', () {
      final testVariants = [
        'साँस तेज़',
        'सांस फूलना',
        'पीलिया',
        'तेज बुखार',
        'दस्त',
        'fast breathing',
        'high temperature',
        'chest indrawing',
        'thirty',
        'तीस',
        'yes',
        'हाँ',
        'nahi',
      ];

      for (final term in testVariants) {
        final once = lexicon.canonicalise(term, language: 'hi');
        final twice = lexicon.canonicalise(once, language: 'hi');
        expect(twice, equals(once),
            reason: 'Idempotence violated for input variant "$term": $twice != $once');
      }
    });

    test('canonicalise is identity for already-canonical concepts', () {
      final canonicalConcepts = [
        'FAST_BREATHING',
        'JAUNDICE',
        'FEVER',
        'DIARRHEA',
        'ANEMIA',
        'MALNUTRITION',
        'CONVULSIONS',
        'CHEST_INDRAWING',
        'VOMITING',
        'YES',
        'NO',
        '30',
      ];

      for (final concept in canonicalConcepts) {
        final result = lexicon.canonicalise(concept);
        expect(result, equals(concept),
            reason: 'Canonical concept "$concept" should map to itself');
        expect(lexicon.canonicalise(result), equals(concept));
      }
    });

    test('canonicalise is idempotent for unmapped / arbitrary strings', () {
      final arbitraryStrings = [
        'unknown symptom xyz',
        '123 random',
        '',
        'कुछ नया लक्षण',
      ];

      for (final term in arbitraryStrings) {
        final once = lexicon.canonicalise(term);
        final twice = lexicon.canonicalise(once);
        expect(twice, equals(once),
            reason: 'Idempotence failed for arbitrary term "$term"');
      }
    });
  });

  group('Confidence-Threshold Check (Requirement 6.3)', () {
    test('requiresConfirmation returns true when confidence is below 0.70', () {
      expect(lexicon.requiresConfirmation(confidence: 0.0), isTrue);
      expect(lexicon.requiresConfirmation(confidence: 0.50), isTrue);
      expect(lexicon.requiresConfirmation(confidence: 0.69), isTrue);
      expect(lexicon.requiresConfirmation(confidence: 0.699), isTrue);
    });

    test('requiresConfirmation returns false when confidence is >= 0.70', () {
      expect(lexicon.requiresConfirmation(confidence: 0.70), isFalse);
      expect(lexicon.requiresConfirmation(confidence: 0.85), isFalse);
      expect(lexicon.requiresConfirmation(confidence: 1.0), isFalse);
    });
  });

  group('ConfidenceConfirmationDialog Widget Tests (Requirement 6.3)', () {
    testWidgets('Renders spoken text, detected canonical value, and confidence percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfidenceConfirmationDialog(
              spokenText: 'साँस तेज़',
              canonicalValue: 'FAST_BREATHING',
              confidence: 0.58,
            ),
          ),
        ),
      );

      expect(find.text('Confirm Voice Input'), findsOneWidget);
      expect(find.text('साँस तेज़'), findsOneWidget);
      expect(find.text('FAST_BREATHING'), findsOneWidget);
      expect(find.textContaining('58%'), findsOneWidget);
      expect(find.byKey(const Key('confirm_voice_button')), findsOneWidget);
      expect(find.byKey(const Key('reject_voice_button')), findsOneWidget);
    });

    testWidgets('Auto-triggers audio readback callback on presentation', (tester) async {
      int audioPlayCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConfidenceConfirmationDialog(
              spokenText: 'fever',
              canonicalValue: 'FEVER',
              confidence: 0.62,
              onPlayAudio: () async {
                audioPlayCount++;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(audioPlayCount, equals(1));
    });

    testWidgets('Tapping Confirm invokes onConfirm and pops dialog with true', (tester) async {
      bool confirmFired = false;
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ConfidenceConfirmationDialog.show(
                    context,
                    spokenText: 'पीलिया',
                    canonicalValue: 'JAUNDICE',
                    confidence: 0.60,
                    onConfirm: () {
                      confirmFired = true;
                    },
                  );
                },
                child: const Text('Launch'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfidenceConfirmationDialog), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirm_voice_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ConfidenceConfirmationDialog), findsNothing);
      expect(confirmFired, isTrue);
      expect(result, isTrue);
    });

    testWidgets('Tapping Reject invokes onReject and pops dialog with false', (tester) async {
      bool rejectFired = false;
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await ConfidenceConfirmationDialog.show(
                    context,
                    spokenText: 'wrong',
                    canonicalValue: 'UNKNOWN',
                    confidence: 0.40,
                    onReject: () {
                      rejectFired = true;
                    },
                  );
                },
                child: const Text('Launch'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('reject_voice_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ConfidenceConfirmationDialog), findsNothing);
      expect(rejectFired, isTrue);
      expect(result, isFalse);
    });

    testWidgets('Action buttons satisfy WCAG AA minimum 48x48 dp touch target', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfidenceConfirmationDialog(
              spokenText: 'test',
              canonicalValue: 'TEST',
              confidence: 0.50,
            ),
          ),
        ),
      );

      final confirmSize = tester.getSize(find.byKey(const Key('confirm_voice_button')));
      final rejectSize = tester.getSize(find.byKey(const Key('reject_voice_button')));

      expect(confirmSize.height, greaterThanOrEqualTo(48.0));
      expect(confirmSize.width, greaterThanOrEqualTo(48.0));
      expect(rejectSize.height, greaterThanOrEqualTo(48.0));
      expect(rejectSize.width, greaterThanOrEqualTo(48.0));
    });
  });
}
