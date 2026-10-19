import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'languages.dart';

/// Language and voice choices for They speak / I ask.
///
/// Stored in a file on the phone. The shared-preferences plugin in this app
/// crashes on Android, which left the page on a spinner.
class SettingsStore extends ChangeNotifier {
  String sourceCode = 'hi-IN';
  bool autoSpeak = true;
  bool askInEnglish = false;

  IndicLanguage get source =>
      languageByCode(sourceCode) ?? indicLanguages.first;

  Future<void> load() async {
    try {
      final file = await _file();
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map) {
          final stored = decoded['source_language'];
          sourceCode = languageByCode(stored is String ? stored : null)?.code ?? 'hi-IN';
          if (decoded['auto_speak'] is bool) autoSpeak = decoded['auto_speak'] as bool;
          if (decoded['ask_in_english'] is bool) {
            askInEnglish = decoded['ask_in_english'] as bool;
          }
        }
      }
    } catch (_) {
      // Keep the defaults so the page still opens.
    }
    notifyListeners();
  }

  Future<void> setSource(String code) async {
    final language = languageByCode(code);
    if (language == null) return;
    sourceCode = language.code;
    await _write();
    notifyListeners();
  }

  Future<void> setAutoSpeak(bool value) async {
    autoSpeak = value;
    await _write();
    notifyListeners();
  }

  Future<void> setAskInEnglish(bool value) async {
    askInEnglish = value;
    await _write();
    notifyListeners();
  }

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/bhasha-settings.json');
  }

  Future<void> _write() async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({
        'source_language': sourceCode,
        'auto_speak': autoSpeak,
        'ask_in_english': askInEnglish,
      }));
    } catch (_) {
      // The choice still applies for this visit.
    }
  }
}
