import 'dart:io';

import 'package:archive/archive.dart';
import 'package:asha_platform/core/packs/map_content_pack_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late MapContentPackStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('asha_map_pack_test_');
    store = MapContentPackStore(baseDirectory: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  List<int> validArchive() {
    final archive = Archive();
    for (final name in [
      'facilities.geojson',
      'india_facilities.json',
      'india_states.geojson',
      'households.json',
      'referrals.json',
      'roads.json',
      'labels.json',
      'pcmc.mbtiles',
    ]) {
      final bytes = 'content for $name'.codeUnits;
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    }
    return ZipEncoder().encode(archive)!;
  }

  test('installs only a complete map archive into app-private storage', () async {
    await store.installArchive(validArchive());

    expect(await store.isInstalled(), isTrue);
    expect(await (await store.file('roads.json')).readAsString(), contains('roads.json'));
    expect(await store.installedBytes(), greaterThan(0));

    await store.remove();
    expect(await store.isInstalled(), isFalse);
  });

  test('rejects an archive whose content hash does not match', () async {
    await expectLater(
      store.installArchive(validArchive(), expectedSha256: 'not-the-real-hash'),
      throwsA(isA<MapContentPackException>()),
    );
    expect(await store.isInstalled(), isFalse);
  });

  test('rejects unsafe archive paths before installing anything', () async {
    final archive = Archive();
    final bytes = 'bad'.codeUnits;
    archive.addFile(ArchiveFile('../outside.txt', bytes.length, bytes));

    await expectLater(
      store.installArchive(ZipEncoder().encode(archive)!),
      throwsA(isA<MapContentPackException>()),
    );
    expect(await store.isInstalled(), isFalse);
  });

  test('rejects files outside the allowlisted map payload', () async {
    final archive = Archive();
    final bytes = 'not map data'.codeUnits;
    archive.addFile(ArchiveFile('unexpected.db', bytes.length, bytes));

    await expectLater(
      store.installArchive(ZipEncoder().encode(archive)!),
      throwsA(isA<MapContentPackException>()),
    );
    expect(await store.isInstalled(), isFalse);
  });
}
