import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

/// Files the phone keeps after the first download.
class ModelStore {
  ModelStore(this.root);

  static const mtBase =
      'https://huggingface.co/hari31416/indictrans2-indic-en-dist-200M-ONNX-int8/resolve/main/';
  static const dolphinUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-dolphin-base-ctc-multi-lang-int8-2025-04-02.tar.bz2';
  static const piperUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-lessac-medium.tar.bz2';
  static const enMtBase =
      'https://huggingface.co/hari31416/indictrans2-en-indic-dist-200M-ONNX-int8/resolve/main/';
  static const hindiVoiceUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-hi_IN-pratham-medium-int8.tar.bz2';

  static const mtSizes = <String, int>{
    'decoder_model.onnx': 1585382,
    'decoder_shared.onnx.data': 110052040,
    'decoder_with_past_model.onnx': 1398395,
    'encoder_model.onnx': 831436,
    'encoder_model.onnx.data': 120068096,
    'tokenizer_src.json': 23876630,
    'tokenizer_tgt.json': 3899748,
  };

  static const enMtSizes = <String, int>{
    'decoder_model.onnx': 2037502,
    'decoder_shared.onnx.data': 203048944,
    'decoder_with_past_model.onnx': 1850479,
    'encoder_model.onnx': 831399,
    'encoder_model.onnx.data': 73791488,
    'tokenizer_src.json': 3906621,
    'tokenizer_tgt.json': 23869629,
  };

  static const hindiVoiceSize = 20987965;
  static const fileCount = 9;
  static const askFileCount = 7;

  final Directory root;

  Directory get mtDirectory => Directory('${root.path}/mt');
  Directory get enMtDirectory => Directory('${root.path}/mt-en');
  String get asrModelPath => '${root.path}/asr/model.int8.onnx';
  String get asrTokensPath => '${root.path}/asr/tokens.txt';
  String get ttsModelPath => '${root.path}/tts/model.onnx';
  String get ttsTokensPath => '${root.path}/tts/tokens.txt';
  String get espeakDirectory => '${root.path}/tts/espeak-ng-data';
  String get hindiTtsModelPath => '${root.path}/tts-hi/model.onnx';
  String get hindiTtsTokensPath => '${root.path}/tts-hi/tokens.txt';

  bool get isReady => _mtReady && _asrReady && _ttsReady;

  bool get askReady {
    for (final entry in enMtSizes.entries) {
      final file = File('${enMtDirectory.path}/${entry.key}');
      if (!file.existsSync() || file.lengthSync() != entry.value) return false;
    }
    return true;
  }

  bool get hindiVoiceReady {
    final model = File(hindiTtsModelPath);
    final tokens = File(hindiTtsTokensPath);
    return model.existsSync() &&
        model.lengthSync() > 1024 * 1024 &&
        tokens.existsSync() &&
        tokens.lengthSync() > 100;
  }

  bool get _mtReady {
    for (final entry in mtSizes.entries) {
      final file = File('${mtDirectory.path}/${entry.key}');
      if (!file.existsSync() || file.lengthSync() != entry.value) return false;
    }
    return true;
  }

  bool get _asrReady {
    final model = File(asrModelPath);
    final tokens = File(asrTokensPath);
    return model.existsSync() &&
        model.lengthSync() > 50 * 1024 * 1024 &&
        tokens.existsSync() &&
        tokens.lengthSync() > 1000;
  }

  bool get _ttsReady {
    final model = File(ttsModelPath);
    final tokens = File(ttsTokensPath);
    final phontab = File('$espeakDirectory/phontab');
    return model.existsSync() &&
        model.lengthSync() > 1024 * 1024 &&
        tokens.existsSync() &&
        tokens.lengthSync() > 100 &&
        phontab.existsSync() &&
        phontab.lengthSync() > 100;
  }

  Future<void> ensure(void Function(DownloadProgress progress) onProgress) async {
    await root.create(recursive: true);
    final client = http.Client();
    try {
      var index = 0;
      await mtDirectory.create(recursive: true);
      for (final entry in mtSizes.entries) {
        await _download(
          client: client,
          url: '$mtBase${entry.key}',
          dest: File('${mtDirectory.path}/${entry.key}'),
          expectedSize: entry.value,
          label: 'Translation model',
          index: index,
          count: fileCount,
          onProgress: onProgress,
        );
        index += 1;
      }
      if (!_asrReady) {
        final archive = File('${root.path}/dolphin.tar.bz2');
        await _download(
          client: client,
          url: dolphinUrl,
          dest: archive,
          expectedSize: 0,
          label: 'Hearing model',
          index: index,
          count: fileCount,
          onProgress: onProgress,
        );
        onProgress(
          DownloadProgress(
            label: 'Unpacking the hearing model',
            received: 1,
            total: 1,
            index: index,
            count: fileCount,
          ),
        );
        await _installDolphin(archive);
        if (archive.existsSync()) archive.deleteSync();
      } else {
        _done(onProgress, 'Hearing model', index, count: fileCount);
      }
      index += 1;
      if (!_ttsReady) {
        final archive = File('${root.path}/piper.tar.bz2');
        await _download(
          client: client,
          url: piperUrl,
          dest: archive,
          expectedSize: 0,
          label: 'English voice',
          index: index,
          count: fileCount,
          onProgress: onProgress,
        );
        onProgress(
          DownloadProgress(
            label: 'Unpacking the English voice',
            received: 1,
            total: 1,
            index: index,
            count: fileCount,
          ),
        );
        await _installPiper(archive);
        if (archive.existsSync()) archive.deleteSync();
      } else {
        _done(onProgress, 'English voice', index, count: fileCount);
      }
    } finally {
      client.close();
    }
    if (!isReady) {
      throw ModelDownloadException(
        'The models did not finish unpacking. Try the download again.',
      );
    }
  }

