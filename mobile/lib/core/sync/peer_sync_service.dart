import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Offline worker-to-worker exchange for aggregate area context.
///
/// Only ward/module counts and recommendations are exchanged. Patient names,
/// ticket IDs, notes, evidence, and household records never enter this
/// envelope. A QR display or any future nearby transport can carry the same
/// signed-by-hash envelope.
class PeerSyncService {
  static const _contextKey = 'triage_hotspot_context_json';
  static const _historyKey = 'peer_sync_history_json';
  static const _storage = FlutterSecureStorage();
  static const _uuid = Uuid();

  Future<String?> createContextPacket() async {
    final raw = await _storage.read(key: _contextKey);
    if (raw == null || raw.isEmpty) return null;
    final context = jsonDecode(raw);
    if (context is! Map<String, dynamic>) return null;
    final workerId = await _storage.read(key: 'worker_id') ?? 'unknown-worker';
    final body = jsonEncode({
      'generated_at': DateTime.now().millisecondsSinceEpoch,
      'source_worker_id': workerId,
      'context': _aggregateOnly(context),
    });
    final compressed = gzip.encode(utf8.encode(body));
    final encoded = base64UrlEncode(compressed);
    final packet = {
      'type': 'asha_area_context_v1',
      'packet_id': _uuid.v4(),
      'payload': encoded,
      'sha256': sha256.convert(utf8.encode(encoded)).toString(),
    };
    return jsonEncode(packet);
  }

  Future<PeerImportResult> importContextPacket(String packetText) async {
    try {
      final packet = jsonDecode(packetText) as Map<String, dynamic>;
      if (packet['type'] != 'asha_area_context_v1') {
        return const PeerImportResult.failure('Unsupported peer packet.');
      }
      final encoded = packet['payload']?.toString();
      final expectedHash = packet['sha256']?.toString();
      if (encoded == null || expectedHash == null ||
          sha256.convert(utf8.encode(encoded)).toString() != expectedHash) {
        return const PeerImportResult.failure('Peer packet integrity check failed.');
      }
      final decoded = jsonDecode(utf8.decode(gzip.decode(base64Url.decode(encoded))))
          as Map<String, dynamic>;
      final context = decoded['context'];
      if (context is! Map<String, dynamic>) {
        return const PeerImportResult.failure('Peer packet has no area context.');
      }
      final merged = await _mergeContext(context);
      await _storage.write(key: _contextKey, value: jsonEncode(merged));
      await _recordHistory({
        'packet_id': packet['packet_id']?.toString() ?? '',
        'source_worker_id': decoded['source_worker_id']?.toString() ?? 'unknown',
        'received_at': DateTime.now().millisecondsSinceEpoch,
        'hotspot_count': (context['hotspots'] as List?)?.length ?? 0,
      });
      return PeerImportResult.success(
        hotspotCount: (context['hotspots'] as List?)?.length ?? 0,
      );
    } catch (_) {
      return const PeerImportResult.failure('Could not read this peer packet.');
    }
  }

  Future<Map<String, dynamic>> _mergeContext(Map<String, dynamic> incoming) async {
    final currentRaw = await _storage.read(key: _contextKey);
    if (currentRaw == null) return Map<String, dynamic>.from(incoming);
    final current = jsonDecode(currentRaw);
    if (current is! Map<String, dynamic>) return Map<String, dynamic>.from(incoming);
    final merged = Map<String, dynamic>.from(current);
    merged['generated_at'] = DateTime.now().millisecondsSinceEpoch;
    for (final key in ['counts', 'modules', 'hotspots', 'notifications']) {
      final values = <String, dynamic>{};
      for (final item in [current[key], incoming[key]]) {
        if (item is! List) continue;
        for (final row in item) {
          if (row is! Map) continue;
          final stable = row['id'] ?? '${row['ward_id']}:${row['module_id']}:${row['week_index']}';
          values[stable.toString()] = Map<String, dynamic>.from(row);
        }
      }
      merged[key] = values.values.toList();
    }
    return merged;
  }

  Map<String, dynamic> _aggregateOnly(Map<String, dynamic> context) {
    const allowed = {'generated_at', 'as_of_month', 'lookback_days', 'block_code', 'counts', 'modules', 'hotspots', 'notifications'};
    return {
      for (final entry in context.entries)
        if (allowed.contains(entry.key)) entry.key: entry.value,
    };
  }

  Future<void> _recordHistory(Map<String, dynamic> item) async {
    final raw = await _storage.read(key: _historyKey);
    final history = raw == null ? <dynamic>[] : (jsonDecode(raw) as List<dynamic>);
    history.insert(0, item);
    await _storage.write(
      key: _historyKey,
      value: jsonEncode(history.take(20).toList()),
    );
  }
}

class PeerImportResult {
  const PeerImportResult.success({required this.hotspotCount}) : error = null, imported = true;
  const PeerImportResult.failure(this.error) : hotspotCount = 0, imported = false;

  final bool imported;
  final int hotspotCount;
  final String? error;
}
