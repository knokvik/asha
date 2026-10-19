import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/database/app_database.dart';

/// Represents a potential duplicate beneficiary match with similarity scoring.
class DuplicateCandidate {
  final Member existingMember;
  final double score;
  final double nameScore;
  final double dobScore;
  final double householdScore;
  final double phoneScore;

  const DuplicateCandidate({
    required this.existingMember,
    required this.score,
    required this.nameScore,
    required this.dobScore,
    required this.householdScore,
    required this.phoneScore,
  });

  int get matchPercentage => (score * 100).round();
}

/// User's resolution choice when a potential duplicate is detected.
enum DuplicateResolution {
  /// Merge / link with the existing beneficiary record.
  merge,

  /// Confirmed as a distinct individual; proceed saving.
  continueAnyway,

  /// Abort and return to form for corrections.
  cancel,
}

/// Service performing phonetic and fuzzy duplicate detection on beneficiary records.
///
/// Features:
/// - Levenshtein edit distance with length normalisation.
/// - Phonetic Soundex normalisation adapted for regional/Indian names.
/// - Multi-field weighted scoring (Name 40%, DOB/Age 25%, Household 20%, Phone 15%).
/// - Configurable match threshold (default: 0.75).
/// - Mathematical guarantee for Property 9 (Duplicate Beneficiary Detection Invariant):
///   Any two records with matching name, DOB/approx age, and household score >= 0.85,
///   strictly exceeding the 0.75 threshold regardless of comparison order.
///
/// Requirements: 4.3
class DuplicateDetector {
  final double threshold;

  // Weight constants (sum = 1.0)
  static const double wName = 0.40;
  static const double wDob = 0.25;
  static const double wHousehold = 0.20;
  static const double wPhone = 0.15;

  const DuplicateDetector({this.threshold = 0.75});

  // ── Phonetic Soundex Normalisation ────────────────────────────────────────

  /// Generates a 4-character phonetic Soundex code for [input].
  ///
  /// Adapted with Indian English transliteration mappings (e.g. V/W, PH/F, SH/S).
  static String soundex(String input) {
    final cleaned = _preNormalizePhonetic(input);
    if (cleaned.isEmpty) return '0000';

    final firstChar = cleaned[0].toUpperCase();
    final buffer = StringBuffer(firstChar);

    String? prevCode = _soundexChar(firstChar);

    for (int i = 1; i < cleaned.length; i++) {
      final code = _soundexChar(cleaned[i]);
      if (code != '0' && code != prevCode) {
        buffer.write(code);
        prevCode = code;
        if (buffer.length == 4) break;
      } else if (code == '0') {
        prevCode = null; // Vowels separate identical consonants
      }
    }

    final result = buffer.toString();
    return result.padRight(4, '0').substring(0, 4);
  }

  /// Generates space-separated Soundex codes for each word in [input].
  static String soundexWords(String input) {
    final words = input.trim().split(RegExp(r'\s+'));
    final codes = words
        .map(soundex)
        .where((code) => code != '0000')
        .toSet()
        .toList();
    if (codes.isEmpty) return '0000';
    return codes.join(' ');
  }

  static String _preNormalizePhonetic(String text) {
    var s = text.trim().toLowerCase();
    // Common Indian transliteration normalisations
    s = s.replaceAll('sh', 's');
    s = s.replaceAll('ph', 'f');
    s = s.replaceAll('ee', 'i');
    s = s.replaceAll('oo', 'u');
    s = s.replaceAll('gh', 'g');
    s = s.replaceAll('dh', 'd');
    s = s.replaceAll('th', 't');
    s = s.replaceAll('ch', 'c');
    s = s.replaceAll('w', 'v');
    // Keep only alphabetical characters
    return s.replaceAll(RegExp(r'[^a-zA-Z]'), '');
  }

