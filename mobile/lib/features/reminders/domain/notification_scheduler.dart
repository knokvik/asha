import 'reminder_models.dart';

/// Pure algorithmic scheduler for managing local push notifications, quiet hours suppression,
/// and batching (Requirements 26.1, 26.5).
class NotificationScheduler {
  /// Computes the effective time at which a notification should be presented to the ASHA.
  ///
  /// Rules:
  /// - Urgent notifications (RED flag triage, severe danger signs) are NEVER suppressed and fire immediately.
  /// - Standard routine notifications that fall within the configured quiet-hours window are deferred
  ///   to the exact end of quiet hours on the morning the window closes.
  static DateTime calculateEffectiveNotificationTime({
    required DateTime targetTime,
    required NotificationUrgency urgency,
    required QuietHoursConfig quietHoursConfig,
  }) {
    if (urgency == NotificationUrgency.urgent || !quietHoursConfig.enabled) {
      return targetTime;
    }

    if (!quietHoursConfig.isWithinQuietHours(targetTime)) {
      return targetTime;
    }

    // Determine when quiet hours end relative to targetTime
    // If quiet hours span midnight (e.g. 21:00 to 07:00):
    // - If target is in the evening (hour >= startHour), quiet hours end next morning.
    // - If target is in the early morning (hour < endHour), quiet hours end that same morning.
    DateTime nextMorningEnd;
    if (quietHoursConfig.startHour > quietHoursConfig.endHour) {
      if (targetTime.hour >= quietHoursConfig.startHour) {
        // Evening before midnight: wake up tomorrow morning at endHour:endMinute
        final tomorrow = targetTime.add(const Duration(days: 1));
        nextMorningEnd = DateTime(
          tomorrow.year,
          tomorrow.month,
          tomorrow.day,
          quietHoursConfig.endHour,
          quietHoursConfig.endMinute,
        );
      } else {
        // Past midnight: wake up today at endHour:endMinute
        nextMorningEnd = DateTime(
          targetTime.year,
          targetTime.month,
          targetTime.day,
          quietHoursConfig.endHour,
          quietHoursConfig.endMinute,
        );
      }
    } else {
      // Same-day quiet hours (e.g. 13:00 to 15:00)
      nextMorningEnd = DateTime(
        targetTime.year,
        targetTime.month,
        targetTime.day,
        quietHoursConfig.endHour,
        quietHoursConfig.endMinute,
      );
    }

    return nextMorningEnd;
  }

  /// Evaluates whether a high volume of pending tasks warrants aggregating into a single batch summary.
  static bool shouldBatchNotifications(int pendingCount, {int threshold = 5}) {
    return pendingCount >= threshold;
  }

  /// Formats the daily summary notification text for high-volume days.
  static Map<String, String> formatDailyBatchSummary({
    required int dueTodayCount,
    required int overdueCount,
    required List<String> hamlets,
  }) {
    final total = dueTodayCount + overdueCount;
    final title = 'ASHA Daily Workplan: $total visits due';

    final buffer = StringBuffer();
    if (overdueCount > 0) {
      buffer.write('$overdueCount overdue! ');
    }
    buffer.write('$dueTodayCount scheduled for today. ');

    if (hamlets.isNotEmpty) {
      final uniqueHamlets = hamlets.toSet().toList();
      final preview = uniqueHamlets.take(3).join(', ');
      final extra = uniqueHamlets.length > 3 ? ' (+${uniqueHamlets.length - 3} more)' : '';
      buffer.write('Hamlets: $preview$extra.');
    }

    return {
      'title': title,
      'body': buffer.toString().trim(),
    };
  }

  /// Generates a stable, positive 32-bit integer ID for `flutter_local_notifications` from any string ID.
  static int generateStableNotificationId(String sourceId) {
    var hash = 5381;
    for (var i = 0; i < sourceId.length; i++) {
      hash = ((hash << 5) + hash) + sourceId.codeUnitAt(i);
      hash = hash & 0x7FFFFFFF; // keep in positive 31-bit integer range
    }
    return hash;
  }
}
