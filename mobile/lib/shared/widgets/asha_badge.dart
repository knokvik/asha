import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

enum AshaBadgeType {
  highRisk,
  warning,
  normal,
  teleConsult,
  offlineEncrypted,
  synced,
  neutral,
}

/// Semantic risk, status, and synchronization badge component.
class AshaBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AshaBadgeType type;
  final bool isFilled;
  final EdgeInsetsGeometry padding;

  const AshaBadge({
    super.key,
    required this.label,
    this.icon,
    this.type = AshaBadgeType.neutral,
    this.isFilled = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  factory AshaBadge.highRisk({required String label, IconData? icon, bool isFilled = false}) {
    return AshaBadge(
      label: label,
      icon: icon ?? Icons.error_outline,
      type: AshaBadgeType.highRisk,
      isFilled: isFilled,
    );
  }

  factory AshaBadge.warning({required String label, IconData? icon, bool isFilled = false}) {
    return AshaBadge(
      label: label,
      icon: icon ?? Icons.warning_amber_rounded,
      type: AshaBadgeType.warning,
      isFilled: isFilled,
    );
  }

  factory AshaBadge.normal({required String label, IconData? icon, bool isFilled = false}) {
    return AshaBadge(
      label: label,
      icon: icon ?? Icons.check_circle_outline,
      type: AshaBadgeType.normal,
      isFilled: isFilled,
    );
  }

  factory AshaBadge.offline({String label = 'Offline • AES-256'}) {
    return AshaBadge(
      label: label,
      icon: Icons.lock_outline,
      type: AshaBadgeType.offlineEncrypted,
      isFilled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    Color bgColor;
    Color textColor;

    switch (type) {
      case AshaBadgeType.highRisk:
        baseColor = AshaColors.alertHighRisk;
        bgColor = isFilled ? baseColor : baseColor.withValues(alpha: 0.12);
        textColor = isFilled ? Colors.white : const Color(0xFFC53030);
        break;
      case AshaBadgeType.warning:
        baseColor = AshaColors.warningPending;
        bgColor = isFilled ? baseColor : baseColor.withValues(alpha: 0.14);
        textColor = isFilled ? Colors.white : const Color(0xFFB45309);
        break;
      case AshaBadgeType.normal:
        baseColor = AshaColors.vitalNormal;
        bgColor = isFilled ? baseColor : baseColor.withValues(alpha: 0.12);
        textColor = isFilled ? Colors.white : const Color(0xFF15803D);
        break;
      case AshaBadgeType.teleConsult:
        baseColor = AshaColors.teleConsultBlue;
        bgColor = isFilled ? baseColor : baseColor.withValues(alpha: 0.12);
        textColor = isFilled ? Colors.white : const Color(0xFF1D4ED8);
        break;
      case AshaBadgeType.offlineEncrypted:
        baseColor = AshaColors.primary;
        bgColor = isFilled ? const Color(0xFF1E4231) : AshaColors.primaryLight;
        textColor = Colors.white;
        break;
      case AshaBadgeType.synced:
        baseColor = AshaColors.leafMint;
        bgColor = isFilled ? baseColor : const Color(0xFFE8FAF0);
        textColor = const Color(0xFF0F7A3C);
        break;
      case AshaBadgeType.neutral:
        baseColor = AshaColors.borderSubtle;
        bgColor = AshaColors.surfaceMuted;
        textColor = AshaColors.textSecondary;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isFilled ? Colors.transparent : baseColor.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AshaTypography.riskBadge.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
