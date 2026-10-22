import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../data/ncd_repository.dart';
import '../domain/cbac_models.dart';

/// Screen displaying the Chronic Care Register for hypertension and diabetes patients,
/// tracking medication refills, adherence check visits, overdue tracing, and
/// National NCD Portal CSV export.
///
/// Implements Requirements 19.4 – 19.6.
class NcdRegisterScreen extends ConsumerStatefulWidget {
  final String ashaId;

  const NcdRegisterScreen({
    super.key,
    required this.ashaId,
  });

  @override
  ConsumerState<NcdRegisterScreen> createState() => _NcdRegisterScreenState();
}

class _NcdRegisterScreenState extends ConsumerState<NcdRegisterScreen> {
  bool _isLoading = false;
  String? _exportedCsv;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'NCD Chronic Care Register',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              'Hypertension, Diabetes & Chronic Care Monitoring',
              style: TextStyle(fontSize: 12, color: AshaColors.textMuted),
            ),
          ],
        ),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Run Overdue Tracing',
            icon: const Icon(Icons.person_search),
            onPressed: _runOverdueTracing,
          ),
          IconButton(
            tooltip: 'Export National NCD Portal CSV',
            icon: const Icon(Icons.file_download),
            onPressed: _exportNationalCsv,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Quick Summary Card
                Card(
                  color: Colors.blueGrey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.monitor_heart, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Hypertension & Diabetes Follow-up',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Track monthly medication refills, adherence check visits, and repeat BP / Blood Glucose measurements.',
                          style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_exportedCsv != null) ...[
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green),
                              const SizedBox(width: 8),
                              const Text('National NCD Portal CSV Generated', style: TextStyle(fontWeight: FontWeight.bold)),
                              const Spacer(),
                              TextButton(
                                onPressed: () => setState(() => _exportedCsv = null),
                                child: const Text('Dismiss'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'CSV export ready with ${_exportedCsv!.split("\n").length - 1} records. Ready for upload to national NCD portal without re-entry.',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Cards
                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.medication, color: Colors.white),
                  ),
                  title: const Text('Monthly Refill & Adherence Check', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Record repeat BP, sugar, refill distribution & adherence status'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRecordFollowUpDialog(context),
                ),
                const SizedBox(height: 12),

                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.amber,
                    child: Icon(Icons.person_search, color: Colors.white),
                  ),
                  title: const Text('Overdue Defaulter Tracing', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Scan patients overdue for refills > 14 days and create priority due tasks'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _runOverdueTracing,
                ),
                const SizedBox(height: 12),

                ListTile(
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.file_download, color: Colors.white),
                  ),
                  title: const Text('Export to National NCD Portal', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Export CBAC screening CSV format (Requirement 19.6, 35)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _exportNationalCsv,
                ),
              ],
            ),
    );
  }

  Future<void> _runOverdueTracing() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(ncdRepositoryProvider);
      final tasks = await repo.generateOverdueTracingTasks(overdueDaysThreshold: 14);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tasks.isEmpty
                ? 'No overdue NCD defaulters (> 14 days) found.'
                : 'Generated ${tasks.length} urgent NCD tracing tasks in Due List!',
          ),
          backgroundColor: tasks.isEmpty ? Colors.teal : Colors.amber.shade900,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error running tracing: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportNationalCsv() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(ncdRepositoryProvider);
      final csv = await repo.exportNationalNcdPortalCsv();

      if (!mounted) return;
      setState(() => _exportedCsv = csv);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('National NCD Portal CSV generated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting CSV: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showRecordFollowUpDialog(BuildContext context) {
    final memberIdController = TextEditingController();
    final sbpController = TextEditingController();
    final dbpController = TextEditingController();
    final glucoseController = TextEditingController();
    MedicationAdherence adherence = MedicationAdherence.regular;
    bool refilled = true;
    int refillDays = 30;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record NCD Follow-Up Visit'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: memberIdController,
                  decoration: const InputDecoration(labelText: 'Beneficiary Member ID', border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle))),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: sbpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'SBP', hintText: '120', border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: dbpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'DBP', hintText: '80', border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: glucoseController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Blood Glucose (mg/dL)', border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle))),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MedicationAdherence>(
                  initialValue: adherence,
                  decoration: const InputDecoration(labelText: 'Medication Adherence', border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle))),
                  items: MedicationAdherence.values
                      .map((a) => DropdownMenuItem(value: a, child: Text(a.label)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => adherence = val);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Medicines Refilled'),
                  value: refilled,
                  onChanged: (v) => setDialogState(() => refilled = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final memberId = memberIdController.text.trim();
                if (memberId.isEmpty) return;

                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                try {
                  final repo = ref.read(ncdRepositoryProvider);
                  await repo.recordFollowUpVisit(
                    memberId: memberId,
                    systolicBp: int.tryParse(sbpController.text.trim()),
                    diastolicBp: int.tryParse(dbpController.text.trim()),
                    bloodGlucoseMgDl: double.tryParse(glucoseController.text.trim()),
                    glucoseType: GlucoseType.random,
                    adherence: adherence,
                    medicinesRefilled: refilled,
                    daysOfRefillProvided: refillDays,
                    ashaId: widget.ashaId,
                  );
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('NCD Follow-Up Visit Recorded!'), backgroundColor: Colors.teal),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Save Visit'),
            ),
          ],
        ),
      ),
    );
  }
}
