import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
