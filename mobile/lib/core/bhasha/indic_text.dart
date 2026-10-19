import 'languages.dart';

/// Source text ready for the IndicTrans2 tokenizer, plus placeholders to put back.
class PreparedText {
  const PreparedText(this.prefixed, this.placeholders);

  final String prefixed;
  final Map<String, String> placeholders;
}

const _scriptBase = <String, int>{
  'pa': 0x0A00,
  'gu': 0x0A80,
  'or': 0x0B00,
  'ta': 0x0B80,
  'te': 0x0C00,
  'kn': 0x0C80,
  'ml': 0x0D00,
  'hi': 0x0900,
  'mr': 0x0900,
  'kK': 0x0900,
  'sa': 0x0900,
  'ne': 0x0900,
  'sd': 0x0900,
  'bn': 0x0980,
  'as': 0x0980,
};

final _digits = _digitMap();

Map<int, String> _digitMap() {
  const groups = <String, String>{
    '0': '\u09e6\u0ae6\u0ce6\u0966\u0660\uabf0\u0b66\u0a66\u1c50\u06f0',
    '1': '\u09e7\u0ae7\u0967\u0ce7\u06f1\uabf1\u0b67\u0a67\u1c51\u0c67',
    '2': '\u09e8\u0ae8\u0968\u0ce8\u06f2\uabf2\u0b68\u0a68\u1c52\u0c68',
    '3': '\u09e9\u0ae9\u0969\u0ce9\u06f3\uabf3\u0b69\u0a69\u1c53\u0c69',
    '4': '\u09ea\u0aea\u096a\u0cea\u06f4\uabf4\u0b6a\u0a6a\u1c54\u0c6a',
    '5': '\u09eb\u0aeb\u096b\u0ceb\u06f5\uabf5\u0b6b\u0a6b\u1c55\u0c6b',
    '6': '\u09ec\u0aec\u096c\u0cec\u06f6\uabf6\u0b6c\u0a6c\u1c56\u0c6c',
    '7': '\u09ed\u0aed\u096d\u0ced\u06f7\uabf7\u0b6d\u0a6d\u1c57\u0c6d',
    '8': '\u09ee\u0aee\u096e\u0cee\u06f8\uabf8\u0b6e\u0a6e\u1c58\u0c6e',
    '9': '\u09ef\u0aef\u096f\u0cef\u06f9\uabf9\u0b6f\u0a6f\u1c59\u0c6f',
  };
  final map = <int, String>{};
  groups.forEach((digit, chars) {
    for (final char in chars.runes) {
      map[char] = digit;
    }
  });
  for (var code = 0x30; code <= 0x39; code++) {
    map[code] = String.fromCharCode(code);
  }
  return map;
}

const _asciiPunctuation = r"""!"#$%&'()*+,-./:;<=>?@[\]^_`{|}~""";
final _indicPunctuation = <int>{
  ..._asciiPunctuation.runes,
  0x0964,
  0x0965,
  0xAAF1,
  0xAAF0,
  0xABEB,
  0xABEC,
  0xABED,
  0xABEE,
  0xABEF,
  0x1C7E,
  0x1C7F,
};

final _multiSpace = RegExp('[ ]{2,}');
final _endBracket = RegExp(r'\) ([\.!:?;,])');
final _digitPercent = RegExp(r'(\d) %');
final _doubleQuote = RegExp(r'"([,\.]+)');
final _digitNbsp = RegExp('(\\d)\u00a0(\\d)');
final _nbspPunct = RegExp('\u00a0[?!;]');
final _url = RegExp(
  r"\b(?<![\w/.])(?:(?:https?|ftp)://)?(?:(?:[\w-]+\.)+(?!\.))(?:[\w/\-?#&=%.]+)+(?!\.\w+)\b",
);
final _numeral = RegExp(
  r"(~?\d+\.?\d*\s?%?\s?-?\s?~?\d+\.?\d*\s?%|~?\d+%|\d+[-\/.,:']\d+[-\/.,:'+]\d+(?:\.\d+)?|\d+[-\/.:'+]\d+(?:\.\d+)?)",
);
final _email = RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}');
final _other = RegExp(r'[A-Za-z0-9]*[#|@]\w+');
final _numSeq = RegExp(r'([0-9]+ [,.:/] )+[0-9]+');
final _anySpace = RegExp(r'\s+');

String _apply(String text, RegExp pattern, String replacement) {
  return text.replaceAll(pattern, replacement);
}

