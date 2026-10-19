# AshaSetu Unified Design System & Styling Guide

> **Single Source of Truth** for UI styling, themes, typography, and component blueprints for the Setu ASHA Worker App.
> Combines the modular, high-velocity multi-service architecture of **Zevoa** with the trusted clinical clarity of **DocSpot**.

---

## 1. Unified Color Tokens

```dart
import 'package:flutter/material.dart';

class AshaColors {
  AshaColors._();

  // Primary Clinical Palette (DocSpot Forest Foundation)
  static const primary = Color(0xFF2D5F47);
  static const primaryDark = Color(0xFF1E4231);
  static const primaryLight = Color(0xFFE5F2EE);

  // Energy & Positive Normal State (Zevoa Mint)
  static const leafMint = Color(0xFF19D96B);
  static const vitalNormal = Color(0xFF16A34A);

  // Triage Risk & Emergency Badges
  static const highRiskAlert = Color(0xFFFF5A36); // High-risk pregnancy, emergency SOS
  static const pendingWarning = Color(0xFFF59E0B); // Overdue immunization, follow-up
  static const teleConsultBlue = Color(0xFF3B82F6); // Telemedicine, MO connect

  // Canvas & Surfaces
  static const screenBackground = Color(0xFFF8F9FA); // Soft glare-free off-white
  static const cardSurface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F5F2);
  static const borderSubtle = Color(0xFFE2E8E4);

  // High-Contrast Deep Charcoal
  static const carbonBlack = Color(0xFF121A15);
  static const textPrimary = Color(0xFF111815);
  static const textSecondary = Color(0xFF5F6B64);
  static const textMuted = Color(0xFF8A968F);
}
```

---

## 2. Unified Typography Scale

```dart
import 'package:flutter/material.dart';

class AshaTypography {
  AshaTypography._();

  static const fontFamily = 'Plus Jakarta Sans';

  static const headlineMedium = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AshaColors.textPrimary,
    letterSpacing: -0.8,
  );

  static const titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AshaColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AshaColors.textPrimary,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AshaColors.textPrimary,
    height: 1.4,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AshaColors.textSecondary,
    height: 1.4,
  );

  static const labelLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const subtitleSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AshaColors.textSecondary,
  );

  static const riskBadge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );
}
```

---

## 3. Shapes & Tactile Targets

- **Primary Action Buttons**: Minimum height `54dp`, pill radius `26dp`.
- **Search Bar**: Pill radius `24dp`, height `50dp` with Voice Record Icon on right.
- **Service Modules Grid**: Rounded rectangular cards `20dp`, 3D/tinted icons with 12sp medium labels.
- **Beneficiary Cards**: `18dp` corner radius, `12dp` padding, subtle 1dp border `#E2E8E4`.
- **Bottom Navigation Dock**: Floating dark pill dock (`#121A15`, radius `28dp`, height `64dp`), active tab in white pill.

---

## 4. Design Guidelines for Future UI Tasks

1. **Zero Style Fragmentation**: Never create a separate theme; all screens (Registration, Triage, Tele-Consult, Home, Household Census) must use `AshaColors`, `AshaTypography`, and `AshaShapes`.
2. **Generous Touch Targets**: All buttons, chips, and cards must have at least 48dp clickable area for rural field work.
3. **Dual Warning Indicators**: Always pair color alerts with text badges and icons (e.g., `🔴 High Risk (Severe Anemia)`).
4. **Offline-First Clarity**: Always display sync badges on cards and headers so workers know if data is cached or uploaded.
