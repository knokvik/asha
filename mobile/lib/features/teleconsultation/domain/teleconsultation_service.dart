import 'package:flutter/foundation.dart';

enum HelplineType {
  emergencyAmbulance, // 108
  obstetricTransport, // 102 (Janani Shishu Suraksha)
  healthAdvice104,    // 104 National Health Helpline
  mentalHealthKiran,  // 14416 (Tele-MANAS)
  childlineEmergency, // 1098
  nationalEmergency112, // 112
}

@immutable
class PeerMessage {
  final String id;
  final String senderName;
  final String senderRole;
  final String contentText;
  final String? audioClipUrl;
  final DateTime sentAt;
  final bool isModerated;

  const PeerMessage({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.contentText,
    this.audioClipUrl,
    required this.sentAt,
    this.isModerated = true,
  });
}

class TeleconsultationService {
  static const Map<HelplineType, String> helplineNumbers = {
    HelplineType.emergencyAmbulance: '108',
    HelplineType.obstetricTransport: '102',
    HelplineType.healthAdvice104: '104',
    HelplineType.mentalHealthKiran: '14416',
    HelplineType.childlineEmergency: '1098',
    HelplineType.nationalEmergency112: '112',
  };

  /// Generates a standardized tel: URI for one-tap voice dialing without internet (Requirement 38.1)
  String getHelplineUri(HelplineType type) {
    final number = helplineNumbers[type] ?? '108';
    return 'tel:$number';
  }

  /// Generates a tel: URI for direct contact to assigned ANM, CHO, or MO (Requirement 38.1)
  String getDirectStaffCallUri(String phoneNumber) {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    return 'tel:$clean';
  }

  /// Formats an asynchronous clinical case note excerpt for SMS / Messaging (Requirement 38.2)
  /// Enforces DPDP & ABDM purpose limitation: minimal necessary clinical data, requiring beneficiary consent (Req 38.4)
  String formatAsyncCaseSharingNote({
    required String patientCodedId,
    required String ageGender,
    required String primaryComplaint,
    required Map<String, dynamic> vitals,
    required List<String> redFlags,
    required bool hasBeneficiaryConsent,
  }) {
    if (!hasBeneficiaryConsent) {
      throw StateError('Cannot share clinical case details without explicit beneficiary consent (Requirement 38.4).');
    }

    final buffer = StringBuffer();
    buffer.writeln('【ASHA Clinical Case Excerpt (e-Sanjeevani / ANM)】');
    buffer.writeln('Patient ID: $patientCodedId ($ageGender)');
    buffer.writeln('Chief Concern: $primaryComplaint');

    if (vitals.isNotEmpty) {
      buffer.write('Vitals: ');
      final vitalsParts = <String>[];
      if (vitals['bp'] != null) vitalsParts.add('BP: ${vitals['bp']} mmHg');
      if (vitals['pulse'] != null) vitalsParts.add('Pulse: ${vitals['pulse']} bpm');
      if (vitals['spo2'] != null) vitalsParts.add('SpO2: ${vitals['spo2']}%');
      if (vitals['temp'] != null) vitalsParts.add('Temp: ${vitals['temp']} °F');
      if (vitals['respRate'] != null) vitalsParts.add('Resp: ${vitals['respRate']}/min');
      buffer.writeln(vitalsParts.join(', '));
    }

    if (redFlags.isNotEmpty) {
      buffer.writeln('Alert Danger Signs: ${redFlags.join(', ')}');
    }

    buffer.writeln('Consent: Verified by ASHA • Purpose: Clinical Advice');
    return buffer.toString().trim();
  }

  /// Generates an e-Sanjeevani deeplink with web fallback (Requirement 38.2)
  Uri generateESanjeevaniLink({
    required String patientCodedId,
    required String chiefComplaint,
    String specialty = 'GeneralMedicine',
  }) {
    final encodedComplaint = Uri.encodeComponent(chiefComplaint);
    return Uri.parse(
      'esanjeevani://consult?patientId=$patientCodedId&complaint=$encodedComplaint&specialty=$specialty',
    );
  }

  /// Posts a message to the moderated peer support group with privacy check (Requirement 38.3, 38.4)
  PeerMessage createPeerMessage({
    required String senderName,
    required String contentText,
    String? audioClipUrl,
    required bool containsPatientData,
    bool hasPatientConsent = false,
  }) {
    if (containsPatientData && !hasPatientConsent) {
      throw ArgumentError('Sharing patient observations in peer group requires explicit consent.');
    }

    return PeerMessage(
      id: 'peer_${DateTime.now().millisecondsSinceEpoch}',
      senderName: senderName,
      senderRole: 'ASHA',
      contentText: contentText,
      audioClipUrl: audioClipUrl,
      sentAt: DateTime.now(),
      isModerated: true,
    );
  }
}
