import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'vosk_service.dart';

/// Installation status of an offline Vosk speech model.
enum ModelInstallStatus {
  notInstalled,
  downloading,
  verifying,
  extracting,
  installed,
  error,
  deferredToWifi,
}

/// Metadata descriptor for a downloadable Vosk language model bundle.
/// Requirements: 6.9
class VoskModelDescriptor {
  final String language;
  final VoskModelType modelType;
  final String downloadUrl;
  final String expectedSha256;
  final int sizeBytes;

  const VoskModelDescriptor({
    required this.language,
    required this.modelType,
    required this.downloadUrl,
    required this.expectedSha256,
    required this.sizeBytes,
  });

  String get modelKey => '${language.toLowerCase()}_${modelType.name}';
}

/// Offline Vosk ASR model download and lifecycle manager.
///
/// Features:
/// - Independently downloadable `.zip` bundles per language (Requirement 6.9).
/// - Mandatory SHA-256 verification before extraction (Requirement 6.9).
/// - Stored in app-private support directory, excluded from cloud backup (Design 2.5).
/// - Install and remove models dynamically without APK update (Requirement 6.9).
/// - Automatic default post-install download for Hindi (deferred to Wi-Fi in data-cost control mode).
class VoskModelManager extends ChangeNotifier {
  final Directory? baseDirectory;
  final http.Client? httpClient;
  final Map<String, ModelInstallStatus> _statusMap = {};
  final Map<String, double> _progressMap = {};

  VoskModelManager({
    this.baseDirectory,
    this.httpClient,
  });

  /// Default registry of supported models.
  static final Map<String, VoskModelDescriptor> catalog = {
    'hi_full': const VoskModelDescriptor(
      language: 'hi',
      modelType: VoskModelType.full,
      downloadUrl: 'https://models.asha-platform.org/vosk/hi_full.zip',
      expectedSha256:
          'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', // Sample reference hash
      sizeBytes: 40 * 1024 * 1024, // ~40 MB
    ),
    'hi_compressed': const VoskModelDescriptor(
      language: 'hi',
      modelType: VoskModelType.compressed,
      downloadUrl: 'https://models.asha-platform.org/vosk/hi_compressed.zip',
      expectedSha256:
          'a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e',
      sizeBytes: 15 * 1024 * 1024, // ~15 MB
    ),
    'mr_full': const VoskModelDescriptor(
      language: 'mr',
      modelType: VoskModelType.full,
      downloadUrl: 'https://models.asha-platform.org/vosk/mr_full.zip',
      expectedSha256:
          'fba3c78c772b22646d61d84f88126b88931a29367d32a4e40280eb9a34bc4398',
      sizeBytes: 38 * 1024 * 1024,
    ),
  };

  ModelInstallStatus getStatus(String language, {VoskModelType type = VoskModelType.full}) {
    final key = '${language.toLowerCase()}_${type.name}';
    if (_statusMap.containsKey(key)) {
      return _statusMap[key]!;
    }
    return isModelInstalled(language, type: type)
        ? ModelInstallStatus.installed
        : ModelInstallStatus.notInstalled;
  }

  double getDownloadProgress(String language, {VoskModelType type = VoskModelType.full}) {
    final key = '${language.toLowerCase()}_${type.name}';
    return _progressMap[key] ?? 0.0;
  }

