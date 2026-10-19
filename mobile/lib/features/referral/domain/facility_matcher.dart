import 'dart:convert';
import 'dart:math' as math;

import '../../../core/database/app_database.dart';
import '../../../core/triage/models/models.dart';
import 'referral_models.dart';

/// Service performing offline nearest qualifying health facility matching.
///
/// Implements Requirements 8.5, 10.3, 10.5:
/// - Proposes appropriate facility level based on triage severity (SC/HWC, PHC, CHC, DH, Higher Centre).
/// - Filters by care level capability matching clinical urgency.
/// - Computes Haversine distance from ASHA's registered coordinates.
/// - Returns shortest-distance qualifying facilities with contact phones and available services.
class FacilityMatcher {
  /// Radius of Earth in kilometres.
  static const double earthRadiusKm = 6371.0;

  /// Emergency dial numbers available offline across India (Requirement 10.8).
  static const Map<String, String> nationalEmergencyNumbers = {
    '108': 'National Ambulance Service (Emergency / Trauma)',
    '102': 'Janani Shishu Suraksha Karyakram (Pregnant Women & Neonates)',
    '112': 'Integrated National Emergency Helpline',
  };

  /// Computes great-circle distance between two GPS coordinates using the Haversine formula.
  static double calculateHaversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degree) => degree * math.pi / 180.0;

  /// Determines whether a facility level is qualified to handle a given triage severity.
  ///
  /// Requirement 10.3:
  /// - RED triage: Secondary or Tertiary Care (CHC, SDH, DH, Medical College, FRU, SNCU).
  /// - YELLOW triage: Medical Officer evaluation (PHC, CHC, HWC with Doctor/CHO).
  /// - GREEN triage: Primary Care / Outpatient home care (Sub-Centre, HWC, PHC).
  static bool isLevelQualified({
    required FacilityLevel level,
    required TriageFlag flag,
    int? ageInDays,
  }) {
    switch (flag) {
      case TriageFlag.red:
        // Young infants under 60 days with RED flag benefit from SNCU / FRU / DH / CHC
        if (ageInDays != null && ageInDays < 60) {
          return level == FacilityLevel.sncu ||
              level == FacilityLevel.fru ||
              level == FacilityLevel.districtHospital ||
              level == FacilityLevel.subDistrictHospital ||
              level == FacilityLevel.medicalCollege ||
              level == FacilityLevel.chc;
        }
        return level == FacilityLevel.chc ||
            level == FacilityLevel.subDistrictHospital ||
            level == FacilityLevel.districtHospital ||
            level == FacilityLevel.medicalCollege ||
            level == FacilityLevel.fru ||
            level == FacilityLevel.sncu;

      case TriageFlag.yellow:
        return level == FacilityLevel.phc ||
            level == FacilityLevel.chc ||
            level == FacilityLevel.subDistrictHospital ||
            level == FacilityLevel.districtHospital;

      case TriageFlag.green:
        return true; // All facilities qualify for green / routine care
    }
  }

  /// Matches and sorts qualifying facilities from a list of records.
  static List<FacilityInfo> matchFacilities({
    required List<FacilityDirectoryData> allFacilities,
    required TriageFlag triageFlag,
    double? ashaLatitude,
    double? ashaLongitude,
    int? ageInDays,
    String? preferredDistrict,
  }) {
    final qualifying = <FacilityInfo>[];

    for (final row in allFacilities) {
      if (!row.isActive) continue;

      final level = FacilityLevel.fromString(row.facilityLevel);
      if (!isLevelQualified(level: level, flag: triageFlag, ageInDays: ageInDays)) {
        continue;
      }

      double? distance;
      if (ashaLatitude != null &&
          ashaLongitude != null &&
          row.latitude != null &&
          row.longitude != null) {
        distance = calculateHaversineDistanceKm(
          ashaLatitude,
          ashaLongitude,
          row.latitude!,
          row.longitude!,
        );
      }

      List<String> services = [];
      try {
        final decoded = jsonDecode(row.servicesJson);
        if (decoded is List) {
          services = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}

      qualifying.add(
        FacilityInfo(
          id: row.id,
          name: row.name,
          level: level,
          district: row.district,
          block: row.block,
          village: row.village,
          latitude: row.latitude,
          longitude: row.longitude,
          contactPhone: row.contactPhone,
          services: services,
          isActive: row.isActive,
          distanceKm: distance != null ? double.parse(distance.toStringAsFixed(1)) : null,
        ),
      );
    }

    // Sort by distance ascending if GPS available, otherwise by facility tier
    qualifying.sort((a, b) {
      if (a.distanceKm != null && b.distanceKm != null) {
        return a.distanceKm!.compareTo(b.distanceKm!);
      }
      if (a.distanceKm != null) return -1;
      if (b.distanceKm != null) return 1;
      return a.name.compareTo(b.name);
    });

    return qualifying;
  }

  /// Queries the local Drift database directly for nearest qualifying facilities.
  static Future<List<FacilityInfo>> matchFromDb({
    required AppDatabase db,
    required TriageFlag triageFlag,
    double? ashaLatitude,
    double? ashaLongitude,
    int? ageInDays,
    String? district,
  }) async {
    final query = db.select(db.facilityDirectory)..where((t) => t.isActive.equals(true));
    if (district != null && district.trim().isNotEmpty) {
      query.where((t) => t.district.equals(district.trim()));
    }

    final rows = await query.get();

    return matchFacilities(
      allFacilities: rows,
      triageFlag: triageFlag,
      ashaLatitude: ashaLatitude,
      ashaLongitude: ashaLongitude,
      ageInDays: ageInDays,
      preferredDistrict: district,
    );
  }

  /// Returns standard emergency transport options for a referral.
  static List<String> getTransportOptions(TriageFlag flag) {
    if (flag == TriageFlag.red) {
      return [
        '108 — National Emergency Ambulance',
        '102 — Janani Shishu Vahan (Maternal/Infant)',
        'Local Gram Panchayat Emergency Vehicle',
        'Private Auto / Vehicle Arranged by Family',
      ];
    }
    return [
      '102 — Free Transport Vehicle (if eligible)',
      'Public Bus / Shared Transport',
      'Private Two-Wheeler / Auto',
      'Walking / Home Visit Follow-up',
    ];
  }
}