  static String _soundexChar(String c) {
    switch (c.toUpperCase()) {
      case 'B':
      case 'F':
      case 'P':
      case 'V':
        return '1';
      case 'C':
      case 'G':
      case 'J':
      case 'K':
      case 'Q':
      case 'S':
      case 'X':
      case 'Z':
        return '2';
      case 'D':
      case 'T':
        return '3';
      case 'L':
        return '4';
      case 'M':
      case 'N':
        return '5';
      case 'R':
        return '6';
      default:
        return '0';
    }
  }

  // ── Levenshtein Distance & Similarity ─────────────────────────────────────

  /// Computes Levenshtein edit distance between [s1] and [s2].
  static int levenshteinDistance(String s1, String s2) {
    final a = s1.toLowerCase().trim();
    final b = s2.toLowerCase().trim();

    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> v0 = List<int>.generate(b.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final cost = a[i] == b[j] ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }
      for (int j = 0; j <= b.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[b.length];
  }

  /// Normalised Levenshtein similarity in range [0.0, 1.0].
  static double levenshteinSimilarity(String s1, String s2) {
    final a = s1.trim().toLowerCase();
    final b = s2.trim().toLowerCase();
    if (a.isEmpty && b.isEmpty) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;
    if (a == b) return 1.0;

    final distance = levenshteinDistance(a, b);
    final maxLen = max(a.length, b.length);
    return max(0.0, 1.0 - (distance / maxLen));
  }

  // ── Field Scoring ─────────────────────────────────────────────────────────

  /// Computes fuzzy name similarity combining exact equality, Levenshtein, and Soundex.
  double computeNameScore(String name1, String name2) {
    final n1 = name1.trim().toLowerCase();
    final n2 = name2.trim().toLowerCase();

    if (n1 == n2) return 1.0;
    if (n1.isEmpty || n2.isEmpty) return 0.0;

    final lev = levenshteinSimilarity(n1, n2);
    final sndx1 = soundex(n1);
    final sndx2 = soundex(n2);

    final sndxWords1 = soundexWords(n1).split(' ').toSet();
    final sndxWords2 = soundexWords(n2).split(' ').toSet();
    final hasSharedWordSoundex =
        sndxWords1.intersection(sndxWords2).any((c) => c != '0000');

    if ((sndx1 == sndx2 && sndx1 != '0000') || hasSharedWordSoundex) {
      return max(0.85, lev);
    }

    return lev;
  }

  /// Computes DOB / age similarity.
  double computeDobScore({
    int? dobApprox1,
    int? dobApprox2,
    bool isApprox1 = false,
    bool isApprox2 = false,
  }) {
    if (dobApprox1 == null || dobApprox2 == null) {
      // Neutral if either is missing
      return 0.50;
    }

    final diffMs = (dobApprox1 - dobApprox2).abs();
    final diffDays = diffMs / (1000 * 60 * 60 * 24);

    if (diffDays <= 30) {
      return 1.0;
    } else if (diffDays <= 365) {
      return 0.85;
    } else if (diffDays <= 730) {
      return 0.65;
    } else if (diffDays <= 1095) {
      return 0.45;
    } else {
      return 0.0;
    }
  }

  /// Computes household match score.
  double computeHouseholdScore(String? householdId1, String? householdId2) {
    if (householdId1 == null || householdId2 == null) {
      return 0.50;
    }
    return householdId1 == householdId2 ? 1.0 : 0.0;
  }

  /// Computes phone match score.
  double computePhoneScore(String? phone1, String? phone2) {
    final p1 = _normalizePhone(phone1);
    final p2 = _normalizePhone(phone2);

    if (p1 == null || p2 == null) {
      // Missing phone: neutral score
      return 0.50;
    }

    return p1 == p2 ? 1.0 : 0.0;
  }

  static String? _normalizePhone(String? phone) {
    if (phone == null) return null;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return null;
    return digits.substring(digits.length - 10);
  }

  // ── Aggregate Score ───────────────────────────────────────────────────────

  /// Computes the overall match score between target and candidate beneficiary.
  ///
  /// Mathematical guarantee:
  /// Identical (name, DOB, household) yields score >= 0.85, guaranteeing
  /// score >= [threshold] (0.75) for Property 9 Invariant.
  double computeMatchScore({
    required String name1,
    required String name2,
    int? dobApprox1,
    int? dobApprox2,
    String? householdId1,
    String? householdId2,
    String? phone1,
    String? phone2,
  }) {
    final nameScore = computeNameScore(name1, name2);
    final dobScore = computeDobScore(dobApprox1: dobApprox1, dobApprox2: dobApprox2);
    final householdScore = computeHouseholdScore(householdId1, householdId2);
    final phoneScore = computePhoneScore(phone1, phone2);

    return (nameScore * wName) +
        (dobScore * wDob) +
        (householdScore * wHousehold) +
        (phoneScore * wPhone);
  }

  /// Checks candidate [existingMember] against target beneficiary parameters.
  DuplicateCandidate evaluateCandidate({
    required Member existingMember,
    required String targetName,
    int? targetDobApprox,
    String? targetHouseholdId,
    String? targetPhone,
  }) {
    final nameScore = computeNameScore(targetName, existingMember.name);
    final dobScore = computeDobScore(
      dobApprox1: targetDobApprox,
      dobApprox2: existingMember.dobApprox,
    );
    final householdScore = computeHouseholdScore(
      targetHouseholdId,
      existingMember.householdId,
    );
    final phoneScore = computePhoneScore(targetPhone, existingMember.phone);

    final score = (nameScore * wName) +
        (dobScore * wDob) +
        (householdScore * wHousehold) +
        (phoneScore * wPhone);

    return DuplicateCandidate(
      existingMember: existingMember,
      score: score,
      nameScore: nameScore,
      dobScore: dobScore,
      householdScore: householdScore,
      phoneScore: phoneScore,
    );
  }

  /// Filters and orders all candidates matching above [threshold].
  List<DuplicateCandidate> filterDuplicates({
    required List<Member> existingMembers,
    required String targetName,
    int? targetDobApprox,
    String? targetHouseholdId,
    String? targetPhone,
  }) {
    final matches = <DuplicateCandidate>[];

    for (final member in existingMembers) {
      final candidate = evaluateCandidate(
        existingMember: member,
        targetName: targetName,
        targetDobApprox: targetDobApprox,
        targetHouseholdId: targetHouseholdId,
        targetPhone: targetPhone,
      );

      if (candidate.score >= threshold) {
        matches.add(candidate);
      }
    }

    matches.sort((a, b) => b.score.compareTo(a.score));
    return matches;
  }
}

/// Dialog prompting the user to resolve potential duplicate beneficiaries.
///
/// Presents merge/link, continue anyway, or cancel options.
/// Requirements: 4.3
class DuplicateConfirmationDialog extends StatelessWidget {
  final List<DuplicateCandidate> candidates;

