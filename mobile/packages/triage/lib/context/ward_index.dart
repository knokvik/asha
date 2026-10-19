import 'dart:math' as math;

class LatLon {
  const LatLon(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class WardPolygon {
  const WardPolygon({required this.wardId, required this.ring});

  final String wardId;

  /// Closed or open ring of latitude/longitude points. GeoJSON order is converted at parse time.
  final List<LatLon> ring;
}

enum WardFixKind { inside, confirmBoundary, outside, noFix }

class WardResolution {
  const WardResolution({
    required this.kind,
    required this.wardId,
    required this.choices,
  });

  final WardFixKind kind;

  /// The ward that contains the point, when there is one.
  final String? wardId;

  /// Wards the worker may confirm. Empty when the fix is clearly inside one ward.
  final List<String> choices;
}

/// Offline point-in-polygon lookup. Distance uses a local metre approximation.
class WardIndex {
  WardIndex(this.wards);

  final List<WardPolygon> wards;

  static const boundaryMetres = 50.0;

  WardResolution resolve(LatLon? fix) {
    if (fix == null) {
      return WardResolution(
        kind: WardFixKind.noFix,
        wardId: null,
        choices: [for (final ward in wards) ward.wardId],
      );
    }
    WardPolygon? containing;
    for (final ward in wards) {
      if (_contains(ward.ring, fix)) {
        containing = ward;
        break;
      }
    }
    if (containing == null) {
      return WardResolution(
        kind: WardFixKind.outside,
        wardId: null,
        choices: [for (final ward in wards) ward.wardId],
      );
    }
    final near = <String>[containing.wardId];
    for (final ward in wards) {
      if (ward.wardId == containing.wardId) continue;
      if (_distanceToRing(ward.ring, fix) <= boundaryMetres) near.add(ward.wardId);
    }
    final onEdge = _distanceToRing(containing.ring, fix) <= boundaryMetres;
    if (onEdge || near.length > 1) {
      return WardResolution(kind: WardFixKind.confirmBoundary, wardId: containing.wardId, choices: near);
    }
    return WardResolution(kind: WardFixKind.inside, wardId: containing.wardId, choices: const []);
  }

  static bool _contains(List<LatLon> ring, LatLon point) {
    var inside = false;
    final count = _uniqueCount(ring);
    for (var i = 0, j = count - 1; i < count; j = i++) {
      final yi = ring[i].latitude;
      final xi = ring[i].longitude;
      final yj = ring[j].latitude;
      final xj = ring[j].longitude;
      final crosses = (yi > point.latitude) != (yj > point.latitude);
      if (!crosses) continue;
      final xCross = (xj - xi) * (point.latitude - yi) / (yj - yi) + xi;
      if (point.longitude < xCross) inside = !inside;
    }
    return inside;
  }

  static double _distanceToRing(List<LatLon> ring, LatLon point) {
    final count = _uniqueCount(ring);
    var best = double.infinity;
    for (var i = 0; i < count; i++) {
      final next = ring[(i + 1) % count];
      final distance = _distanceToSegment(point, ring[i], next);
      if (distance < best) best = distance;
    }
    return best;
  }

  static int _uniqueCount(List<LatLon> ring) {
    if (ring.length < 2) return ring.length;
    final first = ring.first;
    final last = ring.last;
    final closed = first.latitude == last.latitude && first.longitude == last.longitude;
    return closed ? ring.length - 1 : ring.length;
  }

  static double _distanceToSegment(LatLon point, LatLon a, LatLon b) {
    final metresPerLat = 111320.0;
    final metresPerLon = 111320.0 * math.cos(a.latitude * math.pi / 180);
    final bx = (b.longitude - a.longitude) * metresPerLon;
    final by = (b.latitude - a.latitude) * metresPerLat;
    final px = (point.longitude - a.longitude) * metresPerLon;
    final py = (point.latitude - a.latitude) * metresPerLat;
    final lengthSquared = bx * bx + by * by;
    if (lengthSquared == 0) return math.sqrt(px * px + py * py);
    final t = ((px * bx + py * by) / lengthSquared).clamp(0.0, 1.0);
    final dx = px - t * bx;
    final dy = py - t * by;
    return math.sqrt(dx * dx + dy * dy);
  }
}
