import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geo_intel/geo_intel.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:permission_handler/permission_handler.dart';
import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:triage/triage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/widgets/asha_bottom_nav.dart';
import '../../../core/packs/map_content_pack_store.dart';
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
      final mapStore = MapContentPackStore();
      if (!await mapStore.isInstalled()) {
        throw const MapContentPackException(
          'Install the Offline maps pack before opening the map.',
        );
      }
      final wards = await rootBundle.loadString(
        'packages/triage/lib/data/pack/wards.geojson',
      );
      final counts = await rootBundle.loadString(
        'packages/triage/lib/data/pack/disease_counts.csv',
      );
      final facilities = await (await mapStore.file('facilities.geojson')).readAsString();
      final indiaFacilities = await (await mapStore.file('india_facilities.json')).readAsString();
      final states = await (await mapStore.file('india_states.geojson')).readAsString();
      final households = await (await mapStore.file('households.json')).readAsString();
      final referrals = await (await mapStore.file('referrals.json')).readAsString();
      final roads = await (await mapStore.file('roads.json')).readAsString();
      final labelsRaw = await (await mapStore.file('labels.json')).readAsString();
      TileProvider? tiles;
      if (widget.useOsmBasemap) {
        tiles = MemoryTileProvider(MbTilesTileProvider.blank);
      } else {
        final file = await mapStore.file('pcmc.mbtiles');
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
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
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
      lang: lang,
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
    this.lang = 'en',
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
  final String lang;

  @override
  State<GeoMapScreen> createState() => _GeoMapScreenState();
}

