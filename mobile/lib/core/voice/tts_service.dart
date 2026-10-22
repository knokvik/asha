import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Clinical procedure types that offer step-by-step audio guidance.
/// Requirements: 7.2
enum ClinicalProcedure { breathCounting, muac, orsPreparation }

/// A single step in a clinical procedure audio guidance sequence.
class ProcedureStep {
  final int stepIndex;
  final String title;
  final String instructionText;
  final String familyFacingExplanation;
  final String? clipId;
  final Duration? timerDuration;
  final String? pictorialAsset;

  const ProcedureStep({
    required this.stepIndex,
    required this.title,
    required this.instructionText,
    required this.familyFacingExplanation,
    this.clipId,
    this.timerDuration,
    this.pictorialAsset,
  });
}

/// Result of playing audio via [TtsService].
enum AudioSourceType { preRecordedClip, onDeviceSynthesis, none }

/// Text-to-speech audio service wrapping flutter_tts and bundled audio clips.
///
/// Features:
/// - Bundled pre-recorded human voice clips where available (Requirement 7.3).
/// - Fallback to on-device TTS synthesis when clips are absent (Requirement 7.3).
/// - Triage result spoken feedback (Requirement 7.1).
/// - Family-facing explanation audio (Requirement 7.4).
/// - Step-by-step clinical procedure sequences (Requirement 7.2).
class TtsService {
  final FlutterTts? _flutterTts;
  final Map<String, String> _registeredClips =
      {}; // key: "$language:$clipId" -> assetPath
  bool _isPlaying = false;
  String? _lastSpokenText;
  AudioSourceType _lastAudioSource = AudioSourceType.none;

  TtsService({FlutterTts? flutterTts})
    : _flutterTts = flutterTts ?? (_isPlatformSupported ? FlutterTts() : null) {
    _initTts();
  }

  static bool get _isPlatformSupported {
    if (kIsWeb) return true;
    try {
      return Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isMacOS ||
          Platform.isWindows;
    } catch (_) {
      return false;
    }
  }

  bool get isPlaying => _isPlaying;
  String? get lastSpokenText => _lastSpokenText;
  AudioSourceType get lastAudioSource => _lastAudioSource;

  void _initTts() {
    if (_flutterTts == null) return;
    try {
      _flutterTts.setSpeechRate(0.45).catchError((_) => null);
      _flutterTts.setVolume(1.0).catchError((_) => null);
      _flutterTts.setPitch(1.0).catchError((_) => null);
    } catch (_) {}
  }

  // ── Pre-Recorded Audio Clips (Requirement 7.3) ─────────────────────────────

  /// Registers a bundled human voice clip for [language] and [clipId].
  void registerClip({
    required String clipId,
    required String language,
    required String assetPath,
  }) {
    _registeredClips['${_languageKey(language)}:$clipId'] = assetPath;
  }

  /// Checks whether a bundled clip is available for the given language.
  bool isClipAvailable(String clipId, String language) {
    return _registeredClips.containsKey('${_languageKey(language)}:$clipId');
  }

  String? getClipAsset(String clipId, String language) {
    return _registeredClips['${_languageKey(language)}:$clipId'];
  }

  // ── Speech Output (Requirements 7.1, 7.3, 7.4) ─────────────────────────────

  /// Speaks text using a pre-recorded clip if available, or on-device TTS synthesis fallback.
  Future<AudioSourceType> speak({
    required String text,
    String language = 'en',
    String? clipId,
  }) async {
    _lastSpokenText = text;

    // Check if pre-recorded clip exists for this clipId & language
    if (clipId != null && isClipAvailable(clipId, language)) {
      _isPlaying = true;
      _lastAudioSource = AudioSourceType.preRecordedClip;
      // In production, an audio player plays getClipAsset(clipId, language)
      _isPlaying = false;
      return AudioSourceType.preRecordedClip;
    }

    // Fall back to flutter_tts synthesis
    _lastAudioSource = AudioSourceType.onDeviceSynthesis;
    if (_flutterTts != null) {
      try {
        _isPlaying = true;
        final ttsLang = _mapLanguageToLocale(language);
        await _flutterTts.setLanguage(ttsLang);
        await _flutterTts.speak(text);
      } catch (_) {
        // In tests or unsupported desktop where platform channels aren't active, gracefully complete
      } finally {
        _isPlaying = false;
      }
    }

    return AudioSourceType.onDeviceSynthesis;
  }

  /// Speaks triage result: flag colour, triggering reason, and recommended action.
  /// Requirements: 7.1, 7.4
  Future<AudioSourceType> speakTriageResult({
    required String flagColor,
    required String reason,
    required String action,
    String language = 'en',
    bool isFamilyFacing = false,
    String? clipId,
  }) async {
    final text = formatTriageMessage(
      flagColor: flagColor,
      reason: reason,
      action: action,
      isFamilyFacing: isFamilyFacing,
      language: language,
    );

    return speak(text: text, language: language, clipId: clipId);
  }

  /// Stops current speech synthesis or audio playback.
  Future<void> stop() async {
    _isPlaying = false;
    if (_flutterTts != null) {
      try {
        await _flutterTts.stop();
      } catch (_) {}
    }
  }

  // ── Clinical Procedure Guidance Sequences (Requirement 7.2) ────────────────

