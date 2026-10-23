import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service wrapping Firebase Phone Number (SMS OTP) Authentication.
///
/// Designed strictly for Android Phone Authentication without Google,
/// Email, or Anonymous sign-in providers.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // In-progress phone authentication state
  String? _verificationId;
  int? _resendToken;
  String? _currentPhoneNumber;
  DateTime? _lastOtpSentTime;
  static const int cooldownDurationSeconds = 60;

  // State getters
  String? get verificationId => _verificationId;
  int? get resendToken => _resendToken;
  String? get currentPhoneNumber => _currentPhoneNumber;
  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => _auth.currentUser != null;

  /// Returns remaining cooldown seconds before another OTP can be requested.
  int get remainingCooldownSeconds {
    if (_lastOtpSentTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastOtpSentTime!).inSeconds;
    final remaining = cooldownDurationSeconds - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Listen to authentication state changes across the application.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Optionally set language for SMS template (e.g. 'en', 'hi')
  Future<void> setLanguageCode(String languageCode) async {
    try {
      await _auth.setLanguageCode(languageCode);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] Could not set language code: $e');
      }
    }
  }

  /// Sends an OTP to the given E.164 formatted phone number.
  ///
  /// Uses a 60-second timeout, handles instant auto-retrieval, stores the
  /// in-progress state (verificationId, resendToken), and maps errors to
  /// frontline-friendly messages.
  Future<void> sendOtp(
    String e164Phone, {
    int? forceResendingToken,
    void Function(String verificationId, int? resendToken)? onCodeSent,
    void Function(String errorMessage)? onVerificationFailed,
    void Function(UserCredential credential)? onVerificationCompleted,
    void Function(String verificationId)? onAutoRetrievalTimeout,
  }) async {
    _currentPhoneNumber = e164Phone;
    _lastOtpSentTime = DateTime.now();

    // Localize SMS if possible
    await setLanguageCode('en');

    final completer = Completer<void>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: e164Phone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: forceResendingToken ?? _resendToken,

        // 1. Instant verification or SMS auto-retrieval (Android Play Services)
        verificationCompleted: (PhoneAuthCredential credential) async {
          if (kDebugMode) {
            debugPrint('[AuthService] verificationCompleted (auto-retrieval/instant)');
          }
          try {
            final userCredential = await _auth.signInWithCredential(credential);
            if (onVerificationCompleted != null) {
              onVerificationCompleted(userCredential);
            }
          } on FirebaseAuthException catch (e) {
            final msg = mapAuthException(e);
            if (onVerificationFailed != null) {
              onVerificationFailed(msg);
            }
          }
        },

        // 2. Verification failed
        verificationFailed: (FirebaseAuthException e) {
          final friendlyMessage = mapAuthException(e);
          if (kDebugMode) {
            debugPrint('[AuthService] verificationFailed: [${e.code}] ${e.message}');
          }
          if (onVerificationFailed != null) {
            onVerificationFailed(friendlyMessage);
          }
          if (!completer.isCompleted) completer.complete();
        },

        // 3. SMS OTP sent to handset
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _lastOtpSentTime = DateTime.now();

          if (kDebugMode) {
            debugPrint('[AuthService] codeSent successfully. verificationId set.');
          }

          if (onCodeSent != null) {
            onCodeSent(verificationId, resendToken);
          }
          if (!completer.isCompleted) completer.complete();
        },

        // 4. Auto-retrieval timeout
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (kDebugMode) {
            debugPrint('[AuthService] codeAutoRetrievalTimeout reached.');
          }
          if (onAutoRetrievalTimeout != null) {
            onAutoRetrievalTimeout(verificationId);
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] verifyPhoneNumber exception: $e');
      }
      if (onVerificationFailed != null) {
        onVerificationFailed('Failed to initiate SMS verification. Please try again.');
      }
      if (!completer.isCompleted) completer.complete();
    }

    return completer.future;
  }

  /// Verifies the entered 6-digit SMS code against the active verificationId.
  Future<UserCredential> verifyOtp(String smsCode) async {
    if (_verificationId == null || _verificationId!.isEmpty) {
      throw FirebaseAuthException(
        code: 'session-expired',
        message: 'No active verification session found. Please request a new OTP.',
      );
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );

      final userCredential = await _auth.signInWithCredential(credential);
      if (kDebugMode) {
        debugPrint('[AuthService] OTP successfully verified. Signed in UID: ${userCredential.user?.uid}');
      }
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthService] verifyOtp failed: [${e.code}] ${e.message}');
      }
      rethrow;
    }
  }

  /// Resends an OTP with cooldown protection (30-60s).
  Future<void> resendOtp({
    void Function(String verificationId, int? resendToken)? onCodeSent,
    void Function(String errorMessage)? onVerificationFailed,
    void Function(UserCredential credential)? onVerificationCompleted,
  }) async {
    if (_currentPhoneNumber == null || _currentPhoneNumber!.isEmpty) {
      throw StateError('Cannot resend OTP: No phone number currently active.');
    }

    final remaining = remainingCooldownSeconds;
    if (remaining > 0) {
      throw StateError('Please wait $remaining seconds before requesting another code.');
    }

    return sendOtp(
      _currentPhoneNumber!,
      forceResendingToken: _resendToken,
      onCodeSent: onCodeSent,
      onVerificationFailed: onVerificationFailed,
      onVerificationCompleted: onVerificationCompleted,
    );
  }

  /// Signs out the current Firebase user and resets session state.
  Future<void> signOut() async {
    _verificationId = null;
    _resendToken = null;
    _currentPhoneNumber = null;
    _lastOtpSentTime = null;
    await _auth.signOut();
  }

  /// Clear in-progress session to allow phone number change.
  void clearSession() {
    _verificationId = null;
    _resendToken = null;
    _currentPhoneNumber = null;
    _lastOtpSentTime = null;
  }

  /// Maps Firebase error codes to clear, frontline-friendly messages.
  String mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-phone-number':
        return 'The phone number entered is invalid. Please check and try again.';
      case 'too-many-requests':
        return 'Too many attempts. SMS quota exceeded or device temporarily blocked. Please try again later.';
      case 'quota-exceeded':
        return 'SMS verification quota has been reached. Please contact your health facility supervisor.';
      case 'missing-activity-for-recaptcha':
        return 'reCAPTCHA verification requires an active window. Please ensure Google Play services are installed.';
      case 'network-request-failed':
        return 'Network error. Please check your mobile data or Wi-Fi connectivity and try again.';
      case 'app-not-authorized':
        return 'This app build is not authorized to use Firebase Authentication. Please verify SHA fingerprints in the Firebase Console.';
      case 'captcha-check-failed':
        return 'Safety check verification failed. Please try again.';
      case 'invalid-verification-code':
        return 'Invalid 6-digit OTP entered. Please check the code and try again.';
      case 'session-expired':
        return 'Verification session has expired. Please request a new OTP.';
      case 'user-disabled':
        return 'This user account has been disabled. Please contact administrator.';
      case 'operation-not-allowed':
        return 'Phone sign-in is not enabled in Firebase Console. Please verify Phone Provider status.';
      default:
        return e.message?.isNotEmpty == true
            ? e.message!
            : 'Authentication failed. Please check your credentials and try again.';
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DEBUG-ONLY TESTING SUPPORT
  // ──────────────────────────────────────────────────────────────────────────

  /// Debug-only testing helper for fictional test numbers and emulators without
  /// Google Play services.
  ///
  /// CRITICAL: MUST NEVER run in production / release builds.
  /// Guarded strictly by [kDebugMode].
  static Future<void> configureTestingEnvironment({
    bool disableAppVerification = true,
    bool forceRecaptchaFlow = false,
  }) async {
    if (kDebugMode) {
      // Per Firebase documentation: Disable app verification for fictional test numbers
      // in development/emulators.
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: disableAppVerification,
        forceRecaptchaFlow: forceRecaptchaFlow,
      );
      debugPrint(
        '[AuthService DEBUG] Firebase setSettings applied: '
        'appVerificationDisabledForTesting=$disableAppVerification, '
        'forceRecaptchaFlow=$forceRecaptchaFlow',
      );
    }
  }
}
