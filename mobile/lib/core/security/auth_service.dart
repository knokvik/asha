import 'dart:math';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Authentication state for the current session.
enum AuthState { unauthenticated, authenticated, lockedOut, requiresOtp }

class AuthService {
  static const _pinHashKey = 'asha_pin_hash_v1';
  static const _failedAttemptsKey = 'asha_pin_fails_v1';
  static const _lockoutUntilKey = 'asha_lockout_until_v1';
  static const _offlineCredKey = 'asha_offline_cred_v1';
  static const _offlineCredExpKey = 'asha_offline_exp_v1';
  static const _deviceIdKey = 'asha_device_id_v1';
  static const _databaseKeyKey = 'asha_database_key_v1';

  static const int _maxAttempts = 5;
  static const int _maxLockoutSecs = 600;
  static const Duration _offlineCredTtl = Duration(days: 7);

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  int _biometricFailures = 0;

  AuthService({FlutterSecureStorage? storage, LocalAuthentication? localAuth})
    : _storage =
          storage ?? const FlutterSecureStorage(aOptions: AndroidOptions()),
      _localAuth = localAuth ?? LocalAuthentication();

  // ── PIN setup ─────────────────────────────────────────────────────────────

  /// Hashes and stores [pin]. Resets any lockout state.
  Future<void> setupPin(String pin) async {
    _validatePinFormat(pin);
    final hash = BCrypt.hashpw(pin, BCrypt.gensalt(logRounds: 12));
    await _storage.write(key: _pinHashKey, value: hash);
    await _resetLockout();
    await _refreshOfflineCredential(pin);
  }

  /// Returns true if a PIN has been configured.
  Future<bool> get isPinConfigured async {
    final hash = await _storage.read(key: _pinHashKey);
    return hash != null;
  }

