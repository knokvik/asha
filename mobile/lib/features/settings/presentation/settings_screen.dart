import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/bhasha/model_store.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/l10n/language_selector_dialog.dart';
import '../../../core/voice/model_manager.dart';
import '../../../core/voice/vosk_service.dart';
import '../../../shared/shell/shell_copy.dart';

/// App preferences kept intentionally simple for the first light-mode release.
/// Voice interpreter packs remain installable here without requiring an APK
/// update, as required by the offline voice workflow.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider).languageCode;
    final manager = ref.watch(modelManagerProvider);
    final descriptors = VoskModelManager.catalog.values.toList()
      ..sort((a, b) => a.modelKey.compareTo(b.modelKey));

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Text(shellText(lang, 'settings')),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          _sectionTitle(shellText(lang, 'appearance')),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.light_mode_outlined,
                color: Color(0xFF2D5F47),
              ),
              title: Text(shellText(lang, 'lightMode')),
              subtitle: Text(
                shellText(lang, 'lightModeDesc'),
              ),
              trailing: const Icon(
                Icons.check_circle,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle(shellText(lang, 'appLanguage')),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.language_rounded,
                color: Color(0xFF2563EB),
              ),
              title: Text(shellText(lang, 'appLanguage')),
              subtitle: Text(shellText(lang, 'appLanguageDesc')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => const LanguageSelectorDialog(),
              ),
            ),
          ),
          const SizedBox(height: 22),
          _sectionTitle(shellText(lang, 'mapNav')),
          _MapStyleSection(lang: lang),
          const SizedBox(height: 22),
          _sectionTitle(shellText(lang, 'voicePacks')),
          Text(
            shellText(lang, 'voicePacksDesc'),
            style: const TextStyle(color: Color(0xFF5F6B64), height: 1.4),
          ),
          const SizedBox(height: 10),
          _InterpreterPackSection(lang: lang),
          const SizedBox(height: 22),
          _sectionTitle(shellText(lang, 'clinicalVoicePacks')),
          ...descriptors.map(
            (descriptor) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ModelPackCard(
                descriptor: descriptor,
                manager: manager,
                lang: lang,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFF8F9FA),
            child: ListTile(
              leading: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF6B7280),
              ),
              title: Text(shellText(lang, 'privateOnDevice')),
              subtitle: Text(
                shellText(lang, 'privateOnDeviceDesc'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF111815),
        ),
      ),
    );
  }
}

class _MapStyleSection extends StatefulWidget {
  final String lang;
  const _MapStyleSection({required this.lang});

  @override
  State<_MapStyleSection> createState() => _MapStyleSectionState();
}

class _MapStyleSectionState extends State<_MapStyleSection> {
  static const _storage = FlutterSecureStorage();
  String _mapStyle = 'street';

  @override
  void initState() {
    super.initState();
    _loadStyle();
  }

  Future<void> _loadStyle() async {
    final style = await _storage.read(key: 'map_view_style') ?? 'street';
    if (mounted) setState(() => _mapStyle = style);
  }

