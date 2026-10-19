import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/language_selector_dialog.dart';
import '../../../shared/widgets/app_drawer.dart';
import '../../../shared/widgets/asha_badge.dart';
import '../../../shared/widgets/asha_card.dart';
import '../domain/due_list_models.dart';
import '../domain/task_scheduler.dart';

/// Home screen — Prioritised Due List, Calendar & Programme Coverage (Requirements 24.1 – 24.7).
class DueListScreen extends ConsumerStatefulWidget {
  const DueListScreen({super.key, this.initialTab = 0});

  /// 0 due list, 1 calendar, 2 coverage. Each route opens on its own page.
  final int initialTab;

  @override
  ConsumerState<DueListScreen> createState() => _DueListScreenState();
}

class _DueListScreenState extends ConsumerState<DueListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;

  List<DueTask> _allTasks = [];
  Map<UrgencyGroup, Map<String, List<DueTask>>> _groupedTasks = {};
  WorkloadSummary? _workloadSummary;
  List<ProgramCoverage> _coverageSummary = [];
  Map<int, int> _calendarDailyCounts = {};

  String _selectedHamlet = 'All';
  String _selectedProgram = 'All';
  final int _workloadThreshold = 8;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTab.clamp(0, 2));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final scheduler = ref.read(taskSchedulerProvider);

      final tasks = await scheduler.fetchDueTasks(
        hamletFilter: _selectedHamlet == 'All' ? null : _selectedHamlet,
        programFilter: _selectedProgram == 'All' ? null : _selectedProgram,
        workloadThreshold: _workloadThreshold,
      );

      final grouped = await scheduler.fetchGroupedDueList(
        hamletFilter: _selectedHamlet == 'All' ? null : _selectedHamlet,
        programFilter: _selectedProgram == 'All' ? null : _selectedProgram,
        workloadThreshold: _workloadThreshold,
      );

      final workload = await scheduler.fetchWorkloadSummary(
        workloadThreshold: _workloadThreshold,
      );

      final coverage = await scheduler.fetchProgramCoverageSummary();

      final now = DateTime.now();
      final calCounts = await scheduler.fetchMonthDailyCounts(
        year: now.year,
        month: now.month,
      );

      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _groupedTasks = grouped;
          _workloadSummary = workload;
          _coverageSummary = coverage;
          _calendarDailyCounts = calCounts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  List<String> get _availableHamlets {
    final hamlets = <String>{'All'};
    if (_workloadSummary != null) {
      hamlets.addAll(_workloadSummary!.tasksByHamlet.keys);
    }
    for (final t in _allTasks) {
      if (t.hamlet.isNotEmpty) hamlets.add(t.hamlet);
    }
    return hamlets.toList()..sort();
  }

  List<String> get _availablePrograms {
    final progs = <String>{'All'};
    for (final t in _allTasks) {
      progs.add(t.programCode);
    }
    return progs.toList()..sort();
  }

  // ── Skip & Reschedule Dialog (Requirement 24.4) ────────────────────────────
  Future<void> _showSkipDialog(DueTask task) async {
    SkipReason selectedReason = SkipReason.notAtHome;
    final notesController = TextEditingController();
    DateTime? chosenRescheduleDate;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Skip / Reschedule Visit: ${task.memberName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Task: ${task.visitType}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<SkipReason>(
                  initialValue: selectedReason,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Reason for Skipping / Rescheduling',
                    border: OutlineInputBorder(),
                  ),
                  items: SkipReason.values.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(
                        reason.label,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedReason = val);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (selectedReason.canReschedule) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Custom Date: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          chosenRescheduleDate != null
                              ? '${chosenRescheduleDate!.day}/${chosenRescheduleDate!.month}/${chosenRescheduleDate!.year}'
                              : 'Auto (+2 days)',
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(
                              const Duration(days: 2),
                            ),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                          );
                          if (picked != null) {
                            setDialogState(() => chosenRescheduleDate = picked);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedReason.canReschedule
                    ? Colors.teal.shade800
                    : Colors.red.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                final scheduler = ref.read(taskSchedulerProvider);
                await scheduler.recordSkipAndReschedule(
                  visitScheduleId: task.id,
                  reason: selectedReason,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                  customRescheduleDate: chosenRescheduleDate,
                );
                _loadData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        selectedReason.canReschedule
                            ? 'Visit rescheduled within protocol window.'
                            : 'Visit marked as skipped.',
                      ),
                      backgroundColor: Colors.teal.shade900,
                    ),
                  );
                }
              },
              child: Text(
                selectedReason.canReschedule ? 'Reschedule' : 'Confirm Skip',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ad-Hoc Visit Creation Dialog (Requirement 24.7) ────────────────────────
  Future<void> _showAdHocTaskDialog() async {
    final titleController = TextEditingController();
    final memberIdController = TextEditingController();
    final notesController = TextEditingController();
    String programCode = 'ad_hoc';
    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Ad-Hoc Task / Visit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: memberIdController,
                  decoration: const InputDecoration(
                    labelText: 'Beneficiary Member ID or Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task / Visit Purpose',
                    hintText: 'e.g. Unplanned Fever Check, BP Monitoring',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: programCode,
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'ad_hoc',
                      child: Text('Ad-Hoc / General Home Visit'),
                    ),
                    DropdownMenuItem(
                      value: 'anc',
                      child: Text('ANC Follow-up'),
                    ),
                    DropdownMenuItem(
                      value: 'pnc',
                      child: Text('PNC Follow-up'),
                    ),
                    DropdownMenuItem(
                      value: 'hbnc',
                      child: Text('HBNC Follow-up'),
                    ),
                    DropdownMenuItem(
                      value: 'hbyc',
                      child: Text('HBYC Growth / Nutrition Check'),
                    ),
                    DropdownMenuItem(
                      value: 'immunization',
                      child: Text('Immunization Outreach'),
                    ),
                    DropdownMenuItem(
                      value: 'ncd',
                      child: Text('NCD Follow-up'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => programCode = val);
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'Due Date: ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 7),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 60),
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AshaColors.primary,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: AshaShapes.buttonRadius),
              ),
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    memberIdController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter beneficiary and visit purpose',
                      ),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogCtx);
                final scheduler = ref.read(taskSchedulerProvider);
                await scheduler.createAdHocTask(
                  memberId: memberIdController.text.trim(),
                  title: titleController.text.trim(),
                  programCode: programCode,
                  dueDate: selectedDate,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                );
                _loadData();
              },
              child: const Text('Save Task'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(l10n?.dueList ?? "Today's Tasks"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AshaColors.primary,
          unselectedLabelColor: AshaColors.textSecondary,
          indicatorColor: AshaColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: [
            Tab(
              icon: const Icon(Icons.checklist),
              text:
                  "Due List (${_allTasks.where((t) => t.urgencyGroup != UrgencyGroup.upcoming).length})",
            ),
            const Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            const Tab(icon: Icon(Icons.pie_chart_outline), text: 'Coverage'),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('home_search_button'),
            icon: const Icon(Icons.search),
            tooltip: 'Search beneficiaries',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            key: const Key('home_households_button'),
            icon: const Icon(Icons.people),
            tooltip: l10n?.households ?? 'Households',
            onPressed: () => context.push('/households'),
          ),
          IconButton(
            key: const Key('home_language_selector_button'),
            icon: const Icon(Icons.language),
            tooltip: l10n?.language ?? 'Language',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const LanguageSelectorDialog(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Loading tasks...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          : _errorMessage != null
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (constraints.maxHeight - 48).clamp(
                      0,
                      double.infinity,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Error: $_errorMessage',
                          textAlign: TextAlign.center,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDueListTab(l10n),
                _buildCalendarTab(),
                _buildCoverageTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('home_register_household_fab'),
        onPressed: _showAdHocTaskDialog,
        icon: const Icon(Icons.add_task),
        label: const Text('Add Task'),
        backgroundColor: AshaColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ── TAB 1: Due List View (Requirements 24.1, 24.6) ─────────────────────────
  Widget _buildDueListTab(AppLocalizations? l10n) {
    if (_allTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No tasks scheduled yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register a household or add an ad-hoc visit to begin',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              key: const Key('home_register_household_button'),
              onPressed: () => context.push('/household/new'),
              icon: const Icon(Icons.person_add),
              label: Text(l10n?.registerHousehold ?? 'Register Household'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: const Key('home_triage_button'),
              onPressed: () => context.push('/triage'),
              icon: const Icon(Icons.medical_services_outlined),
              label: const Text('Clinical Triage & Assessment'),
            ),
          ],
        ),
      );
    }

    final isOverloaded = _workloadSummary?.isOverloaded ?? false;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          // ── Quick Access Row (Preserves existing test buttons) ─────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('home_register_household_button'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: const RoundedRectangleBorder(borderRadius: AshaShapes.pillRadius),
                  ),
                  onPressed: () => context.push('/household/new'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l10n?.registerHousehold ?? 'Register Household',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  key: const Key('home_triage_button'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: const RoundedRectangleBorder(borderRadius: AshaShapes.pillRadius),
                  ),
                  onPressed: () => context.push('/triage'),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services_outlined, size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Triage Assessment',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Workload Threshold Alert (Requirement 24.6) ───────────────────
          if (isOverloaded)
            Card(
              color: Colors.amber.shade100,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.amber.shade800, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade900,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'High Workload Alert (${_workloadSummary!.totalTasksToday} visits scheduled)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Exceeds standard capacity ($_workloadThreshold/day). Tasks ordered by clinical risk & window expiry urgency score.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Filters: Hamlet & Program ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('hamlet_$_selectedHamlet'),
                    initialValue: _selectedHamlet,
                    decoration: const InputDecoration(
                      labelText: 'Hamlet',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    items: _availableHamlets
                        .map(
                          (h) => DropdownMenuItem(
                            value: h,
                            child: Text(h, overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedHamlet = val);
                        _loadData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('program_$_selectedProgram'),
                    initialValue: _selectedProgram,
                    decoration: const InputDecoration(
                      labelText: 'Program',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    items: _availablePrograms
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedProgram = val);
                        _loadData();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Urgency Groups: RED -> Overdue -> Due Today -> Upcoming ────────
          for (final group in UrgencyGroup.values)
            _buildUrgencyGroupSection(group),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildUrgencyGroupSection(UrgencyGroup group) {
    final hamletMap = _groupedTasks[group] ?? {};
    final totalInGroup = hamletMap.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    if (totalInGroup == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Color(group.colorValue).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Color(group.colorValue).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                group == UrgencyGroup.redFollowUp
                    ? Icons.emergency
                    : (group == UrgencyGroup.overdue
                          ? Icons.schedule
                          : Icons.event_available),
                size: 20,
                color: Color(group.colorValue),
              ),
              const SizedBox(width: 8),
              Text(
                '${group.label} ($totalInGroup)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(group.colorValue),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ...hamletMap.entries.map((entry) {
          final hamletName = entry.key;
          final tasks = entry.value;

          return Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Hamlet: $hamletName (${tasks.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                ...tasks.map((task) => _buildTaskCard(task)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTaskCard(DueTask task) {
    final stripeColor = task.hasRedAlert
        ? AshaColors.alertHighRisk
        : (task.urgencyGroup == UrgencyGroup.overdue
            ? AshaColors.warningPending
            : AshaColors.vitalNormal);

    return AshaCard(
      margin: const EdgeInsets.symmetric(vertical: 5),
      statusStripeColor: stripeColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Member name, program chip, score
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.memberName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AshaColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${task.sex} • ${task.memberAgeText ?? "Age N/A"} • ${task.hamlet}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AshaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AshaBadge(
                label: task.programCode.toUpperCase(),
                type: task.hasRedAlert ? AshaBadgeType.highRisk : AshaBadgeType.normal,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Visit Type & Due Info
          Text(
            task.visitType,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AshaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),

          // Urgency & Prioritisation Reason Rationale (Requirement 24.6)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: task.hasRedAlert
                  ? AshaColors.alertHighRisk.withValues(alpha: 0.1)
                  : (task.clinicalRiskLevel >= 2.0
                        ? AshaColors.warningPending.withValues(alpha: 0.12)
                        : AshaColors.surfaceMuted),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  task.hasRedAlert ? Icons.error_outline : Icons.info_outline,
                  size: 15,
                  color: task.hasRedAlert
                      ? AshaColors.alertHighRisk
                      : AshaColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    task.prioritisationReason,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: task.hasRedAlert
                          ? AshaColors.alertHighRisk
                          : AshaColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (task.rescheduledCount > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    'Rescheduled x${task.rescheduledCount}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AshaColors.warningPending,
                    ),
                  ),
                ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.event_busy, size: 16),
                label: const Text(
                  'Skip / Reschedule',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () => _showSkipDialog(task),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  backgroundColor: task.hasRedAlert
                      ? AshaColors.alertHighRisk
                      : AshaColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text(
                  'Start Visit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _startTaskVisit(task),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startTaskVisit(DueTask task) {
    final code = task.programCode.toLowerCase();
    if (code.contains('anc')) {
      context.push(
        '/programs/anc-visit?memberId=${task.memberId}&name=${Uri.encodeComponent(task.memberName)}&visitId=${task.id}&contact=3&weeks=28',
      );
    } else if (code.contains('pnc')) {
      context.push(
        '/programs/pnc-visit?memberId=${task.memberId}&name=${Uri.encodeComponent(task.memberName)}&visitId=${task.id}&day=7',
      );
    } else if (code.contains('hbnc')) {
      context.push(
        '/programs/hbnc-visit?memberId=${task.memberId}&visitId=${task.id}',
      );
    } else if (code.contains('hbyc')) {
      context.push(
        '/programs/hbyc-visit?memberId=${task.memberId}&name=${Uri.encodeComponent(task.memberName)}&visitId=${task.id}',
      );
    } else if (code.contains('ncd') || code.contains('cbac')) {
      context.push(
        '/programs/cbac?memberId=${task.memberId}&name=${Uri.encodeComponent(task.memberName)}&age=55&sex=${task.sex}',
      );
    } else if (code.contains('immun')) {
      context.push(
        '/programs/immunization?memberId=${task.memberId}&name=${Uri.encodeComponent(task.memberName)}',
      );
    } else if (code.contains('growth') || code.contains('nutrition')) {
      context.push(
        '/programs/growth?memberId=${task.memberId}&name=${Uri.encodeComponent(task.memberName)}',
      );
    } else if (code.contains('tb')) {
      context.push(
        '/programs/tb-presumptive?memberId=${task.memberId}&name=${Uri.encodeComponent(task.memberName)}',
      );
    } else {
      context.push('/beneficiary/${task.memberId}');
    }
  }

  // ── TAB 2: Calendar Month View (Requirement 24.5) ──────────────────────────
  Widget _buildCalendarTab() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayWeekday = DateTime(now.year, now.month, 1).weekday;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_getMonthName(now.month)} ${now.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
            ],
          ),
          const SizedBox(height: 12),
          // Weekday header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('Mon', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Tue', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Wed', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Thu', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Fri', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Sat', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Sun', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),

          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: 42,
            itemBuilder: (ctx, index) {
              final dayOffset = index - (firstDayWeekday - 1);
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox.shrink();
              }
              final day = dayOffset + 1;
              final taskCount = _calendarDailyCounts[day] ?? 0;
              final isToday = day == now.day;

              return Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isToday
                      ? Colors.teal.shade100
                      : (taskCount > 0
                            ? Colors.teal.shade50
                            : Colors.grey.shade50),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isToday
                        ? Colors.teal.shade800
                        : Colors.grey.shade300,
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    if (taskCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: taskCount > 8
                              ? Colors.amber.shade800
                              : Colors.teal.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$taskCount',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Legend: Teal circle = Scheduled visits. Orange badge = High workload (>8 visits).',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ── TAB 3: Coverage Summary (Requirement 24.5) ─────────────────────────────
  Widget _buildCoverageTab() {
    if (_coverageSummary.isEmpty) {
      return const Center(child: Text('No programme coverage data available'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Area Programme Coverage Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Track completion rates against registered beneficiaries in your catchment area.',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 16),
        ..._coverageSummary.map((cov) {
          final pct = cov.coveragePercentage;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cov.programName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: pct >= 80
                              ? Colors.green.shade800
                              : Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: pct / 100.0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      pct >= 80
                          ? Colors.teal
                          : (pct >= 50 ? Colors.amber.shade700 : Colors.red),
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Completed: ${cov.completed} / ${cov.totalScheduled}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (cov.overdue > 0)
                        Text(
                          'Overdue: ${cov.overdue}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _getMonthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }
}
