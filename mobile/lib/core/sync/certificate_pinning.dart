/// Certificate-pinned HTTP transport for production API calls.
library;

import 'package:http/http.dart' as http;
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

class CertificatePinningException implements Exception {
  const CertificatePinningException(this.message);
  final String message;

  @override
  String toString() => 'CertificatePinningException: $message';
}

class PinnedHttpTransport {
  PinnedHttpTransport({required List<String> sha256Fingerprints})
      : _pins = List.unmodifiable(sha256Fingerprints.where(_isSha256Fingerprint));

  final List<String> _pins;

  static bool _isSha256Fingerprint(String pin) =>
      RegExp(r'^(?:[A-Fa-f0-9]{2}:){31}[A-Fa-f0-9]{2}$').hasMatch(pin);

  Future<http.Response> post(
    Uri uri, {
    required Map<String, String> headers,
    required List<int> body,
  }) async {
    if (uri.scheme != 'https') {
      throw const CertificatePinningException('Sync must use HTTPS outside a local development endpoint.');
    }
    if (_pins.isEmpty) {
      throw const CertificatePinningException('No valid SHA-256 certificate pins are configured for the API.');
    }
    final client = SecureHttpClient.build(_pins);
    try {
      return await client.post(uri, headers: headers, body: body);
    } on CertificateNotVerifiedException {
      throw CertificatePinningException('The API certificate does not match a configured SHA-256 pin.');
    } finally {
      client.close();
    }
  }
}
