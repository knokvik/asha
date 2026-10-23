import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/language_selector_dialog.dart';
import '../../../../shared/widgets/asha_svg_illustrations.dart';
import '../../../../services/auth_service.dart';

/// Phone-only Supabase OTP login screen.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _phoneController = TextEditingController();
  final _captchaController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _auth = AuthService();
  Timer? _timer;
  int _seconds = 0;
  bool _otpRequested = false;
  String _captchaCode = '';
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshCaptcha();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _captchaController.dispose();
    for (final controller in _otpControllers) controller.dispose();
    for (final node in _otpFocusNodes) node.dispose();
    super.dispose();
  }

  void _refreshCaptcha() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final random = Random.secure();
    setState(() {
      _captchaCode = List.generate(
        5,
        (_) => chars[random.nextInt(chars.length)],
      ).join();
      _captchaController.clear();
    });
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
    if (_captchaController.text.trim().toUpperCase() != _captchaCode) {
      setState(() => _error = 'Enter the captcha correctly.');
      _refreshCaptcha();
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Language',
            icon: const Icon(Icons.language),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const LanguageSelectorDialog(),
            ),
          ),
        ],
      ),
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
                      const AshaLogo(height: 64),
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
                        'Secure sign-in for ASHA field work',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      const SizedBox(height: 8),
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
                      if (!_otpRequested) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _captchaController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Captcha',
                                  prefixIcon: Icon(
                                    Icons.verified_user_outlined,
                                  ),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.only(left: 10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _captchaCode,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _refreshCaptcha,
                                    icon: const Icon(Icons.refresh, size: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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
                                  // The first box accepts the complete SMS
                                  // autofill value; the handler distributes it
                                  // across all six visible boxes.
                                  maxLength: index == 0 ? 6 : 1,
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
