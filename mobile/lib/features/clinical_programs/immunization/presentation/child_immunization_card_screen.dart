import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../data/immunization_repository.dart';
import '../domain/immunization_models.dart';
import 'aefi_report_dialog.dart';

/// Screen displaying the child's immunization card / MCP card matrix (Requirement 16.1, 16.2, 16.3).
class ChildImmunizationCardScreen extends ConsumerStatefulWidget {
  final String memberId;
  final String childName;
  final DateTime dateOfBirth;
  final String ashaId;

  const ChildImmunizationCardScreen({
    super.key,
    required this.memberId,
    required this.childName,
    required this.dateOfBirth,
    required this.ashaId,
  });

  @override
  ConsumerState<ChildImmunizationCardScreen> createState() => _ChildImmunizationCardScreenState();
}

class _ChildImmunizationCardScreenState extends ConsumerState<ChildImmunizationCardScreen> {
  final _dateFormat = DateFormat('dd MMM yyyy');
  bool _isLoading = true;
  List<ImmunizationCardItem> _items = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadImmunizationData();
  }

  Future<void> _loadImmunizationData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(immunizationRepositoryProvider);
      final items = await repo.getImmunizationCard(
        memberId: widget.memberId,
        dateOfBirth: widget.dateOfBirth,
      );
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showRecordDoseSheet([VaccineDefinition? preselected]) {
    final defaultDef = preselected ?? _items.firstWhere((it) => it.status == VaccineDoseStatus.due || it.status == VaccineDoseStatus.overdue, orElse: () => _items.first).definition;

    String selectedVaccineCode = defaultDef.code;
    AdministrationSite selectedSite = defaultDef.standardSite;
    ImmunizationSessionType selectedSession = ImmunizationSessionType.vhsnd;
    DateTime administeredDate = DateTime.now();
    final batchController = TextEditingController();
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Record Vaccine Dose',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Vaccine dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedVaccineCode,
                  decoration: const InputDecoration(
                    labelText: 'Vaccine Dose',
                    border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                  ),
                  items: NationalImmunizationCatalog.infantAndChildSchedule
                      .map((v) => DropdownMenuItem(
                            value: v.code,
                            child: Text('${v.code} (${v.name.split("(").first.trim()})'),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final def = NationalImmunizationCatalog.findByCode(val);
                      setSheetState(() {
                        selectedVaccineCode = val;
                        if (def != null) {
                          selectedSite = def.standardSite;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Date administered picker
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date Administered'),
                  subtitle: Text(_dateFormat.format(administeredDate), style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: administeredDate,
                      firstDate: widget.dateOfBirth,
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setSheetState(() => administeredDate = picked);
                    }
                  },
                ),
                const SizedBox(height: 12),

                // Administration Site
                DropdownButtonFormField<AdministrationSite>(
                  initialValue: selectedSite,
                  decoration: const InputDecoration(
                    labelText: 'Administration Site',
                    border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                  ),
                  items: AdministrationSite.values
                      .map((site) => DropdownMenuItem(
                            value: site,
                            child: Text(site.displayName, style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (val) => setSheetState(() => selectedSite = val!),
                ),
                const SizedBox(height: 12),

                // Session type
                DropdownButtonFormField<ImmunizationSessionType>(
                  initialValue: selectedSession,
                  decoration: const InputDecoration(
                    labelText: 'Session Type',
                    border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                  ),
                  items: ImmunizationSessionType.values
                      .map((st) => DropdownMenuItem(
                            value: st,
                            child: Text(st.displayName),
                          ))
                      .toList(),
                  onChanged: (val) => setSheetState(() => selectedSession = val!),
                ),
                const SizedBox(height: 12),

                // Batch number (optional)
                TextField(
                  controller: batchController,
                  decoration: const InputDecoration(
                    labelText: 'Vaccine Batch Number (Optional)',
                    border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                    hintText: 'e.g. BATCH-2024-X4',
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes / ANM Remarks (Optional)',
                    border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),

                FilledButton.icon(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Save Dose Administration'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(sheetContext).pop();
                    try {
                      final repo = ref.read(immunizationRepositoryProvider);
                      await repo.recordDose(
                        memberId: widget.memberId,
                        record: VaccineDoseRecord(
                          vaccineCode: selectedVaccineCode,
                          administeredDate: administeredDate,
                          bodySite: selectedSite,
                          sessionType: selectedSession,
                          batchNumber: batchController.text.trim().isNotEmpty ? batchController.text.trim() : null,
                          notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                        ),
                        ashaId: widget.ashaId,
                      );
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('$selectedVaccineCode recorded successfully.')),
                        );
                        _loadImmunizationData();
                      }
                    } catch (e) {
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Error recording dose: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAefiDialog([String? vaccineCode]) {
    showDialog(
      context: context,
      builder: (_) => AefiReportDialog(
        memberId: widget.memberId,
        childName: widget.childName,
        initialVaccineCode: vaccineCode,
        ashaId: widget.ashaId,
      ),
    ).then((_) => _loadImmunizationData());
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _items.where((i) => i.isCompleted).length;
    final totalCount = _items.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;
    final defaulters = _items.where((i) => i.isDefaulter || i.isOverdue).toList();

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.childName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(
              'DOB: ${_dateFormat.format(widget.dateOfBirth)} (${_computeAge(widget.dateOfBirth)})',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem, color: Colors.orangeAccent),
            tooltip: 'Report AEFI',
            onPressed: () => _showAefiDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadImmunizationData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: Text('Loading immunization card...'))
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Coverage Progress Summary Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Vaccination Progress',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: completedCount == totalCount ? Colors.green.shade100 : Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$completedCount / $totalCount Given',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: completedCount == totalCount ? Colors.green.shade900 : Colors.blue.shade900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                              backgroundColor: Colors.grey.shade300,
                              color: completedCount == totalCount ? Colors.green : Colors.teal,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              completedCount >= 16
                                  ? '🎉 Full Immunization (1 Year) Milestone Achieved'
                                  : 'Targeting complete immunization per National Schedule',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Defaulter / Catch-Up Advice Banner (Requirement 16.3)
                    if (defaulters.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red, size: 22),
                                const SizedBox(width: 8),
                                Text(
                                  'Catch-Up Schedule Required (${defaulters.length} Missed/Overdue)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...defaulters.take(3).map((d) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '• ${d.definition.code}: ${d.catchUpGuidance ?? "Administer as soon as possible"}',
                                    style: TextStyle(fontSize: 12, color: Colors.red.shade900),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    const Text(
                      'Mother-Child Protection (MCP) Matrix',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),

                    // Grouped List by Period
                    ..._buildGroupedCards(),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Record Dose'),
        onPressed: () => _showRecordDoseSheet(),
      ),
    );
  }

  List<Widget> _buildGroupedCards() {
    final groups = <String, List<ImmunizationCardItem>>{};
    for (final it in _items) {
      groups.putIfAbsent(it.definition.periodCategory, () => []).add(it);
    }

    final categoryDisplayNames = {
      'AT_BIRTH': 'At Birth',
      '6_WEEKS': '6 Weeks',
      '10_WEEKS': '10 Weeks',
      '14_WEEKS': '14 Weeks',
      '9_12_MONTHS': '9–12 Months',
      '16_24_MONTHS': '16–24 Months',
      '5_6_YEARS': '5–6 Years',
      '10_YEARS': '10 Years',
      '16_YEARS': '16 Years',
    };

    return groups.entries.map((entry) {
      final title = categoryDisplayNames[entry.key] ?? entry.key;
      final items = entry.value;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo),
              ),
              const Divider(height: 16),
              ...items.map((item) => _buildDoseRow(item)),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildDoseRow(ImmunizationCardItem item) {
    final status = item.status;
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case VaccineDoseStatus.given:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusLabel = item.doseRecord?.administeredDate != null
            ? 'Given: ${_dateFormat.format(item.doseRecord!.administeredDate)}'
            : 'Given';
        break;
      case VaccineDoseStatus.due:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusLabel = 'Due Now';
        break;
      case VaccineDoseStatus.overdue:
        statusColor = Colors.deepOrange;
        statusIcon = Icons.warning_amber;
        statusLabel = 'Overdue (${item.daysLapsed}d)';
        break;
      case VaccineDoseStatus.defaulter:
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusLabel = 'Defaulter (${item.daysLapsed}d)';
        break;
      case VaccineDoseStatus.expired:
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        statusLabel = 'Age Expired';
        break;
      case VaccineDoseStatus.upcoming:
        statusColor = Colors.grey.shade600;
        statusIcon = Icons.hourglass_empty;
        statusLabel = 'Due ${_dateFormat.format(item.targetDueDate)}';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: status == VaccineDoseStatus.given
            ? Colors.green.shade50.withValues(alpha: 0.5)
            : (status == VaccineDoseStatus.defaulter ? Colors.red.shade50.withValues(alpha: 0.5) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.definition.code,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  item.definition.name,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
                if (item.doseRecord?.batchNumber != null)
                  Text(
                    'Batch: ${item.doseRecord!.batchNumber} | Site: ${item.doseRecord!.bodySite.name}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                if (item.catchUpGuidance != null && (item.isOverdue || item.isDefaulter))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.catchUpGuidance!,
                      style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                ),
              ),
              if (!item.isCompleted && !item.isExpired)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => _showRecordDoseSheet(item.definition),
                  child: const Text('Record', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _computeAge(DateTime dob) {
    final now = DateTime.now();
    final days = now.difference(dob).inDays;
    if (days < 60) {
      return '$days days';
    } else if (days < 730) {
      final months = (days / 30.4).floor();
      return '$months months';
    } else {
      final years = (days / 365.25).floor();
      return '$years years';
    }
  }
}
