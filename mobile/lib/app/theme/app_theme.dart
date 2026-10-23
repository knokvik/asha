import 'package:flutter/material.dart';

/// Single source of truth for UI styling, themes, typography, and component tokens.
/// Combines the modular, high-velocity multi-service architecture of Zevoa with
/// the trusted clinical clarity of DocSpot for field health workers.
class AshaColors {
  AshaColors._();

  // Primary Clinical Palette (DocSpot Forest Foundation)
  static const primary = Color(0xFF2D5F47);
  static const primaryDark = Color(0xFF1E4231);
  static const primaryLight = Color(0xFFE5F2EE);

  // Energy & Positive Normal State (Zevoa Mint)
  static const leafMint = Color(0xFF19D96B);
  static const vitalNormal = Color(0xFF16A34A);

  // Triage Risk & Emergency Badges (Zevoa Coral & Amber)
  static const alertHighRisk = Color(0xFFFF5A36); // High-risk pregnancy, red triage alert, SOS
  static const warningPending = Color(0xFFF59E0B); // Overdue immunization, follow-up warning
  static const teleConsultBlue = Color(0xFF3B82F6); // Telemedicine, Medical Officer connect

  // Canvas & Surfaces (Glare-free for field sunlight)
  static const screenBg = Color(0xFFF8F9FA); // Soft glare-free off-white
  static const cardSurface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF1F5F2);
  static const borderSubtle = Color(0xFFE2E8E4);

  // High-Contrast Deep Carbon & Typography
  static const carbonBlack = Color(0xFF121A15);
  static const textPrimary = Color(0xFF111815);
  static const textSecondary = Color(0xFF5F6B64);
  static const textMuted = Color(0xFF8A968F);
}

/// Unified Typography Scale for the ASHA Digital Platform.
class AshaTypography {
  AshaTypography._();

  static const fontFamily = 'SF Pro Display';
  static const fontFallback = ['SF Pro Text', '-apple-system', 'BlinkMacSystemFont', 'sans-serif'];

  static const displayHero = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AshaColors.textPrimary,
    letterSpacing: -0.8,
  );

  static const screenTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AshaColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AshaColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const cardTitle = TextStyle(
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

/// Unified Shape and Tactile Dimensions.
class AshaShapes {
  AshaShapes._();

  static const double buttonPillRadius = 26.0;
  static const double searchPillRadius = 24.0;
  static const double serviceCardRadius = 20.0;
  static const double beneficiaryCardRadius = 18.0;
  static const double chipRadius = 12.0;
  static const double dockRadius = 28.0;

  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(buttonPillRadius));
  static const BorderRadius searchRadius = BorderRadius.all(Radius.circular(searchPillRadius));
  static const BorderRadius serviceRadius = BorderRadius.all(Radius.circular(serviceCardRadius));
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(beneficiaryCardRadius));
  static const BorderRadius chipBorderRadius = BorderRadius.all(Radius.circular(chipRadius));
  static const BorderRadius dockBorderRadius = BorderRadius.all(Radius.circular(dockRadius));

  static const Size minButtonSize = Size(0, 54);
}

/// Application theme configuration conforming to WCAG AA contrast (Requirement 3.4 & 49.1).
class AppTheme {
  AppTheme._();

  // Backward compatibility aliases
  static const Color primaryGreen = AshaColors.primary;
  static const Color errorRed = AshaColors.alertHighRisk;
  static const Color warningAmber = AshaColors.warningPending;

