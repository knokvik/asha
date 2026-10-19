import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tts_service.dart';

/// Tap-to-hear audio prompt widget available on form fields and clinical screens.
///
/// Features:
/// - Speaks the configured prompt or clinical finding via [TtsService].
/// - Supports family-facing explanation toggle (Requirement 7.4).
/// - Adheres to WCAG AA 48×48 dp minimum touch target standards.
/// Requirements: 7.1, 7.3, 7.4
class TapToHearButton extends ConsumerStatefulWidget {
  final String text;
  final String? familyExplanation;
  final String language;
  final String? clipId;
  final String? tooltip;

  const TapToHearButton({
    super.key,
    required this.text,
    this.familyExplanation,
    this.language = 'en',
    this.clipId,
    this.tooltip,
  });

  @override
  ConsumerState<TapToHearButton> createState() => _TapToHearButtonState();
}

class _TapToHearButtonState extends ConsumerState<TapToHearButton> {
  bool _isPlaying = false;
  bool _isFamilyFacing = false;

  Future<void> _handleAudioTap() async {
    final tts = ref.read(ttsServiceProvider);

    if (_isPlaying) {
      await tts.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    final speechText = _isFamilyFacing && widget.familyExplanation != null
        ? widget.familyExplanation!
        : widget.text;

    setState(() => _isPlaying = true);
    try {
      await tts.speak(
        text: speechText,
        language: widget.language,
        clipId: widget.clipId,
      );
    } finally {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Speaker button with >= 48x48 dp touch target
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: IconButton(
            key: const Key('tap_to_hear_speaker_button'),
            icon: Icon(
              _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
              color: _isPlaying ? theme.colorScheme.primary : Colors.grey.shade700,
              size: 26,
            ),
            tooltip: widget.tooltip ?? 'Tap to listen',
            onPressed: _handleAudioTap,
          ),
        ),
        if (widget.familyExplanation != null)
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: TextButton.icon(
              key: const Key('family_mode_toggle_button'),
              icon: Icon(
                _isFamilyFacing ? Icons.family_restroom : Icons.person,
                size: 18,
                color: _isFamilyFacing ? Colors.orange.shade800 : Colors.grey.shade700,
              ),
              label: Text(
                _isFamilyFacing ? 'Family View' : 'Clinician View',
                style: TextStyle(
                  fontSize: 12,
                  color: _isFamilyFacing ? Colors.orange.shade800 : Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                setState(() => _isFamilyFacing = !_isFamilyFacing);
              },
            ),
          ),
      ],
    );
  }
}
