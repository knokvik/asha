import 'package:flutter/material.dart';

import '../../core/voice/confidence_confirmation_dialog.dart';
import '../../core/voice/lexicon_service.dart';
import '../../core/voice/too_noisy_dialog.dart';
import '../../core/voice/vosk_service.dart';

/// Supported field input types for grammar-constrained voice decoding.
enum VoiceFieldType {
  boolean,
  numeric,
  enumeration,
  freeText,
}

/// Accessible clinical form field with an integrated voice input button.
///
/// Features:
/// - Direct speech capture wired to [VoskService] and [LexiconService].
/// - RAM fallback notice for ultra-low-memory devices (Requirement 6.7).
/// - Ambient noise detection triggering [TooNoisyDialog] (Requirement 6.5).
/// - Low confidence (< 0.70) read-back and confirmation via [ConfidenceConfirmationDialog] (Requirement 6.3).
/// - WCAG AA minimum 48×48 dp touch targets on all interactive elements (Requirement 49.4).
class VoiceFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final VoiceFieldType fieldType;
  final List<String>? options;
  final String language;
  final VoskService? voskService;
  final LexiconService? lexiconService;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  const VoiceFormField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.fieldType = VoiceFieldType.freeText,
    this.options,
    this.language = 'en',
    this.voskService,
    this.lexiconService,
    this.onChanged,
    this.readOnly = false,
  });

  @override
  State<VoiceFormField> createState() => _VoiceFormFieldState();
}

class _VoiceFormFieldState extends State<VoiceFormField> {
  bool _isListening = false;

  VoskGrammar _resolveGrammar() {
    switch (widget.fieldType) {
      case VoiceFieldType.boolean:
        return VoskGrammar.yesNo(language: widget.language);
      case VoiceFieldType.numeric:
        return VoskGrammar.numeric(min: 0, max: 200);
      case VoiceFieldType.enumeration:
        return VoskGrammar.enumeration(widget.options ?? []);
      case VoiceFieldType.freeText:
        return VoskGrammar.yesNo(language: widget.language);
    }
  }

  Future<void> _handleVoiceInput() async {
    final vosk = widget.voskService ?? VoskService();

    // 1. RAM Fallback Check (Requirement 6.7)
    if (vosk.isTapOnlyFallback) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voice input disabled for low memory. Please use tap/keyboard entry.',
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isListening = true);

    try {
      final grammar = _resolveGrammar();
      final results = await vosk.startListening(
        language: widget.language,
        grammar: grammar,
      );
      if (results == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice model is not installed. Please use tap entry.')),
          );
        }
        return;
      }
      final raw = await results.first.timeout(const Duration(seconds: 30));
      final result = vosk.parseFinalResult(raw);
      if (result.text.isNotEmpty) {
        await processVoiceResult(
          rawTranscript: result.text,
          confidence: result.confidence,
        );
      }
    } finally {
      if (mounted) setState(() => _isListening = false);
    }
  }

  /// Evaluates transcribed text, handles noise / low-confidence confirmation,
  /// and updates the text field upon acceptance.
  Future<void> processVoiceResult({
    required String rawTranscript,
    required double confidence,
    double rms = 0.0,
  }) async {
    final vosk = widget.voskService ?? VoskService();
    final lexicon = widget.lexiconService ?? LexiconService();

    // 1. Ambient Noise Check (Requirement 6.5)
    if (vosk.isNoiseExcessive(rms)) {
      if (!mounted) return;
      final switchTap = await TooNoisyDialog.show(context);
      if (switchTap == true) {
        // User opted for tap entry
        return;
      }
    }

    // 2. Lexicon Canonicalisation (Requirement 6.2, 6.6)
    final canonicalValue = lexicon.canonicalise(
      rawTranscript,
      language: widget.language,
    );

    // 3. Low-Confidence Confirmation Check (Requirement 6.3)
    if (lexicon.requiresConfirmation(confidence: confidence)) {
      if (!mounted) return;
      final confirmed = await ConfidenceConfirmationDialog.show(
        context,
        spokenText: rawTranscript,
        canonicalValue: canonicalValue,
        confidence: confidence,
      );

      if (confirmed != true) {
        // Rejected by user
        return;
      }
    }

    // 4. Update Controller and notify
    widget.controller.text = canonicalValue;
    widget.onChanged?.call(canonicalValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                readOnly: widget.readOnly,
                onChanged: widget.onChanged,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Dedicated Voice Input Button (>= 48×48 dp)
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: IconButton.filled(
                key: const Key('voice_field_mic_button'),
                icon: Icon(
                  _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: _isListening
                      ? Colors.red.shade700
                      : theme.colorScheme.primary,
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.all(12),
                ),
                tooltip: 'Speak to fill field',
                onPressed: _handleVoiceInput,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