  Future<void> _setStyle(String style) async {
    setState(() => _mapStyle = style);
    await _storage.write(key: 'map_view_style', value: style);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _mapStyle == 'satellite'
                      ? Icons.satellite_alt_rounded
                      : Icons.map_rounded,
                  color: const Color(0xFF2D5F47),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shellText(widget.lang, 'mapBasemapStyle'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        _mapStyle == 'satellite'
                            ? shellText(widget.lang, 'satelliteHybridDesc')
                            : shellText(widget.lang, 'streetDefaultDesc'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.map_outlined, size: 18),
                    label: Text(shellText(widget.lang, 'streetDefault')),
                    selected: _mapStyle == 'street',
                    onSelected: (val) {
                      if (val) _setStyle('street');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    avatar: const Icon(Icons.satellite_alt_rounded, size: 18),
                    label: Text(shellText(widget.lang, 'satelliteHybrid')),
                    selected: _mapStyle == 'satellite',
                    onSelected: (val) {
                      if (val) _setStyle('satellite');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.offline_pin_outlined,
                  size: 15,
                  color: Color(0xFF16A34A),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    shellText(widget.lang, 'mapOfflineCacheNote'),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InterpreterPackSection extends StatefulWidget {
  final String lang;
  const _InterpreterPackSection({required this.lang});

  @override
  State<_InterpreterPackSection> createState() =>
      _InterpreterPackSectionState();
}

class _InterpreterPackSectionState extends State<_InterpreterPackSection> {
  ModelStore? _store;
  DownloadProgress? _progress;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadStore();
  }

  Future<void> _loadStore() async {
    final support = await getApplicationSupportDirectory();
    final store = ModelStore(Directory('${support.path}/bhasha-models'));
    if (!mounted) return;
    setState(() => _store = store);
  }

  Future<void> _run(
    Future<void> Function(void Function(DownloadProgress)) job,
  ) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _progress = null;
    });
    try {
      await job((progress) {
        if (mounted) setState(() => _progress = progress);
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = shellText(widget.lang, 'installErrorMsg'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    if (store == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: LinearProgressIndicator(minHeight: 4),
        ),
      );
    }
    final progress = _progress;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        child: Column(
          children: [
            _InterpreterPackTile(
              icon: Icons.translate_rounded,
              title: shellText(widget.lang, 'interpreterCorePack'),
              subtitle: store.isReady
                  ? shellText(widget.lang, 'installed')
                  : shellText(widget.lang, 'interpreterCoreDesc'),
              installed: store.isReady,
              busy: _busy,
              installLabel: shellText(widget.lang, 'install'),
              onInstall: () => _run(store.ensure),
            ),
            const Divider(height: 1),
            _InterpreterPackTile(
              icon: Icons.record_voice_over_rounded,
              title: shellText(widget.lang, 'askBackPack'),
              subtitle: store.askReady
                  ? shellText(widget.lang, 'installed')
                  : shellText(widget.lang, 'askBackDesc'),
              installed: store.askReady,
              busy: _busy,
              installLabel: shellText(widget.lang, 'install'),
              onInstall: () => _run(store.ensureAsk),
            ),
            const Divider(height: 1),
            _InterpreterPackTile(
              icon: Icons.volume_up_rounded,
              title: shellText(widget.lang, 'hindiVoicePack'),
              subtitle: store.hindiVoiceReady
                  ? shellText(widget.lang, 'installed')
                  : shellText(widget.lang, 'hindiVoiceDesc'),
              installed: store.hindiVoiceReady,
              busy: _busy,
              installLabel: shellText(widget.lang, 'install'),
              onInstall: () => _run(store.ensureHindiVoice),
            ),
            if (progress != null && _busy) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.total > 0
                    ? progress.received / progress.total
                    : null,
                minHeight: 4,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    progress.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
            if (_error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InterpreterPackTile extends StatelessWidget {
  const _InterpreterPackTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.installed,
    required this.busy,
    required this.installLabel,
    required this.onInstall,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool installed;
  final bool busy;
  final String installLabel;
  final VoidCallback onInstall;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: installed
          ? const Icon(Icons.check_circle, color: Color(0xFF16A34A))
          : OutlinedButton(
              onPressed: busy ? null : onInstall,
              child: Text(busy ? '…' : installLabel),
            ),
    );
  }
}

class _ModelPackCard extends StatelessWidget {
  const _ModelPackCard({
    required this.descriptor,
    required this.manager,
    required this.lang,
  });

  final VoskModelDescriptor descriptor;
  final VoskModelManager manager;
  final String lang;

  String get _languageName => switch (descriptor.language) {
    'hi' => 'Hindi',
    'mr' => 'Marathi',
    _ => descriptor.language.toUpperCase(),
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) {
        final status = manager.getStatus(
          descriptor.language,
          type: descriptor.modelType,
        );
        final installed = status == ModelInstallStatus.installed;
        final busy =
            status == ModelInstallStatus.downloading ||
            status == ModelInstallStatus.verifying ||
            status == ModelInstallStatus.extracting;
        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F2EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    descriptor.language.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF2D5F47),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_languageName · ${descriptor.modelType == VoskModelType.full ? 'Full' : 'Compressed'}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${(descriptor.sizeBytes / (1024 * 1024)).round()} MB · ${_statusLabel(status, lang)}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                      if (busy) ...[
                        const SizedBox(height: 7),
                        LinearProgressIndicator(
                          value: manager.getDownloadProgress(
                            descriptor.language,
                            type: descriptor.modelType,
                          ),
                          minHeight: 4,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (installed)
                  IconButton(
                    tooltip: shellText(lang, 'removePack'),
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => manager.removeModel(
                      descriptor.language,
                      type: descriptor.modelType,
                    ),
                  )
                else
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            final success = await manager.installModel(
                              descriptor,
                            );
                            if (!context.mounted || success) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  shellText(lang, 'installErrorMsg'),
                                ),
                              ),
                            );
                          },
                    child: Text(busy ? '…' : shellText(lang, 'install')),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _statusLabel(ModelInstallStatus status, String lang) => switch (status) {
    ModelInstallStatus.notInstalled => shellText(lang, 'notInstalled'),
    ModelInstallStatus.downloading => shellText(lang, 'downloading'),
    ModelInstallStatus.verifying => shellText(lang, 'verifying'),
    ModelInstallStatus.extracting => shellText(lang, 'preparing'),
    ModelInstallStatus.installed => shellText(lang, 'installed'),
    ModelInstallStatus.deferredToWifi => shellText(lang, 'waitingWifi'),
    ModelInstallStatus.error => shellText(lang, 'installFailed'),
  };
}
