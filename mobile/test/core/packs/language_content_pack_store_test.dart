import 'dart:io';

import 'package:archive/archive.dart';
import 'package:asha_platform/core/packs/language_content_pack_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late LanguageContentPackStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('asha_language_pack_test_');
    store = LanguageContentPackStore(baseDirectory: tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  List<int> archiveFor(String code) {
    final archive = Archive();
    final bytes = '{"language":"$code"}'.codeUnits;
    archive.addFile(ArchiveFile('app_$code.arb', bytes.length, bytes));
    return ZipEncoder().encode(archive)!;
  }

  test('installs and removes only the requested language bundle', () async {
    await store.installArchive('hi', archiveFor('hi'));

    expect(await store.isInstalled('hi'), isTrue);
    expect(await store.isInstalled('mr'), isFalse);

    await store.remove('hi');
    expect(await store.isInstalled('hi'), isFalse);
  });

  test('does not accept an archive for a different language', () async {
    await expectLater(
      store.installArchive('hi', archiveFor('mr')),
      throwsA(isA<LanguageContentPackException>()),
    );
    expect(await store.isInstalled('hi'), isFalse);
  });

  test('rejects unsupported language identifiers', () async {
    await expectLater(
      store.installArchive('en', archiveFor('en')),
      throwsA(isA<LanguageContentPackException>()),
    );
  });
}
