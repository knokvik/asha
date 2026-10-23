import 'package:flutter/material.dart';

import 'pin_setup_screen.dart';

/// Legacy route retained as an alias; OTP is handled inline by PinSetupScreen.
class OtpScreen extends StatelessWidget {
  const OtpScreen({
    super.key,
    this.phoneNumberE164,
    this.verificationId,
    this.resendToken,
  });

  final String? phoneNumberE164;
  final String? verificationId;
  final int? resendToken;

  @override
  Widget build(BuildContext context) => const PinSetupScreen();
}
