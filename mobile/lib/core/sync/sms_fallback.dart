/// SMS fallback text generation for Red referrals — Task 2.7.
///
/// When data connectivity is unavailable, generates a compact ≤160-char
/// SMS summary of a Red referral. The caller opens it via Android's native
/// `sms:` or `tel:` intent, requiring no data connection.
///
/// Format (≤160 chars):
///   ASHA REFERRAL [date]
///   Pt: [member_id_short] [age]y [sex]
///   Flag: RED — [primary_finding]
///   Facility: [facility_name]
///   ASHA: [name] [phone]
///   Ref#: [referral_id_short]
///
/// Requirements: 31.5
class SmsFallback {
  /// Generate a ≤160-char Red referral SMS summary.
  ///
  /// All string fields are truncated as needed to fit within the 160-char
  /// limit while preserving the most safety-critical information.
  static String generateReferralSms({
    required String memberId,
    required int ageYears,
    required String sex, // 'M', 'F', 'O'
    required String primaryFinding,
    required String facilityName,
    required String ashaName,
    required String ashaPhone,
    required String referralId,
    required DateTime referralDate,
  }) {
    final dateStr = '${referralDate.day.toString().padLeft(2, '0')}/'
        '${referralDate.month.toString().padLeft(2, '0')}/'
        '${referralDate.year}';

    final memberShort = memberId.length > 8 ? memberId.substring(0, 8) : memberId;
    final refShort = referralId.length > 8 ? referralId.substring(0, 8) : referralId;
    final findingTrunc = primaryFinding.length > 20 ? '${primaryFinding.substring(0, 17)}...' : primaryFinding;
    final facilityTrunc = facilityName.length > 20 ? '${facilityName.substring(0, 17)}...' : facilityName;
    final ashaTrunc = ashaName.length > 15 ? '${ashaName.substring(0, 12)}...' : ashaName;

    final sms = 'ASHA REFERRAL $dateStr\n'
        'Pt: $memberShort ${ageYears}y $sex\n'
        'Flag: RED - $findingTrunc\n'
        'Facility: $facilityTrunc\n'
        'ASHA: $ashaTrunc $ashaPhone\n'
        'Ref#: $refShort';

    // Safety-trim to 160 chars if still over (edge case with long phone numbers)
    if (sms.length > 160) {
      return '${sms.substring(0, 157)}...';
    }
    return sms;
  }

  /// Build the Android SMS intent URI for the given [phoneNumber] and [message].
  ///
  /// Use with `url_launcher`: `launchUrl(Uri.parse(smsUri(...)))`.
  static String smsIntentUri(String phoneNumber, String message) {
    final encoded = Uri.encodeComponent(message);
    return 'sms:$phoneNumber?body=$encoded';
  }
}
