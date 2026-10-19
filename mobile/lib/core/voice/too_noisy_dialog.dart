import 'package:flutter/material.dart';

/// Modal dialog surfaced when ambient noise RMS exceeds the configurable threshold.
///
/// Notifies the ASHA of excessive ambient noise and offers tap-based entry as
/// an accessible alternative to voice input.
///
/// Adheres to WCAG AA 48×48 dp minimum touch target standards.
/// Requirements: 6.5
class TooNoisyDialog extends StatelessWidget {
  final VoidCallback? onTapEntry;
  final VoidCallback? onRetry;

  const TooNoisyDialog({
    super.key,
    this.onTapEntry,
    this.onRetry,
  });

  /// Displays the [TooNoisyDialog] and returns:
  /// - `true` if tap-based entry was selected.
  /// - `false` if retry was selected.
  /// - `null` if dismissed.
  static Future<bool?> show(
    BuildContext context, {
    VoidCallback? onTapEntry,
    VoidCallback? onRetry,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TooNoisyDialog(
        onTapEntry: onTapEntry,
        onRetry: onRetry,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hearing_disabled_rounded,
              color: Colors.amber.shade900,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'High Background Noise',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The ambient noise in your surroundings is too high for accurate voice recognition.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          SizedBox(height: 12),
          Text(
            'You can switch to tap-based entry or move to a quieter area and try again.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        // Secondary action: Try Again
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 100),
          child: OutlinedButton.icon(
            key: const Key('too_noisy_retry_button'),
            icon: const Icon(Icons.mic, size: 20),
            label: const Text('Try Again'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(100, 48),
            ),
            onPressed: () {
              Navigator.of(context).pop(false);
              onRetry?.call();
            },
          ),
        ),
        const SizedBox(width: 8),
        // Primary action: Use Tap Entry
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 140),
          child: ElevatedButton.icon(
            key: const Key('too_noisy_tap_entry_button'),
            icon: const Icon(Icons.touch_app, size: 20),
            label: const Text('Use Tap Entry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(140, 48),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
              onTapEntry?.call();
            },
          ),
        ),
      ],
    );
  }
}
