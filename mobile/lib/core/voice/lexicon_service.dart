import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single mapping rule inside a Lexicon bundle.
///
/// Maps colloquial and dialect spoken variants to a standardized clinical concept.
/// Requirements: 6.2, 6.6
class LexiconEntry {
  final List<String> spokenVariants;
  final String canonicalConcept;
  final String fieldType;
  final double confidenceBoost;
  final String? outputTransform;

  const LexiconEntry({
    required this.spokenVariants,
    required this.canonicalConcept,
    this.fieldType = 'symptom_flag',
    this.confidenceBoost = 0.0,
    this.outputTransform,
  });

  factory LexiconEntry.fromJson(Map<String, dynamic> json) {
    final rawVariants = json['spoken_variants'] as List<dynamic>? ?? [];
    return LexiconEntry(
      spokenVariants: rawVariants.map((e) => e.toString().trim()).toList(),
      canonicalConcept: json['canonical_concept'] as String? ?? '',
      fieldType: json['field_type'] as String? ?? 'symptom_flag',
      confidenceBoost: (json['confidence_boost'] as num?)?.toDouble() ?? 0.0,
      outputTransform: json['output_transform'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'spoken_variants': spokenVariants,
        'canonical_concept': canonicalConcept,
        'field_type': fieldType,
        'confidence_boost': confidenceBoost,
        if (outputTransform != null) 'output_transform': outputTransform,
      };
}

/// Collection of lexicon entries for a specific regional language.
class LexiconBundle {
  final String language;
  final String version;
  final List<LexiconEntry> entries;

  const LexiconBundle({
    required this.language,
    required this.version,
    required this.entries,
  });

  factory LexiconBundle.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? [];
    return LexiconBundle(
      language: json['language'] as String? ?? 'en',
      version: json['version'] as String? ?? '1.0',
      entries: rawEntries
          .map((e) => LexiconEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Result of looking up a spoken variant in the Lexicon.
class LexiconLookupResult {
  final String canonicalConcept;
  final String matchedVariant;
  final String fieldType;
  final double confidenceBoost;
  final double adjustedConfidence;
  final String? outputTransform;

  const LexiconLookupResult({
    required this.canonicalConcept,
    required this.matchedVariant,
    this.fieldType = 'symptom_flag',
    this.confidenceBoost = 0.0,
    this.adjustedConfidence = 0.0,
    this.outputTransform,
  });
}

/// Normalizes colloquial & dialect symptom terms into standardized clinical concepts.
///
/// Implements Property 13 (Idempotence):
/// `canonicalise(canonicalise(term)) == canonicalise(term)`.
/// Requirements: 6.2, 6.3, 6.6
class LexiconService {
  final Map<String, Map<String, LexiconEntry>> _variantMapByLang = {};
  final Set<String> _knownCanonicalConcepts = {};

  LexiconService() {
    _registerEmbeddedDefaults();
  }

  /// Registers a bundle in-memory (e.g., from assets, OTA sync, or unit tests).
  void registerBundle(LexiconBundle bundle) {
    final lang = bundle.language.toLowerCase();
    final langMap = _variantMapByLang.putIfAbsent(lang, () => {});

    for (final entry in bundle.entries) {
      final canonical = entry.canonicalConcept.trim();
      _knownCanonicalConcepts.add(canonical.toUpperCase());

      // Map canonical concept to itself for identity lookup
      langMap[canonical.toLowerCase()] = entry;

      for (final variant in entry.spokenVariants) {
        final normalizedVariant = _normalizeString(variant);
        langMap[normalizedVariant] = entry;
      }
    }
  }

  /// Loads a language bundle from assets JSON (`assets/lexicon/lexicon_<lang>.json`).
  Future<bool> loadLanguage(String language, {AssetBundle? bundle}) async {
    final assetBundle = bundle ?? rootBundle;
    final path = 'assets/lexicon/lexicon_${language.toLowerCase()}.json';

    try {
      final jsonString = await assetBundle.loadString(path);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final lexiconBundle = LexiconBundle.fromJson(decoded);
      registerBundle(lexiconBundle);
      return true;
    } catch (_) {
      // In headless test environments or if asset is missing, embedded defaults remain
      return false;
    }
  }

  /// Looks up a spoken term in the lexicon for [language].
  ///
  /// Falls back to English ('en') if not found in the primary language.
  LexiconLookupResult? lookup(
    String spokenTerm, {
    String language = 'en',
    double rawConfidence = 1.0,
  }) {
    final normalized = _normalizeString(spokenTerm);
    if (normalized.isEmpty) return null;

    final lang = language.toLowerCase();
    LexiconEntry? entry = _variantMapByLang[lang]?[normalized];

    // Fall back to English or other loaded languages if not found
    if (entry == null && lang != 'en') {
      entry = _variantMapByLang['en']?[normalized];
    }

    if (entry == null) {
      for (final otherMap in _variantMapByLang.values) {
        if (otherMap.containsKey(normalized)) {
          entry = otherMap[normalized];
          break;
        }
      }
    }

    if (entry == null) return null;

    final adjusted = (rawConfidence + entry.confidenceBoost).clamp(0.0, 1.0);
    return LexiconLookupResult(
      canonicalConcept: entry.canonicalConcept,
      matchedVariant: spokenTerm,
      fieldType: entry.fieldType,
      confidenceBoost: entry.confidenceBoost,
      adjustedConfidence: adjusted,
      outputTransform: entry.outputTransform,
    );
  }

  /// Pure canonicalisation function satisfying Property 13 (Idempotence).
  ///
  /// Invariant: `canonicalise(canonicalise(term)) == canonicalise(term)`.
  /// If [term] is already a canonical concept or has no mapping, it is returned intact.
  String canonicalise(String term, {String language = 'en'}) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return '';

    // Check if term is already a known canonical concept (identity property)
    if (_knownCanonicalConcepts.contains(trimmed.toUpperCase())) {
      // Find the exact registered case
      for (final concept in _knownCanonicalConcepts) {
        if (concept.toUpperCase() == trimmed.toUpperCase()) {
          return concept;
        }
      }
      return trimmed.toUpperCase();
    }

    final result = lookup(trimmed, language: language);
    if (result != null) {
      return result.canonicalConcept;
    }

    // Unmapped terms return their trimmed normalized form
    return trimmed;
  }

  /// Checks whether confidence falls below threshold (Requirement 6.3).
  bool requiresConfirmation({
    required double confidence,
    double threshold = 0.70,
  }) {
    return confidence < threshold;
  }

  static String _normalizeString(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'''[.,!?:;"'\-—–]'''), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  void _registerEmbeddedDefaults() {
    registerBundle(
      const LexiconBundle(
        language: 'hi',
        version: 'embedded_1.0',
        entries: [
          LexiconEntry(
            spokenVariants: ['साँस तेज़', 'सांस तेज़', 'सांस फूलना', 'हाँफना', 'तेज सांस', 'तेज़ साँस', 'सांस तेज'],
            canonicalConcept: 'FAST_BREATHING',
            confidenceBoost: 0.1,
          ),
          LexiconEntry(
            spokenVariants: ['पीलिया', 'पीला', 'आँखें पीली', 'पीलापन', 'पीली आँखें'],
            canonicalConcept: 'JAUNDICE',
          ),
          LexiconEntry(
            spokenVariants: ['बुखार', 'तेज बुखार', 'ताप', 'गर्म बदन', 'ज्वर'],
            canonicalConcept: 'FEVER',
            confidenceBoost: 0.05,
          ),
          LexiconEntry(
            spokenVariants: ['दस्त', 'पतले दस्त', 'झाड़ा', 'पेचिश'],
            canonicalConcept: 'DIARRHEA',
            confidenceBoost: 0.05,
          ),
          LexiconEntry(
            spokenVariants: ['खून की कमी', 'एनीमिया', 'रक्तअल्पता'],
            canonicalConcept: 'ANEMIA',
          ),
          LexiconEntry(
            spokenVariants: ['कुपोषण', 'सूखा रोग', 'कमजोरी'],
            canonicalConcept: 'MALNUTRITION',
          ),
          LexiconEntry(
            spokenVariants: ['दौरा', 'दौरे', 'झटके', 'आक्षेप'],
            canonicalConcept: 'CONVULSIONS',
            confidenceBoost: 0.1,
          ),
          LexiconEntry(
            spokenVariants: ['छाती धंसना', 'पसलियां चलना', 'छाती खिंचना'],
            canonicalConcept: 'CHEST_INDRAWING',
            confidenceBoost: 0.1,
          ),
          LexiconEntry(
            spokenVariants: ['उल्टी', 'उलटी', 'कै'],
            canonicalConcept: 'VOMITING',
            confidenceBoost: 0.05,
          ),
          LexiconEntry(
            spokenVariants: ['हाँ', 'haan', 'ha', 'ji haan', 'हाँजी'],
            canonicalConcept: 'YES',
            fieldType: 'boolean',
          ),
          LexiconEntry(
            spokenVariants: ['नहीं', 'nahi', 'nahin', 'ji nahi', 'ना'],
            canonicalConcept: 'NO',
            fieldType: 'boolean',
          ),
          LexiconEntry(
            spokenVariants: ['तीस', '30', 'तीस साल'],
            canonicalConcept: '30',
            fieldType: 'numeric',
            outputTransform: 'numeric',
          ),
        ],
      ),
    );

    registerBundle(
      const LexiconBundle(
        language: 'en',
        version: 'embedded_1.0',
        entries: [
          LexiconEntry(
            spokenVariants: ['fast breathing', 'rapid breathing', 'shortness of breath', 'gasping'],
            canonicalConcept: 'FAST_BREATHING',
            confidenceBoost: 0.1,
          ),
          LexiconEntry(
            spokenVariants: ['jaundice', 'yellow skin', 'yellow eyes'],
            canonicalConcept: 'JAUNDICE',
          ),
          LexiconEntry(
            spokenVariants: ['fever', 'high temperature', 'hot body', 'chills'],
            canonicalConcept: 'FEVER',
            confidenceBoost: 0.05,
          ),
          LexiconEntry(
            spokenVariants: ['diarrhea', 'loose stools', 'watery stools'],
            canonicalConcept: 'DIARRHEA',
            confidenceBoost: 0.05,
          ),
          LexiconEntry(
            spokenVariants: ['anemia', 'pale skin', 'low blood'],
            canonicalConcept: 'ANEMIA',
          ),
          LexiconEntry(
            spokenVariants: ['malnutrition', 'wasting', 'underweight'],
            canonicalConcept: 'MALNUTRITION',
          ),
          LexiconEntry(
            spokenVariants: ['convulsions', 'seizures', 'fits'],
            canonicalConcept: 'CONVULSIONS',
            confidenceBoost: 0.1,
          ),
          LexiconEntry(
            spokenVariants: ['chest indrawing', 'intercostal indrawing'],
            canonicalConcept: 'CHEST_INDRAWING',
            confidenceBoost: 0.1,
          ),
          LexiconEntry(
            spokenVariants: ['vomiting', 'throwing up'],
            canonicalConcept: 'VOMITING',
            confidenceBoost: 0.05,
          ),
          LexiconEntry(
            spokenVariants: ['yes', 'yeah', 'correct', 'true'],
            canonicalConcept: 'YES',
            fieldType: 'boolean',
          ),
          LexiconEntry(
            spokenVariants: ['no', 'nope', 'false'],
            canonicalConcept: 'NO',
            fieldType: 'boolean',
          ),
          LexiconEntry(
            spokenVariants: ['thirty', '30'],
            canonicalConcept: '30',
            fieldType: 'numeric',
            outputTransform: 'numeric',
          ),
        ],
      ),
    );
  }
}

/// Riverpod provider for [LexiconService].
final lexiconServiceProvider = Provider<LexiconService>((ref) {
  return LexiconService();
});
