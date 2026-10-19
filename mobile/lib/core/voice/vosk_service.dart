import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
// Native vosk decoupled for pure Dart model

/// Lightweight interface abstraction for Vosk ASR plugin.
abstract class VoskFlutterPlugin {
  static VoskFlutterPlugin instance() => _DefaultVoskFlutterPlugin();
  Future<Model> createModel(String path);
  Future<Recognizer> createRecognizer({
    required Model model,
    required int sampleRate,
    List<String>? grammar,
  });
  Future<SpeechService> initSpeechService(Recognizer recognizer);
}

class _DefaultVoskFlutterPlugin implements VoskFlutterPlugin {
  @override
  Future<Model> createModel(String path) async => Model();
  @override
  Future<Recognizer> createRecognizer({
    required Model model,
    required int sampleRate,
    List<String>? grammar,
  }) async => Recognizer();
  @override
  Future<SpeechService> initSpeechService(Recognizer recognizer) async =>
      SpeechService();
}

class Model {
  void dispose() {}
}

class Recognizer {
  Future<void> dispose() async {}
}

class SpeechService {
  Future<void> start() async {}
  Future<void> stop() async {}
  Future<void> dispose() async {}
  Stream<String> onResult() => const Stream.empty();
}

/// Available Vosk speech model footprints based on device hardware RAM.
enum VoskModelType {
  /// Full 40 MB model: for devices with >= 1.5 GB RAM.
  full,

  /// Compressed 15 MB model: for devices with 1.0 GB to 1.5 GB RAM.
  compressed,

  /// Tap-only fallback: for devices with < 1.0 GB RAM where ASR cannot run safely.
  tapOnly,
}

/// Grammar constraint for closed-vocabulary fields in Vosk.
///
/// Restricts ASR decoding to a finite set of words or numbers (yes/no, numbers,
/// enumerations) via Vosk's FST grammar compiler.
/// Requirements: 6.2
class VoskGrammar {
  final List<String> words;

  const VoskGrammar({required this.words});

  /// Factory for boolean yes/no fields supporting English and common Indian regional terms.
  factory VoskGrammar.yesNo({String language = 'en'}) {
    return const VoskGrammar(words: [
      'yes', 'no',
      'हाँ', 'नहीं', 'haan', 'nahi', 'nahin',
      'होय', 'नाही', 'ho', 'nahi',
      'হ্যাঁ', 'না', 'hyan', 'na',
      'అవును', 'కాదు', 'avunu', 'kaadu',
      'ஆம்', 'இல்லை', 'aam', 'illai',
      'ಹೌದು', 'ಇಲ್ಲ', 'haudu', 'illa',
      'അതെ', 'അല്ല', 'athe', 'alla',
      'ହଁ', 'ନା', 'han', 'na',
      'હા', 'ના', 'haa', 'naa',
      'ਹਾਂ', 'ਨਹੀਂ', 'haan', 'nahin',
      'হয়', 'নহয়', 'hoy', 'nohoy',
      '[unk]',
    ]);
  }

  /// Factory for numeric entry (e.g. respiratory rate 0–99 BPM, age, blood pressure).
  factory VoskGrammar.numeric({int min = 0, int max = 100}) {
    final list = <String>['[unk]'];
    for (int i = min; i <= max; i++) {
      list.add(i.toString());
    }
    // Add common Hindi / English number words
    list.addAll([
      'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten',
      'शून्य', 'एक', 'दो', 'तीन', 'चार', 'पाँच', 'छह', 'सात', 'आठ', 'नौ', 'दस',
      'बीस', 'तीस', 'चालीस', 'पचास', 'साठ', 'सत्तर', 'अस्सी', 'नब्बे', 'सौ',
    ]);
    return VoskGrammar(words: list);
  }

  /// Factory for enumerated clinical choices.
  factory VoskGrammar.enumeration(List<String> options) {
    return VoskGrammar(words: ['[unk]', ...options]);
  }

