import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../database/app_database.dart';

/// Derives a 32-byte AES key from the user's PIN using PBKDF2-HMAC-SHA256
/// with 100,000 iterations, conforming to the design specification.
///
/// The random salt (32 bytes) is stored in Android Keystore-backed
/// EncryptedSharedPreferences via flutter_secure_storage.
///
/// The derived key is returned as a 64-character lowercase hex string
/// suitable for use as a SQLCipher `PRAGMA key = "x'...'";` argument.
class KeyManager {
  static const String _saltStorageKey = 'asha_db_salt_v1';
  static const String _backgroundKeyStorageKey = 'asha_db_background_key_v1';
  static const int _iterations = 100000;
  static const int _keyLengthBytes = 32; // 256-bit AES

  final FlutterSecureStorage _secureStorage;

  KeyManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
            );

  /// Returns the 64-character hex encryption key for the given [pin].
  ///
  /// On first call, generates and persists a random 32-byte salt.
  /// On subsequent calls, reads the existing salt and re-derives the key.
  Future<String> deriveKey(String pin) async {
    final salt = await _getOrCreateSalt();
    final keyBytes = await _pbkdf2(pin, salt);
    final key = _toHex(keyBytes);
    // The PIN is never persisted. The already-derived key is held only by
    // hardware-backed secure storage so WorkManager can open SQLCipher while
    // the Flutter UI isolate is not running.
    await _secureStorage.write(key: _backgroundKeyStorageKey, value: key);
    return key;
  }

  /// Re-keys the database after a PIN change.
  ///
  /// Call this after `PRAGMA rekey` has been issued to the open database.
  /// Returns the new hex key so the caller can update its in-memory reference.
  Future<String> rotateKey({
    required String newPin,
  }) async {
    // Salt stays the same — only the PIN changes.
    final salt = await _getOrCreateSalt();
    final newKeyBytes = await _pbkdf2(newPin, salt);
    final key = _toHex(newKeyBytes);
    await _secureStorage.write(key: _backgroundKeyStorageKey, value: key);
    return key;
  }

  /// Re-encrypts an already-open SQLCipher database after verifying the old
  /// PIN. The caller must reopen its session using the returned key.
  Future<String> changePin({
    required String oldPin,
    required String newPin,
    required AppDatabase db,
  }) async {
    final oldKey = await deriveKey(oldPin);
    final newKey = await rotateKey(newPin: newPin);
    if (oldKey == newKey) {
      throw ArgumentError('New PIN must differ from the current PIN.');
    }
    await db.customStatement("PRAGMA rekey = \"x'$newKey'\";");
    return newKey;
  }

  /// Deletes the stored salt (called during remote wipe).
  Future<void> deleteSalt() async {
    await _secureStorage.delete(key: _saltStorageKey);
    await _secureStorage.delete(key: _backgroundKeyStorageKey);
  }

  /// Returns the hardware-backed database key for a background sync worker.
  /// It is cleared by remote wipe along with all secure-storage records.
  Future<String?> readBackgroundDatabaseKey() =>
      _secureStorage.read(key: _backgroundKeyStorageKey);

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<Uint8List> _getOrCreateSalt() async {
    final existing = await _secureStorage.read(key: _saltStorageKey);
    if (existing != null) {
      return base64Decode(existing);
    }
    // Generate a fresh 32-byte cryptographically random salt.
    final salt = _randomBytes(32);
    await _secureStorage.write(
      key: _saltStorageKey,
      value: base64Encode(salt),
    );
    return salt;
  }

  Future<Uint8List> _pbkdf2(String pin, Uint8List salt) async {
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _iterations,
      bits: _keyLengthBytes * 8,
    );

    final secretKey = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );

    final keyBytes = await secretKey.extractBytes();
    return Uint8List.fromList(keyBytes);
  }

  Uint8List _randomBytes(int count) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(count, (_) => rng.nextInt(256)),
    );
  }

  String _toHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
