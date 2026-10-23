import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../shared/providers/core_providers.dart';
import '../../../shared/providers/user_profile_provider.dart';
import '../../../shared/shell/shell_copy.dart';
import '../../../shared/widgets/asha_bottom_nav.dart';
import '../domain/due_list_models.dart';
import '../domain/task_scheduler.dart';

String _dueCopy(String language, String key) {
  const copy = <String, Map<String, String>>{
    'en': {
      'createTask': 'Create task',
      'createTaskSub':
          'Add an unplanned visit. It is saved locally and queued for sync.',
      'syncServer': 'Sync with Server',
      'addTask': 'Add Task',
      'unlockTask': 'Unlock the app before creating a task.',
      'addBeneficiary': 'Add an active beneficiary first.',
      'beneficiary': 'Beneficiary',
      'beneficiaryName': 'Beneficiary name',
      'beneficiaryNameHint': 'Enter the registered beneficiary name',
      'nameNotFound': 'No active beneficiary matches that name. Add the person first, then create the task.',
      'taskTitle': 'Task title',
      'risk': 'Risk',
      'low': 'Low',
      'moderate': 'Moderate',
      'high': 'High',
      'notesOptional': 'Notes (optional)',
      'additionalDetails': 'Additional details',
      'saveTask': 'Save task',
      'taskSaved': 'Task saved offline and queued for sync.',
      'taskFailed': 'Could not create the task locally.',
    },
    'hi': {
      'createTask': 'कार्य बनाएं',
      'createTaskSub': 'बिना योजना की विज़िट जोड़ें। यह स्थानीय रूप से सहेजी जाएगी और सिंक के लिए कतार में जाएगी।',
      'syncServer': 'सर्वर से सिंक करें',
      'addTask': 'कार्य जोड़ें',
      'unlockTask': 'कार्य बनाने से पहले ऐप अनलॉक करें।',
      'addBeneficiary': 'पहले सक्रिय लाभार्थी जोड़ें।',
      'beneficiary': 'लाभार्थी',
      'beneficiaryName': 'लाभार्थी का नाम',
      'beneficiaryNameHint': 'पंजीकृत लाभार्थी का नाम लिखें',
      'nameNotFound':
          'इस नाम का सक्रिय लाभार्थी नहीं मिला। पहले व्यक्ति को जोड़ें।',
      'taskTitle': 'कार्य का नाम',
      'risk': 'जोखिम',
      'low': 'कम',
      'moderate': 'मध्यम',
      'high': 'अधिक',
      'notesOptional': 'नोट्स (वैकल्पिक)',
      'additionalDetails': 'अतिरिक्त विवरण',
      'saveTask': 'कार्य सहेजें',
      'taskSaved': 'कार्य ऑफ़लाइन सहेजा गया और सिंक कतार में जोड़ा गया।',
      'taskFailed': 'कार्य स्थानीय रूप से नहीं बनाया जा सका।',
    },
    'mr': {
      'createTask': 'काम तयार करा',
      'createTaskSub':
          'नियोजित नसलेली भेट जोडा. ती फोनवर जतन होऊन सिंकसाठी रांगेत जाईल.',
      'syncServer': 'सर्व्हरशी सिंक करा',
      'addTask': 'काम जोडा',
      'unlockTask': 'काम तयार करण्यापूर्वी अॅप अनलॉक करा.',
      'addBeneficiary': 'प्रथम सक्रिय लाभार्थी जोडा.',
      'beneficiary': 'लाभार्थी',
      'beneficiaryName': 'लाभार्थ्याचे नाव',
      'beneficiaryNameHint': 'नोंदणीकृत लाभार्थ्याचे नाव लिहा',
      'nameNotFound':
          'या नावाचा सक्रिय लाभार्थी सापडला नाही. आधी व्यक्ती जोडा.',
      'taskTitle': 'कामाचे नाव',
      'risk': 'जोखीम',
      'low': 'कमी',
      'moderate': 'मध्यम',
      'high': 'जास्त',
      'notesOptional': 'नोंदी (पर्यायी)',
      'additionalDetails': 'अधिक माहिती',
      'saveTask': 'काम जतन करा',
      'taskSaved': 'काम ऑफलाइन जतन झाले आणि सिंक रांगेत जोडले गेले.',
      'taskFailed': 'काम फोनवर तयार करता आले नाही.',
    },
  };
  return copy[language]?[key] ?? copy['en']![key]!;
}