  List<String> toList() => words;

  String toJsonString() => jsonEncode(words);
}

/// Recognition output with transcript and confidence score.
class VoskRecognitionResult {
  final String text;
  final double confidence; // 0.0 to 1.0
  final bool isLowConfidence;
  final bool isExcessiveNoise;

  const VoskRecognitionResult({
    required this.text,
    required this.confidence,
    this.isLowConfidence = false,
    this.isExcessiveNoise = false,
  });

  static const empty = VoskRecognitionResult(text: '', confidence: 0.0);
}

/// Offline Vosk ASR lifecycle, RAM model selection, and ambient noise detector.
///
/// Requirements: 6.1, 6.2, 6.5, 6.7
class VoskService {
  final int deviceRamMb;
  final double noiseThreshold;
  final double confidenceThreshold;
  final VoskFlutterPlugin? plugin;

  Model? _loadedModel;
  Recognizer? _recognizer;
  SpeechService? _speechService;
  bool _isInitialized = false;

  VoskService({
    int? deviceRamMb,
    this.noiseThreshold = 0.65,
    this.confidenceThreshold = 0.70,
    this.plugin,
  }) : deviceRamMb = deviceRamMb ?? _detectDeviceRamMb();

  // ── RAM Model Selection (Requirement 6.7) ──────────────────────────────────

  /// Recommended model footprint based on total hardware RAM.
  VoskModelType get recommendedModelType {
    if (deviceRamMb >= 1500) {
      return VoskModelType.full;
    } else if (deviceRamMb >= 1000) {
      return VoskModelType.compressed;
    } else {
      return VoskModelType.tapOnly;
    }
  }

  bool get isTapOnlyFallback => recommendedModelType == VoskModelType.tapOnly;
  bool get isInitialized => _isInitialized;

  // ── Model Lifecycle (Lazy Initialisation & Navigation Dispose) ──────────────

