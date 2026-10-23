import 'dart:convert';

import 'package:triage/triage.dart';

import 'geo_models.dart';

/// Walking graph baked from local streets. Coordinates are degrees.
class RoadGraph {
  RoadGraph._(this.points, this._next, this._weight, this._grid);

  final List<LatLon> points;
  final List<List<int>> _next;
  final List<List<double>> _weight;
  final Map<int, List<int>> _grid;

  factory RoadGraph.parse(String raw) {
    final json = jsonDecode(raw) as Map<String, Object?>;
    final roads = json['roads'] as List<Object?>? ?? const [];
    final index = <int, int>{};
    final points = <LatLon>[];

    int node(int lat, int lon) {
      final key = (lat + 9000000) * 20000000 + (lon + 18000000);
      final found = index[key];
      if (found != null) return found;
      final id = points.length;
      index[key] = id;
      points.add(LatLon(lat / 1e5, lon / 1e5));
      return id;
    }

    final edges = <List<int>>[];
    final weights = <List<double>>[];
    void ensure(int id) {
      while (edges.length <= id) {
        edges.add(<int>[]);
        weights.add(<double>[]);
      }
    }

    void link(int a, int b, int kind) {
      if (a == b) return;
      final metres = haversineMetres(points[a], points[b]) * (kind == 2 ? 4 : 1);
      ensure(a);
      ensure(b);
      edges[a].add(b);
      weights[a].add(metres);
      edges[b].add(a);
      weights[b].add(metres);
    }

    for (final road in roads) {
      final map = road as Map<String, Object?>;
      final kind = (map['k'] as num?)?.toInt() ?? 0;
      final pairs = map['p'] as List<Object?>? ?? const [];
      int? previous;
      for (final pair in pairs) {
        final row = pair as List<Object?>;
        final id = node((row[0] as num).toInt(), (row[1] as num).toInt());
        if (previous != null) link(previous, id, kind);
        previous = id;
      }
    }
    if (points.isEmpty) {
      return RoadGraph._(const [], const [], const [], const {});
    }
    ensure(points.length - 1);

    final grid = <int, List<int>>{};
    for (var i = 0; i < points.length; i++) {
      final cell = _cell(points[i]);
      (grid[cell] ??= <int>[]).add(i);
    }
    return RoadGraph._(points, edges, weights, grid);
  }

  static int _cell(LatLon point) => (point.latitude * 400).floor() * 100000 + (point.longitude * 400).floor();

  int _nearest(LatLon target, {double maxDistanceMetres = 5000}) {
    if (points.isEmpty) return -1;
    var best = -1;
    var bestMetres = double.infinity;
    final baseLat = (target.latitude * 400).floor();
    final baseLon = (target.longitude * 400).floor();
    for (var dLat = -1; dLat <= 1; dLat++) {
      for (var dLon = -1; dLon <= 1; dLon++) {
        final bucket = _grid[(baseLat + dLat) * 100000 + (baseLon + dLon)];
        if (bucket == null) continue;
        for (final id in bucket) {
          final metres = haversineMetres(target, points[id]);
          if (metres < bestMetres) {
            bestMetres = metres;
            best = id;
          }
        }
      }
    }
    if (best != -1 && bestMetres <= maxDistanceMetres) return best;
    for (var i = 0; i < points.length; i++) {
      final metres = haversineMetres(target, points[i]);
      if (metres < bestMetres) {
        bestMetres = metres;
        best = i;
      }
    }
    if (bestMetres > maxDistanceMetres) return -1;
    return best;
  }

  /// Returns a route only when both endpoints can be credibly snapped to this
  /// local road graph. Unlike [route], this never draws a misleading straight
  /// line across a village, district, or state when the pack has no road data
  /// for one of the points.
  List<LatLon>? routeOnRoads(
    LatLon from,
    LatLon to, {
    double maxSnapMetres = 180,
  }) {
    final start = _nearest(from);
    final goal = _nearest(to);
    if (start < 0 || goal < 0) return null;
    if (haversineMetres(from, points[start]) > maxSnapMetres ||
        haversineMetres(to, points[goal]) > maxSnapMetres) {
      return null;
    }
    if (start == goal) return [from, points[start], to];

    final dist = List<double>.filled(points.length, double.infinity);
    final prev = List<int>.filled(points.length, -1);
    dist[start] = 0;
    final heap = _Heap();
    heap.push(0, start);
    while (heap.isNotEmpty) {
      final item = heap.pop();
      final d = item.$1;
      final here = item.$2;
      if (d != dist[here]) continue;
      if (here == goal) break;
      final next = _next[here];
      final weight = _weight[here];
      for (var i = 0; i < next.length; i++) {
        final there = next[i];
        final nd = d + weight[i];
        if (nd < dist[there]) {
          dist[there] = nd;
          prev[there] = here;
          heap.push(nd, there);
        }
      }
    }
    if (dist[goal].isInfinite) return null;
    final path = <LatLon>[to];
    for (var here = goal; here != -1; here = prev[here]) {
      path.add(points[here]);
      if (here == start) break;
    }
    path.add(from);
    return path.reversed.toList();
  }

