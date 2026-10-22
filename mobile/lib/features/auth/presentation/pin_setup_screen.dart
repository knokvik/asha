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
import '../../../../shared/widgets/asha_svg_illustrations.dart';

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
  bool _statusChecked = false;
  bool _isSubmitting = false;
  int _pinLength = 4;
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
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      if (mounted) {
        final pinLength = configured ? await auth.configuredPinLength : 4;
        setState(() {
          _isPinConfigured = configured;
          _pinLength = pinLength;
          _statusChecked = true;
        });
      }
    } catch (_) {
      // Default to false in testing or uninitialized environments
      if (mounted) setState(() => _statusChecked = true);
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final l10n = AppLocalizations.of(context);
    final pin = _pinController.text.trim();
    final invalidLength = _isPinConfigured
        ? pin.length != _pinLength
        : pin.length < 4 || pin.length > 8;
    if (invalidLength || !RegExp(r'^\d+$').hasMatch(pin)) {
      setState(() {
        _errorMessage = _isPinConfigured
            ? 'PIN must be exactly $_pinLength numeric digits.'
            : 'PIN must be 4–8 numeric digits.';
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
        _pinLength = pin.length;
      });

      try {
        final ashaId = _ashaIdController.text.trim();
        // A local PIN alone must never create an application identity. The
        // worker ID is required so the backend can return the correct user,
        // role, assignments, and sync scope.
        if (ashaId.isEmpty) {
          setState(() {
            _isSubmitting = false;
            _errorMessage =
                'Enter your ASHA ID to sign in and load your worker profile.';
          });
          return;
        }
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
            _errorMessage =
                serverLogin.error ??
                'Invalid credentials. Please verify your ASHA ID and PIN.';
          });
          _refreshCaptcha();
          return;
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

  void _appendPinDigit(String digit) {
    if (_isSubmitting || _pinController.text.length >= _pinLength) return;
    setState(() {
      _errorMessage = null;
      _pinController.text += digit;
    });
    if (_isPinConfigured && _pinController.text.length == _pinLength) {
      Future<void>.microtask(_handleSubmit);
    }
  }

  void _removePinDigit() {
    if (_isSubmitting || _pinController.text.isEmpty) return;
    setState(() {
      _errorMessage = null;
      _pinController.text = _pinController.text.substring(
        0,
        _pinController.text.length - 1,
      );
    });
  }

  Widget _buildUnlockPad() {
    const digits = ['1', '2', '3', '4', '5', '6', '7', '8', '9'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_pinLength, (index) {
            final filled = index < _pinController.text.length;
            return Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                border: Border.all(
                  color: filled
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            for (final digit in digits)
              _pinKey(digit, () => _appendPinDigit(digit)),
            const SizedBox.shrink(),
            _pinKey('0', () => _appendPinDigit('0')),
            _pinKey('⌫', _removePinDigit),
          ],
        ),
      ],
    );
  }

  Widget _pinKey(String label, VoidCallback onPressed) {
    return OutlinedButton(
      key: Key('pin_key_$label'),
      onPressed: _isSubmitting ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 52),
        padding: EdgeInsets.zero,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: label == '⌫' ? 20 : 22,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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

    if (!_statusChecked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
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
                  const Center(child: AshaLogo(height: 64)),
                  const SizedBox(height: 12),
                  Text(
                    l10n?.pinSetupTitle ?? 'ASHA Digital Platform',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 24,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isPinConfigured
                            ? (l10n?.welcomeBack ?? 'Welcome Back')
                            : (l10n?.securitySetup ?? 'Security Setup'),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPinConfigured
                        ? 'Enter your $_pinLength-digit PIN to unlock patient records'
                        : 'Set a 4–8 digit PIN to encrypt your local database',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 28),
                  if (!_isPinConfigured) ...[
                    TextField(
                      key: const Key('asha_id_field'),
                      controller: _ashaIdController,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'ASHA ID or registered mobile number',
                        hintText: 'Use your ASHA ID or mobile number',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    if (_ashaIdController.text.trim().isNotEmpty) ...[
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
                                labelText: 'Online verification code',
                                hintText: 'Required only for server sync setup',
                                prefixIcon: Icon(Icons.verified_user_outlined),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            key: const Key('captcha_code'),
                            padding: const EdgeInsets.only(left: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              border: Border.all(color: Colors.green.shade200),
                              borderRadius: BorderRadius.circular(10),
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
                                  key: const Key('captcha_refresh_button'),
                                  onPressed: _refreshCaptcha,
                                  tooltip: 'Refresh verification code',
                                  icon: const Icon(Icons.refresh, size: 19),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  if (_isPinConfigured) ...[
                    const SizedBox(height: 4),
                    const Icon(Icons.lock_outline, size: 28),
                    const SizedBox(height: 10),
                    _buildUnlockPad(),
                    const SizedBox(height: 14),
                    TextButton.icon(
                      key: const Key('forgot_password_button'),
                      onPressed: _isSubmitting ? null : _requestPasswordReset,
                      icon: const Icon(Icons.mail_outline),
                      label: const Text('Forgot PIN or password?'),
                    ),
                  ] else ...[
                    const SizedBox(height: 18),
                    TextField(
                      key: const Key('pin_input_field'),
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 8,
                      decoration: InputDecoration(
                        labelText: l10n?.createPin ?? 'Create 4–8 digit PIN',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: const OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                  ],
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
                  if (_isSubmitting) ...[
                    const SizedBox(height: 18),
                    const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ],
                  if (!_isPinConfigured)
                    ElevatedButton(
                      key: const Key('submit_pin_button'),
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _isSubmitting
                            ? 'Processing...'
                            : (l10n?.setPinAndInitialize ??
                                  'Set PIN & Initialize'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestPasswordReset() async {
    final identifier = _ashaIdController.text.trim();
    final enteredIdentifier = identifier.isNotEmpty
        ? identifier
        : await _askForResetIdentifier();
    if (enteredIdentifier == null ||
        enteredIdentifier.trim().isEmpty ||
        !mounted) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final result = await ref
        .read(authServiceProvider)
        .requestPasswordReset(
          apiBaseUrl: await resolveAshaApiBaseUrl(),
          identifier: enteredIdentifier.trim(),
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          result.isSuccess ? 'Reset email sent' : 'Reset unavailable',
        ),
        content: Text(result.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<String?> _askForResetIdentifier() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset PIN or password'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'ASHA ID, mobile number, or email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Send email'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }
}
