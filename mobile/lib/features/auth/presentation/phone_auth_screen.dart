import 'package:flutter/material.dart';

import 'pin_setup_screen.dart';

/// Backwards-compatible route alias for the Supabase phone-only login screen.
class PhoneAuthScreen extends StatelessWidget {
  const PhoneAuthScreen({super.key});

  @override
  Widget build(BuildContext context) => const PinSetupScreen();
}
