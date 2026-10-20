import 'package:flutter/material.dart';

import 'geo_map_screen.dart';

/// Main Map-tab entry point using the original country-wide OpenStreetMap view.
class FieldMapScreen extends StatelessWidget {
  const FieldMapScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) =>
      GeoMapPage(embedded: embedded, useOsmBasemap: true);
}
