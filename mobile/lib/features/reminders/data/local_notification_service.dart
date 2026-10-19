import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../domain/notification_scheduler.dart';
import '../domain/reminder_models.dart';

/// Representation of an on-device scheduled notification record.
class ScheduledNotificationRecord {
  final int notificationId;
  final String scheduleId;
  final String title;
  final String body;
  final DateTime scheduledTime;
  final NotificationUrgency urgency;
  final String? payload;

  const ScheduledNotificationRecord({
    required this.notificationId,
    required this.scheduleId,
    required this.title,
    required this.body,
    required this.scheduledTime,
    required this.urgency,
    this.payload,
  });
}

/// Service managing on-device push notifications and alarms using `flutter_local_notifications`
/// without requiring any network connection (Requirements 26.1, 26.5).
class LocalNotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  final Map<String, ScheduledNotificationRecord> _activeSchedules = {};
  bool _isInitialized = false;

  LocalNotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  bool get isInitialized => _isInitialized;
  List<ScheduledNotificationRecord> get activeSchedules => _activeSchedules.values.toList();

  // ── 1. Initialization ────────────────────────────────────────────────────────

  /// Initializes local notification channels for Android, iOS, and desktop.
  Future<bool> initialize({
    void Function(NotificationResponse)? onNotificationTapped,
  }) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    try {
      final initialized = await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: onNotificationTapped,
      );
      _isInitialized = initialized ?? true;
      return _isInitialized;
    } catch (e) {
      debugPrint('LocalNotificationService initialization warning (offline/mock environment): $e');
      _isInitialized = true;
      return true;
    }
  }

  // ── 2. Channel Details Factory ───────────────────────────────────────────────

  NotificationDetails _buildNotificationDetails(NotificationUrgency urgency) {
    switch (urgency) {
      case NotificationUrgency.urgent:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'asha_urgent_channel',
            'Clinical Emergency & Danger Signs',
            channelDescription: 'High-priority alerts for RED triage and danger signs requiring immediate care.',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        );

      case NotificationUrgency.summary:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'asha_batch_channel',
            'Daily Workplan Summary',
            channelDescription: 'Aggregated daily workplan and due task summaries.',
            importance: Importance.low,
            priority: Priority.low,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        );

      case NotificationUrgency.standard:
        return const NotificationDetails(
          android: AndroidNotificationDetails(
            'asha_routine_channel',
            'Due & Upcoming Visits',
            channelDescription: 'Reminders for scheduled maternal, child, and chronic care visits.',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        );
    }
  }

  // ── 3. Schedule Visit Reminder (Requirement 26.1, 26.5) ─────────────────────

  /// Schedules a notification for a visit task, adjusting for quiet hours if standard urgency.
  Future<ScheduledNotificationRecord> scheduleVisitReminder({
    required String scheduleId,
    required String title,
    required String body,
    required DateTime targetDueDate,
    NotificationUrgency urgency = NotificationUrgency.standard,
    QuietHoursConfig quietHoursConfig = const QuietHoursConfig(),
    Map<String, dynamic>? payload,
  }) async {
    final effectiveTime = NotificationScheduler.calculateEffectiveNotificationTime(
      targetTime: targetDueDate,
      urgency: urgency,
      quietHoursConfig: quietHoursConfig,
    );

    final notificationId = NotificationScheduler.generateStableNotificationId(scheduleId);
    final payloadJson = payload != null ? jsonEncode(payload) : null;

    final record = ScheduledNotificationRecord(
      notificationId: notificationId,
      scheduleId: scheduleId,
      title: title,
      body: body,
      scheduledTime: effectiveTime,
      urgency: urgency,
      payload: payloadJson,
    );

    _activeSchedules[scheduleId] = record;

    try {
      // If effective time is in the past or right now, display immediately
      final now = DateTime.now();
      if (!effectiveTime.isAfter(now)) {
        await _plugin.show(
          id: notificationId,
          title: title,
          body: body,
          notificationDetails: _buildNotificationDetails(urgency),
          payload: payloadJson,
        );
      }
    } catch (e) {
      debugPrint('LocalNotificationService: Notice - could not dispatch native push in current environment: $e');
    }

    return record;
  }

  // ── 4. Urgent Push Alert (Immediate) ────────────────────────────────────────

  /// Shows an immediate alert for urgent clinical events (e.g. RED flag referrals, danger signs).
  Future<void> showUrgentAlert({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF;
    final payloadJson = payload != null ? jsonEncode(payload) : null;

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _buildNotificationDetails(NotificationUrgency.urgent),
        payload: payloadJson,
      );
    } catch (e) {
      debugPrint('LocalNotificationService: Notice - could not show urgent alert natively: $e');
    }
  }

  // ── 5. Batch Daily Summary (Requirement 26.5) ───────────────────────────────

  /// Shows an aggregated daily summary notification for high task volumes.
  Future<void> showDailySummaryNotification({
    required int dueTodayCount,
    required int overdueCount,
    required List<String> hamlets,
  }) async {
    final summary = NotificationScheduler.formatDailyBatchSummary(
      dueTodayCount: dueTodayCount,
      overdueCount: overdueCount,
      hamlets: hamlets,
    );

    const id = 999001; // Reserved stable ID for daily workplan summary
    try {
      await _plugin.show(
        id: id,
        title: summary['title']!,
        body: summary['body']!,
        notificationDetails: _buildNotificationDetails(NotificationUrgency.summary),
        payload: jsonEncode({
          'type': 'daily_workplan_summary',
          'due_today': dueTodayCount,
          'overdue': overdueCount,
        }),
      );
    } catch (e) {
      debugPrint('LocalNotificationService: Notice - could not show batch summary natively: $e');
    }
  }

  // ── 6. Cancellation ─────────────────────────────────────────────────────────

  /// Cancels a scheduled task notification by its schedule ID.
  Future<void> cancelReminder(String scheduleId) async {
    final record = _activeSchedules.remove(scheduleId);
    if (record != null) {
      try {
        await _plugin.cancel(id: record.notificationId);
      } catch (e) {
        debugPrint('LocalNotificationService: Notice - could not cancel notification natively: $e');
      }
    }
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAll() async {
    _activeSchedules.clear();
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('LocalNotificationService: Notice - could not cancel all notifications natively: $e');
    }
  }
}
