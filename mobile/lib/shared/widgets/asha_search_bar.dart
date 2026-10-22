import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Tactile Search Pill with the original animated ASHA symbol, Voice, and Clear shortcuts.
class AshaSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onVoicePressed;
  final VoidCallback? onScanPressed;
  final VoidCallback? onClear;
  final VoidCallback? onTap;
  final String hintText;
  final bool autofocus;

  const AshaSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onVoicePressed,
    this.onScanPressed,
    this.onClear,
    this.onTap,
    this.hintText = 'Search beneficiaries, ABHA, phone...',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: AshaShapes.searchRadius,
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Color(0xFF15803D),
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              readOnly: onTap != null,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                fontSize: 15,
                color: AshaColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.cancel,
                color: AshaColors.textMuted,
                size: 20,
              ),
              tooltip: 'Clear search',
              onPressed: () {
                controller.clear();
                if (onChanged != null) onChanged!('');
                if (onClear != null) onClear!();
              },
            ),
          if (onVoicePressed != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                icon: const Icon(
                  Icons.mic,
                  color: AshaColors.primary,
                  size: 22,
                ),
                tooltip: 'Voice Search',
                onPressed: onVoicePressed,
              ),
            ),
          if (onScanPressed != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: AshaColors.primary,
                  size: 22,
                ),
                tooltip: 'Scan QR / ABHA',
                onPressed: onScanPressed,
              ),
            ),
        ],
      ),
    );
  }
}

class _AnimatedAshaSearchMark extends StatelessWidget {
  const _AnimatedAshaSearchMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: Key('animated_search_logo'),
      width: 0,
      height: 0,
    );
  }
}
