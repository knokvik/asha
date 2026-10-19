import 'indic_text.dart';

/// Words an ASHA worker and a family actually use.
///
/// Indic to English: a surface such as मीटर or ढोकला is swapped for the English
/// lemma before the model runs, so the worker reads "meter" and "dhokla" rather
/// than a misspelling.
///
/// English to Indic: the model already carries most of these words. Forcing the
/// Devanagari in first can make it invent a different word (ढोकला became ताला).
/// Only the phrases it actually gets wrong are held aside as `<G1>` and put back,
/// in the family's script, after the translation.
class FieldTerm {
  const FieldTerm(
    this.english,
    this.spoken, {
    this.aliases = const [],
    this.forms = const [],
    this.shieldAsk = false,
  });

  /// What the worker should read.
  final String english;

  /// Devanagari the family should see and hear.
  final String spoken;

  /// Other English spellings that mean this term.
  final List<String> aliases;

  /// Other Devanagari spellings that mean this term.
  final List<String> forms;

  /// Hold this phrase out of English-to-Indic. The model mishandles it.
  final bool shieldAsk;
}

const fieldTerms = <FieldTerm>[
  // Food names the model tends to split or invent.
  FieldTerm('dhokla', 'ढोकला'),
  FieldTerm('idli', 'इडली'),
  FieldTerm('dosa', 'डोसा'),
  FieldTerm('roti', 'रोटी'),
  FieldTerm('chapati', 'चपाती', aliases: ['chapatti', 'chapathi']),
  FieldTerm('khichdi', 'खिचड़ी', aliases: ['khichri', 'khichadi', 'khichdee']),
  FieldTerm('dal', 'दाल', aliases: ['daal', 'dhal']),
  FieldTerm('poha', 'पोहा'),
  FieldTerm('upma', 'उपमा'),
  FieldTerm('laddu', 'लड्डू', aliases: ['laddoo', 'ladoo', 'laddu']),
  FieldTerm('chikki', 'चिक्की'),
  FieldTerm('panjiri', 'पंजीरी', aliases: ['panjeeri', 'panjiri']),
  FieldTerm('sattu', 'सत्तू'),
  FieldTerm('ragi', 'रागी'),
  FieldTerm('jowar', 'ज्वार'),
  FieldTerm('bajra', 'बाजरा'),
  FieldTerm('thepla', 'थेपला', shieldAsk: true),
  FieldTerm('khakhra', 'खाखरा', shieldAsk: true),
  FieldTerm('chutney', 'चटनी'),

  // Measures and English loanwords spoken as-is.
  FieldTerm('high blood pressure', 'हाई बीपी', aliases: ['high bp']),
  FieldTerm('low blood pressure', 'लो बीपी', aliases: ['low bp']),
  FieldTerm('blood pressure', 'बीपी', aliases: ['bp', 'b.p.', 'b.p']),
  FieldTerm('meter', 'मीटर', aliases: ['metre']),
  FieldTerm('litre', 'लीटर', aliases: ['liter']),
  FieldTerm('millilitre', 'मिलीलीटर', aliases: ['milliliter', 'millilitre']),
  FieldTerm('kilogram', 'किलोग्राम', aliases: ['kilo']),
  FieldTerm('milligram', 'मिलीग्राम'),
  FieldTerm('gram', 'ग्राम'),
  FieldTerm('iron tablet', 'आयरन की गोली', aliases: ['ifa tablet', 'ifa']),
  FieldTerm('tablet', 'गोली', forms: ['टैबलेट', 'टेबलेट']),
  FieldTerm('capsule', 'कैप्सूल'),
  FieldTerm('syrup', 'सिरप', forms: ['सीरप']),
  FieldTerm('injection', 'इंजेक्शन', forms: ['इंजेक्सन']),
  FieldTerm('syringe', 'सिरिंज', forms: ['सिरींज']),
  FieldTerm('bottle', 'बोतल'),
  FieldTerm('thermometer', 'थर्मामीटर'),
  FieldTerm('oxygen', 'ऑक्सीजन'),
  FieldTerm('pulse', 'पल्स'),
  FieldTerm('ultrasound', 'अल्ट्रासाउंड', aliases: ['sonography'], forms: ['सोनोग्राफी']),
  FieldTerm('scan', 'स्कैन'),
  FieldTerm('report', 'रिपोर्ट'),

  // Illness, pregnancy, and the words used in a visit.
  FieldTerm('cold and cough', 'सर्दी और खांसी'),
  FieldTerm(
    'loose motion',
    'दस्त',
    aliases: ['loose motions'],
    forms: ['लूज मोशन', 'लूस मोशन', 'डायरिया'],
    shieldAsk: true,
  ),
  FieldTerm('stomach pain', 'पेट दर्द', aliases: ['stomach ache', 'stomachache', 'abdominal pain']),
  FieldTerm('chest pain', 'सीने में दर्द'),
  FieldTerm('body pain', 'बदन दर्द', aliases: ['body ache']),
  FieldTerm('shortness of breath', 'साँस फूलना', aliases: ['breathlessness']),
  FieldTerm('pregnancy test', 'प्रेग्नेंसी टेस्ट'),
  FieldTerm(
    'missed period',
    'माहवारी नहीं आई',
    aliases: ['missed her period', 'missed periods'],
    shieldAsk: true,
  ),
  FieldTerm('sanitary pad', 'सैनिटरी पैड', aliases: ['sanitary napkin']),
  FieldTerm('copper-t', 'कॉपर-टी', aliases: ['copper t', 'iucd']),
  FieldTerm('blood sugar', 'ब्लड शुगर', aliases: ['sugar test']),
  FieldTerm('fever', 'बुखार', forms: ['फीवर', 'ज्वर']),
  FieldTerm('cough', 'खांसी', forms: ['कफ']),
  FieldTerm('cold', 'सर्दी'),
  FieldTerm('vomiting', 'उल्टी', aliases: ['vomit'], forms: ['उलटी']),
  FieldTerm('headache', 'सिरदर्द'),
  FieldTerm('dizziness', 'चक्कर', aliases: ['giddiness']),
  FieldTerm('weakness', 'कमजोरी'),
  FieldTerm('swelling', 'सूजन'),
  FieldTerm('bleeding', 'खून बहना'),
  FieldTerm('jaundice', 'पीलिया'),
  FieldTerm('dehydration', 'पानी की कमी'),
  FieldTerm('malnutrition', 'कुपोषण'),
  FieldTerm('pneumonia', 'निमोनिया'),
  FieldTerm('diabetes', 'मधुमेह', forms: ['डायबिटीज']),
  FieldTerm('anemia', 'एनीमिया', aliases: ['anaemia']),
  FieldTerm('haemoglobin', 'हीमोग्लोबिन', aliases: ['hemoglobin', 'hb']),
  FieldTerm('malaria', 'मलेरिया'),
  FieldTerm('dengue', 'डेंगू', aliases: ['dengu']),
  FieldTerm('TB', 'टीबी', aliases: ['tuberculosis', 'tb']),
  FieldTerm('convulsion', 'दौरा', aliases: ['seizure', 'seizures', 'convulsions', 'fits']),
  FieldTerm(
    'periods',
    'माहवारी',
    aliases: ['menstruation', 'menses'],
    shieldAsk: true,
  ),
  FieldTerm('pregnant', 'गर्भवती'),
  FieldTerm('pregnancy', 'गर्भावस्था'),
  FieldTerm('delivery', 'डिलीवरी', forms: ['प्रसव']),
  FieldTerm('breastfeeding', 'स्तनपान'),
  FieldTerm('first milk', 'पहला दूध', aliases: ['colostrum']),
  FieldTerm('newborn', 'नवजात'),
  FieldTerm('baby', 'बच्चा'),
  FieldTerm('urine', 'पेशाब', aliases: ['peshab']),
  FieldTerm('wound', 'घाव'),
  FieldTerm('bandage', 'पट्टी'),

  // Vaccines, medicines, and schemes.
  FieldTerm('pentavalent', 'पेंटावैलेंट'),
  FieldTerm('rotavirus', 'रोटावायरस', aliases: ['rota virus', 'rota']),
  FieldTerm('polio', 'पोलियो'),
  FieldTerm('tetanus', 'टिटनेस', aliases: ['tt injection', 'tt shot']),
  FieldTerm('measles', 'खसरा'),
  FieldTerm('BCG', 'बीसीजी', aliases: ['bcg']),
  FieldTerm('paracetamol', 'पैरासिटामोल'),
  FieldTerm('albendazole', 'एल्बेंडाजोल'),
  FieldTerm('deworming', 'कृमि की दवा'),
  FieldTerm('folic acid', 'फोलिक एसिड'),
  FieldTerm('calcium', 'कैल्शियम'),
  FieldTerm('iron', 'आयरन'),
  FieldTerm('ORS packet', 'ओआरएस का पैकेट'),
  FieldTerm('ORS', 'ओआरएस', aliases: ['ors']),
  FieldTerm('zinc', 'जिंक'),
  FieldTerm('glucose', 'ग्लूकोज'),
  FieldTerm('saline', 'सलाइन'),
  FieldTerm('condom', 'कंडोम'),
  FieldTerm('vaccine', 'टीका', aliases: ['vaccination', 'immunization', 'immunisation']),
  FieldTerm('ANC', 'एएनसी', aliases: ['anc', 'antenatal']),
  FieldTerm('ASHA worker', 'आशा कार्यकर्ता', aliases: ['asha', 'asha worker'], forms: ['आशा दीदी']),
  FieldTerm('ANM', 'एएनएम', aliases: ['anm']),
  FieldTerm('anganwadi', 'आंगनवाड़ी', aliases: ['anganvadi', 'anganbadi'], forms: ['आंगनवाडी']),
  FieldTerm('ICDS', 'आईसीडीएस', aliases: ['icds']),
  FieldTerm('JSY', 'जेएसवाई', aliases: ['jsy', 'janani suraksha yojana']),
  FieldTerm('PMMVY', 'पीएमएमवीवाई', aliases: ['pmmvy']),
  FieldTerm('PHC', 'पीएचसी', aliases: ['phc', 'primary health centre', 'primary health center']),
  FieldTerm('sub-centre', 'सब सेंटर', aliases: ['sub centre', 'sub center', 'sub-center']),
  FieldTerm('MCP card', 'एमसीपी कार्ड', aliases: ['mcp card']),
  FieldTerm('mosquito net', 'मच्छरदानी'),
  FieldTerm('hand washing', 'हाथ धोना', aliases: ['handwash', 'hand wash']),
  FieldTerm('toilet', 'शौचालय'),
  FieldTerm('hospital', 'अस्पताल'),
  FieldTerm('doctor', 'डॉक्टर'),
  FieldTerm('nurse', 'नर्स'),
  FieldTerm('medicine', 'दवा', forms: ['दवाई', 'मेडिसिन']),
  FieldTerm('follow-up', 'फॉलो अप', aliases: ['follow up']),
  FieldTerm('positive', 'पॉजिटिव'),
  FieldTerm('negative', 'नेगेटिव'),
  FieldTerm('weight', 'वजन'),
  FieldTerm('nutrition', 'पोषण'),
  FieldTerm('gloves', 'दस्ताने'),
  FieldTerm('mask', 'मास्क'),
  FieldTerm('sanitizer', 'सैनिटाइजर'),
];

