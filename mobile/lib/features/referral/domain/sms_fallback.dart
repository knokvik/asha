import 'referral_models.dart';

/// Formatter generating compact emergency SMS fallback text summaries (≤ 160 characters).
///
/// Implements Requirements 10.2, 10.8:
/// - Guarantees strictly ≤ 160 characters to fit a single GSM 03.38 standard SMS PDU.
/// - Prioritizes key clinical elements: Flag, Patient Name, Age/Sex, Key Vital/Reason, Facility, ASHA Phone.
class SmsFallbackFormatter {
  static const int maxGsmLength = 160;

  /// Generates a strictly bounded SMS message (≤ 160 characters) from a [StructuredReferralNote].
  static String formatSms(StructuredReferralNote note, {int maxLength = maxGsmLength}) {
    final flag = note.triageFlag.label; // RED, YELLOW, GREEN
    final pName = note.patient.name;
    final ageSex = '${note.patient.formattedAge}, ${note.patient.sex}';

    // Extract primary clinical vital or danger sign
    String clinicalKey = note.primaryReason;
    if (clinicalKey.length > 35) {
      clinicalKey = '${clinicalKey.substring(0, 32)}...';
    }

    final facilityName = note.destinationFacility?.name ?? 'Designated PHC/CHC';
    final ashaPhone = note.asha.phone ?? note.asha.name;

    // Base template
    // "REF [FLAG]: [Name] ([Age/Sex]). [Key Reason]. To: [Facility]. ASHA: [Phone]"
    String message = 'REF $flag: $pName ($ageSex). $clinicalKey. To: $facilityName. ASHA: $ashaPhone.';

    if (message.length <= maxLength) {
      return message;
    }

    // If over limit, progressively compress:
    // 1. Shorter facility name
    String shortFacility = facilityName;
    if (shortFacility.length > 15) {
      shortFacility = '${shortFacility.substring(0, 12)}...';
    }
    message = 'REF $flag: $pName ($ageSex). $clinicalKey. To: $shortFacility. ASHA: $ashaPhone.';
    if (message.length <= maxLength) return message;

    // 2. Shorten clinical reason
    if (clinicalKey.length > 20) {
      clinicalKey = '${clinicalKey.substring(0, 17)}...';
    }
    message = 'REF $flag: $pName ($ageSex). $clinicalKey. To: $shortFacility. ASHA: $ashaPhone.';
    if (message.length <= maxLength) return message;

    // 3. Hard clamp to maxLength
    if (message.length > maxLength) {
      return message.substring(0, maxLength);
    }

    return message;
  }
}
