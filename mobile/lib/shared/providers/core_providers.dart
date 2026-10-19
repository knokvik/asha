import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/demo_data_seeder.dart';
import '../../core/security/auth_service.dart';
import '../../core/security/idle_lock_service.dart';
import '../../core/security/key_manager.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/triage/triage_engine.dart';

part 'core_providers.g.dart';

/// SQLCipher key for the current unlocked session. It is deliberately kept
/// only in memory and is cleared when the provider container is disposed.
class DatabaseKeyNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void unlock(String key) => state = key;

  void lock() => state = null;
}

final databaseKeyProvider =
    NotifierProvider<DatabaseKeyNotifier, String?>(DatabaseKeyNotifier.new);

/// Keeps key derivation injectable for tests while production uses
/// Android-Keystore-backed secure storage.
final keyManagerProvider = Provider<KeyManager>((ref) => KeyManager());

/// Database provider (kept alive across the application lifecycle).
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final encryptionKey = ref.watch(databaseKeyProvider);
  if (encryptionKey == null) {
    throw StateError('Database access requires an unlocked PIN session.');
  }
  final db = AppDatabase(openEncryptedDatabase(encryptionKey: encryptionKey));
  DemoDataSeeder.seedIfEmpty(db);
  return db;
}

/// Triage engine provider (pure rule evaluator, kept alive).
@Riverpod(keepAlive: true)
TriageEngine triageEngine(Ref ref) {
  return TriageEngine();
}

/// BitChat sync engine provider (priority queue, kept alive).
@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncEngine(db);
}

/// PIN and biometric authentication service provider (kept alive).
@Riverpod(keepAlive: true)
AuthService authService(Ref ref) {
  return AuthService();
}

/// Idle-lock service provider (kept alive).
@Riverpod(keepAlive: true)
IdleLockService idleLockService(Ref ref) {
  final service = IdleLockService(
    timeout: const Duration(minutes: 2),
    onLock: () {},
  );
  service.start();
  ref.onDispose(service.dispose);
  return service;
}
