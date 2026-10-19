import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:onnxruntime_core/onnxruntime_core.dart';

import 'field_glossary.dart';
import 'hf_bpe.dart';
import 'indic_text.dart';
import 'languages.dart';

/// Phone-sized IndicTrans2, Indic to English.
///
/// The weights are the distilled 200M INT8 export. A sentence is encoded,
/// run through the encoder once, then decoded greedily for at most 128 tokens.
class IndicTranslator {
  IndicTranslator._(
    this._encoder,
    this._decoder,
    this._decoderPast,
    this._sourceTokenizer,
    this._targetTokenizer, {
    required this.srcDictSize,
    required this.tgtDictSize,
  });

  static const eosId = 2;
  static const layers = 18;
  static const maxNewTokens = 128;

  final Session _encoder;
  final Session _decoder;
  final Session _decoderPast;
  final HfBpeTokenizer _sourceTokenizer;
  final HfBpeTokenizer _targetTokenizer;
  final int srcDictSize;
  final int tgtDictSize;

  static Future<IndicTranslator> open(Directory directory) {
    return _open(directory, srcDictSize: 122706, tgtDictSize: 32296);
  }

  /// English into an Indian language. Same 18-layer model, vocabularies swapped.
  static Future<IndicTranslator> openEnglish(Directory directory) {
    return _open(directory, srcDictSize: 32322, tgtDictSize: 122672);
  }

  static Future<IndicTranslator> _open(
    Directory directory, {
    required int srcDictSize,
    required int tgtDictSize,
  }) async {
    await openOnnxRuntime();
    final options = SessionOptions(
      intraOpNumThreads: 2,
      config: {
        'session.model_external_initializers_file_folder_path': directory.path,
      },
    );
    Session? encoder;
    Session? decoder;
    Session? past;
    try {
      encoder = _openGraph(directory, 'encoder_model.onnx', options);
      decoder = _openGraph(directory, 'decoder_model.onnx', options);
      past = _openGraph(directory, 'decoder_with_past_model.onnx', options);
      final source = await HfBpeTokenizer.load(
        File('${directory.path}/tokenizer_src.json'),
      );
      final target = await HfBpeTokenizer.load(
        File('${directory.path}/tokenizer_tgt.json'),
      );
      return IndicTranslator._(
        encoder,
        decoder,
        past,
        source,
        target,
        srcDictSize: srcDictSize,
        tgtDictSize: tgtDictSize,
      );
    } catch (_) {
      encoder?.release();
      decoder?.release();
      past?.release();
      rethrow;
    }
  }

  void close() {
    _encoder.release();
    _decoder.release();
    _decoderPast.release();
  }

  String translate(String text, IndicLanguage language, {bool glossary = true}) {
    return _run(
      glossary ? applyGlossaryToEnglish(text, language.iso) : text,
      (piece) => prepareIndicSource(piece, language),
      (raw, placeholders) => finishEnglish(raw, placeholders),
    );
  }

  String translateFromEnglish(
    String text,
    IndicLanguage language, {
    bool glossary = true,
  }) {
    final shielded = glossary
        ? shieldAskTerms(text)
        : ShieldedEnglish(text, const {});
    return _run(
      shielded.text,
      (piece) => prepareEnglishSource(piece, language),
      (raw, placeholders) {
        final finished = finishIndic(raw, placeholders, language.iso);
        return restoreAskShields(finished, shielded.spokenById, language.iso);
      },
    );
  }

  String _run(
    String text,
    PreparedText Function(String piece) prepare,
    String Function(String raw, Map<String, String> placeholders) finish,
  ) {
    final pieces = splitForTranslation(text);
    if (pieces.isEmpty) return '';
    final sentences = <String>[];
    for (final piece in pieces) {
      final prepared = prepare(piece);
      final raw = _generate(prepared);
      final sentence = finish(raw, prepared.placeholders);
      if (sentence.isNotEmpty) sentences.add(sentence);
    }
    return sentences.join(' ');
  }

