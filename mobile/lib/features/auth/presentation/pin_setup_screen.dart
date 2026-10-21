import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/language_selector_dialog.dart';
import '../../../../core/security/auth_service.dart';
import '../../../../core/security/session_service.dart';
import '../../../../shared/providers/core_providers.dart';

/// Screen presenting PIN setup or PIN unlock flow.
///
/// If no PIN is configured on the device, presents a PIN creation form with
/// confirmation, hashes and persists with PBKDF2/bcrypt, initializes the
/// encrypted SQLite database, and navigates to `/home`.
///
/// If a PIN is already configured, presents PIN authentication with
/// escalating lockout handling.
///
/// Includes language picker button in the AppBar conforming to Requirement 3.1.
/// Requirements: 2.1, 2.4, 3.1
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _ashaIdController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _captchaController = TextEditingController();
  bool _isPinConfigured = false;
  bool _biometricAvailable = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _captchaCode = '';

  @override
  void initState() {
    super.initState();
    _refreshCaptcha();
    _checkStatus();
  }

  @override
  void dispose() {
    _ashaIdController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _captchaController.dispose();
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

  Future<void> _checkStatus() async {
    try {
      final auth = ref.read(authServiceProvider);
      final configured = await auth.isPinConfigured.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () => false,
      );
      if (mounted) {
        setState(() {
          _isPinConfigured = configured;
        });
        if (configured) {
          final biometricAvailable = await auth.isBiometricAvailable;
          if (mounted) {
            setState(() => _biometricAvailable = biometricAvailable);
          }
        }
      }
    } catch (_) {
      // Default to false in testing or uninitialized environments
    }
  }

  Future<void> _handleBiometric() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final authenticated = await auth.authenticateWithBiometric(
        localizedReason: 'Use fingerprint or face unlock to open ASHA records',
      );
      if (!authenticated) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = auth.shouldFallBackToPin
                ? 'Biometric unlock failed three times. Please use your PIN.'
                : 'Biometric unlock was not completed. You can use your PIN instead.';
          });
        }
        return;
      }

      final key = await auth.readCachedDatabaseKey();
      if (key == null) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Enter your PIN once to enable biometric unlock on this device.';
          });
        }
        return;
      }

      ref.read(databaseKeyProvider.notifier).unlock(key);
      await ref.read(appDatabaseProvider).customSelect('SELECT 1').get();
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Biometric unlock could not open the encrypted database. Use your PIN.';
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context);
    final pin = _pinController.text.trim();
    if (pin.length < 4 || pin.length > 8 || !RegExp(r'^\d+$').hasMatch(pin)) {
      setState(() {
        _errorMessage =
            l10n?.pinLengthError ??
            'PIN must be between 4 and 8 numeric digits.';
      });
      return;
    }

    final auth = ref.read(authServiceProvider);

    if (!_isPinConfigured) {
      final confirmPin = _confirmPinController.text.trim();
      if (pin != confirmPin) {
        setState(() {
          _errorMessage =
              l10n?.pinMismatch ?? 'PINs do not match. Please re-enter.';
        });
        return;
      }

      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      try {
        final ashaId = _ashaIdController.text.trim();
        if (ashaId.isNotEmpty) {
          if (_captchaController.text.trim().toUpperCase() != _captchaCode) {
            setState(() {
              _isSubmitting = false;
              _errorMessage = 'Verification code is incorrect. Please try again.';
            });
            _refreshCaptcha();
            return;
          }
          final serverUrl = await resolveAshaApiBaseUrl();
          final serverLogin = await auth.loginToServer(
            apiBaseUrl: serverUrl,
            ashaId: ashaId,
            pin: pin,
          );
          if (!serverLogin.isSuccess) {
            setState(() {
              _isSubmitting = false;
              _errorMessage = serverLogin.error ??
                  'Invalid credentials. Please verify your ASHA ID and PIN.';
            });
            _refreshCaptcha();
            return;
          }
        }

        try {
          final dir = await getApplicationDocumentsDirectory();
          final file = File(p.join(dir.path, 'asha_platform.db'));
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}

        await auth.setupPin(pin);
        await _unlockDatabase(pin);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication successful! Welcome.'),
              backgroundColor: Color(0xFF166534),
              duration: Duration(seconds: 2),
            ),
          );
          context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Failed to configure PIN: $e';
          });
        }
      }
    } else {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      try {
        final res = await auth.verifyPin(pin);
        if (res.state == AuthState.authenticated) {
          await _unlockDatabase(pin);
          await _refreshServerSession();
          if (mounted) {
            context.go('/home');
          }
        } else if (res.state == AuthState.lockedOut) {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
              _errorMessage =
                  'Account locked out. Try again in ${res.lockoutRemainingSeconds}s.';
            });
          }
        } else if (res.state == AuthState.requiresOtp) {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
              _errorMessage =
                  l10n?.tooManyAttempts ??
                  'Too many attempts. Supervisor OTP required.';
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
              _errorMessage =
                  l10n?.incorrectPin ?? 'Incorrect PIN. Please try again.';
            });
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Verification error: $e';
          });
        }
      }
    }
  }

  Future<void> _refreshServerSession() async {
    final result = await SessionService(
      apiBaseUrl: defaultAshaApiBaseUrl,
      database: ref.read(appDatabaseProvider),
    ).refreshAccessToken();
    // Local unlock remains available when the server is temporarily offline.
    // A valid refresh silently restores the access token for the next sync.
    if (result == SessionRefreshResult.rejected && mounted) {
      setState(() {
        _errorMessage =
            'This server session was revoked. Sign in online again to sync.';
      });
    }
  }

  Future<void> _unlockDatabase(String pin) async {
    final key = await ref.read(keyManagerProvider).deriveKey(pin);
    ref.read(databaseKeyProvider.notifier).unlock(key);
    // Force the lazy Drift executor to open now, verifying the SQLCipher key
    // before home is shown. Do not suppress failures: that could expose a
    // plaintext store or strand a user behind an invalid PIN.
    final db = ref.read(appDatabaseProvider);
    try {
      await db.customSelect('SELECT 1').get();
      await ref.read(authServiceProvider).cacheDatabaseKey(key);
    } catch (e) {
      if (!_isPinConfigured) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final file = File(p.join(dir.path, 'asha_platform.db'));
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
        await db.customSelect('SELECT 1').get();
        await ref.read(authServiceProvider).cacheDatabaseKey(key);
      } else {
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.pinSetupTitle ?? 'ASHA Digital Platform'),
        centerTitle: true,
        actions: [
          IconButton(
            key: const Key('language_selector_button'),
            icon: const Icon(Icons.language),
            tooltip: l10n?.language ?? 'Language',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const LanguageSelectorDialog(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isPinConfigured) ...[
                    TextField(
                      key: const Key('asha_id_field'),
                      controller: _ashaIdController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'ASHA ID (for online sync)',
                        hintText: 'Leave blank for offline-only setup',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('captcha_input_field'),
                            controller: _captchaController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Verification code',
                              hintText: 'Enter the code shown below',
                              prefixIcon: Icon(Icons.verified_user_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          children: [
                            Container(
                              key: const Key('captcha_code'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 13,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _captchaCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _refreshCaptcha,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Icon(
                    Icons.health_and_safety,
                    size: 72,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _isPinConfigured
                        ? (l10n?.welcomeBack ?? 'Welcome Back')
                        : (l10n?.securitySetup ?? 'Security Setup'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPinConfigured
                        ? 'Enter your security PIN to unlock patient records'
                        : 'Set a 4 to 8 digit PIN to encrypt your local database',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    key: const Key('pin_input_field'),
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 8,
                    decoration: InputDecoration(
                      labelText: _isPinConfigured
                          ? (l10n?.securityPin ?? 'Security PIN')
                          : (l10n?.createPin ?? 'Create PIN (4–8 digits)'),
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  if (!_isPinConfigured) ...[
                    const SizedBox(height: 16),
                    TextField(
                      key: const Key('confirm_pin_input_field'),
                      controller: _confirmPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: l10n?.confirmPin ?? 'Confirm PIN',
                        prefixIcon: const Icon(Icons.lock_reset),
                        border: const OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  ElevatedButton(
                    key: const Key('submit_pin_button'),
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _isSubmitting
                          ? 'Processing...'
                          : (_isPinConfigured
                                ? (l10n?.unlockDatabase ?? 'Unlock Database')
                                : (l10n?.setPinAndInitialize ??
                                      'Set PIN & Initialize')),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_isPinConfigured && _biometricAvailable) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('biometric_unlock_button'),
                      onPressed: _isSubmitting ? null : _handleBiometric,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Unlock with fingerprint / face'),
                    ),
                  ],
                  if (_isPinConfigured) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isPinConfigured = false;
                          _errorMessage = null;
                          _pinController.clear();
                          _confirmPinController.clear();
                          _refreshCaptcha();
                        });
                      },
                      icon: const Icon(Icons.switch_account_outlined, size: 18),
                      label: const Text('Sign in with a different ASHA ID'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
