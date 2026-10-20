import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geo_intel/geo_intel.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/asha_bottom_nav.dart';
import '../data/mbtiles_tile_provider.dart';

typedef UriOpener = Future<bool> Function(Uri uri);

/// Opens the phone dialer. Map drawing never leaves the app.
Future<bool> openExternalUri(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object {
    return false;
  }
}

/// Loads the shipped street pack. Tiles and routes stay on the device.
class GeoMapPage extends StatefulWidget {
  const GeoMapPage({super.key, this.openUri = openExternalUri});

  final UriOpener openUri;

  @override
  State<GeoMapPage> createState() => _GeoMapPageState();
}

class _GeoMapPageState extends State<GeoMapPage> {
  GeoPack? _pack;
  TileProvider? _tiles;
  RoadGraph? _roads;
  List<MapLabel> _labels = const [];
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final wards = await rootBundle.loadString('packages/triage/lib/data/pack/wards.geojson');
      final counts = await rootBundle.loadString('packages/triage/lib/data/pack/disease_counts.csv');
      final facilities = await rootBundle.loadString('assets/geo/facilities.geojson');
      final households = await rootBundle.loadString('assets/geo/households.json');
      final referrals = await rootBundle.loadString('assets/geo/referrals.json');
      final roads = await rootBundle.loadString('assets/geo/roads.json');
      final labelsRaw = await rootBundle.loadString('assets/geo/labels.json');
      final bytes = await rootBundle.load('assets/geo/pcmc.mbtiles');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pcmc.mbtiles');
      await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes), flush: true);
      final database = sql.sqlite3.open(file.path, mode: sql.OpenMode.readOnly);
      if (!mounted) return;
      setState(() {
        _pack = GeoPack.parse(
          wardsGeoJson: wards,
          countsCsv: counts,
          facilitiesGeoJson: facilities,
          householdsJson: households,
          referralsJson: referrals,
          sampleLatitude: 18.64,
          sampleLongitude: 73.84,
        );
        _tiles = MbTilesTileProvider(database);
        _roads = RoadGraph.parse(roads);
        _labels = MapLabel.parse(labelsRaw);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pack = _pack;
    final tiles = _tiles;
    if (_error != null) {
      return Scaffold(
        bottomNavigationBar: const AshaBottomNav(index: 1),
        body: Center(child: Text('Offline map failed to open: $_error')),
      );
    }
    if (pack == null || tiles == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2EFE9),
        bottomNavigationBar: AshaBottomNav(index: 1),
        body: SizedBox.expand(),
      );
    }
    return GeoMapScreen(pack: pack, tiles: tiles, roads: _roads, labels: _labels, openUri: widget.openUri);
  }
}

/// Embedded street map. No search field and no other map app.
class GeoMapScreen extends StatefulWidget {
  const GeoMapScreen({
    super.key,
    required this.pack,
    required this.tiles,
    this.roads,
    this.labels = const [],
    this.openUri = openExternalUri,
  });

  final GeoPack pack;
  final TileProvider tiles;
  final RoadGraph? roads;
  final List<MapLabel> labels;
  final UriOpener openUri;

  @override
  State<GeoMapScreen> createState() => _GeoMapScreenState();
}

class _GeoMapScreenState extends State<GeoMapScreen> {
  final _mapController = MapController();
  FacilityPoi? _selected;
  var _ateMarkerTap = false;
  var _zoomLevel = 14.0;
  late final List<LatLng> _dayRoute;

  get _fix => widget.pack.sampleFix;