class _GeoMapScreenState extends State<GeoMapScreen> {
  String get _lang {
    final ctxLang = Localizations.maybeLocaleOf(context)?.languageCode;
    if (ctxLang != null && ctxLang.isNotEmpty && ctxLang != 'en') {
      return ctxLang;
    }
    return widget.lang;
  }

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
    final lang = _lang;
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
                MarkerLayer(markers: _markers(lang)),
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
              lang: lang,
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
              child: _directionCard(_pointingTarget!, lang),
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
                  child: _selectionCard(selected, selectedWalk, lang),
                ),
              ),
            ),

          // Bottom Filter & Controls Dock
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _buildBottomControlBar(lang),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControlBar(String lang) {
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
              lang: lang,
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
                    _conditionPrefix(lang),
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
                      items: [
                        DropdownMenuItem(
                          value: 'dengue_like',
                          child: Text(_conditionLabel('dengue_like', lang)),
                        ),
                        DropdownMenuItem(
                          value: 'acute_diarrhoea',
                          child: Text(_conditionLabel('acute_diarrhoea', lang)),
                        ),
                        DropdownMenuItem(
                          value: 'measles_like',
                          child: Text(_conditionLabel('measles_like', lang)),
                        ),
                        DropdownMenuItem(
                          value: 'aes',
                          child: Text(_conditionLabel('aes', lang)),
                        ),
                        DropdownMenuItem(
                          value: 'fever',
                          child: Text(_conditionLabel('fever', lang)),
                        ),
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
                    _weekLabel(_week, lang),
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
                      _todaysRouteLabel(lang),
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

  List<Marker> _markers(String lang) {
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
            child: IgnorePointer(
              child: _NameChip(_localizeMapLabel(label.name, lang)),
            ),
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
          ..._stateHubMarkers(lang),
          ..._topHospitalMarkers(facilities, lang),
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

      // A state tap moves the camera to roughly zoom 8.5. At that level a
      // Maharashtra-sized viewport can still contain thousands of facilities;
      // creating one Flutter widget per POI blocks the UI thread and makes the
      // map appear frozen. Keep the overview bounded with geographic clusters
      // until the worker zooms into a smaller area.
      if (visiblePool.length > 120) {
        return [
          ...markers,
          ..._facilityClusterMarkers(visiblePool),
        ];
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
              lang: lang,
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
                    _NameChip(
                      '${routeIndex + 1}. ${_localizeHouseholdName(household.name, lang)}',
                    ),
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
                    _sharedHotspotSnackbarText(hotspot, lang),
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

  List<Marker> _facilityClusterMarkers(List<FacilityPoi> facilities) {
    final cellSize = (1.0 / math.pow(2, (_zoomLevel - 7) / 2))
        .clamp(0.025, 1.0)
        .toDouble();
    final groups = <String, List<FacilityPoi>>{};
    for (final facility in facilities) {
      final latCell = (facility.latitude / cellSize).floor();
      final lngCell = (facility.longitude / cellSize).floor();
      groups.putIfAbsent('$latCell:$lngCell', () => []).add(facility);
    }

    return [
      for (final group in groups.values)
        if (group.isNotEmpty)
          () {
            final latitude = group
                    .map((item) => item.latitude)
                    .reduce((a, b) => a + b) /
                group.length;
            final longitude = group
                    .map((item) => item.longitude)
                    .reduce((a, b) => a + b) /
                group.length;
            final category = group.any((item) => item.category == 'hospital')
                ? 'hospital'
                : group.any((item) => item.category == 'blood_bank')
                    ? 'blood_bank'
                    : group.first.category;
            return Marker(
              key: Key('facility-cluster-${group.first.id}'),
              point: LatLng(latitude, longitude),
              width: 52,
              height: 52,
              child: _ClusterMarker(
                count: group.length,
                color: _facilityColor(category),
                onTap: () {
                  _ateMarkerTap = true;
                  _mapController.move(
                    LatLng(latitude, longitude),
                    math.min(_zoomLevel + 2, 18),
                  );
                },
              ),
            );
          }(),
    ];
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

  List<Marker> _stateHubMarkers(String lang) {
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
            lang: lang,
            onTap: () => _mapController.move(LatLng(hub.lat, hub.lng), 8.5),
          ),
        ),
    ];
  }

  List<Marker> _topHospitalMarkers(List<FacilityPoi> facilities, String lang) {
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
            lang: lang,
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

  Widget _selectionCard(
    FacilityPoi? selected,
    List<LatLon>? selectedWalk,
    String lang,
  ) {
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
                          _localizeMapLabel(selected.name, lang),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          '${_categoryLabel(selected.category, lang)}${selected.wardId.isNotEmpty && selected.wardId != "INDIA" ? " · ${selected.wardId}" : ""} · ${_distanceAwayText(metres, lang)}',
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
                          _callLabel(lang),
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
                          _pointMeLabel(lang),
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
                _inlineCompassGuidance(selected.point, lang),
              ],
            ],
          ),
        ),
      );
    }
    final household = _selectedHousehold;
    if (household != null) {
      return _householdCard(household, lang);
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
                      '${ward.wardId} · ${_conditionLabel(_condition, lang)}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedWard = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(_casesInWeekText(cases, _week, lang)),
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
                label: Text(_startAssessmentText(ward.wardId, lang)),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _householdCard(HouseholdPin household, String lang) {
    final metres = haversineMetres(_effectiveFix, household.point).round();
    final duesStr = household.dues.isNotEmpty
        ? household.dues.map((due) => _localizeDue(due, lang)).join(" · ")
        : _upToDateLabel(lang);
    final ageStr = '${household.ageYears}${_yearSuffix(lang)}';

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
                        _localizeHouseholdName(household.name, lang),
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
                        '$ageStr · $duesStr · ${_distanceAwayText(metres, lang)}',
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
                        _pointMeLabel(lang),
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
              _inlineCompassGuidance(household.point, lang),
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

  Widget _inlineCompassGuidance(LatLon target, String lang) {
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
              _directHeadingText(
                bearingLabel(bearing),
                bearing.round(),
                metres.round(),
                lang,
              ),
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

  Widget _directionCard(LatLon target, String lang) {
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
                _directHeadingText(
                  bearingLabel(bearing),
                  bearing.round(),
                  metres.round(),
                  lang,
                ),
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

  String _categoryLabel(String category, [String? lang]) =>
      _localizeCategoryLabel(category, lang ?? _lang);

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

  String _conditionLabel(String condition, [String? lang]) =>
      _localizeConditionLabel(condition, lang ?? _lang);
}

String _localizeStateName(String name, String lang) {
  if (lang == 'en') return name;
  const states = <String, Map<String, String>>{
    'Uttar Pradesh': {
      'hi': 'उत्तर प्रदेश', 'mr': 'उत्तर प्रदेश', 'bn': 'উত্তর প্রদেশ', 'te': 'ఉత్తరప్రదేశ్',
      'ta': 'உத்தரப் பிரதேசம்', 'kn': 'ಉತ್ತರ ಪ್ರದೇಶ', 'ml': 'ഉത്തർപ്രദേശ്', 'gu': 'ઉત્તર પ્રદેશ',
      'pa': 'ਉੱਤਰ ਪ੍ਰਦੇਸ਼', 'or': 'ଉତ୍ତର ପ୍ରଦେଶ', 'as': 'উত্তৰ প্ৰদেশ',
    },
    'Maharashtra': {
      'hi': 'महाराष्ट्र', 'mr': 'महाराष्ट्र', 'bn': 'মহারাষ্ট্র', 'te': 'మహారాష్ట్ర',
      'ta': 'மகாராஷ்டிரா', 'kn': 'ಮಹಾರಾಷ್ಟ್ರ', 'ml': 'മഹാരാഷ്ട്ര', 'gu': 'મહારાષ્ટ્ર',
      'pa': 'ਮਹਾਰਾਸ਼ਟਰ', 'or': 'ମହାରାଷ୍ଟ୍ର', 'as': 'মহাৰাষ্ট্ৰ',
    },
    'Rajasthan': {
      'hi': 'राजस्थान', 'mr': 'राजस्थान', 'bn': 'রাজস্থান', 'te': 'రాజస్థాన్',
      'ta': 'ராஜஸ்தான்', 'kn': 'ರಾಜಸ್ಥಾನ', 'ml': 'രാജസ്ഥാൻ', 'gu': 'રાજસ્થાન',
      'pa': 'ਰਾਜਸਥਾਨ', 'or': 'ରାଜସ୍ଥାନ', 'as': 'ৰাজস্থান',
    },
    'Karnataka': {
      'hi': 'कर्नाटक', 'mr': 'कर्नाटक', 'bn': 'কর্ণাটক', 'te': 'కర్ణాటక',
      'ta': 'கர்நாடகா', 'kn': 'ಕರ್ನಾಟಕ', 'ml': 'ಕರ್ನಾಟಕ', 'gu': 'કર્ણાટક',
      'pa': 'ਕਰਨਾਟਕ', 'or': 'କର୍ଣ୍ଣାଟକ', 'as': 'কৰ্ণাটক',
    },
    'Tamil Nadu': {
      'hi': 'तमिलनाडु', 'mr': 'तमिळनाडू', 'bn': 'তামিলনাড়ু', 'te': 'తమిళనాడు',
      'ta': 'தமிழ்நாடு', 'kn': 'ತಮಿಳುನಾಡು', 'ml': 'തമിഴ്‌നാട്', 'gu': 'તમિલનાડુ',
      'pa': 'ਤਾਮਿਲਨਾਡੂ', 'or': 'ତାମିଲନାଡୁ', 'as': 'তামিলনাডু',
    },
    'Gujarat': {
      'hi': 'गुजरात', 'mr': 'गुजरात', 'bn': 'ગુજરાત', 'te': 'గుజరాత్',
      'ta': 'குஜராத்', 'kn': 'ಗುಜರಾತ್', 'ml': 'ഗുജറാത്ത്', 'gu': 'ગુજરાત',
      'pa': 'ਗੁਜਰਾਤ', 'or': 'ଗୁଜରାଟ', 'as': 'গুজৰাট',
    },
    'Bihar': {
      'hi': 'बिहार', 'mr': 'बिहार', 'bn': 'বিহার', 'te': 'బీహార్',
      'ta': 'பீகார்', 'kn': 'ಬಿಹಾರ', 'ml': 'ബിഹാർ', 'gu': 'બિહાર',
      'pa': 'ਬਿਹਾਰ', 'or': 'ବିହାର', 'as': 'বিহাৰ',
    },
    'Odisha': {
      'hi': 'ओडिशा', 'mr': 'ओडिशा', 'bn': 'ওড়িশা', 'te': 'ఒడిశా',
      'ta': 'ஒடிசா', 'kn': 'ಒಡಿಶಾ', 'ml': 'ಒഡീഷ', 'gu': 'ઓડિશા',
      'pa': 'ਓਡੀਸ਼ਾ', 'or': 'ଓଡ଼ିଶା', 'as': 'ওড়িশা',
    },
    'Madhya Pradesh': {
      'hi': 'मध्य प्रदेश', 'mr': 'मध्य प्रदेश', 'bn': 'মধ্য প্রদেশ', 'te': 'మధ్యప్రదేశ్',
      'ta': 'மத்தியப் பிரதேசம்', 'kn': 'ಮಧ್ಯ ಪ್ರದೇಶ', 'ml': 'മധ്യപ്രദേശ്', 'gu': 'મધ્ય પ્રદેશ',
      'pa': 'ਮੱਧ ਪ੍ਰਦੇਸ਼', 'or': 'ମଧ୍ୟ ପ୍ରଦେଶ', 'as': 'মধ্য প্ৰদেশ',
    },
    'Andhra Pradesh': {
      'hi': 'आंध्र प्रदेश', 'mr': 'आंध्र प्रदेश', 'bn': 'অন্ধ্র প্রদেশ', 'te': 'ఆంధ్రప్రదేశ్',
      'ta': 'ஆந்திரப் பிரதேசம்', 'kn': 'ಆಂಧ್ರ ಪ್ರದೇಶ', 'ml': 'ആന്ധ്രാപ്രദേശ്', 'gu': 'આંધ્ર પ્રદેશ',
      'pa': 'ਆਂਧਰਾ ਪ੍ਰਦੇਸ਼', 'or': 'ଆନ୍ଧ୍ର ପ୍ରଦେଶ', 'as': 'অন্ধ্ৰ প্ৰদেশ',
    },
    'West Bengal': {
      'hi': 'पश्चिम बंगाल', 'mr': 'पश्चिम बंगाल', 'bn': 'পশ্চিমবঙ্গ', 'te': 'పశ్చిమ బెంగాల్',
      'ta': 'மேற்கு வங்காளம்', 'kn': 'ಪಶ್ಚಿಮ ಬಂಗಾಳ', 'ml': 'പശ്ചിമ ബംഗാൾ', 'gu': 'પશ્ચિમ બંગાળ',
      'pa': 'ਪੱਛਮੀ ਬੰਗਾਲ', 'or': 'ପଶ୍ଚିମ ବଙ୍ଗ', 'as': 'পশ্চিম বংগ',
    },
    'Kerala': {
      'hi': 'केरल', 'mr': 'केरळ', 'bn': 'কেরালা', 'te': 'కేరళ',
      'ta': 'கேரளா', 'kn': 'ಕೇರಳ', 'ml': 'കേരളം', 'gu': 'કેરળ',
      'pa': 'ਕੇਰਲ', 'or': 'କେରଳ', 'as': 'কেৰালা',
    },
    'Chhattisgarh': {
      'hi': 'छत्तीसगढ़', 'mr': 'छत्तीसगड', 'bn': 'ছত্তিশগড়', 'te': 'ఛత్తీస్‌గఢ్',
      'ta': 'சத்தீஸ்கர்', 'kn': 'ಛತ್ತೀಸ್‌ಗಢ', 'ml': 'ഛത്തീസ്ഗഡ്', 'gu': 'છત્તીસગઢ',
      'pa': 'ਛੱਤੀਸਗੜ੍ਹ', 'or': 'ଛତିଶଗଡ଼', 'as': 'ছত্তীশগড়',
    },
    'Telangana': {
      'hi': 'तेलंगाना', 'mr': 'तेलंगणा', 'bn': 'তেলেঙ্গানা', 'te': 'తెలంగాణ',
      'ta': 'தெலுங்கானா', 'kn': 'ತೆಲಂಗಾಣ', 'ml': 'തെലങ്കാന', 'gu': 'તેલંગાણા',
      'pa': 'ਤੇਲੰਗਾਨਾ', 'or': 'ତେଲେଙ୍ଗାନା', 'as': 'তেলেংগানা',
    },
    'Assam': {
      'hi': 'असम', 'mr': 'आसाम', 'bn': 'আসাম', 'te': 'అస్సాం',
      'ta': 'அசாம்', 'kn': 'ಅಸ್ಸಾಂ', 'ml': 'അസം', 'gu': 'અસમ',
      'pa': 'ਅਸਾਮ', 'or': 'ଆସାମ', 'as': 'অসম',
    },
    'Jammu & Kashmir': {
      'hi': 'जम्मू और कश्मीर', 'mr': 'जम्मू आणि काश्मीर', 'bn': 'জম্মু ও কাশ্মীর', 'te': 'జమ్మూ కాశ్మీర్',
      'ta': 'ஜம்மு & காஷ்மீர்', 'kn': 'ಜಮ್ಮು ಮತ್ತು ಕಾಶ್ಮೀರ', 'ml': 'ജമ്മു & കശ്മീർ', 'gu': 'જમ્મુ અને કાશ્મીર',
      'pa': 'ਜੰਮੂ ਅਤੇ ਕਸ਼ਮੀਰ', 'or': 'ଜମ୍ମୁ ଓ କାଶ୍ମୀର', 'as': 'জম্মু আৰু কাশ্মীৰ',
    },
    'Punjab': {
      'hi': 'पंजाब', 'mr': 'पंजाब', 'bn': 'পাঞ্জাব', 'te': 'పంజాబ్',
      'ta': 'பஞ்சாப்', 'kn': 'ಪಂಜಾಬ್', 'ml': 'പഞ്ചാബ്', 'gu': 'પંજાબ',
      'pa': 'ਪੰਜਾਬ', 'or': 'ପଞ୍ଜାବ', 'as': 'পঞ্জাৱ',
    },
    'Haryana': {
      'hi': 'हरियाणा', 'mr': 'हरियाणा', 'bn': 'হরিয়ানা', 'te': 'హర్యానా',
      'ta': 'ஹரியானா', 'kn': 'ಹರಿಯಾಣ', 'ml': 'ഹരിയാന', 'gu': 'હરિયાણા',
      'pa': 'ਹਰਿਆਣਾ', 'or': 'ହରିୟାଣା', 'as': 'হাৰিয়ানা',
    },
    'Delhi': {
      'hi': 'दिल्ली', 'mr': 'दिल्ली', 'bn': 'দিল্লি', 'te': 'ఢిల్లీ',
      'ta': 'டெல்லி', 'kn': 'ದೆಹಲಿ', 'ml': 'ഡൽഹി', 'gu': 'દિલ્હી',
      'pa': 'ਦਿੱਲੀ', 'or': 'ଦିଲ୍ଲୀ', 'as': 'দিল্লী',
    },
    'Himachal Pradesh': {
      'hi': 'हिमाचल प्रदेश', 'mr': 'हिमाचल प्रदेश', 'bn': 'হিমাচল প্রদেশ', 'te': 'హిమాచల్ ప్రదేశ్',
      'ta': 'இமாச்சலப் பிரதேசம்', 'kn': 'ಹಿಮಾಚಲ ಪ್ರದೇಶ', 'ml': 'ഹിമാചൽ പ്രദേശ്', 'gu': 'હિમાચલ પ્રદેશ',
      'pa': 'ਹਿਮਾਚਲ ਪ੍ਰਦੇਸ਼', 'or': 'ହିମାଚଳ ପ୍ରଦେଶ', 'as': 'হিমাচল প্ৰদেশ',
    },
    'Jharkhand': {
      'hi': 'झारखंड', 'mr': 'झारखंड', 'bn': 'ঝাড়খণ্ড', 'te': 'జార్ఖండ్',
      'ta': 'ஜார்கண்ட்', 'kn': 'ಜಾರ್ಖಂಡ್', 'ml': 'ജാർഖണ്ഡ്', 'gu': 'ઝારખંડ',
      'pa': 'ਝਾਰਖੰਡ', 'or': 'ଝାଡ଼ଖଣ୍ଡ', 'as': 'ঝাৰখণ্ড',
    },
    'Uttarakhand': {
      'hi': 'उत्तराखंड', 'mr': 'उत्तराखंड', 'bn': 'উত্তরাখণ্ড', 'te': 'ఉత్తరాఖండ్',
      'ta': 'உத்தரகாண்ட்', 'kn': 'ಉತ್ತರಾಖಂಡ', 'ml': 'ഉത്തരാഖണ്ഡ്', 'gu': 'ઉત્તરાખંડ',
      'pa': 'ਉੱਤਰਾਖੰਡ', 'or': 'ଉତ୍ତରାଖଣ୍ଡ', 'as': 'উত্তৰাখণ্ড',
    },
    'Meghalaya': {
      'hi': 'मेघालय', 'mr': 'मेघालय', 'bn': 'মেঘালয়', 'te': 'మేఘాలయ',
      'ta': 'மேகாலயா', 'kn': 'ಮೇಘಾಲಯ', 'ml': 'മേഘാലയ', 'gu': 'મેઘાલય',
      'pa': 'ਮੇਘਾਲਿਆ', 'or': 'ମେଘାଳୟ', 'as': 'মেঘালয়',
    },
    'Arunachal Pradesh': {
      'hi': 'अरुणाचल प्रदेश', 'mr': 'अरुणाचल प्रदेश', 'bn': 'অরুণাচল প্রদেশ', 'te': 'అరుణాచల్ ప్రదేశ్',
      'ta': 'அருணாச்சலப் பிரதேசம்', 'kn': 'ಅರುಣಾಚಲ ಪ್ರದೇಶ', 'ml': 'അരുണാചൽ പ്രദേശ്', 'gu': 'અરુણાચલ પ્રદેશ',
      'pa': 'ਅਰੁਣਾਂਚਲ ਪ੍ਰਦੇਸ਼', 'or': 'ଅରୁଣାଚଳ ପ୍ରଦେଶ', 'as': 'অৰুণাচল প্ৰদেশ',
    },
    'Nagaland': {
      'hi': 'नागालैंड', 'mr': 'नागालँड', 'bn': 'নাগাল্যান্ড', 'te': 'నాగాలాండ్',
      'ta': 'நாகாலாந்து', 'kn': 'ನಾಗಾಲ್ಯಾಂಡ್', 'ml': 'നാഗാലാൻഡ്', 'gu': 'નાગાલેન્ડ',
      'pa': 'ਨਾਗਾਲੈਂਡ', 'or': 'ନାଗାଲାଣ୍ଡ', 'as': 'নাগালেণ্ড',
    },
    'Tripura': {
      'hi': 'त्रिपुरा', 'mr': 'त्रिपुरा', 'bn': 'ত্রিপুরা', 'te': 'త్రిపుర',
      'ta': 'திரிபுரா', 'kn': 'ತ್ರಿಪುರ', 'ml': 'ത്രിപുര', 'gu': 'ત્રિપુરા',
      'pa': 'ਤ੍ਰਿਪੁਰਾ', 'or': 'ତ୍ରିପୁରା', 'as': 'ত্ৰিপুৰা',
    },
    'Manipur': {
      'hi': 'मणिपुर', 'mr': 'मणिपूर', 'bn': 'মণিপুর', 'te': 'మణిపూర్',
      'ta': 'மணிப்பூர்', 'kn': 'ಮಣಿಪುರ', 'ml': 'മണിപ്പൂർ', 'gu': 'મણિપુર',
      'pa': 'ਮਣੀਪੁਰ', 'or': 'ମଣିପୁର', 'as': 'মণিপুৰ',
    },
    'Mizoram': {
      'hi': 'मिजोरम', 'mr': 'मिझोराम', 'bn': 'মিজোরাম', 'te': 'మిజోరం',
      'ta': 'மிசோரம்', 'kn': 'ಮಿಜೋರಾಂ', 'ml': 'മിസോറാം', 'gu': 'મિઝોરમ',
      'pa': 'ਮਿਜ਼ੋਰਮ', 'or': 'ମਿଜୋਰਾਮ', 'as': 'মিজোৰাম',
    },
    'Puducherry': {
      'hi': 'पुडुचेरी', 'mr': 'पुडुचेरी', 'bn': 'পুদুচেরি', 'te': 'పుదుచ్చేరి',
      'ta': 'புதுச்சேரி', 'kn': 'ಪುದುಚೇರಿ', 'ml': 'പുതുച്ചേരി', 'gu': 'પુડુચેરી',
      'pa': 'ਪੁਡੂਚੇਰੀ', 'or': 'ପୁଡୁଚେରୀ', 'as': 'পুডুচেৰী',
    },
    'Chandigarh': {
      'hi': 'चंडीगढ़', 'mr': 'चंदिगढ', 'bn': 'চণ্ডীগড়', 'te': 'చండీగఢ్',
      'ta': 'சண்டிகர்', 'kn': 'ಚಂಡೀಗಢ', 'ml': 'ചണ്ഡീഗഡ്', 'gu': 'ચંદીગઢ',
      'pa': 'ਚੰਡੀਗੜ੍ਹ', 'or': 'ଚଣ୍ଡିଗଡ଼', 'as': 'চণ্ডীগড়',
    },
    'Goa': {
      'hi': 'गोवा', 'mr': 'गोवा', 'bn': 'গোয়া', 'te': 'గోవా',
      'ta': 'கோவா', 'kn': 'ಗೋವಾ', 'ml': 'ഗോവ', 'gu': 'ગોવા',
      'pa': 'ਗੋਆ', 'or': 'ଗୋଆ', 'as': 'গোৱা',
    },
    'A & N Islands': {
      'hi': 'अंडमान और निकोबार', 'mr': 'अंदमान आणि निकोबार', 'bn': 'আন্দামান ও নিকোবর', 'te': 'అండమాన్ నికోబార్',
      'ta': 'அந்தமான் & நிக்கோபார்', 'kn': 'ಅಂಡಮಾನ್ & ನಿಕೋಬಾರ್', 'ml': 'ആൻഡമാൻ & നിക്കോബാർ', 'gu': 'અંદમાન અને નિકોબાર',
      'pa': 'ਅੰਡੇਮਾਨ ਅਤੇ ਨਿਕੋਬਾਰ', 'or': 'ଆଣ୍ଡାମାନ ଓ ନିକୋବର', 'as': 'আন্দামান আৰু নিকোবৰ',
    },
    'Sikkim': {
      'hi': 'सिक्किम', 'mr': 'सिक्कीम', 'bn': 'সিকিম', 'te': 'సిక్కిಂ',
      'ta': 'சிக்கிம்', 'kn': 'ಸಿಕ್ಕಿಂ', 'ml': 'സിക്കിം', 'gu': 'સિક્કિમ',
      'pa': 'ਸਿੱਕਮ', 'or': 'ସିକିମ', 'as': 'ছিকিম',
    },
  };
  return states[name]?[lang] ?? name;
}

String _localizeMapLabel(String name, String lang) {
  if (lang == 'en') return name;

  const termMap = <String, Map<String, String>>{
    'UPHC': {
      'mr': 'नागरी प्रा.आ. केंद्र', 'hi': 'शहरी प्रा.स्वा. केंद्र', 'bn': 'ইউপিএইচসি', 'te': 'పట్టణ పిహెచ్‌సి',
      'ta': 'நகர்ப்புற ஆரம்ப சுகாதார நிலையம்', 'kn': 'ನಗರ ಪ್ರಾಥಮಿಕ ಆರೋಗ್ಯ ಕೇಂದ್ರ', 'ml': 'യുപിഎച്ച്സി', 'gu': 'શહેરી પીએચસી',
      'pa': 'ਯੂਪੀਐਚਸੀ', 'or': 'ୟୁପିଏଚସି', 'as': 'ইউপিএইচচি',
    },
    'CHC': {
      'mr': 'सामुदायिक आरोग्य केंद्र', 'hi': 'सामुदायिक स्वास्थ्य केंद्र', 'bn': 'কমিউনিটি স্বাস্থ্য কেন্দ্র', 'te': 'సామాజిక ఆరోగ్య కేంద్రం',
      'ta': 'சமூக சுகாதார மையம்', 'kn': 'ಸಮುದಾಯ ಆರೋಗ್ಯ ಕೇಂದ್ರ', 'ml': 'സാമൂഹിക ആരോഗ്യ കേന്ദ്രം', 'gu': 'સામુદાયિક આરોગ્ય કેન્દ્ર',
      'pa': 'ਕਮਿਊਨਿਟੀ ਸਿਹਤ ਕੇਂਦਰ', 'or': 'ଗୋଷ୍ଠୀ ସ୍ୱାସ୍ଥ୍ୟ କେନ୍ଦ୍ର', 'as': 'সামূহিক স্বাস্থ্য কেন্দ্ৰ',
    },
    'PHC': {
      'mr': 'प्राथमिक आरोग्य केंद्र', 'hi': 'प्राथमिक स्वास्थ्य केंद्र', 'bn': 'প্রাথমিক স্বাস্থ্য কেন্দ্র', 'te': 'ప్రాథమిక ఆరోగ్య కేంద్రం',
      'ta': 'ஆரம்ப சுகாதார நிலையம்', 'kn': 'ಪ್ರಾಥಮಿಕ ಆರೋಗ್ಯ ಕೇಂದ್ರ', 'ml': 'പ്രാഥമിക ആരോഗ്യ കേന്ദ്രം', 'gu': 'પ્રાથમિક આરોગ્ય કેન્દ્ર',
      'pa': 'ਪ੍ਰਾਇਮਰੀ ਸਿਹਤ ਕੇਂਦਰ', 'or': 'ପ୍ରାଥମିକ ସ୍ୱାସ୍ଥ୍ୟ କେନ୍ଦ୍ର', 'as': 'প্ৰাথমিক স্বাস্থ্য কেন্দ্ৰ',
    },
    'Sub-centre': {
      'mr': 'उप-आरोग्य केंद्र', 'hi': 'उप-स्वास्थ्य केंद्र', 'bn': 'উপ-স্বাস্থ্য কেন্দ্র', 'te': 'ఉప-కేంద్రం',
      'ta': 'துணை சுகாதார நிலையம்', 'kn': 'ಉಪ ಕೇಂದ್ರ', 'ml': 'ഉപകേന്ദ്രം', 'gu': 'પેટા-આરોગ્ય કેન્દ્ર',
      'pa': 'ਉਪ-ਸਿਹਤ ਕੇਂਦਰ', 'or': 'ଉପ-ସ୍ୱାସ୍ଥ୍ୟ କେନ୍ଦ୍ର', 'as': 'উপ-স্বাস্থ্য কেন্দ্ৰ',
    },
    'Sub-Centre': {
      'mr': 'उप-आरोग्य केंद्र', 'hi': 'उप-स्वास्थ्य केंद्र', 'bn': 'উপ-स्वास्थ्य केंद्र', 'te': 'ఉప-కేంద్రం',
      'ta': 'துணை சுகாதார நிலையம்', 'kn': 'ಉಪ ಕೇಂದ್ರ', 'ml': 'ഉപകേന്ദ്രം', 'gu': 'પેટા-આરોગ્ય કેન્દ્ર',
      'pa': 'ਉਪ-ਸਿਹਤ ਕੇਂਦਰ', 'or': 'ଉପ-ସ୍ୱାସ୍ଥ୍ୟ କେନ୍ଦ୍ର', 'as': 'উপ-স্বাস্থ্য কেন্দ্ৰ',
    },
    'General hospital': {
      'mr': 'सामान्य रुग्णालय', 'hi': 'सामान्य अस्पताल', 'bn': 'জেনারেল হাসপাতাল', 'te': 'జనరల్ ఆసుపత్రి',
      'ta': 'பொது மருத்துவமனை', 'kn': 'ಜನರಲ್ ಆಸ್ಪತ್ರೆ', 'ml': 'ജനറൽ ആശുപത്രി', 'gu': 'જનરલ હોસ્પિટલ',
      'pa': 'ਜਨਰਲ ਹਸਪਤਾਲ', 'or': 'ସାଧାରଣ ଡାକ୍ତରଖାନା', 'as': 'সাধাৰণ চিকিৎসালয়',
    },
    'General Hospital': {
      'mr': 'सामान्य रुग्णालय', 'hi': 'सामान्य अस्पताल', 'bn': 'জেনারেল হাসপাতাল', 'te': 'జనరల్ ఆసుపత్రి',
      'ta': 'பொது மருத்துவமனை', 'kn': 'ಜನರಲ್ ಆಸ್ಪತ್ರೆ', 'ml': 'ജനറൽ ആശുപത്രി', 'gu': 'જનરલ હોસ્પિટલ',
      'pa': 'ਜਨਰਲ ਹਸਪਤਾਲ', 'or': 'ସାଧାରଣ ଡାକ୍ତରଖାନା', 'as': 'সাধাৰণ চিকিৎসালয়',
    },
    'Hospital': {
      'mr': 'रुग्णालय', 'hi': 'अस्पताल', 'bn': 'হাসপাতাল', 'te': 'ఆసుపత్రి',
      'ta': 'மருத்துவமனை', 'kn': 'ಆಸ್ಪತ್ರೆ', 'ml': 'ആശുപത്രി', 'gu': 'હોસ્પિટલ',
      'pa': 'ਹਸਪਤਾਲ', 'or': 'ଡାକ୍ତରଖାନା', 'as': 'চিকিৎসালয়',
    },
    'Dispensary': {
      'mr': 'दवाखाना', 'hi': 'दवाखाना', 'bn': 'ডিসপেনসারি', 'te': 'డిస్పెన్సరీ',
      'ta': 'மருந்தகம்', 'kn': 'ಔಷಧಾಲಯ', 'ml': 'ഡിസ്പെൻസറി', 'gu': 'દવાખાનું',
      'pa': 'ਡਿਸਪੈਂਸਰੀ', 'or': 'ଚିକିତ୍ସାଳୟ', 'as': 'ডিচপেনচাৰী',
    },
    'Diagnostic lab': {
      'mr': 'निदान प्रयोगशाळा', 'hi': 'निदान प्रयोगशाला', 'bn': 'ডায়াগনস্টিক ল্যাব', 'te': 'డయాగ్నస్టిక్ ల్యాబ్',
      'ta': 'பரிசோதனை மையம்', 'kn': 'ಡಯಾಗ್ನೋಸ್ಟಿಕ್ ಲ್ಯಾಬ್', 'ml': 'ഡയഗ്നോസ്റ്റിക് ലാബ്', 'gu': 'નિદાન પ્રયોગશાળા',
      'pa': 'ਡਾਇਗਨੋਸਟਿਕ ਲੈਬ', 'or': 'ନିଦାନ ପରୀକ୍ଷାଗାର', 'as': 'ডায়াগনষ্টিক লেব',
    },
    'Diagnostic Lab': {
      'mr': 'निदान प्रयोगशाळा', 'hi': 'निदान प्रयोगशाला', 'bn': 'ডায়াগনস্টিক ল্যাব', 'te': 'డయాగ్నస్టిక్ ల్యాబ్',
      'ta': 'பரிசோதனை மையம்', 'kn': 'ಡಯಾಗ್ನೋಸ್ಟಿಕ್ ಲ್ಯಾಬ್', 'ml': 'ഡയഗ്നോസ്റ്റിക് ലാബ്', 'gu': 'નિદાન પ્રયોગશાળા',
      'pa': 'ਡਾਇਗਨੋਸਟਿਕ ਲੈਬ', 'or': 'ନିଦାନ ପରୀକ୍ଷାଗାର', 'as': 'ডায়াগনষ্টিক লেব',
    },
    'Blood bank': {
      'mr': 'रक्तपेढी', 'hi': 'रक्त बैंक', 'bn': 'ব্লাড ব্যাংক', 'te': 'రక్త నిధి',
      'ta': 'இரத்த வங்கி', 'kn': 'ರಕ್ತ ನಿಧಿ', 'ml': 'ബ്ലഡ് ബാങ്ക്', 'gu': 'બ્લડ બેંક',
      'pa': 'ਬਲੱਡ ਬੈਂਕ', 'or': 'ରକ୍ତ ଭଣ୍ଡାର', 'as': 'ব্লাড বেংক',
    },
    'Blood Bank': {
      'mr': 'रक्तपेढी', 'hi': 'रक्त बैंक', 'bn': 'ব্লাড ব্যাংক', 'te': 'రక్త నిధి',
      'ta': 'இரத்த வங்கி', 'kn': 'ರಕ್ತ ನಿಧಿ', 'ml': 'ബ്ലഡ് ബാങ്ക്', 'gu': 'બ્લડ બેંક',
      'pa': 'ਬਲੱਡ ਬੈਂਕ', 'or': 'ରକ୍ତ ଭଣ୍ଡାର', 'as': 'ব্লাড বেংক',
    },
    'Janaushadhi Kendra': {
      'mr': 'जन औषधी केंद्र', 'hi': 'जन औषधि केंद्र', 'bn': 'জন ঔষধ কেন্দ্র', 'te': 'జన ఔషధి కేంద్రం',
      'ta': 'ஜன் ஔஷதி மையம்', 'kn': 'ಜನ ಔಷಧಿ ಕೇಂದ್ರ', 'ml': 'ജൻ ഔഷധി കേന്ദ്രം', 'gu': 'જન ઔષધિ કેન્દ્ર',
      'pa': 'ਜਨ ਔਸ਼ਧੀ ਕੇਂਦਰ', 'or': 'ଜନ ଔଷଧି କେନ୍ଦ୍ର', 'as': 'জন ঔষধি কেন্দ্ৰ',
    },
    'Anganwadi': {
      'mr': 'अंगणवाडी', 'hi': 'आंगनवाड़ी', 'bn': 'অঙ্গনওয়াড়ি', 'te': 'అంగన్‌వాడీ',
      'ta': 'அங்கன்வாடி', 'kn': 'ಅಂಗನವಾಡಿ', 'ml': 'അങ്കണവാടി', 'gu': 'આંગણવાડી',
      'pa': 'ਆਂਗਣਵਾੜੀ', 'or': 'ଅଙ୍ଗନୱାଡ଼ି', 'as': 'অংগনৱাড়ী',
    },
    'Block office': {
      'mr': 'गट कार्यालय', 'hi': 'ब्लॉक कार्यालय', 'bn': 'ব্লক অফিস', 'te': 'బ్లాక్ కార్యాలయం',
      'ta': 'வட்டார அலுவலகம்', 'kn': 'ಬ್ಲಾಕ್ ಕಚೇರಿ', 'ml': 'ബ്ലോക്ക് ഓഫീസ്', 'gu': 'બ્લોક કચેરી',
      'pa': 'ਬਲਾਕ ਦਫ਼ਤਰ', 'or': 'ବ୍ଲକ କାର୍ଯ୍ୟାଳୟ', 'as': 'ব্লক কাৰ্যালয়',
    },
    'Panchayat office': {
      'mr': 'ग्रामपंचायत कार्यालय', 'hi': 'पंचायत कार्यालय', 'bn': 'পঞ্চায়েত অফিস', 'te': 'పంచాయతీ కార్యాలయం',
      'ta': 'பஞ்சாயத்து அலுவலகம்', 'kn': 'ಪಂಚಾಯತ್ ಕಚೇರಿ', 'ml': 'പഞ്ചായത്ത് ഓഫീസ്', 'gu': 'પંચાયત કચેરી',
      'pa': 'ਪੰਚਾਇਤ ਦਫ਼ਤਰ', 'or': 'ପଞ୍ଚାୟତ କାର୍ଯ୍ୟାଳୟ', 'as': 'পঞ্চায়ত কাৰ্যালয়',
    },
    'Police station': {
      'mr': 'पोलीस ठाणे', 'hi': 'पुलिस थाना', 'bn': 'পুলিশ স্টেশন', 'te': 'పోలీస్ స్టేషన్',
      'ta': 'காவல் நிலையம்', 'kn': 'ಪೊಲೀಸ್ ಠಾಣೆ', 'ml': 'പോലീസ് സ്റ്റേഷൻ', 'gu': 'પોલીસ સ્ટેશન',
      'pa': 'ਪੁਲਿਸ ਥਾਣਾ', 'or': 'ଥାନା', 'as': 'আৰক্ষী থানা',
    },
    'Ration shop': {
      'mr': 'रेशन दुकान', 'hi': 'राशन दुकान', 'bn': 'রেশন দোকান', 'te': 'రేషన్ షాపు',
      'ta': 'ரேஷன் கடை', 'kn': 'ಪಡಿತರ ಅಂಗಡಿ', 'ml': 'റേഷൻ കട', 'gu': 'રેશનની દુકાન',
      'pa': 'ਰਾਸ਼ਨ ਦੀ ਦੁਕਾਨ', 'or': 'ରାସନ ଦୋକାନ', 'as': 'ৰেচনৰ দোকান',
    },
    'Road': {
      'mr': 'रस्ता', 'hi': 'मार्ग', 'bn': 'রোড', 'te': 'రోడ్డు', 'ta': 'சாலை', 'kn': 'ರಸ್ತೆ', 'ml': 'റോഡ്', 'gu': 'રોડ', 'pa': 'ਰੋਡ', 'or': 'ରାସ୍ତା', 'as': 'পথ',
    },
    'Flyover': {
      'mr': 'उड्डाणपूल', 'hi': 'फ्लाईओवर', 'bn': 'ফ্লাইওভার', 'te': 'ఫ్లైఓవర్', 'ta': 'மேம்பாலம்', 'kn': 'ಮೇಲ್ಸೇತುವೆ', 'ml': 'ഫ്ലൈഓവർ', 'gu': 'ફ્લાયઓવર', 'pa': 'ਫਲਾਈਓਵਰ', 'or': 'ଫ୍ଲାଏଓଭର', 'as': 'উৰণীয়া সেতু',
    },
    'Bridge': {
      'mr': 'पूल', 'hi': 'पुल', 'bn': 'সেতু', 'te': 'వంతెన', 'ta': 'பாலம்', 'kn': 'ಸೇತುವೆ', 'ml': 'പാലം', 'gu': 'પુલ', 'pa': 'ਪੁਲ', 'or': 'ପୋଲ', 'as': 'দলং',
    },
    'Chowk': {
      'mr': 'चौक', 'hi': 'चौक', 'bn': 'চক', 'te': 'చౌక్', 'ta': 'சந்திப்பு', 'kn': 'ಚೌಕ', 'ml': 'ചൗക്ക്', 'gu': 'ચોક', 'pa': 'ਚੌਕ', 'or': 'ଛକ', 'as': 'চক',
    },
    'Underpass': {
      'mr': 'भुयारी मार्ग', 'hi': 'अंडरपास', 'bn': 'আন্ডারপাস', 'te': 'అండర్‌పాస్', 'ta': 'சுரங்கப்பாதை', 'kn': 'ಕೆಳಸೇತುವೆ', 'ml': 'അണ്ടർപാസ്', 'gu': 'અંડરપાસ', 'pa': 'ਅੰਡਰਪਾਸ', 'or': 'ଅଣ୍ଡରପାସ୍', 'as': 'আণ্ডাৰপাছ',
    },
  };

  var result = name;
  for (final entry in termMap.entries) {
    if (result.contains(entry.key)) {
      final replacement = entry.value[lang] ?? entry.key;
      result = result.replaceAll(entry.key, replacement);
    }
  }
  return result;
}

String _localizeHouseholdName(String name, String lang) {
  if (lang == 'en') return name;
  const householdMap = <String, Map<String, String>>{
    'Demo household near': {
      'mr': 'प्रात्यक्षिक घर जवळ', 'hi': 'डेमो घर पास', 'bn': 'নমুনা বাড়ি কাছাকাছি', 'te': 'నమూనా ఇల్లు సమీపంలో',
      'ta': 'மாதிரி வீடு அருகில்', 'kn': 'ಮಾದರಿ ಮನೆ ಹತ್ತಿರ', 'ml': 'മാതൃകാ വീട് അടുത്ത്', 'gu': 'ડેમો ઘર નજીક',
      'pa': 'ਡੈਮੋ ਘਰ ਨੇੜੇ', 'or': 'ନମୁନା ଘର ନିକଟ', 'as': 'নমুনা ঘৰ ওচৰত',
    },
    'Demo household mid': {
      'mr': 'प्रात्यक्षिक घर मध्यम', 'hi': 'डेमो घर मध्यम', 'bn': 'নমুনা বাড়ি মধ্যবর্তী', 'te': 'నమూనా ఇల్లు మధ్యస్థ',
      'ta': 'மாதிரி வீடு நடுவில்', 'kn': 'ಮಾದರಿ ಮನೆ ಮಧ್ಯಮ', 'ml': 'മാതൃകാ വീട് മധ്യേ', 'gu': 'ડેમો ઘર મધ્યમ',
      'pa': 'ਡੈਮੋ ਘਰ ਮੱਧ', 'or': 'ନମୁନା ଘର ମଧ୍ୟମ', 'as': 'নমুনা ঘৰ মধ্যম',
    },
    'Demo household far': {
      'mr': 'प्रात्यक्षिक घर दूर', 'hi': 'डेमो घर दूर', 'bn': 'নমুনা বাড়ি দূরে', 'te': 'నమూనా ఇల్లు దూరంగా',
      'ta': 'மாதிரி வீடு தொலைவில்', 'kn': 'ಮಾದರಿ ಮನೆ ದೂರ', 'ml': 'മാതൃകാ വീട് ദൂരെ', 'gu': 'ડેમો ઘર દૂર',
      'pa': 'ਡੈਮੋ ਘਰ ਦੂਰ', 'or': 'ନମୁନା ଘର ଦୂର', 'as': 'নমুনা ঘৰ দূৰত',
    },
  };
  if (householdMap.containsKey(name)) {
    return householdMap[name]![lang] ?? name;
  }
  const termMap = <String, Map<String, String>>{
    'Household': {
      'mr': 'घर', 'hi': 'घर', 'bn': 'বাড়ি', 'te': 'ఇల్లు', 'ta': 'வீடு', 'kn': 'ಮನೆ', 'ml': 'വീട്', 'gu': 'ઘર', 'pa': 'ਘਰ', 'or': 'ଘର', 'as': 'ঘৰ',
    },
    'household': {
      'mr': 'घर', 'hi': 'घर', 'bn': 'বাড়ি', 'te': 'ఇల్లు', 'ta': 'வீடு', 'kn': 'ಮನೆ', 'ml': 'വീട്', 'gu': 'ઘર', 'pa': 'ਘਰ', 'or': 'ଘର', 'as': 'ঘৰ',
    },
  };
  var result = name;
  for (final entry in termMap.entries) {
    if (result.contains(entry.key)) {
      result = result.replaceAll(entry.key, entry.value[lang] ?? entry.key);
    }
  }
  return result;
}

String _localizeDue(String due, String lang) {
  if (lang == 'en') return due;
  const duesMap = <String, Map<String, String>>{
    'follow-up': {
      'mr': 'पुढील तपासणी', 'hi': 'फॉलो-अप', 'bn': 'ফলো-আপ', 'te': 'ఫాలో-అప్', 'ta': 'பின்தொடர்தல்',
      'kn': 'ಫಾಲೋ-ಅಪ್', 'ml': 'ഫോളോ-അപ്പ്', 'gu': 'ફોલો-અપ', 'pa': 'ਫਾਲੋ-ਅੱਪ', 'or': 'ଅନୁବର୍ତ୍ତୀ ଯାଞ୍ଚ', 'as': 'ফলো-আপ',
    },
    'ANC': {
      'mr': 'प्रसूतीपूर्व तपासणी (ANC)', 'hi': 'प्रसवपूर्व जांच (ANC)', 'bn': 'প্রসবপূর্ব যত্ন (ANC)',
      'te': 'ప్రసవపూర్వ సంరక్షణ (ANC)', 'ta': 'மகப்பேறுக்கு முந்தைய பராமரிப்பு (ANC)', 'kn': 'ಪ್ರಸವಪೂರ್ವ ಆರೈಕೆ (ANC)',
      'ml': 'പ്രസവത്തിനു മുമ്പുള്ള പരിചരണം (ANC)', 'gu': 'પ્રસવપૂર્વ તપાસ (ANC)', 'pa': 'ਜਣੇਪੇ ਤੋਂ ਪਹਿਲਾਂ ਦੀ ਦੇਖਭਾਲ (ANC)',
      'or': 'ପ୍ରସବପୂର୍ବ ଯତ୍ନ (ANC)', 'as': 'প্ৰসৱপূৰ্ব যত্ন (ANC)',
    },
    'PNC': {
      'mr': 'प्रसूतीनंतरची तपासणी (PNC)', 'hi': 'प्रसवोत्तर जांच (PNC)', 'bn': 'প্রসবোত্তর যত্ন (PNC)',
      'te': 'ప్రసవానంతర సంరక్షణ (PNC)', 'ta': 'மகப்பேற்றுக்கு பிந்தைய பராமரிப்பு (PNC)', 'kn': 'ಪ್ರಸವೋತ್ತರ ಆರೈಕೆ (PNC)',
      'ml': 'പ്രസവാനന്തര പരിചരണം (PNC)', 'gu': 'પ્રસવોત્તર તપાસ (PNC)', 'pa': 'ਜਣੇਪੇ ਤੋਂ ਬਾਅਦ ਦੀ ਦੇਖਭਾਲ (PNC)',
      'or': 'ପ୍ରସବୋତ୍ତର ଯତ୍ନ (PNC)', 'as': 'প্ৰসৱোত্তৰ যত্ন (PNC)',
    },
    'immunization': {
      'mr': 'लसीकरण', 'hi': 'टीकाकरण', 'bn': 'টিকাদান', 'te': 'టీకా', 'ta': 'தடுப்பூசி',
      'kn': 'ಲಸಿಕೆ', 'ml': 'പ്രതിരോധ കുത്തിവയ്പ്പ്', 'gu': 'રસીકરણ', 'pa': 'ਟੀਕਾਕਰਨ', 'or': 'ଟୀକାକରଣ', 'as': 'টীকাকৰণ',
    },
    'overdue': {
      'mr': 'प्रलंबित', 'hi': 'विलंबित', 'bn': 'বকেয়া', 'te': 'గడువు ముగిసింది', 'ta': 'தாமதமானது',
      'kn': 'ಬಾಕಿ ಉಳಿದಿದೆ', 'ml': 'കാലഹരണപ്പെട്ടു', 'gu': 'બાકી', 'pa': 'ਬਕਾਇਆ', 'or': 'ବକେୟା', 'as': 'বকেয়া',
    },
  };
  return duesMap[due]?[lang] ?? due;
}

String _categoryLabel(String category, [String lang = 'en']) =>
    _localizeCategoryLabel(category, lang);

String _localizeCategoryLabel(String category, [String lang = 'en']) {
  if (lang == 'en') {
    return switch (category.toLowerCase()) {
      'phc' => 'PHC',
      'chc' => 'CHC',
      'hospital' || 'dh' => 'Hospital',
      'blood_bank' => 'Blood Bank',
      'nrc' => 'NRC',
      'deic' => 'DEIC',
      'antivenom' => 'Antivenom',
      'ab_hwc' => 'AB-HWC',
      'pmjay' => 'PM-JAY',
      'anganwadi' => 'Anganwadi',
      'sub_centre' || 'subcentre' => 'Sub-centre',
      'lab' => 'Diagnostic Lab',
      'all' => 'Facilities',
      _ => category
          .replaceAll('_', ' ')
          .split(' ')
          .map(
            (word) => word.isEmpty
                ? word
                : '${word[0].toUpperCase()}${word.substring(1)}',
          )
          .join(' '),
    };
  }

  const catMap = <String, Map<String, String>>{
    'all': {
      'mr': 'आरोग्य सुविधा', 'hi': 'स्वास्थ्य सुविधाएं', 'bn': 'স্বাস্থ্য সুবিধা', 'te': 'ఆరోగ్య సదుపాయాలు',
      'ta': 'சுகாதார வசதிகள்', 'kn': 'ಆರೋಗ್ಯ ಸೌಲಭ್ಯಗಳು', 'ml': 'ആരോഗ്യ സൗകര്യങ്ങൾ', 'gu': 'આરોગ્ય સુવિધાઓ',
      'pa': 'ਸਿਹਤ ਸਹੂਲਤਾਂ', 'or': 'ସ୍ୱାସ୍ଥ୍ୟ ସୁବିଧା', 'as': 'স্বাস্থ্য সুবিধা',
    },
    'phc': {
      'mr': 'प्रा.आ. केंद्र (PHC)', 'hi': 'प्रा.स्वा. केंद्र (PHC)', 'bn': 'পিএইচসি', 'te': 'పిహెచ్‌సి',
      'ta': 'ஆரம்ப சுகாதார நிலையம்', 'kn': 'ಪ್ರಾಥಮಿಕ ಆರೋಗ್ಯ ಕೇಂದ್ರ', 'ml': 'പിഎച്ച്സി', 'gu': 'પીએચસી',
      'pa': 'ਪੀਐਚਸੀ', 'or': 'ପିଏଚସି', 'as': 'পিএইচচি',
    },
    'chc': {
      'mr': 'सा.आ. केंद्र (CHC)', 'hi': 'सामुदायिक स्वास्थ्य केंद्र (CHC)', 'bn': 'সিএইচসি', 'te': 'సిహెచ్‌సి',
      'ta': 'சமூக சுகாதார மையம்', 'kn': 'ಸಮುದಾಯ ಆರೋಗ್ಯ ಕೇಂದ್ರ', 'ml': 'സിഎച്ച്സി', 'gu': 'સીએચસી',
      'pa': 'ਸੀਐਚਸੀ', 'or': 'ସିଏଚସି', 'as': 'চিএইচচি',
    },
    'hospital': {
      'mr': 'रुग्णालय', 'hi': 'अस्पताल', 'bn': 'হাসপাতাল', 'te': 'ఆసుపత్రి',
      'ta': 'மருத்துவமனை', 'kn': 'ಆಸ್ಪತ್ರೆ', 'ml': 'ആശുപത്രി', 'gu': 'હોસ્પિટલ',
      'pa': 'ਹਸਪਤਾਲ', 'or': 'ଡାକ୍ତରଖାନା', 'as': 'চিকিৎসালয়',
    },
    'dh': {
      'mr': 'जिल्हा रुग्णालय', 'hi': 'जिला अस्पताल', 'bn': 'জেলা হাসপাতাল', 'te': 'జిల్లా ఆసుపత్రి',
      'ta': 'மாவட்ட மருத்துவமனை', 'kn': 'ಜಿಲ್ಲಾ ಆಸ್ಪತ್ರೆ', 'ml': 'ജില്ലാ ആശുപത്രി', 'gu': 'જિલ્લા હોસ્પિટલ',
      'pa': 'ਜ਼ਿਲ੍ਹਾ ਹਸਪਤਾਲ', 'or': 'ଜିଲ୍ଲା ଡାକ୍ତରଖାନା', 'as': 'জিলা চিকিৎসালয়',
    },
    'blood_bank': {
      'mr': 'रक्तपेढी', 'hi': 'रक्त बैंक', 'bn': 'ব্লাড ব্যাংক', 'te': 'రక్త నిధి',
      'ta': 'இரத்த வங்கி', 'kn': 'ರಕ್ತ ನಿಧಿ', 'ml': 'ബ്ലഡ് ബാങ്ക്', 'gu': 'બ્લડ બેંક',
      'pa': 'ਬਲੱਡ ਬੈਂਕ', 'or': 'ରକ୍ତ ଭଣ୍ଡାର', 'as': 'ব্লাড বেংক',
    },
    'nrc': {
      'mr': 'पोषण पुनर्वसन केंद्र (NRC)', 'hi': 'पोषण पुनर्वास केंद्र (NRC)', 'bn': 'এনআরসি', 'te': 'ఎన్‌ఆర్‌సి',
      'ta': 'ஊட்டச்சத்து மறுவாழ்வு மையம்', 'kn': 'ಪೌಷ್ಟಿಕಾಂಶ ಪುನರ್ವಸತಿ ಕೇಂದ್ರ', 'ml': 'എൻആർസി', 'gu': 'એનઆરસી',
      'pa': 'ਐਨਆਰਸੀ', 'or': 'ଏନଆରସି', 'as': 'এনআৰচি',
    },
    'antivenom': {
      'mr': 'सर्पदंश लस', 'hi': 'एंटीवेनम', 'bn': 'অ্যান্টিভেনম', 'te': 'యాంటీవెనమ్',
      'ta': 'பாம்புக்கடி மருந்து', 'kn': 'ಹಾವುಕಡಿತ ಲಸಿಕೆ', 'ml': 'ആന്റിവെനം', 'gu': 'એન્ટીવેનમ',
      'pa': 'ਐਂਟੀਵੈਨਮ', 'or': 'ଆଣ୍ଟିଭେନମ', 'as': 'এণ্টিভেনম',
    },
    'ab_hwc': {
      'mr': 'आरोग्य व कल्याण केंद्र (AB-HWC)', 'hi': 'आरोग्य व कल्याण केंद्र (AB-HWC)', 'bn': 'এবি-এইচডব্লিউসি',
      'te': 'ఆరోగ్య కేంద్రం (AB-HWC)', 'ta': 'சுகாதார நல மையம்', 'kn': 'ಆರೋಗ್ಯ ಕ್ಷೇಮ ಕೇಂದ್ರ',
      'ml': 'ആരോഗ്യ കേന്ദ്രം (AB-HWC)', 'gu': 'આરોગ્ય કેન્દ્ર (AB-HWC)', 'pa': 'ਤੰਦਰੁਸਤੀ ਕੇਂਦਰ',
      'or': 'ଆରୋଗ୍ୟ କେନ୍ଦ୍ର (AB-HWC)', 'as': 'আৰোগ্য কেন্দ্ৰ (AB-HWC)',
    },
    'deic': {
      'mr': 'विशेष बाल हस्तक्षेप केंद्र (DEIC)', 'hi': 'प्रारंभिक हस्तक्षेप केंद्र (DEIC)', 'bn': 'ডিইআইসি',
      'te': 'డిఇఐసి', 'ta': 'குழந்தை பராமரிப்பு மையம் (DEIC)', 'kn': 'ಆರಂಭಿಕ ಹಸ್ತಕ್ಷೇಪ ಕೇಂದ್ರ',
      'ml': 'ഡിഇআইസി', 'gu': 'ડીઈઆઈસી', 'pa': 'ਡੀਈਆਈਸੀ', 'or': 'ଡିଇଆଇସି', 'as': 'ডিইআইচি',
    },
    'pmjay': {
      'mr': 'आयुष्मान भारत (PM-JAY)', 'hi': 'आयुष्मान भारत (PM-JAY)', 'bn': 'পিএম-জেএওয়াই',
      'te': 'పిఎం-జెఎవై', 'ta': 'பிஎம்-ஜேஏஒய்', 'kn': 'ಪಿಎಂ-ಜೆಎವೈ', 'ml': 'പിഎം-ജെഎവൈ',
      'gu': 'પીએમ-જેએવાય', 'pa': 'ਪੀਐਮ-ਜੇਏਵਾਈ', 'or': 'ପିଏମ-ଜେଏୱାଇ', 'as': 'পিএম-জেএৱাই',
    },
    'anganwadi': {
      'mr': 'अंगणवाडी', 'hi': 'आंगनवाड़ी', 'bn': 'অঙ্গনওয়াড়ি', 'te': 'అంగన్‌వాడీ',
      'ta': 'அங்கன்வாடி', 'kn': 'ಅಂಗನವಾಡಿ', 'ml': 'അങ്കണവാടി', 'gu': 'આંગણવાડી',
      'pa': 'ਆਂਗਣਵਾੜੀ', 'or': 'ଅଙ୍ଗନୱାଡ଼ି', 'as': 'অংগনৱাড়ী',
    },
    'sub_centre': {
      'mr': 'उप-आरोग्य केंद्र', 'hi': 'उप-स्वास्थ्य केंद्र', 'bn': 'উপ-স্বাস্থ্য কেন্দ্র', 'te': 'ఉప-కేంద్రం',
      'ta': 'துணை சுகாதார நிலையம்', 'kn': 'ಉಪ ಕೇಂದ್ರ', 'ml': 'ഉപകേന്ദ്രം', 'gu': 'પેટા-આરોગ્ય કેન્દ્ર',
      'pa': 'ਉਪ-ਸਿਹਤ ਕੇਂਦਰ', 'or': 'ଉପ-ସ୍ୱାସ୍ଥ୍ୟ କେନ୍ଦ୍ର', 'as': 'উপ-স্বাস্থ্য কেন্দ্ৰ',
    },
    'lab': {
      'mr': 'निदान प्रयोगशाळा', 'hi': 'निदान प्रयोगशाला', 'bn': 'ডায়াগনস্টিক ল্যাব', 'te': 'డయాగ్నస్టిక్ ల్యాబ్',
      'ta': 'பரிசோதனை மையம்', 'kn': 'ಡಯಾಗ್ನೋಸ್ಟಿಕ್ ಲ್ಯಾಬ್', 'ml': 'ഡയഗ്നോസ്റ്റിക് ലാബ്', 'gu': 'નિદાન પ્રયોગશાળા',
      'pa': 'ਡਾਇਗਨੋਸਟਿਕ ਲੈਬ', 'or': 'ନିଦାନ ପରୀକ୍ଷାଗାର', 'as': 'ডায়াগনষ্টিক লেব',
    },
  };

  return catMap[category.toLowerCase()]?[lang] ??
      category
          .replaceAll('_', ' ')
          .split(' ')
          .map(
            (word) => word.isEmpty
                ? word
                : '${word[0].toUpperCase()}${word.substring(1)}',
          )
          .join(' ');
}

String _filterPillLabel(String key, String lang) {
  if (lang == 'en') {
    return switch (key) {
      'all' => 'Facilities',
      'phc' => 'PHC',
      'chc' => 'CHC',
      'blood_bank' => 'Blood Bank',
      'nrc' => 'NRC',
      'antivenom' => 'Antivenom',
      'ab_hwc' => 'AB-HWC',
      'deic' => 'DEIC',
      'pmjay' => 'PM-JAY',
      'radar' => 'Disease radar',
      'households' => 'Households',
      _ => key,
    };
  }

  const pillMap = <String, Map<String, String>>{
    'all': {
      'mr': 'सर्व सुविधा', 'hi': 'सभी सुविधाएं', 'bn': 'সব সুবিধা', 'te': 'అన్ని సదుపాయాలు', 'ta': 'அனைத்து வசதிகள்',
      'kn': 'ಎಲ್ಲಾ ಸೌಲಭ್ಯಗಳು', 'ml': 'എല്ലാ സൗകര്യങ്ങളും', 'gu': 'બધી સુવિધાઓ', 'pa': 'ਸਾਰੀਆਂ ਸਹੂਲਤਾਂ', 'or': 'ସମସ୍ତ ସୁବିଧା', 'as': 'সকলো সুবিধা',
    },
    'phc': {
      'mr': 'PHC', 'hi': 'PHC', 'bn': 'PHC', 'te': 'PHC', 'ta': 'PHC',
      'kn': 'PHC', 'ml': 'PHC', 'gu': 'PHC', 'pa': 'PHC', 'or': 'PHC', 'as': 'PHC',
    },
    'chc': {
      'mr': 'CHC', 'hi': 'CHC', 'bn': 'CHC', 'te': 'CHC', 'ta': 'CHC',
      'kn': 'CHC', 'ml': 'CHC', 'gu': 'CHC', 'pa': 'CHC', 'or': 'CHC', 'as': 'CHC',
    },
    'blood_bank': {
      'mr': 'रक्तपेढी', 'hi': 'रक्त बैंक', 'bn': 'ব্লাড ব্যাংক', 'te': 'రక్త నిధి',
      'ta': 'இரத்த வங்கி', 'kn': 'ರಕ್ತ ನಿಧಿ', 'ml': 'ബ്ലഡ് ബാങ്ക്', 'gu': 'બ્લડ બેંક',
      'pa': 'ਬਲੱਡ ਬੈਂਕ', 'or': 'ରକ୍ତ ଭଣ୍ଡାର', 'as': 'ব্লাড বেংক',
    },
    'nrc': {
      'mr': 'NRC', 'hi': 'NRC', 'bn': 'NRC', 'te': 'NRC', 'ta': 'NRC',
      'kn': 'NRC', 'ml': 'NRC', 'gu': 'NRC', 'pa': 'NRC', 'or': 'NRC', 'as': 'NRC',
    },
    'antivenom': {
      'mr': 'सर्पदंश लस', 'hi': 'एंटीवेनम', 'bn': 'অ্যান্টিভেনম', 'te': 'యాంటీవెనమ్',
      'ta': 'பாம்புக்கடி மருந்து', 'kn': 'ಹಾವುಕಡಿತ ಲಸಿಕೆ', 'ml': 'ആന്റിവെനം', 'gu': 'એન્ટીવેનમ',
      'pa': 'ਐਂਟੀਵੈਨਮ', 'or': 'ଆଣ୍ଟିଭେନମ', 'as': 'এণ্টিভেনম',
    },
    'ab_hwc': {
      'mr': 'AB-HWC', 'hi': 'AB-HWC', 'bn': 'AB-HWC', 'te': 'AB-HWC', 'ta': 'AB-HWC',
      'kn': 'AB-HWC', 'ml': 'AB-HWC', 'gu': 'AB-HWC', 'pa': 'AB-HWC', 'or': 'AB-HWC', 'as': 'AB-HWC',
    },
    'deic': {
      'mr': 'DEIC', 'hi': 'DEIC', 'bn': 'DEIC', 'te': 'DEIC', 'ta': 'DEIC',
      'kn': 'DEIC', 'ml': 'DEIC', 'gu': 'DEIC', 'pa': 'DEIC', 'or': 'DEIC', 'as': 'DEIC',
    },
    'pmjay': {
      'mr': 'PM-JAY', 'hi': 'PM-JAY', 'bn': 'PM-JAY', 'te': 'PM-JAY', 'ta': 'PM-JAY',
      'kn': 'PM-JAY', 'ml': 'PM-JAY', 'gu': 'PM-JAY', 'pa': 'PM-JAY', 'or': 'PM-JAY', 'as': 'PM-JAY',
    },
    'radar': {
      'mr': 'रोग रडार', 'hi': 'रोग रडार', 'bn': 'রোগ রাডার', 'te': 'వ్యాధి రాడార్',
      'ta': 'நோய் ரேடார்', 'kn': 'ರೋಗ ರೇಡಾರ್', 'ml': 'രോഗ റഡാർ', 'gu': 'રોગ રડાર',
      'pa': 'ਬਿਮਾਰੀ ਰਾਡਾਰ', 'or': 'ରୋଗ ରାଡାର୍', 'as': 'ৰোগ ৰাডাৰ',
    },
    'households': {
      'mr': 'घरे', 'hi': 'परिवार / घर', 'bn': 'পরিবারসমূহ', 'te': 'గృహాలు',
      'ta': 'குடும்பங்கள்', 'kn': 'ಮನೆಗಳು', 'ml': 'വീടുകൾ', 'gu': 'ઘરો',
      'pa': 'ਘਰ', 'or': 'ଘରଗୁଡ଼ିକ', 'as': 'ঘৰসমূহ',
    },
  };
  return pillMap[key]?[lang] ?? key;
}

String _localizeConditionLabel(String condition, [String lang = 'en']) {
  if (lang == 'en') {
    return switch (condition) {
      'dengue_like' => 'Dengue-like',
      'acute_diarrhoea' => 'Acute diarrhoea',
      'measles_like' => 'Measles-like',
      'aes' => 'AES',
      _ => 'Fever',
    };
  }

  const condMap = <String, Map<String, String>>{
    'dengue_like': {
      'mr': 'डेंग्यू-सदृश', 'hi': 'डेंगू-जैसे', 'bn': 'ডেঙ্গু-সদৃশ', 'te': 'డెంగ్యూ తరహా',
      'ta': 'டெங்கு போன்ற', 'kn': 'ಡೆಂಗ್ಯೂ ತರಹದ', 'ml': 'ഡെങ്കി പോലുള്ള', 'gu': 'ડેન્ગ્યુ જેવું',
      'pa': 'ਡੇਂਗੂ ਵਰਗਾ', 'or': 'ଡେଙ୍ଗୁ ଭଳି', 'as': 'ডেংগুৰ দৰে',
    },
    'acute_diarrhoea': {
      'mr': 'अतिसार', 'hi': 'डायरिया / अतिसार', 'bn': 'ডায়রিয়া', 'te': 'విరేచనాలు',
      'ta': 'வயிற்றுப்போக்கு', 'kn': 'ಅತಿಸಾರ', 'ml': 'വയറിളക്കം', 'gu': 'ઝાડા / અતિસાર',
      'pa': 'ਦਸਤ', 'or': 'ତରଳ ଝାଡ଼ା', 'as': 'হাগনি / ডায়েৰিয়া',
    },
    'measles_like': {
      'mr': 'गोवर-सदृश', 'hi': 'खसरा-जैसे', 'bn': 'হাম-সদৃশ', 'te': 'తట్టు తరహా',
      'ta': 'தட்டம்மை போன்ற', 'kn': 'ದಡಾರ ತರಹದ', 'ml': 'അഞ്ചാംപനി പോലുള്ള', 'gu': 'ઓરી જેવું',
      'pa': 'ਖਸਰਾ ਵਰਗਾ', 'or': 'ମିଳିମିଳା ଭଳି', 'as': 'হামৰ দৰে',
    },
    'aes': {
      'mr': 'AES', 'hi': 'AES', 'bn': 'AES', 'te': 'AES', 'ta': 'AES',
      'kn': 'AES', 'ml': 'AES', 'gu': 'AES', 'pa': 'AES', 'or': 'AES', 'as': 'AES',
    },
    'fever': {
      'mr': 'ताप', 'hi': 'बुखार', 'bn': 'জ্বর', 'te': 'జ్వరం', 'ta': 'காய்ச்சல்',
      'kn': 'ಜ್ವರ', 'ml': 'പനി', 'gu': 'તાવ', 'pa': 'ਬੁਖ਼ਾਰ', 'or': 'ଜ୍ୱର', 'as': 'জ্বৰ',
    },
  };
  return condMap[condition]?[lang] ?? condition;
}

String _callLabel(String lang) {
  if (lang == 'en') return 'Call';
  const map = {
    'mr': 'कॉल करा', 'hi': 'कॉल करें', 'bn': 'কল করুন', 'te': 'కాల్ చేయండి',
    'ta': 'அழைக்கவும்', 'kn': 'ಕರೆ ಮಾಡಿ', 'ml': 'വിളിക്കുക', 'gu': 'કૉલ કરો',
    'pa': 'ਕਾਲ ਕਰੋ', 'or': 'କଲ କରନ୍ତୁ', 'as': 'কল কৰক',
  };
  return map[lang] ?? 'Call';
}

String _pointMeLabel(String lang) {
  if (lang == 'en') return 'Point me';
  const map = {
    'mr': 'दिशा दाखवा', 'hi': 'दिशा दिखाएं', 'bn': 'দিকনির্দেশ', 'te': 'దిశ చూపించు',
    'ta': 'திசையைக் காட்டு', 'kn': 'ದಿಕ್ಕು ತೋರಿಸಿ', 'ml': 'ദിശ കാണിക്കുക', 'gu': 'દિશા બતાવો',
    'pa': 'ਦਿਸ਼ਾ ਦਿਖਾਓ', 'or': 'ଦିଗ ଦେଖାନ୍ତୁ', 'as': 'দিশ দেখুৱাওক',
  };
  return map[lang] ?? 'Point me';
}

String _todaysRouteLabel(String lang) {
  if (lang == 'en') return "Today's route";
  const map = {
    'mr': 'आजचा मार्ग', 'hi': 'आज का रूट', 'bn': 'আজকের রুট', 'te': 'నేటి మార్గం',
    'ta': 'இன்றைய பாதை', 'kn': 'ಇಂದಿನ ಮಾರ್ಗ', 'ml': 'ഇന്നത്തെ റൂട്ട്', 'gu': 'આજનો રૂટ',
    'pa': 'ਅੱਜ ਦਾ ਰੂਟ', 'or': 'ଆଜିର ରୁଟ୍', 'as': 'আজিৰ পথ',
  };
  return map[lang] ?? "Today's route";
}

String _startAssessmentText(String wardId, String lang) {
  if (lang == 'en') return 'Start assessment in $wardId';
  final map = {
    'mr': '$wardId मध्ये मूल्यांकन सुरू करा', 'hi': '$wardId में मूल्यांकन शुरू करें',
    'bn': '$wardId এ মূল্যায়ন শুরু করুন', 'te': '$wardId లో అంచనా ప్రారంభించండి',
    'ta': '$wardId இல் மதிப்பீட்டைத் தொடங்கு', 'kn': '$wardId ನಲ್ಲಿ ಮೌಲ್ಯಮಾಪನ ಪ್ರಾರಂಭಿಸಿ',
    'ml': '$wardId ൽ വിലയിരുത്തൽ ആരംഭിക്കുക', 'gu': '$wardId માં આકારણી શરૂ કરો',
    'pa': '$wardId ਵਿੱਚ ਮੁਲਾਂਕਣ ਸ਼ੁਰੂ ਕਰੋ', 'or': '$wardId ରେ ମୂଲ୍ୟାଙ୍କନ ଆରମ୍ଭ କରନ୍ତୁ',
    'as': '$wardId ত মূল্যায়ন আৰম্ভ কৰক',
  };
  return map[lang] ?? 'Start assessment in $wardId';
}

String _casesInWeekText(int cases, int week, String lang) {
  if (lang == 'en') return '$cases cases in week $week';
  final map = {
    'mr': 'आठवडा $week मध्ये $cases प्रकरणे', 'hi': 'सप्ताह $week में $cases मामले',
    'bn': '$week তম সপ্তাহে $cases টি কেস', 'te': 'వారం $week లో $cases కేసులు',
    'ta': 'வாரம் $week இல் $cases வழக்குகள்', 'kn': 'ವಾರ $week ರಲ್ಲಿ $cases ಪ್ರಕರಣಗಳು',
    'ml': '$week-ാം ആഴ്ചയിൽ $cases കേസുകൾ', 'gu': 'અઠવાડિયા $week માં $cases કેસ',
    'pa': 'ਹਫ਼ਤਾ $week ਵਿੱਚ $cases ਕੇਸ', 'or': 'ସପ୍ତାହ $week ରେ $cases ମାମଲା',
    'as': 'সপ্তাহ $week ত $cases টা কেছ',
  };
  return map[lang] ?? '$cases cases in week $week';
}

String _sharedHotspotSnackbarText(SharedHotspot hotspot, String lang) {
  if (lang == 'en') {
    return '${hotspot.condition}: ${hotspot.cases} reports from ${hotspot.workerCount} ASHA workers';
  }
  final map = {
    'mr': '${hotspot.condition}: ${hotspot.workerCount} आशा कार्यकर्त्यांकडून ${hotspot.cases} अहवाल',
    'hi': '${hotspot.condition}: ${hotspot.workerCount} आशा कार्यकर्ताओं से ${hotspot.cases} रिपोर्ट',
    'bn': '${hotspot.condition}: ${hotspot.workerCount} আশা কর্মী থেকে ${hotspot.cases} রিপোর্ট',
    'te': '${hotspot.condition}: ${hotspot.workerCount} ఆశా కార్యకర్తల నుండి ${hotspot.cases} నివేదికలు',
    'ta': '${hotspot.condition}: ${hotspot.workerCount} ஆஷா பணியாளர்களிடமிருந்து ${hotspot.cases} அறிக்கைகள்',
    'kn': '${hotspot.condition}: ${hotspot.workerCount} ಆಶಾ ಕಾರ್ಯಕರ್ತೆಯರಿಂದ ${hotspot.cases} ವರದಿಗಳು',
    'ml': '${hotspot.condition}: ${hotspot.workerCount} ആശാ പ്രവർത്തകരിൽ നിന്ന് ${hotspot.cases} റിപ്പോർട്ടുകൾ',
    'gu': '${hotspot.condition}: ${hotspot.workerCount} આશા કાર્યકરો તરફથી ${hotspot.cases} અહેવાલ',
    'pa': '${hotspot.condition}: ${hotspot.workerCount} ਆਸ਼ਾ ਵਰਕਰਾਂ ਤੋਂ ${hotspot.cases} ਰਿਪੋਰਟਾਂ',
    'or': '${hotspot.condition}: ${hotspot.workerCount} ଆଶା କର୍ମୀଙ୍କଠାରୁ ${hotspot.cases} ରିପୋର୍ଟ',
    'as': '${hotspot.condition}: ${hotspot.workerCount} আশা কৰ্মীৰ পৰা ${hotspot.cases} প্ৰতিবেদন',
  };
  return map[lang] ??
      '${hotspot.condition}: ${hotspot.cases} reports from ${hotspot.workerCount} ASHA workers';
}

String _upToDateLabel(String lang) {
  if (lang == 'en') return 'Up to date';
  const map = {
    'mr': 'अद्ययावत', 'hi': 'अद्यतन', 'bn': 'আপ টু ডেট', 'te': 'తాజా సమాచారం',
    'ta': 'புதுப்பிக்கப்பட்டது', 'kn': 'ನವೀಕರಿಸಲಾಗಿದೆ', 'ml': 'അപ് ടു ഡേറ്റ്',
    'gu': 'અદ્યતન', 'pa': 'ਅੱਪ ਟੂ ਡੇਟ', 'or': 'ଅଦ୍ୟତନ', 'as': 'আপ টু ডেট',
  };
  return map[lang] ?? 'Up to date';
}

String _yearSuffix(String lang) {
  if (lang == 'en') return 'y';
  const map = {
    'mr': ' वर्षे', 'hi': ' वर्ष', 'bn': ' বছর', 'te': ' సం.', 'ta': ' ஆண்.',
    'kn': ' ವರ್ಷ', 'ml': ' വർഷം', 'gu': ' વર્ષ', 'pa': ' ਸਾਲ', 'or': ' ବର୍ଷ', 'as': ' বছৰ',
  };
  return map[lang] ?? 'y';
}

String _distanceAwayText(int metres, String lang) {
  if (lang == 'en') return '${metres}m away';
  final map = {
    'mr': '$metresमी दूर', 'hi': '$metresमी दूर', 'bn': '$metresমি দূরে',
    'te': '$metresమీ దూరంలో', 'ta': '$metresமீ தொலைவில்', 'kn': '$metresಮೀ ದೂರ',
    'ml': '$metresമീറ്റർ അകലെ', 'gu': '$metresમી દૂર', 'pa': '$metresਮੀ ਦੂਰ',
    'or': '$metresମି ଦୂର', 'as': '$metresমি দূৰত',
  };
  return map[lang] ?? '${metres}m away';
}

String _directHeadingText(
  String bearingStr,
  int degrees,
  int metres,
  String lang,
) {
  if (lang == 'en') {
    return 'Heading $bearingStr ($degrees°) · ${metres}m direct';
  }
  final map = {
    'mr': 'दिशा $bearingStr ($degrees°) · $metresमी थेट',
    'hi': 'दिशा $bearingStr ($degrees°) · $metresमी सीधा',
    'bn': 'দিক $bearingStr ($degrees°) · $metresমি সরাসরি',
    'te': 'దిశ $bearingStr ($degrees°) · $metresమీ ప్రత్యక్ష',
    'ta': 'திசை $bearingStr ($degrees°) · $metresமீ நேரடி',
    'kn': 'ದಿಕ್ಕು $bearingStr ($degrees°) · $metresಮೀ ನೇರ',
    'ml': 'ദിശ $bearingStr ($degrees°) · $metresമീറ്റർ നേരിട്ട്',
    'gu': 'દિશા $bearingStr ($degrees°) · $metresમી સીધું',
    'pa': 'ਦਿਸ਼ਾ $bearingStr ($degrees°) · $metresਮੀ ਸਿੱਧਾ',
    'or': 'ଦିଗ $bearingStr ($degrees°) · $metresମି ସିଧା',
    'as': 'দিশ $bearingStr ($degrees°) · $metresমি পোনপটীয়া',
  };
  return map[lang] ?? 'Heading $bearingStr ($degrees°) · ${metres}m direct';
}

String _liveGpsText(String lang) {
  if (lang == 'en') return 'Live GPS';
  const map = {
    'mr': 'थेट GPS', 'hi': 'लाइव GPS', 'bn': 'লাইভ GPS', 'te': 'లైవ్ GPS',
    'ta': 'நேரலை GPS', 'kn': 'ಲೈವ್ GPS', 'ml': 'തത്സമയ GPS', 'gu': 'લાઈવ GPS',
    'pa': 'ਲਾਈਵ GPS', 'or': 'ଲାଇଭ୍ GPS', 'as': 'লাইভ GPS',
  };
  return map[lang] ?? 'Live GPS';
}

String _catchmentText(String wardId, String lang) {
  if (lang == 'en') return 'Catchment · $wardId';
  final map = {
    'mr': 'कार्यक्षेत्र · $wardId', 'hi': 'कार्यक्षेत्र · $wardId', 'bn': 'এলাকা · $wardId',
    'te': 'పరిధి · $wardId', 'ta': 'பகுதி · $wardId', 'kn': 'ಕಾರ್ಯಕ್ಷೇತ್ರ · $wardId',
    'ml': 'പ്രദേശം · $wardId', 'gu': 'કાર્યક્ષેત્ર · $wardId', 'pa': 'ਕਾਰਜ ਖੇਤਰ · $wardId',
    'or': 'କାର୍ଯ୍ୟକ୍ଷେତ୍ର · $wardId', 'as': 'কাৰ্যক্ষেত্ৰ · $wardId',
  };
  return map[lang] ?? 'Catchment · $wardId';
}

String _conditionPrefix(String lang) {
  if (lang == 'en') return 'Condition: ';
  const map = {
    'mr': 'स्थिती: ', 'hi': 'स्थिति: ', 'bn': 'পরিস্থিতি: ', 'te': 'పరిస్థితి: ',
    'ta': 'நிலைமை: ', 'kn': 'ಸ್ಥಿತಿ: ', 'ml': 'സ്ഥിതി: ', 'gu': 'સ્થિતિ: ',
    'pa': 'ਸਥਿਤੀ: ', 'or': 'ପରିସ୍ଥିତି: ', 'as': 'পৰিস্থিতি: ',
  };
  return map[lang] ?? 'Condition: ';
}

String _weekLabel(int week, String lang) {
  if (lang == 'en') return 'Week $week / 12';
  final map = {
    'mr': 'आठवडा $week / 12', 'hi': 'सप्ताह $week / 12', 'bn': 'সপ্তাহ $week / 12',
    'te': 'వారం $week / 12', 'ta': 'வாரம் $week / 12', 'kn': 'ವಾರ $week / 12',
    'ml': 'ആഴ്ച $week / 12', 'gu': 'અઠવાડિયું $week / 12', 'pa': 'ਹਫ਼ਤਾ $week / 12',
    'or': 'ସପ୍ତାହ $week / 12', 'as': 'সপ্তাহ $week / 12',
  };
  return map[lang] ?? 'Week $week / 12';
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
    this.lang = 'en',
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
  final String lang;

  @override
  Widget build(BuildContext context) {
    final tag = (liveProvider ?? 'gps').toUpperCase();
    final statusText = isLive && liveCoordinates != null
        ? '$tag · ${liveCoordinates!.latitude.toStringAsFixed(5)}, ${liveCoordinates!.longitude.toStringAsFixed(5)} (±${(liveAccuracy ?? 10).toStringAsFixed(0)}m)'
        : (isLive ? _liveGpsText(lang) : _catchmentText(wardId, lang));
    final layerText = switch (layer) {
      _MapLayer.facilities =>
        activeCategory == 'all'
            ? _filterPillLabel('all', lang)
            : _categoryLabel(activeCategory, lang),
      _MapLayer.radar => _filterPillLabel('radar', lang),
      _MapLayer.households => _filterPillLabel('households', lang),
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
    this.lang = 'en',
  });

  final _MapLayer layer;
  final String category;
  final void Function(_MapLayer layer, String category) onSelectFilter;
  final String lang;

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
              label: _filterPillLabel('all', lang),
              icon: Icons.local_hospital_outlined,
              activeColor: const Color(0xFF1E4231),
              selected: layer == _MapLayer.facilities && category == 'all',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'all'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: _filterPillLabel('phc', lang),
              icon: Icons.local_hospital_rounded,
              activeColor: const Color(0xFF16A34A),
              selected: layer == _MapLayer.facilities && category == 'phc',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'phc'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: _filterPillLabel('chc', lang),
              icon: Icons.apartment_rounded,
              activeColor: const Color(0xFF2563EB),
              selected: layer == _MapLayer.facilities && category == 'chc',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'chc'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: _filterPillLabel('blood_bank', lang),
              icon: Icons.bloodtype_rounded,
              activeColor: const Color(0xFFDC2626),
              selected:
                  layer == _MapLayer.facilities && category == 'blood_bank',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'blood_bank'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: _filterPillLabel('nrc', lang),
              icon: Icons.child_friendly_rounded,
              activeColor: const Color(0xFF7C3AED),
              selected: layer == _MapLayer.facilities && category == 'nrc',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'nrc'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: _filterPillLabel('antivenom', lang),
              icon: Icons.warning_amber_rounded,
              activeColor: const Color(0xFFB45309),
              selected:
                  layer == _MapLayer.facilities && category == 'antivenom',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'antivenom'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: _filterPillLabel('ab_hwc', lang),
              icon: Icons.health_and_safety_rounded,
              activeColor: const Color(0xFF0F766E),
              selected: layer == _MapLayer.facilities && category == 'ab_hwc',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'ab_hwc'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: _filterPillLabel('deic', lang),
              icon: Icons.accessibility_new_rounded,
              activeColor: const Color(0xFF2563EB),
              selected: layer == _MapLayer.facilities && category == 'deic',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'deic'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: _filterPillLabel('pmjay', lang),
              icon: Icons.currency_rupee_rounded,
              activeColor: const Color(0xFF15803D),
              selected: layer == _MapLayer.facilities && category == 'pmjay',
              onTap: () => onSelectFilter(_MapLayer.facilities, 'pmjay'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: _filterPillLabel('radar', lang),
              icon: Icons.radar_rounded,
              activeColor: const Color(0xFFEA580C),
              selected: layer == _MapLayer.radar,
              onTap: () => onSelectFilter(_MapLayer.radar, 'all'),
            ),
            const SizedBox(width: 4),
            _FilterPill(
              label: _filterPillLabel('households', lang),
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
    this.lang = 'en',
  });

  final FacilityPoi poi;
  final String category;
  final bool chosen;
  final bool showLabel;
  final VoidCallback onTap;
  final String lang;

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
          if (showLabel) ...[
            _NameChip(_localizeMapLabel(poi.name, lang)),
            const SizedBox(height: 2),
          ],
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
  const _StateHubMarker({
    required this.hub,
    required this.onTap,
    this.lang = 'en',
  });

  final _StateHub hub;
  final VoidCallback onTap;
  final String lang;

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
                _localizeStateName(hub.name, lang),
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
