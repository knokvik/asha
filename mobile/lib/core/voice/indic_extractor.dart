/// Clinical concept extracted from spoken or typed Indic natural language.
class ExtractedSymptom {
  const ExtractedSymptom({
    required this.concept,
    required this.matchedPhrase,
    required this.isAffirmative,
    this.durationDays,
    this.confidence = 1.0,
  });

  /// Canonical IMCI concept name (e.g. FAST_BREATHING, CONVULSIONS, FEVER)
  final String concept;

  /// The exact substring matched from user utterance
  final String matchedPhrase;

  /// True if affirmed ("बुखार है"), false if negated ("बुखार नहीं है")
  final bool isAffirmative;

  /// Optional duration extracted in days
  final int? durationDays;

  /// Extraction confidence score between 0.0 and 1.0
  final double confidence;

  Map<String, dynamic> toJson() => {
    'concept': concept,
    'matchedPhrase': matchedPhrase,
    'isAffirmative': isAffirmative,
    'durationDays': durationDays,
    'confidence': confidence,
  };
}

/// Token with clause break information for accurate Indic negation scoping.
class IndicToken {
  const IndicToken({
    required this.text,
    required this.start,
    required this.end,
    this.isClauseBreak = false,
  });

  final String text;
  final int start;
  final int end;
  final bool isClauseBreak;
}

/// Offline Indic Clinical Concept Extractor for Hindi, Marathi & English.
///
/// Implements §9.2 - §9.4 of clinical voice design:
/// - Bidirectional negation detection with clause boundary scoping (stops at "लेकिन", "पर", "और", commas, full stops).
/// - Lexicon-driven matching against WHO IMCI danger signs & symptoms.
/// - Pure Dart, deterministic, zero-network execution.
class IndicClinicalExtractor {
  IndicClinicalExtractor();

  // Negation keywords across Hindi, Marathi, English
  static const Set<String> _negationWords = {
    // Hindi
    'नहीं', 'ना', 'नही', 'बिना', 'मत',
    // Marathi
    'नाही', 'नाहीत', 'नव्हते', 'नसून', 'नको',
    // English
    'no', 'not', 'never', 'denies', 'without', 'absent',
  };

  // Conjunctions and punctuation that terminate negation scope
  static const Set<String> _clauseBreakWords = {
    'और', 'आणि', 'and', 'लेकिन', 'पण', 'but', 'पर', 'परंतु', 'किंतु', 'तथा',
  };

  static const Set<String> _clauseBreakPunctuation = {
    ',', '।', '.', ';', '?', '!', '|', '\n'
  };

  // Concept dictionary mapping canonical concept to multilingual spoken stems
  static const Map<String, List<String>> _conceptLexicon = {
    'CONVULSIONS': [
      'दौरा', 'दौरे', 'झटके', 'आक्षेप', 'मिर्गी', 'फिट्स',
      'झटके येतात', 'फिट आले', 'convulsion', 'convulsions', 'fits', 'seizures'
    ],
    'UNABLE_TO_DRINK': [
      'दूध नहीं पी रहा', 'पानी नहीं पी रहा', 'पी नहीं पा रहा', 'स्तनपान नहीं', 'कुछ नहीं पीता',
      'दूध पीत नाही', 'पाणी पीत नाही', 'unable to drink', 'cannot drink', 'cannot breastfeed', 'refusing feeds'
    ],
    'VOMITING': [
      'उल्टी', 'उलटी', 'कै', 'सब उल्टी', 'उलट्या',
      'vomiting', 'vomits everything', 'throwing up'
    ],
    'CHEST_INDRAWING': [
      'छाती धंसना', 'छाती धंस', 'पसलियां चलना', 'पसलियां', 'छाती खिंचना', 'छाती खिंच', 'छाती अंदर', 'छाती खचणे',
      'chest indrawing', 'indrawing', 'chest retractions'
    ],
    'STRIDOR': [
      'सांस में आवाज', 'घरघराहट', 'सीटी जैसी आवाज', 'स्ट्राइडर',
      'stridor', 'wheezing', 'noisy breathing'
    ],
    'FAST_BREATHING': [
      'साँस तेज़', 'सांस तेज़', 'सांस फूलना', 'हाँफना', 'तेज सांस', 'तेज़ साँस', 'सांस तेज',
      'श्वास जलद', 'दम लागणे', 'fast breathing', 'rapid breathing', 'shortness of breath'
    ],
    'FEVER': [
      'बुखार', 'तेज बुखार', 'ताप', 'गर्म बदन', 'ज्वर',
      'fever', 'high fever', 'temperature'
    ],
    'DIARRHEA': [
      'दस्त', 'पतले दस्त', 'झाड़ा', 'पेचिश', 'पतला पाखाना',
      'जुलाब', 'पातळ संडास', 'diarrhea', 'loose motions', 'watery stool'
    ],
    'MALNUTRITION': [
      'कुपोषण', 'सूखा रोग', 'वजन कम', 'कमजोरी',
      'कुपोषित', 'malnutrition', 'wasting', 'underweight'
    ],
    'EDEMA': [
      'पैरों में सूजन', 'सूजन', 'सूज', 'पायावर सूज',
      'edema', 'swelling in feet', 'swollen feet'
    ],
    'JAUNDICE': [
      'पीलिया', 'पीला', 'आँखें पीली', 'पीलापन', 'कावीळ', 'डोळे पिवळे',
      'jaundice', 'yellow eyes', 'yellow palms'
    ],
    'LETHARGY': [
      'सुस्ती', 'बेहोशी', 'सुस्त', 'होश नहीं', 'बेहोश', 'गुंगी', 'जागत नाही',
      'lethargic', 'unconscious', 'abnormally sleepy', 'unresponsive'
    ],
  };

