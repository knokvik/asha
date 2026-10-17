import 'dart:io';

import 'package:archive/archive.dart';
import 'package:asha_platform/core/voice/model_manager.dart';
import 'package:asha_platform/core/voice/vosk_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late VoskModelManager modelManager;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('vosk_models_test_');
    modelManager = VoskModelManager(baseDirectory: tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  List<int> createTestZipBytes() {
    final archive = Archive();
    final content = 'vosk model weights and config binary data'.codeUnits;
    archive.addFile(ArchiveFile('model.bin', content.length, content));
    archive.addFile(ArchiveFile('am/final.mdl', content.length, content));
    return ZipEncoder().encode(archive)!;
  }

  group('VoskModelManager Model Catalog & Status (Requirement 6.9)', () {
    test('Catalog contains descriptors for full and compressed models', () {
      expect(VoskModelManager.catalog.containsKey('hi_full'), isTrue);
      expect(VoskModelManager.catalog.containsKey('hi_compressed'), isTrue);
      expect(VoskModelManager.catalog.containsKey('mr_full'), isTrue);

      final hiFull = VoskModelManager.catalog['hi_full']!;
      expect(hiFull.language, 'hi');
      expect(hiFull.modelType, VoskModelType.full);
      expect(hiFull.sizeBytes, greaterThan(10 * 1024 * 1024));
    });

    test('Initial status is notInstalled', () {
      final status = modelManager.getStatus('hi', type: VoskModelType.full);
      expect(status, ModelInstallStatus.notInstalled);
      expect(modelManager.isModelInstalled('hi', type: VoskModelType.full), isFalse);
    });
  });

  group('Data-Cost Control Mode & Wi-Fi Deferral (Requirement 6.9, Design 2.5)', () {
    test('Defers download to Wi-Fi when data-cost control is on and device is on mobile data', () async {
      final zipBytes = createTestZipBytes();
      final hash = sha256.convert(zipBytes).toString();

      final descriptor = VoskModelDescriptor(
        language: 'hi',
        modelType: VoskModelType.full,
        downloadUrl: 'https://models.asha-platform.org/vosk/hi_full.zip',
        expectedSha256: hash,
        sizeBytes: zipBytes.length,
      );

      // On mobile data with data-cost control enabled
      final installed = await modelManager.installModel(
        descriptor,
        isWifi: false,
        dataCostControlEnabled: true,
        preloadedZipBytes: zipBytes,
      );

      expect(installed, isFalse);
      expect(
        modelManager.getStatus('hi', type: VoskModelType.full),
        ModelInstallStatus.deferredToWifi,
      );
    });

    test('Proceeds with download when on Wi-Fi even if data-cost control is active', () async {
      final zipBytes = createTestZipBytes();
      final hash = sha256.convert(zipBytes).toString();

      final descriptor = VoskModelDescriptor(
        language: 'hi',
        modelType: VoskModelType.full,
        downloadUrl: 'https://models.asha-platform.org/vosk/hi_full.zip',
        expectedSha256: hash,
        sizeBytes: zipBytes.length,
      );

      final installed = await modelManager.installModel(
        descriptor,
        isWifi: true,
        dataCostControlEnabled: true,
        preloadedZipBytes: zipBytes,
      );

      expect(installed, isTrue);
      expect(
        modelManager.getStatus('hi', type: VoskModelType.full),
        ModelInstallStatus.installed,
      );
    });
  });

  group('SHA-256 Integrity Verification & Extraction (Requirement 6.9)', () {
    test('Successfully verifies SHA-256 and extracts model files into app storage', () async {
      final zipBytes = createTestZipBytes();
      final expectedHash = sha256.convert(zipBytes).toString();

      final descriptor = VoskModelDescriptor(
        language: 'hi',
        modelType: VoskModelType.compressed,
        downloadUrl: 'https://models.asha-platform.org/vosk/hi_comp.zip',
        expectedSha256: expectedHash,
        sizeBytes: zipBytes.length,
      );

      final success = await modelManager.installModel(
        descriptor,
        preloadedZipBytes: zipBytes,
      );

      expect(success, isTrue);
      expect(
        modelManager.getStatus('hi', type: VoskModelType.compressed),
        ModelInstallStatus.installed,
      );
      expect(modelManager.isModelInstalled('hi', type: VoskModelType.compressed), isTrue);

      final modelPath = await modelManager.getModelPath('hi', type: VoskModelType.compressed);
      expect(modelPath, isNotNull);
      expect(File('$modelPath/model.bin').existsSync(), isTrue);
      expect(File('$modelPath/am/final.mdl').existsSync(), isTrue);
    });

    test('Rejects model bundle and sets error status when SHA-256 hash does not match', () async {
      final zipBytes = createTestZipBytes();

      final descriptor = VoskModelDescriptor(
        language: 'hi',
        modelType: VoskModelType.full,
        downloadUrl: 'https://models.asha-platform.org/vosk/hi_full.zip',
        expectedSha256: 'tampered_or_invalid_sha256_hash_value_1234567890',
        sizeBytes: zipBytes.length,
      );

      final success = await modelManager.installModel(
        descriptor,
        preloadedZipBytes: zipBytes,
      );

      expect(success, isFalse);
      expect(
        modelManager.getStatus('hi', type: VoskModelType.full),
        ModelInstallStatus.error,
      );
      expect(modelManager.isModelInstalled('hi', type: VoskModelType.full), isFalse);
    });
  });

  group('Dynamic Model Removal & Lifecycle (Requirement 6.9)', () {
    test('Removes installed model directory and resets install status without APK update', () async {
      final zipBytes = createTestZipBytes();
      final hash = sha256.convert(zipBytes).toString();

      final descriptor = VoskModelDescriptor(
        language: 'mr',
        modelType: VoskModelType.full,
        downloadUrl: 'https://models.asha-platform.org/vosk/mr_full.zip',
        expectedSha256: hash,
        sizeBytes: zipBytes.length,
      );

      // Install
      await modelManager.installModel(descriptor, preloadedZipBytes: zipBytes);
      expect(modelManager.isModelInstalled('mr', type: VoskModelType.full), isTrue);

      // Remove
      final removed = await modelManager.removeModel('mr', type: VoskModelType.full);
      expect(removed, isTrue);
      expect(modelManager.isModelInstalled('mr', type: VoskModelType.full), isFalse);
      expect(
        modelManager.getStatus('mr', type: VoskModelType.full),
        ModelInstallStatus.notInstalled,
      );
    });
  });
}