String _puncNorm(String text) {
  text = text.replaceAll('\r', '');
  text = _apply(text, RegExp(r'\(\s*'), '(');
  text = _apply(text, RegExp(r'\s*\)'), ')');
  text = _apply(text, RegExp(r'\s:\s?'), ':');
  text = _apply(text, RegExp(r'\s;\s?'), ';');
  text = text.replaceAll(RegExp("[`´‘‚’]"), "'");
  text = text.replaceAll(RegExp('[„“”«»]'), '"');
  text = text.replaceAll(RegExp('[–—]'), '-');
  text = text.replaceAll('...', '...');
  text = text.replaceAll('\u00a0%', '%');
  text = text.replaceAll('nº\u00a0', 'nº ');
  text = text.replaceAll('\u00a0ºC', ' ºC');
  text = text.replaceAllMapped(_nbspPunct, (m) => m.group(0)!.trim());
  text = text.replaceAll(',\u00a0', ', ');
  text = _multiSpace.allMatches(text).isEmpty
      ? text
      : text.replaceAll(_multiSpace, ' ');
  text = text.replaceAllMapped(_endBracket, (m) => ')${m.group(1)}');
  text = text.replaceAllMapped(_digitPercent, (m) => '${m.group(1)}%');
  text = text.replaceAllMapped(_doubleQuote, (m) => '${m.group(1)}"');
  text = text.replaceAllMapped(_digitNbsp, (m) => '${m.group(1)}.${m.group(2)}');
  return text.trim();
}

String _translateDigits(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    buffer.write(_digits[rune] ?? String.fromCharCode(rune));
  }
  return buffer.toString();
}

({String text, Map<String, String> placeholders}) _wrapPlaceholders(
  String text,
) {
  var serial = 1;
  final placeholders = <String, String>{};
  for (final pattern in [_email, _url, _numeral, _other]) {
    final matches = pattern.allMatches(text).map((m) => m.group(0)!).toSet();
    final ordered = matches.toList()
      ..sort((a, b) {
        final byLength = b.length.compareTo(a.length);
        if (byLength != 0) return byLength;
        return text.indexOf(a).compareTo(text.indexOf(b));
      });
    for (final match in ordered) {
      if (identical(pattern, _url) && match.replaceAll('.', '').length < 4) {
        continue;
      }
      if (identical(pattern, _numeral) &&
          match.replaceAll(' ', '').replaceAll('.', '').replaceAll(':', '').length <
              4) {
        continue;
      }
      if (!text.contains(match)) continue;
      final base = '<ID$serial>';
      placeholders[base] = match;
      placeholders['< ID$serial >'] = match;
      placeholders['[ID$serial]'] = match;
      placeholders['[ ID$serial ]'] = match;
      text = text.replaceAll(match, base);
      serial += 1;
    }
  }
  text = text.replaceAll(_anySpace, ' ').replaceAll('>/', '>').replaceAll(']/', ']');
  return (text: text, placeholders: placeholders);
}

String _baseNormalize(String text) {
  const pairs = <String, String>{
    '\ufeff': '',
    '\ufffe': '',
    '\u2060': '',
    '\u00ad': '',
    '\u200b': ' ',
    '\u00a0': ' ',
    '\u200c': '',
    '\u200d': '',
    '„': '"',
    '“': '"',
    '”': '"',
    '–': '-',
    '—': ' - ',
    '´': "'",
    '‘': "'",
    '‚': "'",
    '’': "'",
    "''": '"',
    '´´': '"',
    '…': '...',
  };
  pairs.forEach((from, to) {
    text = text.replaceAll(from, to);
  });
  return text;
}

