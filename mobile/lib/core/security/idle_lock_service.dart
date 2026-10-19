import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Manages automatic idle-lock and recent-apps privacy.
///
/// When the app is backgrounded or the user is idle beyond [_timeoutDuration],
/// this service triggers a lock callback and applies FLAG_SECURE to prevent
/// patient data appearing in the Android recent-apps thumbnail.
///
/// Requirements: 2.2
class IdleLockService with WidgetsBindingObserver {
  static const MethodChannel _channel =
      MethodChannel('com.nhm.asha/security');

  Duration _timeoutDuration;
  Timer? _idleTimer;
  final VoidCallback _onLock;
  bool _isLocked = false;

  IdleLockService({
    Duration timeout = const Duration(minutes: 2),
    required this._onLock,
  })  : _timeoutDuration = timeout;

  /// Start observing app lifecycle events and begin the idle timer.
  void start() {
    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
    _applyFlagSecure(true);
  }

  /// Stop observing. Call on logout or remote wipe.
  void dispose() {
    _idleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }

  /// Update the timeout duration (called when the user changes settings).
  ///
  /// Resets the current idle timer with the new duration.
  void updateTimeout(Duration duration) {
    _timeoutDuration = duration;
    _resetTimer();
  }

  /// Call this on any user interaction to reset the idle timer.
  ///
  /// Has no effect while the screen is locked — the user must authenticate
  /// before interactions are processed.
  void onUserActivity() {
    if (_isLocked) return;
    _resetTimer();
  }

  /// Whether the screen is currently locked.
  bool get isLocked => _isLocked;

  /// Unlock the screen after successful authentication.
  ///
  /// Resets the idle timer so the next lock occurs after a full timeout period.
  void unlock() {
    _isLocked = false;
    _resetTimer();
  }

  // ── WidgetsBindingObserver ────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // App moving to background — lock immediately to protect patient data.
        _triggerLock();
        break;
      case AppLifecycleState.resumed:
        // App returning to foreground — stay locked until user authenticates.
        // Do NOT reset timer here; the lock screen handles re-authentication.
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Transient states — no action needed.
        break;
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  void _resetTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_timeoutDuration, _triggerLock);
  }

  void _triggerLock() {
    if (_isLocked) return;
    _isLocked = true;
    _idleTimer?.cancel();
    _onLock();
  }

  /// Apply or remove FLAG_SECURE to hide content from recent-apps and
  /// prevent screenshots of patient data.
  ///
  /// FLAG_SECURE is Android-only; the call is silently ignored on other
  /// platforms (e.g., during development on desktop/iOS simulators).
  Future<void> _applyFlagSecure(bool enabled) async {
    try {
      await _channel.invokeMethod('setFlagSecure', {'enabled': enabled});
    } on MissingPluginException {
      // FLAG_SECURE is Android-only; safe to ignore on other platforms.
    } on PlatformException {
      // Activity may not be available during early init; safe to ignore.
    }
  }
}