/// Screen 4: Today's Due List matching the master reference image.
/// Top Bar: [ < ]  Today's Due List  [ 📅 ]
/// Filter Pills: All (N), Overdue (N), Upcoming (N) — dynamic from DB & Server sync.
/// Detailed Beneficiary Due Cards generated dynamically from active schedules.
/// Supports pull-to-refresh sync and ad-hoc task creation.
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
  // Keep the due-list calendar compact by default; workers can expand it when
  // they need to browse dates.
  var _calendarExpanded = false;
  final _createdTasks = <_CreatedTaskPreview>[];

  List<DueTask>? _tasks;
  bool _isLoading = false;

  String get _currentLanguage => ref.read(languageProvider).languageCode;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialTab;
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTasks());
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final scheduler = ref.read(taskSchedulerProvider);
      final tasks = await scheduler.fetchDueTasks(referenceDate: _selectedDate);
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tasks = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).languageCode;
    final body = _body(context, lang);
    if (widget.embedded) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        floatingActionButton: _buildCreateTaskFab(),
        body: body,
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      bottomNavigationBar: const AshaBottomNav(index: 2),
      floatingActionButton: _buildCreateTaskFab(),
      body: SafeArea(child: body),
    );
  }

  Widget _buildCreateTaskFab() {
    final lang = ref.watch(languageProvider).languageCode;
    return FloatingActionButton(
      key: const Key('create_task_button'),
      heroTag: widget.embedded ? 'embedded-create-task' : 'create-task',
      onPressed: _showCreateTaskSheet,
      backgroundColor: const Color(0xFF166534),
      foregroundColor: Colors.white,
      tooltip: _dueCopy(lang, 'createTask'),
      child: const Icon(Icons.add_task_rounded),
    );
  }

  Widget _body(BuildContext context, String lang) {
    final allTasks = _tasks ?? [];
    final overdueTasks = allTasks
        .where(
          (t) =>
              t.urgencyGroup == UrgencyGroup.overdue ||
              t.urgencyGroup == UrgencyGroup.redFollowUp,
        )
        .toList();
    final upcomingTasks = allTasks
        .where(
          (t) =>
              t.urgencyGroup == UrgencyGroup.upcoming ||
              t.urgencyGroup == UrgencyGroup.dueToday,
        )
        .toList();

    final filteredTasks = switch (_selectedFilter) {
      1 => overdueTasks,
      2 => upcomingTasks,
      _ => allTasks,
    };

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
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    fontFamily: 'SF Pro Display',
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
          ),

        _buildCalendar(context),

        // 2. Filter Pills: All (N) | Overdue (N) | Upcoming (N)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildFilterPill(
                0,
                '${shellText(lang, 'all')} (${allTasks.length + _createdTasks.length})',
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                1,
                '${shellText(lang, 'overdue')} (${overdueTasks.length})',
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                2,
                '${shellText(lang, 'upcoming')} (${upcomingTasks.length + _createdTasks.length})',
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
          child: Row(
            children: [
              Text(
                shellText(lang, 'tasks'),
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

        // 3. Due Task List Cards with pull-to-refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final coordinator = ref.read(syncCoordinatorProvider);
              if (coordinator != null) {
                await coordinator.syncNow();
              }
              await _loadTasks();
              await ref.read(userProfileProvider.notifier).loadProfile();
            },
            child: _isLoading && _tasks == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : filteredTasks.isEmpty && _createdTasks.isEmpty
                ? _buildEmptyState(lang)
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    children: [
                      for (final task in _createdTasks) ...[
                        _buildCreatedTaskCard(task),
                        const SizedBox(height: 10),
                      ],
                      for (final task in filteredTasks) ...[
                        _buildDueTaskItem(task, lang),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String lang) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: Color(0xFF16A34A),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No visits due for this date',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'All scheduled clinical tasks for this period are completed or none have been assigned yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E4231),
                      side: const BorderSide(color: Color(0xFF1E4231)),
                    ),
                    onPressed: () async {
                      final coord = ref.read(syncCoordinatorProvider);
                      if (coord != null) await coord.syncNow();
                      await _loadTasks();
                    },
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: Text(_dueCopy(_currentLanguage, 'syncServer')),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF166534),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _showCreateTaskSheet,
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(_dueCopy(_currentLanguage, 'addTask')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDueTaskItem(DueTask task, String lang) {
    final isUrgent = task.urgencyGroup == UrgencyGroup.redFollowUp;
    final isOverdue = task.urgencyGroup == UrgencyGroup.overdue;
    final isToday = task.urgencyGroup == UrgencyGroup.dueToday;

    final badgeText = isUrgent
        ? 'URGENT'
        : isOverdue
        ? shellText(lang, 'overdue')
        : isToday
        ? shellText(lang, 'todayBadge')
        : shellText(lang, 'upcoming');

    final badgeBg = (isUrgent || isOverdue)
        ? const Color(0xFFFEE2E2)
        : isToday
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFF3F4F6);

    final badgeColor = (isUrgent || isOverdue)
        ? const Color(0xFFEF4444)
        : isToday
        ? const Color(0xFF16A34A)
        : const Color(0xFF6B7280);

    final avatarBg = (isUrgent || isOverdue)
        ? const Color(0xFFFEE2E2)
        : isToday
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFDBEAFE);

    final avatarColor = (isUrgent || isOverdue)
        ? const Color(0xFFDC2626)
        : isToday
        ? const Color(0xFF16A34A)
        : const Color(0xFF2563EB);

    String initials = 'BN';
    final nameParts = task.memberName.trim().split(RegExp(r'\s+'));
    if (nameParts.length >= 2) {
      initials = '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    } else if (nameParts.isNotEmpty && nameParts[0].isNotEmpty) {
      initials = nameParts[0]
          .substring(0, math.min(2, nameParts[0].length))
          .toUpperCase();
    }

    final subtitle = [
      if (task.hamlet.isNotEmpty) task.hamlet,
      task.visitType,
    ].join(' • ');

    return _buildDueCard(
      avatarInitials: initials,
      avatarBg: avatarBg,
      avatarColor: avatarColor,
      name: task.memberName,
      subtitle: subtitle,
      badgeText: badgeText,
      badgeBg: badgeBg,
      badgeColor: badgeColor,
      timeText: isToday ? shellText(_currentLanguage, 'today') : null,
      onTap: () => context.push('/beneficiary/${task.memberId}'),
    );
  }

  Widget _buildCreatedTaskCard(_CreatedTaskPreview task) {
    return InkWell(
      key: Key('created_task_${task.taskId}'),
      onTap: () => context.push('/beneficiary/${task.memberId}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            Text(
              shellText(_currentLanguage, 'new'),
              style: TextStyle(
                color: Color(0xFF166534),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateTaskSheet() async {
    final memberNameController = TextEditingController();
    final titleController = TextEditingController();
    final hamletController = TextEditingController();
    final notesController = TextEditingController();
    var dueDate = _selectedDate;
    var risk = 1.0;
    String? title;
    String? notes;
    String selectedCategory = 'General Home Visit';
    String selectedTimeSlot = 'Morning (8 AM - 12 PM)';
    var enteredMemberName = '';
    if (!mounted) return;
    bool? created;

    final templates = const [
      ('ANC Checkup', 'Maternal Health (ANC/PNC)', 2.0),
      ('Vaccine Follow-up', 'Child Immunization', 2.0),
      ('BP & Sugar Check', 'NCD Surveillance', 1.0),
      ('IFA Tablets Delivery', 'Nutrition & Supplies', 1.0),
      ('Newborn Care (HBNC)', 'Newborn Care', 3.0),
      ('Fever & Vitals', 'Fever Surveillance', 2.0),
    ];

    try {
      created = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        useSafeArea: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AshaColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.add_task_rounded,
                          color: AshaColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _dueCopy(_currentLanguage, 'createTask'),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AshaColors.textPrimary,
                            ),
                          ),
                          Text(
                            _dueCopy(_currentLanguage, 'createTaskSub'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AshaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quick Template Chips
                  const Text(
                    'Quick Templates',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AshaColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: templates.map((tpl) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            avatar: const Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: AshaColors.primary,
                            ),
                            label: Text(tpl.$1),
                            labelStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AshaColors.textPrimary,
                            ),
                            backgroundColor: AshaColors.surfaceMuted,
                            side: const BorderSide(
                              color: AshaColors.borderSubtle,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            onPressed: () {
                              setSheetState(() {
                                titleController.text = tpl.$1;
                                selectedCategory = tpl.$2;
                                risk = tpl.$3;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Beneficiary Name
                  TextField(
                    controller: memberNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: _dueCopy(_currentLanguage, 'beneficiaryName'),
                      hintText: _dueCopy(
                        _currentLanguage,
                        'beneficiaryNameHint',
                      ),
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Task Title
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: _dueCopy(_currentLanguage, 'taskTitle'),
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      if (sheetContext.mounted) setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 12),

                  // Clinical Category & Locality / Hamlet
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'General Home Visit',
                              child: Text('General Visit'),
                            ),
                            DropdownMenuItem(
                              value: 'Maternal Health (ANC/PNC)',
                              child: Text('ANC / PNC'),
                            ),
                            DropdownMenuItem(
                              value: 'Child Immunization',
                              child: Text('Immunization'),
                            ),
                            DropdownMenuItem(
                              value: 'NCD Surveillance',
                              child: Text('NCD Check'),
                            ),
                            DropdownMenuItem(
                              value: 'Newborn Care',
                              child: Text('Newborn (HBNC)'),
                            ),
                            DropdownMenuItem(
                              value: 'Nutrition & Supplies',
                              child: Text('Nutrition/IFA'),
                            ),
                            DropdownMenuItem(
                              value: 'Fever Surveillance',
                              child: Text('Fever/IDSP'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null && sheetContext.mounted) {
                              setSheetState(() => selectedCategory = val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: hamletController,
                          decoration: const InputDecoration(
                            labelText: 'Hamlet / Ward',
                            hintText: 'e.g. Ward 3',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Date Picker & Risk / Priority
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            if (!sheetContext.mounted) return;
                            final picked = await showDatePicker(
                              context: sheetContext,
                              initialDate: dueDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2035, 12, 31),
                            );
                            if (picked != null && sheetContext.mounted) {
                              setSheetState(
                                () => dueDate = DateUtils.dateOnly(picked),
                              );
                            }
                          },
                          icon: const Icon(Icons.event_outlined, size: 18),
                          label: Text(
                            MaterialLocalizations.of(context)
                                .formatMediumDate(dueDate),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<double>(
                          initialValue: risk,
                          decoration: InputDecoration(
                            labelText: _dueCopy(_currentLanguage, 'risk'),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 1.0,
                              child: Text(_dueCopy(_currentLanguage, 'low')),
                            ),
                            DropdownMenuItem(
                              value: 2.0,
                              child: Text(
                                _dueCopy(_currentLanguage, 'moderate'),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 3.0,
                              child: Text(_dueCopy(_currentLanguage, 'high')),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null || !sheetContext.mounted) return;
                            setSheetState(() => risk = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Preferred Time Slot
                  DropdownButtonFormField<String>(
                    initialValue: selectedTimeSlot,
                    decoration: const InputDecoration(
                      labelText: 'Visit Time Window',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule_rounded),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Morning (8 AM - 12 PM)',
                        child: Text('Morning (8 AM - 12 PM)'),
                      ),
                      DropdownMenuItem(
                        value: 'Afternoon (12 PM - 4 PM)',
                        child: Text('Afternoon (12 PM - 4 PM)'),
                      ),
                      DropdownMenuItem(
                        value: 'Evening (4 PM - 7 PM)',
                        child: Text('Evening (4 PM - 7 PM)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null && sheetContext.mounted) {
                        setSheetState(() => selectedTimeSlot = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Additional Details / Notes
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      _dueCopy(_currentLanguage, 'additionalDetails'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    children: [
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: _dueCopy(
                            _currentLanguage,
                            'notesOptional',
                          ),
                          hintText: 'Clinical notes, medication reminders, directions',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AshaColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AshaShapes.buttonRadius,
                      ),
                    ),
                    onPressed: titleController.text.trim().isEmpty
                        ? null
                        : () {
                            if (!sheetContext.mounted) return;
                            title = titleController.text.trim();
                            final rawNotes = notesController.text.trim();
                            final hamlet = hamletController.text.trim();
                            final details = [
                              'Category: $selectedCategory',
                              'Window: $selectedTimeSlot',
                              if (hamlet.isNotEmpty) 'Hamlet: $hamlet',
                              if (rawNotes.isNotEmpty) rawNotes,
                            ].join(' · ');
                            notes = details;
                            Navigator.pop(sheetContext, true);
                          },
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_dueCopy(_currentLanguage, 'saveTask')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (_) {
      created = false;
    } finally {
      enteredMemberName = memberNameController.text.trim();
      memberNameController.dispose();
      titleController.dispose();
      hamletController.dispose();
      notesController.dispose();
    }
    if (created != true || title == null || !mounted) return;

    try {
      final database = ref.read(appDatabaseProvider);
      final enteredName = enteredMemberName;
      final activeMembers = await (database.select(
        database.members,
      )..where((member) => member.lifecycleStatus.equals('active'))).get();
      Member? matchingMember;
      for (final candidate in activeMembers) {
        if (candidate.name.trim().toLowerCase() == enteredName.toLowerCase()) {
          matchingMember = candidate;
          break;
        }
      }
      final matched = matchingMember;
      if (matched == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_dueCopy(_currentLanguage, 'nameNotFound'))),
        );
        return;
      }

      final taskId = await ref
          .read(taskSchedulerProvider)
          .createAdHocTask(
            memberId: matched.id,
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
            taskId: taskId,
            memberId: matched.id,
            title: title!,
            memberName: matched.name,
            dueDate: dueDate,
          ),
        );
      });
      await _loadTasks();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_dueCopy(_currentLanguage, 'taskSaved'))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_dueCopy(_currentLanguage, 'taskFailed'))),
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
      _loadTasks();
    }
  }

  Widget _buildCalendar(BuildContext context) {
    return Container(
      key: const Key('due_calendar'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
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
                      _loadTasks();
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
    required this.taskId,
    required this.memberId,
    required this.title,
    required this.memberName,
    required this.dueDate,
  });

  final String taskId;
  final String memberId;
  final String title;
  final String memberName;
  final DateTime dueDate;
}
