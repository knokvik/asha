import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../database/app_database.dart';
import 'sync_engine.dart';
import 'sync_worker.dart';

enum SyncConnectionState { offline, ready, syncing, error }

class SyncSnapshot {
  final SyncConnectionState state;
  final List<SyncQueueData> records;
  final DateTime? lastSyncedAt;
  final String? errorMessage;
  final bool isConnected;

  const SyncSnapshot({
    this.state = SyncConnectionState.offline,
    this.records = const [],
    this.lastSyncedAt,
    this.errorMessage,
    this.isConnected = false,
  });

  bool get isConnectedToServer => isConnected || state == SyncConnectionState.ready;

  int get pendingCount => records
      .where(
        (record) =>
            record.syncStatus == 'pending' || record.syncStatus == 'failed',
      )
      .length;

  int get failedCount =>
      records.where((record) => record.syncStatus == 'failed').length;

  bool get hasPackets => records.isNotEmpty;
}

/// Foreground sync coordinator for the small top-bar status control.
///
/// WorkManager remains responsible for background delivery. This coordinator
/// adds the user-visible experience: it monitors the encrypted local queue,
/// retries failed packets when the device becomes reachable again, and lets an
/// ASHA worker trigger a sync immediately from the queue screen.
class SyncCoordinator extends ChangeNotifier {
  final AppDatabase _database;
  final Duration pollInterval;
  final FlutterSecureStorage _storage;
  final SyncEngine _engine;

  Timer? _pollTimer;
  bool _started = false;
  bool _syncInFlight = false;
  SyncSnapshot _snapshot = const SyncSnapshot();

  SyncCoordinator(
    this._database, {
    this.pollInterval = const Duration(seconds: 15),
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _engine = SyncEngine(_database);

  SyncSnapshot get snapshot => _snapshot;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await checkServerConnectivity();
    await refresh();
    _pollTimer = Timer.periodic(pollInterval, (_) => _poll());
  }

  Future<bool> checkServerConnectivity() async {
    try {
      final apiBaseUrl = await _storage.read(key: 'sync_api_base_url') ??
          'http://localhost:8000';
      final cleanUrl = apiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
      final res = await http
          .get(Uri.parse('$cleanUrl/healthz'))
          .timeout(const Duration(seconds: 3));
      final connected = res.statusCode == 200;
      _snapshot = SyncSnapshot(
        state: connected ? SyncConnectionState.ready : SyncConnectionState.offline,
        records: _snapshot.records,
        lastSyncedAt: _snapshot.lastSyncedAt,
        errorMessage: connected ? null : 'Server unreachable',
        isConnected: connected,
      );
      notifyListeners();
      return connected;
    } catch (_) {
      _snapshot = SyncSnapshot(
        state: SyncConnectionState.offline,
        records: _snapshot.records,
        lastSyncedAt: _snapshot.lastSyncedAt,
        errorMessage: 'Offline',
        isConnected: false,
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> refresh() async {
    final records = await _engine.fetchQueue();
    _snapshot = SyncSnapshot(
      state: _snapshot.state,
      records: records,
      lastSyncedAt: _snapshot.lastSyncedAt,
      errorMessage: _snapshot.errorMessage,
      isConnected: _snapshot.isConnected,
    );
    notifyListeners();
  }

  Future<void> syncNow() async {
    if (_syncInFlight) return;
    _syncInFlight = true;
    _snapshot = SyncSnapshot(
      state: SyncConnectionState.syncing,
      records: _snapshot.records,
      lastSyncedAt: _snapshot.lastSyncedAt,
      isConnected: _snapshot.isConnected,
    );
    notifyListeners();

    try {
      await _engine.requeueRetryable();
      final worker = await SyncWorker.fromStoredConfig(
        db: _database,
        storage: _storage,
      );
      if (worker == null) {
        await _finish(
          SyncConnectionState.offline,
          error:
              'No sync server is configured. Your packets remain on this device.',
        );
        return;
      }

      final success = await worker.run();
      await refresh();
      final hasFailedPackets = _snapshot.failedCount > 0;
      final synced = success && !hasFailedPackets;
      _snapshot = SyncSnapshot(
        state: synced ? SyncConnectionState.ready : SyncConnectionState.error,
        records: _snapshot.records,
        lastSyncedAt: synced ? DateTime.now() : _snapshot.lastSyncedAt,
        errorMessage: synced
            ? null
            : hasFailedPackets
            ? 'Some packets need review or another retry.'
            : 'Sync could not reach the server. It will retry automatically.',
        isConnected: synced || _snapshot.isConnected,
      );
      notifyListeners();
    } catch (error) {
      await _finish(
        SyncConnectionState.error,
        error: 'Sync could not reach the server: $error',
      );
    } finally {
      _syncInFlight = false;
    }
  }

  Future<void> _poll() async {
    if (_syncInFlight) return;
    await checkServerConnectivity();
    await refresh();
    if (_snapshot.pendingCount > 0 && _snapshot.isConnected) {
      await syncNow();
    }
  }

  Future<void> _finish(SyncConnectionState state, {String? error}) async {
    final records = await _engine.fetchQueue();
    _snapshot = SyncSnapshot(
      state: state,
      records: records,
      lastSyncedAt: _snapshot.lastSyncedAt,
      errorMessage: error,
      isConnected: state == SyncConnectionState.ready,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
