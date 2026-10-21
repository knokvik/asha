import 'dart:async';
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
import 'package:permission_handler/permission_handler.dart';
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

class SharedHotspot {
  const SharedHotspot({
    required this.condition,
    required this.cases,
    required this.workerCount,
    required this.latitude,
    required this.longitude,
  });

  final String condition;
  final int cases;
  final int workerCount;
  final double latitude;
  final double longitude;
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
  List<SharedHotspot> _sharedHotspots = const [];
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
      final sharedHotspots = await _readSharedHotspots();
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
        _sharedHotspots = sharedHotspots;
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
      sharedHotspots: _sharedHotspots,
      useOsmBasemap: widget.useOsmBasemap,
      embedded: widget.embedded,
      openUri: widget.openUri,
    );
  }

  Future<List<SharedHotspot>> _readSharedHotspots() async {
    try {
      const storage = FlutterSecureStorage();
      final raw = await storage.read(key: 'triage_hotspot_context_json');
      final decoded = raw == null ? null : jsonDecode(raw);
      final hotspots = decoded is Map ? decoded['hotspots'] : null;
      if (hotspots is! List) return const [];
      return [
        for (final item in hotspots)
          if (item is Map &&
              item['active'] == true &&
              item['latitude'] is num &&
              item['longitude'] is num)
            SharedHotspot(
              condition: '${item['condition'] ?? 'Area signal'}',
              cases: (item['cases'] as num?)?.toInt() ?? 0,
              workerCount: (item['worker_count'] as num?)?.toInt() ?? 0,
              latitude: (item['latitude'] as num).toDouble(),
              longitude: (item['longitude'] as num).toDouble(),
            ),
      ];
    } catch (_) {
      return const [];
    }
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
    this.sharedHotspots = const [],
  });

  final GeoPack pack;
  final TileProvider tiles;
  final RoadGraph? roads;
  final List<MapLabel> labels;
  final List<MapStateShape> stateOutlines;
  final bool useOsmBasemap;
  final bool embedded;
  final UriOpener openUri;
  final List<SharedHotspot> sharedHotspots;

  @override
  State<GeoMapScreen> createState() => _GeoMapScreenState();
}

