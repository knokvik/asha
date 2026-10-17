import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/features/household/domain/duplicate_detector.dart';

void main() {
  group('Task 5.10: Property 9 — Duplicate Beneficiary Detection Invariant (Requirements 4.3)', () {
    const detector = DuplicateDetector(threshold: 0.75);
    final random = Random(42);

    test('Property 9 Invariant: Any two records with identical name, DOB, and household exceed threshold regardless of comparison order', () {
      final sampleNames = <String>[
        'Sunita Devi',
        'Rameshwar Yadav',
        'Aarti Kumari',
        'Pooja Sharma',
        'Mohd Imran',
        'Fatima Begum',
        'Kavita Patel',
        'Deepak Verma',
        'सुनीता देवी',
        'रामेश्वर यादव',
        'आरती कुमारी',
        'पूजा शर्मा',
        'कविता पटेल',
      ];

      // Generate 200 random permutations
      for (int i = 0; i < 200; i++) {
        // Pick base name or generate random name
        final baseName = sampleNames[random.nextInt(sampleNames.length)];
        // Add random surrounding spaces or case variations to test normalisation
        final name1 = '  ${baseName.trim()}  ';
        final name2 = baseName.trim();

        // Identical DOB/age
        final dob = DateTime(1960 + random.nextInt(60), random.nextInt(12) + 1, random.nextInt(28) + 1)
            .millisecondsSinceEpoch;

        // Identical household identifier
        final householdId = 'hh-${random.nextInt(10000)}';

        // Varied phone conditions: matching, mismatched, or missing
        final phoneMode = random.nextInt(3);
        String? phone1;
        String? phone2;
        if (phoneMode == 0) {
          // Matching phone
          phone1 = '98${random.nextInt(90000000) + 10000000}';
          phone2 = phone1;
        } else if (phoneMode == 1) {
          // Mismatched phone
          phone1 = '98${random.nextInt(90000000) + 10000000}';
          phone2 = '97${random.nextInt(90000000) + 10000000}';
        } else {
          // Missing phone in one or both
          phone1 = null;
          phone2 = random.nextBool() ? '9812345678' : null;
        }

        // 1. Evaluate forward: (record1, record2)
        final forwardScore = detector.computeMatchScore(
          name1: name1,
          name2: name2,
          dobApprox1: dob,
          dobApprox2: dob,
          householdId1: householdId,
          householdId2: householdId,
          phone1: phone1,
          phone2: phone2,
        );

        // 2. Evaluate reverse: (record2, record1) to verify commutativity / order independence
        final reverseScore = detector.computeMatchScore(
          name1: name2,
          name2: name1,
          dobApprox1: dob,
          dobApprox2: dob,
          householdId1: householdId,
          householdId2: householdId,
          phone1: phone2,
          phone2: phone1,
        );

        // Assert Property 9 Invariant:
        // Must score above threshold (>= 0.75)
        expect(
          forwardScore,
          greaterThanOrEqualTo(detector.threshold),
          reason: 'Property 9 Invariant violated for identical name="$baseName", dob=$dob, hh=$householdId (phoneMode=$phoneMode)',
        );

        expect(
          reverseScore,
          greaterThanOrEqualTo(detector.threshold),
          reason: 'Property 9 Invariant violated in reverse order for name="$baseName", dob=$dob, hh=$householdId',
        );

        // Assert Order Independence / Commutativity
        expect(
          (forwardScore - reverseScore).abs(),
          lessThan(1e-6),
          reason: 'Comparison order must be symmetric for name="$baseName"',
        );
      }
    });
  });
}
