import 'package:flutter/material.dart';

/// Modal dialog presented when Vosk ASR confidence is below threshold (< 0.70).
///
/// Reads the interpreted value back in audio/text and requires explicit
/// confirm/reject confirmation before the value is accepted into clinical fields.
///
/// Adheres to WCAG AA 48×48 dp minimum touch target standards.
/// Requirements: 6.3
class ConfidenceConfirmationDialog extends StatefulWidget {
  final String spokenText;
  final String canonicalValue;
  final double confidence;
  final Future<void> Function()? onPlayAudio;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;

  const ConfidenceConfirmationDialog({
    super.key,
    required this.spokenText,
    required this.canonicalValue,
    required this.confidence,
    this.onPlayAudio,
    this.onConfirm,
    this.onReject,
  });

  /// Displays the confirmation dialog and returns:
  /// - `true` if confirmed.
  /// - `false` if rejected.
  /// - `null` if dismissed.
  static Future<bool?> show(
    BuildContext context, {
    required String spokenText,
    required String canonicalValue,
    required double confidence,
    Future<void> Function()? onPlayAudio,
    VoidCallback? onConfirm,
    VoidCallback? onReject,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ConfidenceConfirmationDialog(
        spokenText: spokenText,
        canonicalValue: canonicalValue,
        confidence: confidence,
        onPlayAudio: onPlayAudio,
        onConfirm: onConfirm,
        onReject: onReject,
      ),
    );
  }

  @override
  State<ConfidenceConfirmationDialog> createState() =>
      _ConfidenceConfirmationDialogState();
}

class _ConfidenceConfirmationDialogState
    extends State<ConfidenceConfirmationDialog> {
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Auto-readback interpreted value via audio on dialog presentation
    _triggerAudioPlayback();
  }

  Future<void> _triggerAudioPlayback() async {
    if (widget.onPlayAudio != null) {
      setState(() => _isPlaying = true);
      try {
        await widget.onPlayAudio!();
      } finally {
        if (mounted) setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidencePercent = (widget.confidence * 100).round();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.record_voice_over_rounded,
              color: Colors.blue.shade900,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Confirm Voice Input',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Speech recognition confidence was $confidencePercent%. Please confirm if this is correct:',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          // Interpreted Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Spoken:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.spokenText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Detected:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.canonicalValue,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Audio playback action
          if (widget.onPlayAudio != null)
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: TextButton.icon(
                  key: const Key('rehear_audio_button'),
                  icon: Icon(
                    _isPlaying ? Icons.volume_up : Icons.replay,
                    size: 20,
                  ),
                  label: Text(_isPlaying ? 'Playing...' : 'Tap to hear again'),
                  onPressed: _isPlaying ? null : _triggerAudioPlayback,
                ),
              ),
            ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        // Reject / Try Again button (>= 48x48 dp)
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 100),
          child: OutlinedButton(
            key: const Key('reject_voice_button'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(100, 48),
            ),
            onPressed: () {
              Navigator.of(context).pop(false);
              widget.onReject?.call();
            },
            child: const Text('Reject / No'),
          ),
        ),
        const SizedBox(width: 8),
        // Confirm button (>= 48x48 dp)
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 120),
          child: ElevatedButton(
            key: const Key('confirm_voice_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(120, 48),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
              widget.onConfirm?.call();
            },
            child: const Text('Confirm / Yes'),
          ),
        ),
      ],
    );
  }
}
