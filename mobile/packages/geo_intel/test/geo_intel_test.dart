import 'dart:io';

import 'package:geo_intel/geo_intel.dart';
import 'package:test/test.dart';
import 'package:triage/triage.dart';

void main() {
  late GeoPack pack;

  setUp(() {
    final root = Directory.current.path;
    String read(String path) => File('$root/$path').readAsStringSync();
    pack = GeoPack.parse(
      wardsGeoJson: read('../triage/lib/data/pack/wards.geojson'),
      countsCsv: read('../triage/lib/data/pack/disease_counts.csv'),
      facilitiesGeoJson: read('../../assets/geo/facilities.geojson'),
      indiaFacilitiesJson: read('../../assets/geo/india_facilities.json'),
      householdsJson: read('../../assets/geo/households.json'),
      referralsJson: read('../../assets/geo/referrals.json'),
      sampleLatitude: 18.64,
      sampleLongitude: 73.84,
    );
  });

  test('cached fix is inside W3', () {
    final resolution = pack.index.resolve(pack.sampleFix);
    expect(resolution.kind, WardFixKind.inside);
    expect(resolution.wardId, 'W3');
  });

  test('nearest NS1 lab is closer than the delivery facility', () {
    final ns1 = nearestFacilities(
      pack.sampleFix,
      pack.facilities,
      capability: 'ns1_dengue_test',
    );
    final delivery = nearestFacilities(
      pack.sampleFix,
      pack.facilities,
      capability: 'delivery_care',
    );
    expect(ns1, isNotEmpty);
    expect(delivery, isNotEmpty);
    expect(ns1.first.facility.capabilities, contains('ns1_dengue_test'));
    expect(ns1.first.metres, lessThan(ns1.last.metres));
    expect(
      delivery.every(
        (row) => row.facility.capabilities.contains('delivery_care'),
      ),
      isTrue,
    );
    expect(ns1.first.metres, lessThan(delivery.first.metres));
  });

  test('W3 dengue week 12 glows and the sparkline is 1, 2, 3, 5', () {
    expect(pack.counts.series('W3', 'dengue_like'), [
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      1,
      2,
      3,
      5,
    ]);
    expect(outbreakActive(pack.counts, 12, 'W3', 'dengue_like'), isTrue);
    expect(outbreakActive(pack.counts, 12, 'W2', 'dengue_like'), isFalse);
    expect(radarLevel(1, 'dengue_like'), RadarLevel.raised);
    expect(radarLevel(5, 'dengue_like'), RadarLevel.outbreak);
    expect(
      outbreakChip(pack.counts, 12, 'W3', 'dengue_like'),
      'Dengue module ACTIVE — 5 cases/week, 4-week trend ↑',
    );
  });

  test("today's route is nearest first and skips a visit that is not due", () {
    final plan = todaysRoute(pack.sampleFix, pack.households);
    expect(plan.stops.map((pin) => pin.id).toList(), [
      'hh-near',
      'hh-mid',
      'hh-far',
    ]);
    expect(plan.totalMetres, greaterThan(0));
  });

  test('navigate chain falls back from Google to OsmAnd to geo', () {
    final targets = NavigationTargets.forPoint(18.64, 73.84);
    expect(targets.chain.map((uri) => uri.toString()).toList(), [
      'google.navigation:q=18.64,73.84',
      'osmand.navigation://q=18.64,73.84',
      'geo:18.64,73.84',
    ]);
    final view = organicMapsView(
      latitude: 18.64,
      longitude: 73.84,
      name: 'Pimpri-Chinchwad',
      pins: [pack.facilities.firstWhere((poi) => poi.id == 'POI-19')],
    );
    expect(
      view.toString(),
      'om://map?v=1&ll=18.64,73.84&n=Pimpri-Chinchwad&z=15&ll=18.6412,73.8408&n=Diagnostic+lab+W3',
    );
  });

  test('offline directional guidance returns bearing and cardinal label', () {
    const from = LatLon(18.64, 73.84);
    const east = LatLon(18.64, 73.85);
    expect(bearingDegrees(from, east), closeTo(90, 1));
    expect(bearingLabel(bearingDegrees(from, east)), 'E');
    expect(haversineMetres(from, east), greaterThan(0));
  });

  test('a walking route follows the street graph', () {
    final graph = RoadGraph.parse(
      '{"roads":[{"k":0,"p":[[1864000,7384000],[1864500,7384000],[1864500,7384500]]}]}',
    );
    final path = graph.route(
      const LatLon(18.64, 73.84),
      const LatLon(18.645, 73.845),
    );
    expect(path.first.latitude, closeTo(18.64, 0.0001));
    expect(path.last.longitude, closeTo(73.845, 0.0001));
    expect(path.length, greaterThan(2));
    expect(
      pathMetres(path),
      greaterThan(haversineMetres(path.first, path.last)),
    );
  });

  test('road-only route refuses endpoints outside the local road pack', () {
    final graph = RoadGraph.parse(
      '{"roads":[{"k":0,"p":[[1864000,7384000],[1864500,7384000],[1864500,7384500]]}]}',
    );

    expect(
      graph.routeOnRoads(
        const LatLon(18.64, 73.84),
        const LatLon(19.64, 74.84),
      ),
      isNull,
    );
  });

  test('the directory has one pin of every category', () {
    expect(pack.facilities.length, greaterThanOrEqualTo(57));
    final categories = pack.facilities.map((poi) => poi.category).toSet();
    expect(
      categories,
      containsAll([
        'phc',
        'sub_centre',
        'chc',
        'hospital',
        'dispensary',
        'lab',
        'blood_bank',
        'janaushadhi',
        'anganwadi',
        'block_office',
        'panchayat',
        'police',
        'ration_shop',
      ]),
    );
  });
}
