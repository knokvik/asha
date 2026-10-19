import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

enum AshaButtonVariant {
  primary,
  mint,
  outlined,
  danger,
}

/// Large tactile button fulfilling the 54dp min-height & 26dp pill radius requirement.
class AshaPillButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget? icon;
  final String label;
  final AshaButtonVariant variant;
  final bool isLoading;
  final double? width;

  const AshaPillButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.variant = AshaButtonVariant.primary,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    BorderSide? side;

    switch (variant) {
      case AshaButtonVariant.primary:
        bg = AshaColors.primary;
        fg = Colors.white;
        break;
      case AshaButtonVariant.mint:
        bg = AshaColors.leafMint;
        fg = AshaColors.carbonBlack;
        break;
      case AshaButtonVariant.danger:
        bg = AshaColors.alertHighRisk;
        fg = Colors.white;
        break;
      case AshaButtonVariant.outlined:
        bg = Colors.transparent;
        fg = AshaColors.textPrimary;
        side = const BorderSide(color: AshaColors.borderSubtle, width: 1.2);
        break;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      minimumSize: const Size(0, 54),
      shape: const RoundedRectangleBorder(borderRadius: AshaShapes.buttonRadius),
      side: side,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    Widget btn = ElevatedButton(
      style: buttonStyle,
      onPressed: isLoading ? null : onPressed,
      child: child,
    );

    if (width != null) {
      btn = SizedBox(width: width, child: btn);
    }

    return btn;
  }
}