  const DuplicateConfirmationDialog({
    super.key,
    required this.candidates,
  });

  @override
  Widget build(BuildContext context) {
    final topCandidate = candidates.first;
    final member = topCandidate.existingMember;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Potential Duplicate Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A beneficiary with similar details already exists in the local registry (${topCandidate.matchPercentage}% match):',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (member.sex.isNotEmpty)
                    Text('Sex: ${member.sex} • Relationship: ${member.relationshipToHead ?? "N/A"}'),
                  if (member.phone != null && member.phone!.isNotEmpty)
                    Text('Phone: ${member.phone}'),
                  if (member.abhaId != null && member.abhaId!.isNotEmpty)
                    Text('ABHA: ${member.abhaId}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Would you like to link to this existing record or continue creating a new beneficiary?',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const Key('duplicate_dialog_cancel_button'),
          onPressed: () => Navigator.of(context).pop(DuplicateResolution.cancel),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          key: const Key('duplicate_dialog_continue_button'),
          onPressed: () => Navigator.of(context).pop(DuplicateResolution.continueAnyway),
          child: const Text('Create New Anyway'),
        ),
        ElevatedButton(
          key: const Key('duplicate_dialog_merge_button'),
          onPressed: () => Navigator.of(context).pop(DuplicateResolution.merge),
          child: const Text('Link / Merge'),
        ),
      ],
    );
  }
}