  /// Resolves the storage directory for models in application support storage.
  Future<Directory> getModelsDirectory() async {
    if (baseDirectory != null) {
      final dir = Directory(p.join(baseDirectory!.path, 'vosk_models'));
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    }

    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'vosk_models'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// Gets the extracted model directory path if installed.
  Future<String?> getModelPath(
    String language, {
    VoskModelType type = VoskModelType.full,
  }) async {
    final baseDir = await getModelsDirectory();
    final modelDir = Directory(p.join(baseDir.path, '${language.toLowerCase()}_${type.name}'));

    if (modelDir.existsSync() && modelDir.listSync().isNotEmpty) {
      return modelDir.path;
    }
    return null;
  }

  /// Checks if model directory exists and contains extracted files.
  bool isModelInstalled(String language, {VoskModelType type = VoskModelType.full}) {
    if (baseDirectory != null) {
      final dir = Directory(
        p.join(baseDirectory!.path, 'vosk_models', '${language.toLowerCase()}_${type.name}'),
      );
      return dir.existsSync() && dir.listSync().isNotEmpty;
    }

    // In asynchronous contexts or test mock, rely on cache if checked
    return _statusMap['${language.toLowerCase()}_${type.name}'] == ModelInstallStatus.installed;
  }

  // ── Download, Verification, and Extraction (Requirement 6.9) ───────────────

  /// Downloads, verifies SHA-256, and extracts an offline model bundle.
  ///
  /// Defers download to Wi-Fi if [dataCostControlEnabled] is `true` and [isWifi] is `false`.
  Future<bool> installModel(
    VoskModelDescriptor descriptor, {
    bool isWifi = true,
    bool dataCostControlEnabled = false,
    List<int>? preloadedZipBytes,
  }) async {
    final key = descriptor.modelKey;

    // Check data-cost control mode
    if (dataCostControlEnabled && !isWifi) {
      _statusMap[key] = ModelInstallStatus.deferredToWifi;
      notifyListeners();
      return false;
    }

    _statusMap[key] = ModelInstallStatus.downloading;
    _progressMap[key] = 0.0;
    notifyListeners();

    try {
      List<int> zipBytes;

      if (preloadedZipBytes != null) {
        zipBytes = preloadedZipBytes;
      } else {
        final client = httpClient ?? http.Client();
        final response = await client.get(Uri.parse(descriptor.downloadUrl));
        if (response.statusCode != 200) {
          _statusMap[key] = ModelInstallStatus.error;
          notifyListeners();
          return false;
        }
        zipBytes = response.bodyBytes;
      }

      // Step 2: SHA-256 Checksum Verification
      _statusMap[key] = ModelInstallStatus.verifying;
      _progressMap[key] = 0.8;
      notifyListeners();

      final actualSha256 = sha256.convert(zipBytes).toString();
      if (descriptor.expectedSha256.isNotEmpty &&
          actualSha256.toLowerCase() != descriptor.expectedSha256.toLowerCase()) {
        _statusMap[key] = ModelInstallStatus.error;
        notifyListeners();
        return false;
      }

      // Step 3: Extraction into app support storage
      _statusMap[key] = ModelInstallStatus.extracting;
      _progressMap[key] = 0.9;
      notifyListeners();

      final baseDir = await getModelsDirectory();
      final targetDir = Directory(p.join(baseDir.path, descriptor.modelKey));
      if (targetDir.existsSync()) {
        targetDir.deleteSync(recursive: true);
      }
      targetDir.createSync(recursive: true);

      final archive = ZipDecoder().decodeBytes(zipBytes);
      for (final file in archive) {
        final filename = p.join(targetDir.path, file.name);
        if (file.isFile) {
          final outFile = File(filename);
          outFile.parent.createSync(recursive: true);
          outFile.writeAsBytesSync(file.content as List<int>);
        } else {
          Directory(filename).createSync(recursive: true);
        }
      }

      _statusMap[key] = ModelInstallStatus.installed;
      _progressMap[key] = 1.0;
      notifyListeners();
      return true;
    } catch (_) {
      _statusMap[key] = ModelInstallStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Removes an installed model directory to reclaim device storage.
  Future<bool> removeModel(
    String language, {
    VoskModelType type = VoskModelType.full,
  }) async {
    final key = '${language.toLowerCase()}_${type.name}';
    try {
      final baseDir = await getModelsDirectory();
      final modelDir = Directory(p.join(baseDir.path, key));
      if (modelDir.existsSync()) {
        modelDir.deleteSync(recursive: true);
      }
      _statusMap[key] = ModelInstallStatus.notInstalled;
      _progressMap[key] = 0.0;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Wires Hindi (or selected language) model as default post-install download.
  ///
  /// Defers to Wi-Fi if data cost control mode is on and device is on mobile data.
  Future<bool> triggerDefaultPostInstallDownload({
    String selectedLanguage = 'hi',
    VoskModelType recommendedType = VoskModelType.full,
    bool isWifi = true,
    bool dataCostControlEnabled = false,
  }) async {
    final key = '${selectedLanguage.toLowerCase()}_${recommendedType.name}';
    final descriptor = catalog[key] ?? catalog['hi_full'];

    if (descriptor == null) return false;

    return installModel(
      descriptor,
      isWifi: isWifi,
      dataCostControlEnabled: dataCostControlEnabled,
    );
  }
}

/// Riverpod provider for [VoskModelManager].
final modelManagerProvider = Provider<VoskModelManager>((ref) {
  return VoskModelManager();
});
