import 'dart:ffi';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// SQLCipher is only available on Android/iOS; import conditionally.
import 'package:sqlite3/open.dart';

import 'tables/users_table.dart';
import 'tables/households_table.dart';
import 'tables/members_table.dart';
import 'tables/consent_records_table.dart';
import 'tables/clinical_encounters_table.dart';
import 'tables/clinical_observations_table.dart';
import 'tables/triage_results_table.dart';
import 'tables/referral_records_table.dart';
import 'tables/visit_schedules_table.dart';
import 'tables/incentive_events_table.dart';
import 'tables/incentive_claims_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/rule_versions_table.dart';
import 'tables/audit_log_table.dart';
import 'tables/drafts_table.dart';
import 'tables/stock_items_table.dart';
import 'tables/stock_transactions_table.dart';
import 'tables/facility_directory_table.dart';
import 'tables/learning_progress_table.dart';
import 'tables/device_profiles_table.dart';

export 'tables/users_table.dart';
export 'tables/households_table.dart';
export 'tables/members_table.dart';
export 'tables/consent_records_table.dart';
export 'tables/clinical_encounters_table.dart';
export 'tables/clinical_observations_table.dart';
export 'tables/triage_results_table.dart';
export 'tables/referral_records_table.dart';
export 'tables/visit_schedules_table.dart';
export 'tables/incentive_events_table.dart';
export 'tables/incentive_claims_table.dart';
export 'tables/sync_queue_table.dart';
export 'tables/rule_versions_table.dart';
export 'tables/audit_log_table.dart';
export 'tables/drafts_table.dart';
export 'tables/stock_items_table.dart';
export 'tables/stock_transactions_table.dart';
export 'tables/facility_directory_table.dart';
export 'tables/learning_progress_table.dart';
export 'tables/device_profiles_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Users,
  Households,
  Members,
  ConsentRecords,
  ClinicalEncounters,
  ClinicalObservations,
  TriageResults,
  ReferralRecords,
  VisitSchedules,
  IncentiveEvents,
  IncentiveClaims,
  SyncQueue,
  RuleVersions,
  AuditLog,
  Drafts,
  StockItems,
  StockTransactions,
  FacilityDirectory,
  LearningProgress,
  DeviceProfiles,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e) {
    setupSqliteForPlatform();
  }
  AppDatabase.forTesting(super.e) {
    setupSqliteForPlatform();
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
          await _createFts5();
        },
        onUpgrade: (m, from, to) async {},
        beforeOpen: (_) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sync_queue_pending '
      'ON sync_queue(priority ASC, created_at ASC) '
      "WHERE sync_status = 'pending'",
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_visit_schedules_due '
      'ON visit_schedules(due_date, status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_encounters_member_program '
      'ON clinical_encounters(member_id, program_code, encounter_date DESC)',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_incentive_idempotency '
      'ON incentive_events(idempotency_key)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_audit_log_record '
      'ON audit_log(table_name, record_id, device_timestamp)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_members_household '
      'ON members(household_id)',
    );
  }

  Future<void> _createFts5() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS members_fts USING fts5(
        member_id UNINDEXED,
        name,
        name_phonetic,
        abha_id,
        rch_id,
        phone,
        village,
        content="members",
        content_rowid="rowid"
      )
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS members_fts_ai
      AFTER INSERT ON members BEGIN
        INSERT INTO members_fts(member_id, name, name_phonetic, abha_id, rch_id, phone, village)
        VALUES (new.id, new.name, new.name_phonetic, new.abha_id, new.rch_id, new.phone,
          (SELECT village FROM households WHERE id = new.household_id));
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS members_fts_ad
      AFTER DELETE ON members BEGIN
        INSERT INTO members_fts(members_fts, member_id, name, name_phonetic, abha_id, rch_id, phone, village)
        VALUES ('delete', old.id, old.name, old.name_phonetic, old.abha_id, old.rch_id, old.phone, '');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS members_fts_au
      AFTER UPDATE ON members BEGIN
        INSERT INTO members_fts(members_fts, member_id, name, name_phonetic, abha_id, rch_id, phone, village)
        VALUES ('delete', old.id, old.name, old.name_phonetic, old.abha_id, old.rch_id, old.phone, '');
        INSERT INTO members_fts(member_id, name, name_phonetic, abha_id, rch_id, phone, village)
        VALUES (new.id, new.name, new.name_phonetic, new.abha_id, new.rch_id, new.phone,
          (SELECT village FROM households WHERE id = new.household_id));
      END
    ''');
  }
}

/// Opens the production local store with a SQLCipher key.
///
/// A nullable key silently produces a plaintext SQLite database, which is not
/// acceptable for patient data. Callers must unlock the database session with
/// the PIN-derived key before opening it.
QueryExecutor openEncryptedDatabase({required String encryptionKey}) {
  if (encryptionKey.length != 64 || !RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(encryptionKey)) {
    throw ArgumentError.value(encryptionKey, 'encryptionKey', 'Expected a 32-byte hexadecimal SQLCipher key');
  }
  return LazyDatabase(() async {
    setupSqliteForPlatform();
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'asha_platform.db'));
    return NativeDatabase(
      file,
      setup: (db) {
        db.execute("PRAGMA key = \"x'$encryptionKey'\";");
        db.execute('PRAGMA cipher_compatibility = 4;');
      },
      logStatements: false,
    );
  });
}

/// Dynamic library configuration for SQLite / SQLCipher on Android and Linux.
void setupSqliteForPlatform() {
  if (kIsWeb) return;
  if (Platform.isAndroid) {
    try {
      open.overrideFor(OperatingSystem.android, () {
        return DynamicLibrary.open('libsqlcipher.so');
      });
    } catch (_) {
      // Ignore if override fails
    }
  } else if (Platform.isLinux) {
    try {
      open.overrideFor(OperatingSystem.linux, () {
        try {
          return DynamicLibrary.open('libsqlite3.so');
        } catch (_) {
          return DynamicLibrary.open('libsqlite3.so.0');
        }
      });
    } catch (_) {
      // Ignore if override fails
    }
  }
}

