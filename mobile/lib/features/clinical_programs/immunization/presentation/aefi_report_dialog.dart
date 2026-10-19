import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/immunization_repository.dart';
import '../domain/immunization_models.dart';

/// Modal dialog for capturing Adverse Events Following Immunization (Requirement 16.6).
class AefiReportDialog extends ConsumerStatefulWidget {
  final String memberId;
  final String? childName;
  final String? initialVaccineCode;
  final DateTime? sessionDate;
  final String ashaId;

  const AefiReportDialog({
    super.key,
    required this.memberId,
    this.childName,
    this.initialVaccineCode,
    this.sessionDate,
    required this.ashaId,
  });

  @override
  ConsumerState<AefiReportDialog> createState() => _AefiReportDialogState();
}

class _AefiReportDialogState extends ConsumerState<AefiReportDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _vaccineCode;
  AefiSeverity _severity = AefiSeverity.minor;
  int _onsetHours = 4;
  final Set<String> _selectedSymptoms = {};
  final _actionController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _vaccineCode = widget.initialVaccineCode ?? 'PENTA_1';
  }

  @override
  void dispose() {
    _actionController.dispose();
    super.dispose();
  }

  bool get _isUrgent {
    final hasUrgentSymptom = _selectedSymptoms.any((s) => AefiSymptoms.isUrgent(s));
    return hasUrgentSymptom || _severity == AefiSeverity.severe || _severity == AefiSeverity.serious;
  }

  Future<void> _saveReport() async {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one symptom')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(immunizationRepositoryProvider);
      final record = await repo.recordAefi(
        memberId: widget.memberId,
        childName: widget.childName,
        vaccineCode: _vaccineCode,
        sessionDate: widget.sessionDate ?? DateTime.now(),
        onsetHoursAfterDose: _onsetHours,
        symptoms: _selectedSymptoms.toList(),
        severity: _severity,
        actionTaken: _actionController.text.trim().isNotEmpty ? _actionController.text.trim() : null,
        ashaId: widget.ashaId,
      );

      if (!mounted) return;

      Navigator.of(context).pop(record);

      if (record.isUrgent) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.red.shade50,
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('URGENT AEFI: RED FLAG', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Urgent adverse reaction reported for ${widget.childName ?? "Child"}.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Immediate emergency referral to PHC / CHC generated.'),
                const Text('• Arrange 108 Ambulance transport immediately.'),
                const Text('• Emergency sync notification dispatched to ANM and Medical Officer.'),
              ],
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Acknowledge & Proceed to Referral'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AEFI report recorded successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error recording AEFI: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Report AEFI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: _isSaving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('Recording AEFI report...', style: TextStyle(fontSize: 16)),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Red alert warning if urgent
                      if (_isUrgent)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade400, width: 1.5),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.report_problem, color: Colors.red, size: 28),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'CRITICAL: Severe symptoms selected! This triggers a RED triage flag and emergency escalation to ANM / MO.',
                                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Vaccine selector
                      DropdownButtonFormField<String>(
                        initialValue: _vaccineCode,
                        decoration: const InputDecoration(
                          labelText: 'Vaccine Administered',
                          border: OutlineInputBorder(),
                        ),
                        items: NationalImmunizationCatalog.infantAndChildSchedule
                            .map((v) => DropdownMenuItem(
                                  value: v.code,
                                  child: Text('${v.code} (${v.name.split("(").first.trim()})'),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => _vaccineCode = val!),
                      ),
                      const SizedBox(height: 16),

                      // Severity dropdown
                      DropdownButtonFormField<AefiSeverity>(
                        initialValue: _severity,
                        decoration: const InputDecoration(
                          labelText: 'Reported Severity',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: AefiSeverity.minor,
                            child: Text('Minor (Local swelling, mild fever)'),
                          ),
                          DropdownMenuItem(
                            value: AefiSeverity.severe,
                            child: Text('Severe (High fever, abscess, persistent crying)'),
                          ),
                          DropdownMenuItem(
                            value: AefiSeverity.serious,
                            child: Text('Serious (Anaphylaxis, fits, hospitalization)'),
                          ),
                        ],
                        onChanged: (val) => setState(() => _severity = val!),
                      ),
                      const SizedBox(height: 16),

                      // Onset hours slider / selector
                      Text('Onset Time After Dose: $_onsetHours hour(s)', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Slider(
                        value: _onsetHours.toDouble(),
                        min: 1,
                        max: 72,
                        divisions: 71,
                        label: '$_onsetHours hrs',
                        onChanged: (v) => setState(() => _onsetHours = v.round()),
                      ),
                      const SizedBox(height: 12),

                      // Symptoms Checkbox List
                      const Text(
                        'Observed Symptoms (Select all that apply):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),

                      const Text('Urgent Symptoms (Trigger RED Flag):', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                      ...AefiSymptoms.urgentSymptoms.map((symptom) => CheckboxListTile(
                            dense: true,
                            title: Text(
                              AefiSymptoms.displayName(symptom),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            value: _selectedSymptoms.contains(symptom),
                            activeColor: Colors.red,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedSymptoms.add(symptom);
                                } else {
                                  _selectedSymptoms.remove(symptom);
                                }
                              });
                            },
                          )),

                      const Divider(),
                      const Text('Minor Symptoms:', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 13)),
                      ...[
                        AefiSymptoms.mildFever,
                        AefiSymptoms.localSwelling,
                        AefiSymptoms.painAtSite,
                        AefiSymptoms.mildIrritability,
                      ].map((symptom) => CheckboxListTile(
                            dense: true,
                            title: Text(
                              AefiSymptoms.displayName(symptom),
                              style: const TextStyle(fontSize: 13),
                            ),
                            value: _selectedSymptoms.contains(symptom),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedSymptoms.add(symptom);
                                } else {
                                  _selectedSymptoms.remove(symptom);
                                }
                              });
                            },
                          )),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _actionController,
                        decoration: const InputDecoration(
                          labelText: 'Action Taken / First Aid Provided',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. Paracetamol advised, cool compress applied, referral initiated',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isUrgent ? Colors.red : Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.send),
                        label: Text(_isUrgent ? 'SUBMIT URGENT AEFI & TRIGGER RED FLAG' : 'Save AEFI Report'),
                        onPressed: _saveReport,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
