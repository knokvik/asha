import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../database/app_database.dart';
import '../sync/certificate_pinning.dart';
import 'remote_wipe.dart';

/// Result of refreshing the server session.
enum SessionRefreshResult { refreshed, missingCredential, rejected, failed }

typedef SessionPost = Future<http.Response> Function(
  Uri uri,
  Map<String, String> headers,
  String body,
);

/// Refreshes the access token and performs a secure wipe only when the server
/// explicitly rejects the refresh credential (requirement 2.5).
///
/// An expired 15-minute access token is normal; it must not erase offline
/// patient records while its 30-day refresh credential is still valid.
class SessionService {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _deviceIdKey = 'device_id';

  final String apiBaseUrl;
  final List<String> certificatePins;
  final FlutterSecureStorage _storage;
  final SessionPost? _postOverride;
  final Future<void> Function()? _onRevoked;

  SessionService({
    required this.apiBaseUrl,
    AppDatabase? database,
    this.certificatePins = const [],
    FlutterSecureStorage? storage,
    SessionPost? post,
    Future<void> Function()? onRevoked,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _postOverride = post,
       _onRevoked =
           onRevoked ??
           (database == null
               ? () async => throw StateError(
                   'A database is required to wipe a revoked session.',
                 )
               : () => RemoteWipe(database).wipe());

  Future<SessionRefreshResult> refreshAccessToken() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final deviceId = await _storage.read(key: _deviceIdKey);
    if (refreshToken == null ||
        refreshToken.isEmpty ||
        deviceId == null ||
        deviceId.isEmpty) {
      return SessionRefreshResult.missingCredential;
    }

    final uri = Uri.parse('$apiBaseUrl/api/v1/auth/refresh');
    try {
      final response = await (_postOverride ?? _post)(
        uri,
        const {'Content-Type': 'application/json'},
        jsonEncode({'refresh_token': refreshToken, 'device_id': deviceId}),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = payload['access_token'];
        if (accessToken is! String || accessToken.isEmpty) {
          return SessionRefreshResult.failed;
        }
        await _storage.write(key: _accessTokenKey, value: accessToken);
        final rotatedRefreshToken = payload['refresh_token'];
        if (rotatedRefreshToken is String && rotatedRefreshToken.isNotEmpty) {
          await _storage.write(
            key: _refreshTokenKey,
            value: rotatedRefreshToken,
          );
        }
        return SessionRefreshResult.refreshed;
      }
      if (response.statusCode == 401) {
        await _onRevoked!();
        return SessionRefreshResult.rejected;
      }
      return SessionRefreshResult.failed;
    } catch (_) {
      return SessionRefreshResult.failed;
    }
  }

  Future<http.Response> _post(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) {
    if (uri.scheme == 'https') {
      return PinnedHttpTransport(sha256Fingerprints: certificatePins)
          .post(uri, headers: headers, body: utf8.encode(body));
    }
    // HTTP exists solely for an explicitly configured local development API.
    return http.post(uri, headers: headers, body: body);
  }
}
