import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/bhasha/onnx_preload.dart';
import 'core/database/app_database.dart';
import 'core/sync/sync_worker.dart';
import 'firebase_options.dart';

/// Application entry point.
///
/// [WidgetsFlutterBinding.ensureInitialized] is required before accessing
/// platform channels (used by path_provider, flutter_secure_storage, etc.).
///
/// [ProviderScope] is the root Riverpod container — all providers declared
/// with @riverpod live inside this scope.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL and SUPABASE_ANON_KEY must be supplied with --dart-define.',
    );
  }
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Dolphin and IndicTrans2 share one ONNX Runtime. Open it for the process
  // before sherpa looks up OrtGetApiBase.
  preloadOnnxRuntime();
  await sherpa.initBindingsAsync();
  setupSqliteForPlatform();
  const apiBaseUrl = String.fromEnvironment(
    'ASHA_API_BASE_URL',
    defaultValue: 'https://asha-backend-1akc.onrender.com',
  );
  const pins = String.fromEnvironment('ASHA_API_SHA256_PINS');
  // The hosted HTTPS endpoint can use the platform trust store when no
  // deployment pin is supplied. This keeps foreground and WorkManager sync
  // enabled in normal debug/release builds while still allowing optional pins.
  if (apiBaseUrl.isNotEmpty) {
    await SyncScheduler().initialise(
      apiBaseUrl: apiBaseUrl,
      certificatePins: pins.isEmpty ? const [] : pins.split(','),
    );
  }
  runApp(const ProviderScope(child: AshaApp()));
}