class _Swap {
  const _Swap(this.surface, this.replacement, {required this.ascii});

  final String surface;
  final String replacement;
  final bool ascii;
}

final _toEnglish = <String, List<_Swap>>{};

/// Replace glossary surfaces in [text] with the English lemma.
String applyGlossaryToEnglish(String text, String iso) {
  return _apply(text, _swapsToEnglish(iso));
}

class ShieldedEnglish {
  const ShieldedEnglish(this.text, this.spokenById);

  final String text;
  final Map<int, String> spokenById;
}

/// Hold aside the English phrases the ask-back model gets wrong.
///
/// Each held phrase becomes `<ID90>`, `<ID91>`, and so on. The model was trained
/// to copy `<IDn>` and it transliterates a made-up marker. [spokenById] is the
/// Devanagari to put back after translation. Ids start at 90 so they do not
/// collide with the email and number placeholders.
ShieldedEnglish shieldAskTerms(String text) {
  final swaps = _askShields();
  if (text.isEmpty || swaps.isEmpty) {
    return ShieldedEnglish(text, const <int, String>{});
  }
  final spokenById = <int, String>{};
  final out = StringBuffer();
  var i = 0;
  var nextId = 90;
  while (i < text.length) {
    if (!_boundaryBefore(text, i)) {
      out.write(text[i]);
      i += 1;
      continue;
    }
    _Swap? hit;
    for (final swap in swaps) {
      final end = i + swap.surface.length;
      if (end > text.length || !_boundaryAfter(text, end)) continue;
      if (text.substring(i, end).toLowerCase() != swap.surface) continue;
      hit = swap;
      break;
    }
    if (hit == null) {
      out.write(text[i]);
      i += 1;
    } else {
      spokenById[nextId] = hit.replacement;
      out.write('<ID$nextId>');
      nextId += 1;
      i += hit.surface.length;
    }
  }
  return ShieldedEnglish(out.toString(), spokenById);
}

