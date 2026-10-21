import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/providers/core_providers.dart';

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
    final days = DateTime.fromMillisecondsSinceEpoch(visit.dueDate)
        .difference(DateTime.now())
        .inDays;
    final timing = days <= 0 ? 'today' : 'in $days days';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New PHC follow-up'),
        content: Text(
          '${visit.visitType} is recommended $timing.\n\n'
          'Program: ${visit.programCode}\n'
          'Planned date: ${_date(visit.dueDate)}\n\n'
          'Open the Due List to review the visit and complete it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/due-list');
            },
            child: const Text('Open Due List'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Updates & triage history'),
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
                  child: Text('Could not load local updates: $_error'),
                ),
              ),
            Text('PHC recommendations', style: AshaTypography.sectionTitle),
            const SizedBox(height: 8),
            if (_visits.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.inbox_outlined),
                  title: Text('No new PHC follow-ups'),
                  subtitle: Text(
                    'Server recommendations will appear after sync.',
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
              Text('Shared area alerts', style: AshaTypography.sectionTitle),
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
            Text('Triage history', style: AshaTypography.sectionTitle),
            const SizedBox(height: 8),
            if (_results.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('No triage assessments yet'),
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
                            child: const Text('Close'),
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
