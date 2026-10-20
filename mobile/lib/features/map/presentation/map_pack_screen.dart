import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../data/offline_state_tiles.dart';

/// Profile screen for the embedded country map and one-state downloads.
class MapPackScreen extends StatefulWidget {
  const MapPackScreen({super.key});

  @override
  State<MapPackScreen> createState() => _MapPackScreenState();
}

class _MapPackScreenState extends State<MapPackScreen> {
  List<IndiaStateRegion> _regions = const [];
  OfflineStateTiles? _store;
  final _ready = <String>{};
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/geo/india_states.geojson');
    final store = await OfflineStateTiles.open();
    final regions = _regionsFrom(raw);
    final ready = <String>{};
    for (final region in regions) {
      if (await store.isReady(region)) ready.add(region.slug);
    }
    await store.loadSelection();
    if (!mounted) return;
    setState(() {
      _regions = regions;
      _store = store;
      _ready
        ..clear()
        ..addAll(ready);
      _loading = false;
    });
  }

  Future<void> _useEmbedded() async {
    await _store?.select(null);
    if (!mounted) return;
    context.go('/india-map');
  }

  Future<void> _useState(IndiaStateRegion region) async {
    final store = _store;
    if (store == null) return;
    if (_ready.contains(region.slug)) {
      await store.select(region);
      if (!mounted) return;
      context.go('/geo-map');
      return;
    }
    final plan = OfflineStateTiles.planFor(region);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(region.name),
        content: Text(
          'Download this state. About ${plan.estimatedLabel}, zoom ${plan.minZoom}–${plan.maxZoom}. '
          'It stays on the phone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    var cancelled = false;
    final progress = ValueNotifier<int>(0);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(region.name),
        content: ValueListenableBuilder<int>(
          valueListenable: progress,
          builder: (context, done, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: plan.tiles.isEmpty ? null : done / plan.tiles.length,
              ),
              const SizedBox(height: 12),
              Text('$done / ${plan.tiles.length} tiles'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              cancelled = true;
              Navigator.pop(dialogContext);
            },
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    final written = await store.download(
      plan,
      isCancelled: () => cancelled,
      onProgress: (finished, _) => progress.value = finished,
    );
    progress.dispose();
    if (!mounted) return;
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    if (cancelled || written == 0) {
      if (written == 0 && !cancelled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The map server did not return tiles. Try again.'),
          ),
        );
      }
      return;
    }
    await store.select(region);
    if (!mounted) return;
    context.go('/geo-map');
  }

  @override
  Widget build(BuildContext context) {
    final regions = [..._regions]..sort((a, b) => a.name.compareTo(b.name));
    return Scaffold(
      appBar: AppBar(title: const Text('Maps pack')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('Embedded whole India'),
                  subtitle: const Text('State outlines already in the app.'),
                  trailing: Icon(
                    selectedMapSlug.value == null
                        ? Icons.check_circle
                        : Icons.chevron_right,
                  ),
                  onTap: _useEmbedded,
                ),
                const Divider(height: 1),
                const ListTile(
                  title: Text('Download one state'),
                  subtitle: Text(
                    'Street tiles for that state, kept near 8 MB.',
                  ),
                ),
                for (final region in regions)
                  ListTile(
                    dense: true,
                    title: Text(region.name),
                    subtitle: Text(
                      _ready.contains(region.slug)
                          ? 'Saved on this phone'
                          : OfflineStateTiles.planFor(region).estimatedLabel,
                    ),
                    trailing: Icon(
                      selectedMapSlug.value == region.slug
                          ? Icons.check_circle
                          : _ready.contains(region.slug)
                          ? Icons.map
                          : Icons.download,
                    ),
                    onTap: () => _useState(region),
                  ),
              ],
            ),
    );
  }
}

List<IndiaStateRegion> _regionsFrom(String raw) {
  final json = jsonDecode(raw) as Map<String, Object?>;
  final features = json['features'] as List<Object?>;
  return [
    for (final feature in features)
      if (feature is Map<String, Object?>)
        IndiaStateRegion(
          name: (feature['properties'] as Map)['name'] as String,
          south: ((feature['properties'] as Map)['s'] as num).toDouble(),
          west: ((feature['properties'] as Map)['w'] as num).toDouble(),
          north: ((feature['properties'] as Map)['n'] as num).toDouble(),
          east: ((feature['properties'] as Map)['e'] as num).toDouble(),
        ),
  ];
}
