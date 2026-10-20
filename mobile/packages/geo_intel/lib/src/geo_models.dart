import 'dart:convert';
import 'dart:math' as math;

import 'package:triage/triage.dart';

/// Outbreak rings use the same weekly thresholds as the triage modules.
const conditionThresholds = <String, int>{
  'dengue_like': 3,
  'acute_diarrhoea': 8,
  'measles_like': 2,
  'aes': 1,
  'fever': 15,
};

const conditionModule = <String, String>{
  'dengue_like': 'Dengue',
  'acute_diarrhoea': 'Diarrhoea',
  'measles_like': 'Measles',
  'aes': 'AES',
};

class FacilityPoi {
  const FacilityPoi({
    required this.id,
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.hours,
    required this.capabilities,
    required this.wardId,
  });

  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final String phone;
  final String hours;
  final List<String> capabilities;
  final String wardId;

  LatLon get point => LatLon(latitude, longitude);
}

class HouseholdPin {
  const HouseholdPin({
    required this.id,
    required this.name,
    required this.ageYears,
    required this.latitude,
    required this.longitude,
    required this.dues,
    required this.dueToday,
  });

  final String id;
  final String name;
  final int ageYears;
  final double latitude;
  final double longitude;
  final List<String> dues;
  final bool dueToday;

  LatLon get point => LatLon(latitude, longitude);
}

class ReferralPin {
  const ReferralPin({
    required this.id,
    required this.flag,
    required this.latitude,
    required this.longitude,
    required this.wardId,
  });

  final String id;
  final String flag;
  final double latitude;
  final double longitude;
  final String wardId;
}

class DiseaseTable {
  DiseaseTable(this.rows);

  /// week (1–12) → ward → condition → cases
  final Map<int, Map<String, Map<String, int>>> rows;

  int cases(int week, String wardId, String condition) => rows[week]?[wardId]?[condition] ?? 0;

  List<int> series(String wardId, String condition) =>
      [for (var week = 1; week <= 12; week++) cases(week, wardId, condition)];
}

class GeoPack {
  const GeoPack({
    required this.wards,
    required this.facilities,
    required this.households,
    required this.referrals,
    required this.counts,
    required this.sampleFix,
  });

  final List<WardPolygon> wards;
  final List<FacilityPoi> facilities;
  final List<HouseholdPin> households;
  final List<ReferralPin> referrals;
  final DiseaseTable counts;
  final LatLon sampleFix;

  WardIndex get index => WardIndex(wards);

  factory GeoPack.parse({
    required String wardsGeoJson,
    required String countsCsv,
    required String facilitiesGeoJson,
    required String householdsJson,
    required String referralsJson,
    required double sampleLatitude,
    required double sampleLongitude,
  }) {
    return GeoPack(
      wards: _wards(wardsGeoJson),
      facilities: _facilities(facilitiesGeoJson),
      households: _households(householdsJson),
      referrals: _referrals(referralsJson),
      counts: _counts(countsCsv),
      sampleFix: LatLon(sampleLatitude, sampleLongitude),
    );
  }
}

class RankedFacility {
  const RankedFacility(this.facility, this.metres);

  final FacilityPoi facility;
  final double metres;
}

List<RankedFacility> nearestFacilities(LatLon from, List<FacilityPoi> facilities, {String? capability}) {
  final pool = capability == null
      ? facilities
      : facilities.where((poi) => poi.capabilities.contains(capability)).toList();
  final ranked = [
    for (final poi in pool) RankedFacility(poi, haversineMetres(from, poi.point)),
  ]..sort((a, b) => a.metres.compareTo(b.metres));
  return ranked;
}

class RoutePlan {
  const RoutePlan(this.stops, this.totalMetres);

  final List<HouseholdPin> stops;
  final double totalMetres;
}

/// Greedy nearest-neighbour from the cached fix. Not turn-by-turn.
RoutePlan todaysRoute(LatLon from, List<HouseholdPin> households) {
  final pending = households.where((pin) => pin.dueToday).toList();
  final stops = <HouseholdPin>[];
  var cursor = from;
  var total = 0.0;
  while (pending.isNotEmpty) {
    pending.sort((a, b) => haversineMetres(cursor, a.point).compareTo(haversineMetres(cursor, b.point)));
    final next = pending.removeAt(0);
    total += haversineMetres(cursor, next.point);
    stops.add(next);
    cursor = next.point;
  }
  return RoutePlan(stops, total);
}

enum RadarLevel { quiet, raised, outbreak }

RadarLevel radarLevel(int cases, String condition) {
  final threshold = conditionThresholds[condition] ?? 99;
  if (cases <= 0) return RadarLevel.quiet;
  if (cases >= threshold) return RadarLevel.outbreak;
  return RadarLevel.raised;
}

bool outbreakActive(DiseaseTable counts, int week, String wardId, String condition) =>
    radarLevel(counts.cases(week, wardId, condition), condition) == RadarLevel.outbreak;

/// "Dengue module ACTIVE — 5 cases/week, 4-week trend ↑"
String? outbreakChip(DiseaseTable counts, int week, String wardId, String condition) {
  if (!outbreakActive(counts, week, wardId, condition)) return null;
  final label = conditionModule[condition];
  if (label == null) return null;
  final value = counts.cases(week, wardId, condition);
  final startWeek = math.max(1, week - 3);
  final trend = counts.cases(week, wardId, condition) >= counts.cases(startWeek, wardId, condition) ? '↑' : '↓';
  return '$label module ACTIVE — $value cases/week, 4-week trend $trend';
}

