import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/database/app_database.dart' hide TriageResult;
import 'package:asha_platform/core/triage/models/models.dart';
import 'package:asha_platform/features/referral/domain/facility_matcher.dart';
import 'package:asha_platform/features/referral/domain/referral_models.dart';
import 'package:asha_platform/features/referral/domain/referral_note_generator.dart';
import 'package:asha_platform/features/referral/domain/sms_fallback.dart';

void main() {
  group('ReferralNoteGenerator Tests (Requirements 10.1, 10.7)', () {
    late Member member;
    late Household household;
    late User asha;
    late TriageResult redResult;
    late FacilityInfo facility;

    setUp(() {
      final now = DateTime.now().millisecondsSinceEpoch;
      // 25-year-old female
      final dob25YearsAgo = DateTime.now().subtract(const Duration(days: 26 * 365)).millisecondsSinceEpoch;

      member = Member(
        id: 'mem_123',
        householdId: 'hh_456',
        name: 'Sunita Devi',
        sex: 'F',
        dobApprox: dob25YearsAgo,
        isDobApprox: false,
        relationshipToHead: 'Wife',
        phone: '9876543210',
        abhaId: 'ABHA-9988-7766',
        lifecycleStatus: 'active',
        consentStatus: 'granted',
        syncStatus: 'pending',
        createdAt: now,
        updatedAt: now,
        createdBy: 'asha_1',
      );

      household = Household(
        id: 'hh_456',
        headName: 'Ramesh Kumar',
        village: 'Rampur',
        hamlet: 'North Tola',
        isBpl: true,
        memberCount: 4,
        createdAt: now,
        updatedAt: now,
        createdBy: 'asha_1',
        syncStatus: 'pending',
      );

      asha = User(
        id: 'asha_user_1',
        ashaId: 'ASHA-001',
        name: 'Anita Verma',
        role: 'ASHA',
        areaVillage: 'Rampur',
        areaSubcentre: 'Rampur SC',
        areaPhc: 'Gopalganj PHC',
        failedPinAttempts: 0,
        syncStatus: 'synced',
        createdAt: now,
        updatedAt: now,
      );

      redResult = TriageResult(
        id: 'tri_789',
        flag: TriageFlag.red,
        ruleFlag: TriageFlag.red,
        ruleVersionId: '1.0.0',
        evaluatedAt: DateTime.now(),
        findings: const [
          TriageFinding(
            ruleId: 'MATERNAL_SEVERE_PREECLAMPSIA',
            severity: TriageFlag.red,
            findingText: 'Severe systolic hypertension with headache and visual disturbances',
            action: 'IMMEDIATE_HOSPITAL_TRANSFER',
            triggeringValues: {'systolic': 165, 'symptom': 'blurred_vision'},
          ),
        ],
      );

      facility = const FacilityInfo(
        id: 'fac_chc_1',
        name: 'Gopalganj Community Health Centre',
        level: FacilityLevel.chc,
        latitude: 26.47,
        longitude: 84.44,
        distanceKm: 14.2,
        contactPhone: '06156-225010',
        services: ['EMERGENCY', 'FRU', 'OBSTETRICS'],
      );
    });

    test('generates complete structured referral note for RED triage in < 30s readability', () {
      final note = ReferralNoteGenerator.generate(
        triageResult: redResult,
        member: member,
        household: household,
        ashaUser: asha,
        destinationFacility: facility,
        transportArranged: '108 Ambulance',
        rawVitals: {'bp': '165/105 mmHg', 'spo2': '98%'},
      );

      expect(note.referralId, isNotEmpty);
      expect(note.triageFlag, TriageFlag.red);
      expect(note.patient.name, 'Sunita Devi');
      expect(note.patient.sex, 'F');
      expect(note.patient.formattedAge, contains('years'));
      expect(note.patient.abhaId, 'ABHA-9988-7766');
      expect(note.patient.village, 'Rampur');
      expect(note.asha.name, 'Anita Verma');
      expect(note.destinationFacility?.name, 'Gopalganj Community Health Centre');
      expect(note.actionsAlreadyTaken, isNotEmpty);
      expect(note.triggeringReasons, anyElement(contains('Severe systolic hypertension')));
    });

    test('generates valid QR code JSON payload and decodes properly', () {
      final note = ReferralNoteGenerator.generate(
        triageResult: redResult,
        member: member,
        household: household,
        ashaUser: asha,
        destinationFacility: facility,
      );

      final qrString = note.toQrPayload();
      expect(qrString, startsWith('{'));
      expect(qrString, contains('"ref_id"'));
      expect(qrString, contains('"flag":"RED"'));
      expect(qrString, contains('"name":"Sunita Devi"'));
    });

    test('supports bilingual output toggle (Hindi & English)', () {
      final note = ReferralNoteGenerator.generate(
        triageResult: redResult,
        member: member,
        household: household,
        ashaUser: asha,
        destinationFacility: facility,
      );

      final hindiText = note.formatSummary(english: false);
      final englishText = note.formatSummary(english: true);

      expect(hindiText, contains('रेफरल पर्ची'));
      expect(englishText, contains('PRIORITY: [ RED ]'));
      expect(englishText, contains('EMERGENCY CLINICAL REFERRAL NOTE'));
    });
  });

  group('SmsFallbackFormatter Invariant Tests (Property 19 & Requirement 10.2)', () {
    test('SMS length is strictly <= 160 characters under various standard scenarios', () {
      final note = StructuredReferralNote(
        referralId: 'REF-20261015-ABCD',
        encounterId: 'enc_123',
        patient: const ReferralPatientInfo(
          memberId: 'mem_1',
          name: 'Sunita Devi',
          sex: 'F',
          ageInDays: 25 * 365,
          village: 'Rampur',
          contactPhone: '9876543210',
        ),
        triageFlag: TriageFlag.red,
        primaryReason: 'Severe hypertension',
        triggeringReasons: const ['BP 170/110 mmHg', 'Convulsion history'],
        vitalsAndSymptoms: const {'bp': '170/110', 'hr': 98},
        actionsAlreadyTaken: const ['Left lateral tilt', 'Called 108'],
        destinationFacility: const FacilityInfo(
          id: 'fac_1',
          name: 'Gopalganj CHC',
          level: FacilityLevel.chc,
          distanceKm: 12.5,
          contactPhone: '0615622001',
        ),
        transportArranged: '108 Ambulance',
        createdAt: DateTime.now(),
        asha: const ReferralAshaInfo(
          id: 'asha_1',
          name: 'Anita Verma',
          phone: '9876500000',
        ),
      );

      final sms = SmsFallbackFormatter.formatSms(note);
      expect(sms.length, lessThanOrEqualTo(160));
      expect(sms, contains('RED'));
      expect(sms, contains('Sunita Devi'));
    });

    test('SMS length remains strictly <= 160 characters even with exceptionally long inputs', () {
      final longNote = StructuredReferralNote(
        referralId: 'REF-VERY-LONG-IDENTIFIER-STRING-20261015-XYZ9876543210',
        encounterId: 'enc_long_456',
        patient: const ReferralPatientInfo(
          memberId: 'mem_long_id_99999999999999999',
          name: 'Shreemati Parmeshwari Devi Choudhary Kumar',
          sex: 'F',
          ageInDays: 87 * 365,
          village: 'Bishunpur Ramakrishna Nagar Sub-settlement North Block',
          contactPhone: '+91 987654321000',
        ),
        triageFlag: TriageFlag.red,
        primaryReason: 'Severe respiratory distress with altered sensorium and oxygen desaturation below 85 percent',
        triggeringReasons: const [
          'Persistent high fever for past two weeks with chest indrawing and wheezing',
          'Severe dehydration with sunken eyes and lethargy',
        ],
        vitalsAndSymptoms: const {
          'pulse': '145 bpm',
          'spo2': '82 percent',
          'temp': '104.5 F',
          'rr': '44/min',
        },
        actionsAlreadyTaken: const ['Immediate emergency contact established'],
        destinationFacility: const FacilityInfo(
          id: 'fac_long_999',
          name: 'Mahatma Gandhi Memorial District Super Specialty Hospital and Research Institute',
          level: FacilityLevel.districtHospital,
          distanceKm: 48.75,
          contactPhone: '+91 0612 22345678',
        ),
        transportArranged: 'State Government Advanced Life Support 108 Emergency Medical Vehicle',
        createdAt: DateTime.now(),
        asha: const ReferralAshaInfo(
          id: 'asha_long_id',
          name: 'Radhika Swaminathan Mukherjee',
          phone: '+91 998877665544',
        ),
      );

      final sms = SmsFallbackFormatter.formatSms(longNote);
      expect(sms.length, lessThanOrEqualTo(160),
          reason: 'Property 19: SMS MUST strictly fit into a single 160-char GSM PDU regardless of text length');
      expect(sms, contains('RED'));
    });
  });

  group('FacilityMatcher & Care Tiers Tests (Requirements 8.5, 10.3, 10.5)', () {
    final now = DateTime.now().millisecondsSinceEpoch;
    final facilitiesData = <FacilityDirectoryData>[
      FacilityDirectoryData(
        id: 'fac_sc_1',
        name: 'Rampur Sub-Centre',
        facilityLevel: 'SUB_CENTRE',
        district: 'Gopalganj',
        latitude: 26.40,
        longitude: 84.40,
        servicesJson: '["OUTPATIENT", "IMMUNIZATION"]',
        isActive: true,
        lastUpdatedAt: now,
      ),
      FacilityDirectoryData(
        id: 'fac_phc_1',
        name: 'Barauli Primary Health Centre',
        facilityLevel: 'PHC',
        district: 'Gopalganj',
        latitude: 26.42,
        longitude: 84.42,
        servicesJson: '["OUTPATIENT", "DOCTOR", "BASIC_LAB"]',
        isActive: true,
        lastUpdatedAt: now,
      ),
      FacilityDirectoryData(
        id: 'fac_chc_1',
        name: 'Gopalganj Community Health Centre',
        facilityLevel: 'CHC',
        district: 'Gopalganj',
        latitude: 26.47,
        longitude: 84.44,
        servicesJson: '["EMERGENCY", "FRU", "SURGERY"]',
        isActive: true,
        lastUpdatedAt: now,
      ),
      FacilityDirectoryData(
        id: 'fac_sncu_1',
        name: 'Sadar Hospital SNCU',
        facilityLevel: 'SNCU',
        district: 'Gopalganj',
        latitude: 26.55,
        longitude: 84.50,
        servicesJson: '["SNCU", "NEONATAL_ICU"]',
        isActive: true,
        lastUpdatedAt: now,
      ),
    ];

    test('calculates accurate Haversine distance in km', () {
      // Rampur Sub-Centre (26.40, 84.40) to Gopalganj CHC (26.47, 84.44) is approx 8.7 km
      final dist = FacilityMatcher.calculateHaversineDistanceKm(
        26.40,
        84.40,
        26.47,
        84.44,
      );
      expect(dist, greaterThan(8.0));
      expect(dist, lessThan(9.5));
    });

    test('RED general adult triage filters to CHC / DH / FRU facilities', () {
      final matched = FacilityMatcher.matchFacilities(
        allFacilities: facilitiesData,
        triageFlag: TriageFlag.red,
        ashaLatitude: 26.40,
        ashaLongitude: 84.40,
      );

      expect(matched.isNotEmpty, isTrue);
      // Red triage must never recommend Sub-Centre or standalone PHC without FRU
      for (final f in matched) {
        expect(
          f.level == FacilityLevel.chc ||
              f.level == FacilityLevel.subDistrictHospital ||
              f.level == FacilityLevel.districtHospital ||
              f.level == FacilityLevel.medicalCollege ||
              f.level == FacilityLevel.fru ||
              f.level == FacilityLevel.sncu,
          isTrue,
        );
      }
    });

    test('RED neonate (<60 days) qualifies SNCU facility', () {
      final matched = FacilityMatcher.matchFacilities(
        allFacilities: facilitiesData,
        triageFlag: TriageFlag.red,
        ageInDays: 15,
        ashaLatitude: 26.40,
        ashaLongitude: 84.40,
      );

      expect(matched.isNotEmpty, isTrue);
      expect(matched.any((f) => f.level == FacilityLevel.sncu), isTrue);
    });

    test('YELLOW triage matches PHC / CHC', () {
      final matched = FacilityMatcher.matchFacilities(
        allFacilities: facilitiesData,
        triageFlag: TriageFlag.yellow,
        ashaLatitude: 26.40,
        ashaLongitude: 84.40,
      );

      expect(matched.isNotEmpty, isTrue);
      expect(matched.any((f) => f.level == FacilityLevel.phc), isTrue);
    });

    test('Emergency helplines provide 108, 102, 112', () {
      final helplines = FacilityMatcher.nationalEmergencyNumbers;
      expect(helplines.keys, contains('108'));
      expect(helplines.keys, contains('102'));
      expect(helplines.keys, contains('112'));
    });
  });
}