String _scriptNormalize(String text, String iso) {
  if (iso == 'ml') {
    const chillu = <String, String>{
      '\u0d23\u0d4d\u200d': '\u0d7a',
      '\u0d28\u0d4d\u200d': '\u0d7b',
      '\u0d30\u0d4d\u200d': '\u0d7c',
      '\u0d32\u0d4d\u200d': '\u0d7d',
      '\u0d33\u0d4d\u200d': '\u0d7e',
      '\u0d15\u0d4d\u200d': '\u0d7f',
    };
    chillu.forEach((from, to) {
      text = text.replaceAll(from, to);
    });
  }
  text = _baseNormalize(text);
  switch (iso) {
    case 'hi':
    case 'mr':
    case 'sa':
    case 'kK':
    case 'ne':
    case 'sd':
      text = text.replaceAll('\u0972', '\u090f');
      const nukta = <String, String>{
        '\u0929': '\u0928\u093c',
        '\u0931': '\u0930\u093c',
        '\u0934': '\u0933\u093c',
        '\u0958': '\u0915\u093c',
        '\u0959': '\u0916\u093c',
        '\u095a': '\u0917\u093c',
        '\u095b': '\u091c\u093c',
        '\u095c': '\u0921\u093c',
        '\u095d': '\u0922\u093c',
        '\u095e': '\u092b\u093c',
        '\u095f': '\u092f\u093c',
      };
      nukta.forEach((from, to) {
        text = text.replaceAll(from, to);
      });
      text = text.replaceAll('|', '\u0964');
      text = text.replaceAllMapped(
        RegExp(r'([\u0900-\u097f]):'),
        (m) => '${m.group(1)}\u0903',
      );
    case 'pa':
      const vowels = <String, String>{
        '\u0a05\u0a3e': '\u0a06',
        '\u0a72\u0a3f': '\u0a07',
        '\u0a72\u0a40': '\u0a08',
        '\u0a73\u0a41': '\u0a09',
        '\u0a73\u0a42': '\u0a0a',
        '\u0a72\u0a47': '\u0a0f',
        '\u0a05\u0a48': '\u0a10',
        '\u0a73\u0a4b': '\u0a13',
        '\u0a05\u0a4c': '\u0a14',
      };
      vowels.forEach((from, to) {
        text = text.replaceAll(from, to);
      });
      const nukta = <String, String>{
        '\u0a33': '\u0a32\u0a3c',
        '\u0a36': '\u0a38\u0a3c',
        '\u0a59': '\u0a16\u0a3c',
        '\u0a5a': '\u0a17\u0a3c',
        '\u0a5b': '\u0a1c\u0a3c',
        '\u0a5e': '\u0a2b\u0a3c',
      };
      nukta.forEach((from, to) {
        text = text.replaceAll(from, to);
      });
      text = text
          .replaceAll('\u0a64', '\u0964')
          .replaceAll('\u0a65', '\u0965')
          .replaceAll('|', '\u0964');
      text = text.replaceAllMapped(
        RegExp(r'([\u0a00-\u0a7f]):'),
        (m) => '${m.group(1)}\u0a03',
      );
    case 'gu':
      text = text.replaceAll('\u0ae4', '\u0964').replaceAll('\u0ae5', '\u0965');
      text = text.replaceAllMapped(
        RegExp(r'([\u0a80-\u0aff]):'),
        (m) => '${m.group(1)}\u0a83',
      );
    case 'or':
      text = text
          .replaceAll('\u0b05\u0b3e', '\u0b06')
          .replaceAll('\u0b0f\u0b57', '\u0b10')
          .replaceAll('\u0b13\u0b57', '\u0b14')
          .replaceAll('\u0b5c', '\u0b21\u0b3c')
          .replaceAll('\u0b5d', '\u0b22\u0b3c')
          .replaceAll('\u0b64', '\u0964')
          .replaceAll('\u0b65', '\u0965')
          .replaceAll('\u0b7c', '\u0964')
          .replaceAll('\u0b35', '\u0b2c')
          .replaceAll('\u0b47\u0b56', '\u0b58')
          .replaceAll('\u0b47\u0b3e', '\u0b4b')
          .replaceAll('\u0b47\u0b57', '\u0b4c');
      text = text.replaceAllMapped(
        RegExp(r'([\u0b00-\u0b7f]):'),
        (m) => '${m.group(1)}\u0b03',
      );
    case 'bn':
    case 'as':
      text = text
          .replaceAll('\u09dc', '\u09a1\u09bc')
          .replaceAll('\u09dd', '\u09a2\u09bc')
          .replaceAll('\u09df', '\u09af\u09bc')
          .replaceAll('\u09e4', '\u0964')
          .replaceAll('\u09e5', '\u0965')
          .replaceAll('|', '\u0964')
          .replaceAll('\u09f7', '\u0964')
          .replaceAll('\u09c7\u09be', '\u09cb')
          .replaceAll('\u09c7\u09d7', '\u09cc');
      text = text.replaceAllMapped(
        RegExp(r'([\u0980-\u09ff]):'),
        (m) => '${m.group(1)}\u0983',
      );
    case 'ta':
      text = text
          .replaceAll('\u0be4', '\u0964')
          .replaceAll('\u0be5', '\u0965')
          .replaceAll('\u0b92\u0bd7', '\u0b94')
          .replaceAll('\u0bc6\u0bbe', '\u0bca')
          .replaceAll('\u0bc7\u0bbe', '\u0bcb')
          .replaceAll('\u0bc6\u0bd7', '\u0bcc');
      text = text.replaceAllMapped(
        RegExp(r'([\u0b80-\u0bff]):'),
        (m) => '${m.group(1)}\u0b83',
      );
    case 'te':
      text = text
          .replaceAll('\u0c64', '\u0964')
          .replaceAll('\u0c65', '\u0965')
          .replaceAll('\u0c46\u0c56', '\u0c48');
      text = text.replaceAllMapped(
        RegExp(r'([\u0c00-\u0c7f]):'),
        (m) => '${m.group(1)}\u0c03',
      );
    case 'kn':
      text = text
          .replaceAll('\u0ce4', '\u0964')
          .replaceAll('\u0ce5', '\u0965')
          .replaceAll('\u0cbf\u0cd5', '\u0cc0')
          .replaceAll('\u0cc6\u0cd5', '\u0cc7')
          .replaceAll('\u0cc6\u0cd6', '\u0cc8')
          .replaceAll('\u0cc6\u0cc2', '\u0cca')
          .replaceAll('\u0cca\u0cd5', '\u0ccb');
      text = text.replaceAllMapped(
        RegExp(r'([\u0c80-\u0cff]):'),
        (m) => '${m.group(1)}\u0c83',
      );
    case 'ml':
      text = text
          .replaceAll('\u0d64', '\u0964')
          .replaceAll('\u0d65', '\u0965')
          .replaceAll('\u0d46\u0d3e', '\u0d4a')
          .replaceAll('\u0d47\u0d3e', '\u0d4b')
          .replaceAll('\u0d46\u0d57', '\u0d4c')
          .replaceAll('\u0d57', '\u0d4c');
      text = text.replaceAllMapped(
        RegExp(r'([\u0d00-\u0d7f]):'),
        (m) => '${m.group(1)}\u0d03',
      );
  }
  return text;
}