/// Put shielded phrases back. Latin `< G1 >` stays Latin through transliteration,
/// so this runs after the sentence has been moved into the family's script.
String restoreAskShields(String text, Map<int, String> spokenById, String iso) {
  if (spokenById.isEmpty || text.isEmpty) return text;
  return text.replaceAllMapped(RegExp(r'<\s*ID\s*(\d+)\s*>'), (match) {
    final spoken = spokenById[int.parse(match.group(1)!)];
    if (spoken == null) return match.group(0)!;
    if (iso == 'hi' || iso == 'mr') return spoken;
    return transliterateScript(spoken, 'hi', iso);
  });
}

List<_Swap> _swapsToEnglish(String iso) {
  return _toEnglish.putIfAbsent(iso, () {
    final swaps = <_Swap>[];
    final seen = <String>{};
    void add(String surface, String replacement, {required bool ascii}) {
      final key = ascii ? surface.toLowerCase() : surface;
      if (key.length < 2 || !seen.add('$ascii:$key')) return;
      swaps.add(_Swap(key, replacement, ascii: ascii));
    }

    for (final term in fieldTerms) {
      add(term.spoken, term.english, ascii: false);
      for (final form in term.forms) {
        add(form, term.english, ascii: false);
      }
      if (iso != 'hi' && iso != 'mr') {
        add(transliterateScript(term.spoken, 'hi', iso), term.english, ascii: false);
        for (final form in term.forms) {
          add(transliterateScript(form, 'hi', iso), term.english, ascii: false);
        }
      }
      add(term.english, term.english, ascii: true);
      for (final alias in term.aliases) {
        add(alias, term.english, ascii: true);
      }
    }
    swaps.sort((a, b) => b.surface.length.compareTo(a.surface.length));
    return swaps;
  });
}

