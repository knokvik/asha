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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: AshaShapes.searchRadius,
        border: Border.all(color: const Color(0xFFD1D5DB), width: 1.0),
      ),
      child: Row(
        children: [
          const SizedBox(width: 6),
          const _AnimatedAshaSearchMark(),
          const SizedBox(width: 8),
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
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFF374151),
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
    return AnimatedBuilder(
      key: const Key('animated_search_logo'),
      animation: _controller,
      builder: (context, child) => SizedBox(
        width: 30,
        height: 30,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(30),
              painter: _SearchOrbitPainter(progress: _controller.value),
            ),
            Transform.rotate(
              angle: _controller.value * 2 * 3.14159265359,
              child: child,
            ),
          ],
        ),
      ),
      child: const Image(
        image: AssetImage('assets/branding/favicon.png'),
        width: 22,
        height: 22,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _SearchOrbitPainter extends CustomPainter {
  const _SearchOrbitPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final basePaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final orbitPaint = Paint()
      ..color = const Color(0xFF2D5F47)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.8;
    canvas.drawCircle(size.center(Offset.zero), 13, basePaint);
    canvas.drawArc(
      rect.deflate(2),
      progress * 2 * 3.14159265359,
      1.5,
      false,
      orbitPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SearchOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
