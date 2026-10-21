import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/language_provider.dart';
import 'asha_bottom_dock.dart';

/// Master bottom navigation bar:
/// Home, Map, centred Triage, Tasks, and Profile.
class AshaBottomNav extends ConsumerWidget {
  const AshaBottomNav({super.key, required this.index, this.onTap});

  final int index;
  final ValueChanged<int>? onTap;

  static const items = [
    AshaDockItem(icon: Icons.home_rounded, label: 'Home'),
    AshaDockItem(icon: Icons.map_outlined, label: 'Map'),
    AshaDockItem(
      icon: Icons.emergency_rounded,
      label: 'Triage',
      isAction: true,
    ),
    AshaDockItem(icon: Icons.assignment_outlined, label: 'Tasks'),
    AshaDockItem(icon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  static const routes = [
    '/home',
    '/geo-map',
    '/triage',
    '/due-list',
    '/profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String code = 'en';
    try {
      code = ref.watch(languageProvider).languageCode;
    } catch (_) {
      // Standalone widget test without ProviderScope
    }
    final labels = _dockLabels[code] ?? _dockLabels['en']!;
    final items = [
      for (var i = 0; i < AshaBottomNav.items.length; i++)
        AshaDockItem(
          icon: AshaBottomNav.items[i].icon,
          label: labels[i],
          isAction: AshaBottomNav.items[i].isAction,
        ),
    ];
    return AshaBottomDock(
      currentIndex: index >= 2 ? index + 1 : index,
      onTabSelected: (idx) {
        if (idx == 2) {
          context.push('/triage');
          return;
        }
        final shellIndex = idx > 2 ? idx - 1 : idx;
        if (onTap != null) {
          if (shellIndex != index) onTap!(shellIndex);
        } else if (shellIndex != index && shellIndex >= 0) {
          context.go(routes[idx]);
        }
      },
      items: items,
    );
  }
}

const _dockLabels = <String, List<String>>{
  'en': ['Home', 'Map', 'Triage', 'Tasks', 'Profile'],
  'hi': ['होम', 'नक्शा', 'ट्राइएज', 'कार्य', 'प्रोफ़ाइल'],
  'mr': ['होम', 'नकाशा', 'ट्रायज', 'कामे', 'प्रोफाइल'],
  'bn': ['হোম', 'মানচিত্র', 'ট্রায়াজ', 'কাজ', 'প্রোফাইল'],
  'te': ['హోమ్', 'మ్యాప్', 'ట్రయాజ్', 'పనులు', 'ప్రొఫైల్'],
  'ta': ['முகப்பு', 'வரைபடம்', 'ட்ரையாஜ்', 'பணிகள்', 'சுயவிவரம்'],
  'kn': ['ಮುಖಪುಟ', 'ನಕ್ಷೆ', 'ಟ್ರಯಾಜ್', 'ಕೆಲಸ', 'ಪ್ರೊಫೈಲ್'],
  'ml': ['ഹോം', 'മാപ്പ്', 'ട്രയാജ്', 'ജോലികൾ', 'പ്രൊഫൈൽ'],
  'or': ['ହୋମ', 'ମାନଚିତ୍ର', 'ଟ୍ରାଏଜ୍', 'କାମ', 'ପ୍ରୋଫାଇଲ'],
  'gu': ['હોમ', 'નકશો', 'ટ્રાયજ', 'કાર્યો', 'પ્રોફાઇલ'],
  'pa': ['ਹੋਮ', 'ਨਕਸ਼ਾ', 'ਟ੍ਰਾਈਏਜ', 'ਕੰਮ', 'ਪ੍ਰੋਫਾਈਲ'],
  'as': ['হোম', 'মেপ', 'ট্ৰায়েজ', 'কাম', 'প্ৰফাইল'],
};
