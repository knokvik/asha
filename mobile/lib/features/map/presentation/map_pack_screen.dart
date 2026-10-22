import 'package:flutter/material.dart';

import '../../settings/presentation/pack_manager_screen.dart';

/// Compatibility entry point for older deep links.
///
/// Map downloads now live with the other optional packages so the old
/// per-state screen cannot accidentally rely on geo assets bundled in the APK.
@Deprecated('Use PackManagerScreen through /packs instead.')
class MapPackScreen extends StatelessWidget {
  const MapPackScreen({super.key});

  @override
  Widget build(BuildContext context) => const PackManagerScreen();
}
