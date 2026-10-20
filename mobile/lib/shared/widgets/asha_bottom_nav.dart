import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_theme.dart';

/// Dashboard, Map, Tools, Profile. Tab switches replace the route.
class AshaBottomNav extends StatelessWidget {
  const AshaBottomNav({super.key, required this.index});

  final int index;

  static const routes = ['/home', '/geo-map', '/tools', '/profile'];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      key: const Key('asha_bottom_nav'),
      selectedIndex: index,
      backgroundColor: AshaColors.cardSurface,
      indicatorColor: AshaColors.primary.withValues(alpha: 0.16),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (next) {
        if (next == index) return;
        final router = GoRouter.maybeOf(context);
        if (router == null) return;
        router.go(routes[next]);
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
        NavigationDestination(icon: Icon(Icons.handyman_outlined), selectedIcon: Icon(Icons.handyman), label: 'Tools'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
