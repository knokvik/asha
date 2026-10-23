import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// Clean, modern container for clinical form sections with rounded borders and subtle shadows.
class ClinicalFormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? iconColor;

  const ClinicalFormCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AshaColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (iconColor ?? AshaColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: iconColor ?? AshaColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AshaColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// Standardized clean switch tile with minimal padding and clear labels.
class ClinicalSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDanger;

  const ClinicalSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: value && isDanger ? Colors.red.shade50 : AshaColors.screenBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value && isDanger ? Colors.red.shade300 : AshaColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: value && isDanger ? Colors.red.shade900 : AshaColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: value && isDanger ? Colors.red.shade700 : AshaColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: isDanger ? Colors.red.shade700 : AshaColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Modern primary button for completing visits or triggering referrals.
class ClinicalSubmitButton extends StatelessWidget {
  final String label;
  final bool isSaving;
  final VoidCallback? onPressed;
  final bool isEmergency;

  const ClinicalSubmitButton({
    super.key,
    required this.label,
    required this.isSaving,
    required this.onPressed,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isEmergency ? const Color(0xFFDC2626) : AshaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: isSaving ? null : onPressed,
        child: isSaving
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}
