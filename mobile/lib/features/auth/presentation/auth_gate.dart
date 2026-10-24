import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/demo_data_seeder.dart';
import '../../../core/security/api_session_bridge.dart';
import '../../../core/security/api_token.dart';
import '../../../services/auth_service.dart';
import '../../../shared/providers/core_providers.dart';
import 'pin_setup_screen.dart';
import '../../../shared/shell/main_shell.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  String? _bootstrappedUserId;
  Future<void>? _bootstrapFuture;

  Future<void> _bootstrapDatabase(User user) {
    if (_bootstrappedUserId == user.id && _bootstrapFuture != null) {
      return _bootstrapFuture!;
    }

    _bootstrappedUserId = user.id;
    _bootstrapFuture = _unlockDatabase(user);
    return _bootstrapFuture!;
  }

  Future<void> _unlockDatabase(User user) async {
    final existingKey = await ref.read(keyManagerProvider).readBackgroundDatabaseKey();
    final key = existingKey ??
        await ref.read(keyManagerProvider).deriveKey('supabase:${user.id}');
    if (!mounted) return;
    ref.read(databaseKeyProvider.notifier).unlock(key);
    
    // Seed real demo beneficiaries if local DB is currently empty
    try {
      final db = ref.read(appDatabaseProvider);
      await DemoDataSeeder.seedIfEmpty(db);
    } catch (_) {}

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      const storage = FlutterSecureStorage();
      // Keep the Supabase session away from the API bearer. Sync rejects it
      // and the queue used to show that rejection as "unauthorized".
      await storage.write(key: 'supabase_access_token', value: session.accessToken);
      await storage.write(key: 'supabase_user_id', value: user.id);
      final current = await storage.read(key: 'access_token');
      if (current != null && !isApiAccessToken(current)) {
        await storage.delete(key: 'access_token');
      }
      final apiBase = await storage.read(key: 'sync_api_base_url');
      if (apiBase != null && apiBase.isNotEmpty) {
        await ApiSessionBridge().adoptSupabaseSession(apiBaseUrl: apiBase);
      }
    }
    // A fresh authenticated session must see the current Supabase registry,
    // not only records newer than a watermark left by an older install.
    await const FlutterSecureStorage().delete(key: 'sync_watermarks');
    final coordinator = ref.read(syncCoordinatorProvider);
    if (coordinator != null) {
      await coordinator.start();
      if (coordinator.snapshot.isConnectedToServer) {
        await coordinator.syncNow();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return StreamBuilder<AuthState>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data?.session?.user ?? auth.currentUser;
        if (user == null) {
          _bootstrappedUserId = null;
          _bootstrapFuture = null;
          return const PinSetupScreen();
        }

        return FutureBuilder<void>(
          future: _bootstrapDatabase(user),
          builder: (context, bootstrapSnapshot) {
            if (bootstrapSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to open secure local storage. Please sign in again.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
              );
            }
            if (bootstrapSnapshot.connectionState != ConnectionState.done ||
                ref.watch(databaseKeyProvider) == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return const MainShell();
          },
        );
      },
    );
  }
}
