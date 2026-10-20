import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/language_selector_dialog.dart';
import '../../../shared/widgets/asha_bottom_nav.dart';
import '../../map/presentation/map_pack_screen.dart';
import '../../triage/presentation/language_bridge_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('profile_screen'),
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        title: const Text('Profile'),
      ),
      bottomNavigationBar: const AshaBottomNav(index: 3),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 36,
            backgroundColor: AshaColors.primary,
            child: Text('SS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
          ),
          const SizedBox(height: 12),
          const Text('Sunita Sharma', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const Text('ASHA · Pimpri-Chinchwad · ward W3'),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.public_off),
            title: Text('Field pack is on this phone'),
            subtitle: Text('Wards, facilities, and disease counts do not need a network.'),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English, हिन्दी, मराठी'),
            onTap: () => showDialog(context: context, builder: (_) => const LanguageSelectorDialog()),
          ),
          ListTile(
            leading: const Icon(Icons.record_voice_over),
            title: const Text('Voice pack'),
            subtitle: const Text('Download the offline voice once, then it stays on this phone.'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LanguageBridgeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Maps pack'),
            subtitle: const Text('Embedded India, or download one state.'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const MapPackScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
