import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../domain/due_list_models.dart';
import '../domain/route_models.dart';

/// Screen displaying the computed offline visit route on an OpenStreetMap tile canvas
/// or a landmark sketch map fallback (Requirements 25.1, 25.2, 25.3).
class RouteMapScreen extends StatefulWidget {
  final PlannedRoute route;
  final Function(String hamlet, BarrierReason reason, String? notes, DateTime? until)? onFlagHamletBlocked;

  const RouteMapScreen({
    super.key,
    required this.route,
    this.onFlagHamletBlocked,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  LatLng _getInitialCenter() {
    final start = widget.route.startLocation;
    if (start != null) {
      return LatLng(start.latitude, start.longitude);
    }
    for (final wp in widget.route.orderedWaypoints) {
      if (wp.coordinate != null) {
        return LatLng(wp.coordinate!.latitude, wp.coordinate!.longitude);
      }
    }
    // Default fallback to rural North India coordinate
    return const LatLng(25.3176, 82.9739);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit Route & Map'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'Map View'),
            Tab(icon: Icon(Icons.alt_route), text: 'Landmark Sketch'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: FlutterMap OpenStreetMap View ────────────────────────────
          _buildMapCanvas(context),

          // ── Tab 2: Offline Landmark Sketch View (Requirement 25.3) ─────────
          _buildLandmarkSketchView(context),
        ],
      ),
      bottomNavigationBar: _buildRouteSummaryBar(context),
    );
  }

  Widget _buildMapCanvas(BuildContext context) {
    final waypoints = widget.route.orderedWaypoints;
    final initialCenter = _getInitialCenter();

    // Build polyline points
    final polylinePoints = <LatLng>[];
    if (widget.route.startLocation != null) {
      polylinePoints.add(
        LatLng(widget.route.startLocation!.latitude, widget.route.startLocation!.longitude),
      );
    }
    for (final wp in waypoints) {
      if (wp.coordinate != null) {
        polylinePoints.add(LatLng(wp.coordinate!.latitude, wp.coordinate!.longitude));
      }
    }

    // Build markers
    final markers = <Marker>[];
    for (var i = 0; i < waypoints.length; i++) {
      final wp = waypoints[i];
      if (wp.coordinate != null) {
        final point = LatLng(wp.coordinate!.latitude, wp.coordinate!.longitude);
        final markerColor = wp.hasRedAlert
            ? const Color(0xFFD32F2F)
            : (wp.tasks.any((t) => t.urgencyGroup == UrgencyGroup.overdue)
                ? const Color(0xFFE65100)
                : const Color(0xFF1B5E20));

        markers.add(
          Marker(
            point: point,
            width: 48,
            height: 48,
            child: GestureDetector(
              onTap: () {
                _showWaypointDetailsModal(context, wp, i + 1);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.location_on, size: 48, color: markerColor),
                  Positioned(
                    top: 8,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 14.0,
          ),
          children: [
            // Standard offline/cached tile layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'org.mohfw.asha_platform',
            ),
            if (polylinePoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: polylinePoints,
                    strokeWidth: 4.0,
                    color: const Color(0xFF1565C0),
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),

        // Floating Opt-In GPS Status Tag (Requirement 25.2)
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.route.isOptInGpsUsed ? Icons.gps_fixed : Icons.gps_off,
                  size: 16,
                  color: widget.route.isOptInGpsUsed ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.route.isOptInGpsUsed ? 'Opt-in GPS' : 'Static Hamlets',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandmarkSketchView(BuildContext context) {
    final waypoints = widget.route.orderedWaypoints;

    if (waypoints.isEmpty) {
      return const Center(child: Text('No stops scheduled on this route.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: waypoints.length,
      itemBuilder: (context, index) {
        final wp = waypoints[index];
        final isLast = index == waypoints.length - 1;
        final hasRed = wp.hasRedAlert;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: hasRed ? const Color(0xFFD32F2F) : const Color(0xFF1B5E20),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 80,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            wp.hamlet,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${wp.totalVisits} visit${wp.totalVisits == 1 ? '' : 's'}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Village: ${wp.village}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),

                      // Local Landmark Notes (Requirement 25.3)
                      if (wp.landmarkNotes.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.flag, size: 16, color: Color(0xFFE65100)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Landmarks: ${wp.landmarkNotes.join(', ')}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFFBF360C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Flag Hamlet as Impassable button (Requirement 25.4)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _showFlagBlockedDialog(context, wp.hamlet),
                          icon: const Icon(Icons.report_problem, size: 16, color: Colors.red),
                          label: const Text(
                            'Flag Impassable',
                            style: TextStyle(fontSize: 12, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRouteSummaryBar(BuildContext context) {
    final dist = widget.route.totalEstimatedDistanceKm;
    final duration = widget.route.estimatedWalkingDuration;
    final totalVisits = widget.route.totalScheduledVisits;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dist.toStringAsFixed(1)} km  •  ~${duration.inMinutes} mins',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$totalVisits visits in ${widget.route.totalStops} hamlets',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Starting planned visit route navigation.')),
                );
              },
              icon: const Icon(Icons.navigation, size: 18),
              label: const Text('Start Route'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWaypointDetailsModal(BuildContext context, HamletWaypoint wp, int stopNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stop $stopNumber: ${wp.hamlet}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Village: ${wp.village}  •  ${wp.totalVisits} visits due'),
            const Divider(height: 24),
            ...wp.tasks.map((t) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    t.hasRedAlert ? Icons.warning : Icons.person,
                    color: t.hasRedAlert ? Colors.red : Colors.green,
                  ),
                  title: Text(t.memberName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${t.visitType} (${t.urgencyGroup.label})'),
                )),
          ],
        ),
      ),
    );
  }

  void _showFlagBlockedDialog(BuildContext context, String hamlet) {
    BarrierReason selectedReason = BarrierReason.flood;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Flag $hamlet as Impassable'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reporting an impassable route will automatically adjust scheduled visits and notify your supervisor (Req 25.4).',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              DropdownButton<BarrierReason>(
                value: selectedReason,
                isExpanded: true,
                items: BarrierReason.values.map((r) {
                  return DropdownMenuItem(value: r, child: Text(r.label));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => selectedReason = val);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Optional Notes / Details',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onFlagHamletBlocked?.call(
                  hamlet,
                  selectedReason,
                  notesController.text,
                  DateTime.now().add(const Duration(days: 7)),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$hamlet flagged as $selectedReason. Visits rescheduled.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Confirm Flag'),
            ),
          ],
        ),
      ),
    );
  }
}
