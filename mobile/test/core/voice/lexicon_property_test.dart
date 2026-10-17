import 'dart:math';

import 'package:asha_platform/core/l10n/language_provider.dart';
import 'package:asha_platform/core/voice/lexicon_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task 4.8: Property 13 — Lexicon Normalisation Idempotence (Requirements 6.2, 6.6)', () {
    late LexiconService lexicon;

    setUp(() {
      lexicon = LexiconService();
    });

    test('Property 13 Invariant: normalise(normalise(term)) == normalise(term) across all 12 languages', () {
      final supportedCodes = supportedLanguages.map((l) => l.code).toList();
      final random = Random(42);

      // Diverse sample vocabulary: clinical terms, variants, noise, punctuation, mixed script
      final testInputs = <String>[
        'साँस तेज़',
        'सांस फूलना',
        'हाँफना',
        'पीलिया',
        'बुखार',
        'दस्त',
        'खून की कमी',
        'कुपोषण',
        'झटके',
        'छाती धंसना',
        'उल्टी',
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
        'fast breathing',
        'high temperature',
        'yellow eyes',
        'cough',
        '100',
        '0',
        '',
        '   ',
        'Random! Unmapped? String...',
        '123abcXYZ',
        '--special-chars--',
        'श्वास जलद',
        'कावीळ',
      ];

      // Add 100 generated arbitrary string permutations
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789 !?.,-;:हाँनहींपीलियातीस';
      for (int i = 0; i < 100; i++) {
        final length = random.nextInt(25) + 1;
        final buffer = StringBuffer();
        for (int j = 0; j < length; j++) {
          buffer.write(chars[random.nextInt(chars.length)]);
        }
        testInputs.add(buffer.toString());
      }

      for (final lang in supportedCodes) {
        for (final input in testInputs) {
          final firstApplication = lexicon.canonicalise(input, language: lang);
          final secondApplication = lexicon.canonicalise(firstApplication, language: lang);

          expect(
            secondApplication,
            equals(firstApplication),
            reason:
                'Property 13 (Idempotence) violated for language "$lang" and input "$input": '
                'first="$firstApplication", second="$secondApplication"',
          );
        }
      }
    });

    test('Property 13: Identity invariant on canonical concepts', () {
      const canonicalSet = [
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

      for (final concept in canonicalSet) {
        final mapped = lexicon.canonicalise(concept);
        expect(mapped, equals(concept));
        expect(lexicon.canonicalise(mapped), equals(concept));
      }
    });
  });
}
