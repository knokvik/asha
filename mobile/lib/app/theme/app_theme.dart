import 'package:flutter/material.dart';

/// Application theme configuration.
///
/// Colours are chosen to meet WCAG AA contrast ratios (requirement 3.4).
/// Green (#00695C) is the primary NHM health programme colour.
class AppTheme {
  AppTheme._();

  static const Color _primaryGreen = Color(0xFF00695C);
  static const Color _errorRed = Color(0xFFB71C1C);
  static const Color _warningAmber = Color(0xFFF9A825);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryGreen,
          error: _errorRed,
        ),
        // Ensure touch targets meet the 48×48 dp minimum (requirement 3.4, 49.4)
        materialTapTargetSize: MaterialTapTargetSize.padded,
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryGreen,
          brightness: Brightness.dark,
          error: _errorRed,
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
      );

  /// Returns the semantic triage colour for use in triage result displays.
  static Color triageColor(String flag) {
    return switch (flag.toUpperCase()) {
      'RED' => _errorRed,
      'YELLOW' => _warningAmber,
      _ => _primaryGreen,
    };
  }
}
