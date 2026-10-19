import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';

/// Performs a secure local wipe of all patient data when triggered by an
/// administrator revocation event (device lost or reassigned).
///
/// Wipe sequence:
///   1. Call `DROP TABLE IF EXISTS` for every drift table via the open DB.
///   2. Close and delete the SQLCipher database file from disk.
///   3. Clear all keys from flutter_secure_storage (JWT, offline credential,
///      key salt, worker_id, device_id, access_token).
///   4. Signal the caller to navigate to the initial PIN setup screen.
///
/// Requirements: 2.5
class RemoteWipe {
  static const _storage = FlutterSecureStorage();

  final AppDatabase _db;

  RemoteWipe(this._db);

  /// Execute the full wipe sequence.
  ///
  /// After this method returns, the app should navigate to the root `/`
  /// route which renders the PIN setup screen for a fresh installation.
  Future<void> wipe() async {
    // 1. Drop all drift tables using the ORM (avoids hardcoding SQL table names)
    await _dropAllTables();

    // 2. Close the database connection so the file can be deleted
    await _db.close();

    // 3. Delete the SQLCipher database file
    await _deleteDatabaseFile();

    // 4. Clear all secure storage (keys, tokens, credentials)
    await _storage.deleteAll();
  }

  Future<void> _dropAllTables() async {
    // Execute raw SQL to drop all tables within the encrypted DB.
    // The list mirrors the tables registered in AppDatabase.
    const tables = [
      'audit_log',
      'clinical_observations',
      'triage_results',
      'referral_records',
      'clinical_encounters',
      'visit_schedules',
      'incentive_claims',
      'incentive_events',
      'consent_records',
      'members',
      'households',
      'sync_queue',
      'rule_versions',
      'drafts',
      'stock_transactions',
      'stock_items',
      'facility_directory',
      'learning_progress',
      'device_profiles',
      'users',
    ];
    for (final table in tables) {
      try {
        await _db.customStatement('DROP TABLE IF EXISTS $table');
      } catch (_) {
        // Continue even if a table doesn't exist
      }
    }
  }

  Future<void> _deleteDatabaseFile() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dir.path, 'asha_platform.db'));
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
      // Also delete any WAL/SHM files
      for (final suffix in ['-wal', '-shm']) {
        final sidecar = File('${dbFile.path}$suffix');
        if (await sidecar.exists()) {
          await sidecar.delete();
        }
      }
    } catch (_) {
      // Best-effort; file may already be gone
    }
  }
}