String _trivialTokenize(String text) {
  final spaced = StringBuffer();
  text = text.replaceAll('\t', ' ');
  for (final rune in text.runes) {
    if (_indicPunctuation.contains(rune)) {
      spaced.write(' ');
      spaced.writeCharCode(rune);
      spaced.write(' ');
    } else {
      spaced.writeCharCode(rune);
    }
  }
  var collapsed = spaced.toString().replaceAll(RegExp(r'[ ]+'), ' ').trim();
  final rebuilt = StringBuffer();
  var previous = 0;
  for (final match in _numSeq.allMatches(collapsed)) {
    rebuilt.write(collapsed.substring(previous, match.start));
    rebuilt.write(match.group(0)!.replaceAll(' ', ''));
    previous = match.end;
  }
  rebuilt.write(collapsed.substring(previous));
  collapsed = rebuilt.toString();
  return collapsed.split(' ').where((part) => part.isNotEmpty).join(' ');
}

String _transliterate(String text, String fromIso) {
  final from = _scriptBase[fromIso];
  final to = _scriptBase['hi'];
  if (from == null || to == null) return text;
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final offset = rune - from;
    if (offset >= 0 && offset <= 111 && rune != 0x0964 && rune != 0x0965) {
      buffer.writeCharCode(to + offset);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// Tamil has no voiced or aspirated stops. The official map folds those
/// Devanagari offsets onto the unvoiced unaspirated Tamil letter.
int _tamilOffset(int offset) {
  if (offset >= 0x15 &&
      offset <= 0x28 &&
      offset != 0x1c &&
      (offset - 0x15) % 5 != 0 &&
      (offset - 0x15) % 5 != 4) {
    final subst = (offset - 0x15) ~/ 5;
    offset = 0x15 + 5 * subst;
  }
  if (offset == 0x2b || offset == 0x2c || offset == 0x2d) offset = 0x2a;
  if (offset == 0x36) offset = 0x37;
  return offset;
}

/// Map a coordinated Indic script onto another. Latin and danda stay put.
/// Tamil is corrected only when Tamil is the target.
String transliterateScript(String text, String fromIso, String toIso) {
  final from = _scriptBase[fromIso];
  final to = _scriptBase[toIso];
  if (from == null || to == null || from == to) return text;
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    var offset = rune - from;
    if (offset >= 0 && offset <= 111 && rune != 0x0964 && rune != 0x0965) {
      if (toIso == 'ta') offset = _tamilOffset(offset);
      buffer.writeCharCode(to + offset);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString();
}

/// Normalize, tokenize, and transliterate [text] into the Devanagari space
/// IndicTrans2 was trained on, then prefix the language tags.
PreparedText prepareIndicSource(String text, IndicLanguage language) {
  final script = language.flores.split('_')[1];
  text = _puncNorm(text);
  text = _translateDigits(text);
  final wrapped = _wrapPlaceholders(text);
  text = wrapped.text;
  final normalized = _scriptNormalize(text, language.iso);
  var joined = _trivialTokenize(normalized);
  const keepScript = {'Arab', 'Aran', 'Olck', 'Mtei', 'Latn'};
  if (!keepScript.contains(script)) {
    joined = _transliterate(joined, language.iso).replaceAll(' ् ', '्');
  }
  joined = joined.trim();
  return PreparedText(
    '${language.flores} eng_Latn $joined',
    wrapped.placeholders,
  );
}

/// Moses-style English detokenizer for the spacing IndicTrans2 emits.
String finishEnglish(String raw, Map<String, String> placeholders) {
  var text = raw;
  final keys = placeholders.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final key in keys) {
    text = text.replaceAll(key, placeholders[key]!);
  }
  final tokens = text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  final punct = RegExp(r"""^[,\.\?\!\:\;\\%\}\]\)]+$""");
  final contraction = RegExp(r"^'[A-Za-z]");
  final buffer = StringBuffer();
  var prepend = '';
  for (var i = 0; i < tokens.length; i++) {
    final token = tokens[i];
    if (punct.hasMatch(token) || (i > 0 && contraction.hasMatch(token))) {
      buffer.write(token);
      prepend = ' ';
    } else {
      buffer.write(prepend);
      buffer.write(token);
      prepend = ' ';
    }
  }
  return buffer.toString().replaceAll(RegExp(r' {2,}'), ' ').trim();
}

/// Break a long turn into sentence-sized pieces so the 128-token decoder
/// does not cut a paragraph off.
List<String> splitForTranslation(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const [];
  final pieces = trimmed
      .split(RegExp(r'(?<=[।!?])\s+|(?<=\.)\s+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  final limited = <String>[];
  for (final piece in pieces.isEmpty ? [trimmed] : pieces) {
    if (piece.length <= 240) {
      limited.add(piece);
      continue;
    }
    final words = piece.split(RegExp(r'\s+'));
    final buffer = StringBuffer();
    for (final word in words) {
      if (buffer.isNotEmpty && buffer.length + word.length > 220) {
        limited.add(buffer.toString());
        buffer.clear();
      }
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(word);
    }
    if (buffer.isNotEmpty) limited.add(buffer.toString());
  }
  return limited;
}

/// English source for IndicTrans2. Punctuation is spaced. The text is not run
/// through the Indic normalizer, and Latin the glossary inserted stays Latin
/// while Devanagari glossary words stay Devanagari.
PreparedText prepareEnglishSource(String text, IndicLanguage language) {
  text = _puncNorm(text);
  text = _translateDigits(text);
  final wrapped = _wrapPlaceholders(text);
  final joined = _trivialTokenize(wrapped.text);
  return PreparedText(
    'eng_Latn ${language.flores} $joined',
    wrapped.placeholders,
  );
}

/// Put the Devanagari model output into [toIso], and pull danda back onto the word.
String finishIndic(String raw, Map<String, String> placeholders, String toIso) {
  var text = raw;
  final keys = placeholders.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  for (final key in keys) {
    text = text.replaceAll(key, placeholders[key]!);
  }
  if (toIso != 'hi' && toIso != 'mr') {
    text = transliterateScript(text, 'hi', toIso);
  }
  final tokens = text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  final punct = RegExp(r"""^[,\.\?\!\:\;\\%\}\]\)]+[।॥]?$|^[।॥]+$""");
  final buffer = StringBuffer();
  var prepend = '';
  for (final token in tokens) {
    if (punct.hasMatch(token)) {
      buffer.write(token);
      prepend = ' ';
    } else {
      buffer.write(prepend);
      buffer.write(token);
      prepend = ' ';
    }
  }
  return buffer.toString().replaceAll(RegExp(r' {2,}'), ' ').trim();
}
