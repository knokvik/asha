import 'dart:convert';

/// True only for a FastAPI access JWT from this app's own backend.
///
/// A Supabase session token is a JWT too, but its `iss` is the Supabase
/// project and it has no `type: access` claim. Sending it to `/api/v1/sync`
/// is what the server reports as unauthorized.
bool isApiAccessToken(String token) {
  final parts = token.split('.');
  if (parts.length != 3 || parts[1].isEmpty) return false;
  try {
    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map) return false;
    final issuer = payload['iss']?.toString() ?? '';
    if (issuer.contains('supabase')) return false;
    return payload['type'] == 'access';
  } catch (_) {
    return false;
  }
}
