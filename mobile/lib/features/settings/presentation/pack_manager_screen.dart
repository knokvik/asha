import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/bhasha/languages.dart';
import '../../../core/bhasha/model_store.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/packs/language_content_pack_store.dart';
import '../../../core/packs/map_content_pack_store.dart';
import '../../../core/packs/pack_manager.dart';
import '../../../core/security/auth_service.dart';

/// Explicit installer for optional offline capabilities.
///
/// Nothing in this page is preinstalled merely because a screen exists. This
/// keeps the base APK small and makes storage ownership clear to the worker.
class PackManagerScreen extends ConsumerStatefulWidget {
  const PackManagerScreen({super.key});

  @override
  ConsumerState<PackManagerScreen> createState() => _PackManagerScreenState();
}

class _PackManagerScreenState extends ConsumerState<PackManagerScreen> {
  final MapContentPackStore _mapStore = MapContentPackStore();
  final LanguageContentPackStore _languageStore = LanguageContentPackStore();
  ModelStore? _interpreterStore;
  bool _loading = true;
  bool _busy = false;
  double? _mapProgress;
  String? _error;
  int _mapBytes = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final support = await getApplicationSupportDirectory();
      final interpreter = ModelStore(Directory('${support.path}/bhasha-models'));
      final installed = await _mapStore.isInstalled();
      final bytes = installed ? await _mapStore.installedBytes() : 0;
      if (!mounted) return;
      ref.read(offlinePackProvider.notifier).setMapInstalled(installed);
      setState(() {
        _interpreterStore = interpreter;
        _mapBytes = bytes;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _run(Future<void> Function() job) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _mapProgress = null;
    });
    try {
      await job();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _installMap() => _run(() async {
        final baseUrl = await resolveAshaApiBaseUrl();
        await _mapStore.install(
          apiBaseUrl: baseUrl,
          onProgress: (received, total) {
            if (!mounted) return;
            setState(
              () => _mapProgress = total > 0 ? received / total : null,
            );
          },
        );
        final bytes = await _mapStore.installedBytes();
        await ref.read(offlinePackProvider.notifier).setMapInstalled(true);
        if (mounted) setState(() => _mapBytes = bytes);
      });

  Future<void> _removeMap() => _run(() async {
        await _mapStore.remove();
        await ref.read(offlinePackProvider.notifier).setMapInstalled(false);
        if (mounted) setState(() => _mapBytes = 0);
      });

  Future<void> _installInterpreterLanguage(IndicLanguage language) =>
      _run(() async {
        final store = _interpreterStore;
        if (store == null) return;
        // One verified model core is shared by the language choices. The
        // language is not exposed until that download has completed.
        await store.ensure((_) {});
        await ref
            .read(offlinePackProvider.notifier)
            .setInterpreterLanguageInstalled(language.code, true);
      });

  Future<void> _removeInterpreterLanguage(IndicLanguage language) => _run(
        () => ref
            .read(offlinePackProvider.notifier)
            .setInterpreterLanguageInstalled(language.code, false),
      );

  Future<void> _removeInterpreterCore() => _run(() async {
        final store = _interpreterStore;
        if (store == null) return;
        await store.removeAll();
        await ref.read(offlinePackProvider.notifier).clearInterpreterLanguages();
      });

  @override
  Widget build(BuildContext context) {
    final packState = ref.watch(offlinePackProvider);
    final currentLanguage = ref.watch(languageProvider).languageCode;
    final store = _interpreterStore;
    final mapInstalled = packState.mapInstalled;

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: const Text('Offline packs'),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _InfoCard(
                  icon: Icons.inventory_2_outlined,
                  text:
                      'Install only what this phone needs. Removing a pack deletes its downloaded files; local health records are never removed.',
                ),
                const SizedBox(height: 14),
                _PackExpansion(
                  icon: Icons.language_rounded,
                  title: 'App language packs',
                  subtitle: '${packState.appLanguageCodes.length} language${packState.appLanguageCodes.length == 1 ? '' : 's'} available',
                  children: [
                    for (final language in supportedLanguages)
                      _LanguageRow(
                        language: language,
                        installed: packState.hasAppLanguage(language.code),
                        base: language.code == 'en',
                        busy: _busy,
                        onInstall: () => _run(() async {
                          final baseUrl = await resolveAshaApiBaseUrl();
                          await _languageStore.install(
                            languageCode: language.code,
                            apiBaseUrl: baseUrl,
                          );
                          await ref
                              .read(offlinePackProvider.notifier)
                              .setAppLanguageInstalled(language.code, true);
                        }),
                        onRemove: () async {
                          await _run(
                            () async {
                              await _languageStore.remove(language.code);
                              await ref
                                  .read(offlinePackProvider.notifier)
                                  .setAppLanguageInstalled(language.code, false);
                            },
                          );
                          if (currentLanguage == language.code && mounted) {
                            await ref
                                .read(languageProvider.notifier)
                                .setLanguageCode('en');
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _PackExpansion(
                  icon: Icons.map_outlined,
                  title: 'Offline maps',
                  subtitle: mapInstalled
                      ? 'India map data · ${_formatBytes(_mapBytes)} on this phone'
                      : 'Not installed in the base APK',
                  children: [
                    _PackActionRow(
                      icon: Icons.public_rounded,
                      title: 'India facility and street map',
                      detail: mapInstalled
                          ? 'Saved for offline use'
                          : 'About 4.3 MB. Includes facilities, roads, household and district reference data.',
                      installed: mapInstalled,
                      busy: _busy,
                      onInstall: _installMap,
                      onRemove: _removeMap,
                    ),
                    const Divider(height: 1),
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.satellite_alt_outlined),
                      title: Text('Satellite imagery'),
                      subtitle: Text(
                        'Available inside an installed map when connectivity is present. Imagery is never preloaded into the APK.',
                      ),
                    ),
                    if (_mapProgress != null && _busy) ...[
                      const SizedBox(height: 4),
                      LinearProgressIndicator(value: _mapProgress, minHeight: 5),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _PackExpansion(
                  icon: Icons.record_voice_over_outlined,
                  title: 'Interpreter packs',
                  subtitle: packState.interpreterLanguageCodes.isEmpty
                      ? 'No interpreter language installed'
                      : '${packState.interpreterLanguageCodes.length} language${packState.interpreterLanguageCodes.length == 1 ? '' : 's'} available offline',
                  children: [
                    if (store == null)
                      const LinearProgressIndicator(minHeight: 4)
                    else ...[
                      for (final language in indicLanguages)
                        _PackActionRow(
                          icon: Icons.translate_rounded,
                          title: language.nativeName,
                          detail: language.speech
                              ? '${language.name} · voice and typed interpretation'
                              : '${language.name} · typed interpretation',
                          installed: packState.hasInterpreterLanguage(language.code),
                          busy: _busy,
                          onInstall: () => _installInterpreterLanguage(language),
                          onRemove: () => _removeInterpreterLanguage(language),
                        ),
                      if (store.isReady) ...[
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFB91C1C),
                          ),
                          title: const Text('Remove interpreter core'),
                          subtitle: const Text(
                            'Removes all interpreter model files and every interpreter language from this phone.',
                          ),
                          trailing: TextButton(
                            onPressed: _busy ? null : _removeInterpreterCore,
                            child: const Text('Remove'),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _InfoCard(
                    icon: Icons.error_outline_rounded,
                    color: const Color(0xFFB91C1C),
                    text: _error!,
                  ),
                ],
              ],
            ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _PackExpansion extends StatelessWidget {
  const _PackExpansion({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: Icon(icon, color: AshaColors.primary),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: children,
        ),
      );
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.installed,
    required this.base,
    required this.busy,
    required this.onInstall,
    required this.onRemove,
  });

  final AppLanguage language;
  final bool installed;
  final bool base;
  final bool busy;
  final VoidCallback onInstall;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(language.nativeName),
        subtitle: Text(base ? '${language.englishName} · included with the app' : language.englishName),
        trailing: base || installed
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D)),
                  if (!base)
                    IconButton(
                      tooltip: 'Remove ${language.englishName}',
                      onPressed: busy ? null : onRemove,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                ],
              )
            : OutlinedButton(
                onPressed: busy ? null : onInstall,
                child: const Text('Install'),
              ),
      );
}

class _PackActionRow extends StatelessWidget {
  const _PackActionRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.installed,
    required this.busy,
    required this.onInstall,
    required this.onRemove,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool installed;
  final bool busy;
  final VoidCallback onInstall;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AshaColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(detail),
        trailing: installed
            ? IconButton(
                tooltip: 'Remove $title',
                onPressed: busy ? null : onRemove,
                icon: const Icon(Icons.delete_outline_rounded),
              )
            : OutlinedButton(
                onPressed: busy ? null : onInstall,
                child: Text(busy ? '…' : 'Install'),
              ),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color ?? const Color(0xFF2563EB)),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
          ],
        ),
      );
}
