/// Helper utility for generating one-tap phone call and SMS intents (Requirement 26.3, 26.6).
class CommunicationLauncher {
  /// Strips whitespace, dashes, and invalid characters from phone numbers, preserving leading '+'.
  static String sanitizePhoneNumber(String rawNumber) {
    final trimmed = rawNumber.trim();
    if (trimmed.isEmpty) return '';

    final hasPlus = trimmed.startsWith('+');
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');

    return hasPlus ? '+$digitsOnly' : digitsOnly;
  }

  /// Builds a standard `tel:<phone>` URI for initiating one-tap phone calls.
  static Uri buildPhoneUri(String phoneNumber) {
    final clean = sanitizePhoneNumber(phoneNumber);
    return Uri(scheme: 'tel', path: clean);
  }

  /// Builds a standard `sms:<phone>?body=<message>` URI for initiating one-tap SMS messages.
  static Uri buildSmsUri(String phoneNumber, [String? prefilledMessage]) {
    final clean = sanitizePhoneNumber(phoneNumber);
    if (prefilledMessage == null || prefilledMessage.isEmpty) {
      return Uri(scheme: 'sms', path: clean);
    }
    return Uri(
      scheme: 'sms',
      path: clean,
      queryParameters: {'body': prefilledMessage},
    );
  }
}
