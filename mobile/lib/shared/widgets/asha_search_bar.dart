import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// Tactile Search Pill with an animated ASHA mark, Voice, and Clear shortcuts.
class AshaSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onVoicePressed;
  final VoidCallback? onScanPressed;
  final VoidCallback? onClear;
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
    this.hintText = 'Search beneficiaries, ABHA, phone...',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: AshaShapes.searchRadius,
        border: Border.all(color: AshaColors.borderSubtle, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(18, 26, 21, 0.04),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const _AnimatedAshaSearchMark(),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                fontSize: 15,
                color: AshaColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: AshaColors.textMuted,
                  fontSize: 14,
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

class _AnimatedAshaSearchMark extends StatefulWidget {
  const _AnimatedAshaSearchMark();

  @override
  State<_AnimatedAshaSearchMark> createState() =>
      _AnimatedAshaSearchMarkState();
}

class _AnimatedAshaSearchMarkState extends State<_AnimatedAshaSearchMark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      key: const Key('animated_search_logo'),
      turns: _controller,
      child: const Image(
        image: AssetImage('assets/branding/favicon.png'),
        width: 24,
        height: 24,
        fit: BoxFit.contain,
      ),
    );
  }
}
