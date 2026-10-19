import 'dart:math' as math;
import 'due_list_models.dart';

/// Geographical coordinate representing latitude and longitude.
class GeoCoordinate {
  final double latitude;
  final double longitude;

  const GeoCoordinate({
    required this.latitude,
    required this.longitude,
  });

  /// Computes Haversine distance in kilometers between two coordinates.
  double distanceTo(GeoCoordinate other) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(other.latitude - latitude);
    final dLon = _degToRad(other.longitude - longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(latitude)) *
            math.cos(_degToRad(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  factory GeoCoordinate.fromJson(Map<String, dynamic> json) => GeoCoordinate(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoCoordinate &&
          runtimeType == other.runtimeType &&
          (latitude - other.latitude).abs() < 1e-6 &&
          (longitude - other.longitude).abs() < 1e-6;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoCoordinate($latitude, $longitude)';
}

/// Reason why a hamlet is inaccessible or seasonal (Requirement 25.4).
enum BarrierReason {
  flood('flood', 'Monsoon Flood / Waterlogging'),
  landslide('landslide', 'Hilly Landslide / Rockfall'),
  roadImpassable('road_impassable', 'Mud / Road Washed Out / Impassable Path'),
  wildlifeHazard('wildlife_hazard', 'Wildlife / Forest Route Hazard'),
  bridgeDamage('bridge_damage', 'Culvert or Footbridge Damaged'),
  extremeWeather('extreme_weather', 'Severe Weather / Cloudburst'),
  other('other', 'Other Physical Access Barrier');

  final String code;
  final String label;
  const BarrierReason(this.code, this.label);

  static BarrierReason fromCode(String? code) {
    if (code == null) return BarrierReason.other;
    return BarrierReason.values.firstWhere(
      (e) => e.code == code,
      orElse: () => BarrierReason.other,
    );
  }
}

/// Accessibility state of a remote hamlet (Requirement 25.4).
class HamletAccessibility {
  final String id;
  final String village;
  final String hamlet;
  final bool isBlocked;
  final BarrierReason reason;
  final String? notes;
  final DateTime reportedAt;
  final DateTime? blockedUntil;

  const HamletAccessibility({
    required this.id,
    required this.village,
    required this.hamlet,
    required this.isBlocked,
    required this.reason,
    this.notes,
    required this.reportedAt,
    this.blockedUntil,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'village': village,
        'hamlet': hamlet,
        'is_blocked': isBlocked,
        'reason': reason.code,
        'notes': notes,
        'reported_at': reportedAt.toIso8601String(),
        'blocked_until': blockedUntil?.toIso8601String(),
      };

  factory HamletAccessibility.fromJson(Map<String, dynamic> json) => HamletAccessibility(
        id: json['id'] as String,
        village: json['village'] as String,
        hamlet: json['hamlet'] as String,
        isBlocked: json['is_blocked'] as bool,
        reason: BarrierReason.fromCode(json['reason'] as String?),
        notes: json['notes'] as String?,
        reportedAt: DateTime.parse(json['reported_at'] as String),
        blockedUntil: json['blocked_until'] != null ? DateTime.parse(json['blocked_until'] as String) : null,
      );
}

/// A hamlet waypoint grouping multiple household visits together for routing (Requirement 25.1).
class HamletWaypoint {
  final String hamlet;
  final String village;
  final GeoCoordinate? coordinate;
  final List<DueTask> tasks;
  final List<String> landmarkNotes;
  final HamletAccessibility? accessibility;

  const HamletWaypoint({
    required this.hamlet,
    required this.village,
    this.coordinate,
    required this.tasks,
    this.landmarkNotes = const [],
    this.accessibility,
  });

  bool get isBlocked => accessibility?.isBlocked ?? false;

  /// Maximum urgency score among all tasks in this hamlet
  double get maxUrgencyScore {
    if (tasks.isEmpty) return 0.0;
    return tasks.map((t) => t.urgencyScore).reduce(math.max);
  }

  /// Whether any task in this hamlet has a RED alert follow-up
  bool get hasRedAlert => tasks.any((t) => t.hasRedAlert);

  int get totalVisits => tasks.length;
}

/// Complete planned itinerary produced by the nearest-neighbour router (Requirement 25.1, 25.2).
class PlannedRoute {
  final GeoCoordinate? startLocation;
  final bool isOptInGpsUsed;
  final List<HamletWaypoint> orderedWaypoints;
  final double totalEstimatedDistanceKm;
  final Duration estimatedWalkingDuration;
  final List<HamletWaypoint> blockedWaypoints;

  const PlannedRoute({
    this.startLocation,
    required this.isOptInGpsUsed,
    required this.orderedWaypoints,
    required this.totalEstimatedDistanceKm,
    required this.estimatedWalkingDuration,
    required this.blockedWaypoints,
  });

  int get totalStops => orderedWaypoints.length;
  int get totalScheduledVisits =>
      orderedWaypoints.fold(0, (sum, w) => sum + w.totalVisits);

  Map<String, dynamic> toSummaryJson() => {
        'start_location': startLocation?.toJson(),
        'opt_in_gps_used': isOptInGpsUsed,
        'total_stops': totalStops,
        'total_visits': totalScheduledVisits,
        'distance_km': double.parse(totalEstimatedDistanceKm.toStringAsFixed(2)),
        'duration_minutes': estimatedWalkingDuration.inMinutes,
        'blocked_hamlets_count': blockedWaypoints.length,
      };
}

/// Supervisor Area Coverage & Workload Rebalance Analysis Report (Requirement 25.5).
class CoverageAnalysisReport {
  final String village;
  final int totalHamlets;
  final int accessibleHamlets;
  final int seasonallyBlockedHamlets;
  final bool ashaConsentGiven;
  final Map<String, int> hamletVisitFrequencies;
  final Map<String, double> hamletCompletionRates;
  final List<String> accessBarriersHistory;
  final List<String> workloadRebalanceSuggestions;

  const CoverageAnalysisReport({
    required this.village,
    required this.totalHamlets,
    required this.accessibleHamlets,
    required this.seasonallyBlockedHamlets,
    required this.ashaConsentGiven,
    required this.hamletVisitFrequencies,
    required this.hamletCompletionRates,
    required this.accessBarriersHistory,
    required this.workloadRebalanceSuggestions,
  });
}
