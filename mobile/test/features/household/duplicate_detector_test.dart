import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/features/household/domain/duplicate_detector.dart';

void main() {
  group('DuplicateDetector - Phonetic Soundex', () {
    test('soundex generates 4-character code for names', () {
      final code1 = DuplicateDetector.soundex('Sunita');
      final code2 = DuplicateDetector.soundex('Sunil');
      final code3 = DuplicateDetector.soundex('Rajesh');

      expect(code1.length, equals(4));
      expect(code2.length, equals(4));
      expect(code3.length, equals(4));
      expect(code1[0], equals('S'));
      expect(code3[0], equals('R'));
    });

    test('soundex matches Indian English transliteration variants', () {
      // Pooja vs Puja (oo -> u)
      expect(
        DuplicateDetector.soundex('Pooja'),
        equals(DuplicateDetector.soundex('Puja')),
      );

      // Vikas vs Wikas (v -> w)
      expect(
        DuplicateDetector.soundex('Vikas'),
        equals(DuplicateDetector.soundex('Wikas')),
      );

      // Sharma vs Sarma (sh -> s)
      expect(
        DuplicateDetector.soundex('Sharma'),
        equals(DuplicateDetector.soundex('Sarma')),
      );

      // Fatima vs Phathima (ph -> f, th -> t)
      expect(
        DuplicateDetector.soundex('Fatima'),
        equals(DuplicateDetector.soundex('Phathima')),
      );
    });

    test('soundex returns 0000 for empty or non-alphabetic string', () {
      expect(DuplicateDetector.soundex(''), equals('0000'));
      expect(DuplicateDetector.soundex('12345'), equals('0000'));
    });
  });

  group('DuplicateDetector - Levenshtein Distance & Similarity', () {
    test('computes exact distance for standard operations', () {
      expect(DuplicateDetector.levenshteinDistance('kitten', 'sitting'), equals(3));
      expect(DuplicateDetector.levenshteinDistance('same', 'same'), equals(0));
      expect(DuplicateDetector.levenshteinDistance('', 'test'), equals(4));
      expect(DuplicateDetector.levenshteinDistance('test', ''), equals(4));
    });

    test('computes normalised similarity between 0.0 and 1.0', () {
      expect(DuplicateDetector.levenshteinSimilarity('Anita', 'Anita'), equals(1.0));
      expect(DuplicateDetector.levenshteinSimilarity('', ''), equals(1.0));
      expect(DuplicateDetector.levenshteinSimilarity('Anita', ''), equals(0.0));

      final sim = DuplicateDetector.levenshteinSimilarity('Sunita', 'Sunitha');
      expect(sim, greaterThan(0.8));
    });
  });

  group('DuplicateDetector - Multi-Field Scoring & Candidate Filtering', () {
    const detector = DuplicateDetector(threshold: 0.75);

    test('identical name, DOB, and household scores >= 0.85 (Property 9 invariant)', () {
      final now = DateTime.now().millisecondsSinceEpoch;

      final scoreWithMatchingPhone = detector.computeMatchScore(
        name1: 'Ramesh Yadav',
        name2: 'Ramesh Yadav',
        dobApprox1: now,
        dobApprox2: now,
        householdId1: 'hh-001',
        householdId2: 'hh-001',
        phone1: '9876543210',
        phone2: '9876543210',
      );
      expect(scoreWithMatchingPhone, equals(1.0));

      // With missing phone, score is 0.925
      final scoreWithMissingPhone = detector.computeMatchScore(
        name1: 'Ramesh Yadav',
        name2: 'Ramesh Yadav',
        dobApprox1: now,
        dobApprox2: now,
        householdId1: 'hh-001',
        householdId2: 'hh-001',
      );
      expect(scoreWithMissingPhone, closeTo(0.925, 1e-6));

      // Even with completely mismatched phone, score is 0.85 >= 0.75 threshold
      final scoreWithMismatchedPhone = detector.computeMatchScore(
        name1: 'Ramesh Yadav',
        name2: 'Ramesh Yadav',
        dobApprox1: now,
        dobApprox2: now,
        householdId1: 'hh-001',
        householdId2: 'hh-001',
        phone1: '9876543210',
        phone2: '9111111111',
      );
      expect(scoreWithMismatchedPhone, closeTo(0.85, 1e-6));
      expect(scoreWithMismatchedPhone, greaterThanOrEqualTo(detector.threshold));
    });

    test('filters and orders duplicate candidates above threshold', () {
      const existing1 = Member(
        id: 'm1',
        householdId: 'hh-001',
        name: 'Sunita Devi',
        sex: 'F',
        isDobApprox: false,
        lifecycleStatus: 'active',
        consentStatus: 'granted',
        phone: '9876543210',
        createdAt: 1000,
        updatedAt: 1000,
        createdBy: 'user',
        syncStatus: 'pending',
        serverVersion: 1,
      );

      const existing2 = Member(
        id: 'm2',
        householdId: 'hh-002',
        name: 'Anita Devi',
        sex: 'F',
        isDobApprox: false,
        lifecycleStatus: 'active',
        consentStatus: 'granted',
        createdAt: 1000,
        updatedAt: 1000,
        createdBy: 'user',
        syncStatus: 'pending',
        serverVersion: 1,
      );

      const existing3 = Member(
        id: 'm3',
        householdId: 'hh-003',
        name: 'Vikram Singh',
        sex: 'M',
        isDobApprox: false,
        lifecycleStatus: 'active',
        consentStatus: 'granted',
        createdAt: 1000,
        updatedAt: 1000,
        createdBy: 'user',
        syncStatus: 'pending',
        serverVersion: 1,
      );

      final matches = detector.filterDuplicates(
        existingMembers: [existing1, existing2, existing3],
        targetName: 'Suneeta Devi',
        targetHouseholdId: 'hh-001',
        targetPhone: '9876543210',
      );

      expect(matches.isNotEmpty, isTrue);
      expect(matches.first.existingMember.id, equals('m1'));
      expect(matches.first.score, greaterThanOrEqualTo(0.75));
      expect(matches.any((c) => c.existingMember.id == 'm3'), isFalse);
    });
  });

  group('DuplicateConfirmationDialog', () {
    testWidgets('renders match details and returns user resolution', (tester) async {
      const candidateMember = Member(
        id: 'm1',
        householdId: 'hh-001',
        name: 'Aarti Kumari',
        sex: 'F',
        isDobApprox: false,
        lifecycleStatus: 'active',
        consentStatus: 'granted',
        phone: '9812345678',
        relationshipToHead: 'Daughter',
        createdAt: 1000,
        updatedAt: 1000,
        createdBy: 'user',
        syncStatus: 'pending',
        serverVersion: 1,
      );

      const candidate = DuplicateCandidate(
        existingMember: candidateMember,
        score: 0.92,
        nameScore: 1.0,
        dobScore: 1.0,
        householdScore: 1.0,
        phoneScore: 0.5,
      );

      DuplicateResolution? selectedResolution;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                selectedResolution = await showDialog<DuplicateResolution>(
                  context: context,
                  builder: (_) => const DuplicateConfirmationDialog(
                    candidates: [candidate],
                  ),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Potential Duplicate Found'), findsOneWidget);
      expect(find.text('Aarti Kumari'), findsOneWidget);
      expect(find.textContaining('92% match'), findsOneWidget);

      // Tap Merge / Link
      final mergeButton = find.byKey(const Key('duplicate_dialog_merge_button'));
      expect(mergeButton, findsOneWidget);
      await tester.tap(mergeButton);
      await tester.pumpAndSettle();

      expect(selectedResolution, equals(DuplicateResolution.merge));
    });
  });
}
