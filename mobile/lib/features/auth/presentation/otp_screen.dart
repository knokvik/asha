import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/auth_service.dart';

/// Screen for entering the 6-digit OTP code with SMS autofill,
/// cooldown timer, retry logic, and number change option.
class OtpScreen extends StatefulWidget {
  final String phoneNumberE164;
  final String verificationId;
  final int? resendToken;

  const OtpScreen({
    super.key,
    required this.phoneNumberE164,
    required this.verificationId,
    this.resendToken,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;

  // Countdown timer for resend cooldown
  Timer? _timer;
  int _secondsRemaining = AuthService.cooldownDurationSeconds;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _authService.remainingCooldownSeconds > 0
          ? _authService.remainingCooldownSeconds
          : AuthService.cooldownDurationSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  /// Obfuscate phone number for presentation (e.g. +91 ****** 4321)
  String _maskedPhoneNumber(String e164) {
    if (e164.length < 8) return e164;
    final prefix = e164.substring(0, 3); // +91
    final suffix = e164.substring(e164.length - 4);
    return '$prefix ****** $suffix';
  }

  Future<void> _handleVerifyOtp() async {
    final smsCode = _otpController.text.trim();
    if (smsCode.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit code.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      await _authService.verifyOtp(smsCode);
      if (!mounted) return;

      // Successful verification triggers authStateChanges stream at the root
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = _authService.mapAuthException(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handleResendOtp() async {
    if (_secondsRemaining > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      await _authService.resendOtp(
        onCodeSent: (newVerificationId, newResendToken) {
          if (!mounted) return;
          setState(() => _isResending = false);
          _startCooldownTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A new 6-digit verification code has been sent.'),
              backgroundColor: Color(0xFF0C5A3E),
            ),
          );
        },
        onVerificationFailed: (errorMsg) {
          if (!mounted) return;
          setState(() {
            _isResending = false;
            _errorMessage = errorMsg;
          });
        },
        onVerificationCompleted: (credential) {
          if (!mounted) return;
          setState(() => _isResending = false);
          // Instant auto-retrieval
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isResending = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _handleChangeNumber() {
    _authService.clearSession();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsRemaining == 0 && !_isResending && !_isVerifying;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // SMS Shield Icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF7F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCDEEE0)),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 38,
                    color: Color(0xFF0C5A3E),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Headline & Masked Phone
              const Text(
                'Enter 6-Digit Code',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Sent to ${_maskedPhoneNumber(widget.phoneNumberE164)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: _isVerifying || _isResending ? null : _handleChangeNumber,
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0C5A3E),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 6-Digit Pin-Style Input with Autofill
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  enabled: !_isVerifying && !_isResending,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 14,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: const InputDecoration(
                    hintText: '••••••',
                    hintStyle: TextStyle(
                      letterSpacing: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    if (val.trim().length == 6) {
                      _handleVerifyOtp();
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Error Message Banner
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Verify OTP Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isVerifying || _isResending ? null : _handleVerifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0C5A3E),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF0C5A3E).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 1,
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Verify OTP',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Resend OTP / Cooldown Section
              Center(
                child: canResend
                    ? TextButton.icon(
                        onPressed: _handleResendOtp,
                        icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF0C5A3E)),
                        label: const Text(
                          'Resend Code via SMS',
                          style: TextStyle(
                            color: Color(0xFF0C5A3E),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            _isResending
                                ? 'Sending new code…'
                                : 'Resend code in ${_secondsRemaining}s',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
