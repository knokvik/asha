import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../shared/providers/core_providers.dart';

/// Reminders & Notifications screen.
///
/// Shows upcoming and overdue visit schedules as reminders, so the ASHA worker
/// knows which beneficiaries need attention today. Uses the same [visitSchedules]
/// table as the due list; this view filters to pending/rescheduled entries.
///
/// Route: `/reminders`
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});

  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  List<VisitSchedule> _reminders = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final rows = await (db.select(db.visitSchedules)
            ..where(
              (t) =>
                  t.status.equals('pending') | t.status.equals('rescheduled'),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.dueDate)])
            ..limit(100))
          .get();
      if (!mounted) return;
      setState(() {
        _reminders = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).languageCode;
    final title = lang == 'hi'
        ? 'रिमाइंडर'
        : lang == 'mr'
        ? 'रिमाइंडर'
        : 'Reminders';

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              setState(() => _loading = true);
              _load();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.orange),
              const SizedBox(height: 12),
              const Text(
                'Could not load reminders',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: AshaColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    if (_reminders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 56,
                color: AshaColors.textSecondary,
              ),
              SizedBox(height: 16),
              Text(
                'No pending reminders',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8),
              Text(
                'Scheduled beneficiary visit reminders will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AshaColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _reminders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            _ReminderTile(schedule: _reminders[index]),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.schedule});

  final VisitSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final dueDate = DateTime.fromMillisecondsSinceEpoch(schedule.dueDate);
    final isOverdue = dueDate.isBefore(DateTime.now());
    final accent = isOverdue ? Colors.red.shade700 : Colors.teal.shade700;

    return Card(
      margin: EdgeInsets.zero,
      color: AshaColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isOverdue ? Colors.red.shade200 : AshaColors.borderSubtle,
        ),
      ),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: accent.withValues(alpha: 0.1),
          child: Icon(
            isOverdue
                ? Icons.notification_important_rounded
                : Icons.notifications_active_rounded,
            color: accent,
            size: 20,
          ),
        ),
        title: Text(
          schedule.visitType.replaceAll('_', ' ').toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Beneficiary: ${schedule.memberId}',
              style: const TextStyle(fontSize: 11, color: AshaColors.textSecondary),
            ),
            const SizedBox(height: 2),
            Text(
              isOverdue
                  ? 'Overdue since ${_formatDate(dueDate)}'
                  : 'Due ${_formatDate(dueDate)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          tooltip: 'Go to beneficiary',
          onPressed: () => context.push('/beneficiary/${schedule.memberId}'),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
