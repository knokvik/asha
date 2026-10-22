import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/packs/pack_manager.dart';
import 'geo_map_screen.dart';

/// Main Map-tab entry point using the original country-wide OpenStreetMap view.
class FieldMapScreen extends ConsumerWidget {
  const FieldMapScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packState = ref.watch(offlinePackProvider);
    if (!packState.loaded) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!packState.mapInstalled) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_outlined, size: 50, color: Color(0xFF2563EB)),
                const SizedBox(height: 14),
                const Text(
                  'Offline map pack needed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Install the India map pack once to view facilities, households and routes without adding it to the APK.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.push('/packs'),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Open offline packs'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return GeoMapPage(embedded: embedded, useOsmBasemap: true);
  }
}
