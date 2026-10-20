import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/language_provider.dart';
import 'asha_bottom_dock.dart';

/// Master 4-item bottom navigation bar:
/// Home, Map, Tasks, Profile matching Screen 1 and Screen 9.
class AshaBottomNav extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(languageProvider).languageCode;
    final labels = _dockLabels[code] ?? _dockLabels['en']!;
    final items = [
      for (var i = 0; i < AshaBottomNav.items.length; i++)
        AshaDockItem(icon: AshaBottomNav.items[i].icon, label: labels[i]),
    ];
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

const _dockLabels = <String, List<String>>{
  'en': ['Home', 'Map', 'Tasks', 'Profile'],
  'hi': ['होम', 'नक्शा', 'कार्य', 'प्रोफ़ाइल'],
  'mr': ['होम', 'नकाशा', 'कामे', 'प्रोफाइल'],
  'bn': ['হোম', 'মানচিত্র', 'কাজ', 'প্রোফাইল'],
  'te': ['హోమ్', 'మ్యాప్', 'పనులు', 'ప్రొఫైల్'],
  'ta': ['முகப்பு', 'வரைபடம்', 'பணிகள்', 'சுயவிவரம்'],
  'kn': ['ಮುಖಪುಟ', 'ನಕ್ಷೆ', 'ಕೆಲಸ', 'ಪ್ರೊಫೈಲ್'],
  'ml': ['ഹോം', 'മാപ്പ്', 'ജോലികൾ', 'പ്രൊഫൈൽ'],
  'or': ['ହୋମ', 'ମାନଚିତ୍ର', 'କାମ', 'ପ୍ରୋଫାଇଲ'],
  'gu': ['હોમ', 'નકશો', 'કાર્યો', 'પ્રોફાઇલ'],
  'pa': ['ਹੋਮ', 'ਨਕਸ਼ਾ', 'ਕੰਮ', 'ਪ੍ਰੋਫਾਈਲ'],
  'as': ['হোম', 'মেপ', 'কাম', 'প্ৰফাইল'],
};
