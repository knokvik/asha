import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Stores low-confidence ASR confirmations/rejections until a sync transport
/// is available. Raw transcript retention is opt-in; otherwise only a hash is
/// retained so field feedback cannot become a second patient record.
class AsrFeedbackStore {
  static const _queueKey = 'asr_feedback_queue_json';
  static const _rawOptInKey = 'asr_feedback_raw_opt_in';
  static const _storage = FlutterSecureStorage();
  static const _uuid = Uuid();

  static Future<void> record({
    required String rawTranscript,
    required String canonicalValue,
    required double confidence,
    required bool accepted,
    required String language,
    required String fieldType,
  }) async {
    final rawOptIn = (await _storage.read(key: _rawOptInKey)) == 'true';
    final item = <String, dynamic>{
      'id': _uuid.v4(),
      'raw_transcript': rawOptIn ? rawTranscript : null,
      'raw_hash': sha256.convert(utf8.encode(rawTranscript)).toString(),
      'canonical_value': canonicalValue,
      'confidence': confidence,
      'accepted': accepted,
      'language': language,
      'field_type': fieldType,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'raw_retention_opt_in': rawOptIn,
    };
    final raw = await _storage.read(key: _queueKey);
    final queue = raw == null ? <dynamic>[] : (jsonDecode(raw) as List<dynamic>);
    queue.add(item);
    await _storage.write(key: _queueKey, value: jsonEncode(queue.take(100).toList()));
  }

  static Future<List<Map<String, dynamic>>> pending() async {
    final raw = await _storage.read(key: _queueKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw);
    return decoded is List
        ? decoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
        : [];
  }

  static Future<void> removeIds(Iterable<String> ids) async {
    final remove = ids.toSet();
    final remaining = (await pending()).where((item) => !remove.contains(item['id'])).toList();
    await _storage.write(key: _queueKey, value: jsonEncode(remaining));
  }

  static Future<void> setRawRetentionOptIn(bool enabled) =>
      _storage.write(key: _rawOptInKey, value: enabled.toString());
}
