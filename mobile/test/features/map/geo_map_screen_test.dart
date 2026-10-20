import 'dart:io';

import 'package:asha_platform/features/map/data/mbtiles_tile_provider.dart';
import 'package:asha_platform/features/map/presentation/geo_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_intel/geo_intel.dart';

void main() {
  late GeoPack pack;

  setUp(() {
    String read(String path) => File(path).readAsStringSync();
    pack = GeoPack.parse(
      wardsGeoJson: read('packages/triage/lib/data/pack/wards.geojson'),
      countsCsv: read('packages/triage/lib/data/pack/disease_counts.csv'),
      facilitiesGeoJson: read('assets/geo/facilities.geojson'),
      householdsJson: read('assets/geo/households.json'),
      referralsJson: read('assets/geo/referrals.json'),
      sampleLatitude: 18.64,
      sampleLongitude: 73.84,
    );
  });

  testWidgets('the map is embedded and has no search field', (tester) async {
    final opened = <Uri>[];
    await tester.pumpWidget(
      MaterialApp(
        home: GeoMapScreen(
          pack: pack,
          tiles: MemoryTileProvider(MbTilesTileProvider.blank),
          openUri: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const Key('zoom_in')), findsOneWidget);
    expect(find.byKey(const Key('zoom_out')), findsOneWidget);
    expect(find.text('Diagnostic lab W3'), findsWidgets);
    expect(find.text('Search government facilities'), findsNothing);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byKey(const Key('geo_map_screen')), findsOneWidget);
    expect(opened, isEmpty);

    await tester.tap(find.byKey(const Key('poi-POI-19')));
    await tester.pump();
    expect(find.text('Diagnostic lab W3'), findsWidgets);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.byKey(const Key('call-POI-19')));
    await tester.pump();
    expect(opened.single.toString(), 'tel:02067000019');
  });

  testWidgets('offline layers expose radar ward detail and household route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GeoMapScreen(
          pack: pack,
          tiles: MemoryTileProvider(MbTilesTileProvider.blank),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Disease radar'));
    await tester.pump();
    expect(find.text('Dengue-like'), findsOneWidget);
    expect(find.byKey(const Key('ward-W3')), findsOneWidget);

    await tester.tap(find.byKey(const Key('ward-W3')));
    await tester.pump();
    expect(find.textContaining('W3 · Dengue-like'), findsOneWidget);
    expect(find.textContaining('Dengue module ACTIVE'), findsOneWidget);

    await tester.tap(find.text('Households'));
    await tester.pump();
    expect(find.text("Today's route"), findsOneWidget);
    await tester.tap(find.byKey(const Key('household-hh-near')));
    await tester.pump();
    expect(find.text('Demo household near'), findsOneWidget);
  });
}
