import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/shell/shell_copy.dart';

/// Local history of triage packets and PHC follow-up instructions received by
/// the normal sync pull. No demo notification text is used here.
class TriageHistoryScreen extends ConsumerStatefulWidget {
  const TriageHistoryScreen({super.key});

  @override
  ConsumerState<TriageHistoryScreen> createState() =>
      _TriageHistoryScreenState();
}

class _TriageHistoryScreenState extends ConsumerState<TriageHistoryScreen> {
  List<dynamic> _visits = const [];
  List<dynamic> _results = const [];
  List<Map<String, dynamic>> _areaNotifications = const [];
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final horizon = DateTime.now()
          .add(const Duration(days: 25))
          .millisecondsSinceEpoch;
      final visits =
          await (db.select(db.visitSchedules)
                ..where(
                  (row) =>
                      row.status.isIn(const ['pending', 'rescheduled']) &
                      row.dueDate.isBiggerOrEqualValue(now) &
                      row.dueDate.isSmallerOrEqualValue(horizon),
                )
                ..orderBy([(row) => OrderingTerm.asc(row.dueDate)]))
              .get();
      final results =
          await (db.select(db.triageResults)
                ..orderBy([(row) => OrderingTerm.desc(row.evaluatedAt)])
                ..limit(30))
              .get();
      final notificationJson = await const FlutterSecureStorage().read(
        key: 'area_notifications_json',
      );
      final decodedNotifications = notificationJson == null
          ? const <dynamic>[]
          : jsonDecode(notificationJson);
      if (!mounted) return;
      setState(() {
        _visits = visits;
        _results = results;
        _areaNotifications = decodedNotifications is List
            ? decodedNotifications
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
            : const [];
      });
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  String _date(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  void _showVisitMessage(dynamic visit) {
    final lang = ref.read(languageProvider).languageCode;
    final days = DateTime.fromMillisecondsSinceEpoch(visit.dueDate)
        .difference(DateTime.now())
        .inDays;
    final timing = days <= 0 ? 'today' : 'in $days days';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(shellText(lang, 'newPhcFollowup')),
        content: Text(
          '${visit.visitType} is recommended $timing.\n\n'
          'Program: ${visit.programCode}\n'
          'Planned date: ${_date(visit.dueDate)}\n\n'
          'Open the Due List to review the visit and complete it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(shellText(lang, 'close')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/due-list');
            },
            child: Text(shellText(lang, 'openDueList')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(shellText(lang, 'updatesTriageHistory')),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('${shellText(lang, 'couldNotLoadUpdates')}: $_error'),
                ),
              ),
            Text(shellText(lang, 'phcRecommendations'), style: AshaTypography.sectionTitle),
            const SizedBox(height: 8),
            if (_visits.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.inbox_outlined),
                  title: Text(shellText(lang, 'noNewPhcFollowups')),
                  subtitle: Text(
                    shellText(lang, 'serverRecommendationsSync'),
                  ),
                ),
              )
            else
              for (final visit in _visits)
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.local_hospital_outlined),
                    ),
                    title: Text(visit.visitType),
                    subtitle: Text(
                      '${visit.programCode} · planned ${_date(visit.dueDate)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showVisitMessage(visit),
                  ),
                ),
            if (_areaNotifications.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(shellText(lang, 'sharedAreaAlerts'), style: AshaTypography.sectionTitle),
              const SizedBox(height: 8),
              for (final notification in _areaNotifications)
                Card(
                  color: Colors.amber.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.radar_outlined),
                    title: Text(
                      notification['title']?.toString() ?? 'Area signal',
                    ),
                    subtitle: Text(notification['body']?.toString() ?? ''),
                  ),
                ),
            ],
            const SizedBox(height: 20),
            Text(shellText(lang, 'triageHistory'), style: AshaTypography.sectionTitle),
            const SizedBox(height: 8),
            if (_results.isEmpty)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(shellText(lang, 'noTriageYet')),
                ),
              )
            else
              for (final result in _results)
                Card(
                  child: ListTile(
                    leading: Icon(
                      result.flag.toString().toLowerCase() == 'red'
                          ? Icons.emergency
                          : Icons.health_and_safety_outlined,
                      color: result.flag.toString().toLowerCase() == 'red'
                          ? Colors.red
                          : AshaColors.primary,
                    ),
                    title: Text(
                      '${result.flag.toString().toUpperCase()} triage',
                    ),
                    subtitle: Text(
                      'Evaluated ${_date(result.evaluatedAt)} · ${result.id}',
                    ),
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Triage record'),
                        content: Text(
                          'Flag: ${result.flag.toString().toUpperCase()}\n'
                          'Rule version: ${result.ruleVersionId}\n'
                          'Evaluated: ${_date(result.evaluatedAt)}',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(shellText(lang, 'close')),
                          ),
                        ],
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
