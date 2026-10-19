import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

/// Dolphin hears the recording. Piper reads English, or Hindi when the worker asks in Hindi.
///
/// Each call loads one model and frees it before returning, so the translator
/// is not in memory at the same time.
class SpeechEngine {
  static String transcribe({
    required String wavPath,
    required String modelPath,
    required String tokensPath,
  }) {
    final recognizer = sherpa.OfflineRecognizer(
      sherpa.OfflineRecognizerConfig(
        model: sherpa.OfflineModelConfig(
          dolphin: sherpa.OfflineDolphinModelConfig(model: modelPath),
          tokens: tokensPath,
          numThreads: 2,
          debug: false,
          provider: 'cpu',
        ),
      ),
    );
    try {
      final wave = sherpa.readWave(wavPath);
      if (wave.samples.isEmpty) {
        throw SpeechException('The recording could not be read. Speak again.');
      }
      final stream = recognizer.createStream();
      try {
        stream.acceptWaveform(
          samples: wave.samples,
          sampleRate: wave.sampleRate,
        );
        recognizer.decode(stream);
        return cleanHeardText(recognizer.getResult(stream).text);
      } finally {
        stream.free();
      }
    } finally {
      recognizer.free();
    }
  }

  static void speakToFile({
    required String text,
    required String modelPath,
    required String tokensPath,
    required String dataDir,
    required String destPath,
  }) {
    final tts = sherpa.OfflineTts(
      sherpa.OfflineTtsConfig(
        model: sherpa.OfflineTtsModelConfig(
          vits: sherpa.OfflineTtsVitsModelConfig(
            model: modelPath,
            tokens: tokensPath,
            dataDir: dataDir,
          ),
          numThreads: 2,
          debug: false,
          provider: 'cpu',
        ),
      ),
    );
    try {
      final audio = tts.generate(text: text, sid: 0, speed: 1.0);
      if (audio.samples.isEmpty) {
        throw SpeechException('The voice produced no audio.');
      }
      final wrote = sherpa.writeWave(
        filename: destPath,
        samples: audio.samples,
        sampleRate: audio.sampleRate,
      );
      if (!wrote) {
        throw SpeechException('Could not save the spoken audio.');
      }
    } finally {
      tts.free();
    }
  }
}

/// Drops a leading language tag Dolphin sometimes prints, such as `<hi>`.
String cleanHeardText(String text) {
  return text.replaceFirst(RegExp(r'^(<[^>]+>\s*)+'), '').trim();
}

class SpeechException implements Exception {
  SpeechException(this.message);

  final String message;

  @override
  String toString() => message;
}
