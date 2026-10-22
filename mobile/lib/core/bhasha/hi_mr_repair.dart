import 'speech_engine.dart';

/// Turns rough Hindi and Marathi speech text into the written forms the
/// translator already knows. Other languages pass through unchanged.
///
/// The listener often prints English letters for words the family says
/// inside the sentence (fever, ORS, paani). Hindi and Marathi are the
/// languages this screen is meant to get right, so those letters are
/// rewritten into Devanagari before IndicTrans2 runs.
String prepareHeardForTranslation(String text, String iso) {
  final cleaned = cleanHeardText(text).replaceAll(RegExp(r'\s+'), ' ').trim();
  if (iso != 'hi' && iso != 'mr') return cleaned;
  final table = iso == 'mr' ? _marathi : _hindi;
  return _replaceWords(cleaned, table);
}

String _replaceWords(String text, Map<String, String> table) {
  final keys = table.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  var next = text;
  for (final key in keys) {
    next = next.replaceAll(
      RegExp('(?<![\\p{L}\\p{N}])${RegExp.escape(key)}(?![\\p{L}\\p{N}])', caseSensitive: false, unicode: true),
      table[key]!,
    );
  }
  return next.replaceAll(RegExp(r'\s+'), ' ').trim();
}

const _hindi = <String, String>{
  'high blood pressure': 'हाई बीपी',
  'low blood pressure': 'लो बीपी',
  'blood pressure': 'बीपी',
  'loose motion': 'दस्त',
  'loose motions': 'दस्त',
  'not drinking': 'पानी नहीं पी रहा',
  'cannot drink': 'पी नहीं सकता',
  'blood in stool': 'दस्त में खून',
  'fever': 'बुखार',
  'bukhar': 'बुखार',
  'bukhaar': 'बुखार',
  'ulti': 'उल्टी',
  'vomiting': 'उल्टी',
  'vomit': 'उल्टी',
  'dast': 'दस्त',
  'diarrhoea': 'दस्त',
  'diarrhea': 'दस्त',
  'paani': 'पानी',
  'pani': 'पानी',
  'nahin': 'नहीं',
  'nahi': 'नहीं',
  'doodh': 'दूध',
  'dudh': 'दूध',
  'baccha': 'बच्चा',
  'bachcha': 'बच्चा',
  'baby': 'बच्चा',
  'khansi': 'खांसी',
  'cough': 'खांसी',
  'saans': 'सांस',
  'breath': 'सांस',
  'behosh': 'बेहोश',
  'unconscious': 'बेहोश',
  'daura': 'दौरा',
  'fit': 'दौरा',
  'convulsion': 'दौरा',
  'ors': 'ओआरएस',
  'bp': 'बीपी',
  'tablet': 'गोली',
  'goli': 'गोली',
};

final _marathi = <String, String>{
  ..._hindi,
  'taap': 'ताप',
  'tap': 'ताप',
  'fever': 'ताप',
  'paani': 'पाणी',
  'pani': 'पाणी',
  'nahi': 'नाही',
  'nahin': 'नाही',
  'not drinking': 'पाणी पीत नाही',
  'cannot drink': 'प्यायला नाही',
  'baccha': 'बाळ',
  'bachcha': 'बाळ',
  'baby': 'बाळ',
  'jutka': 'झटका',
  'fit': 'झटका',
  'convulsion': 'झटका',
  'dokyala': 'डोक्याला',
};
