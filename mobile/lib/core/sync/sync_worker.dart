import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:workmanager/workmanager.dart';

import '../database/app_database.dart';
import '../security/key_manager.dart';
import '../security/session_service.dart';
import 'sync_engine.dart';
import 'certificate_pinning.dart';

/// Backoff schedule in seconds: 30s → 60s → 120s → 300s (max).
const _kBackoffSchedule = [30, 60, 120, 300];
const _kPeriodicSyncTask = 'asha-periodic-sync';
const _kUrgentSyncTask = 'asha-urgent-sync';
const _kApiBaseUrlKey = 'sync_api_base_url';
const _kCertificatePinsKey = 'sync_certificate_pins';

/// Top-level entry point retained by the compiler for Android's headless
/// WorkManager isolate.
@pragma('vm:entry-point')
void syncCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    final storage = FlutterSecureStorage();
    final databaseKey = await KeyManager().readBackgroundDatabaseKey();
    final apiBaseUrl = await storage.read(key: _kApiBaseUrlKey);
    if (databaseKey == null || apiBaseUrl == null) return false;
    final pinsJson = await storage.read(key: _kCertificatePinsKey);
    final pins = pinsJson == null
        ? const <String>[]
        : List<String>.from(jsonDecode(pinsJson) as List);
    final db = AppDatabase(openEncryptedDatabase(encryptionKey: databaseKey));
    try {
      return await SyncWorker(
        db: db,
        apiBaseUrl: apiBaseUrl,
        certificatePins: pins,
      ).run();
    } finally {
      try {
        await db.close();
      } catch (_) {
        // RemoteWipe closes the database before deleting it.
      }
    }
  });
}

/// Registers encrypted background synchronisation and P1 expedited sync.
class SyncScheduler {
  static final _constraints = Constraints(
    networkType: NetworkType.connected,
    requiresBatteryNotLow: true,
    requiresStorageNotLow: true,
  );

  final FlutterSecureStorage _storage;

  SyncScheduler({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> initialise({
    required String apiBaseUrl,
    required List<String> certificatePins,
  }) async {
    await _storage.write(key: _kApiBaseUrlKey, value: apiBaseUrl);
    await _storage.write(
      key: _kCertificatePinsKey,
      value: jsonEncode(certificatePins),
    );
    await Workmanager().initialize(syncCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _kPeriodicSyncTask,
      _kPeriodicSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: _constraints,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 30),
    );
  }

  Future<void> scheduleUrgentSync() => Workmanager().registerOneOffTask(
    _kUrgentSyncTask,
    _kUrgentSyncTask,
    constraints: _constraints,
    expedited: true,
    existingWorkPolicy: ExistingWorkPolicy.replace,
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(seconds: 30),
  );
}

/// WorkManager Dart entry point for background sync.
///
/// Drains the top-50 pending sync_queue entries (ordered by priority, then
/// created_at), builds a gzip-compressed delta payload, and POSTs it to
/// `POST /api/v1/sync/push`. Updates sync_status per record on response.
///
/// Constraints: network required, battery not low, storage not low.
/// Backoff schedule: 30 s → 60 s → 120 s → 300 s (max).
///
/// Requirements: 31.1, 31.2, 31.3, 31.6
class SyncWorker {
  static const _storage = FlutterSecureStorage();
  static const _uuid = Uuid();

  final SyncEngine _syncEngine;
  final String apiBaseUrl;
  final List<String> certificatePins;
  final AppDatabase _db;

  SyncWorker({
    required AppDatabase db,
    required this.apiBaseUrl,
    this.certificatePins = const [],
  }) : _db = db,
       _syncEngine = SyncEngine(db);

  // ── WorkManager entry point ───────────────────────────────────────────────

  /// Invoked by the WorkManager callback dispatcher.
  ///
  /// Returns true on success (workmanager expects bool result).
  Future<bool> run() async {
    try {
      await _drainQueue();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Core drain logic ──────────────────────────────────────────────────────

  Future<void> _drainQueue({bool retriedAfterRefresh = false}) async {
    final workerId = await _storage.read(key: 'worker_id') ?? '';
    final deviceId = await _storage.read(key: 'device_id') ?? '';
    final accessToken = await _storage.read(key: 'access_token') ?? '';
    const appVersion = '1.0.0'; // TODO: read from package_info_plus

    final batch = await _syncEngine.fetchPendingBatch(limit: 50);
    if (batch.isEmpty) return;

    final batchId = _uuid.v4();
    final gzipBody = await _syncEngine.buildGzipPayload(
      workerId: workerId,
      deviceId: deviceId,
      appVersion: appVersion,
      batchId: batchId,
      records: batch,
    );

    final endpoint = Uri.parse('$apiBaseUrl/api/v1/sync/push');
    final headers = {
      'Content-Type': 'application/json',
      'Content-Encoding': 'gzip',
      'Authorization': 'Bearer $accessToken',
    };
    final response = endpoint.scheme == 'https'
        ? await PinnedHttpTransport(sha256Fingerprints: certificatePins)
              .post(endpoint, headers: headers, body: gzipBody)
              .timeout(const Duration(seconds: 30))
        : await http
              .post(endpoint, headers: headers, body: gzipBody)
              .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final queueIds = batch.map((r) => r.id).toList();
      await _syncEngine.markSynced(queueIds);
    } else if (response.statusCode == 401) {
      // Access tokens are short-lived. Refresh first; only a rejected refresh
      // token is proof of a remote revocation and triggers RemoteWipe.
      if (!retriedAfterRefresh) {
        final refresh = await SessionService(
          apiBaseUrl: apiBaseUrl,
          certificatePins: certificatePins,
          database: _db,
        ).refreshAccessToken();
        if (refresh == SessionRefreshResult.refreshed) {
          await _drainQueue(retriedAfterRefresh: true);
          return;
        }
        if (refresh == SessionRefreshResult.rejected) {
          throw StateError(
            'Device access was revoked and local data was wiped.',
          );
        }
      }
      final queueIds = batch.map((r) => r.id).toList();
      await _syncEngine.markFailed(queueIds, 'unauthorised');
      throw StateError('Sync is unauthorised; sign in again when online.');
    } else if (response.statusCode == 409) {
      // Conflicts returned — re-enqueue at P2 after conflict resolver runs.
      final queueIds = batch.map((r) => r.id).toList();
      await _syncEngine.markFailed(
        queueIds,
        'conflict: ${response.statusCode}',
      );
    } else {
      final queueIds = batch.map((r) => r.id).toList();
      await _syncEngine.markFailed(
        queueIds,
        'http_error: ${response.statusCode}',
      );
      throw Exception('Sync push failed: ${response.statusCode}');
    }
  }

  /// Compute the backoff duration for the given [attemptCount] (0-indexed).
  static Duration backoffFor(int attemptCount) {
    final idx = attemptCount.clamp(0, _kBackoffSchedule.length - 1);
    return Duration(seconds: _kBackoffSchedule[idx]);
  }
}
