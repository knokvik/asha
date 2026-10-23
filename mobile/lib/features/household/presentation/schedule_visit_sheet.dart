import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/database/app_database.dart';
import '../../../shared/providers/core_providers.dart';

class ScheduleVisitBottomSheet extends ConsumerStatefulWidget {
  final String beneficiaryName;
  final String memberId;
  final VoidCallback? onSaved;

  const ScheduleVisitBottomSheet({
    super.key,
    required this.beneficiaryName,
    required this.memberId,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required String beneficiaryName,
    required String memberId,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ScheduleVisitBottomSheet(
        beneficiaryName: beneficiaryName,
        memberId: memberId,
        onSaved: onSaved,
      ),
    );
  }

  @override
  ConsumerState<ScheduleVisitBottomSheet> createState() =>
      _ScheduleVisitBottomSheetState();
}

class _ScheduleVisitBottomSheetState
    extends ConsumerState<ScheduleVisitBottomSheet> {
  static const _uuid = Uuid();

  final List<String> _categories = [
    'Routine Home Visit',
    'ANC Follow-up',
    'PNC Checkup',
    'HBNC Newborn Visit',
    'Immunization Due',
    'NCD Screening',
  ];

  late String _selectedCategory;
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categories[0];
    _titleController = TextEditingController(text: _selectedCategory);
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _titleController.text = category;
    });
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveSchedule() async {
    final title = _titleController.text.trim().isEmpty
        ? _selectedCategory
        : _titleController.text.trim();
    final notes = _notesController.text.trim();

    setState(() => _isSaving = true);
    final db = ref.read(appDatabaseProvider);
    final nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final dueEpoch = _selectedDate.millisecondsSinceEpoch;

    final programCode = switch (_selectedCategory) {
      'ANC Follow-up' => 'anc',
      'PNC Checkup' => 'pnc',
      'HBNC Newborn Visit' => 'hbnc',
      'Immunization Due' => 'immunization',
      'NCD Screening' => 'ncd',
      _ => 'routine_home_visit',
    };

    try {
      // 1. Insert into visit schedules for ASHA field planner
      await db.into(db.visitSchedules).insert(
        VisitSchedulesCompanion.insert(
          id: _uuid.v4(),
          memberId: widget.memberId,
          programCode: programCode,
          visitType: title,
          dueDate: dueEpoch,
          status: const Value('pending'),
          createdAt: nowEpoch,
        ),
      );

      // 2. Insert into clinical encounters as scheduled visit
      await db.into(db.clinicalEncounters).insert(
        ClinicalEncountersCompanion.insert(
          id: _uuid.v4(),
          memberId: widget.memberId,
          encounterType: title.toUpperCase().replaceAll(' ', '_'),
          programCode: programCode,
          encounterDate: dueEpoch,
          ashaId: 'local_worker',
          status: const Value('scheduled'),
          visitNotes: Value(notes.isEmpty ? 'Scheduled visit' : notes),
          createdAt: nowEpoch,
          updatedAt: nowEpoch,
          syncStatus: const Value('pending'),
        ),
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E4231),
            content: Text(
              'Scheduled "$title" for ${_formatDate(_selectedDate)} in your ASHA planner.',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule visit: $e')),
        );
      }
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final in3Days = today.add(const Duration(days: 3));
    final in1Week = today.add(const Duration(days: 7));

    final isToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;
    final isTomorrow = _selectedDate.year == tomorrow.year &&
        _selectedDate.month == tomorrow.month &&
        _selectedDate.day == tomorrow.day;
    final isIn3Days = _selectedDate.year == in3Days.year &&
        _selectedDate.month == in3Days.month &&
        _selectedDate.day == in3Days.day;
    final isIn1Week = _selectedDate.year == in1Week.year &&
        _selectedDate.month == in1Week.month &&
        _selectedDate.day == in1Week.day;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_note_rounded, color: Color(0xFF16A34A)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Schedule Visit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E4231),
                        ),
                      ),
                      Text(
                        'Beneficiary: ${widget.beneficiaryName}',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // 1. Visit Type Quick Chips
            const Text(
              'Visit Category',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF1E4231),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: const Color(0xFF1E4231),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (_) => _onCategorySelected(cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // 2. Custom Title Field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Visit Title / Purpose',
                labelStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF1E4231)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            // 3. Due Date Picker Chips
            const Text(
              'Scheduled Date',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? Colors.white : const Color(0xFF1E4231),
                    ),
                  ),
                  selected: isToday,
                  selectedColor: const Color(0xFF1E4231),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (_) => setState(() => _selectedDate = today),
                ),
                ChoiceChip(
                  label: Text(
                    'Tomorrow',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isTomorrow ? FontWeight.w700 : FontWeight.w500,
                      color: isTomorrow ? Colors.white : const Color(0xFF1E4231),
                    ),
                  ),
                  selected: isTomorrow,
                  selectedColor: const Color(0xFF1E4231),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (_) => setState(() => _selectedDate = tomorrow),
                ),
                ChoiceChip(
                  label: Text(
                    'In 3 Days',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isIn3Days ? FontWeight.w700 : FontWeight.w500,
                      color: isIn3Days ? Colors.white : const Color(0xFF1E4231),
                    ),
                  ),
                  selected: isIn3Days,
                  selectedColor: const Color(0xFF1E4231),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (_) => setState(() => _selectedDate = in3Days),
                ),
                ChoiceChip(
                  label: Text(
                    'Next Week',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isIn1Week ? FontWeight.w700 : FontWeight.w500,
                      color: isIn1Week ? Colors.white : const Color(0xFF1E4231),
                    ),
                  ),
                  selected: isIn1Week,
                  selectedColor: const Color(0xFF1E4231),
                  backgroundColor: const Color(0xFFF1F5F9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onSelected: (_) => setState(() => _selectedDate = in1Week),
                ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 14, color: Color(0xFF1E4231)),
                  label: Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E4231),
                    ),
                  ),
                  backgroundColor: const Color(0xFFE8F5E9),
                  side: const BorderSide(color: Color(0xFFA5D6A7)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  onPressed: _pickCustomDate,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Visit Instructions / Notes (Optional)',
                labelStyle: const TextStyle(fontSize: 13),
                hintText: 'e.g. Check IFA tablet compliance and BP',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 20),

            // 5. Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                key: const Key('confirm_schedule_visit_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E4231),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveSchedule,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.add_task_rounded),
                label: Text(
                  _isSaving ? 'Scheduling...' : 'Save to Field Schedule & Sync',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
