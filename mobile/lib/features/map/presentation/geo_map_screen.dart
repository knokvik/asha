import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geo_intel/geo_intel.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:triage/triage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/asha_bottom_nav.dart';
import '../data/mbtiles_tile_provider.dart';

typedef UriOpener = Future<bool> Function(Uri uri);

class MapStateShape {
  const MapStateShape({required this.name, required this.points});

  final String name;
  final List<LatLng> points;
}

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
  const GeoMapPage({
    super.key,
    this.embedded = false,
    this.openUri = openExternalUri,
  });

  final bool embedded;
  final UriOpener openUri;

  @override
  State<GeoMapPage> createState() => _GeoMapPageState();
}

class _GeoMapPageState extends State<GeoMapPage> {
  GeoPack? _pack;
  TileProvider? _tiles;
  RoadGraph? _roads;
  List<MapLabel> _labels = const [];
  List<MapStateShape> _states = const [];
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final wards = await rootBundle.loadString(
        'packages/triage/lib/data/pack/wards.geojson',
      );
      final counts = await rootBundle.loadString(
        'packages/triage/lib/data/pack/disease_counts.csv',
      );
      final facilities = await rootBundle.loadString(
        'assets/geo/facilities.geojson',
      );
      final indiaFacilities = await rootBundle.loadString(
        'assets/geo/india_facilities.json',
      );
      final states = await rootBundle.loadString(
        'assets/geo/india_states.geojson',
      );
      final households = await rootBundle.loadString(
        'assets/geo/households.json',
      );
      final referrals = await rootBundle.loadString(
        'assets/geo/referrals.json',
      );
      final roads = await rootBundle.loadString('assets/geo/roads.json');
      final labelsRaw = await rootBundle.loadString('assets/geo/labels.json');
      final bytes = await rootBundle.load('assets/geo/pcmc.mbtiles');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/pcmc.mbtiles');
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
      final database = sql.sqlite3.open(file.path, mode: sql.OpenMode.readOnly);
      if (!mounted) return;
      setState(() {
        _pack = GeoPack.parse(
          wardsGeoJson: wards,
          countsCsv: counts,
          facilitiesGeoJson: facilities,
          indiaFacilitiesJson: indiaFacilities,
          householdsJson: households,
          referralsJson: referrals,
          sampleLatitude: 18.64,
          sampleLongitude: 73.84,
        );
        _tiles = MbTilesTileProvider(database);
        _roads = RoadGraph.parse(roads);
        _labels = MapLabel.parse(labelsRaw);
        _states = _parseStateShapes(states);
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
        bottomNavigationBar: widget.embedded
            ? null
            : const AshaBottomNav(index: 1),
        body: Center(child: Text('Offline map failed to open: $_error')),
      );
    }
    if (pack == null || tiles == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2EFE9),
        body: SizedBox.expand(),
      );
    }
    return GeoMapScreen(
      pack: pack,
      tiles: tiles,
      roads: _roads,
      labels: _labels,
      stateOutlines: _states,
      embedded: widget.embedded,
      openUri: widget.openUri,
    );
  }

  List<MapStateShape> _parseStateShapes(String raw) {
    final json = jsonDecode(raw) as Map<String, Object?>;
    final features = json['features'] as List<Object?>? ?? const [];
    final shapes = <MapStateShape>[];
    for (final feature in features) {
      if (feature is! Map) continue;
      final properties = feature['properties'];
      final name = properties is Map ? properties['name'] as String? : null;
      final geometry = feature['geometry'];
      if (name == null || geometry is! Map) continue;
      final type = geometry['type'];
      final coordinates = geometry['coordinates'];
      if (type == 'Polygon' && coordinates is List) {
        _addStateShape(
          shapes,
          name,
          coordinates.isEmpty ? null : coordinates.first,
        );
      } else if (type == 'MultiPolygon' && coordinates is List) {
        for (final polygon in coordinates) {
          if (polygon is List) {
            _addStateShape(
              shapes,
              name,
              polygon.isEmpty ? null : polygon.first,
            );
          }
        }
      }
    }
    return shapes;
  }

  void _addStateShape(
    List<MapStateShape> target,
    String name,
    Object? rawRing,
  ) {
    if (rawRing is! List) return;
    final points = <LatLng>[];
    for (final pair in rawRing) {
      if (pair is! List || pair.length < 2) continue;
      final longitude = (pair[0] as num?)?.toDouble();
      final latitude = (pair[1] as num?)?.toDouble();
      if (latitude != null && longitude != null) {
        points.add(LatLng(latitude, longitude));
      }
    }
    if (points.length >= 3) {
      target.add(MapStateShape(name: name, points: points));
    }
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
    this.stateOutlines = const [],
    this.embedded = false,
    this.openUri = openExternalUri,
  });

  final GeoPack pack;
  final TileProvider tiles;
  final RoadGraph? roads;
  final List<MapLabel> labels;
  final List<MapStateShape> stateOutlines;
  final bool embedded;
  final UriOpener openUri;

  @override
  State<GeoMapScreen> createState() => _GeoMapScreenState();
}

