import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/features/teleconsultation/domain/teleconsultation_service.dart';

void main() {
  late TeleconsultationService service;

  setUp(() {
    service = TeleconsultationService();
  });

  group('TeleconsultationService - Voice & Helplines (Req 38.1)', () {
    test('getHelplineUri returns accurate tel: URIs for emergency and health helplines', () {
      expect(service.getHelplineUri(HelplineType.emergencyAmbulance), 'tel:108');
      expect(service.getHelplineUri(HelplineType.obstetricTransport), 'tel:102');
      expect(service.getHelplineUri(HelplineType.healthAdvice104), 'tel:104');
      expect(service.getHelplineUri(HelplineType.mentalHealthKiran), 'tel:14416');
    });

    test('getDirectStaffCallUri cleans non-digit characters and prepends tel:', () {
      expect(service.getDirectStaffCallUri('+91 98765-43210'), 'tel:+919876543210');
      expect(service.getDirectStaffCallUri('(080) 2345-6789'), 'tel:08023456789');
    });
  });

  group('TeleconsultationService - Async Case Sharing & Consent (Req 38.2, 38.4)', () {
    test('formatAsyncCaseSharingNote throws StateError when beneficiary consent is false', () {
      expect(
        () => service.formatAsyncCaseSharingNote(
          patientCodedId: 'P-1234',
          ageGender: '26F',
          primaryComplaint: 'High fever and severe chills',
          vitals: {'temp': 103.2, 'pulse': 110},
          redFlags: ['Fever > 103F'],
          hasBeneficiaryConsent: false,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('formatAsyncCaseSharingNote generates formatted clinical summary when consent is true', () {
      final note = service.formatAsyncCaseSharingNote(
        patientCodedId: 'P-1234',
        ageGender: '26F',
        primaryComplaint: 'High fever and severe chills',
        vitals: {
          'bp': '120/80',
          'pulse': 110,
          'temp': 103.2,
          'spo2': 98,
          'respRate': 22,
        },
        redFlags: ['Fever > 103F', 'Altered sensorium'],
        hasBeneficiaryConsent: true,
      );

      expect(note, contains('Patient ID: P-1234 (26F)'));
      expect(note, contains('Chief Concern: High fever and severe chills'));
      expect(note, contains('BP: 120/80 mmHg'));
      expect(note, contains('Pulse: 110 bpm'));
      expect(note, contains('SpO2: 98%'));
      expect(note, contains('Temp: 103.2 °F'));
      expect(note, contains('Alert Danger Signs: Fever > 103F, Altered sensorium'));
      expect(note, contains('Consent: Verified by ASHA • Purpose: Clinical Advice'));
    });

    test('generateESanjeevaniLink produces valid deep-link URI', () {
      final uri = service.generateESanjeevaniLink(
        patientCodedId: 'BEN-889',
        chiefComplaint: 'Postpartum bleeding',
        specialty: 'Obstetrics',
      );

      expect(uri.scheme, 'esanjeevani');
      expect(uri.host, 'consult');
      expect(uri.queryParameters['patientId'], 'BEN-889');
      expect(uri.queryParameters['complaint'], 'Postpartum bleeding');
      expect(uri.queryParameters['specialty'], 'Obstetrics');
    });
  });

  group('TeleconsultationService - Peer Support Forum (Req 38.3, 38.4)', () {
    test('createPeerMessage creates message without patient data', () {
      final msg = service.createPeerMessage(
        senderName: 'Sunita Devi',
        contentText: 'Any tips on organizing next week VHSND in low-turnout ward?',
        containsPatientData: false,
      );

      expect(msg.senderName, 'Sunita Devi');
      expect(msg.senderRole, 'ASHA');
      expect(msg.isModerated, isTrue);
      expect(msg.contentText, contains('VHSND'));
    });

    test('createPeerMessage throws ArgumentError when patient data is included without consent', () {
      expect(
        () => service.createPeerMessage(
          senderName: 'Sunita Devi',
          contentText: 'Child in Ward 4 has continuous vomiting',
          containsPatientData: true,
          hasPatientConsent: false,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createPeerMessage succeeds when patient data is included with explicit consent', () {
      final msg = service.createPeerMessage(
        senderName: 'Sunita Devi',
        contentText: 'Severe rash consultation query',
        containsPatientData: true,
        hasPatientConsent: true,
      );

      expect(msg.senderName, 'Sunita Devi');
      expect(msg.contentText, 'Severe rash consultation query');
    });
  });
}
