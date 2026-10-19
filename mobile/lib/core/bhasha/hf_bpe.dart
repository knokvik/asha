import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:characters/characters.dart';

/// Hugging Face BPE tokenizer, the same one shipped with the IndicTrans2 ONNX
/// bundle. Language tags are whole-word added tokens. The body is Metaspace
/// BPE, and encode appends the end-of-sentence id.
class HfBpeTokenizer {
  HfBpeTokenizer._(
    this._vocab,
    this._idToToken,
    this._merges,
    this._addedPattern,
    this._addedIds,
    this._chars,
  );

  static const unkId = 3;

  final Map<String, int> _vocab;
  final Map<int, String> _idToToken;
  final Map<String, Map<String, int>> _merges;
  final RegExp _addedPattern;
  final Map<String, int> _addedIds;
  final _SpmChars? _chars;

  static Future<HfBpeTokenizer> load(File file) async {
    final decoded =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final model = decoded['model'] as Map<String, dynamic>;
    final vocabRaw = model['vocab'] as Map<String, dynamic>;
    final vocab = <String, int>{};
    final idToToken = <int, String>{};
    vocabRaw.forEach((token, id) {
      final value = (id as num).toInt();
      vocab[token] = value;
      idToToken[value] = token;
    });
    final merges = <String, Map<String, int>>{};
    final mergeList = model['merges'] as List<dynamic>;
    for (var rank = 0; rank < mergeList.length; rank++) {
      final pair = mergeList[rank] as List<dynamic>;
      final left = pair[0] as String;
      final right = pair[1] as String;
      merges.putIfAbsent(left, () => <String, int>{})[right] = rank;
    }
    final added = (decoded['added_tokens'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .where((token) => token['single_word'] == true)
        .toList();
    added.sort(
      (a, b) => (b['content'] as String).length.compareTo(
        (a['content'] as String).length,
      ),
    );
    final addedIds = <String, int>{
      for (final token in added)
        token['content'] as String: (token['id'] as num).toInt(),
    };
    final alternation = added
        .map((token) => RegExp.escape(token['content'] as String))
        .join('|');
    final pattern = RegExp('(?:^|(?<=\\s))($alternation)(?!\\S)\\s*');
    _SpmChars? chars;
    final normalizer = decoded['normalizer'];
    if (normalizer is Map<String, dynamic>) {
      final steps = normalizer['normalizers'];
      if (steps is List && steps.isNotEmpty) {
        final first = steps.first;
        if (first is Map<String, dynamic> &&
            first['precompiled_charsmap'] is String) {
          chars = _SpmChars.parse(first['precompiled_charsmap'] as String);
        }
      }
    }
    return HfBpeTokenizer._(
      vocab,
      idToToken,
      merges,
      pattern,
      addedIds,
      chars,
    );
  }

  /// Token ids for [text], clamped to [dictSize], with the end id appended.
  List<int> encode(String text, {required int dictSize}) {
    final ids = <int>[];
    var position = 0;
    for (final match in _addedPattern.allMatches(text)) {
      if (match.start > position) {
        _encodeSpan(text.substring(position, match.start), ids);
      }
      final id = _addedIds[match.group(1)];
      if (id != null) ids.add(id);
      position = match.end;
    }
    if (position < text.length) {
      _encodeSpan(text.substring(position), ids);
    }
    ids.add(2);
    for (var i = 0; i < ids.length; i++) {
      if (ids[i] >= dictSize) ids[i] = unkId;
    }
    return ids;
  }

  void _encodeSpan(String span, List<int> ids) {
    final normalized = _chars?.normalize(span) ?? span;
    for (final word in _metaspace(normalized)) {
      ids.addAll(_bpe(word));
    }
  }

  List<String> _metaspace(String text) {
    if (text.isEmpty) return const [];
    final marked = '▁${text.replaceAll(' ', '▁')}';
    final parts = marked.split('▁');
    final words = <String>[];
    for (final part in parts) {
      if (part.isEmpty) {
        if (words.isNotEmpty) words.add('▁');
        continue;
      }
      words.add('▁$part');
    }
    return words;
  }

  List<int> _bpe(String word) {
    final symbols = word.runes.map(String.fromCharCode).toList();
    while (symbols.length > 1) {
      var best = 1 << 62;
      var at = -1;
      for (var i = 0; i < symbols.length - 1; i++) {
        final rank = _merges[symbols[i]]?[symbols[i + 1]];
        if (rank != null && rank < best) {
          best = rank;
          at = i;
        }
      }
      if (at < 0) break;
      symbols[at] = symbols[at] + symbols[at + 1];
      symbols.removeAt(at + 1);
    }
    final ids = <int>[];
    for (final symbol in symbols) {
      final id = _vocab[symbol] ?? unkId;
      if (ids.isNotEmpty && id == unkId && ids.last == unkId) continue;
      ids.add(id);
    }
    return ids;
  }

  /// Target-side decode. Drops special ids and turns the Metaspace mark into a space.
  String decode(List<int> ids) {
    final buffer = StringBuffer();
    for (final id in ids) {
      if (id == 0 || id == 1 || id == 2 || id == 3) continue;
      final token = _idToToken[id];
      if (token != null) buffer.write(token);
    }
    var text = buffer.toString().replaceAll('▁', ' ');
    if (text.startsWith(' ')) text = text.substring(1);
    return text;
  }
}

/// SentencePiece precompiled character map, read the way Hugging Face does.
class _SpmChars {
  _SpmChars(this._trie, this._normalized);

  final List<int> _trie;
  final Uint8List _normalized;

  static _SpmChars parse(String encoded) {
    final bytes = base64Decode(encoded.replaceAll(RegExp(r'\s+'), ''));
    final view = ByteData.sublistView(bytes);
    final trieBytes = view.getUint32(0, Endian.little);
    final units = trieBytes ~/ 4;
    final trie = List<int>.generate(
      units,
      (index) => view.getUint32(4 + index * 4, Endian.little),
      growable: false,
    );
    return _SpmChars(trie, Uint8List.sublistView(bytes, 4 + trieBytes));
  }

  String normalize(String text) {
    final buffer = StringBuffer();
    for (final grapheme in text.characters) {
      final graphemeBytes = utf8.encode(grapheme);
      if (graphemeBytes.length < 6) {
        final whole = _transform(grapheme);
        if (whole != null) {
          buffer.write(whole);
          continue;
        }
      }
      var byteIndex = 0;
      for (final rune in grapheme.runes) {
        final char = String.fromCharCode(rune);
        final width = utf8.encode(char).length;
        final part = utf8.decode(graphemeBytes.sublist(byteIndex, byteIndex + width));
        byteIndex += width;
        final replaced = _transform(part);
        if (replaced != null) {
          buffer.write(replaced);
        } else {
          buffer.write(char);
        }
      }
    }
    return buffer.toString();
  }

  String? _transform(String chunk) {
    final values = _prefixValues(utf8.encode(chunk));
    if (values.isEmpty) return null;
    final start = values.first;
    if (start < 0 || start >= _normalized.length) return null;
    var end = start;
    while (end < _normalized.length && _normalized[end] != 0) {
      end += 1;
    }
    return utf8.decode(_normalized.sublist(start, end));
  }

  List<int> _prefixValues(List<int> key) {
    if (_trie.isEmpty) return const [];
    final results = <int>[];
    var node = 0;
    var unit = _trie[node];
    node ^= _offset(unit);
    for (final byte in key) {
      if (byte == 0) break;
      if (node < 0 || node >= _trie.length) return results;
      node ^= byte;
      if (node < 0 || node >= _trie.length) return results;
      unit = _trie[node];
      if (_label(unit) != byte) return results;
      node ^= _offset(unit);
      if (_hasLeaf(unit)) {
        if (node < 0 || node >= _trie.length) return results;
        results.add(_value(_trie[node]));
      }
    }
    return results;
  }

  static bool _hasLeaf(int unit) => ((unit >> 8) & 1) == 1;

  static int _value(int unit) => unit & ((1 << 31) - 1);

  static int _label(int unit) => unit & ((1 << 31) | 0xFF);

  static int _offset(int unit) => (unit >> 10) << ((unit & (1 << 9)) >> 6);
}
