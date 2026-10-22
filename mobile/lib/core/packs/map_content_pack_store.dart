import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Installs the large, optional all-India map payload outside the APK.
///
/// The archive is fetched from the ASHA server, checksum-verified and unpacked
/// into application support storage. Extraction rejects traversal paths so a
/// compromised archive cannot write outside the pack directory.
class MapContentPackStore {
  MapContentPackStore({this.baseDirectory, this.httpClient});

  static const packId = 'india-map-v1';
  static const _requiredFiles = {
    'facilities.geojson',
    'india_facilities.json',
    'india_states.geojson',
    'households.json',
    'referrals.json',
    'roads.json',
    'labels.json',
    'pcmc.mbtiles',
  };

  final Directory? baseDirectory;
  final http.Client? httpClient;

  Future<Directory> directory() async {
    final root = baseDirectory ?? await getApplicationSupportDirectory();
    return Directory(p.join(root.path, 'content-packs', packId));
  }

  Future<File> file(String name) async => File(p.join((await directory()).path, name));

  Future<bool> isInstalled() async {
    final dir = await directory();
    if (!await dir.exists()) return false;
    for (final name in _requiredFiles) {
      if (!await File(p.join(dir.path, name)).exists()) return false;
    }
    return true;
  }

  Future<int> installedBytes() async {
    final dir = await directory();
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<void> install({
    required String apiBaseUrl,
    void Function(int received, int total)? onProgress,
  }) async {
    final base = apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
    final request = http.Request('GET', Uri.parse('$base/api/v1/packs/map-india'));
    final client = httpClient ?? http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode != HttpStatus.ok) {
        throw MapContentPackException('Map pack download failed (${response.statusCode}).');
      }
      final total = response.contentLength ?? 0;
      final chunks = <int>[];
      var received = 0;
      await for (final chunk in response.stream) {
        chunks.addAll(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await installArchive(
        Uint8List.fromList(chunks),
        expectedSha256: response.headers['x-content-sha256'],
      );
    } finally {
      if (httpClient == null) client.close();
    }
  }

  /// Visible for tests and for a PHC sideload workflow where a verified archive
  /// is copied to a device before travelling to a no-network area.
  Future<void> installArchive(
    List<int> bytes, {
    String? expectedSha256,
  }) async {
    final actual = sha256.convert(bytes).toString();
    if (expectedSha256 != null &&
        expectedSha256.isNotEmpty &&
        actual.toLowerCase() != expectedSha256.toLowerCase()) {
      throw const MapContentPackException('Map pack integrity check failed.');
    }

    final parent = (await directory()).parent;
    await parent.create(recursive: true);
    final staging = Directory(p.join(parent.path, '$packId.installing'));
    if (await staging.exists()) await staging.delete(recursive: true);
    await staging.create(recursive: true);

    try {
      final archive = ZipDecoder().decodeBytes(bytes);
      for (final entry in archive.files) {
        final safeName = _safeArchiveName(entry.name);
        if (safeName == null || !_requiredFiles.contains(safeName)) {
          throw const MapContentPackException(
            'Map pack contains an unexpected file path.',
          );
        }
        final target = File(p.join(staging.path, safeName));
        if (entry.isFile) {
          await target.parent.create(recursive: true);
          await target.writeAsBytes(entry.content as List<int>, flush: true);
        } else {
          await Directory(p.join(staging.path, safeName)).create(recursive: true);
        }
      }
      for (final name in _requiredFiles) {
        if (!await File(p.join(staging.path, name)).exists()) {
          throw MapContentPackException('Map pack is missing $name.');
        }
      }
      final installed = await directory();
      if (await installed.exists()) await installed.delete(recursive: true);
      await staging.rename(installed.path);
    } catch (_) {
      if (await staging.exists()) await staging.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> remove() async {
    final dir = await directory();
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  String? _safeArchiveName(String input) {
    final portable = input.replaceAll('\\', '/');
    // `path.isAbsolute` follows the device platform. Reject Windows drive
    // paths explicitly too, so an archive is safe regardless of where it was
    // created or tested.
    if (portable.startsWith('/') ||
        RegExp(r'^[A-Za-z]:').hasMatch(portable)) {
      return null;
    }
    final normalized = p.normalize(portable);
    if (normalized.isEmpty ||
        p.isAbsolute(normalized) ||
        normalized == '..' ||
        normalized.startsWith('../')) {
      return null;
    }
    return normalized;
  }
}

class MapContentPackException implements Exception {
  const MapContentPackException(this.message);
  final String message;

  @override
  String toString() => message;
}