  /// English-to-Indic weights. Separate from the hearing bundle, so a failed
  /// download here does not take the hear path offline.
  Future<void> ensureAsk(void Function(DownloadProgress progress) onProgress) async {
    await root.create(recursive: true);
    await enMtDirectory.create(recursive: true);
    final client = http.Client();
    try {
      var index = 0;
      for (final entry in enMtSizes.entries) {
        await _download(
          client: client,
          url: '$enMtBase${entry.key}',
          dest: File('${enMtDirectory.path}/${entry.key}'),
          expectedSize: entry.value,
          label: 'Ask-back model',
          index: index,
          count: askFileCount,
          onProgress: onProgress,
        );
        index += 1;
      }
    } finally {
      client.close();
    }
    if (!askReady) {
      throw ModelDownloadException(
        'The ask-back model did not finish. Try the download again.',
      );
    }
  }

  /// Hindi Piper voice. Reuses the English espeak data already on the phone.
  Future<void> ensureHindiVoice(
    void Function(DownloadProgress progress) onProgress,
  ) async {
    if (hindiVoiceReady) {
      _done(onProgress, 'Hindi voice', 0, count: 1);
      return;
    }
    await root.create(recursive: true);
    final client = http.Client();
    final archive = File('${root.path}/piper-hi.tar.bz2');
    try {
      await _download(
        client: client,
        url: hindiVoiceUrl,
        dest: archive,
        expectedSize: hindiVoiceSize,
        label: 'Hindi voice',
        index: 0,
        count: 1,
        onProgress: onProgress,
      );
      onProgress(
        const DownloadProgress(
          label: 'Unpacking the Hindi voice',
          received: 1,
          total: 1,
          index: 0,
          count: 1,
        ),
      );
      await _installHindi(archive);
      if (archive.existsSync()) archive.deleteSync();
    } finally {
      client.close();
    }
    if (!hindiVoiceReady) {
      throw ModelDownloadException(
        'The Hindi voice did not finish unpacking. Try again.',
      );
    }
  }