  /// Road-following walk. A disconnected pair falls back to the straight line.
  List<LatLon> route(LatLon from, LatLon to) {
    final start = _nearest(from);
    final goal = _nearest(to);
    if (start < 0 || goal < 0 || start == goal) return [from, to];
    final dist = List<double>.filled(points.length, double.infinity);
    final prev = List<int>.filled(points.length, -1);
    dist[start] = 0;
    final heap = _Heap();
    heap.push(0, start);
    while (heap.isNotEmpty) {
      final item = heap.pop();
      final d = item.$1;
      final here = item.$2;
      if (d != dist[here]) continue;
      if (here == goal) break;
      final next = _next[here];
      final weight = _weight[here];
      for (var i = 0; i < next.length; i++) {
        final there = next[i];
        final nd = d + weight[i];
        if (nd < dist[there]) {
          dist[there] = nd;
          prev[there] = here;
          heap.push(nd, there);
        }
      }
    }
    if (dist[goal].isInfinite) return [from, to];
    final path = <LatLon>[to];
    for (var here = goal; here != -1; here = prev[here]) {
      path.add(points[here]);
      if (here == start) break;
    }
    path.add(from);
    return path.reversed.toList();
  }
}

/// Chain [stops] along roads. The first stop is the start.
List<LatLon> walkRoute(RoadGraph? graph, List<LatLon> stops) {
  if (stops.length < 2) return stops;
  final path = <LatLon>[];
  for (var i = 0; i < stops.length - 1; i++) {
    final leg = graph?.route(stops[i], stops[i + 1]) ?? [stops[i], stops[i + 1]];
    if (path.isEmpty) {
      path.addAll(leg);
    } else if (leg.length > 1) {
      path.addAll(leg.skip(1));
    }
  }
  return path;
}

/// Chains only verified on-road legs. Missing or disconnected graph data is
/// reported through [unroutableLegs] and is deliberately not replaced by a
/// straight geographic line.
List<LatLon> walkRoadRoute(
  RoadGraph? graph,
  List<LatLon> stops, {
  void Function()? onUnroutableLeg,
}) {
  if (graph == null || stops.length < 2) return const [];
  final path = <LatLon>[];
  for (var i = 0; i < stops.length - 1; i++) {
    final leg = graph.routeOnRoads(stops[i], stops[i + 1]);
    if (leg == null) {
      onUnroutableLeg?.call();
      continue;
    }
    if (path.isEmpty) {
      path.addAll(leg);
    } else {
      path.addAll(leg.skip(1));
    }
  }
  return path;
}

class _Heap {
  final List<({double d, int n})> _items = [];

  bool get isNotEmpty => _items.isNotEmpty;

  void push(double distance, int node) {
    _items.add((d: distance, n: node));
    var i = _items.length - 1;
    while (i > 0) {
      final parent = (i - 1) >> 1;
      if (_items[parent].d <= _items[i].d) break;
      final swap = _items[parent];
      _items[parent] = _items[i];
      _items[i] = swap;
      i = parent;
    }
  }

  (double, int) pop() {
    final top = _items.first;
    final last = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = last;
      var i = 0;
      while (true) {
        final left = i * 2 + 1;
        final right = left + 1;
        var smallest = i;
        if (left < _items.length && _items[left].d < _items[smallest].d) smallest = left;
        if (right < _items.length && _items[right].d < _items[smallest].d) smallest = right;
        if (smallest == i) break;
        final swap = _items[smallest];
        _items[smallest] = _items[i];
        _items[i] = swap;
        i = smallest;
      }
    }
    return (top.d, top.n);
  }
}

double pathMetres(List<LatLon> path) {
  var total = 0.0;
  for (var i = 1; i < path.length; i++) {
    total += haversineMetres(path[i - 1], path[i]);
  }
  return total;
}