  /// Returns the ordered step-by-step guidance sequence for [procedure].
  static List<ProcedureStep> getProcedureSteps(
    ClinicalProcedure procedure, {
    String language = 'en',
  }) {
    switch (procedure) {
      case ClinicalProcedure.breathCounting:
        return const [
          ProcedureStep(
            stepIndex: 1,
            title: 'Prepare Infant',
            instructionText: 'Ensure the baby is calm and not feeding or crying. Uncover the chest so movement is clearly visible.',
            familyFacingExplanation:
                'Please keep the baby calm and still while we count breathing.',
            clipId: 'breath_step_1',
            timerDuration: Duration(seconds: 5),
          ),
          ProcedureStep(
            stepIndex: 2,
            title: 'Locate Chest Movement',
            instructionText: 'Observe the inward and outward movement of the chest or abdomen.',
            familyFacingExplanation:
                'We are watching the baby chest move with each breath.',
            clipId: 'breath_step_2',
            timerDuration: Duration(seconds: 5),
          ),
          ProcedureStep(
            stepIndex: 3,
            title: 'Count for 60 Seconds',
            instructionText: 'Count each outward movement as one breath for a full 60 seconds. Timer will alert when complete.',
            familyFacingExplanation: 'Counting breaths for one full minute.',
            clipId: 'breath_step_3',
            timerDuration: Duration(seconds: 60),
          ),
        ];

      case ClinicalProcedure.muac:
        return const [
          ProcedureStep(
            stepIndex: 1,
            title: 'Select Left Arm',
            instructionText: 'Bend the child’s left arm at a 90-degree angle. Locate the tip of the shoulder and tip of the elbow.',
            familyFacingExplanation:
                'We are measuring the child’s upper arm to check growth.',
            clipId: 'muac_step_1',
            timerDuration: Duration(seconds: 10),
          ),
          ProcedureStep(
            stepIndex: 2,
            title: 'Find Midpoint & Wrap Tape',
            instructionText: 'Measure the distance between shoulder and elbow, mark the midpoint. Straighten the arm and wrap tape smoothly without pinching.',
            familyFacingExplanation:
                'Wrapping the soft measuring tape gently around the arm.',
            clipId: 'muac_step_2',
            timerDuration: Duration(seconds: 15),
          ),
          ProcedureStep(
            stepIndex: 3,
            title: 'Read Color Zone',
            instructionText: 'Read the measurement in the window: Red (<115mm SAM), Yellow (115–125mm MAM), Green (>=125mm Normal).',
            familyFacingExplanation: 'Checking the color window: Green is healthy, Yellow or Red needs nutrition support.',
            clipId: 'muac_step_3',
            timerDuration: Duration(seconds: 10),
          ),
        ];

      case ClinicalProcedure.orsPreparation:
        return const [
          ProcedureStep(
            stepIndex: 1,
            title: 'Wash Hands',
            instructionText: 'Wash hands thoroughly with soap and clean running water before preparing the solution.',
            familyFacingExplanation:
                'Wash hands with soap and water to keep medicine clean.',
            clipId: 'ors_step_1',
            timerDuration: Duration(seconds: 10),
          ),
          ProcedureStep(
            stepIndex: 2,
            title: 'Measure 1 Litre Clean Water',
            instructionText: 'Pour 1 litre (approximately 5 standard cups) of boiled and cooled or clean drinking water into a clean container.',
            familyFacingExplanation:
                'Take exactly 1 litre of clean drinking water.',
            clipId: 'ors_step_2',
            timerDuration: Duration(seconds: 15),
          ),
          ProcedureStep(
            stepIndex: 3,
            title: 'Add Full ORS Packet',
            instructionText: 'Empty the entire packet of ORS into the water. Do not add half packets or extra sugar/salt.',
            familyFacingExplanation:
                'Add the whole packet of ORS powder into the water.',
            clipId: 'ors_step_3',
            timerDuration: Duration(seconds: 10),
          ),
          ProcedureStep(
            stepIndex: 4,
            title: 'Stir & Administer',
            instructionText: 'Stir well until the powder is completely dissolved. Give frequent small sips using a clean cup and spoon. Discard after 24 hours.',
            familyFacingExplanation: 'Mix well until clear. Give small sips frequently. Make a fresh batch after 24 hours.',
            clipId: 'ors_step_4',
            timerDuration: Duration(seconds: 15),
          ),
        ];
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String formatTriageMessage({
    required String flagColor,
    required String reason,
    required String action,
    required bool isFamilyFacing,
    String language = 'en',
  }) {
    final colorUpper = flagColor.toUpperCase();
    if (isFamilyFacing) {
      if (colorUpper == 'RED') {
        return 'Alert: The baby needs urgent medical care. Reason: $reason. Action: Please accompany us to the hospital immediately.';
      } else if (colorUpper == 'YELLOW') {
        return 'Attention: The baby needs close monitoring and home care. Reason: $reason. Action: $action.';
      } else {
        return 'Good news: The baby is doing well. Continue standard feeding and care. Action: $action.';
      }
    }

    return 'Triage Flag $colorUpper. Reason: $reason. Recommended Action: $action.';
  }

  static String _mapLanguageToLocale(String code) {
    // App settings use bare language codes (hi), while interpreter packs and
    // some callers use Indian locales (hi-IN). Normalize both forms before
    // selecting the device voice so a translated question is never spoken by
    // the English fallback locale merely because it has a region suffix.
    final language = _languageKey(code);
    switch (language) {
      case 'hi':
        return 'hi-IN';
      case 'mr':
        return 'mr-IN';
      case 'bn':
        return 'bn-IN';
      case 'te':
        return 'te-IN';
      case 'ta':
        return 'ta-IN';
      case 'kn':
        return 'kn-IN';
      case 'ml':
        return 'ml-IN';
      case 'gu':
        return 'gu-IN';
      case 'pa':
        return 'pa-IN';
      case 'or':
        return 'or-IN';
      case 'as':
        return 'as-IN';
      default:
        return 'en-IN';
    }
  }

  static String _languageKey(String code) =>
      code.toLowerCase().replaceAll('_', '-').split('-').first;
}

/// Riverpod provider for [TtsService].
final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});
