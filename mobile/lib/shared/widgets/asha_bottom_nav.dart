import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'asha_bottom_dock.dart';

/// Master 4-item bottom navigation bar:
/// Home, Map, Tasks, Profile matching Screen 1 and Screen 9.
class AshaBottomNav extends StatelessWidget {
  const AshaBottomNav({
    super.key,
    required this.index,
    this.onTap,
  });

  final int index;
  final ValueChanged<int>? onTap;

  static const items = [
    AshaDockItem(
      icon: Icons.home_rounded,
      label: 'Home',
    ),
    AshaDockItem(
      icon: Icons.map_outlined,
      label: 'Map',
    ),
    AshaDockItem(
      icon: Icons.assignment_outlined,
      label: 'Tasks',
    ),
    AshaDockItem(
      icon: Icons.person_outline_rounded,
      label: 'Profile',
    ),
  ];

  static const routes = [
    '/home',
    '/geo-map',
    '/due-list',
    '/profile',
  ];

  @override
  Widget build(BuildContext context) {
    return AshaBottomDock(
      currentIndex: index,
      onTabSelected: (idx) {
        if (onTap != null) {
          onTap!(idx);
        } else if (idx != index && idx >= 0 && idx < routes.length) {
          context.go(routes[idx]);
        }
      },
      items: items,
    );
  }
}
