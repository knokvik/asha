import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import 'auth_home_placeholder.dart';
import 'pin_setup_screen.dart';

/// Root Authentication Gate with a StreamBuilder listening to authStateChanges().
///
/// Signed-in users see the Home placeholder (showing user.phoneNumber and Logout).
/// Unauthenticated users see the PhoneAuthScreen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, snapshot) {
        // While Firebase Auth restores persistent token from local storage
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF8FAF9),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF0C5A3E)),
            ),
          );
        }

        // Signed in -> Show Home with user.phoneNumber and Logout
        if (snapshot.hasData && snapshot.data != null) {
          return AuthHomePlaceholder(user: snapshot.data!);
        }

        // Signed out -> Show Phone Screen
        return const PinSetupScreen();
      },
    );
  }
}
