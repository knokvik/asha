import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geo_intel/geo_intel.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
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
    this.useOsmBasemap = true,
    this.openUri = openExternalUri,
  });

  final bool embedded;
  final bool useOsmBasemap;
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
      TileProvider? tiles;
      if (widget.useOsmBasemap) {
        tiles = MemoryTileProvider(MbTilesTileProvider.blank);
      } else {
        final bytes = await rootBundle.load('assets/geo/pcmc.mbtiles');
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/pcmc.mbtiles');
        await file.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          flush: true,
        );
        final database = sql.sqlite3.open(
          file.path,
          mode: sql.OpenMode.readOnly,
        );
        tiles = MbTilesTileProvider(database);
      }
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
        _tiles = tiles;
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
      useOsmBasemap: widget.useOsmBasemap,
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
    this.useOsmBasemap = false,
    this.embedded = false,
    this.openUri = openExternalUri,
  });

  final GeoPack pack;
  final TileProvider tiles;
  final RoadGraph? roads;
  final List<MapLabel> labels;
  final List<MapStateShape> stateOutlines;
  final bool useOsmBasemap;
  final bool embedded;
  final UriOpener openUri;

  @override
  State<GeoMapScreen> createState() => _GeoMapScreenState();
}

class _GeoMapScreenState extends State<GeoMapScreen> {
  double get _mapSheetReserved => _layer == _MapLayer.facilities ? 76.0 : 180.0;
  final _mapController = MapController();
  FacilityPoi? _selected;
  HouseholdPin? _selectedHousehold;
  WardPolygon? _selectedWard;
  var _ateMarkerTap = false;
  late double _zoomLevel;
  var _layer = _MapLayer.facilities;
  var _condition = 'dengue_like';
  var _week = 12;
  static const _showMyFlags = true;
  var _routeMode = false;
  var _showLiveLocation = false;
  var _satelliteView = false;
  static const _householdScope = _HouseholdScope.due;
  var _facilityCategory = 'all';
  LatLon? _pointingTarget;
  late final List<LatLng> _dayRoute;
  static const _secureStorage = FlutterSecureStorage();

  LatLon get _fix => widget.pack.sampleFix;

  LatLng get _initialCenter => widget.stateOutlines.isNotEmpty
      ? const LatLng(22.5, 79.0)
      : LatLng(_fix.latitude, _fix.longitude);

  double get _initialZoom => widget.stateOutlines.isNotEmpty ? 4.6 : 14.0;

  @override
  void initState() {
    super.initState();
    _zoomLevel = _initialZoom;
    _loadBasemapPreference();
    final stops = todaysRoute(_fix, widget.pack.households).stops;
    _dayRoute = [
      for (final point in walkRoute(widget.roads, [
        _fix,
        for (final stop in stops) stop.point,
      ]))
        LatLng(point.latitude, point.longitude),
    ];
  }

  Future<void> _loadBasemapPreference() async {
    try {
      final style = await _secureStorage.read(key: 'map_view_style');
      if (style == 'satellite' && mounted) {
        setState(() => _satelliteView = true);
      }
    } catch (_) {}
  }

  void _toggleSatellite() {
    setState(() => _satelliteView = !_satelliteView);
    _secureStorage.write(
      key: 'map_view_style',
      value: _satelliteView ? 'satellite' : 'street',
    );
  }

