import 'dart:convert';

import '../../../core/triage/models/models.dart';

/// Status of a referral lifecycle.
///
/// Implements Requirements 10.1, 10.4, 10.5.
enum ReferralStatus {
  created,
  enRoute,
  arrived,
  outcomeRecorded;

  String get value {
    switch (this) {
      case ReferralStatus.created:
        return 'created';
      case ReferralStatus.enRoute:
        return 'en_route';
      case ReferralStatus.arrived:
        return 'arrived';
      case ReferralStatus.outcomeRecorded:
        return 'outcome_recorded';
    }
  }

  static ReferralStatus fromString(String val) {
    switch (val.toLowerCase().replaceAll('-', '_')) {
      case 'en_route':
        return ReferralStatus.enRoute;
      case 'arrived':
        return ReferralStatus.arrived;
      case 'outcome_recorded':
        return ReferralStatus.outcomeRecorded;
      case 'created':
      default:
        return ReferralStatus.created;
    }
  }
}

/// Clinical outcome recorded by the receiving health facility staff.
///
/// Implements Requirement 10.5.
enum OutcomeType {
  arrived,
  treated,
  admitted,
  discharged,
  didNotReach;

  String get value {
    switch (this) {
      case OutcomeType.arrived:
        return 'arrived';
      case OutcomeType.treated:
        return 'treated';
      case OutcomeType.admitted:
        return 'admitted';
      case OutcomeType.discharged:
        return 'discharged';
      case OutcomeType.didNotReach:
        return 'did_not_reach';
    }
  }

  String get label {
    switch (this) {
      case OutcomeType.arrived:
        return 'Patient Arrived at Facility';
      case OutcomeType.treated:
        return 'Treated in Outpatient';
      case OutcomeType.admitted:
        return 'Admitted to Inpatient Ward / ICU';
      case OutcomeType.discharged:
        return 'Treated and Discharged';
      case OutcomeType.didNotReach:
        return 'Patient Did Not Reach Facility';
    }
  }

  static OutcomeType fromString(String val) {
    switch (val.toLowerCase().replaceAll('-', '_')) {
      case 'treated':
        return OutcomeType.treated;
      case 'admitted':
        return OutcomeType.admitted;
      case 'discharged':
        return OutcomeType.discharged;
      case 'did_not_reach':
        return OutcomeType.didNotReach;
      case 'arrived':
      default:
        return OutcomeType.arrived;
    }
  }
}

/// Level of health care facility in Indian public health infrastructure (IPHS).
///
/// Implements Requirement 10.3.
enum FacilityLevel {
  subCentre,
  phc,
  chc,
  subDistrictHospital,
  districtHospital,
  medicalCollege,
  fru,
  sncu;

  String get value {
    switch (this) {
      case FacilityLevel.subCentre:
        return 'SC_HWC';
      case FacilityLevel.phc:
        return 'PHC';
      case FacilityLevel.chc:
        return 'CHC';
      case FacilityLevel.subDistrictHospital:
        return 'SDH';
      case FacilityLevel.districtHospital:
        return 'DH';
      case FacilityLevel.medicalCollege:
        return 'MEDICAL_COLLEGE';
      case FacilityLevel.fru:
        return 'FRU';
      case FacilityLevel.sncu:
        return 'SNCU';
    }
  }

  String get displayName {
    switch (this) {
      case FacilityLevel.subCentre:
        return 'Sub-Centre / Ayushman Arogya Mandir';
      case FacilityLevel.phc:
        return 'Primary Health Centre (PHC)';
      case FacilityLevel.chc:
        return 'Community Health Centre (CHC)';
      case FacilityLevel.subDistrictHospital:
        return 'Sub-District Hospital (SDH)';
      case FacilityLevel.districtHospital:
        return 'District Hospital (DH)';
      case FacilityLevel.medicalCollege:
        return 'Tertiary Care / Medical College';
      case FacilityLevel.fru:
        return 'First Referral Unit (FRU)';
      case FacilityLevel.sncu:
        return 'Special Newborn Care Unit (SNCU)';
    }
  }

  static FacilityLevel fromString(String val) {
    final v = val.toUpperCase().replaceAll('-', '_').replaceAll(' ', '_');
    if (v.contains('SNCU')) return FacilityLevel.sncu;
    if (v.contains('FRU')) return FacilityLevel.fru;
    if (v.contains('COLLEGE') || v.contains('TERTIARY')) return FacilityLevel.medicalCollege;
    if (v.contains('DISTRICT') || v == 'DH') return FacilityLevel.districtHospital;
    if (v.contains('SUB_DISTRICT') || v == 'SDH') return FacilityLevel.subDistrictHospital;
    if (v.contains('CHC') || v.contains('COMMUNITY')) return FacilityLevel.chc;
    if (v.contains('PHC') || v.contains('PRIMARY')) return FacilityLevel.phc;
    return FacilityLevel.subCentre;
  }
}

