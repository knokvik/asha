import 'due_list_models.dart';
import 'route_models.dart';

/// Pure offline algorithmic route planner implementing Nearest-Neighbour visit ordering
/// and privacy-preserving opt-in GPS handling (Requirements 25.1, 25.2, 25.4).
class RoutePlanner {
  /// Walking speed in km/h used for rural terrain time estimates
  static const double defaultWalkingSpeedKmH = 3.5;

  /// Estimated consultation / clinical encounter time in minutes per beneficiary visit
  static const int estimatedMinutesPerVisit = 15;

  /// Computes an optimal visit itinerary ordering hamlets via nearest-neighbour heuristic.
  ///
  /// Privacy Guarantee (Req 25.2):
  /// - [ashaLocation] is strictly used IF AND ONLY IF [gpsOptIn] is true.
  /// - No GPS coordinates are logged or tracked continuously.
  static PlannedRoute planRoute({
    required List<DueTask> tasks,
    Map<String, GeoCoordinate> hamletCoordinates = const {},
    Map<String, List<String>> hamletLandmarks = const {},
    Map<String, HamletAccessibility> accessibilityMap = const {},
    GeoCoordinate? ashaLocation,
    bool gpsOptIn = false,
    double walkingSpeedKmH = defaultWalkingSpeedKmH,
  }) {
    if (tasks.isEmpty) {
      return const PlannedRoute(
        isOptInGpsUsed: false,
        orderedWaypoints: [],
        totalEstimatedDistanceKm: 0.0,
        estimatedWalkingDuration: Duration.zero,
        blockedWaypoints: [],
      );
    }

    // 1. Group tasks by village + hamlet
    final Map<String, List<DueTask>> tasksByHamlet = {};
    for (final task in tasks) {
      final key = task.hamlet.isNotEmpty ? task.hamlet : 'Main Village';
      tasksByHamlet.putIfAbsent(key, () => []).add(task);
    }

    final List<HamletWaypoint> accessibleWaypoints = [];
    final List<HamletWaypoint> blockedWaypoints = [];

    // 2. Classify waypoints into accessible vs. seasonally/physically blocked (Req 25.4)
    tasksByHamlet.forEach((hamletName, hamletTasks) {
      // Sort tasks within hamlet by clinical priority: RED alerts first, then highest urgency score
      final sortedTasks = List<DueTask>.from(hamletTasks)
        ..sort((a, b) {
          if (a.hasRedAlert != b.hasRedAlert) {
            return a.hasRedAlert ? -1 : 1;
          }
          if (a.urgencyGroup.sortOrder != b.urgencyGroup.sortOrder) {
            return a.urgencyGroup.sortOrder.compareTo(b.urgencyGroup.sortOrder);
          }
          return b.urgencyScore.compareTo(a.urgencyScore);
        });

      final coord = hamletCoordinates[hamletName];
      final landmarks = hamletLandmarks[hamletName] ?? const [];
      final access = accessibilityMap[hamletName];
      final village = hamletTasks.first.village;

      final waypoint = HamletWaypoint(
        hamlet: hamletName,
        village: village,
        coordinate: coord,
        tasks: sortedTasks,
        landmarkNotes: landmarks,
        accessibility: access,
      );

      if (access != null && access.isBlocked) {
        blockedWaypoints.add(waypoint);
      } else {
        accessibleWaypoints.add(waypoint);
      }
    });

    if (accessibleWaypoints.isEmpty) {
      return PlannedRoute(
        startLocation: gpsOptIn ? ashaLocation : null,
        isOptInGpsUsed: gpsOptIn && ashaLocation != null,
        orderedWaypoints: const [],
        totalEstimatedDistanceKm: 0.0,
        estimatedWalkingDuration: Duration.zero,
        blockedWaypoints: blockedWaypoints,
      );
    }

    // 3. Nearest-Neighbour Route Ordering (Req 25.1, 25.2)
    final bool useGps = gpsOptIn && ashaLocation != null;
    final GeoCoordinate? effectiveStart = useGps ? ashaLocation : null;

    final unvisited = List<HamletWaypoint>.from(accessibleWaypoints);
    final ordered = <HamletWaypoint>[];

    // Determine initial anchor point
    HamletWaypoint currentWaypoint;
    if (effectiveStart != null) {
      // Pick waypoint closest to ASHA's opt-in position
      currentWaypoint = _findNearestWaypoint(effectiveStart, unvisited);
    } else {
      // Pick waypoint with highest urgency task (RED alert follow-ups take precedence)
      unvisited.sort((a, b) {
        if (a.hasRedAlert != b.hasRedAlert) {
          return a.hasRedAlert ? -1 : 1;
        }
        return b.maxUrgencyScore.compareTo(a.maxUrgencyScore);
      });
      currentWaypoint = unvisited.first;
    }

    ordered.add(currentWaypoint);
    unvisited.remove(currentWaypoint);

    // Iteratively select nearest neighbour until all hamlets are scheduled
    while (unvisited.isNotEmpty) {
      final currentCoord = currentWaypoint.coordinate;
      if (currentCoord != null) {
        currentWaypoint = _findNearestWaypoint(currentCoord, unvisited);
      } else {
        // Fallback if current waypoint lacks coordinate: pick unvisited with coordinate or highest urgency
        currentWaypoint = unvisited.first;
      }

      ordered.add(currentWaypoint);
      unvisited.remove(currentWaypoint);
    }

    // 4. Calculate total distance and estimated duration
    double totalDistanceKm = 0.0;

    // If starting from opt-in GPS, add distance from current location to first stop
    if (effectiveStart != null && ordered.first.coordinate != null) {
      totalDistanceKm += effectiveStart.distanceTo(ordered.first.coordinate!);
    }

    for (var i = 0; i < ordered.length - 1; i++) {
      final from = ordered[i].coordinate;
      final to = ordered[i + 1].coordinate;
      if (from != null && to != null) {
        totalDistanceKm += from.distanceTo(to);
      } else {
        // Assume default inter-hamlet distance of 1.2 km if coordinates missing
        totalDistanceKm += 1.2;
      }
    }

    final totalVisits = ordered.fold(0, (sum, w) => sum + w.totalVisits);
    final walkingMinutes = (totalDistanceKm / walkingSpeedKmH * 60.0).round();
    final visitMinutes = totalVisits * estimatedMinutesPerVisit;
    final totalDuration = Duration(minutes: walkingMinutes + visitMinutes);

    return PlannedRoute(
      startLocation: effectiveStart,
      isOptInGpsUsed: useGps,
      orderedWaypoints: ordered,
      totalEstimatedDistanceKm: totalDistanceKm,
      estimatedWalkingDuration: totalDuration,
      blockedWaypoints: blockedWaypoints,
    );
  }

  /// Finds the unvisited waypoint with the shortest Haversine distance to [origin].
  static HamletWaypoint _findNearestWaypoint(
    GeoCoordinate origin,
    List<HamletWaypoint> candidates,
  ) {
    HamletWaypoint nearest = candidates.first;
    double minDistance = double.infinity;

    for (final candidate in candidates) {
      final coord = candidate.coordinate;
      if (coord != null) {
        final dist = origin.distanceTo(coord);
        if (dist < minDistance) {
          minDistance = dist;
          nearest = candidate;
        }
      }
    }

    return nearest;
  }
}