  /// Extracts clinical symptoms and danger signs from natural language utterance.
  List<ExtractedSymptom> extract(String rawUtterance) {
    if (rawUtterance.trim().isEmpty) return [];

    final text = rawUtterance.toLowerCase();
    final tokens = _tokenize(text);
    final results = <ExtractedSymptom>[];

    for (final entry in _conceptLexicon.entries) {
      final concept = entry.key;
      final phrases = entry.value;

      for (final phrase in phrases) {
        final phraseLower = phrase.toLowerCase();
        final matchIdx = text.indexOf(phraseLower);
        if (matchIdx != -1) {
          final isNegated = _isPhraseNegated(tokens, matchIdx, matchIdx + phraseLower.length);

          results.add(ExtractedSymptom(
            concept: concept,
            matchedPhrase: phrase,
            isAffirmative: !isNegated,
            confidence: 0.95,
          ));
          break; // Avoid duplicate matches for same concept
        }
      }
    }

    return results;
  }

  bool _isPhraseNegated(List<IndicToken> tokens, int charStart, int charEnd) {
    if (tokens.isEmpty) return false;

    // Find token range for this match
    int tokenStart = -1;
    int tokenEnd = -1;
    for (int i = 0; i < tokens.length; i++) {
      if (tokenStart == -1 && tokens[i].end > charStart) {
        tokenStart = i;
      }
      if (tokens[i].start < charEnd) {
        tokenEnd = i;
      }
    }

    if (tokenStart == -1 || tokenEnd == -1) return false;

    // Check backwards up to 4 tokens or clause break
    for (int i = tokenStart - 1; i >= 0 && i >= tokenStart - 4; i--) {
      if (tokens[i].isClauseBreak) break;
      if (_negationWords.contains(tokens[i].text)) {
        return true;
      }
    }

    // Check forwards (Indic verb-final) up to 4 tokens or clause break
    for (int i = tokenEnd + 1; i < tokens.length && i <= tokenEnd + 4; i++) {
      if (tokens[i].isClauseBreak) break;
      if (_negationWords.contains(tokens[i].text)) {
        return true;
      }
    }

    return false;
  }

  List<IndicToken> _tokenize(String text) {
    final tokens = <IndicToken>[];
    final pattern = RegExp(r'\S+');

    for (final match in pattern.allMatches(text)) {
      final raw = match.group(0)!;
      final hasPunct = raw.isNotEmpty && _clauseBreakPunctuation.contains(raw[raw.length - 1]);
      final clean = raw.replaceAll(RegExp(r'[^\w\u0900-\u097F]', unicode: true), '').trim();

      if (clean.isNotEmpty) {
        tokens.add(IndicToken(
          text: clean,
          start: match.start,
          end: match.end,
          isClauseBreak: _clauseBreakWords.contains(clean),
        ));
      }

      if (hasPunct) {
        tokens.add(IndicToken(
          text: raw[raw.length - 1],
          start: match.end - 1,
          end: match.end,
          isClauseBreak: true,
        ));
      }
    }
    return tokens;
  }
}