  void _locateMeLive() {
    setState(() => _showLiveLocation = true);
    _mapController.move(
      LatLng(_fix.latitude, _fix.longitude),
      math.max(_mapController.camera.zoom, 14.5),
    );
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
      backgroundColor: _satelliteView
          ? const Color(0xFF0F172A)
          : const Color(0xFFF2EFE9),
      bottomNavigationBar: widget.embedded
          ? null
          : const AshaBottomNav(index: 1),
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: _initialZoom,
                minZoom: 3,
                maxZoom: 19,
                backgroundColor: _satelliteView
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF2EFE9),
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
                  if (_selected != null ||
                      _selectedHousehold != null ||
                      _selectedWard != null) {
                    setState(() {
                      _selected = null;
                      _selectedHousehold = null;
                      _selectedWard = null;
                    });
                  }
                },
              ),
              children: [
                if (_satelliteView)
                  TileLayer(
                    urlTemplate:
                        'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'org.mohfw.asha_platform',
                    minZoom: 3,
                    maxZoom: 19,
                    tileDisplay: const TileDisplay.instantaneous(),
                  )
                else if (widget.useOsmBasemap)
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'org.mohfw.asha_platform',
                    minZoom: 3,
                    maxZoom: 19,
                  )
                else
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
                if ((_showLiveLocation || _routeMode) && _dayRoute.length > 1)
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
                if (_layer == _MapLayer.radar)
                  CircleLayer(circles: _radarCircles()),
                if (_showLiveLocation)
                  CircleLayer(circles: _liveLocationCircles()),
                MarkerLayer(markers: _markers()),
                if (widget.useOsmBasemap && !_satelliteView)
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  )
                else if (_satelliteView)
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('Esri, Maxar, Earthstar Geographics'),
                    ],
                  ),
              ],
            ),
          ),

          // Minimal Floating Location / Area Pill (Top-Left)
          Positioned(
            left: 14,
            top: widget.embedded ? 14 : 22,
            child: _LocationStatusPill(
              wardId: widget.pack.index.resolve(_fix).wardId ?? 'catchment',
              isLive: _showLiveLocation,
              isSatellite: _satelliteView,
              activeCategory: _facilityCategory,
              layer: _layer,
              onTap: _locateMeLive,
            ),
          ),

          // Right-Side Control Stack: Satellite Toggle, Locate Me Live, Zoom In, Zoom Out
          Positioned(
            right: 14,
            top: widget.embedded ? 14 : 22,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MapActionButton(
                  tooltip: _satelliteView
                      ? 'Switch to Street Map'
                      : 'Switch to Satellite Aerial',
                  icon: _satelliteView
                      ? Icons.map_rounded
                      : Icons.satellite_alt_rounded,
                  color: _satelliteView
                      ? const Color(0xFF10B981)
                      : const Color(0xFF1E293B),
                  onPressed: _toggleSatellite,
                ),
                const SizedBox(height: 8),
                _MapActionButton(
                  tooltip: _showLiveLocation
                      ? 'Locating active'
                      : 'Locate ourselves live',
                  icon: _showLiveLocation
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                  color: _showLiveLocation
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF475569),
                  onPressed: _locateMeLive,
                ),
                const SizedBox(height: 8),
                _ZoomButton(
                  key: const Key('zoom_in'),
                  icon: Icons.add_rounded,
                  onPressed: () => _changeZoom(1),
                ),
                const SizedBox(height: 8),
                _ZoomButton(
                  key: const Key('zoom_out'),
                  icon: Icons.remove_rounded,
                  onPressed: () => _changeZoom(-1),
                ),
              ],
            ),
          ),

          if (_pointingTarget != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: _mapSheetReserved,
              child: _directionCard(_pointingTarget!),
            ),

          if (selected != null ||
              _selectedHousehold != null ||
              _selectedWard != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: _mapSheetReserved,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: SingleChildScrollView(
                  child: _selectionCard(selected, selectedWalk),
                ),
              ),
            ),

          // Bottom Filter & Controls Dock
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _buildBottomControlBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControlBar() {
    return Material(
      color: _satelliteView
          ? const Color(0xFF1E293B).withValues(alpha: 0.95)
          : Colors.white.withValues(alpha: 0.95),
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BottomMapFilterBar(
              layer: _layer,
              category: _facilityCategory,
              onSelectFilter: (layer, category) {
                setState(() {
                  _layer = layer;
                  _facilityCategory = category;
                  _selected = null;
                  _selectedHousehold = null;
                  _selectedWard = null;
                  if (layer == _MapLayer.households) {
                    _routeMode = true;
                  }
                });
              },
            ),
            if (_layer == _MapLayer.radar) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Condition: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _satelliteView
                          ? Colors.grey.shade300
                          : const Color(0xFF374151),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _condition,
                      isDense: true,
                      dropdownColor: _satelliteView
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _satelliteView
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
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
                        if (value != null) setState(() => _condition = value);
                      },
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Previous cached week',
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed:
                        _week <= 1 ? null : () => setState(() => _week--),
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: _satelliteView ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Week $_week / 12',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: _satelliteView
                          ? Colors.white
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Next cached week',
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed:
                        _week >= 12 ? null : () => setState(() => _week++),
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: _satelliteView ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
            if (_layer == _MapLayer.households) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.route_outlined,
                    size: 18,
                    color: Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Today's route",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _satelliteView
                            ? Colors.white
                            : const Color(0xFF111827),
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch.adaptive(
                      value: _routeMode,
                      onChanged: (val) => setState(() => _routeMode = val),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _changeZoom(double delta) {
    final camera = _mapController.camera;
    final next = (camera.zoom + delta).clamp(3.0, 18.0);
    _mapController.move(camera.center, next);
    setState(() => _zoomLevel = next);
  }

  List<Marker> _markers() {
    final markers = <Marker>[];
    if (_showLiveLocation) {
      markers.add(
        Marker(
          key: const Key('asha_live_location'),
          point: LatLng(_fix.latitude, _fix.longitude),
          width: 76,
          height: 58,
          alignment: Alignment.center,
          child: const _LiveLocationMarker(),
        ),
      );
    }
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
      final facilities = widget.pack.facilities
          .where(
            (poi) =>
                _facilityCategory == 'all' || poi.category == _facilityCategory,
          )
          .toList();
      if (facilities.length > 40 && _zoomLevel < 7) {
        return [...markers, ..._facilityClusterMarkers(facilities)];
      }
      for (final poi in facilities) {
        final chosen = _selected?.id == poi.id;
        final showLabel = _zoomLevel >= 8 || chosen || facilities.length <= 40;
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
                        : _facilityColor(poi.category),
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
      final scoped = widget.pack.households.where(
        (household) => _householdScope == _HouseholdScope.due
            ? household.dueToday
            : !household.dueToday,
      );
      final pins = _routeMode ? route : scoped.toList();
      if (_zoomLevel < 8) {
        return [...markers, ..._householdClusterMarkers(pins)];
      }
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

  List<CircleMarker> _liveLocationCircles() {
    final point = LatLng(_fix.latitude, _fix.longitude);
    return [
      CircleMarker(
        point: point,
        radius: 650,
        useRadiusInMeter: true,
        color: const Color(0x142563EB),
        borderColor: const Color(0x552563EB),
        borderStrokeWidth: 1.5,
      ),
      CircleMarker(
        point: point,
        radius: 90,
        useRadiusInMeter: true,
        color: const Color(0x223B82F6),
        borderColor: const Color(0x993B82F6),
        borderStrokeWidth: 2,
      ),
    ];
  }

  List<Marker> _householdClusterMarkers(List<HouseholdPin> pins) {
    final clusters = <String, List<HouseholdPin>>{};
    for (final household in pins) {
      final key =
          '${(household.latitude * 2).floor()}:${(household.longitude * 2).floor()}';
      clusters.putIfAbsent(key, () => []).add(household);
    }
    return [
      for (final group in clusters.values)
        Marker(
          key: Key('household-cluster-${group.first.id}'),
          point: LatLng(
            group.map((item) => item.latitude).reduce((a, b) => a + b) /
                group.length,
            group.map((item) => item.longitude).reduce((a, b) => a + b) /
                group.length,
          ),
          width: 50,
          height: 50,
          child: _ClusterMarker(
            count: group.length,
            color: const Color(0xFF2563EB),
            onTap: () => _mapController.move(
              LatLng(
                group.map((item) => item.latitude).reduce((a, b) => a + b) /
                    group.length,
                group.map((item) => item.longitude).reduce((a, b) => a + b) /
                    group.length,
              ),
              math.min(_zoomLevel + 2, 14),
            ),
          ),
        ),
    ];
  }

  List<Marker> _facilityClusterMarkers(List<FacilityPoi> facilities) {
    final clusters = <String, List<FacilityPoi>>{};
    for (final facility in facilities) {
      final key =
          '${(facility.latitude * 2).floor()}:${(facility.longitude * 2).floor()}';
      clusters.putIfAbsent(key, () => []).add(facility);
    }
    return [
      for (final group in clusters.values)
        Marker(
          key: Key('facility-cluster-${group.first.id}'),
          point: LatLng(
            group.map((item) => item.latitude).reduce((a, b) => a + b) /
                group.length,
            group.map((item) => item.longitude).reduce((a, b) => a + b) /
                group.length,
          ),
          width: 50,
          height: 50,
          child: _ClusterMarker(
            count: group.length,
            color: const Color(0xFF1E4231),
            onTap: () => _mapController.move(
              LatLng(
                group.map((item) => item.latitude).reduce((a, b) => a + b) /
                    group.length,
                group.map((item) => item.longitude).reduce((a, b) => a + b) /
                    group.length,
              ),
              math.min(_zoomLevel + 2, 12),
            ),
          ),
        ),
    ];
  }

  List<CircleMarker> _radarCircles() {
    final circles = <CircleMarker>[];
    for (final ward in widget.pack.wards) {
      if (outbreakActive(widget.pack.counts, _week, ward.wardId, _condition)) {
        final center = wardCentroid(ward);
        final pt = LatLng(center.latitude, center.longitude);
        // Outer buffer ring
        circles.add(
          CircleMarker(
            point: pt,
            radius: 1500,
            useRadiusInMeter: true,
            color: const Color(0xFFDC2626).withValues(alpha: 0.12),
            borderColor: const Color(0xFFDC2626).withValues(alpha: 0.35),
            borderStrokeWidth: 1.5,
          ),
        );
        // Inner core hotspot
        circles.add(
          CircleMarker(
            point: pt,
            radius: 650,
            useRadiusInMeter: true,
            color: const Color(0xFFDC2626).withValues(alpha: 0.28),
            borderColor: const Color(0xFFDC2626),
            borderStrokeWidth: 2,
          ),
        );
      }
    }
    if (_condition == 'dengue_like' && _zoomLevel < 10) {
      final hotspots = [
        const LatLng(25.325, 82.980), // Varanasi / Rampur
        const LatLng(28.567, 77.210), // Delhi
        const LatLng(19.043, 72.855), // Mumbai
        const LatLng(12.978, 77.641), // Bengaluru
      ];
      for (final spot in hotspots) {
        circles.add(
          CircleMarker(
            point: spot,
            radius: 25000,
            useRadiusInMeter: true,
            color: const Color(0xFFEA580C).withValues(alpha: 0.16),
            borderColor: const Color(0xFFEA580C).withValues(alpha: 0.6),
            borderStrokeWidth: 1.5,
          ),
        );
      }
    }
    return circles;
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
    'phc' => Icons.local_hospital_rounded,
    'chc' => Icons.apartment_rounded,
    'blood_bank' => Icons.bloodtype_rounded,
    'hospital' => Icons.local_hospital_outlined,
    'sub_centre' => Icons.health_and_safety_outlined,
    'lab' => Icons.science_outlined,
    'janaushadhi' || 'dispensary' => Icons.medication_outlined,
    'anganwadi' => Icons.groups_outlined,
    'police' => Icons.local_police_outlined,
    'ration_shop' => Icons.shopping_basket_outlined,
    _ => Icons.account_balance_outlined,
  };

  Color _facilityColor(String category) => switch (category) {
    'phc' => const Color(0xFF16A34A),
    'chc' => const Color(0xFF2563EB),
    'blood_bank' => const Color(0xFFDC2626),
    'hospital' => const Color(0xFF7C3AED),
    'lab' => const Color(0xFF0D9488),
    'anganwadi' => const Color(0xFFEA580C),
    'sub_centre' => const Color(0xFF059669),
    _ => const Color(0xFF1E4231),
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

enum _HouseholdScope { due }


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

class _LiveLocationMarker extends StatelessWidget {
  const _LiveLocationMarker();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: 1.12),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      onEnd: () {},
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _NameChip('You · live'),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0x663B82F6), blurRadius: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClusterMarker extends StatelessWidget {
  const _ClusterMarker({
    required this.count,
    required this.color,
    required this.onTap,
  });

  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 5)],
        ),
        child: Center(
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
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

class _LocationStatusPill extends StatelessWidget {
  const _LocationStatusPill({
    required this.wardId,
    required this.isLive,
    required this.isSatellite,
    required this.activeCategory,
    required this.layer,
    required this.onTap,
  });

  final String wardId;
  final bool isLive;
  final bool isSatellite;
  final String activeCategory;
  final _MapLayer layer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusText = isLive ? 'Live GPS' : 'Catchment · $wardId';
    final layerText = switch (layer) {
      _MapLayer.facilities => activeCategory == 'all'
          ? 'Facilities'
          : activeCategory.toUpperCase(),
      _MapLayer.radar => 'Disease radar',
      _MapLayer.households => 'Households',
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSatellite
              ? const Color(0xFF1E293B).withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: isSatellite
                ? const Color(0xFF334155)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isLive
                    ? const Color(0xFF10B981)
                    : const Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$statusText · $layerText',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSatellite ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  const _MapActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        elevation: 3,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}

class _BottomMapFilterBar extends StatelessWidget {
  const _BottomMapFilterBar({
    required this.layer,
    required this.category,
    required this.onSelectFilter,
  });

  final _MapLayer layer;
  final String category;
  final void Function(_MapLayer layer, String category) onSelectFilter;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FilterPill(
              label: 'Facilities',
              icon: Icons.local_hospital_outlined,
              activeColor: const Color(0xFF1E4231),
              selected: layer == _MapLayer.facilities && category == 'all',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'all'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: 'PHC',
              icon: Icons.local_hospital_rounded,
              activeColor: const Color(0xFF16A34A),
              selected: layer == _MapLayer.facilities && category == 'phc',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'phc'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: 'CHC',
              icon: Icons.apartment_rounded,
              activeColor: const Color(0xFF2563EB),
              selected: layer == _MapLayer.facilities && category == 'chc',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'chc'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: 'Blood Bank',
              icon: Icons.bloodtype_rounded,
              activeColor: const Color(0xFFDC2626),
              selected: layer == _MapLayer.facilities && category == 'blood_bank',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'blood_bank'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: 'Disease radar',
              icon: Icons.radar_rounded,
              activeColor: const Color(0xFFEA580C),
              selected: layer == _MapLayer.radar,
              onTap: () => onSelectFilter(_MapLayer.radar, 'all'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: 'Households',
              icon: Icons.home_rounded,
              activeColor: const Color(0xFF4F46E5),
              selected: layer == _MapLayer.households,
              onTap: () => onSelectFilter(_MapLayer.households, 'all'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color activeColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? activeColor : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? activeColor : const Color(0xFFE5E7EB),
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : const Color(0xFF4B5563),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