/// Facility details retrieved from local offline directory.
///
/// Implements Requirement 10.3, 10.5.
class FacilityInfo {
  final String id;
  final String name;
  final FacilityLevel level;
  final String? district;
  final String? block;
  final String? village;
  final double? latitude;
  final double? longitude;
  final String? contactPhone;
  final List<String> services;
  final bool isActive;
  final double? distanceKm;

  const FacilityInfo({
    required this.id,
    required this.name,
    required this.level,
    this.district,
    this.block,
    this.village,
    this.latitude,
    this.longitude,
    this.contactPhone,
    this.services = const [],
    this.isActive = true,
    this.distanceKm,
  });

  factory FacilityInfo.fromJson(Map<String, dynamic> json) {
    List<String> parsedServices = [];
    if (json['services'] is List) {
      parsedServices = (json['services'] as List).map((e) => e.toString()).toList();
    } else if (json['services_json'] is String) {
      try {
        final decoded = jsonDecode(json['services_json'] as String);
        if (decoded is List) {
          parsedServices = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return FacilityInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Health Facility',
      level: FacilityLevel.fromString(json['facility_level'] as String? ?? json['facilityLevel'] as String? ?? 'PHC'),
      district: json['district'] as String?,
      block: json['block'] as String?,
      village: json['village'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      contactPhone: json['contact_phone'] as String? ?? json['contactPhone'] as String?,
      services: parsedServices,
      isActive: json['is_active'] as bool? ?? true,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'facility_level': level.value,
        'district': district,
        'block': block,
        'village': village,
        'latitude': latitude,
        'longitude': longitude,
        'contact_phone': contactPhone,
        'services': services,
        'is_active': isActive,
        if (distanceKm != null) 'distance_km': distanceKm,
      };
}

/// Patient identification information captured in a referral note.
class ReferralPatientInfo {
  final String memberId;
  final String name;
  final String sex;
  final int? ageInDays;
  final int? dobApprox;
  final String? abhaId;
  final String? householdId;
  final String? headName;
  final String? village;
  final String? hamlet;
  final String? contactPhone;

  const ReferralPatientInfo({
    required this.memberId,
    required this.name,
    required this.sex,
    this.ageInDays,
    this.dobApprox,
    this.abhaId,
    this.householdId,
    this.headName,
    this.village,
    this.hamlet,
    this.contactPhone,
  });

  String get formattedAge {
    if (ageInDays != null) {
      if (ageInDays! < 60) return '$ageInDays days';
      final months = (ageInDays! / 30.4).floor();
      if (months < 24) return '$months months';
      final years = (ageInDays! / 365.25).floor();
      return '$years years';
    }
    if (dobApprox != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final days = ((now - dobApprox!) / (1000 * 60 * 60 * 24)).floor();
      if (days < 60) return '$days days';
      final months = (days / 30.4).floor();
      if (months < 24) return '$months months';
      final years = (days / 365.25).floor();
      return '$years years';
    }
    return 'Age unrecorded';
  }
}

/// ASHA worker details identifying the referring community health worker.
class ReferralAshaInfo {
  final String id;
  final String name;
  final String? phone;
  final String? sector;
  final String? village;

  const ReferralAshaInfo({
    required this.id,
    required this.name,
    this.phone,
    this.sector,
    this.village,
  });
}

/// Structured referral note assembled for prompt clinical handoff.
///
/// Implements Requirements 10.1, 10.7:
/// - Designed so a receiving doctor can read and act in < 30 seconds.
/// - Bilingual output support (local language + English).
class StructuredReferralNote {
  final String referralId;
  final String encounterId;
  final ReferralPatientInfo patient;
  final TriageFlag triageFlag;
  final String primaryReason;
  final List<String> triggeringReasons;
  final Map<String, dynamic> vitalsAndSymptoms;
  final List<String> actionsAlreadyTaken;
  final String? overrideFlag;
  final String? overrideReason;
  final FacilityInfo? destinationFacility;
  final String? transportArranged;
  final DateTime createdAt;
  final ReferralAshaInfo asha;

  const StructuredReferralNote({
    required this.referralId,
    required this.encounterId,
    required this.patient,
    required this.triageFlag,
    required this.primaryReason,
    this.triggeringReasons = const [],
    this.vitalsAndSymptoms = const {},
    this.actionsAlreadyTaken = const [],
    this.overrideFlag,
    this.overrideReason,
    this.destinationFacility,
    this.transportArranged,
    required this.createdAt,
    required this.asha,
  });

  /// Formats the note into a high-density, structured summary readable in < 30 seconds.
  ///
  /// Requirement 10.1, 10.7: Supports optional English mode for receiving medical officers.
  String formatSummary({bool english = true}) {
    final buffer = StringBuffer();
    final headerTitle = english
        ? 'EMERGENCY CLINICAL REFERRAL NOTE'
        : 'नैदानिक ​​रेफरल पर्ची (CLINICAL REFERRAL)';

    buffer.writeln('========================================');
    buffer.writeln(headerTitle);
    buffer.writeln('Ref ID: $referralId | Date: ${createdAt.toIso8601String().substring(0, 16).replaceAll('T', ' ')}');
    buffer.writeln('========================================');

    // 1. Critical Priority Flag
    buffer.writeln('PRIORITY: [ ${triageFlag.label} ] ${triageFlag == TriageFlag.red ? '— IMMEDIATE CLINICAL ACTION' : ''}');
    if (overrideFlag != null) {
      buffer.writeln('  * ASHA OVERRIDE TO: $overrideFlag (Reason: $overrideReason)');
    }
    buffer.writeln('CHIEF COMPLAINT: $primaryReason');
    buffer.writeln('----------------------------------------');

    // 2. Patient Demographics & Contact
    buffer.writeln('PATIENT DETAILS:');
    buffer.writeln('  Name: ${patient.name} | Sex: ${patient.sex} | Age: ${patient.formattedAge}');
    if (patient.abhaId != null && patient.abhaId!.isNotEmpty) {
      buffer.writeln('  ABHA ID: ${patient.abhaId}');
    }
    buffer.writeln('  Village/Hamlet: ${patient.village ?? "Community"}${patient.hamlet != null ? " / ${patient.hamlet}" : ""}');
    if (patient.contactPhone != null && patient.contactPhone!.isNotEmpty) {
      buffer.writeln('  Family Phone: ${patient.contactPhone}');
    }
    buffer.writeln('----------------------------------------');

    // 3. Measured Vitals & Key Symptoms
    buffer.writeln('MEASURED VITALS & OBSERVATIONS:');
    if (vitalsAndSymptoms.isNotEmpty) {
      vitalsAndSymptoms.forEach((key, val) {
        final formattedKey = key.replaceAll('_', ' ').toUpperCase();
        buffer.writeln('  • $formattedKey: $val');
      });
    } else {
      buffer.writeln('  • No additional numerical vitals entered.');
    }

    if (triggeringReasons.isNotEmpty) {
      buffer.writeln('TRIGGERING CDSS RULES:');
      for (final r in triggeringReasons) {
        buffer.writeln('  • $r');
      }
    }
    buffer.writeln('----------------------------------------');

    // 4. Actions Already Taken by ASHA
    buffer.writeln('ACTIONS ALREADY TAKEN BY ASHA:');
    if (actionsAlreadyTaken.isNotEmpty) {
      for (final a in actionsAlreadyTaken) {
        buffer.writeln('  ✓ $a');
      }
    } else {
      buffer.writeln('  ✓ Kept patient calm, counselled family, arranged immediate transit');
    }
    buffer.writeln('----------------------------------------');

    // 5. Destination & Transit
    if (destinationFacility != null) {
      buffer.writeln('REFERRED TO:');
      buffer.writeln('  Facility: ${destinationFacility!.name} (${destinationFacility!.level.displayName})');
      if (destinationFacility!.contactPhone != null) {
        buffer.writeln('  Facility Phone: ${destinationFacility!.contactPhone}');
      }
    }
    if (transportArranged != null && transportArranged!.isNotEmpty) {
      buffer.writeln('  Transport: $transportArranged');
    }
    buffer.writeln('----------------------------------------');

    // 6. ASHA Contact
    buffer.writeln('REFERRING ASHA WORKER:');
    buffer.writeln('  Name: ${asha.name} | ID: ${asha.id}');
    if (asha.phone != null && asha.phone!.isNotEmpty) {
      buffer.writeln('  Contact Phone: ${asha.phone}');
    }
    buffer.writeln('========================================');

    return buffer.toString();
  }

  /// Compact JSON payload for QR code transfer to facility dashboard / receiving tablet.
  String toQrPayload() {
    final map = {
      'ref_id': referralId,
      'member_id': patient.memberId,
      'name': patient.name,
      'sex': patient.sex,
      'age': patient.formattedAge,
      'flag': triageFlag.label,
      'reason': primaryReason,
      'vitals': vitalsAndSymptoms,
      'facility_id': destinationFacility?.id,
      'asha_id': asha.id,
      'asha_phone': asha.phone,
      'time': createdAt.millisecondsSinceEpoch,
    };
    return jsonEncode(map);
  }
}
