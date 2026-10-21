import 'dart:convert';

import 'package:drift/drift.dart' show Value;
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

  /// Creates a foreground worker from the encrypted sync configuration.
  /// Returns null when the app has no server configured yet, which is a valid
  /// offline-only state during onboarding or local development.
  static Future<SyncWorker?> fromStoredConfig({
    required AppDatabase db,
    FlutterSecureStorage? storage,
  }) async {
    final secureStorage = storage ?? const FlutterSecureStorage();
    final apiBaseUrl = await secureStorage.read(key: _kApiBaseUrlKey);
    if (apiBaseUrl == null || apiBaseUrl.trim().isEmpty) return null;
    final pinsJson = await secureStorage.read(key: _kCertificatePinsKey);
    final pins = pinsJson == null || pinsJson.isEmpty
        ? const <String>[]
        : List<String>.from(jsonDecode(pinsJson) as List);
    return SyncWorker(db: db, apiBaseUrl: apiBaseUrl, certificatePins: pins);
  }

  // ── WorkManager entry point ───────────────────────────────────────────────

  /// Invoked by the WorkManager callback dispatcher.
  ///
  /// Returns true on success (workmanager expects bool result).
  Future<bool> run() async {
    try {
      await _drainQueue();
      await _pullDelta();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Core drain logic ──────────────────────────────────────────────────────

  Future<void> _drainQueue({bool retriedAfterRefresh = false}) async {
    final workerId = await _storage.read(key: 'worker_id') ?? '';
    // The local auth flow historically used the namespaced device key while
    // the network session used the shorter key. Accept both so an existing
    // installed app keeps the same device identity after upgrading.
    final deviceId =
        await _storage.read(key: 'device_id') ??
        await _storage.read(key: 'asha_device_id_v1') ??
        '';
    final accessToken = await _storage.read(key: 'access_token') ?? '';
    const appVersion = '1.0.0'; // TODO: read from package_info_plus

    await _syncEngine.requeueRetryable();
    final batch = await _syncEngine.fetchPendingBatch(limit: 50);
    if (batch.isEmpty) return;
    if (accessToken.isEmpty) {
      await _syncEngine.markFailed(
        batch.map((record) => record.id).toList(),
        'missing_server_session',
      );
      throw StateError(
        'Sync needs an online server session. Sign in once while connected, then retry.',
      );
    }

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
      final queueIdsByRecordId = {
        for (final record in batch) record.recordId: record.id,
      };
      try {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final syncedRecordIds = (payload['synced'] as List<dynamic>? ?? [])
            .whereType<String>()
            .toSet();
        final conflicts = (payload['conflicts'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        final conflictRecordIds = conflicts
            .map((item) => item['record_id'])
            .whereType<String>()
            .toSet();

        // A duplicate batch is intentionally returned with empty arrays by
        // the server because it has already been applied. It is safe to
        // acknowledge the local batch in that case.
        final acknowledged =
            syncedRecordIds.isEmpty && conflictRecordIds.isEmpty
            ? queueIdsByRecordId.keys.toSet()
            : syncedRecordIds;
        await _syncEngine.markSynced(
          acknowledged
              .map((recordId) => queueIdsByRecordId[recordId])
              .whereType<String>()
              .toList(),
        );
        if (conflictRecordIds.isNotEmpty) {
          await _syncEngine.markFailed(
            conflictRecordIds
                .map((recordId) => queueIdsByRecordId[recordId])
                .whereType<String>()
                .toList(),
            'conflict: review required on server',
          );
        }
      } catch (_) {
        // A 200 with an unreadable response must not silently discard packets.
        await _syncEngine.markFailed(
          batch.map((record) => record.id).toList(),
          'invalid_sync_response',
        );
        rethrow;
      }
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

  Future<void> _pullDelta() async {
    final workerId = await _storage.read(key: 'worker_id') ?? '';
    final accessToken = await _storage.read(key: 'access_token') ?? '';
    if (workerId.isEmpty || accessToken.isEmpty) return;

    final watermarksJson = await _storage.read(key: 'sync_watermarks') ?? '{}';
    final uri = Uri.parse('$apiBaseUrl/api/v1/sync/pull').replace(
      queryParameters: {'worker_id': workerId, 'watermarks': watermarksJson},
    );

    final headers = {
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    };

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final records = payload['records'] as List<dynamic>? ?? [];
        final serverWatermarks =
            payload['server_watermarks'] as Map<String, dynamic>?;
        if (serverWatermarks != null) {
          await _storage.write(
            key: 'sync_watermarks',
            value: jsonEncode(serverWatermarks),
          );
        }
        await _applyIncomingRecords(records);
      }
      await _pullHotspotContext(accessToken);
    } catch (_) {
      // Pull failure must not disrupt overall sync execution
    }
  }

  /// Pulls only block-level, cross-worker disease aggregates. The raw server
  /// response is cached in secure storage so the next offline triage session
  /// can activate the same area modules without network access.
  Future<void> _pullHotspotContext(String accessToken) async {
    final uri = Uri.parse('$apiBaseUrl/api/v1/sync/hotspots');
    final response = await http
        .get(uri, headers: {'Authorization': 'Bearer $accessToken'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200 || response.body.isEmpty) return;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return;
    await _storage.write(
      key: 'triage_hotspot_context_json',
      value: jsonEncode(decoded),
    );
    final notifications = decoded['notifications'];
    if (notifications is List) {
      await _storage.write(
        key: 'area_notifications_json',
        value: jsonEncode(notifications),
      );
    }
  }

  Future<void> _applyIncomingRecords(List<dynamic> records) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final raw in records) {
      if (raw is! Map<String, dynamic>) continue;
      final table = raw['_table']?.toString() ?? '';
      try {
        if (table == 'visit_schedules') {
          await _db
              .into(_db.visitSchedules)
              .insertOnConflictUpdate(
                VisitSchedulesCompanion.insert(
                  id: raw['id']?.toString() ?? '',
                  memberId: raw['member_id']?.toString() ?? '',
                  programCode: raw['program_code']?.toString() ?? 'ad_hoc',
                  visitType: raw['visit_type']?.toString() ?? 'Visit',
                  dueDate: (raw['due_date'] as num?)?.toInt() ?? now,
                  status: Value(raw['status']?.toString() ?? 'pending'),
                  createdAt: (raw['created_at'] as num?)?.toInt() ?? now,
                ),
              );
        } else if (table == 'households') {
          await _db
              .into(_db.households)
              .insertOnConflictUpdate(
                HouseholdsCompanion.insert(
                  id: raw['id']?.toString() ?? '',
                  village: raw['village']?.toString() ?? 'Shahpur',
                  hamlet: Value(raw['hamlet']?.toString()),
                  headName: raw['head_name']?.toString() ?? 'Head of Household',
                  memberCount: Value(
                    (raw['member_count'] as num?)?.toInt() ?? 1,
                  ),
                  createdAt: (raw['created_at'] as num?)?.toInt() ?? now,
                  updatedAt: (raw['updated_at'] as num?)?.toInt() ?? now,
                  createdBy: raw['created_by']?.toString() ?? 'worker',
                ),
              );
        } else if (table == 'members') {
          await _db
              .into(_db.members)
              .insertOnConflictUpdate(
                MembersCompanion.insert(
                  id: raw['id']?.toString() ?? '',
                  householdId: raw['household_id']?.toString() ?? '',
                  name: raw['name']?.toString() ?? 'Beneficiary',
                  sex: raw['sex']?.toString() ?? 'F',
                  phone: Value(raw['phone']?.toString()),
                  createdAt: (raw['created_at'] as num?)?.toInt() ?? now,
                  updatedAt: (raw['updated_at'] as num?)?.toInt() ?? now,
                  createdBy: raw['created_by']?.toString() ?? 'worker',
                ),
              );
        } else if (table == 'users') {
          await _db
              .into(_db.users)
              .insertOnConflictUpdate(
                UsersCompanion.insert(
                  id: raw['id']?.toString() ?? '',
                  ashaId: raw['asha_id']?.toString() ?? '',
                  name: raw['name']?.toString() ?? '',
                  role: raw['role']?.toString() ?? 'ASHA',
                  areaVillage: Value(raw['area_village']?.toString()),
                  areaSubcentre: Value(raw['area_subcentre']?.toString()),
                  areaPhc: Value(raw['area_phc']?.toString()),
                  areaBlock: Value(raw['area_block']?.toString()),
                  areaDistrict: Value(raw['area_district']?.toString()),
                  areaState: Value(raw['area_state']?.toString()),
                  createdAt: (raw['created_at'] as num?)?.toInt() ?? now,
                  updatedAt: (raw['updated_at'] as num?)?.toInt() ?? now,
                ),
              );
        } else if (table == 'facility_directory') {
          await _db
              .into(_db.facilityDirectory)
              .insertOnConflictUpdate(
                FacilityDirectoryCompanion.insert(
                  id: raw['id']?.toString() ?? '',
                  name: raw['name']?.toString() ?? '',
                  facilityLevel: raw['facility_level']?.toString() ?? 'PHC',
                  district: Value(raw['district']?.toString()),
                  block: Value(raw['block']?.toString()),
                  village: Value(raw['village']?.toString()),
                  latitude: Value((raw['latitude'] as num?)?.toDouble()),
                  longitude: Value((raw['longitude'] as num?)?.toDouble()),
                  contactPhone: Value(raw['contact_phone']?.toString()),
                  servicesJson: Value(raw['services_json']?.toString() ?? '[]'),
                  isActive: Value(raw['is_active'] as bool? ?? true),
                  lastUpdatedAt:
                      (raw['last_updated_at'] as num?)?.toInt() ?? now,
                ),
              );
        } else if (table == 'clinical_encounters') {
          await _db
              .into(_db.clinicalEncounters)
              .insertOnConflictUpdate(
                ClinicalEncountersCompanion.insert(
                  id: raw['id']?.toString() ?? '',
                  memberId: raw['member_id']?.toString() ?? '',
                  encounterType: raw['encounter_type']?.toString() ?? 'general',
                  programCode: raw['program_code']?.toString() ?? 'general',
                  encounterDate:
                      (raw['encounter_date'] as num?)?.toInt() ?? now,
                  ashaId: raw['asha_id']?.toString() ?? '',
                  status: Value(raw['status']?.toString() ?? 'completed'),
                  visitNotes: Value(raw['visit_notes']?.toString()),
                  createdAt: (raw['created_at'] as num?)?.toInt() ?? now,
                  updatedAt: (raw['updated_at'] as num?)?.toInt() ?? now,
                  syncStatus: const Value('synced'),
                ),
              );
        } else if (table == 'triage_results') {
          await _db
              .into(_db.triageResults)
              .insertOnConflictUpdate(
                TriageResultsCompanion.insert(
                  id: raw['id']?.toString() ?? '',
                  encounterId: raw['encounter_id']?.toString() ?? '',
                  flag: raw['flag']?.toString() ?? 'GREEN',
                  ruleVersionId:
                      raw['rule_version_id']?.toString() ?? 'v1.0-mohfw',
                  findingsJson: raw['findings_json']?.toString() ?? '[]',
                  evaluatedAt: (raw['evaluated_at'] as num?)?.toInt() ?? now,
                ),
              );
        }
      } catch (_) {}
    }
  }

  /// Compute the backoff duration for the given [attemptCount] (0-indexed).
  static Duration backoffFor(int attemptCount) =>
      SyncBackoff.forAttempt(attemptCount);
}
