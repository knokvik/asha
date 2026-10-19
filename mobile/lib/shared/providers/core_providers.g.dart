// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Database provider (kept alive across the application lifecycle).

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Database provider (kept alive across the application lifecycle).

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Database provider (kept alive across the application lifecycle).
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'2d6df27e376426d7b6384df7dd7fcb764bfecda6';

/// Triage engine provider (pure rule evaluator, kept alive).

@ProviderFor(triageEngine)
final triageEngineProvider = TriageEngineProvider._();

/// Triage engine provider (pure rule evaluator, kept alive).

final class TriageEngineProvider
    extends $FunctionalProvider<TriageEngine, TriageEngine, TriageEngine>
    with $Provider<TriageEngine> {
  /// Triage engine provider (pure rule evaluator, kept alive).
  TriageEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'triageEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$triageEngineHash();

  @$internal
  @override
  $ProviderElement<TriageEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TriageEngine create(Ref ref) {
    return triageEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TriageEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TriageEngine>(value),
    );
  }
}

String _$triageEngineHash() => r'68652c96685f919dcc6c1cf97bbbc2e228e1de77';

/// BitChat sync engine provider (priority queue, kept alive).

@ProviderFor(syncEngine)
final syncEngineProvider = SyncEngineProvider._();

/// BitChat sync engine provider (priority queue, kept alive).

final class SyncEngineProvider
    extends $FunctionalProvider<SyncEngine, SyncEngine, SyncEngine>
    with $Provider<SyncEngine> {
  /// BitChat sync engine provider (priority queue, kept alive).
  SyncEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncEngineHash();

  @$internal
  @override
  $ProviderElement<SyncEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncEngine create(Ref ref) {
    return syncEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncEngine>(value),
    );
  }
}

String _$syncEngineHash() => r'49c3f56da2d145c7f4adc82dc1142dec8dabe677';

/// PIN and biometric authentication service provider (kept alive).

@ProviderFor(authService)
final authServiceProvider = AuthServiceProvider._();

/// PIN and biometric authentication service provider (kept alive).

final class AuthServiceProvider
    extends $FunctionalProvider<AuthService, AuthService, AuthService>
    with $Provider<AuthService> {
  /// PIN and biometric authentication service provider (kept alive).
  AuthServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  $ProviderElement<AuthService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthService create(Ref ref) {
    return authService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthService>(value),
    );
  }
}

String _$authServiceHash() => r'1a086f396b6916ee8c5a9a14df3ece637f134805';

/// Idle-lock service provider (kept alive).

@ProviderFor(idleLockService)
final idleLockServiceProvider = IdleLockServiceProvider._();

/// Idle-lock service provider (kept alive).

final class IdleLockServiceProvider
    extends
        $FunctionalProvider<IdleLockService, IdleLockService, IdleLockService>
    with $Provider<IdleLockService> {
  /// Idle-lock service provider (kept alive).
  IdleLockServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'idleLockServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$idleLockServiceHash();

  @$internal
  @override
  $ProviderElement<IdleLockService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IdleLockService create(Ref ref) {
    return idleLockService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdleLockService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IdleLockService>(value),
    );
  }
}

String _$idleLockServiceHash() => r'64220ec40c88d31f52628f73e1b7a18112acfb15';
