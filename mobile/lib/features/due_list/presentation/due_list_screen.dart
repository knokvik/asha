import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show OrderingTerm;

import '../../../core/l10n/language_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/shell/shell_copy.dart';
import '../../../shared/widgets/asha_bottom_nav.dart';
import '../domain/task_scheduler.dart';

/// Screen 4: Today's Due List matching the master reference image.
/// Top Bar: [ < ]  Today's Due List  [ 📅 ]
/// Filter Pills: All (12), Overdue (3), Upcoming (5)
/// Detailed Beneficiary Due Cards (Savitri Devi, Meena Kumari, Rekha Sharma, Kamla Bai, Lata Devi)
/// Fixed 4-item bottom navigation dock (Tasks active).
class DueListScreen extends ConsumerStatefulWidget {
  final int initialTab;
  final bool embedded;

  const DueListScreen({super.key, this.initialTab = 0, this.embedded = false});

  @override
  ConsumerState<DueListScreen> createState() => _DueListScreenState();
}

class _DueListScreenState extends ConsumerState<DueListScreen> {
  late int _selectedFilter;
  late DateTime _selectedDate;
  var _calendarExpanded = true;
  final _createdTasks = <_CreatedTaskPreview>[];

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialTab;
    _selectedDate = DateUtils.dateOnly(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).languageCode;
    final body = _body(context, lang);
    if (widget.embedded) return body;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      bottomNavigationBar: const AshaBottomNav(index: 2),
      body: SafeArea(child: body),
    );
  }

  Widget _body(BuildContext context, String lang) {
    return Column(
      children: [
        if (!widget.embedded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),

                Text(
                  shellText(lang, 'dueTitle'),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    fontFamily: 'SF Pro Display',
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      key: const Key('create_task_button'),
                      onTap: _showCreateTaskSheet,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.add_task_rounded,
                          size: 21,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _chooseDate(context),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.calendar_today_outlined,
                          size: 20,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            child: Row(
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                IconButton(
                  key: const Key('create_task_button'),
                  tooltip: 'Create task',
                  onPressed: _showCreateTaskSheet,
                  icon: const Icon(
                    Icons.add_task_rounded,
                    color: Color(0xFF166534),
                  ),
                ),
              ],
            ),
          ),

        _buildCalendar(context),

        // 2. Filter Pills matching Screen 4: All (12) | Overdue (3) | Upcoming (5)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildFilterPill(0, '${shellText(lang, 'all')} (12)'),
              const SizedBox(width: 8),
              _buildFilterPill(1, '${shellText(lang, 'overdue')} (3)'),
              const SizedBox(width: 8),
              _buildFilterPill(2, '${shellText(lang, 'upcoming')} (5)'),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
          child: Row(
            children: [
              const Text(
                'Tasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  fontFamily: 'SF Pro Display',
                ),
              ),
              const Spacer(),
              Text(
                MaterialLocalizations.of(context)
                    .formatMediumDate(_selectedDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Display',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // 3. Due Task List Cards
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            children: [
              for (final task in _createdTasks) ...[
                _buildCreatedTaskCard(task),
                const SizedBox(height: 10),
              ],
              // 1. Savitri Devi (Overdue - 10:00 AM)
              if (_selectedFilter == 0 || _selectedFilter == 1) ...[
                _buildDueCard(
                  avatarInitials: 'SD',
                  avatarBg: const Color(0xFFFEE2E2),
                  avatarColor: const Color(0xFFDC2626),
                  name: 'Savitri Devi',
                  subtitle: 'W7 • ANC Visit',
                  badgeText: shellText(lang, 'overdue'),
                  badgeBg: const Color(0xFFFEE2E2),
                  badgeColor: const Color(0xFFEF4444),
                  timeText: '10:00 AM',
                  onTap: () => context.push('/beneficiary/sav-01'),
                ),
                const SizedBox(height: 10),
              ],

              // 2. Meena Kumari (Today - 11:30 AM)
              if (_selectedFilter == 0 || _selectedFilter == 2) ...[
                _buildDueCard(
                  avatarInitials: 'MK',
                  avatarBg: const Color(0xFFDCFCE7),
                  avatarColor: const Color(0xFF16A34A),
                  name: 'Meena Kumari',
                  subtitle: 'W6 • Child Immunization',
                  badgeText: shellText(lang, 'todayBadge'),
                  badgeBg: const Color(0xFFDCFCE7),
                  badgeColor: const Color(0xFF16A34A),
                  timeText: '11:30 AM',
                  onTap: () => context.push('/beneficiary/sav-01'),
                ),
                const SizedBox(height: 10),
              ],

              // 3. Rekha Sharma (Today - 1:00 PM)
              if (_selectedFilter == 0 || _selectedFilter == 2) ...[
                _buildDueCard(
                  avatarInitials: 'RS',
                  avatarBg: const Color(0xFFDBEAFE),
                  avatarColor: const Color(0xFF2563EB),
                  name: 'Rekha Sharma',
                  subtitle: 'W7 • Follow-up',
                  badgeText: shellText(lang, 'todayBadge'),
                  badgeBg: const Color(0xFFDCFCE7),
                  badgeColor: const Color(0xFF16A34A),
                  timeText: '1:00 PM',
                  onTap: () => context.push('/beneficiary/sav-01'),
                ),
                const SizedBox(height: 10),
              ],

              // 4. Kamla Bai (Tomorrow)
              if (_selectedFilter == 0 || _selectedFilter == 2) ...[
                _buildDueCard(
                  avatarInitials: 'KB',
                  avatarBg: const Color(0xFFF3E8FF),
                  avatarColor: const Color(0xFF9333EA),
                  name: 'Kamla Bai',
                  subtitle: 'W8 • NCD Screening',
                  badgeText: 'Tomorrow',
                  badgeBg: const Color(0xFFF3F4F6),
                  badgeColor: const Color(0xFF6B7280),
                  timeText: null,
                  onTap: () => context.push('/beneficiary/sav-01'),
                ),
                const SizedBox(height: 10),
              ],

              // 5. Lata Devi (Tomorrow)
              if (_selectedFilter == 0 || _selectedFilter == 2) ...[
                _buildDueCard(
                  avatarInitials: 'LD',
                  avatarBg: const Color(0xFFFFEDD5),
                  avatarColor: const Color(0xFFEA580C),
                  name: 'Lata Devi',
                  subtitle: 'W6 • PNC Visit',
                  badgeText: 'Tomorrow',
                  badgeBg: const Color(0xFFF3F4F6),
                  badgeColor: const Color(0xFF6B7280),
                  timeText: null,
                  onTap: () => context.push('/beneficiary/sav-01'),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreatedTaskCard(_CreatedTaskPreview task) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 19,
            backgroundColor: Color(0xFFDCFCE7),
            child: Icon(Icons.add_task_rounded, color: Color(0xFF166534)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.memberName} · ${MaterialLocalizations.of(context).formatMediumDate(task.dueDate)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'New',
            style: TextStyle(
              color: Color(0xFF166534),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateTaskSheet() async {
    List<Member> members;
    try {
      final database = ref.read(appDatabaseProvider);
      members =
          await (database.select(database.members)
                ..where((member) => member.lifecycleStatus.equals('active'))
                ..orderBy([(member) => OrderingTerm(expression: member.name)]))
              .get();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlock the app before creating a task.')),
      );
      return;
    }
    if (members.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an active beneficiary first.')),
      );
      return;
    }

    final titleController = TextEditingController();
    final notesController = TextEditingController();
    var selectedMember = members.first;
    var dueDate = _selectedDate;
    var risk = 1.0;
    String? title;
    String? notes;
    if (!mounted) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create task',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Add an unplanned visit. It is saved locally and queued for sync.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Member>(
                  value: selectedMember,
                  decoration: const InputDecoration(
                    labelText: 'Beneficiary',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final member in members)
                      DropdownMenuItem(value: member, child: Text(member.name)),
                  ],
                  onChanged: (member) {
                    if (member != null) {
                      setSheetState(() => selectedMember = member);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  autofocus: true,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    hintText: 'Example: Follow-up home visit',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2035, 12, 31),
                          );
                          if (picked != null) {
                            setSheetState(
                              () => dueDate = DateUtils.dateOnly(picked),
                            );
                          }
                        },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          MaterialLocalizations.of(context)
                              .formatMediumDate(dueDate),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<double>(
                        value: risk,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1.0, child: Text('Routine')),
                          DropdownMenuItem(value: 2.0, child: Text('Moderate')),
                          DropdownMenuItem(value: 3.0, child: Text('High')),
                        ],
                        onChanged: (value) {
                          if (value != null) setSheetState(() => risk = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: titleController.text.trim().isEmpty
                      ? null
                      : () {
                          title = titleController.text.trim();
                          notes = notesController.text.trim().isEmpty
                              ? null
                              : notesController.text.trim();
                          Navigator.pop(sheetContext, true);
                        },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save task'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    titleController.dispose();
    notesController.dispose();
    if (created != true || title == null || !mounted) return;

    try {
      await ref
          .read(taskSchedulerProvider)
          .createAdHocTask(
            memberId: selectedMember.id,
            title: title!,
            dueDate: dueDate,
            clinicalRiskLevel: risk,
            notes: notes,
          );
      if (!mounted) return;
      setState(() {
        _createdTasks.insert(
          0,
          _CreatedTaskPreview(
            title: title!,
            memberName: selectedMember.name,
            dueDate: dueDate,
          ),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task saved offline and queued for sync.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create the task locally.')),
      );
    }
  }

  Future<void> _chooseDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035, 12, 31),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = DateUtils.dateOnly(picked));
    }
  }

  Widget _buildCalendar(BuildContext context) {
    return Container(
      key: const Key('due_calendar'),
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F5138),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            key: const Key('due_calendar_toggle'),
            onTap: () => setState(() => _calendarExpanded = !_calendarExpanded),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF166534),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    MaterialLocalizations.of(context)
                        .formatMonthYear(_selectedDate),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      fontFamily: 'SF Pro Display',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Choose date',
                    onPressed: () => _chooseDate(context),
                    icon: const Icon(
                      Icons.edit_calendar_outlined,
                      color: Color(0xFF166534),
                      size: 20,
                    ),
                  ),
                  Icon(
                    _calendarExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            child: _calendarExpanded
                ? CalendarDatePicker(
                    initialDate: _selectedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2035, 12, 31),
                    onDateChanged: (date) {
                      setState(() => _selectedDate = DateUtils.dateOnly(date));
                    },
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E4231) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1E4231)
                : const Color(0xFFE5E7EB),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
            fontFamily: 'SF Pro Display',
          ),
        ),
      ),
    );
  }

  Widget _buildDueCard({
    required String avatarInitials,
    required Color avatarBg,
    required Color avatarColor,
    required String name,
    required String subtitle,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    String? timeText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarBg,
                child: Text(
                  avatarInitials,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: avatarColor,
                    fontFamily: 'SF Pro Display',
                  ),
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(
                          Icons.home_outlined,
                          size: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: badgeColor,
                            fontFamily: 'SF Pro Display',
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9CA3AF),
                        size: 18,
                      ),
                    ],
                  ),
                  if (timeText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeText,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatedTaskPreview {
  const _CreatedTaskPreview({
    required this.title,
    required this.memberName,
    required this.dueDate,
  });

  final String title;
  final String memberName;
  final DateTime dueDate;
}
