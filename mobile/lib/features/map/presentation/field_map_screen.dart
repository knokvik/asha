import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/l10n/language_provider.dart';
import '../../../shared/shell/shell_copy.dart';
import '../../../shared/widgets/asha_bottom_nav.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen 3: Field Map matching the master reference image.
/// Top Bar: [ < ]  Field Map  [ ჻ ]
/// Toggle: [ My Area | All Households ]
/// Map with house pins (red, orange, green), blue pulsing live location, GPS and Layer controls.
/// Bottom sheet: "5 households today", "3 Due • 1 Follow-up • 1 Upcoming", Savitri Devi and Rekha Sharma cards.
/// Fixed 4-item bottom navigation dock (Map active).
enum _LocationStatus { requesting, granted, denied, unavailable }

class FieldMapScreen extends ConsumerStatefulWidget {
  const FieldMapScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<FieldMapScreen> createState() => _FieldMapScreenState();
}

class _FieldMapScreenState extends ConsumerState<FieldMapScreen> {
  final MapController _mapController = MapController();
  static const _indiaCenter = LatLng(22.5, 79.0);
  static const _fallbackCenter = LatLng(18.6279, 73.8131);
  static const _locationChannel = MethodChannel('asha_platform/location');

  // Start on the national view so the supplied India-wide data is visible.
  int _selectedToggle = 1; // 0: My Area, 1: All Households
  List<Marker> _facilityMarkers = const [];
  List<Polygon> _stateOutlines = const [];
  LatLng? _liveLocation;
  _LocationStatus _locationStatus = _LocationStatus.requesting;

  @override
  void initState() {
    super.initState();
    _loadFacilities();
    _loadStateOutlines();
    _requestCurrentLocation();
  }