  static ThemeData get light {
    final scheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AshaColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AshaColors.primaryLight,
      onPrimaryContainer: AshaColors.primaryDark,
      secondary: AshaColors.alertHighRisk,
      onSecondary: Colors.white,
      tertiary: AshaColors.teleConsultBlue,
      onTertiary: Colors.white,
      error: AshaColors.alertHighRisk,
      onError: Colors.white,
      surface: AshaColors.cardSurface,
      onSurface: AshaColors.textPrimary,
      surfaceContainerHighest: AshaColors.surfaceMuted,
      outline: AshaColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AshaColors.screenBg,
      fontFamily: AshaTypography.fontFamily,
      fontFamilyFallback: AshaTypography.fontFallback,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      appBarTheme: const AppBarTheme(
        backgroundColor: AshaColors.screenBg,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: AshaTypography.screenTitle,
        iconTheme: IconThemeData(color: AshaColors.textPrimary),
      ),

      textTheme: const TextTheme(
        headlineLarge: AshaTypography.displayHero,
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AshaColors.textPrimary,
          letterSpacing: -0.6,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AshaColors.textPrimary,
        ),
        titleLarge: AshaTypography.screenTitle,
        titleMedium: AshaTypography.cardTitle,
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AshaColors.textPrimary,
        ),
        bodyLarge: AshaTypography.bodyLarge,
        bodyMedium: AshaTypography.bodyMedium,
        labelLarge: AshaTypography.labelLarge,
        bodySmall: AshaTypography.subtitleSmall,
      ),

      // Tactile Pill Buttons (54dp height, 26dp radius)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: AshaShapes.minButtonSize,
          backgroundColor: AshaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AshaShapes.buttonRadius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: AshaShapes.minButtonSize,
          backgroundColor: AshaColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AshaShapes.buttonRadius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: AshaShapes.minButtonSize,
          foregroundColor: AshaColors.textPrimary,
          side: const BorderSide(color: AshaColors.borderSubtle, width: 1.2),
          shape: const RoundedRectangleBorder(borderRadius: AshaShapes.buttonRadius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // Beneficiary & Service Cards (18dp radius, clean 1dp border, elevation 0)
      cardTheme: CardThemeData(
        color: AshaColors.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AshaShapes.cardRadius,
          side: const BorderSide(color: AshaColors.borderSubtle, width: 1.0),
        ),
      ),

      // Search & Input Fields (24dp pill radius)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AshaColors.cardSurface,
        border: OutlineInputBorder(
          borderRadius: AshaShapes.searchRadius,
          borderSide: const BorderSide(color: AshaColors.borderSubtle, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AshaShapes.searchRadius,
          borderSide: const BorderSide(color: AshaColors.borderSubtle, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AshaShapes.searchRadius,
          borderSide: const BorderSide(color: AshaColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AshaShapes.searchRadius,
          borderSide: const BorderSide(color: AshaColors.alertHighRisk, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(color: AshaColors.textMuted, fontSize: 14),
      ),

      // Status & Filter Chips: High-contrast theme match for selected & unselected states
      chipTheme: ChipThemeData(
        backgroundColor: AshaColors.surfaceMuted,
        selectedColor: AshaColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            );
          }
          return const TextStyle(
            color: AshaColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          );
        }),
        shape: const RoundedRectangleBorder(borderRadius: AshaShapes.chipBorderRadius),
        side: WidgetStateBorderSide.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const BorderSide(color: AshaColors.primary, width: 1.2);
          }
          return const BorderSide(color: AshaColors.borderSubtle, width: 0.8);
        }),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),

      // TabBar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AshaColors.primary,
        unselectedLabelColor: AshaColors.textSecondary,
        indicatorColor: AshaColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: AshaColors.leafMint,
      onPrimary: AshaColors.carbonBlack,
      primaryContainer: AshaColors.primaryDark,
      onPrimaryContainer: Colors.white,
      secondary: AshaColors.alertHighRisk,
      onSecondary: Colors.white,
      tertiary: AshaColors.teleConsultBlue,
      onTertiary: Colors.white,
      error: AshaColors.alertHighRisk,
      onError: Colors.white,
      surface: Color(0xFF1B241F),
      onSurface: Colors.white,
      surfaceContainerHighest: Color(0xFF233029),
      outline: Color(0xFF2E3E36),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AshaColors.carbonBlack,
      fontFamily: AshaTypography.fontFamily,
      fontFamilyFallback: AshaTypography.fontFallback,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      appBarTheme: const AppBarTheme(
        backgroundColor: AshaColors.carbonBlack,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.4,
        ),
      ),

      cardTheme: CardThemeData(
        color: const Color(0xFF1B241F),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AshaShapes.cardRadius,
          side: const BorderSide(color: Color(0xFF2E3E36), width: 1.0),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: AshaShapes.minButtonSize,
          backgroundColor: AshaColors.leafMint,
          foregroundColor: AshaColors.carbonBlack,
          shape: const RoundedRectangleBorder(borderRadius: AshaShapes.buttonRadius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }

  /// Returns the semantic triage colour for use in triage result displays.
  static Color triageColor(String flag) {
    return switch (flag.toUpperCase()) {
      'RED' => AshaColors.alertHighRisk,
      'YELLOW' => AshaColors.warningPending,
      _ => AshaColors.vitalNormal,
    };
  }
}