double haversineMetres(LatLon a, LatLon b) {
  const earth = 6371000.0;
  final lat1 = a.latitude * math.pi / 180;
  final lat2 = b.latitude * math.pi / 180;
  final dLat = (b.latitude - a.latitude) * math.pi / 180;
  final dLon = (b.longitude - a.longitude) * math.pi / 180;
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return 2 * earth * math.asin(math.min(1, math.sqrt(h)));
}

class NavigationTargets {
  const NavigationTargets({
    required this.organic,
    required this.google,
    required this.osmand,
    required this.geo,
  });

  final Uri organic;
  final Uri google;
  final Uri osmand;
  final Uri geo;

  static NavigationTargets forPoint(double latitude, double longitude) {
    final pair = '$latitude,$longitude';
    return NavigationTargets(
      organic: Uri.parse('om://route?dll=$pair&type=pedestrian'),
      google: Uri.parse('google.navigation:q=$pair'),
      osmand: Uri.parse('osmand.navigation://q=$pair'),
      geo: Uri.parse('geo:$pair'),
    );
  }

  List<Uri> get chain => [organic, google, osmand, geo];
}

/// Full-screen Organic Maps view. Commas in `ll` stay literal.
Uri organicMapsView({
  required double latitude,
  required double longitude,
  required String name,
  int zoom = 15,
  List<FacilityPoi> pins = const [],
}) {
  final parts = <String>[
    'v=1',
    'll=$latitude,$longitude',
    'n=${Uri.encodeQueryComponent(name)}',
    'z=$zoom',
    for (final pin in pins) ...[
      'll=${pin.latitude},${pin.longitude}',
      'n=${Uri.encodeQueryComponent(pin.name)}',
    ],
  ];
  return Uri.parse('om://map?${parts.join('&')}');
}

const navigationExplainer = 'Organic Maps walks and drives fully offline.';

List<WardPolygon> _wards(String raw) {
  final json = jsonDecode(raw) as Map<String, Object?>;
  final features = json['features'] as List<Object?>;
  return [
    for (final feature in features)
      WardPolygon(
        wardId: ((feature as Map)['properties'] as Map)['ward_id'] as String,
        ring: [
          for (final pair in (((feature['geometry'] as Map)['coordinates'] as List).first as List))
            LatLon(((pair as List)[1] as num).toDouble(), (pair[0] as num).toDouble()),
        ],
      ),
  ];
}

List<FacilityPoi> _facilities(String raw) {
  final json = jsonDecode(raw) as Map<String, Object?>;
  return [
    for (final feature in json['features'] as List)
      FacilityPoi(
        id: (feature as Map)['properties']['id'] as String,
        name: feature['properties']['name'] as String,
        category: feature['properties']['category'] as String,
        longitude: (((feature['geometry'] as Map)['coordinates'] as List)[0] as num).toDouble(),
        latitude: ((feature['geometry']['coordinates'] as List)[1] as num).toDouble(),
        phone: feature['properties']['phone'] as String? ?? '',
        hours: feature['properties']['hours'] as String? ?? '',
        capabilities: [
          for (final item in (feature['properties']['capabilities'] as List? ?? [])) item as String,
        ],
        wardId: feature['properties']['ward_id'] as String? ?? '',
      ),
  ];
}

List<HouseholdPin> _households(String raw) {
  final list = jsonDecode(raw) as List;
  return [
    for (final row in list)
      HouseholdPin(
        id: (row as Map)['id'] as String,
        name: row['name'] as String,
        ageYears: row['age_years'] as int,
        latitude: (row['lat'] as num).toDouble(),
        longitude: (row['lng'] as num).toDouble(),
        dues: [for (final item in row['dues'] as List) item as String],
        dueToday: row['due_today'] as bool,
      ),
  ];
}

List<ReferralPin> _referrals(String raw) {
  final list = jsonDecode(raw) as List;
  return [
    for (final row in list)
      ReferralPin(
        id: (row as Map)['id'] as String,
        flag: row['flag'] as String,
        latitude: (row['lat'] as num).toDouble(),
        longitude: (row['lng'] as num).toDouble(),
        wardId: row['ward_id'] as String,
      ),
  ];
}

DiseaseTable _counts(String csv) {
  final rows = <int, Map<String, Map<String, int>>>{};
  final lines = const LineSplitter().convert(csv);
  for (final line in lines.skip(1)) {
    if (line.trim().isEmpty) continue;
    final parts = line.split(',');
    final week = int.parse(parts[0]);
    final ward = parts[1];
    final condition = parts[2];
    final cases = int.parse(parts[3]);
    rows.putIfAbsent(week, () => {}).putIfAbsent(ward, () => {})[condition] = cases;
  }
  return DiseaseTable(rows);
}

LatLon wardCentroid(WardPolygon ward) {
  var lat = 0.0;
  var lon = 0.0;
  final count = ward.ring.length > 1 &&
          ward.ring.first.latitude == ward.ring.last.latitude &&
          ward.ring.first.longitude == ward.ring.last.longitude
      ? ward.ring.length - 1
      : ward.ring.length;
  for (var i = 0; i < count; i++) {
    lat += ward.ring[i].latitude;
    lon += ward.ring[i].longitude;
  }
  return LatLon(lat / count, lon / count);
}
