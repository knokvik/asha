import '../../../core/database/app_database.dart';
import '../../../core/triage/models/triage_flag.dart';
import '../../../core/triage/models/triage_inputs.dart';
import 'facility_capabilities.dart';
import 'facility_matcher.dart';
import 'referral_models.dart';

/// Clinical routing scenario selected from explicit assessment findings.
enum ReferralRoutingScenario {
  obstetricBleeding,
  severeAcuteMalnutrition,
  snakebite,
  highBloodPressure,
  routine,
}

class OfflineRoutingRequest {
  const OfflineRoutingRequest({
    required this.triageFlag,
    this.obstetricBleeding = false,
    this.muacMm,
    this.snakebite = false,
    this.systolicBp,
    this.highBloodPressure = false,
    this.avoidFerryCrossings = false,
  });

  final TriageFlag triageFlag;
  final bool obstetricBleeding;
  final double? muacMm;
  final bool snakebite;
  final int? systolicBp;
  final bool highBloodPressure;
  final bool avoidFerryCrossings;

  factory OfflineRoutingRequest.fromTriageInputs(
    TriageInputs inputs, {
    required TriageFlag triageFlag,
  }) {
    final systolic =
        inputs.getNumeric('systolic_bp')?.round() ??
        inputs.getNumeric('systolic')?.round();
    final muac =
        inputs.getNumeric('muac_mm')?.toDouble() ??
        inputs.getNumeric('muac')?.toDouble();
    return OfflineRoutingRequest(
      triageFlag: triageFlag,
      obstetricBleeding: _readBool(inputs, const [
        'obstetric_bleeding',
        'postpartum_haemorrhage',
        'postpartum_hemorrhage',
        'heavy_vaginal_bleeding',
      ]),
      muacMm: muac,
      snakebite: _readBool(inputs, const [
        'snakebite',
        'snake_bite',
        'snake_bite_suspected',
      ]),
      systolicBp: systolic,
      highBloodPressure: _readBool(inputs, const [
        'high_bp',
        'high_blood_pressure',
        'cbac_high_bp',
      ]),
      avoidFerryCrossings: _readBool(inputs, const [
        'avoid_ferry_crossings',
        'route_avoid_ferry',
      ]),
    );
  }

  ReferralRoutingScenario get scenario {
    // Emergency-specific signals are deliberately ordered before routine
    // triage. A generic RED flag must not erase a more specific destination.
    if (obstetricBleeding) return ReferralRoutingScenario.obstetricBleeding;
    if (muacMm != null && muacMm! > 0 && muacMm! < 115) {
      return ReferralRoutingScenario.severeAcuteMalnutrition;
    }
    if (snakebite) return ReferralRoutingScenario.snakebite;
    if (highBloodPressure || (systolicBp != null && systolicBp! >= 140)) {
      return ReferralRoutingScenario.highBloodPressure;
    }
    return ReferralRoutingScenario.routine;
  }

  static bool _readBool(TriageInputs inputs, Iterable<String> keys) =>
      keys.any((key) => inputs.getBool(key) == true);
}

class FacilityRouteCandidate {
  const FacilityRouteCandidate({
    required this.facility,
    required this.requiredCapabilities,
    required this.matchedCapabilities,
    required this.routeSafetyKnown,
    required this.routeAvoidsFerry,
  });

  final FacilityInfo facility;
  final Set<String> requiredCapabilities;
  final Set<String> matchedCapabilities;
  final bool routeSafetyKnown;
  final bool routeAvoidsFerry;

  bool get hasExactCapabilities =>
      matchedCapabilities.containsAll(requiredCapabilities);
}

class FacilityRoutePlan {
  const FacilityRoutePlan({
    required this.scenario,
    required this.destinations,
    required this.affordabilityOptions,
    required this.requiredCapabilities,
    required this.rationale,
    required this.warnings,
    this.emergencyNumber,
  });

  final ReferralRoutingScenario scenario;
  final List<FacilityRouteCandidate> destinations;
  final List<FacilityRouteCandidate> affordabilityOptions;
  final Set<String> requiredCapabilities;
  final String rationale;
  final List<String> warnings;
  final String? emergencyNumber;

  bool get hasExactDestination =>
      destinations.any((item) => item.hasExactCapabilities);
}

