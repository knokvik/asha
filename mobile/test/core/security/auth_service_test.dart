import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:asha_platform/core/security/auth_service.dart';

class MockLocalAuth extends Mock implements LocalAuthentication {}

class FakeSecureStorage extends Fake implements FlutterSecureStorage {
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
  }) async =>
      _store.remove(key);
}

void main() {
  late AuthService svc;
  late FakeSecureStorage storage;
  late MockLocalAuth mockAuth;

  setUp(() {
    storage = FakeSecureStorage();
    mockAuth = MockLocalAuth();
    svc = AuthService(storage: storage, localAuth: mockAuth);
  });


  group('PIN setup and verification', () {
    test('setupPin stores hash and verifyPin succeeds', () async {
      await svc.setupPin('1234');
      final result = await svc.verifyPin('1234');
      expect(result.state, AuthState.authenticated);
    });

    test('wrong PIN returns lockedOut with delay on first failure', () async {
      await svc.setupPin('1234');
      final result = await svc.verifyPin('9999');
      expect(result.state, AuthState.lockedOut);
      expect(result.lockoutRemainingSeconds, greaterThan(0));
    });

    test('lockout delay doubles per failure', () async {
      await svc.setupPin('1234');
      final r1 = await svc.verifyPin('0000');
      // Clear the lockout so we can record a second failure
      final pastTime = DateTime.now()
          .subtract(const Duration(seconds: 60))
          .millisecondsSinceEpoch;
      await storage.write(
          key: 'asha_lockout_until_v1', value: pastTime.toString());

      final r2 = await svc.verifyPin('0000');
      expect(r2.lockoutRemainingSeconds,
          greaterThanOrEqualTo(r1.lockoutRemainingSeconds));
    });

    test('max attempts returns requiresOtp', () async {
      await svc.setupPin('1234');
      // Exhaust all 5 attempts by expiring each lockout before the next try
      for (var i = 0; i < 4; i++) {
        await svc.verifyPin('0000');
        // Expire the lockout so the next attempt is accepted
        final pastTime = DateTime.now()
            .subtract(const Duration(seconds: 700))
            .millisecondsSinceEpoch;
        await storage.write(
            key: 'asha_lockout_until_v1', value: pastTime.toString());
      }
      // 5th failure should trigger requiresOtp
      final result = await svc.verifyPin('0000');
      expect(result.state, AuthState.requiresOtp);
    });

    test('correct PIN after lockout resets failure count', () async {
      await svc.setupPin('1234');
      await svc.verifyPin('0000'); // 1 failure — starts lockout

      // Simulate lockout expiry by overwriting the lockout key
      final pastTime = DateTime.now()
          .subtract(const Duration(seconds: 60))
          .millisecondsSinceEpoch;
      await storage.write(
          key: 'asha_lockout_until_v1', value: pastTime.toString());
      await storage.write(key: 'asha_pin_fails_v1', value: '1');

      final result = await svc.verifyPin('1234');
      expect(result.state, AuthState.authenticated);
    });

    test('PIN must be 4–8 digits — too short throws', () {
      expect(() => svc.setupPin('123'), throwsArgumentError);
    });

    test('PIN must be 4–8 digits — too long throws', () {
      expect(() => svc.setupPin('123456789'), throwsArgumentError);
    });

    test('PIN must contain only digits — alpha throws', () {
      expect(() => svc.setupPin('abcd'), throwsArgumentError);
    });

    test('PIN of exactly 4 digits is accepted', () async {
      await expectLater(svc.setupPin('1234'), completes);
    });

    test('PIN of exactly 8 digits is accepted', () async {
      await expectLater(svc.setupPin('12345678'), completes);
    });
  });

  group('Offline credential', () {
    test('verifyOfflineCredential returns true for correct PIN within 7 days',
        () async {
      await svc.setupPin('1234');
      final valid = await svc.verifyOfflineCredential('1234');
      expect(valid, isTrue);
    });

    test('verifyOfflineCredential returns false for wrong PIN', () async {
      await svc.setupPin('1234');
      final valid = await svc.verifyOfflineCredential('9999');
      expect(valid, isFalse);
    });

    test('verifyOfflineCredential returns false when no credential stored',
        () async {
      // No setupPin called — credential should not exist
      final valid = await svc.verifyOfflineCredential('1234');
      expect(valid, isFalse);
    });

    test('verifyOfflineCredential returns false when credential expired',
        () async {
      await svc.setupPin('1234');
      // Force expiry to be in the past
      final pastTime = DateTime.now()
          .subtract(const Duration(days: 8))
          .millisecondsSinceEpoch;
      await storage.write(
          key: 'asha_offline_exp_v1', value: pastTime.toString());
      final valid = await svc.verifyOfflineCredential('1234');
      expect(valid, isFalse);
    });
  });

  group('Biometric authentication', () {
    test('returns false when device does not support biometrics', () async {
      when(() => mockAuth.canCheckBiometrics)
          .thenAnswer((_) async => false);
      when(() => mockAuth.isDeviceSupported())
          .thenAnswer((_) async => false);

      final result =
          await svc.authenticateWithBiometric(localizedReason: 'Test');
      expect(result, isFalse);
    });

    test('returns true on successful biometric authentication', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            biometricOnly: any(named: 'biometricOnly'),
            persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
          )).thenAnswer((_) async => true);

      final result =
          await svc.authenticateWithBiometric(localizedReason: 'Test');
      expect(result, isTrue);
    });

    test('increments failure count on biometric failure', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            biometricOnly: any(named: 'biometricOnly'),
            persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
          )).thenAnswer((_) async => false);

      expect(svc.shouldFallBackToPin, isFalse);
      await svc.authenticateWithBiometric(localizedReason: 'Test');
      await svc.authenticateWithBiometric(localizedReason: 'Test');
      await svc.authenticateWithBiometric(localizedReason: 'Test');
      expect(svc.shouldFallBackToPin, isTrue);
    });

    test('returns false after 3 consecutive biometric failures', () async {
      when(() => mockAuth.canCheckBiometrics).thenAnswer((_) async => true);
      when(() => mockAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            biometricOnly: any(named: 'biometricOnly'),
            persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
          )).thenAnswer((_) async => false);

      // 3 failures
      for (var i = 0; i < 3; i++) {
        await svc.authenticateWithBiometric(localizedReason: 'Test');
      }

      // 4th attempt — should return false without calling local_auth
      final result =
          await svc.authenticateWithBiometric(localizedReason: 'Test');
      expect(result, isFalse);
      // authenticate should have been called exactly 3 times (not 4)
      verify(() => mockAuth.authenticate(
            localizedReason: any(named: 'localizedReason'),
            biometricOnly: any(named: 'biometricOnly'),
            persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
          )).called(3);
    });
  });

  group('Lockout escalation', () {
    test('first failure lockout is 30 seconds', () async {
      await svc.setupPin('1234');
      final result = await svc.verifyPin('0000');
      expect(result.state, AuthState.lockedOut);
      // Allow a 2-second window for test execution time
      expect(result.lockoutRemainingSeconds, inInclusiveRange(28, 30));
    });

    test('second failure lockout is 60 seconds', () async {
      await svc.setupPin('1234');
      await svc.verifyPin('0000'); // 1st failure
      // Expire first lockout
      final pastTime = DateTime.now()
          .subtract(const Duration(seconds: 60))
          .millisecondsSinceEpoch;
      await storage.write(
          key: 'asha_lockout_until_v1', value: pastTime.toString());
      final result = await svc.verifyPin('0000'); // 2nd failure
      expect(result.lockoutRemainingSeconds, inInclusiveRange(58, 60));
    });

    test('lockout does not exceed 600 seconds (10 minutes)', () async {
      await svc.setupPin('1234');
      // Drive through 10 failures to ensure cap is respected
      for (var i = 0; i < 4; i++) {
        await svc.verifyPin('0000');
        final pastTime = DateTime.now()
            .subtract(const Duration(seconds: 700))
            .millisecondsSinceEpoch;
        await storage.write(
            key: 'asha_lockout_until_v1', value: pastTime.toString());
      }
      final result = await svc.verifyPin('0000');
      expect(result.lockoutRemainingSeconds, lessThanOrEqualTo(600));
    });
  });
}