class _GeoMapScreenState extends State<GeoMapScreen> {
  static const _mapSheetReserved = 196.0;
  final _mapController = MapController();
  FacilityPoi? _selected;
  HouseholdPin? _selectedHousehold;
  WardPolygon? _selectedWard;
  var _ateMarkerTap = false;
  var _zoomLevel = 4.6;
  var _layer = _MapLayer.facilities;
  var _condition = 'dengue_like';
  var _week = 12;
  var _showMyFlags = true;
  var _routeMode = false;
  var _facilityCategory = 'all';
  LatLon? _pointingTarget;
  late final List<LatLng> _dayRoute;

  LatLon get _fix => widget.pack.sampleFix;

  @override
  void initState() {
    super.initState();
    final stops = todaysRoute(_fix, widget.pack.households).stops;
    _dayRoute = [
      for (final point in walkRoute(widget.roads, [
        _fix,
        for (final stop in stops) stop.point,
      ]))
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
    final selectedWalk = selected == null
        ? null
        : walkRoute(widget.roads, [_fix, selected.point]);
    final selectedPath = [
      if (selectedWalk != null)
        for (final point in selectedWalk)
          LatLng(point.latitude, point.longitude),
    ];
    return Scaffold(
      key: const Key('geo_map_screen'),
      backgroundColor: const Color(0xFFF2EFE9),
      bottomNavigationBar: widget.embedded
          ? null
          : const AshaBottomNav(index: 1),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(22.5, 79.0),
                initialZoom: 4.6,
                minZoom: 3,
                maxZoom: 18,
                backgroundColor: const Color(0xFFF2EFE9),
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
                  minZoom: 3,
                  maxZoom: 18,
                  maxNativeZoom: 14,
                ),
                if (_layer != _MapLayer.radar &&
                    widget.stateOutlines.isNotEmpty)
                  PolygonLayer(polygons: _statePolygons()),
                if (_dayRoute.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _dayRoute,
                        strokeWidth: 4,
                        color: const Color(0xFF1D4E89),
                      ),
                    ],
                  ),
                if (selectedPath.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: selectedPath,
                        strokeWidth: 5,
                        color: const Color(0xFFE11D48),
                      ),
                    ],
                  ),
                if (_layer == _MapLayer.households &&
                    _routeMode &&
                    _dayRoute.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _dayRoute,
                        strokeWidth: 5,
                        color: const Color(0xFF2563EB),
                        pattern: const StrokePattern.dotted(),
                      ),
                    ],
                  ),
                if (_layer == _MapLayer.radar)
                  PolygonLayer(polygons: _radarPolygons()),
                MarkerLayer(markers: _markers()),
              ],
            ),
          ),
          _buildFieldMapSheet(),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: _MapControls(
              layer: _layer,
              condition: _condition,
              week: _week,
              showMyFlags: _showMyFlags,
              routeMode: _routeMode,
              facilityCategory: _facilityCategory,
              onLayerChanged: (layer) => setState(() {
                _layer = layer;
                _selected = null;
                _selectedHousehold = null;
                _selectedWard = null;
              }),
              onConditionChanged: (condition) =>
                  setState(() => _condition = condition),
              onWeekChanged: (week) => setState(() => _week = week),
              onMyFlagsChanged: (value) => setState(() => _showMyFlags = value),
              onRouteChanged: (value) => setState(() => _routeMode = value),
              onFacilityCategoryChanged: (category) =>
                  setState(() => _facilityCategory = category),
              onSearch: _searchFacilities,
            ),
          ),
          Positioned(
            left: 12,
            top: widget.embedded ? 116 : 128,
            child: _LocationChip(
              wardId: widget.pack.index.resolve(_fix).wardId ?? 'district',
              label: 'cached location',
            ),
          ),
          if (_pointingTarget != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: _mapSheetReserved,
              child: _directionCard(_pointingTarget!),
            ),
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                _ZoomButton(
                  key: const Key('zoom_in'),
                  icon: Icons.add,
                  onPressed: () => _changeZoom(1),
                ),
                const SizedBox(height: 8),
                _ZoomButton(
                  key: const Key('zoom_out'),
                  icon: Icons.remove,
                  onPressed: () => _changeZoom(-1),
                ),
              ],
            ),
          ),
          if (selected != null ||
              _selectedHousehold != null ||
              _selectedWard != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: _mapSheetReserved,
              child: _selectionCard(selected, selectedWalk),
            ),
        ],
      ),
    );
  }

  Widget _buildFieldMapSheet() {
    final households = widget.pack.households;
    final dueToday = households.where((household) => household.dueToday).length;
    final followUps = households
        .where(
          (household) =>
              household.dues.any((due) => due.toLowerCase().contains('follow')),
        )
        .length;
    final upcoming = households.length - dueToday;
    final route = todaysRoute(_fix, households).stops;

    return DraggableScrollableSheet(
      initialChildSize: 0.24,
      minChildSize: 0.14,
      maxChildSize: 0.62,
      snap: true,
      snapSizes: const [0.14, 0.24, 0.62],
      builder: (context, scrollController) {
        return Material(
          color: Colors.white,
          elevation: 8,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Today on the field',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  Text(
                    '${route.length} route stops',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  _StatusCount(
                    color: const Color(0xFFEF4444),
                    text: '$dueToday Due',
                  ),
                  const SizedBox(width: 12),
                  _StatusCount(
                    color: const Color(0xFFF59E0B),
                    text: '$followUps Follow-up',
                  ),
                  const SizedBox(width: 12),
                  _StatusCount(
                    color: const Color(0xFF16A34A),
                    text: '$upcoming Upcoming',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _SourceChip(
                    icon: Icons.local_hospital_outlined,
                    label: '${widget.pack.facilities.length} facilities',
                  ),
                  _SourceChip(
                    icon: Icons.map_outlined,
                    label: '${widget.stateOutlines.length} states/UTs',
                  ),
                  _SourceChip(
                    icon: Icons.analytics_outlined,
                    label: '${widget.pack.wards.length} radar wards',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final household in households.take(3)) ...[
                _MapHouseholdRow(
                  household: household,
                  onTap: () => _selectHouseholdFromSheet(household),
                ),
                const SizedBox(height: 8),
              ],
              if (households.isEmpty)
                const Text(
                  'No household pins are cached for this area yet.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              const Text(
                'Pan across India to see bundled directory sources. Street detail appears when a regional offline pack is available.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                  height: 1.35,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectHouseholdFromSheet(HouseholdPin household) {
    setState(() {
      _layer = _MapLayer.households;
      _selected = null;
      _selectedWard = null;
      _selectedHousehold = household;
    });
    _mapController.move(
      LatLng(household.latitude, household.longitude),
      math.max(_mapController.camera.zoom, 14),
    );
  }

  void _changeZoom(double delta) {
    final camera = _mapController.camera;
    final next = (camera.zoom + delta).clamp(3.0, 18.0);
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
              decoration: BoxDecoration(
                color: Color(0xFF1D4E89),
                shape: BoxShape.circle,
              ),
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
    if (_layer == _MapLayer.facilities) {
      for (final poi in widget.pack.facilities.where(
        (poi) =>
            _facilityCategory == 'all' || poi.category == _facilityCategory,
      )) {
        final chosen = _selected?.id == poi.id;
        final showLabel = _zoomLevel >= 8 || chosen;
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
                setState(() {
                  _selected = poi;
                  _selectedHousehold = null;
                  _selectedWard = null;
                });
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showLabel) _NameChip(poi.name),
                  Icon(
                    _facilityIcon(poi.category),
                    color: chosen
                        ? const Color(0xFFE11D48)
                        : const Color(0xFF2D5F47),
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    if (_layer == _MapLayer.households) {
      final route = todaysRoute(_fix, widget.pack.households).stops;
      final pins = _routeMode ? route : widget.pack.households;
      for (final household in pins) {
        final routeIndex = route.indexWhere((pin) => pin.id == household.id);
        markers.add(
          Marker(
            key: Key('household-${household.id}'),
            point: LatLng(household.latitude, household.longitude),
            width: 116,
            height: 48,
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: () => setState(() {
                _selected = null;
                _selectedWard = null;
                _selectedHousehold = household;
              }),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_routeMode && routeIndex >= 0)
                    _NameChip('${routeIndex + 1}. ${household.name}'),
                  Icon(
                    Icons.home_rounded,
                    color: _householdColor(household),
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    if (_layer == _MapLayer.radar) {
      for (final ward in widget.pack.wards) {
        final center = wardCentroid(ward);
        final active = outbreakActive(
          widget.pack.counts,
          _week,
          ward.wardId,
          _condition,
        );
        markers.add(
          Marker(
            key: Key('ward-${ward.wardId}'),
            point: LatLng(center.latitude, center.longitude),
            width: 116,
            height: 46,
            child: GestureDetector(
              onTap: () => setState(() {
                _selected = null;
                _selectedHousehold = null;
                _selectedWard = ward;
              }),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NameChip(
                    '${ward.wardId} · ${widget.pack.counts.cases(_week, ward.wardId, _condition)}',
                  ),
                  if (active)
                    _OutbreakMarker(color: _radarColor(RadarLevel.outbreak)),
                ],
              ),
            ),
          ),
        );
      }
      if (_showMyFlags) {
        for (final referral in widget.pack.referrals) {
          markers.add(
            Marker(
              key: Key('referral-${referral.id}'),
              point: LatLng(referral.latitude, referral.longitude),
              width: 30,
              height: 30,
              child: Icon(
                Icons.flag_rounded,
                color: _flagColor(referral.flag),
                size: 24,
              ),
            ),
          );
        }
      }
    }
    return markers;
  }

  List<Polygon<WardPolygon>> _radarPolygons() {
    return [
      for (final ward in widget.pack.wards)
        Polygon<WardPolygon>(
          points: [
            for (final point in ward.ring)
              LatLng(point.latitude, point.longitude),
          ],
          color: _radarColor(
            radarLevel(
              widget.pack.counts.cases(_week, ward.wardId, _condition),
              _condition,
            ),
          ).withValues(alpha: 0.28),
          borderColor: _radarColor(
            radarLevel(
              widget.pack.counts.cases(_week, ward.wardId, _condition),
              _condition,
            ),
          ),
          borderStrokeWidth: 2,
          label: ward.wardId,
          labelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
          hitValue: ward,
        ),
    ];
  }

  List<Polygon> _statePolygons() {
    return [
      for (final state in widget.stateOutlines)
        Polygon(
          points: state.points,
          color: const Color(0x0A16805C),
          borderColor: const Color(0x5516805C),
          borderStrokeWidth: 1,
          label: state.name,
          labelStyle: const TextStyle(
            color: Color(0xFF1E4231),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
    ];
  }

  Widget _selectionCard(FacilityPoi? selected, List<LatLon>? selectedWalk) {
    if (selected != null) {
      return Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    _facilityIcon(selected.category),
                    color: const Color(0xFF1E4231),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selected.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selected = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text('${_categoryLabel(selected.category)} · ${selected.hours}'),
              if (selected.capabilities.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final item in selected.capabilities)
                      Chip(
                        label: Text(item, style: const TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: Key('call-${selected.id}'),
                      onPressed: selected.phone.isEmpty
                          ? null
                          : () => widget.openUri(
                              Uri.parse('tel:${selected.phone}'),
                            ),
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Call'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      key: Key('navigate-${selected.id}'),
                      onPressed: () =>
                          _navigate(selected.latitude, selected.longitude),
                      icon: const Icon(Icons.navigation_outlined),
                      label: Text(
                        '${pathMetres(selectedWalk ?? [selected.point]).round()} m',
                      ),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    setState(() => _pointingTarget = selected.point),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Point me · directional guidance'),
              ),
            ],
          ),
        ),
      );
    }
    final household = _selectedHousehold;
    if (household != null) {
      return _householdCard(household);
    }
    final ward = _selectedWard;
    if (ward != null) {
      final cases = widget.pack.counts.cases(_week, ward.wardId, _condition);
      return Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${ward.wardId} · ${_conditionLabel(_condition)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedWard = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text('$cases cases in week $_week'),
              const SizedBox(height: 8),
              _Sparkline(
                values: widget.pack.counts.series(ward.wardId, _condition),
              ),
              const SizedBox(height: 8),
              if (outbreakChip(
                    widget.pack.counts,
                    _week,
                    ward.wardId,
                    _condition,
                  )
                  case final chip?)
                Text(
                  chip,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => context.push('/triage'),
                icon: const Icon(Icons.fact_check_outlined),
                label: Text('Start assessment in ${ward.wardId}'),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _householdCard(HouseholdPin household) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    household.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _selectedHousehold = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text('${household.ageYears} years · ${household.dues.join(', ')}'),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () =>
                  setState(() => _pointingTarget = household.point),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Point me · directional guidance'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  _navigate(household.latitude, household.longitude),
              icon: const Icon(Icons.navigation_outlined),
              label: const Text('Navigate'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _searchFacilities() async {
    var query = '';
    final selected = await showDialog<FacilityPoi>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final results = widget.pack.facilities.where((poi) {
            final matchesCategory =
                _facilityCategory == 'all' || poi.category == _facilityCategory;
            return matchesCategory &&
                poi.name.toLowerCase().contains(query.toLowerCase());
          }).toList();
          return AlertDialog(
            title: const Text('Search government facilities'),
            content: SizedBox(
              width: 420,
              height: 360,
              child: Column(
                children: [
                  TextField(
                    onChanged: (value) => setDialogState(() => query = value),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by facility name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final poi in results)
                          ListTile(
                            leading: Icon(_facilityIcon(poi.category)),
                            title: Text(poi.name),
                            subtitle: Text(_categoryLabel(poi.category)),
                            onTap: () => Navigator.pop(dialogContext, poi),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      _layer = _MapLayer.facilities;
      _selected = selected;
      _selectedHousehold = null;
      _selectedWard = null;
    });
  }

  Future<void> _navigate(double latitude, double longitude) async {
    for (final uri in NavigationTargets.forPoint(latitude, longitude).chain) {
      if (await widget.openUri(uri)) return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No offline navigation app is available.'),
        ),
      );
    }
  }

  Widget _directionCard(LatLon target) {
    final bearing = bearingDegrees(_fix, target);
    final metres = haversineMetres(_fix, target);
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Transform.rotate(
              angle: bearing * math.pi / 180,
              child: const Icon(
                Icons.navigation_rounded,
                color: Color(0xFF2563EB),
                size: 34,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Point ${bearingLabel(bearing)} · ${metres.round()} m\nDirectional guidance — roads may differ.',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _pointingTarget = null),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }

  IconData _facilityIcon(String category) => switch (category) {
    'phc' ||
    'sub_centre' ||
    'chc' ||
    'hospital' => Icons.local_hospital_outlined,
    'lab' => Icons.science_outlined,
    'blood_bank' => Icons.bloodtype_outlined,
    'janaushadhi' || 'dispensary' => Icons.medication_outlined,
    'anganwadi' => Icons.groups_outlined,
    'police' => Icons.local_police_outlined,
    'ration_shop' => Icons.shopping_basket_outlined,
    _ => Icons.account_balance_outlined,
  };

  String _categoryLabel(String category) => category
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');

  Color _householdColor(HouseholdPin household) =>
      household.dues.any((due) => due.toLowerCase().contains('overdue'))
      ? const Color(0xFFB42318)
      : household.dueToday
      ? const Color(0xFFD97706)
      : const Color(0xFF15803D);

  Color _flagColor(String flag) => switch (flag.toLowerCase()) {
    'red' => const Color(0xFFB42318),
    'yellow' => const Color(0xFFD97706),
    _ => const Color(0xFF15803D),
  };

  Color _radarColor(RadarLevel level) => switch (level) {
    RadarLevel.outbreak => const Color(0xFFB42318),
    RadarLevel.raised => const Color(0xFFD97706),
    RadarLevel.quiet => const Color(0xFF64748B),
  };

  String _conditionLabel(String condition) => switch (condition) {
    'dengue_like' => 'Dengue-like',
    'acute_diarrhoea' => 'Acute diarrhoea',
    'measles_like' => 'Measles-like',
    'aes' => 'AES',
    _ => 'Fever',
  };
}

enum _MapLayer { facilities, radar, households }

class _MapControls extends StatelessWidget {
  const _MapControls({
    required this.layer,
    required this.condition,
    required this.week,
    required this.showMyFlags,
    required this.routeMode,
    required this.facilityCategory,
    required this.onLayerChanged,
    required this.onConditionChanged,
    required this.onWeekChanged,
    required this.onMyFlagsChanged,
    required this.onRouteChanged,
    required this.onFacilityCategoryChanged,
    required this.onSearch,
  });

  final _MapLayer layer;
  final String condition;
  final int week;
  final bool showMyFlags;
  final bool routeMode;
  final String facilityCategory;
  final ValueChanged<_MapLayer> onLayerChanged;
  final ValueChanged<String> onConditionChanged;
  final ValueChanged<int> onWeekChanged;
  final ValueChanged<bool> onMyFlagsChanged;
  final ValueChanged<bool> onRouteChanged;
  final ValueChanged<String> onFacilityCategoryChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      elevation: 3,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _layerChip(
                    _MapLayer.facilities,
                    Icons.local_hospital_outlined,
                    'Facilities',
                  ),
                  _layerChip(
                    _MapLayer.radar,
                    Icons.track_changes_outlined,
                    'Disease radar',
                  ),
                  _layerChip(
                    _MapLayer.households,
                    Icons.home_work_outlined,
                    'Households',
                  ),
                  IconButton(
                    key: const Key('facility_search_button'),
                    tooltip: 'Search facilities',
                    onPressed: onSearch,
                    icon: const Icon(Icons.search_rounded),
                  ),
                ],
              ),
            ),
            if (layer == _MapLayer.facilities)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final category in const [
                      'all',
                      'phc',
                      'chc',
                      'hospital',
                      'lab',
                      'anganwadi',
                      'police',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            category == 'all'
                                ? 'All'
                                : category.replaceAll('_', ' '),
                          ),
                          selected: facilityCategory == category,
                          onSelected: (_) =>
                              onFacilityCategoryChanged(category),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
            if (layer == _MapLayer.radar)
              Row(
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: condition,
                      isDense: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'dengue_like',
                          child: Text('Dengue-like'),
                        ),
                        DropdownMenuItem(
                          value: 'acute_diarrhoea',
                          child: Text('Diarrhoea'),
                        ),
                        DropdownMenuItem(
                          value: 'measles_like',
                          child: Text('Measles-like'),
                        ),
                        DropdownMenuItem(value: 'aes', child: Text('AES')),
                        DropdownMenuItem(value: 'fever', child: Text('Fever')),
                      ],
                      onChanged: (value) {
                        if (value != null) onConditionChanged(value);
                      },
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Previous cached week',
                    onPressed: week <= 1 ? null : () => onWeekChanged(week - 1),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text(
                    'Week $week / 12',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  IconButton(
                    tooltip: 'Next cached week',
                    onPressed: week >= 12
                        ? null
                        : () => onWeekChanged(week + 1),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                  Switch.adaptive(
                    value: showMyFlags,
                    onChanged: onMyFlagsChanged,
                  ),
                  const Text('My flags', style: TextStyle(fontSize: 11)),
                ],
              ),
            if (layer == _MapLayer.households)
              Row(
                children: [
                  const Icon(
                    Icons.route_outlined,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Today\'s route',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Switch.adaptive(value: routeMode, onChanged: onRouteChanged),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _layerChip(_MapLayer value, IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        avatar: Icon(icon, size: 16),
        label: Text(label),
        selected: layer == value,
        onSelected: (_) => onLayerChanged(value),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.wardId, required this.label});

  final String wardId;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 5)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 15,
              color: Color(0xFF2563EB),
            ),
            const SizedBox(width: 4),
            Text(
              '$label · $wardId',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCount extends StatelessWidget {
  const _StatusCount({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF1E4231)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapHouseholdRow extends StatelessWidget {
  const _MapHouseholdRow({required this.household, required this.onTap});

  final HouseholdPin household;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = household.dueToday
        ? const Color(0xFFEF4444)
        : const Color(0xFF16A34A);
    final initials = household.name
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      household.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      household.dues.join(' · '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutbreakMarker extends StatelessWidget {
  const _OutbreakMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.78, end: 1.18),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeInOut,
      onEnd: () {},
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: Container(
          width: 25,
          height: 25,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<int>(1, math.max);
    return SizedBox(
      height: 42,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final value in values)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: FractionallySizedBox(
                  heightFactor: value == 0 ? 0.06 : value / maxValue,
                  alignment: Alignment.bottomCenter,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: value == maxValue
                          ? const Color(0xFFB42318)
                          : const Color(0xFF94A3B8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF1C1C1C),
            fontWeight: FontWeight.w600,
          ),
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
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: const Color(0xFF1E4231)),
        ),
      ),
    );
  }
}