/// Offline capability-first referral routing.
///
/// This is intentionally conservative: for life-threatening scenarios it
/// returns no generic fallback when the required capability is not verified in
/// the local pack. The UI can then tell the ASHA to call 108/112 and verify the
/// receiving facility, instead of sending a family to the nearest wrong door.
abstract final class OfflineReferralRouter {
  static FacilityRoutePlan plan({
    required List<FacilityDirectoryData> allFacilities,
    required OfflineRoutingRequest request,
    double? ashaLatitude,
    double? ashaLongitude,
    String? district,
  }) {
    final scenario = request.scenario;
    final requirements = _requirementsFor(scenario);
    final candidates = <FacilityRouteCandidate>[];

    for (final row in allFacilities) {
      if (!row.isActive) continue;
      final level = FacilityLevel.fromString(row.facilityLevel);
      if (!FacilityMatcher.isLevelQualified(
        level: level,
        flag: request.triageFlag,
      )) {
        continue;
      }
      if (district != null &&
          district.trim().isNotEmpty &&
          row.district != null &&
          row.district!.trim().isNotEmpty &&
          row.district!.toLowerCase() != district.trim().toLowerCase()) {
        continue;
      }

      final facility = FacilityInfo.fromDirectoryRow(row);
      final capabilities = facility.capabilities;
      final matched = capabilities.intersection(requirements);
      final knownFerry = capabilities.contains(
        FacilityCapability.routeFerryCrossing,
      );
      // Missing road metadata is unknown, not safe. Only an explicit
      // route_ferry_safe tag can claim ferry avoidance offline.
      final routeSafe = capabilities.contains(
        FacilityCapability.routeFerrySafe,
      );
      if (request.avoidFerryCrossings && knownFerry) continue;

      // Specialised scenarios require an explicit source capability. Routine
      // care may use any qualifying facility, as required by the product brief.
      if (scenario != ReferralRoutingScenario.routine &&
          !matched.containsAll(requirements)) {
        continue;
      }
      if (scenario == ReferralRoutingScenario.highBloodPressure &&
          !capabilities.contains(FacilityCapability.cho) &&
          !capabilities.contains(FacilityCapability.ncdClinic)) {
        continue;
      }

      final distance =
          ashaLatitude != null &&
              ashaLongitude != null &&
              facility.latitude != null &&
              facility.longitude != null
          ? FacilityMatcher.calculateHaversineDistanceKm(
              ashaLatitude,
              ashaLongitude,
              facility.latitude!,
              facility.longitude!,
            )
          : null;
      candidates.add(
        FacilityRouteCandidate(
          facility: facility.copyWithDistance(distance),
          requiredCapabilities: requirements,
          matchedCapabilities: matched,
          routeSafetyKnown: capabilities.contains(
            FacilityCapability.routeNetworkV1,
          ),
          routeAvoidsFerry: routeSafe,
        ),
      );
    }

    candidates.sort((a, b) {
      if (request.avoidFerryCrossings &&
          a.routeAvoidsFerry != b.routeAvoidsFerry) {
        return a.routeAvoidsFerry ? -1 : 1;
      }
      if (a.routeSafetyKnown != b.routeSafetyKnown) {
        return a.routeSafetyKnown ? -1 : 1;
      }
      final aDistance = a.facility.distanceKm;
      final bDistance = b.facility.distanceKm;
      if (aDistance != null && bDistance != null) {
        return aDistance.compareTo(bDistance);
      }
      if (aDistance != null) return -1;
      if (bDistance != null) return 1;
      return a.facility.name.compareTo(b.facility.name);
    });

    final affordability = scenario == ReferralRoutingScenario.routine
        ? candidates
              .where(
                (candidate) => candidate.facility.hasCapability(
                  FacilityCapability.janaushadhi,
                ),
              )
              .take(3)
              .toList()
        : const <FacilityRouteCandidate>[];

    final warnings = <String>[];
    if (candidates.isEmpty && scenario != ReferralRoutingScenario.routine) {
      warnings.add(
        'No locally verified facility has all required capabilities. Call 108/112 and confirm capacity before travel.',
      );
    }
    if (request.avoidFerryCrossings &&
        candidates.any((candidate) => !candidate.routeSafetyKnown)) {
      warnings.add(
        'Road-network metadata is incomplete offline; verify the route locally. Ferry avoidance is only guaranteed for tagged roads.',
      );
    }

    return FacilityRoutePlan(
      scenario: scenario,
      destinations: candidates,
      affordabilityOptions: affordability,
      requiredCapabilities: requirements,
      rationale: _rationaleFor(scenario),
      warnings: warnings,
      emergencyNumber: _emergencyNumberFor(scenario),
    );
  }

  static Set<String> _requirementsFor(ReferralRoutingScenario scenario) {
    switch (scenario) {
      case ReferralRoutingScenario.obstetricBleeding:
        return {FacilityCapability.bloodBank, FacilityCapability.deliveryRoom};
      case ReferralRoutingScenario.severeAcuteMalnutrition:
        return {FacilityCapability.nrc};
      case ReferralRoutingScenario.snakebite:
        return {FacilityCapability.antivenom, FacilityCapability.bloodBank};
      case ReferralRoutingScenario.highBloodPressure:
        // AB-HWC is mandatory; CHO and NCD clinic are alternative evidence
        // tags because either can represent the facility's NCD capability.
        return {FacilityCapability.abHwc};
      case ReferralRoutingScenario.routine:
        return const {};
    }
  }

  static String _rationaleFor(ReferralRoutingScenario scenario) {
    switch (scenario) {
      case ReferralRoutingScenario.obstetricBleeding:
        return 'Route to the nearest verified facility with blood and a delivery room; call 102/108 immediately.';
      case ReferralRoutingScenario.severeAcuteMalnutrition:
        return 'MUAC below 115 mm routes to a verified Nutrition Rehabilitation Centre, not a generic PHC.';
      case ReferralRoutingScenario.snakebite:
        return 'Route to verified antivenom and blood capacity; do not rely on a generic nearest-facility result.';
      case ReferralRoutingScenario.highBloodPressure:
        return 'Route to an Ayushman Arogya Mandir/AB-HWC with CHO/NCD capacity for confirmation and management.';
      case ReferralRoutingScenario.routine:
        return 'Use the nearest qualifying primary-care facility and show a verified Jan Aushadhi option when available.';
    }
  }

  static String? _emergencyNumberFor(ReferralRoutingScenario scenario) {
    switch (scenario) {
      case ReferralRoutingScenario.obstetricBleeding:
        return '102';
      case ReferralRoutingScenario.snakebite:
      case ReferralRoutingScenario.severeAcuteMalnutrition:
        return '108';
      case ReferralRoutingScenario.highBloodPressure:
      case ReferralRoutingScenario.routine:
        return null;
    }
  }
}
