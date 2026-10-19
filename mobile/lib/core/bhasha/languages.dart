/// Languages this phone build can translate into English.
///
/// [speech] is true when Dolphin, the on-phone listener, covers that language.
/// Kannada and Malayalam can still be typed.
class IndicLanguage {
  const IndicLanguage({
    required this.code,
    required this.flores,
    required this.iso,
    required this.name,
    required this.nativeName,
    required this.speech,
  });

  /// App code, kept stable for the saved setting.
  final String code;

  /// IndicTrans2 language tag, for example `hin_Deva`.
  final String flores;

  /// ISO code used by the Indic normalizer and the script map.
  final String iso;
  final String name;
  final String nativeName;
  final bool speech;

  String get label => '$nativeName · $name';
}

const indicLanguages = <IndicLanguage>[
  IndicLanguage(
    code: 'hi-IN',
    flores: 'hin_Deva',
    iso: 'hi',
    name: 'Hindi',
    nativeName: 'हिन्दी',
    speech: true,
  ),
  IndicLanguage(
    code: 'mr-IN',
    flores: 'mar_Deva',
    iso: 'mr',
    name: 'Marathi',
    nativeName: 'मराठी',
    speech: true,
  ),
  IndicLanguage(
    code: 'bn-IN',
    flores: 'ben_Beng',
    iso: 'bn',
    name: 'Bengali',
    nativeName: 'বাংলা',
    speech: true,
  ),
  IndicLanguage(
    code: 'ta-IN',
    flores: 'tam_Taml',
    iso: 'ta',
    name: 'Tamil',
    nativeName: 'தமிழ்',
    speech: true,
  ),
  IndicLanguage(
    code: 'te-IN',
    flores: 'tel_Telu',
    iso: 'te',
    name: 'Telugu',
    nativeName: 'తెలుగు',
    speech: true,
  ),
  IndicLanguage(
    code: 'gu-IN',
    flores: 'guj_Gujr',
    iso: 'gu',
    name: 'Gujarati',
    nativeName: 'ગુજરાતી',
    speech: true,
  ),
  IndicLanguage(
    code: 'pa-IN',
    flores: 'pan_Guru',
    iso: 'pa',
    name: 'Punjabi',
    nativeName: 'ਪੰਜਾਬੀ',
    speech: true,
  ),
  IndicLanguage(
    code: 'or-IN',
    flores: 'ory_Orya',
    iso: 'or',
    name: 'Odia',
    nativeName: 'ଓଡ଼ିଆ',
    speech: true,
  ),
  IndicLanguage(
    code: 'kn-IN',
    flores: 'kan_Knda',
    iso: 'kn',
    name: 'Kannada',
    nativeName: 'ಕನ್ನಡ',
    speech: false,
  ),
  IndicLanguage(
    code: 'ml-IN',
    flores: 'mal_Mlym',
    iso: 'ml',
    name: 'Malayalam',
    nativeName: 'മലയാളം',
    speech: false,
  ),
];

IndicLanguage? languageByCode(String? code) {
  if (code == null || code.isEmpty) return null;
  for (final language in indicLanguages) {
    if (language.code == code) return language;
  }
  return null;
}

String languageLabel(String? code) {
  if (code == 'en') return 'English';
  return languageByCode(code)?.name ?? 'Hindi';
}