class _GeoMapScreenState extends State<GeoMapScreen> {
  double get _mapSheetReserved {
    if (_layer == _MapLayer.facilities) return 74.0;
    if (_layer == _MapLayer.households) return 112.0;
    return 180.0;
  }

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
  var _isLocating = false;
  var _satelliteView = false;
  static const _householdScope = _HouseholdScope.due;
  var _facilityCategory = 'all';
  LatLon? _pointingTarget;
  LatLng? _liveLocation;
  double _liveAccuracy = 10.0;
  String _liveProvider = 'gps';
  Timer? _liveLocationTimer;
  List<LatLng> _dayRoute = const [];
  static const _secureStorage = FlutterSecureStorage();
  static const _locationChannel = MethodChannel('asha_platform/location');

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
    _rebuildDayRoute();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _locateMeLive();
    });
  }

  LatLon get _effectiveFix => _liveLocation == null
      ? _fix
      : LatLon(_liveLocation!.latitude, _liveLocation!.longitude);

  void _rebuildDayRoute() {
    final stops = todaysRoute(_effectiveFix, widget.pack.households).stops;
    _dayRoute = [
      for (final point in walkRoute(widget.roads, [
        _effectiveFix,
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

  Future<void> _locateMeLive() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);

    try {
      var permission = await Permission.locationWhenInUse.status;
      if (permission.isDenied || permission.isRestricted) {
        permission = await Permission.locationWhenInUse.request();
      }
      if (!permission.isGranted) {
        _locationUnavailable(
          permission.isPermanentlyDenied
              ? 'Location permission is off. Enable it in phone settings to use live location.'
              : 'Location permission is required to show your current location.',
        );
        return;
      }

      final raw = await _locationChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getCurrentLocation',
      );
      final latitude = (raw?['latitude'] as num?)?.toDouble();
      final longitude = (raw?['longitude'] as num?)?.toDouble();
      final accuracy = (raw?['accuracy'] as num?)?.toDouble() ?? 10.0;
      final provider = (raw?['provider'] as String?) ?? 'gps';
      if (latitude == null ||
          longitude == null ||
          latitude < -90 ||
          latitude > 90 ||
          longitude < -180 ||
          longitude > 180) {
        _locationUnavailable(
          'GPS is not on or no current location is available. Turn on location and try again.',
        );
        return;
      }

      final location = LatLng(latitude, longitude);
      if (!mounted) return;
      setState(() {
        _liveLocation = location;
        _liveAccuracy = accuracy;
        _liveProvider = provider;
        _showLiveLocation = true;
        _isLocating = false;
        _rebuildDayRoute();
      });
      _startLiveLocationTracking();
      _mapController.move(location, math.max(_mapController.camera.zoom, 17.0));
    } on PlatformException catch (error) {
      _locationUnavailable(
        error.code == 'PERMISSION_DENIED'
            ? 'Location permission is required to show your current location.'
            : 'GPS is not on or no current location is available. Turn on location and try again.',
      );
    } on MissingPluginException {
      _locationUnavailable(
        'Live location is not available on this device build. Please use a current Android build.',
      );
    } catch (_) {
      _locationUnavailable(
        'GPS is not on or no current location is available. Try again in an open area.',
      );
    }
  }

  void _startLiveLocationTracking() {
    _liveLocationTimer?.cancel();
    _liveLocationTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshLiveLocation(),
    );
  }

  Future<void> _refreshLiveLocation() async {
    if (!mounted || _liveLocation == null) return;
    try {
      final raw = await _locationChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getCurrentLocation',
      );
      final latitude = (raw?['latitude'] as num?)?.toDouble();
      final longitude = (raw?['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) return;
      final next = LatLng(latitude, longitude);
      if (!mounted) return;
      setState(() {
        _liveLocation = next;
        _liveAccuracy = (raw?['accuracy'] as num?)?.toDouble() ?? _liveAccuracy;
        _liveProvider = (raw?['provider'] as String?) ?? _liveProvider;
        _rebuildDayRoute();
      });
    } catch (_) {
      // Keep the last trusted fix visible when a subsequent GPS read fails.
    }
  }

  void _locationUnavailable(String message) {
    if (!mounted) return;
    setState(() {
      _isLocating = false;
      _showLiveLocation = false;
      _liveLocation = null;
    });
    _liveLocationTimer?.cancel();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _liveLocationTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final selectedWalk = selected == null
        ? null
        : walkRoute(widget.roads, [_effectiveFix, selected.point]);
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
                initialCenter: _initialCenter,
                initialZoom: _initialZoom,
                minZoom: 3,
                maxZoom: 19,
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
                    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
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
                if (_routeMode && _dayRoute.length > 1)
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
                      TextSourceAttribution(
                        'Esri, Maxar, Earthstar Geographics',
                      ),
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
              wardId:
                  widget.pack.index.resolve(_effectiveFix).wardId ??
                  'catchment',
              isLive: _showLiveLocation,
              isSatellite: _satelliteView,
              activeCategory: _facilityCategory,
              layer: _layer,
              onTap: _locateMeLive,
              liveCoordinates: _liveLocation,
              liveAccuracy: _liveAccuracy,
              liveProvider: _liveProvider,
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
                  color: const Color(0xFF10B981),
                  onPressed: _toggleSatellite,
                ),
                const SizedBox(height: 8),
                _MapActionButton(
                  tooltip: _showLiveLocation
                      ? 'Locating active'
                      : 'Locate ourselves live',
                  icon: _showLiveLocation
                      ? Icons.my_location_rounded
                      : (_isLocating
                            ? Icons.gps_fixed_rounded
                            : Icons.location_searching_rounded),
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

          if (_pointingTarget != null &&
              selected == null &&
              _selectedHousehold == null)
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
      color: Colors.white.withValues(alpha: 0.98),
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF374151),
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _condition,
                      isDense: true,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
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
                    onPressed: _week <= 1
                        ? null
                        : () => setState(() => _week--),
                    icon: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Week $_week / 12',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Next cached week',
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: _week >= 12
                        ? null
                        : () => setState(() => _week++),
                    icon: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.black87,
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
    if (_showLiveLocation && _liveLocation != null) {
      markers.add(
        Marker(
          key: const Key('asha_live_location'),
          point: _liveLocation!,
          width: 80,
          height: 80,
          alignment: Alignment.center,
          child: _LiveLocationMarker(accuracy: _liveAccuracy),
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

      if (facilities.length > 50 && _zoomLevel < 7) {
        return [
          ...markers,
          ..._stateHubMarkers(),
          ..._topHospitalMarkers(facilities),
        ];
      }

      final List<FacilityPoi> visiblePool;
      if (facilities.length > 60) {
        final bounds = _mapController.camera.visibleBounds;
        final south = bounds.south - 0.2;
        final north = bounds.north + 0.2;
        final west = bounds.west - 0.2;
        final east = bounds.east + 0.2;

        visiblePool = facilities.where((poi) {
          return poi.latitude >= south &&
              poi.latitude <= north &&
              poi.longitude >= west &&
              poi.longitude <= east;
        }).toList();

        if (_selected != null &&
            !visiblePool.any((p) => p.id == _selected!.id)) {
          visiblePool.add(_selected!);
        }

        visiblePool.sort((a, b) {
          int rank(String cat) => switch (cat) {
            'hospital' => 3,
            'blood_bank' => 2,
            'chc' => 1,
            _ => 0,
          };
          return rank(a.category).compareTo(rank(b.category));
        });
      } else {
        visiblePool = facilities;
      }

      for (final poi in visiblePool) {
        final chosen = _selected?.id == poi.id;
        final showLabel =
            _zoomLevel >= 12 || chosen || visiblePool.length <= 40;
        markers.add(
          Marker(
            key: Key('poi-${poi.id}'),
            point: LatLng(poi.latitude, poi.longitude),
            width: chosen ? 136 : 116,
            height: chosen ? 68 : 52,
            alignment: Alignment.topCenter,
            child: _ModernPinMarker(
              poi: poi,
              category: poi.category,
              chosen: chosen,
              showLabel: showLabel,
              onTap: () {
                _ateMarkerTap = true;
                setState(() {
                  _selected = poi;
                  _selectedHousehold = null;
                  _selectedWard = null;
                  _pointingTarget = null;
                });
              },
            ),
          ),
        );
      }
    }
    if (_layer == _MapLayer.households) {
      final route = todaysRoute(_effectiveFix, widget.pack.households).stops;
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
                  _HouseholdMarker(color: _householdColor(household)),
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
        if (!active) continue;
        markers.add(
          Marker(
            key: Key('ward-${ward.wardId}'),
            point: LatLng(center.latitude, center.longitude),
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => setState(() {
                _selected = null;
                _selectedHousehold = null;
                _selectedWard = ward;
              }),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _OutbreakMarker(color: _radarColor(RadarLevel.outbreak)),
                ],
              ),
            ),
          ),
        );
      }
      for (final hotspot in widget.sharedHotspots) {
        markers.add(
          Marker(
            key: Key('shared-hotspot-${hotspot.latitude}-${hotspot.longitude}'),
            point: LatLng(hotspot.latitude, hotspot.longitude),
            width: 46,
            height: 46,
            child: GestureDetector(
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${hotspot.condition}: ${hotspot.cases} reports from ${hotspot.workerCount} ASHA workers',
                  ),
                ),
              ),
              child: const _SharedHotspotMarker(),
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
    final point = _liveLocation;
    if (point == null) return const [];
    final radius = math.max(_liveAccuracy, 6.0);
    return [
      CircleMarker(
        point: point,
        radius: radius,
        useRadiusInMeter: true,
        color: const Color(0x1F2563EB),
        borderColor: const Color(0x662563EB),
        borderStrokeWidth: 1.5,
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

  List<Marker> _stateHubMarkers() {
    return [
      for (final hub in _stateHubs)
        Marker(
          key: Key('hub-${hub.name}'),
          point: LatLng(hub.lat, hub.lng),
          width: 130,
          height: 32,
          alignment: Alignment.center,
          child: _StateHubMarker(
            hub: hub,
            onTap: () => _mapController.move(LatLng(hub.lat, hub.lng), 8.5),
          ),
        ),
    ];
  }

  List<Marker> _topHospitalMarkers(List<FacilityPoi> facilities) {
    final dhs = facilities
        .where((f) => f.category == 'hospital' || f.category == 'blood_bank')
        .take(30);
    return [
      for (final poi in dhs)
        Marker(
          key: Key('poi-${poi.id}'),
          point: LatLng(poi.latitude, poi.longitude),
          width: 100,
          height: 44,
          alignment: Alignment.topCenter,
          child: _ModernPinMarker(
            poi: poi,
            category: poi.category,
            chosen: _selected?.id == poi.id,
            showLabel: false,
            onTap: () {
              _ateMarkerTap = true;
              setState(() {
                _selected = poi;
                _selectedHousehold = null;
                _selectedWard = null;
                _pointingTarget = null;
              });
            },
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
    for (final hotspot in widget.sharedHotspots) {
      final point = LatLng(hotspot.latitude, hotspot.longitude);
      circles.add(
        CircleMarker(
          point: point,
          radius: math.min(2400, 700 + hotspot.cases * 120).toDouble(),
          useRadiusInMeter: true,
          color: const Color(0x267C3AED),
          borderColor: const Color(0xAA7C3AED),
          borderStrokeWidth: 2,
        ),
      );
    }
    return circles;
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
      final metres = pathMetres(selectedWalk ?? [selected.point]).round();
      final hasPhone = selected.phone.isNotEmpty;
      final categoryColor = _facilityColor(selected.category);

      return Material(
        color: Colors.white,
        elevation: 6,
        shadowColor: Colors.black38,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Icon badge + Name + Category/Distance + Close button
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _facilityIcon(selected.category),
                        color: categoryColor,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selected.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          '${_categoryLabel(selected.category)}${selected.wardId.isNotEmpty && selected.wardId != "INDIA" ? " · ${selected.wardId}" : ""} · ${metres}m away',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() {
                      _selected = null;
                      _pointingTarget = null;
                    }),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Action buttons: Call, Navigate, Point me in a sleek compact horizontal row
              Row(
                children: [
                  // Call button
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: OutlinedButton.icon(
                        key: Key('call-${selected.id}'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                          side: BorderSide(
                            color: hasPhone
                                ? const Color(0xFF16A34A)
                                : Colors.grey.shade400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: hasPhone
                            ? () => widget.openUri(
                                Uri.parse('tel:${selected.phone}'),
                              )
                            : null,
                        icon: Icon(
                          Icons.call_rounded,
                          size: 14,
                          color: hasPhone
                              ? const Color(0xFF16A34A)
                              : Colors.grey,
                        ),
                        label: Text(
                          'Call',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: hasPhone
                                ? (_satelliteView
                                      ? Colors.white
                                      : const Color(0xFF1E4231))
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Navigate button
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: FilledButton.icon(
                        key: Key('navigate-${selected.id}'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () =>
                            _navigate(selected.latitude, selected.longitude),
                        icon: const Icon(Icons.navigation_rounded, size: 14),
                        label: Text(
                          '${metres}m',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Point me button
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _pointingTarget != null
                              ? const Color(0xFFEA580C).withValues(alpha: 0.12)
                              : null,
                          side: BorderSide(
                            color: _pointingTarget != null
                                ? const Color(0xFFEA580C)
                                : const Color(0xFF64748B),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => setState(() {
                          if (_pointingTarget != null) {
                            _pointingTarget = null;
                          } else {
                            _pointingTarget = selected.point;
                          }
                        }),
                        icon: Icon(
                          Icons.explore_rounded,
                          size: 14,
                          color: _pointingTarget != null
                              ? const Color(0xFFEA580C)
                              : const Color(0xFF64748B),
                        ),
                        label: Text(
                          'Point me',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _pointingTarget != null
                                ? const Color(0xFFEA580C)
                                : (_satelliteView
                                      ? Colors.white
                                      : const Color(0xFF334155)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // If Point Me is active, show the directional compass inline
              if (_pointingTarget != null) ...[
                const SizedBox(height: 8),
                _inlineCompassGuidance(selected.point),
              ],
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
    final metres = haversineMetres(_effectiveFix, household.point).round();
    return Material(
      color: _satelliteView
          ? const Color(0xFF1E293B).withValues(alpha: 0.96)
          : Colors.white,
      elevation: 6,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _householdColor(household).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.home_rounded,
                      color: _householdColor(household),
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        household.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _satelliteView
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${household.ageYears}y · ${household.dues.isNotEmpty ? household.dues.join(" · ") : "Up to date"} · ${metres}m away',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: _satelliteView
                              ? Colors.grey.shade400
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() {
                    _selectedHousehold = null;
                    _pointingTarget = null;
                  }),
                  icon: Icon(
                    Icons.close_rounded,
                    color: _satelliteView
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () =>
                          _navigate(household.latitude, household.longitude),
                      icon: const Icon(Icons.navigation_rounded, size: 14),
                      label: Text(
                        '${metres}m',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 34,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _pointingTarget != null
                            ? const Color(0xFFEA580C).withValues(alpha: 0.12)
                            : null,
                        side: BorderSide(
                          color: _pointingTarget != null
                              ? const Color(0xFFEA580C)
                              : const Color(0xFF64748B),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => setState(() {
                        if (_pointingTarget != null) {
                          _pointingTarget = null;
                        } else {
                          _pointingTarget = household.point;
                        }
                      }),
                      icon: Icon(
                        Icons.explore_rounded,
                        size: 14,
                        color: _pointingTarget != null
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF64748B),
                      ),
                      label: Text(
                        'Point me',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _pointingTarget != null
                              ? const Color(0xFFEA580C)
                              : (_satelliteView
                                    ? Colors.white
                                    : const Color(0xFF334155)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_pointingTarget != null) ...[
              const SizedBox(height: 8),
              _inlineCompassGuidance(household.point),
            ],
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

  Widget _inlineCompassGuidance(LatLon target) {
    final bearing = bearingDegrees(_effectiveFix, target);
    final metres = haversineMetres(_effectiveFix, target);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEA580C).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFEA580C).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Transform.rotate(
            angle: bearing * math.pi / 180,
            child: const Icon(
              Icons.navigation_rounded,
              color: Color(0xFFEA580C),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Heading ${bearingLabel(bearing)} (${bearing.round()}°) · ${metres.round()}m direct',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _satelliteView ? Colors.white : const Color(0xFF9A3412),
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _pointingTarget = null),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: _satelliteView ? Colors.white70 : const Color(0xFF9A3412),
            ),
          ),
        ],
      ),
    );
  }

  Widget _directionCard(LatLon target) {
    final bearing = bearingDegrees(_effectiveFix, target);
    final metres = haversineMetres(_effectiveFix, target);
    return Material(
      color: _satelliteView
          ? const Color(0xFF1E293B).withValues(alpha: 0.96)
          : Colors.white,
      elevation: 6,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Transform.rotate(
              angle: bearing * math.pi / 180,
              child: const Icon(
                Icons.navigation_rounded,
                color: Color(0xFFEA580C),
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Heading ${bearingLabel(bearing)} (${bearing.round()}°) · ${metres.round()}m direct',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _satelliteView
                      ? Colors.white
                      : const Color(0xFF111827),
                ),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => setState(() => _pointingTarget = null),
              icon: Icon(
                Icons.close_rounded,
                color: _satelliteView
                    ? Colors.grey.shade400
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _facilityIcon(String category) => switch (category.toLowerCase()) {
    'phc' => Icons.local_hospital_rounded,
    'chc' => Icons.apartment_rounded,
    'blood_bank' => Icons.bloodtype_rounded,
    'nrc' => Icons.child_friendly_rounded,
    'deic' => Icons.accessibility_new_rounded,
    'antivenom' => Icons.warning_amber_rounded,
    'ab_hwc' => Icons.health_and_safety_rounded,
    'pmjay' => Icons.currency_rupee_rounded,
    'vhsnd' => Icons.event_available_rounded,
    'eye_bank' => Icons.visibility_rounded,
    'hospital' || 'dh' => Icons.domain_rounded,
    'sub_centre' || 'subcentre' => Icons.health_and_safety_rounded,
    'lab' => Icons.science_rounded,
    'janaushadhi' || 'dispensary' => Icons.medication_rounded,
    'anganwadi' => Icons.child_care_rounded,
    'police' => Icons.local_police_outlined,
    'ration_shop' => Icons.shopping_basket_outlined,
    _ => Icons.local_hospital_rounded,
  };

  Color _facilityColor(String category) => switch (category.toLowerCase()) {
    'phc' => const Color(0xFF10B981),
    'chc' => const Color(0xFF2563EB),
    'blood_bank' => const Color(0xFFDC2626),
    'nrc' => const Color(0xFF7C3AED),
    'deic' => const Color(0xFF2563EB),
    'antivenom' => const Color(0xFFB45309),
    'ab_hwc' => const Color(0xFF0F766E),
    'pmjay' => const Color(0xFF15803D),
    'vhsnd' => const Color(0xFF9333EA),
    'eye_bank' => const Color(0xFF0891B2),
    'hospital' || 'dh' => const Color(0xFFF59E0B),
    'lab' => const Color(0xFF0284C7),
    'anganwadi' => const Color(0xFFEA580C),
    'sub_centre' || 'subcentre' => const Color(0xFF0D9488),
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

class _SharedHotspotMarker extends StatelessWidget {
  const _SharedHotspotMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x557C3AED), blurRadius: 8),
            ],
          ),
          child: const Icon(
            Icons.groups_2_rounded,
            color: Colors.white,
            size: 17,
          ),
        ),
        Positioned(
          right: -5,
          top: -5,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7C3AED)),
            ),
            child: const Icon(
              Icons.sync_rounded,
              color: Color(0xFF7C3AED),
              size: 9,
            ),
          ),
        ),
      ],
    );
  }
}

class _HouseholdMarker extends StatelessWidget {
  const _HouseholdMarker({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 5)],
      ),
      child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 16),
    );
  }
}

class _LiveLocationMarker extends StatelessWidget {
  const _LiveLocationMarker({this.accuracy});

  final double? accuracy;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1.08),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      onEnd: () {},
      builder: (context, scale, child) => Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Name chip floating directly above the centered pin
          Positioned(bottom: 30, child: const _NameChip('You · live')),
          // Pulsing halo
          Transform.scale(
            scale: scale,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0x332563EB),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Pinpoint blue GPS dot centered EXACTLY at point
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x551D4ED8),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
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
    this.liveCoordinates,
    this.liveAccuracy,
    this.liveProvider,
  });

  final String wardId;
  final bool isLive;
  final bool isSatellite;
  final String activeCategory;
  final _MapLayer layer;
  final VoidCallback onTap;
  final LatLng? liveCoordinates;
  final double? liveAccuracy;
  final String? liveProvider;

  @override
  Widget build(BuildContext context) {
    final tag = (liveProvider ?? 'gps').toUpperCase();
    final statusText = isLive && liveCoordinates != null
        ? '$tag · ${liveCoordinates!.latitude.toStringAsFixed(5)}, ${liveCoordinates!.longitude.toStringAsFixed(5)} (±${(liveAccuracy ?? 10).toStringAsFixed(0)}m)'
        : (isLive ? 'Live GPS' : 'Catchment · $wardId');
    final layerText = switch (layer) {
      _MapLayer.facilities =>
        activeCategory == 'all' ? 'Facilities' : activeCategory.toUpperCase(),
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
              selected:
                  layer == _MapLayer.facilities && category == 'blood_bank',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'blood_bank'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: 'NRC',
              icon: Icons.child_friendly_rounded,
              activeColor: const Color(0xFF7C3AED),
              selected: layer == _MapLayer.facilities && category == 'nrc',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'nrc'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: 'Antivenom',
              icon: Icons.warning_amber_rounded,
              activeColor: const Color(0xFFB45309),
              selected:
                  layer == _MapLayer.facilities && category == 'antivenom',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'antivenom'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: 'AB-HWC',
              icon: Icons.health_and_safety_rounded,
              activeColor: const Color(0xFF0F766E),
              selected: layer == _MapLayer.facilities && category == 'ab_hwc',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'ab_hwc'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: 'DEIC',
              icon: Icons.accessibility_new_rounded,
              activeColor: const Color(0xFF2563EB),
              selected: layer == _MapLayer.facilities && category == 'deic',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'deic'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: 'PM-JAY',
              icon: Icons.currency_rupee_rounded,
              activeColor: const Color(0xFF15803D),
              selected: layer == _MapLayer.facilities && category == 'pmjay',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'pmjay'),
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

class _ModernPinMarker extends StatelessWidget {
  const _ModernPinMarker({
    required this.poi,
    required this.category,
    required this.chosen,
    required this.showLabel,
    required this.onTap,
  });

  final FacilityPoi poi;
  final String category;
  final bool chosen;
  final bool showLabel;
  final VoidCallback onTap;

  Color _pinColor(String cat, bool isChosen) {
    if (isChosen) return const Color(0xFFE11D48); // Rose highlight when chosen
    return switch (cat.toLowerCase()) {
      'phc' => const Color(0xFF10B981), // Emerald Green
      'chc' => const Color(0xFF2563EB), // Royal Blue
      'hospital' || 'dh' => const Color(0xFFF59E0B), // Golden Amber
      'blood_bank' => const Color(0xFFDC2626), // Crimson Red
      'sub_centre' || 'subcentre' => const Color(0xFF0D9488),
      'anganwadi' => const Color(0xFFEA580C),
      'lab' => const Color(0xFF0284C7),
      _ => const Color(0xFF1E4231),
    };
  }

  Color _pinBorderColor(String cat, bool isChosen) {
    if (isChosen) return const Color(0xFF9F1239);
    return switch (cat.toLowerCase()) {
      'phc' => const Color(0xFF064E3B),
      'chc' => const Color(0xFF1E3A8A),
      'hospital' || 'dh' => const Color(0xFF92400E),
      'blood_bank' => const Color(0xFF7F1D1D),
      'sub_centre' || 'subcentre' => const Color(0xFF134E4A),
      'anganwadi' => const Color(0xFF7C2D12),
      'lab' => const Color(0xFF075985),
      _ => const Color(0xFF0F291E),
    };
  }

  IconData _pinIcon(String cat) {
    return switch (cat.toLowerCase()) {
      'phc' => Icons.local_hospital_rounded,
      'chc' => Icons.apartment_rounded,
      'hospital' || 'dh' => Icons.domain_rounded,
      'blood_bank' => Icons.bloodtype_rounded,
      'sub_centre' || 'subcentre' => Icons.health_and_safety_rounded,
      'anganwadi' => Icons.child_care_rounded,
      'lab' => Icons.science_rounded,
      _ => Icons.local_hospital_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _pinColor(category, chosen);
    final borderColor = _pinBorderColor(category, chosen);
    final icon = _pinIcon(category);

    final pinWidth = chosen ? 28.0 : 22.0;
    final pinHeight = chosen ? 35.0 : 28.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showLabel) ...[_NameChip(poi.name), const SizedBox(height: 2)],
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (chosen)
                Positioned(
                  top: -3,
                  child: Container(
                    width: pinWidth + 12,
                    height: pinWidth + 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.3),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              CustomPaint(
                size: Size(pinWidth, pinHeight),
                painter: _PinPainter(
                  fillColor: color,
                  borderColor: borderColor,
                  strokeWidth: chosen ? 2.0 : 1.4,
                ),
                child: SizedBox(
                  width: pinWidth,
                  height: pinHeight,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: chosen ? 9 : 7),
                    child: Center(
                      child: Container(
                        width: chosen ? 15 : 12,
                        height: chosen ? 15 : 12,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            icon,
                            size: chosen ? 10 : 8,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  const _PinPainter({
    required this.fillColor,
    required this.borderColor,
    this.strokeWidth = 1.4,
  });

  final Color fillColor;
  final Color borderColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final radius = w / 2;

    final path = Path()
      ..moveTo(radius, h)
      ..cubicTo(radius * 0.45, h * 0.65, 0, radius * 1.25, 0, radius)
      ..arcToPoint(
        Offset(w, radius),
        radius: Radius.circular(radius),
        clockwise: true,
      )
      ..cubicTo(w, radius * 1.25, radius + radius * 0.55, h * 0.65, radius, h)
      ..close();

    canvas.drawShadow(path, Colors.black45, 3.0, false);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

class _StateHubMarker extends StatelessWidget {
  const _StateHubMarker({required this.hub, required this.onTap});

  final _StateHub hub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final countLabel = hub.count >= 1000
        ? '${(hub.count / 1000).toStringAsFixed(1)}k'
        : '${hub.count}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.7),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                hub.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                countLabel,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF065F46),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateHub {
  const _StateHub({
    required this.name,
    required this.lat,
    required this.lng,
    required this.count,
  });

  final String name;
  final double lat;
  final double lng;
  final int count;
}

const _stateHubs = <_StateHub>[
  _StateHub(name: 'Uttar Pradesh', lat: 26.8467, lng: 80.9462, count: 3866),
  _StateHub(name: 'Maharashtra', lat: 19.2408, lng: 76.6078, count: 3074),
  _StateHub(name: 'Rajasthan', lat: 26.9124, lng: 75.7873, count: 3012),
  _StateHub(name: 'Karnataka', lat: 15.0106, lng: 76.3443, count: 2713),
  _StateHub(name: 'Tamil Nadu', lat: 10.8158, lng: 78.2891, count: 2269),
  _StateHub(name: 'Gujarat', lat: 22.4046, lng: 71.4801, count: 1938),
  _StateHub(name: 'Bihar', lat: 25.0961, lng: 85.3131, count: 1900),
  _StateHub(name: 'Odisha', lat: 20.1743, lng: 84.4321, count: 1717),
  _StateHub(name: 'Madhya Pradesh', lat: 23.4733, lng: 77.9479, count: 1657),
  _StateHub(name: 'Andhra Pradesh', lat: 15.8897, lng: 80.7370, count: 1616),
  _StateHub(name: 'West Bengal', lat: 24.3489, lng: 87.8532, count: 1267),
  _StateHub(name: 'Kerala', lat: 10.5237, lng: 76.0518, count: 1198),
  _StateHub(name: 'Chhattisgarh', lat: 21.2787, lng: 81.8661, count: 982),
  _StateHub(name: 'Telangana', lat: 17.8468, lng: 79.3731, count: 918),
  _StateHub(name: 'Assam', lat: 26.1435, lng: 92.8162, count: 881),
  _StateHub(name: 'Jammu & Kashmir', lat: 33.7782, lng: 76.5762, count: 804),
  _StateHub(name: 'Punjab', lat: 31.0264, lng: 75.4296, count: 692),
  _StateHub(name: 'Haryana', lat: 29.0588, lng: 76.0856, count: 645),
  _StateHub(name: 'Delhi', lat: 28.6139, lng: 77.2090, count: 593),
  _StateHub(name: 'Himachal Pradesh', lat: 31.7808, lng: 77.1431, count: 571),
  _StateHub(name: 'Jharkhand', lat: 23.6716, lng: 85.6692, count: 557),
  _StateHub(name: 'Uttarakhand', lat: 30.0668, lng: 79.0193, count: 307),
  _StateHub(name: 'Meghalaya', lat: 25.5496, lng: 91.2307, count: 177),
  _StateHub(name: 'Arunachal Pradesh', lat: 28.2180, lng: 94.7278, count: 172),
  _StateHub(name: 'Nagaland', lat: 25.8881, lng: 94.2660, count: 156),
  _StateHub(name: 'Tripura', lat: 23.6053, lng: 91.7957, count: 124),
  _StateHub(name: 'Manipur', lat: 24.8054, lng: 93.7839, count: 113),
  _StateHub(name: 'Mizoram', lat: 23.3712, lng: 92.8399, count: 80),
  _StateHub(name: 'Puducherry', lat: 11.9416, lng: 79.8083, count: 48),
  _StateHub(name: 'Chandigarh', lat: 30.7362, lng: 76.7788, count: 45),
  _StateHub(name: 'Goa', lat: 15.3527, lng: 73.9630, count: 37),
  _StateHub(name: 'A & N Islands', lat: 10.1460, lng: 93.1600, count: 31),
  _StateHub(name: 'Sikkim', lat: 27.4108, lng: 88.4485, count: 31),
];