  Future<void> _download({
    required http.Client client,
    required String url,
    required File dest,
    required int expectedSize,
    required String label,
    required int index,
    required int count,
    required void Function(DownloadProgress progress) onProgress,
  }) async {
    if (dest.existsSync()) {
      final length = dest.lengthSync();
      if (expectedSize == 0 || length == expectedSize) {
        _done(onProgress, label, index, count: count, total: length);
        return;
      }
      dest.deleteSync();
    }
    final partial = File('${dest.path}.partial');
    if (partial.existsSync()) partial.deleteSync();
    await dest.parent.create(recursive: true);

    final request = http.Request('GET', Uri.parse(url));
    request.headers['user-agent'] = 'bhasha/1.0';
    final response = await client.send(request);
    if (response.statusCode != 200) {
      throw ModelDownloadException(
        'Could not download $label (${response.statusCode}).',
      );
    }
    final total = expectedSize > 0
        ? expectedSize
        : (response.contentLength ?? 0);
    final sink = partial.openWrite();
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress(
          DownloadProgress(
            label: label,
            received: received,
            total: total,
            index: index,
            count: count,
          ),
        );
      }
    } catch (error) {
      await sink.close();
      if (partial.existsSync()) partial.deleteSync();
      throw ModelDownloadException('The download stopped. $error');
    }
    await sink.close();
    final length = partial.lengthSync();
    if (expectedSize > 0 && length != expectedSize) {
      partial.deleteSync();
      throw ModelDownloadException(
        '$label is the wrong size. Try the download again.',
      );
    }
    if (length < 1000) {
      partial.deleteSync();
      throw ModelDownloadException('$label came back empty.');
    }
    if (dest.existsSync()) dest.deleteSync();
    partial.renameSync(dest.path);
  }

  Future<void> _installDolphin(File archive) async {
    final asr = Directory('${root.path}/asr');
    if (asr.existsSync()) asr.deleteSync(recursive: true);
    asr.createSync(recursive: true);
    String? modelName;
    String? tokensName;
    final entries = _readArchive(archive);
    for (final entry in entries) {
      final name = entry.name.replaceAll('\\', '/');
      if (name.endsWith('model.int8.onnx') || name.endsWith('model.onnx')) {
        if (modelName == null || name.contains('int8')) modelName = name;
      }
      if (name.endsWith('/tokens.txt') || name.endsWith('tokens.txt')) {
        if (tokensName == null || name.length < tokensName.length) {
          tokensName = name;
        }
      }
    }
    if (modelName == null || tokensName == null) {
      throw ModelDownloadException(
        'The hearing archive did not contain the model.',
      );
    }
    _writeNamed(entries, modelName, File(asrModelPath));
    _writeNamed(entries, tokensName, File(asrTokensPath));
  }

  Future<void> _installPiper(File archive) async {
    final tts = Directory('${root.path}/tts');
    if (tts.existsSync()) tts.deleteSync(recursive: true);
    tts.createSync(recursive: true);
    final entries = _readArchive(archive);
    String? modelName;
    String? tokensName;
    for (final entry in entries) {
      final name = entry.name.replaceAll('\\', '/');
      if (name.endsWith('.onnx') && !name.endsWith('.onnx.json')) {
        modelName ??= name;
      }
      if (!name.contains('espeak-ng-data/') &&
          (name.endsWith('/tokens.txt') || name == 'tokens.txt' || name.endsWith('tokens.txt'))) {
        if (tokensName == null || name.length < tokensName.length) {
          tokensName = name;
        }
      }
    }
    if (modelName == null || tokensName == null) {
      throw ModelDownloadException(
        'The English voice archive did not contain the model.',
      );
    }
    _writeNamed(entries, modelName, File(ttsModelPath));
    _writeNamed(entries, tokensName, File(ttsTokensPath));
    var wroteVoiceData = false;
    for (final entry in entries) {
      final name = entry.name.replaceAll('\\', '/');
      final marker = name.indexOf('espeak-ng-data/');
      if (marker < 0 || !entry.isFile) continue;
      final relative = name.substring(marker);
      _writeRelative(tts, relative, entry.content);
      wroteVoiceData = true;
    }
    if (!wroteVoiceData) {
      throw ModelDownloadException(
        'The English voice archive did not contain the pronunciation data.',
      );
    }
  }

  Future<void> _installHindi(File archive) async {
    final dir = Directory('${root.path}/tts-hi');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    final entries = _readArchive(archive);
    String? modelName;
    String? tokensName;
    for (final entry in entries) {
      final name = entry.name.replaceAll('\\', '/');
      if (name.endsWith('.onnx') && !name.endsWith('.onnx.json')) {
        if (modelName == null || name.contains('int8')) modelName = name;
      }
      if (!name.contains('espeak-ng-data/') && name.endsWith('tokens.txt')) {
        if (tokensName == null || name.length < tokensName.length) {
          tokensName = name;
        }
      }
    }
    if (modelName == null || tokensName == null) {
      throw ModelDownloadException(
        'The Hindi voice archive did not contain the model.',
      );
    }
    _writeNamed(entries, modelName, File(hindiTtsModelPath));
    _writeNamed(entries, tokensName, File(hindiTtsTokensPath));
  }

  List<ArchiveFile> _readArchive(File archive) {
    final compressed = archive.readAsBytesSync();
    final tar = BZip2Decoder().decodeBytes(compressed);
    final decoded = TarDecoder().decodeBytes(tar);
    return decoded.files.where((entry) {
      if (!entry.isFile) return false;
      final name = entry.name.replaceAll('\\', '/');
      if (name.split('/').any((part) => part == '..' || part.startsWith('._'))) {
        return false;
      }
      if (name.contains('__MACOSX') || name.contains('test_wavs')) return false;
      return true;
    }).toList();
  }

  void _writeNamed(List<ArchiveFile> entries, String name, File dest) {
    final match = entries.cast<ArchiveFile?>().firstWhere(
      (entry) => entry!.name.replaceAll('\\', '/') == name,
      orElse: () => null,
    );
    if (match == null) {
      throw ModelDownloadException('Missing $name in the archive.');
    }
    dest.parent.createSync(recursive: true);
    dest.writeAsBytesSync(match.content);
  }

  void _writeRelative(Directory rootDir, String relative, List<int> bytes) {
    final parts = relative.split('/').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty || parts.any((part) => part == '..')) return;
    final file = File('${rootDir.path}/${parts.join('/')}');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
  }

  void _done(
    void Function(DownloadProgress progress) onProgress,
    String label,
    int index, {
    required int count,
    int total = 1,
  }) {
    onProgress(
      DownloadProgress(
        label: label,
        received: total,
        total: total,
        index: index,
        count: count,
      ),
    );
  }
}

class DownloadProgress {
  const DownloadProgress({
    required this.label,
    required this.received,
    required this.total,
    required this.index,
    required this.count,
  });

  final String label;
  final int received;
  final int total;
  final int index;
  final int count;

  double get fraction {
    if (count <= 0) return 0;
    final file = total <= 0 ? 0.0 : (received / total).clamp(0.0, 1.0);
    return ((index + file) / count).clamp(0.0, 1.0);
  }
}

class ModelDownloadException implements Exception {
  ModelDownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}
