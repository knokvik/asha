import 'package:flutter/material.dart';

import '../../../core/bhasha/home_page.dart';
import '../../../core/bhasha/settings_store.dart';

/// They speak and I ask, copied from the offline voice page.
///
/// Opened from triage so the worker can cross the language barrier. It does
/// not write a triage answer.
class LanguageBridgeScreen extends StatefulWidget {
  const LanguageBridgeScreen({super.key, this.notice});

  final String? notice;

  @override
  State<LanguageBridgeScreen> createState() => _LanguageBridgeScreenState();
}

class _LanguageBridgeScreenState extends State<LanguageBridgeScreen> {
  SettingsStore? _settings;
  var _closed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = SettingsStore();
    try {
      await store.load();
    } catch (_) {
      // Defaults are already on the store. Open the page anyway.
    }
    if (!mounted || _closed) {
      store.dispose();
      return;
    }
    setState(() => _settings = store);
  }

  @override
  void dispose() {
    _closed = true;
    _settings?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    if (settings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return HomePage(
      settings: settings,
      title: 'They speak / I ask',
      notice: widget.notice ??
          'They speak hears the family and shows English. I ask turns your English into their language. Neither one sets the triage colour.',
    );
  }
}
