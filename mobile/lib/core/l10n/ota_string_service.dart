import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Over-The-Air (OTA) localisation string bundle model.
/// Requirements: 3.6
class OtaStringBundle {
  final String language;
  final String version;
  final Map<String, String> strings;

  const OtaStringBundle({
    required this.language,
    required this.version,
    required this.strings,
  });

  factory OtaStringBundle.fromJson(Map<String, dynamic> json) {
    final rawStrings = json['strings'] as Map<String, dynamic>? ?? {};
    final stringMap = rawStrings.map((k, v) => MapEntry(k, v.toString()));
    return OtaStringBundle(
      language: json['language'] as String? ?? 'en',
      version: json['version'] as String? ?? '1.0',
      strings: stringMap,
    );
  }

  Map<String, dynamic> toJson() => {
        'language': language,
        'version': version,
        'strings': strings,
      };
}

/// Service managing OTA dynamic string updates without APK releases.
///
/// Delivers updated terminology, dialect phrases, or official translation fixes
/// during sync cycles and applies them dynamically to the UI.
/// Requirements: 3.6
class OtaStringService extends ChangeNotifier {
  final FlutterSecureStorage _storage;
  final Map<String, Map<String, String>> _cache = {}; // lang -> {key: text}
  final Map<String, String> _bundleVersions = {}; // lang -> version

  OtaStringService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Loads cached OTA bundles from persistent storage.
  Future<void> loadSavedBundles(List<String> languages) async {
    for (final lang in languages) {
      try {
        final key = 'ota_strings_${lang.toLowerCase()}';
        final saved = await _storage.read(key: key);
        if (saved != null) {
          final decoded = jsonDecode(saved) as Map<String, dynamic>;
          final bundle = OtaStringBundle.fromJson(decoded);
          _cache[lang.toLowerCase()] = Map.from(bundle.strings);
          _bundleVersions[lang.toLowerCase()] = bundle.version;
        }
      } catch (_) {}
    }
    notifyListeners();
  }

  /// Applies an incoming OTA bundle from backend sync and persists it.
  ///
  /// ⚠️  SECURITY WARNING — NO SIGNATURE VERIFICATION:
  /// This method currently trusts any bundle delivered by the sync transport.
  /// A compromised server, a MITM attack on an unprotected HTTP connection,
  /// or a malicious sync packet could push arbitrary string overrides —
  /// including replacing clinical guidance text, dosage labels, or danger-sign
  /// prompts with incorrect values.
  ///
  /// Before shipping to production you MUST add bundle signature verification:
  ///   1. The backend signs each bundle with an Ed25519 or ECDSA P-256 key.
  ///   2. The public key is pinned in the APK (not delivered over the wire).
  ///   3. [applyBundle] verifies the signature before calling [_cache.addAll].
  ///   4. Reject and log any bundle that fails verification.
  ///
  /// Until verification is in place, OTA string updates are disabled in
  /// production builds by a feature flag and only enabled in supervised pilots.
  Future<void> applyBundle(Map<String, dynamic> bundleJson) async {
    final bundle = OtaStringBundle.fromJson(bundleJson);
    final lang = bundle.language.toLowerCase();

    final currentLangMap = _cache.putIfAbsent(lang, () => {});
    currentLangMap.addAll(bundle.strings);
    _bundleVersions[lang] = bundle.version;

    try {
      final key = 'ota_strings_$lang';
      await _storage.write(key: key, value: jsonEncode(bundle.toJson()));
    } catch (_) {}

    notifyListeners();
  }

  /// Looks up a string key, returning the OTA override if present,
  /// otherwise returning [fallback].
  String lookup(String key, {String language = 'en', String? fallback}) {
    final lang = language.toLowerCase();
    final otaText = _cache[lang]?[key];
    if (otaText != null && otaText.isNotEmpty) {
      return otaText;
    }
    return fallback ?? key;
  }

  /// Checks if an OTA override is active for [key] in [language].
  bool hasOverride(String key, {String language = 'en'}) {
    return _cache[language.toLowerCase()]?.containsKey(key) ?? false;
  }

  /// Returns current version for [language], or null if using base bundle.
  String? getVersion(String language) {
    return _bundleVersions[language.toLowerCase()];
  }

  /// Clears stored OTA overrides for testing or reset.
  Future<void> clearAll() async {
    _cache.clear();
    _bundleVersions.clear();
    notifyListeners();
  }
}

/// Riverpod provider for [OtaStringService].
final otaStringServiceProvider = Provider<OtaStringService>((ref) {
  return OtaStringService();
});