  Future<void> _loadStateOutlines() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/geo/india_states.geojson',
      );
      final json = jsonDecode(raw) as Map<String, Object?>;
      final features = json['features'] as List<Object?>? ?? const [];
      final outlines = <Polygon>[];
      for (final feature in features) {
        if (feature is! Map) continue;
        final geometry = feature['geometry'];
        if (geometry is! Map) continue;
        final type = geometry['type'];
        final coordinates = geometry['coordinates'];
        if (type == 'Polygon' && coordinates is List) {
          _addPolygon(outlines, coordinates.isEmpty ? null : coordinates.first);
        } else if (type == 'MultiPolygon' && coordinates is List) {
          for (final polygon in coordinates) {
            if (polygon is List) {
              _addPolygon(outlines, polygon.isEmpty ? null : polygon.first);
            }
          }
        }
      }
      if (!mounted) return;
      setState(() => _stateOutlines = outlines);
    } catch (_) {
      // Facility pins remain usable if a state-boundary asset is unavailable.
    }
  }

  void _addPolygon(List<Polygon> target, Object? rawRing) {
    if (rawRing is! List) return;
    final points = <LatLng>[];
    for (final point in rawRing) {
      if (point is! List || point.length < 2) continue;
      final lon = (point[0] as num?)?.toDouble();
      final lat = (point[1] as num?)?.toDouble();
      if (lat != null && lon != null) points.add(LatLng(lat, lon));
    }
    if (points.length < 3) return;
    target.add(
      Polygon(
        points: points,
        color: const Color(0x0A16805C),
        borderColor: const Color(0x6616805C),
        borderStrokeWidth: 1,
      ),
    );
  }

  Future<void> _requestCurrentLocation({bool recenter = false}) async {
    if (!mounted) return;
    setState(() => _locationStatus = _LocationStatus.requesting);
    PermissionStatus permission;
    try {
      permission = await Permission.locationWhenInUse.request();
    } catch (_) {
      if (mounted) {
        setState(() => _locationStatus = _LocationStatus.unavailable);
      }
      return;
    }
    if (!permission.isGranted) {
      if (!mounted) return;
      setState(() => _locationStatus = _LocationStatus.denied);
      if (recenter) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Allow location permission to show your current position.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final raw = await _locationChannel.invokeMethod<Object?>(
        'getCurrentLocation',
      );
      if (raw is! Map) throw StateError('Location unavailable');
      final lat = (raw['latitude'] as num?)?.toDouble();
      final lon = (raw['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) throw StateError('Location unavailable');
      final location = LatLng(lat, lon);
      if (!mounted) return;
      setState(() {
        _liveLocation = location;
        _locationStatus = _LocationStatus.granted;
      });
      if (recenter) _mapController.move(location, 15.6);
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationStatus = _LocationStatus.unavailable);
      if (recenter) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location is not available yet.'),
          ),
        );
      }
    }
  }

  Future<void> _loadFacilities() async {
    var raw = await rootBundle.loadString('assets/geo/india_facilities.json');
    try {
      final response = await http
          .get(Uri.parse('http://10.255.102.24:8000/api/v1/facilities/dummy'))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) raw = response.body;
    } catch (_) {}
    final json = jsonDecode(raw) as Map<String, Object?>;
    final rows = json['facilities'] as List<Object?>? ?? const [];
    final markers = <Marker>[];
    for (final row in rows) {
      if (row is! Map) continue;
      final lat = (row['lat'] as num?)?.toDouble();
      final lon = (row['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;
      final kind = row['kind'] as String? ?? 'phc';
      markers.add(
        Marker(
          point: LatLng(lat, lon),
          width: 28,
          height: 28,
          child: Tooltip(
            message: '${row['name']} · $kind',
            child: Icon(_iconFor(kind), color: _colorFor(kind), size: 22),
          ),
        ),
      );
    }
    if (!mounted) return;
    setState(() => _facilityMarkers = markers);
  }

  IconData _iconFor(String kind) => switch (kind) {
    'hospital' || 'phc' || 'chc' || 'subcentre' => Icons.local_hospital,
    'anganwadi' => Icons.groups,
    'blood_bank' => Icons.bloodtype,
    'janaushadhi' => Icons.medication,
    'government' => Icons.account_balance,
    _ => Icons.place,
  };

  Color _colorFor(String kind) => switch (kind) {
    'hospital' || 'phc' || 'chc' => const Color(0xFFB42318),
    'subcentre' => const Color(0xFF9A3412),
    'anganwadi' => const Color(0xFF3F6212),
    'blood_bank' => const Color(0xFF9F1239),
    'janaushadhi' => const Color(0xFFC2410C),
    'government' => const Color(0xFF1D4E89),
    _ => const Color(0xFF1E4231),
  };

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).languageCode;
    final map = _map(context, lang);
    if (widget.embedded) return map;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      bottomNavigationBar: const AshaBottomNav(index: 1),
      body: map,
    );
  }

  Widget _map(BuildContext context, String lang) {
    return Stack(
      children: [
        // 1. Interactive Raster Map with House Markers
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _selectedToggle == 1
                ? _indiaCenter
                : (_liveLocation ?? _fallbackCenter),
            initialZoom: _selectedToggle == 1 ? 4.6 : 15.6,
            minZoom: 3,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.nhm.asha.asha_platform',
              tileBuilder: (context, widget, tile) {
                return ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    0.90,
                    0.05,
                    0.05,
                    0,
                    5,
                    0.05,
                    0.95,
                    0.05,
                    0,
                    8,
                    0.05,
                    0.05,
                    0.90,
                    0,
                    5,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
                  child: widget,
                );
              },
            ),
            if (_selectedToggle == 1 && _stateOutlines.isNotEmpty)
              PolygonLayer(polygons: _stateOutlines),
            MarkerLayer(markers: _facilityMarkers),

            // House Markers matching Screen 3:
            // Red houses (Due / High risk), Orange houses (Follow-up), Green houses (Upcoming / Done)
            MarkerLayer(
              markers: [
                if (_liveLocation != null)
                  Marker(
                    point: _liveLocation!,
                    width: 70,
                    height: 70,
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0x332563EB),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // House 1: Savitri Devi (Red house pin - Due)
                Marker(
                  point: LatLng(
                    _fallbackCenter.latitude + 0.0032,
                    _fallbackCenter.longitude - 0.0030,
                  ),
                  width: 38,
                  height: 38,
                  child: _buildHousePin(color: const Color(0xFFEF4444)),
                ),

                // House 2: Rekha Sharma (Orange house pin - Follow-up)
                Marker(
                  point: LatLng(
                    _fallbackCenter.latitude - 0.0028,
                    _fallbackCenter.longitude - 0.0026,
                  ),
                  width: 38,
                  height: 38,
                  child: _buildHousePin(color: const Color(0xFFF59E0B)),
                ),

                // House 3: Kamla Bai (Green house pin - Completed/Upcoming)
                Marker(
                  point: LatLng(
                    _fallbackCenter.latitude + 0.0048,
                    _fallbackCenter.longitude - 0.0038,
                  ),
                  width: 38,
                  height: 38,
                  child: _buildHousePin(color: const Color(0xFF16A34A)),
                ),

                // House 4: Lata Devi (Orange house pin)
                Marker(
                  point: LatLng(
                    _fallbackCenter.latitude + 0.0020,
                    _fallbackCenter.longitude + 0.0034,
                  ),
                  width: 38,
                  height: 38,
                  child: _buildHousePin(color: const Color(0xFFF59E0B)),
                ),

                // House 5: Meena Kumari (Red house pin)
                Marker(
                  point: LatLng(
                    _fallbackCenter.latitude - 0.0042,
                    _fallbackCenter.longitude + 0.0022,
                  ),
                  width: 38,
                  height: 38,
                  child: _buildHousePin(color: const Color(0xFFEF4444)),
                ),

                // House 6: Sunita Gaikwad (Green house pin)
                Marker(
                  point: LatLng(
                    _fallbackCenter.latitude - 0.0036,
                    _fallbackCenter.longitude + 0.0046,
                  ),
                  width: 38,
                  height: 38,
                  child: _buildHousePin(color: const Color(0xFF16A34A)),
                ),
              ],
            ),
          ],
        ),

        // 2. Top Header & Segmented Toggle Overlay matching Screen 3
        SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.embedded)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),

                      const Text(
                        'Field Map',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          fontFamily: 'SF Pro Display',
                        ),
                      ),

                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Filter: Showing active households for Ward 7.',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Pill Segmented Toggle: [ My Area | All Households ]
              Center(
                child: Container(
                  width: 230,
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildToggleOption(0, shellText(lang, 'myArea')),
                      ),
                      Expanded(
                        child: _buildToggleOption(
                          1,
                          shellText(lang, 'allHomes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_locationStatus != _LocationStatus.granted)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InkWell(
                    key: const Key('map_location_permission_prompt'),
                    onTap: () => _requestCurrentLocation(recenter: true),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        _locationStatus == _LocationStatus.requesting
                            ? 'Getting current location…'
                            : 'Allow location to show your position',
                        style: const TextStyle(
                          color: Color(0xFF166534),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 3. Floating Controls on Top-Right: GPS Target 🎯, Layer ⛁, Zoom In ➕, Zoom Out ➖
        Positioned(
          right: 16,
          top: 140,
          child: Column(
            children: [
              _buildMapFloatingButton(
                key: const Key('map_my_location_button'),
                icon: Icons.my_location_rounded,
                onTap: () => _requestCurrentLocation(recenter: true),
              ),
              const SizedBox(height: 8),
              _buildMapFloatingButton(
                icon: Icons.layers_outlined,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Layer: High Risk Overlay & Route Path enabled.',
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              // Zoom In (+)
              _buildMapFloatingButton(
                icon: Icons.add_rounded,
                onTap: () {
                  final zoom = (_mapController.camera.zoom + 1.0).clamp(
                    3.0,
                    18.0,
                  );
                  _mapController.move(_mapController.camera.center, zoom);
                },
              ),
              const SizedBox(height: 8),
              // Zoom Out (-)
              _buildMapFloatingButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  final zoom = (_mapController.camera.zoom - 1.0).clamp(
                    3.0,
                    18.0,
                  );
                  _mapController.move(_mapController.camera.center, zoom);
                },
              ),
            ],
          ),
        ),

        // 4. Draggable Bottom Sheet matching Screen 3:
        // "5 households today", "🔴 3 Due  🟠 1 Follow-up  🟢 1 Upcoming", Household cards
        DraggableScrollableSheet(
          initialChildSize: 0.38,
          minChildSize: 0.18,
          maxChildSize: 0.72,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 14,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
                children: [
                  // Handle
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
                  const SizedBox(height: 14),

                  // Title
                  const Text(
                    '5 households today',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Counts row: 🔴 3 Due  🟠 1 Follow-up  🟢 1 Upcoming
                  Row(
                    children: const [
                      _StatusCount(color: Color(0xFFEF4444), text: '3 Due'),
                      SizedBox(width: 12),
                      _StatusCount(
                        color: Color(0xFFF59E0B),
                        text: '1 Follow-up',
                      ),
                      SizedBox(width: 12),
                      _StatusCount(
                        color: Color(0xFF16A34A),
                        text: '1 Upcoming',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Household 1: Savitri Devi (Overdue)
                  _buildHouseholdRow(
                    initials: 'SD',
                    name: 'Savitri Devi',
                    subtitle: 'W7 • ANC Visit',
                    badgeText: 'Overdue',
                    badgeColor: const Color(0xFFEF4444),
                    badgeBg: const Color(0xFFFEE2E2),
                    onTap: () => context.push('/beneficiary/sav-01'),
                  ),
                  const SizedBox(height: 10),

                  // Household 2: Rekha Sharma (Today)
                  _buildHouseholdRow(
                    initials: 'RS',
                    name: 'Rekha Sharma',
                    subtitle: 'W7 • Immunization',
                    badgeText: 'Today',
                    badgeColor: const Color(0xFF16A34A),
                    badgeBg: const Color(0xFFDCFCE7),
                    onTap: () => context.push('/beneficiary/sav-01'),
                  ),
                  const SizedBox(height: 10),

                  // Household 3: Meena Kumari (Today)
                  _buildHouseholdRow(
                    initials: 'MK',
                    name: 'Meena Kumari',
                    subtitle: 'W6 • Child Immunization',
                    badgeText: 'Today',
                    badgeColor: const Color(0xFF16A34A),
                    badgeBg: const Color(0xFFDCFCE7),
                    onTap: () => context.push('/beneficiary/sav-01'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHousePin({required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x28000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
    );
  }

  Widget _buildToggleOption(int index, String label) {
    final isSelected = _selectedToggle == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedToggle = index);
        _mapController.move(
          index == 1 ? _indiaCenter : (_liveLocation ?? _fallbackCenter),
          index == 1 ? 4.6 : 15.6,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF1E4231)
                : const Color(0xFF6B7280),
            fontFamily: 'SF Pro Display',
          ),
        ),
      ),
    );
  }

  Widget _buildMapFloatingButton({
    Key? key,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF374151)),
      ),
    );
  }

  Widget _buildHouseholdRow({
    required String initials,
    required String name,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeBg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF3F4F6), width: 1.0),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE0E7FF),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3730A3),
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: badgeColor,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCount extends StatelessWidget {
  final Color color;
  final String text;

  const _StatusCount({required this.color, required this.text});

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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4B5563),
            fontFamily: 'SF Pro Display',
          ),
        ),
      ],
    );
  }
}