  String _generate(PreparedText prepared) {
    final ids = _sourceTokenizer.encode(
      prepared.prefixed,
      dictSize: srcDictSize,
    );
    final input = _i64(ids, [1, ids.length]);
    final mask = _i64(List<int>.filled(ids.length, 1), [1, ids.length]);
    final encoded = _encoder.run({
      'input_ids': input,
      'attention_mask': mask,
    });
    input.release();
    final hidden = encoded.remove('last_hidden_state');
    _releaseAll(encoded.values);
    if (hidden == null) {
      mask.release();
      throw StateError('The encoder returned no hidden states.');
    }

    final generated = <int>[];
    var token = eosId;
    final past = <String, OrtTensor>{};
    OrtTensor? hiddenHeld = hidden;
    try {
      for (var step = 0; step < maxNewTokens; step++) {
        final tokenTensor = _i64([token], [1, 1]);
        final Map<String, OrtTensor> outputs;
        if (step == 0) {
          outputs = _decoder.run({
            'input_ids': tokenTensor,
            'encoder_hidden_states': hiddenHeld!,
            'encoder_attention_mask': mask,
          });
        } else {
          outputs = _decoderPast.run({
            'input_ids': tokenTensor,
            'encoder_attention_mask': mask,
            ...past,
          });
        }
        tokenTensor.release();

        final logits = outputs.remove('logits');
        if (logits == null) {
          _releaseAll(outputs.values);
          throw StateError('The decoder returned no logits.');
        }
        final next = _argmax(logits);
        logits.release();

        final nextPast = <String, OrtTensor>{};
        try {
          for (var layer = 0; layer < layers; layer++) {
            for (final side in const [
              'decoder.key',
              'decoder.value',
              'encoder.key',
              'encoder.value',
            ]) {
              final name = 'present.$layer.$side';
              final value = outputs.remove(name);
              if (value == null) {
                throw StateError('The decoder did not return $name.');
              }
              nextPast['past_key_values.$layer.$side'] = value;
            }
          }
        } catch (_) {
          _releaseAll(outputs.values);
          _releaseAll(nextPast.values);
          rethrow;
        }
        _releaseAll(outputs.values);
        if (step > 0) _releaseAll(past.values);
        past
          ..clear()
          ..addAll(nextPast);
        if (step == 0) {
          hiddenHeld?.release();
          hiddenHeld = null;
        }
        if (next == eosId) break;
        final clamped = next >= tgtDictSize ? HfBpeTokenizer.unkId : next;
        generated.add(clamped);
        token = clamped;
      }
    } finally {
      _releaseAll(past.values);
      hiddenHeld?.release();
      mask.release();
    }

    return _targetTokenizer.decode(generated);
  }

  static Session _openGraph(
    Directory directory,
    String name,
    SessionOptions options,
  ) {
    final bytes = File('${directory.path}/$name').readAsBytesSync();
    return Session.fromBytes(bytes, options: options);
  }

  static OrtTensor _i64(List<int> values, List<int> shape) {
    return OrtTensor.fromData(
      OrtElementType.int64,
      Int64List.fromList(values),
      shape,
    );
  }

  static int _argmax(OrtTensor logits) {
    final view = logits.view;
    final vocab = view.shape.last;
    final List<num> values = switch (view.elementType) {
      OrtElementType.float32 => view.float32s,
      OrtElementType.int8 => view.int8s,
      OrtElementType.int32 => view.int32s,
      OrtElementType.float64 => view.float64s,
      _ => throw StateError(
        'Unexpected logits type ${view.elementType.name}.',
      ),
    };
    final offset = values.length - vocab;
    var best = 0;
    var score = values[offset];
    for (var i = 1; i < vocab; i++) {
      final value = values[offset + i];
      if (value > score) {
        score = value;
        best = i;
      }
    }
    return best;
  }

  static void _releaseAll(Iterable<OrtTensor> tensors) {
    for (final tensor in tensors) {
      tensor.release();
    }
  }
}

/// Loads the translator, runs one piece of text, and frees the weights.
///
/// Tries a background isolate so the screen can keep painting. If that isolate
/// cannot load the native runtime, the same work runs on the caller.
Future<String> translateOnPhone({
  required String modelDirectory,
  required String text,
  required String languageCode,
}) {
  return _isolateOrHere(modelDirectory, text, languageCode, _translateIsolate);
}

Future<String> translateEnglishOnPhone({
  required String modelDirectory,
  required String text,
  required String languageCode,
}) {
  return _isolateOrHere(
    modelDirectory,
    text,
    languageCode,
    _translateEnglishIsolate,
  );
}

Future<String> _isolateOrHere(
  String modelDirectory,
  String text,
  String languageCode,
  Future<String> Function(String, String, String) body,
) async {
  try {
    return await Isolate.run(
      () => body(modelDirectory, text, languageCode),
    );
  } on IsolateSpawnException {
    return body(modelDirectory, text, languageCode);
  } catch (error) {
    final message = error.toString();
    final runtime =
        message.contains('DynamicLibrary') ||
        message.contains('Failed to load') ||
        message.contains('Unable to load');
    if (!runtime) rethrow;
    return body(modelDirectory, text, languageCode);
  }
}

Future<String> _translateIsolate(
  String modelDirectory,
  String text,
  String languageCode,
) async {
  final language = languageByCode(languageCode);
  if (language == null) {
    throw StateError('Unknown language $languageCode');
  }
  final translator = await IndicTranslator.open(Directory(modelDirectory));
  try {
    return translator.translate(text, language);
  } finally {
    translator.close();
  }
}

Future<String> _translateEnglishIsolate(
  String modelDirectory,
  String text,
  String languageCode,
) async {
  final language = languageByCode(languageCode);
  if (language == null) {
    throw StateError('Unknown language $languageCode');
  }
  final translator = await IndicTranslator.openEnglish(Directory(modelDirectory));
  try {
    return translator.translateFromEnglish(text, language);
  } finally {
    translator.close();
  }
}