List<_Swap>? _askShieldList;

List<_Swap> _askShields() {
  return _askShieldList ??= () {
    final swaps = <_Swap>[];
    final seen = <String>{};
    for (final term in fieldTerms) {
      if (!term.shieldAsk) continue;
      void add(String surface) {
        final key = surface.toLowerCase();
        if (key.length < 2 || !seen.add(key)) return;
        swaps.add(_Swap(key, term.spoken, ascii: true));
      }

      add(term.english);
      for (final alias in term.aliases) {
        add(alias);
      }
    }
    swaps.sort((a, b) => b.surface.length.compareTo(a.surface.length));
    return swaps;
  }();
}

String _apply(String text, List<_Swap> swaps) {
  if (text.isEmpty || swaps.isEmpty) return text;
  final out = StringBuffer();
  var i = 0;
  while (i < text.length) {
    if (!_boundaryBefore(text, i)) {
      out.write(text[i]);
      i += 1;
      continue;
    }
    _Swap? hit;
    for (final swap in swaps) {
      final end = i + swap.surface.length;
      if (end > text.length || !_boundaryAfter(text, end)) continue;
      final slice = text.substring(i, end);
      final matches = swap.ascii ? slice.toLowerCase() == swap.surface : slice == swap.surface;
      if (matches) {
        hit = swap;
        break;
      }
    }
    if (hit == null) {
      out.write(text[i]);
      i += 1;
    } else {
      out.write(hit.replacement);
      i += hit.surface.length;
    }
  }
  return out.toString();
}

bool _boundaryBefore(String text, int index) {
  if (index == 0) return true;
  return !_wordChar(text.codeUnitAt(index - 1));
}

bool _boundaryAfter(String text, int index) {
  if (index >= text.length) return true;
  return !_wordChar(text.codeUnitAt(index));
}

/// Letters, including Indic vowel signs, so a match cannot start inside a word.
/// Danda and Indic digits stay outside the word so "मीटर।" still matches.
bool _wordChar(int unit) {
  if (unit >= 0x41 && unit <= 0x5A) return true;
  if (unit >= 0x61 && unit <= 0x7A) return true;
  if (unit < 0x0900 || unit > 0x0DFF) return false;
  final inner = unit & 0x7F;
  if (inner == 0x64 || inner == 0x65) return false;
  if (inner >= 0x66 && inner <= 0x6F) return false;
  return true;
}
