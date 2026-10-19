import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// Tactile clinical card component conforming to the AshaSetu Unified Design System.
/// Provides 18dp rounded corners, subtle border, optional status stripe, and generous touch feedback.
class AshaCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? statusStripeColor;
  final Color? backgroundColor;
  final double borderRadius;
  final BorderSide? border;

  const AshaCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.statusStripeColor,
    this.backgroundColor,
    this.borderRadius = AshaShapes.beneficiaryCardRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = backgroundColor ?? AshaColors.cardSurface;
    final radius = BorderRadius.circular(borderRadius);

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (statusStripeColor != null) {
      content = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: statusStripeColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(borderRadius),
                  bottomLeft: Radius.circular(borderRadius),
                ),
              ),
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: radius,
        border: Border.fromBorderSide(
          border ?? const BorderSide(color: AshaColors.borderSubtle, width: 1.0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(18, 26, 21, 0.03),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: onTap != null
            ? InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: content,
              )
            : content,
      ),
    );
  }
}
