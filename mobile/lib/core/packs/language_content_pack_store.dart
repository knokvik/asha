import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores OTA language-string bundles outside the APK.
///
/// The current app keeps generated localisation as a resilient fallback. These
/// small, versioned bundles make state/district wording updates downloadable
/// without another APK and are the install proof behind the language picker.
class LanguageContentPackStore {
  LanguageContentPackStore({this.baseDirectory, this.httpClient});

  final Directory? baseDirectory;
  final http.Client? httpClient;

  Future<Directory> directoryFor(String code) async {
    final root = baseDirectory ?? await getApplicationSupportDirectory();
    return Directory(p.join(root.path, 'content-packs', 'ui-$code'));
  }

  Future<bool> isInstalled(String code) async {
    final file = File(p.join((await directoryFor(code)).path, 'app_$code.arb'));
    return file.exists();
  }

  Future<void> install({
    required String languageCode,
    required String apiBaseUrl,
    void Function(int received, int total)? onProgress,
  }) async {
    final code = _validateCode(languageCode);
    final base = apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final client = httpClient ?? http.Client();
    try {
      final response = await client.send(
        http.Request('GET', Uri.parse('$base/api/v1/packs/ui-$code')),
      );
      if (response.statusCode != HttpStatus.ok) {
        throw LanguageContentPackException(
          'Language pack download failed (${response.statusCode}).',
        );
      }
      final bytes = <int>[];
      final total = response.contentLength ?? 0;
      var received = 0;
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await installArchive(
        code,
        Uint8List.fromList(bytes),
        expectedSha256: response.headers['x-content-sha256'],
      );
    } finally {
      if (httpClient == null) client.close();
    }
  }

  Future<void> installArchive(
    String languageCode,
    List<int> bytes, {
    String? expectedSha256,
  }) async {
    final code = _validateCode(languageCode);
    final actual = sha256.convert(bytes).toString();
    if (expectedSha256 != null &&
        expectedSha256.isNotEmpty &&
        actual.toLowerCase() != expectedSha256.toLowerCase()) {
      throw const LanguageContentPackException(
        'Language pack integrity check failed.',
      );
    }
    final destination = await directoryFor(code);
    final staging = Directory('${destination.path}.installing');
    if (await staging.exists()) await staging.delete(recursive: true);
    await staging.create(recursive: true);
    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      final expectedName = 'app_$code.arb';
      final entry = archive.files
          .where((file) => file.name == expectedName)
          .firstOrNull;
      if (entry == null || !entry.isFile) {
        throw LanguageContentPackException(
          'Language pack is missing $expectedName.',
        );
      }
      final target = File(p.join(staging.path, expectedName));
      await target.writeAsBytes(entry.content as List<int>, flush: true);
      if (await destination.exists()) await destination.delete(recursive: true);
      await destination.parent.create(recursive: true);
      await staging.rename(destination.path);
    } catch (_) {
      if (await staging.exists()) await staging.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> remove(String languageCode) async {
    final dir = await directoryFor(_validateCode(languageCode));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  String _validateCode(String value) {
    final code = value.toLowerCase();
    const supported = {
      'hi',
      'mr',
      'bn',
      'te',
      'ta',
      'kn',
      'ml',
      'or',
      'gu',
      'pa',
      'as',
    };
    if (!supported.contains(code)) {
      throw LanguageContentPackException('Unsupported language pack: $value');
    }
    return code;
  }
}

class LanguageContentPackException implements Exception {
  const LanguageContentPackException(this.message);
  final String message;

  @override
  String toString() => message;
}
