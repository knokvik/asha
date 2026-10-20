import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'app/app.dart';
import 'core/bhasha/onnx_preload.dart';
import 'core/database/app_database.dart';
import 'core/sync/sync_worker.dart';

/// Application entry point.
///
/// [WidgetsFlutterBinding.ensureInitialized] is required before accessing
/// platform channels (used by path_provider, flutter_secure_storage, etc.).
///
/// [ProviderScope] is the root Riverpod container — all providers declared
/// with @riverpod live inside this scope.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Dolphin and IndicTrans2 share one ONNX Runtime. Open it for the process
  // before sherpa looks up OrtGetApiBase.
  preloadOnnxRuntime();
  await sherpa.initBindingsAsync();
  setupSqliteForPlatform();
  const apiBaseUrl = String.fromEnvironment(
    'ASHA_API_BASE_URL',
    defaultValue: 'https://asha-setu.onrender.com',
  );
  const pins = String.fromEnvironment('ASHA_API_SHA256_PINS');
  // Deployment supplies a HTTPS base URL and comma-separated SHA-256 pins via
  // dart-defines. Local test/debug builds omit them and do not schedule work.
  // Remote sync still requires certificate pins; the default URL lets builds
  // target the hosted service without weakening the production transport.
  if (apiBaseUrl.isNotEmpty &&
      (pins.isNotEmpty || apiBaseUrl.startsWith('http://'))) {
    await SyncScheduler().initialise(
      apiBaseUrl: apiBaseUrl,
      certificatePins: pins.isEmpty ? const [] : pins.split(','),
    );
  }
  runApp(const ProviderScope(child: AshaApp()));
}
