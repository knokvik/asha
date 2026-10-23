import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/auth_service.dart';
import 'otp_screen.dart';

/// Screen for entering Indian phone number (+91) and initiating SMS OTP delivery.
///
/// Strictly enforces Phone as the ONLY authentication method.
class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  // Debug testing flags (only shown / used in debug mode)
  bool _debugAppVerificationDisabled = true;
  bool _debugForceRecaptcha = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _applyDebugSettings();
    }
  }

  void _applyDebugSettings() {
    if (kDebugMode) {
      AuthService.configureTestingEnvironment(
        disableAppVerification: _debugAppVerificationDisabled,
        forceRecaptchaFlow: _debugForceRecaptcha,
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// Validates and converts the 10-digit phone number into E.164 format (+91XXXXXXXXXX)
  String? _getE164PhoneNumber() {
    final raw = _phoneController.text.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (raw.length != 10) return null;
    return '+91$raw';
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final e164 = _getE164PhoneNumber();
    if (e164 == null) {
      setState(() => _errorMessage = 'Please enter a valid 10-digit mobile number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendOtp(
        e164,
        onCodeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          // Navigate to OTP Screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => OtpScreen(
                phoneNumberE164: e164,
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            ),
          );
        },
        onVerificationFailed: (errorMsg) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
            _errorMessage = errorMsg;
          });
        },
        onVerificationCompleted: (credential) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          // Auto-retrieved or instant verification succeeded
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Instant phone verification succeeded!'),
              backgroundColor: Color(0xFF0C5A3E),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('ASHA Health Worker Sign In'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),

                // App / Government Emblem Emblem Icon
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
                      Icons.phone_android_rounded,
                      size: 38,
                      color: Color(0xFF0C5A3E),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title & Subtitle
                const Text(
                  'Frontline Phone Login',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your official mobile number to receive a 6-digit verification code.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),

                // Phone Input Field Container (+91 Prefix)
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      // Country Code Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Text('🇮🇳', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 6),
                            Text(
                              '+91',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 10-Digit Mobile Input
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumberNational],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          enabled: !_isLoading,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: const InputDecoration(
                            hintText: '98765 43210',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.normal,
                              letterSpacing: 0.5,
                            ),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Phone number is required';
                            }
                            if (value.trim().length != 10) {
                              return 'Enter 10-digit number';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Error Message Card
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

                // Send OTP Button (Disabled while loading)
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C5A3E),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF0C5A3E).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 1,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Send OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mandatory Legal Notice
                const Text(
                  'By continuing, you may receive an SMS for verification. Message and data rates may apply. Your phone number is shared with Google to help prevent spam and abuse.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 32),

                // Debug-Only Testing Panel (Guarded by kDebugMode)
                if (kDebugMode) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bug_report, size: 18, color: Colors.amber),
                            SizedBox(width: 6),
                            Text(
                              'Testing Support (Debug Only)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Test fictional numbers without Google Play services, or force reCAPTCHA verification fallback.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                        ),
                        const Divider(height: 16),
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Fictional Test Numbers Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Disables SafetyNet/Play Integrity for test numbers', style: TextStyle(fontSize: 10)),
                          value: _debugAppVerificationDisabled,
                          onChanged: (val) {
                            setState(() => _debugAppVerificationDisabled = val);
                            _applyDebugSettings();
                          },
                        ),
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Force reCAPTCHA Flow', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Forces SafetyNet / Web reCAPTCHA modal', style: TextStyle(fontSize: 10)),
                          value: _debugForceRecaptcha,
                          onChanged: (val) {
                            setState(() => _debugForceRecaptcha = val);
                            _applyDebugSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
