import 'package:asha_platform/core/security/session_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _Storage extends Fake implements FlutterSecureStorage {
  final values = <String, String>{};

  @override
  Future<String?> read({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) values[key] = value;
  }
}

void main() {
  SessionService service(
    _Storage storage,
    SessionPost post, {
    Future<void> Function()? onRevoked,
  }) => SessionService(
    apiBaseUrl: 'https://api.example.test',
    storage: storage,
    post: post,
    onRevoked: onRevoked,
  );

  test('stores a refreshed access token', () async {
    final storage = _Storage()
      ..values.addAll({'refresh_token': 'refresh', 'device_id': 'device'});
    final result = await service(
      storage,
      (uri, headers, body) async => http.Response(
        '{"access_token":"new-access","refresh_token":"new-refresh"}',
        200,
      ),
    ).refreshAccessToken();
    expect(result, SessionRefreshResult.refreshed);
    expect(storage.values['access_token'], 'new-access');
    expect(storage.values['refresh_token'], 'new-refresh');
  });

  test('does not issue a request when credentials are absent', () async {
    final result = await service(
      _Storage(),
      (uri, headers, body) => throw StateError('must not post'),
    ).refreshAccessToken();
    expect(result, SessionRefreshResult.missingCredential);
  });

  test('wipes only after a server refresh rejection', () async {
    var wiped = false;
    final storage = _Storage()
      ..values.addAll({'refresh_token': 'refresh', 'device_id': 'device'});
    final result = await service(
      storage,
      (uri, headers, body) async => http.Response('', 401),
      onRevoked: () async => wiped = true,
    ).refreshAccessToken();
    expect(result, SessionRefreshResult.rejected);
    expect(wiped, isTrue);
  });
}