  @override
  void initState() {
    super.initState();
    final stops = todaysRoute(_fix, widget.pack.households).stops;
    _dayRoute = [
      for (final point in walkRoute(widget.roads, [_fix, for (final stop in stops) stop.point]))
        LatLng(point.latitude, point.longitude),
    ];
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final selectedWalk = selected == null ? null : walkRoute(widget.roads, [_fix, selected.point]);
    final selectedPath = [
      if (selectedWalk != null)
        for (final point in selectedWalk) LatLng(point.latitude, point.longitude),
    ];
    return Scaffold(
      key: const Key('geo_map_screen'),
      backgroundColor: const Color(0xFFF2EFE9),
      bottomNavigationBar: const AshaBottomNav(index: 1),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_fix.latitude, _fix.longitude),
                initialZoom: 14,
                minZoom: 3,
                maxZoom: 18,
                backgroundColor: const Color(0xFFF2EFE9),
                cameraConstraint: CameraConstraint.containCenter(
                  bounds: LatLngBounds(const LatLng(18.60, 73.72), const LatLng(18.72, 73.92)),
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onPositionChanged: (camera, _) {
                  if ((camera.zoom - _zoomLevel).abs() < 0.05) return;
                  setState(() => _zoomLevel = camera.zoom);
                },
                onTap: (_, _) {
                  if (_ateMarkerTap) {
                    _ateMarkerTap = false;
                    return;
                  }
                  if (_selected != null) setState(() => _selected = null);
                },
              ),
              children: [
                TileLayer(
                  tileProvider: widget.tiles,
                  tileDisplay: const TileDisplay.instantaneous(),
                  minZoom: 8,
                  maxZoom: 18,
                  maxNativeZoom: 14,
                ),
                if (_dayRoute.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(points: _dayRoute, strokeWidth: 4, color: const Color(0xFF1D4E89)),
                    ],
                  ),
                if (selectedPath.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(points: selectedPath, strokeWidth: 5, color: const Color(0xFFE11D48)),
                    ],
                  ),
                MarkerLayer(markers: _markers()),
              ],
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                _ZoomButton(key: const Key('zoom_in'), icon: Icons.add, onPressed: () => _changeZoom(1)),
                const SizedBox(height: 8),
                _ZoomButton(key: const Key('zoom_out'), icon: Icons.remove, onPressed: () => _changeZoom(-1)),
              ],
            ),
          ),
          if (selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Material(
                color: Colors.white,
                elevation: 3,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  title: Text(selected.name),
                  subtitle: Text('${pathMetres(selectedWalk!).round()} m on foot'),
                  trailing: TextButton(
                    key: Key('call-${selected.id}'),
                    onPressed: () => widget.openUri(Uri.parse('tel:${selected.phone}')),
                    child: const Text('Call'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _changeZoom(double delta) {
    final camera = _mapController.camera;
    final next = (camera.zoom + delta).clamp(11.0, 18.0);
    _mapController.move(camera.center, next);
    setState(() => _zoomLevel = next);
  }

  List<Marker> _markers() {
    final markers = <Marker>[
      Marker(
        key: const Key('asha_fix'),
        point: LatLng(_fix.latitude, _fix.longitude),
        width: 72,
        height: 36,
        alignment: Alignment.topCenter,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NameChip('You'),
            DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFF1D4E89), shape: BoxShape.circle),
              child: SizedBox(width: 14, height: 14),
            ),
          ],
        ),
      ),
    ];
    if (_zoomLevel >= 13) {
      for (final label in widget.labels) {
        markers.add(
          Marker(
            point: LatLng(label.latitude, label.longitude),
            width: 120,
            height: 16,
            child: IgnorePointer(child: _NameChip(label.name)),
          ),
        );
      }
    }
    for (final poi in widget.pack.facilities) {
      final chosen = _selected?.id == poi.id;
      markers.add(
        Marker(
          key: Key('poi-${poi.id}'),
          point: LatLng(poi.latitude, poi.longitude),
          width: 132,
          height: 46,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () {
              _ateMarkerTap = true;
              setState(() => _selected = poi);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NameChip(poi.name),
                Icon(Icons.place, color: chosen ? const Color(0xFFE11D48) : const Color(0xFF2D5F47), size: 26),
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }
}

class MapLabel {
  const MapLabel(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;

  static List<MapLabel> parse(String raw) {
    final rows = jsonDecode(raw) as List<Object?>;
    return [
      for (final row in rows)
        MapLabel(
          (row as Map<String, Object?>)['n'] as String,
          ((row['lat'] as num).toDouble()),
          (row['lon'] as num).toDouble(),
        ),
    ];
  }
}

class _NameChip extends StatelessWidget {
  const _NameChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: const Color(0xF2FFFFFF), borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, color: Color(0xFF1C1C1C), fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({super.key, required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: const Color(0xFF1E4231))),
      ),
    );
  }
}
