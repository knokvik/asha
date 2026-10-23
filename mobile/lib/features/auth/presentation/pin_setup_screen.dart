import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../services/auth_service.dart';

/// Phone-only Supabase OTP login screen.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _auth = AuthService();
  Timer? _timer;
  int _seconds = 0;
  bool _otpRequested = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    for (final controller in _otpControllers) controller.dispose();
    for (final node in _otpFocusNodes) node.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = AuthService.cooldownDurationSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
      } else {
        setState(() => _seconds--);
      }
    });
  }

  String get _phone {
    final value = _phoneController.text.trim();
    return value.startsWith('+') ? value : '+91$value';
  }

  Future<void> _sendOtp() async {
    final raw = _phoneController.text.trim().replaceAll(RegExp(r'\s+'), '');
    if (!RegExp(r'^(\+91)?[6-9]\d{9}$').hasMatch(raw)) {
      setState(() => _error = 'Enter a valid 10-digit Indian mobile number.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _auth.sendOtp(_phone);
      if (!mounted) return;
      setState(() {
        _otpRequested = true;
        _busy = false;
      });
      _startTimer();
    } catch (e) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = e.toString().replaceFirst('AuthException: ', '');
        });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length != 6) {
      setState(() => _error = 'Enter the complete 6-digit OTP.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _auth.verifyOtp(otp);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted)
        setState(() {
          _busy = false;
          _error = e.toString().replaceFirst('AuthException: ', '');
        });
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value
          .replaceAll(RegExp(r'\D'), '')
          .characters
          .take(6)
          .toList();
      for (var i = 0; i < digits.length && index + i < 6; i++) {
        _otpControllers[index + i].text = digits[i];
      }
      final next = (index + digits.length).clamp(0, 5);
      _otpFocusNodes[next].requestFocus();
      if (_otpControllers.every((c) => c.text.isNotEmpty)) _verifyOtp();
      return;
    }
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    if (_otpControllers.every((c) => c.text.isNotEmpty)) _verifyOtp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.phone_android_rounded,
                        size: 56,
                        color: Color(0xFF0C5A3E),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ASHA Digital Platform',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Login with your registered mobile number',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _phoneController,
                        enabled: !_otpRequested && !_busy,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile number',
                          prefixText: '+91 ',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_otpRequested) ...[
                        const SizedBox(height: 12),
                        AutofillGroup(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(
                              6,
                              (index) => SizedBox(
                                width: 42,
                                child: TextField(
                                  controller: _otpControllers[index],
                                  focusNode: _otpFocusNodes[index],
                                  enabled: !_busy,
                                  autofocus: index == 0,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  autofillHints: const [
                                    AutofillHints.oneTimeCode,
                                  ],
                                  onChanged: (value) =>
                                      _onOtpChanged(index, value),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            _seconds > 0
                                ? 'Resend in ${_seconds}s'
                                : 'You can resend OTP',
                          ),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : (_otpRequested ? _verifyOtp : _sendOtp),
                        child: Text(
                          _busy
                              ? 'Please wait…'
                              : (_otpRequested ? 'Verify OTP' : 'Send OTP'),
                        ),
                      ),
                      if (_otpRequested && _seconds == 0)
                        TextButton(
                          onPressed: _busy ? null : _sendOtp,
                          child: const Text('Resend OTP'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
