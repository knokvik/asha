import 'package:flutter/material.dart';

import 'geo_map_screen.dart';

/// Main Map-tab entry point.
///
/// The map is deliberately backed by [GeoMapPage], which loads only bundled
/// assets and local MBTiles. This keeps the shell map usable in airplane mode.
class FieldMapScreen extends StatelessWidget {
  const FieldMapScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) => GeoMapPage(embedded: embedded);
}
