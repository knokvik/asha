import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase phone OTP authentication service.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient get _client => Supabase.instance.client;
  String? _currentPhoneNumber;
  DateTime? _lastOtpSentTime;
  static const int cooldownDurationSeconds = 60;

  static void configureTestingEnvironment({
    bool disableAppVerification = true,
    bool forceRecaptchaFlow = false,
  }) {}

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;
  String? get currentPhoneNumber => _currentPhoneNumber;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  int get remainingCooldownSeconds {
    if (_lastOtpSentTime == null) return 0;
    final remaining =
        cooldownDurationSeconds -
        DateTime.now().difference(_lastOtpSentTime!).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  Future<void> sendOtp(
    String e164Phone, {
    void Function(String, int?)? onCodeSent,
    void Function(String)? onVerificationFailed,
    void Function(dynamic)? onVerificationCompleted,
  }) async {
    final remaining = remainingCooldownSeconds;
    if (remaining > 0)
      throw AuthException(
        'Please wait $remaining seconds before requesting another code.',
      );
    try {
      await _client.auth.signInWithOtp(phone: e164Phone);
      _currentPhoneNumber = e164Phone;
      _lastOtpSentTime = DateTime.now();
      onCodeSent?.call('', null);
    } on AuthException catch (e) {
      final message = mapAuthException(e);
      onVerificationFailed?.call(message);
      throw AuthException(message);
    }
  }

  Future<void> resendOtp({
    void Function(String, int?)? onCodeSent,
    void Function(String)? onVerificationFailed,
    void Function(dynamic)? onVerificationCompleted,
  }) async {
    final phone = _currentPhoneNumber;
    if (phone == null)
      throw AuthException('OTP session expired. Please request a new OTP.');
    _lastOtpSentTime = null;
    await sendOtp(
      phone,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
      onVerificationCompleted: onVerificationCompleted,
    );
  }

  Future<AuthResponse> verifyOtp(String smsCode) async {
    final phone = _currentPhoneNumber;
    if (phone == null)
      throw AuthException('OTP session expired. Please request a new OTP.');
    try {
      return await _client.auth.verifyOTP(
        phone: phone,
        token: smsCode.trim(),
        type: OtpType.sms,
      );
    } on AuthException catch (e) {
      throw AuthException(mapAuthException(e));
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    _currentPhoneNumber = null;
    _lastOtpSentTime = null;
  }

  String mapAuthException(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('rate') || message.contains('too many'))
      return 'Too many OTP requests. Please try again later.';
    if (message.contains('invalid') && message.contains('phone'))
      return 'Enter a valid mobile number with country code.';
    if (kDebugMode)
      debugPrint('[AuthService] Supabase auth error: ${e.message}');
    return e.message.isNotEmpty
        ? e.message
        : 'Phone authentication failed. Please try again.';
  }
}