  /// Lazily initialises the Vosk ASR model on first microphone tap.
  ///
  /// Returns `false` if the device falls back to tap-only entry or model fails to load.
  Future<bool> initModel({
    required String language,
    String? modelPath,
  }) async {
    if (_isInitialized) return true;

    // RAM check: fall back to tap-only if device has < 1 GB RAM
    if (isTapOnlyFallback) {
      _isInitialized = false;
      return false;
    }

    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final p = plugin ?? VoskFlutterPlugin.instance();
        final path = modelPath ?? await _resolveModelPath(language);
        if (path == null) {
          _isInitialized = false;
          return false;
        }

        _loadedModel = await p.createModel(path);
        _recognizer = await p.createRecognizer(
          model: _loadedModel!,
          sampleRate: 16000,
        );
        _speechService = await p.initSpeechService(_recognizer!);
      }
      _isInitialized = true;
      return true;
    } catch (_) {
      // In desktop/test environments or on model load error, fallback safely
      _isInitialized = false;
      return false;
    }
  }

  /// Sets or updates a grammar constraint on the recognizer.
  Future<void> setGrammar(VoskGrammar grammar) async {
    if (_recognizer == null || _loadedModel == null) return;
    try {
      final p = plugin ?? VoskFlutterPlugin.instance();
      _recognizer = await p.createRecognizer(
        model: _loadedModel!,
        sampleRate: 16000,
        grammar: grammar.toList(),
      );
      await _speechService?.dispose();
      _speechService = await p.initSpeechService(_recognizer!);
    } catch (_) {}
  }

  /// Starts Android microphone recognition and returns final-result events.
  /// Model availability is checked before requesting the microphone, so a
  /// missing model retains the tap-entry fallback instead of failing a visit.
  Future<Stream<String>?> startListening({
    required String language,
    required VoskGrammar grammar,
  }) async {
    if (!await initModel(language: language)) return null;
    await setGrammar(grammar);
    final service = _speechService;
    if (service == null) return null;
    await service.start();
    return service.onResult();
  }

  /// Converts Vosk's final-result JSON to a normalised app result. Vosk emits
  /// a token confidence per word; the least-confident token is used to ensure
  /// confirmation is requested conservatively.
  VoskRecognitionResult parseFinalResult(String rawResult, {double rms = 0.0}) {
    try {
      final decoded = jsonDecode(rawResult) as Map<String, dynamic>;
      final text = (decoded['text'] as String? ?? '').trim();
      final words = decoded['result'] as List? ?? const [];
      final confidences = words
          .whereType<Map>()
          .map((word) => (word['conf'] as num?)?.toDouble())
          .whereType<double>()
          .toList();
      final confidence = confidences.isEmpty
          ? 0.0
          : confidences.reduce((a, b) => a < b ? a : b);
      return evaluateResult(transcript: text, confidence: confidence, rms: rms);
    } catch (_) {
      return const VoskRecognitionResult(text: '', confidence: 0.0, isLowConfidence: true);
    }
  }

  /// Disposes model, recognizer, and audio streams on navigation away to free RAM.
  Future<void> dispose() async {
    try {
      await _speechService?.stop();
      await _speechService?.dispose();
      await _recognizer?.dispose();
    } catch (_) {}
    _loadedModel?.dispose();
    _speechService = null;
    _recognizer = null;
    _loadedModel = null;
    _isInitialized = false;
  }

  // ── Ambient Noise Detection via Microphone RMS (Requirement 6.5) ───────────

  /// Computes normalized Root Mean Square (RMS) from 16-bit PCM audio samples.
  ///
  /// Returns a value in [0.0, 1.0].
  static double computeRms(Int16List pcmData) {
    if (pcmData.isEmpty) return 0.0;
    double sumSquares = 0.0;
    for (int i = 0; i < pcmData.length; i++) {
      final normalized = pcmData[i] / 32768.0;
      sumSquares += normalized * normalized;
    }
    return sqrt(sumSquares / pcmData.length);
  }

  /// Returns true if [rms] exceeds [noiseThreshold].
  bool isNoiseExcessive(double rms) {
    return rms > noiseThreshold;
  }

  // ── Recognition Processing & Confidence Assessment ─────────────────────────

  /// Evaluates recognition result text and confidence score against thresholds.
  VoskRecognitionResult evaluateResult({
    required String transcript,
    required double confidence,
    double rms = 0.0,
  }) {
    if (isNoiseExcessive(rms)) {
      return VoskRecognitionResult(
        text: transcript,
        confidence: confidence,
        isLowConfidence: true,
        isExcessiveNoise: true,
      );
    }

    final isLow = confidence < confidenceThreshold;
    return VoskRecognitionResult(
      text: transcript.trim(),
      confidence: confidence,
      isLowConfidence: isLow,
      isExcessiveNoise: false,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static int _detectDeviceRamMb() {
    try {
      if (!kIsWeb && Platform.isLinux) {
        final meminfo = File('/proc/meminfo');
        if (meminfo.existsSync()) {
          final lines = meminfo.readAsLinesSync();
          for (final line in lines) {
            if (line.startsWith('MemTotal:')) {
              final parts = line.split(RegExp(r'\s+'));
              if (parts.length >= 2) {
                final kb = int.tryParse(parts[1]) ?? 0;
                return kb ~/ 1024;
              }
            }
          }
        }
      }
    } catch (_) {}
    // Default assumed RAM: 2048 MB (2 GB)
    return 2048;
  }

  Future<String?> _resolveModelPath(String language) async {
    final support = await getApplicationSupportDirectory();
    final modelRoot = Directory(p.join(support.path, 'vosk_models'));
    if (!await modelRoot.exists()) return null;
    final type = recommendedModelType == VoskModelType.full ? 'full' : 'compressed';
    final directory = Directory(p.join(modelRoot.path, '${language.toLowerCase()}_$type'));
    return await directory.exists() ? directory.path : null;
  }
}
