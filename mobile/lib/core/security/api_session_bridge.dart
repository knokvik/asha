import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_token.dart';

/// Turns a Supabase sign-in into the FastAPI session sync actually accepts.
///
/// The phone signs in with Supabase. Sync must send the API access token,
/// never the Supabase session token. If the server has no exchange endpoint
/// yet, this leaves the queue pending instead of failing it as unauthorized.
class ApiSessionBridge {
  ApiSessionBridge({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<bool> adoptSupabaseSession({required String apiBaseUrl}) async {
    final current = await _storage.read(key: 'access_token') ?? '';
    if (isApiAccessToken(current)) return true;

    final supabaseToken = await _storage.read(key: 'supabase_access_token') ?? '';
    if (supabaseToken.isEmpty) return false;

    final deviceId = await _deviceId();
    final endpoint = Uri.parse(
      '${apiBaseUrl.replaceFirst(RegExp(r'/+$'), '')}/api/v1/auth/supabase',
    );
    try {
      final response = await http
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $supabaseToken',
            },
            body: jsonEncode({'device_id': deviceId}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 || response.body.isEmpty) {
        debugPrint(
          '[ApiSessionBridge] Server session not issued (${response.statusCode}). Packets stay queued.',
        );
        return false;
      }
      final payload = jsonDecode(response.body);
      if (payload is! Map) return false;
      final accessToken = payload['access_token'];
      final refreshToken = payload['refresh_token'];
      final workerId = payload['worker_id'];
      if (accessToken is! String ||
          !isApiAccessToken(accessToken) ||
          refreshToken is! String ||
          refreshToken.isEmpty ||
          workerId is! String ||
          workerId.isEmpty) {
        return false;
      }
      await _storage.write(key: 'access_token', value: accessToken);
      await _storage.write(key: 'refresh_token', value: refreshToken);
      await _storage.write(key: 'worker_id', value: workerId);
      await _storage.write(key: 'device_id', value: deviceId);
      await _storage.write(key: 'asha_device_id_v1', value: deviceId);
      await _storage.write(key: 'sync_api_base_url', value: apiBaseUrl);
      return true;
    } catch (error) {
      debugPrint('[ApiSessionBridge] Could not reach the API session endpoint: $error');
      return false;
    }
  }

  Future<String> _deviceId() async {
    final existing =
        await _storage.read(key: 'device_id') ??
        await _storage.read(key: 'asha_device_id_v1');
    if (existing != null && existing.isNotEmpty) return existing;
    final rng = Random.secure();
    final id = List.generate(
      16,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    await _storage.write(key: 'asha_device_id_v1', value: id);
    return id;
  }
}
