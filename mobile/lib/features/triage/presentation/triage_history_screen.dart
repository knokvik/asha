import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/shell/shell_copy.dart';

enum _HistoryFilter { all, phcFollowups, areaSignals, triageRed }

/// Local history of triage packets, PHC follow-up instructions, and disease radar alerts.
/// Features generous component spacing, high-contrast chips, and ticket-style modal window.
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
  _HistoryFilter _activeFilter = _HistoryFilter.all;

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
      if (!mounted) return;
      setState(() => _error = error);
    }
  }

  String _date(int milliseconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  void _showVisitDetailModal(dynamic visit) {
    final lang = ref.read(languageProvider).languageCode;
    final days = DateTime.fromMillisecondsSinceEpoch(visit.dueDate)
        .difference(DateTime.now())
        .inDays;
    final timing = days <= 0 ? 'Due Today' : 'Due in $days days';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.visitType,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AshaColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Program: ${visit.programCode} · Rampur PHC',
                        style: const TextStyle(fontSize: 12, color: AshaColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    timing,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AshaColors.borderSubtle),
            const SizedBox(height: 14),

            // Detail items
            _buildDetailTile(Icons.calendar_today_rounded, 'Planned Visit Date', _date(visit.dueDate)),
            const SizedBox(height: 10),
            _buildDetailTile(Icons.rule_rounded, 'Clinical Recommendation', 'Prescribed by PHC Medical Officer for immediate field follow-up.'),
            const SizedBox(height: 10),
            _buildDetailTile(Icons.health_and_safety_outlined, 'Target Program', '${visit.programCode} Protocol'),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(shellText(lang, 'close')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AshaColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/due-list');
                    },
                    icon: const Icon(Icons.assignment_outlined, size: 18),
                    label: Text(shellText(lang, 'openDueList')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTriageDetailModal(dynamic result) {
    final lang = ref.read(languageProvider).languageCode;
    final isRed = result.flag.toString().toLowerCase() == 'red';
    final flagStr = result.flag.toString().toUpperCase();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isRed ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isRed ? Icons.emergency_rounded : Icons.health_and_safety_rounded,
                    color: isRed ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$flagStr Triage Assessment',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: isRed ? const Color(0xFFDC2626) : AshaColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Record ID: ${_shortId(result.id)} · Evaluated ${_date(result.evaluatedAt)}',
                        style: const TextStyle(fontSize: 12, color: AshaColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isRed ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isRed ? const Color(0xFFFCA5A5) : const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    flagStr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isRed ? const Color(0xFFB42318) : const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AshaColors.borderSubtle),
            const SizedBox(height: 14),

            _buildDetailTile(Icons.policy_outlined, 'Clinical Protocol Engine', 'Rule Version: ${result.ruleVersionId ?? "v2.4-national"}'),
            const SizedBox(height: 10),
            _buildDetailTile(
              Icons.warning_amber_rounded,
              'Clinical Priority',
              isRed
                  ? 'Red Danger: Immediate medical escalation to PHC Emergency Unit.'
                  : 'Normal/Moderate: Routine home monitoring and medication adherence.',
            ),
            const SizedBox(height: 10),
            _buildDetailTile(Icons.medical_services_outlined, 'Destination Facility', 'PHC Shahpur Emergency Unit'),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(shellText(lang, 'close')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRed ? const Color(0xFFDC2626) : AshaColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/tracking');
                    },
                    icon: const Icon(Icons.qr_code_rounded, size: 18),
                    label: const Text('View Ticket Slip'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAreaAlertModal(Map<String, dynamic> notification) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.radar_rounded, color: Color(0xFFD97706), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title']?.toString() ?? 'Area Disease Signal',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AshaColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'IDSP Cluster Surveillance Alert',
                        style: TextStyle(fontSize: 12, color: AshaColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: AshaColors.borderSubtle),
            const SizedBox(height: 14),

            _buildDetailTile(Icons.info_outline_rounded, 'Surveillance Notice', notification['body']?.toString() ?? 'Area disease cluster identified in sector.'),
            const SizedBox(height: 10),
            _buildDetailTile(Icons.check_circle_outline_rounded, 'Required Worker Actions', 'Active household case search, distribute ORS/zinc packets, report febrile cases.'),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AshaColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood & Acknowledged'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AshaColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AshaColors.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AshaColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AshaColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AshaColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).languageCode;

    // Filter results
    final showVisits = _activeFilter == _HistoryFilter.all || _activeFilter == _HistoryFilter.phcFollowups;
    final showAlerts = _activeFilter == _HistoryFilter.all || _activeFilter == _HistoryFilter.areaSignals;
    final showTriage = _activeFilter == _HistoryFilter.all || _activeFilter == _HistoryFilter.triageRed;

    final visibleResults = _activeFilter == _HistoryFilter.triageRed
        ? _results.where((r) => r.flag.toString().toLowerCase() == 'red').toList()
        : _results;

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Text(
          shellText(lang, 'updatesTriageHistory'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: RefreshIndicator(
        color: AshaColors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // Filter Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('All Updates', _HistoryFilter.all),
                  const SizedBox(width: 8),
                  _buildChip('PHC Follow-ups', _HistoryFilter.phcFollowups),
                  const SizedBox(width: 8),
                  _buildChip('Area Signals', _HistoryFilter.areaSignals),
                  const SizedBox(width: 8),
                  _buildChip('Red Triage Alerts', _HistoryFilter.triageRed),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Text(
                  '${shellText(lang, 'couldNotLoadUpdates')}: $_error',
                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
                ),
              ),

            // 1. PHC Recommendations Section
            if (showVisits) ...[
              Text(
                shellText(lang, 'phcRecommendations'),
                style: AshaTypography.sectionTitle,
              ),
              const SizedBox(height: 12),
              if (_visits.isEmpty)
                _buildEmptyCard(
                  icon: Icons.inbox_outlined,
                  title: shellText(lang, 'noNewPhcFollowups'),
                  subtitle: shellText(lang, 'serverRecommendationsSync'),
                )
              else
                ..._visits.map((visit) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildVisitCard(visit),
                )),
              const SizedBox(height: 24),
            ],

            // 2. Area Signals Section
            if (showAlerts && _areaNotifications.isNotEmpty) ...[
              Text(
                shellText(lang, 'sharedAreaAlerts'),
                style: AshaTypography.sectionTitle,
              ),
              const SizedBox(height: 12),
              ..._areaNotifications.map((notification) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAreaNotificationCard(notification),
              )),
              const SizedBox(height: 24),
            ],

            // 3. Triage History Section
            if (showTriage) ...[
              Text(
                shellText(lang, 'triageHistory'),
                style: AshaTypography.sectionTitle,
              ),
              const SizedBox(height: 12),
              if (visibleResults.isEmpty)
                _buildEmptyCard(
                  icon: Icons.history,
                  title: shellText(lang, 'noTriageYet'),
                  subtitle: 'Completed triage records are stored locally.',
                )
              else
                ...visibleResults.map((result) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTriageCard(result),
                )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, _HistoryFilter filter) {
    final isSelected = _activeFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AshaColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
        selected: isSelected,
        selectedColor: AshaColors.primary,
        backgroundColor: AshaColors.surfaceMuted,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AshaColors.primary : const Color(0xFFE5E7EB),
          width: 1.2,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (selected) {
          if (selected) setState(() => _activeFilter = filter);
        },
      ),
    );
  }

  Widget _buildVisitCard(dynamic visit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: AshaShapes.cardRadius,
        border: Border.all(color: AshaColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AshaShapes.cardRadius,
        child: InkWell(
          borderRadius: AshaShapes.cardRadius,
          onTap: () => _showVisitDetailModal(visit),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_hospital_outlined, color: Color(0xFF2563EB), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        visit.visitType,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AshaColors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${visit.programCode} · Planned ${_date(visit.dueDate)}',
                        style: const TextStyle(fontSize: 12, color: AshaColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AshaColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAreaNotificationCard(Map<String, dynamic> notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: AshaShapes.cardRadius,
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AshaShapes.cardRadius,
        child: InkWell(
          borderRadius: AshaShapes.cardRadius,
          onTap: () => _showAreaAlertModal(notification),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.radar_rounded, color: Color(0xFFD97706), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title']?.toString() ?? 'Area Signal',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AshaColors.textPrimary),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        notification['body']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AshaColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AshaColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTriageCard(dynamic result) {
    final isRed = result.flag.toString().toLowerCase() == 'red';
    final flagStr = result.flag.toString().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: AshaShapes.cardRadius,
        border: Border.all(
          color: isRed ? const Color(0xFFFCA5A5) : AshaColors.borderSubtle,
          width: isRed ? 1.4 : 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AshaShapes.cardRadius,
        child: InkWell(
          borderRadius: AshaShapes.cardRadius,
          onTap: () => _showTriageDetailModal(result),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isRed ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isRed ? Icons.emergency_rounded : Icons.health_and_safety_outlined,
                    color: isRed ? const Color(0xFFDC2626) : AshaColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$flagStr Triage',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: isRed ? const Color(0xFFDC2626) : AshaColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isRed ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              flagStr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isRed ? const Color(0xFFB42318) : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Evaluated ${_date(result.evaluatedAt)} · ${_shortId(result.id)}',
                        style: const TextStyle(fontSize: 12, color: AshaColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 20, color: AshaColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: AshaShapes.cardRadius,
        border: Border.all(color: AshaColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AshaColors.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AshaColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AshaColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
