import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The locally persisted availability of optional, offline capabilities.
///
/// English is deliberately part of the base app. Every other visible language
/// and every interpreter language must be explicitly enabled by the worker.
/// This prevents a feature from advertising a language whose offline pack has
/// not been installed on this phone.
class OfflinePackState {
  const OfflinePackState({
    required this.loaded,
    required this.appLanguageCodes,
    required this.interpreterLanguageCodes,
    required this.mapInstalled,
  });

  const OfflinePackState.base()
      : loaded = false,
        appLanguageCodes = const {'en'},
        interpreterLanguageCodes = const {},
        mapInstalled = false;

  final bool loaded;
  final Set<String> appLanguageCodes;
  final Set<String> interpreterLanguageCodes;
  final bool mapInstalled;

  bool hasAppLanguage(String code) =>
      appLanguageCodes.contains(code.toLowerCase());

  /// Interpreter language codes use BCP-47 form, for example `hi-IN`.
  bool hasInterpreterLanguage(String code) =>
      interpreterLanguageCodes.contains(code);

  OfflinePackState copyWith({
    bool? loaded,
    Set<String>? appLanguageCodes,
    Set<String>? interpreterLanguageCodes,
    bool? mapInstalled,
  }) {
    return OfflinePackState(
      loaded: loaded ?? this.loaded,
      appLanguageCodes: Set.unmodifiable(appLanguageCodes ?? this.appLanguageCodes),
      interpreterLanguageCodes: Set.unmodifiable(
        interpreterLanguageCodes ?? this.interpreterLanguageCodes,
      ),
      mapInstalled: mapInstalled ?? this.mapInstalled,
    );
  }

  Map<String, Object> toJson() => {
        'app_languages': appLanguageCodes.toList()..sort(),
        'interpreter_languages': interpreterLanguageCodes.toList()..sort(),
        'map_installed': mapInstalled,
      };

  static OfflinePackState fromJson(Map<Object?, Object?> json) {
    Set<String> stringSet(Object? value) => {
          if (value is List)
            for (final item in value)
              if (item is String && item.trim().isNotEmpty) item.toLowerCase(),
        };

    final appLanguages = stringSet(json['app_languages'])..add('en');
    // BCP-47 region casing is meaningful to the interpreter catalogue.
    final interpreterLanguages = <String>{
      if (json['interpreter_languages'] is List)
        for (final item in json['interpreter_languages'] as List)
          if (item is String && item.trim().isNotEmpty) item,
    };
    return OfflinePackState(
      loaded: true,
      appLanguageCodes: Set.unmodifiable(appLanguages),
      interpreterLanguageCodes: Set.unmodifiable(interpreterLanguages),
      mapInstalled: json['map_installed'] == true,
    );
  }
}

/// One source of truth for installed optional packs.
///
/// Pack payloads live in app-private storage; this small manifest only records
/// availability after a payload has been installed or removed successfully.
class OfflinePackNotifier extends Notifier<OfflinePackState> {
  OfflinePackNotifier({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const storageKey = 'asha_offline_pack_manifest_v1';
  final FlutterSecureStorage _storage;

  @override
  OfflinePackState build() {
    _load();
    return const OfflinePackState.base();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: storageKey);
      if (raw == null || raw.isEmpty) {
        state = state.copyWith(loaded: true);
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        state = OfflinePackState.fromJson(decoded.cast<Object?, Object?>());
        return;
      }
    } catch (_) {
      // The base English/tap-only experience must remain usable on a storage
      // failure. A later install will write a fresh manifest.
    }
    state = state.copyWith(loaded: true);
  }

  Future<void> setAppLanguageInstalled(String code, bool installed) async {
    final normalized = code.toLowerCase();
    if (normalized == 'en') return; // English is the small base fallback.
    final next = {...state.appLanguageCodes};
    if (installed) {
      next.add(normalized);
    } else {
      next.remove(normalized);
    }
    await _replace(state.copyWith(appLanguageCodes: next, loaded: true));
  }

  Future<void> setInterpreterLanguageInstalled(
    String code,
    bool installed,
  ) async {
    final next = {...state.interpreterLanguageCodes};
    if (installed) {
      next.add(code);
    } else {
      next.remove(code);
    }
    await _replace(state.copyWith(interpreterLanguageCodes: next, loaded: true));
  }

  Future<void> clearInterpreterLanguages() async {
    await _replace(
      state.copyWith(interpreterLanguageCodes: const {}, loaded: true),
    );
  }

  Future<void> setMapInstalled(bool installed) async {
    await _replace(state.copyWith(mapInstalled: installed, loaded: true));
  }

  Future<void> _replace(OfflinePackState next) async {
    state = next;
    try {
      await _storage.write(key: storageKey, value: jsonEncode(next.toJson()));
    } catch (_) {
      // Keep the in-session change; the next installation can repair storage.
    }
  }
}

final offlinePackProvider =
    NotifierProvider<OfflinePackNotifier, OfflinePackState>(
  OfflinePackNotifier.new,
);