  /// Returns whether the device can currently perform biometric auth.
  Future<bool> get isBiometricAvailable async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      return canCheck && supported;
    } catch (_) {
      return false;
    }
  }

  /// Keeps the SQLCipher session key in hardware-backed secure storage so a
  /// successful biometric unlock can open the encrypted local database without
  /// persisting the user's PIN.
  Future<void> cacheDatabaseKey(String key) async {
    await _storage.write(key: _databaseKeyKey, value: key);
  }

  Future<String?> readCachedDatabaseKey() async {
    return _storage.read(key: _databaseKeyKey);
  }

  // ── PIN verification ──────────────────────────────────────────────────────

  /// Verifies [pin] against the stored bcrypt hash.
  ///
  /// Returns [AuthState.authenticated] on success.
  /// Returns [AuthState.lockedOut] with a non-zero [lockoutRemainingSeconds].
  /// Returns [AuthState.requiresOtp] after [_maxAttempts] failures.
  Future<({AuthState state, int lockoutRemainingSeconds})> verifyPin(
    String pin, {
    int maxAttempts = _maxAttempts,
  }) async {
    // Check current lockout
    final lockoutResult = await _checkLockout();
    if (lockoutResult.state != AuthState.unauthenticated) return lockoutResult;

    final storedHash = await _storage.read(key: _pinHashKey);
    if (storedHash == null) {
      return (state: AuthState.unauthenticated, lockoutRemainingSeconds: 0);
    }

    final correct = BCrypt.checkpw(pin, storedHash);
    if (correct) {
      await _resetLockout();
      _biometricFailures = 0;
      await _refreshOfflineCredential(pin);
      return (state: AuthState.authenticated, lockoutRemainingSeconds: 0);
    }

    // Increment failure count and apply lockout
    return _handleFailedAttempt(maxAttempts: maxAttempts);
  }

  // ── Offline credential ────────────────────────────────────────────────────

  /// Validates the stored offline credential for the given [pin].
  ///
  /// The credential is a bcrypt hash of (pin:deviceId) stored with an expiry.
  /// Valid for 7 days from the last successful online JWT refresh.
  Future<bool> verifyOfflineCredential(String pin) async {
    final credHash = await _storage.read(key: _offlineCredKey);
    final expStr = await _storage.read(key: _offlineCredExpKey);
    if (credHash == null || expStr == null) return false;

    final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expStr));
    if (DateTime.now().isAfter(expiry)) return false;

    final deviceId = await _getOrCreateDeviceId();
    final payload = '$pin:$deviceId';
    return BCrypt.checkpw(payload, credHash);
  }

  /// Refreshes the offline credential after a successful online authentication.
  Future<void> refreshOfflineCredentialFromServer(String pin) async {
    await _refreshOfflineCredential(pin);
  }

  // ── Biometric ─────────────────────────────────────────────────────────────

  /// Attempts biometric authentication.
  ///
  /// Falls back to PIN flow after 3 consecutive biometric failures.
  /// Returns true on success, false if biometric unavailable or max failures reached.
  Future<bool> authenticateWithBiometric({
    required String localizedReason,
  }) async {
    if (_biometricFailures >= 3) return false;

    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    if (!canCheck || !isSupported) return false;

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (authenticated) {
        _biometricFailures = 0;
        return true;
      } else {
        _biometricFailures++;
        return false;
      }
    } catch (_) {
      _biometricFailures++;
      return false;
    }
  }

  /// True when biometric failures have reached the threshold and PIN is required.
  bool get shouldFallBackToPin => _biometricFailures >= 3;

  // ── Private helpers ───────────────────────────────────────────────────────

  void _validatePinFormat(String pin) {
    if (pin.length < 4 || pin.length > 8) {
      throw ArgumentError('PIN must be 4–8 digits. Got ${pin.length}.');
    }
    if (!RegExp(r'^\d+$').hasMatch(pin)) {
      throw ArgumentError('PIN must contain only digits.');
    }
  }

  Future<({AuthState state, int lockoutRemainingSeconds})>
  _checkLockout() async {
    final attemptsStr = await _storage.read(key: _failedAttemptsKey);
    final lockoutStr = await _storage.read(key: _lockoutUntilKey);
    final attempts = int.tryParse(attemptsStr ?? '0') ?? 0;
    final lockoutUntil = lockoutStr != null
        ? DateTime.fromMillisecondsSinceEpoch(int.parse(lockoutStr))
        : null;

    if (lockoutUntil != null && DateTime.now().isBefore(lockoutUntil)) {
      final remaining = lockoutUntil.difference(DateTime.now()).inSeconds;
      if (attempts >= _maxAttempts) {
        return (
          state: AuthState.requiresOtp,
          lockoutRemainingSeconds: remaining,
        );
      }
      return (state: AuthState.lockedOut, lockoutRemainingSeconds: remaining);
    }
    return (state: AuthState.unauthenticated, lockoutRemainingSeconds: 0);
  }

  Future<({AuthState state, int lockoutRemainingSeconds})>
  _handleFailedAttempt({required int maxAttempts}) async {
    final attemptsStr = await _storage.read(key: _failedAttemptsKey);
    final attempts = (int.tryParse(attemptsStr ?? '0') ?? 0) + 1;
    await _storage.write(key: _failedAttemptsKey, value: attempts.toString());

    if (attempts >= maxAttempts) {
      // Final attempt exceeded — require OTP
      const lockoutSecs = _maxLockoutSecs;
      final until = DateTime.now().add(const Duration(seconds: lockoutSecs));
      await _storage.write(
        key: _lockoutUntilKey,
        value: until.millisecondsSinceEpoch.toString(),
      );
      return (
        state: AuthState.requiresOtp,
        lockoutRemainingSeconds: lockoutSecs,
      );
    }

    // Escalating lockout: 30s * 2^(attempts-1), capped at _maxLockoutSecs
    final rawSecs = 30 * (1 << (attempts - 1));
    final lockoutSecs = rawSecs > _maxLockoutSecs ? _maxLockoutSecs : rawSecs;
    final until = DateTime.now().add(Duration(seconds: lockoutSecs));
    await _storage.write(
      key: _lockoutUntilKey,
      value: until.millisecondsSinceEpoch.toString(),
    );
    return (state: AuthState.lockedOut, lockoutRemainingSeconds: lockoutSecs);
  }

  Future<void> _resetLockout() async {
    await _storage.delete(key: _failedAttemptsKey);
    await _storage.delete(key: _lockoutUntilKey);
  }

  Future<void> _refreshOfflineCredential(String pin) async {
    final deviceId = await _getOrCreateDeviceId();
    final payload = '$pin:$deviceId';
    final hash = BCrypt.hashpw(payload, BCrypt.gensalt(logRounds: 10));
    final expiry = DateTime.now().add(_offlineCredTtl);
    await _storage.write(key: _offlineCredKey, value: hash);
    await _storage.write(
      key: _offlineCredExpKey,
      value: expiry.millisecondsSinceEpoch.toString(),
    );
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null) return existing;
    final id = _randomHex(16);
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }

  String _randomHex(int bytes) {
    final rng = Random.secure();
    return List.generate(
      bytes,
      (_) => rng.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
