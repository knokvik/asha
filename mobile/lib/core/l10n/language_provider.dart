import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Metadata for supported languages in the ASHA Digital Platform.
class AppLanguage {
  final String code;
  final String englishName;
  final String nativeName;

  const AppLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
  });
}

/// The 12 official supported Indian languages + English (Requirement 3.1).
const List<AppLanguage> supportedLanguages = [
  AppLanguage(code: 'en', englishName: 'English', nativeName: 'English'),
  AppLanguage(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी'),
  AppLanguage(code: 'mr', englishName: 'Marathi', nativeName: 'मराठी'),
  AppLanguage(code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা'),
  AppLanguage(code: 'te', englishName: 'Telugu', nativeName: 'తెలుగు'),
  AppLanguage(code: 'ta', englishName: 'Tamil', nativeName: 'தமிழ்'),
  AppLanguage(code: 'kn', englishName: 'Kannada', nativeName: 'ಕನ್ನಡ'),
  AppLanguage(code: 'ml', englishName: 'Malayalam', nativeName: 'മലയാളം'),
  AppLanguage(code: 'or', englishName: 'Odia', nativeName: 'ଓଡ଼ିଆ'),
  AppLanguage(code: 'gu', englishName: 'Gujarati', nativeName: 'ગુજરાતી'),
  AppLanguage(code: 'pa', englishName: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ'),
  AppLanguage(code: 'as', englishName: 'Assamese', nativeName: 'অসমীয়া'),
];

/// Notifier managing runtime locale state and persistent storage.
///
/// Ensures no data loss on runtime switch and persistence across app restarts.
/// Requirements: 3.1, 3.6
class LanguageNotifier extends Notifier<Locale> {
  final FlutterSecureStorage _storage;

  LanguageNotifier({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  static const String storageKey = 'asha_selected_locale_v1';
  static const Locale defaultLocale = Locale('en');

  @override
  Locale build() {
    _loadSavedLocale();
    return defaultLocale;
  }

  Future<void> _loadSavedLocale() async {
    try {
      final saved = await _storage.read(key: storageKey);
      if (saved != null && isSupported(saved)) {
        state = Locale(saved);
      }
    } catch (_) {
      // Default to English on storage failure
    }
  }

  /// Change the application locale at runtime and persist to settings.
  Future<void> setLocale(Locale newLocale) async {
    if (!isSupported(newLocale.languageCode)) return;
    state = newLocale;
    try {
      await _storage.write(key: storageKey, value: newLocale.languageCode);
    } catch (_) {}
  }

  /// Change the application locale by language code (e.g. 'hi', 'mr').
  Future<void> setLanguageCode(String code) async {
    await setLocale(Locale(code));
  }

  static bool isSupported(String code) {
    return supportedLanguages.any((lang) => lang.code == code);
  }
}

/// Global provider for the active application locale.
final languageProvider =
    NotifierProvider<LanguageNotifier, Locale>(LanguageNotifier.new);
