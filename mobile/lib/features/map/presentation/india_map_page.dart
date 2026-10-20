import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/widgets/asha_bottom_nav.dart';
import '../data/offline_state_tiles.dart';

/// Full-page map. Packs are chosen in Profile, not on this screen.
class IndiaMapPage extends StatefulWidget {
  const IndiaMapPage({super.key});

  @override
  State<IndiaMapPage> createState() => _IndiaMapPageState();
}

class _IndiaMapPageState extends State<IndiaMapPage> {
  final _mapController = MapController();
  List<_StateShape> _states = const [];
  OfflineStateTiles? _store;
  StateTilePlan? _plan;
  var _zoom = 4.4;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    selectedMapSlug.addListener(_onSelection);
    _load();
  }

  @override
  void dispose() {
    selectedMapSlug.removeListener(_onSelection);
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = await rootBundle.loadString('assets/geo/india_states.geojson');
      final store = await OfflineStateTiles.open();
      final shapes = _StateShape.parse(raw);
      for (final shape in shapes) {
        await store.isReady(shape.region);
      }
      await store.loadSelection();
      if (!mounted) return;
      setState(() {
        _states = shapes;
        _store = store;
        _loading = false;
      });
      await _applySelection();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = '$error';
        _loading = false;
      });
    }
  }

  void _onSelection() {
    _applySelection();
  }

  Future<void> _applySelection() async {
    final store = _store;
    if (store == null || !mounted) return;
    final slug = selectedMapSlug.value;
    final shape = _states.cast<_StateShape?>().firstWhere(
          (item) => item!.region.slug == slug,
          orElse: () => null,
        );
    if (shape == null) {
      setState(() => _plan = null);
      return;
    }
    final plan = await store.savedPlan(shape.region) ?? OfflineStateTiles.planFor(shape.region);
    if (!mounted) return;
    setState(() => _plan = plan);
    final region = shape.region;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _mapController.move(
        LatLng((region.south + region.north) / 2, (region.west + region.east) / 2),
        6.5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFD7E3F4),
        bottomNavigationBar: AshaBottomNav(index: 1),
        body: SizedBox.expand(),
      );
    }
    if (_error != null) {
      return Scaffold(
        bottomNavigationBar: const AshaBottomNav(index: 1),
        body: Center(child: Text('Map failed to open: $_error')),
      );
    }
    final slug = selectedMapSlug.value;
    final shape = _states.cast<_StateShape?>().firstWhere(
          (item) => item!.region.slug == slug,
          orElse: () => null,
        );
    final region = shape?.region;
    final plan = _plan;
    final store = _store;
    return Scaffold(
      backgroundColor: const Color(0xFFD7E3F4),
      bottomNavigationBar: const AshaBottomNav(index: 1),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(22.5, 79.0),
          initialZoom: 4.6,
          minZoom: 3,
          maxZoom: 18,
          backgroundColor: const Color(0xFFD7E3F4),
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          onPositionChanged: (camera, _) {
            if ((camera.zoom - _zoom).abs() < 0.08) return;
            setState(() => _zoom = camera.zoom);
          },
        ),
        children: [
          if (region != null && store != null && plan != null)
            TileLayer(
              tileProvider: store.providerFor(region),
              userAgentPackageName: 'com.nhm.asha.asha_platform',
              minZoom: 3,
              maxZoom: 18,
              maxNativeZoom: plan.maxZoom,
            )
          else
            TileLayer(
              urlTemplate: streetTileUrl,
              userAgentPackageName: 'com.nhm.asha.asha_platform',
              minZoom: 3,
              maxZoom: 18,
            ),
          MarkerLayer(markers: _pins(region)),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('OpenStreetMap contributors'),
            ],
          ),
        ],
      ),
    );
  }

  List<Marker> _pins(IndiaStateRegion? region) {
    if (region == null && _zoom < 5.4) return const [];
    final markers = <Marker>[];
    for (final shape in _states) {
      if (region != null && shape.region.slug != region.slug) continue;
      final lat = (shape.region.south + shape.region.north) / 2;
      final lon = (shape.region.west + shape.region.east) / 2;
      for (final layer in _layers) {
        markers.add(
          Marker(
            point: LatLng(lat + layer.dLat, lon + layer.dLon),
            width: 36,
            height: 44,
            alignment: Alignment.bottomCenter,
            child: _MapPin(icon: layer.icon, color: layer.color),
          ),
        );
      }
    }
    return markers;
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 1))],
          ),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Icon(icon, color: Colors.white, size: 16),
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }
}

class _CatalogPin {
  const _CatalogPin(this.icon, this.color, this.dLat, this.dLon);

  final IconData icon;
  final Color color;
  final double dLat;
  final double dLon;
}

const _layers = <_CatalogPin>[
  _CatalogPin(Icons.local_hospital, Color(0xFFB42318), 0.15, -0.15),
  _CatalogPin(Icons.medication, Color(0xFF9A3412), -0.15, 0.15),
  _CatalogPin(Icons.account_balance, Color(0xFF1D4E89), 0.15, 0.15),
  _CatalogPin(Icons.groups, Color(0xFF3F6212), -0.15, -0.15),
];

class _StateShape {
  const _StateShape({required this.region, required this.outer});

  final IndiaStateRegion region;
  final List<LatLng> outer;

  static List<_StateShape> parse(String raw) {
    final json = jsonDecode(raw) as Map<String, Object?>;
    final features = json['features'] as List<Object?>;
    return [
      for (final feature in features)
        if (feature is Map<String, Object?>) _fromFeature(feature),
    ];
  }

  static _StateShape _fromFeature(Map<String, Object?> feature) {
    final props = (feature['properties'] as Map).cast<String, Object?>();
    final geometry = (feature['geometry'] as Map).cast<String, Object?>();
    final region = IndiaStateRegion(
      name: props['name'] as String,
      south: (props['s'] as num).toDouble(),
      west: (props['w'] as num).toDouble(),
      north: (props['n'] as num).toDouble(),
      east: (props['e'] as num).toDouble(),
    );
    final coordinates = geometry['coordinates'] as List<Object?>;
    final ring = geometry['type'] == 'Polygon'
        ? coordinates.first as List<Object?>
        : ((coordinates.first as List<Object?>).first as List<Object?>);
    return _StateShape(region: region, outer: _ring(ring));
  }

  static List<LatLng> _ring(List<Object?> ring) {
    return [
      for (final point in ring)
        if (point is List && point.length >= 2)
          LatLng((point[1] as num).toDouble(), (point[0] as num).toDouble()),
    ];
  }
}
