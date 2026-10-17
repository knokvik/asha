import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/security/key_manager.dart';

// Minimal FlutterSecureStorage fake for unit testing
class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

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
    if (value != null) _store[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    AndroidOptions? aOptions,
    AppleOptions? iOptions,
    LinuxOptions? lOptions,
    AppleOptions? mOptions,
    WebOptions? webOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

void main() {
  group('KeyManager', () {
    late KeyManager km;
    late _FakeSecureStorage storage;

    setUp(() {
      storage = _FakeSecureStorage();
      km = KeyManager(secureStorage: storage);
    });

    test('deriveKey returns 64-char hex string', () async {
      final key = await km.deriveKey('1234');
      expect(key.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(key), isTrue);
    });

    test('deriveKey is deterministic for same PIN and salt', () async {
      final key1 = await km.deriveKey('1234');
      final key2 = await km.deriveKey('1234');
      expect(key1, equals(key2));
    });

    test('deriveKey produces different key for different PIN same salt', () async {
      final key1 = await km.deriveKey('1234');
      final key2 = await km.deriveKey('5678');
      expect(key1, isNot(equals(key2)));
    });

    test('rotateKey returns different key for different PIN', () async {
      // Establish salt by first derivation
      await km.deriveKey('1234');

      final newKey = await km.rotateKey(newPin: '9999');
      final oldKey = await km.deriveKey('1234');
      expect(newKey, isNot(equals(oldKey)));
    });

    test('rotateKey returns same key as deriveKey for same new PIN', () async {
      await km.deriveKey('1234');
      final rotated = await km.rotateKey(newPin: '9999');
      final derived = await km.deriveKey('9999');
      expect(rotated, equals(derived));
    });

    test('deleteSalt causes next deriveKey to generate new salt', () async {
      final key1 = await km.deriveKey('1234');
      await km.deleteSalt();
      // New salt → different key even for same PIN
      final key2 = await km.deriveKey('1234');
      expect(key1, isNot(equals(key2)));
    });
  });
}
