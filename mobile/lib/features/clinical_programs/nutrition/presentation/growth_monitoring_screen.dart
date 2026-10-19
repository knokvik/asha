import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/triage/models/models.dart';
import '../data/nutrition_repository.dart';
import '../domain/growth_models.dart';
import '../domain/who_growth_calculator.dart';
import 'growth_chart_widget.dart';

/// Screen for recording child growth monitoring measurements, calculating WHO Z-scores,
/// classifying malnutrition, and tracking NRC referrals (Requirements 17.1, 17.2, 17.3).
class GrowthMonitoringScreen extends ConsumerStatefulWidget {
  final String memberId;
  final String childName;
  final DateTime dateOfBirth;
  final String sex;
  final String ashaId;

  const GrowthMonitoringScreen({
    super.key,
    required this.memberId,
    required this.childName,
    required this.dateOfBirth,
    required this.sex,
    required this.ashaId,
  });

  @override
  ConsumerState<GrowthMonitoringScreen> createState() => _GrowthMonitoringScreenState();
}

class _GrowthMonitoringScreenState extends ConsumerState<GrowthMonitoringScreen> {
  final _dateFormat = DateFormat('dd MMM yyyy');
  final _formKey = GlobalKey<FormState>();

  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _muacController = TextEditingController();
  final _hbController = TextEditingController();

  bool _bilateralOedema = false;
  bool? _appetiteTestPassed;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  List<GrowthMeasurement> _history = [];
  GrowthMeasurement? _livePreview;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _weightController.addListener(_updateLivePreview);
    _heightController.addListener(_updateLivePreview);
    _muacController.addListener(_updateLivePreview);
    _hbController.addListener(_updateLivePreview);
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _muacController.dispose();
    _hbController.dispose();
    super.dispose();
  }

  void _updateLivePreview() {
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      if (_livePreview != null) {
        setState(() => _livePreview = null);
      }
      return;
    }

    final height = double.tryParse(_heightController.text.trim());
    final muac = double.tryParse(_muacController.text.trim());
    final hb = double.tryParse(_hbController.text.trim());

    final preview = WhoGrowthCalculator.evaluateNutritionalStatus(
      id: 'preview',
      memberId: widget.memberId,
      measuredAt: DateTime.now(),
      dateOfBirth: widget.dateOfBirth,
      sex: widget.sex,
      weightKg: weight,
      heightCm: height,
      muacCm: muac,
      bilateralOedema: _bilateralOedema,
      appetiteTestPassed: _appetiteTestPassed,
      haemoglobinGdl: hb,
    );

    setState(() => _livePreview = preview);
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final history = await repo.getGrowthHistory(widget.memberId);
      if (mounted) {
        setState(() {
          _history = history;
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

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight in kg')),
      );
      return;
    }

    final height = double.tryParse(_heightController.text.trim());
    final muac = double.tryParse(_muacController.text.trim());
    final hb = double.tryParse(_hbController.text.trim());

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final repo = ref.read(nutritionRepositoryProvider);
      final result = await repo.recordGrowthMeasurement(
        memberId: widget.memberId,
        weightKg: weight,
        heightCm: height,
        muacCm: muac,
        bilateralOedema: _bilateralOedema,
        appetiteTestPassed: _appetiteTestPassed,
        haemoglobinGdl: hb,
        ashaId: widget.ashaId,
      );

      if (!mounted) return;

      _weightController.clear();
      _heightController.clear();
      _muacController.clear();
      _hbController.clear();
      setState(() {
        _bilateralOedema = false;
        _appetiteTestPassed = null;
        _livePreview = null;
      });

      await _loadHistory();
      if (!mounted) return;

      if (result.triageFlag == TriageFlag.red) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.red.shade50,
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('URGENT: RED FLAG', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Severe Malnutrition / Complications detected for ${widget.childName}.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...result.clinicalFindings.map((f) => Text('• $f')),
                const Divider(),
                const Text('Actions Required Immediately:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...result.recommendedActions.map((a) => Text('• $a')),
              ],
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Initiate NRC Referral & Dispatch 108'),
              ),
            ],
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: result.triageFlag == TriageFlag.yellow ? Colors.orange.shade800 : Colors.green.shade800,
            content: Text(
              'Measurement saved. Status: ${result.wastingStatus.label} (${result.triageFlag.name.toUpperCase()})',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Error saving measurement: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSupplementDialog() {
    SupplementType selectedType = SupplementType.ifa;
    final doseController = TextEditingController(text: '1 ml IFA syrup');

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Record Supplementation Dose', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<SupplementType>(
                initialValue: selectedType,
                decoration: const InputDecoration(labelText: 'Supplement Type', border: OutlineInputBorder()),
                items: SupplementType.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() {
                      selectedType = val;
                      if (val == SupplementType.vitaminA) {
                        doseController.text = '100,000 IU (1 ml)';
                      } else if (val == SupplementType.albendazoleDeworming) {
                        doseController.text = '400 mg (1 chewable tablet)';
                      } else {
                        doseController.text = '1 ml IFA syrup';
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: doseController,
                decoration: const InputDecoration(labelText: 'Dose Amount / Regimen', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                try {
                  final repo = ref.read(nutritionRepositoryProvider);
                  await repo.recordSupplementation(
                    memberId: widget.memberId,
                    type: selectedType,
                    doseAmount: doseController.text.trim(),
                    ashaId: widget.ashaId,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${selectedType.displayName} dose recorded successfully.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save Dose'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.childName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(
              'DOB: ${_dateFormat.format(widget.dateOfBirth)} (${widget.sex == "M" ? "Boy" : "Girl"})',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.medication),
            tooltip: 'Record Supplement (IFA/Vit A/Deworming)',
            onPressed: _showSupplementDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: Text('Loading growth records...'))
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    // Growth Chart Widget
                    GrowthChartWidget(measurements: _history, sex: widget.sex),
                    const SizedBox(height: 16),

                    // Assessment Form
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Record Growth Measurement',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 12),

                              // Weight & Height Row
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _weightController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Weight (kg)*',
                                        border: OutlineInputBorder(),
                                        suffixText: 'kg',
                                      ),
                                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _heightController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Height / Length',
                                        border: OutlineInputBorder(),
                                        suffixText: 'cm',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // MUAC & Haemoglobin Row
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _muacController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'MUAC (cm)',
                                        border: OutlineInputBorder(),
                                        suffixText: 'cm',
                                        hintText: 'e.g. 12.0',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _hbController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(
                                        labelText: 'Haemoglobin (Hb)',
                                        border: OutlineInputBorder(),
                                        suffixText: 'g/dL',
                                        hintText: 'e.g. 10.5',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Bilateral Oedema Toggle
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Bilateral Pitting Oedema', style: TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: const Text('Swelling on both feet — danger sign for Kwashiorkor/SAM', style: TextStyle(fontSize: 12)),
                                value: _bilateralOedema,
                                activeThumbColor: Colors.red,
                                onChanged: (v) {
                                  setState(() => _bilateralOedema = v);
                                  _updateLivePreview();
                                },
                              ),

                              // Appetite Test Toggle (RUTF)
                              const Text('Appetite Test (RUTF / Milk)', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('Passed'),
                                    selected: _appetiteTestPassed == true,
                                    onSelected: (sel) {
                                      setState(() => _appetiteTestPassed = sel ? true : null);
                                      _updateLivePreview();
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Failed (Unable to eat)'),
                                    selected: _appetiteTestPassed == false,
                                    selectedColor: Colors.red.shade100,
                                    onSelected: (sel) {
                                      setState(() => _appetiteTestPassed = sel ? false : null);
                                      _updateLivePreview();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Live Classification Preview Card
                              if (_livePreview != null) _buildPreviewCard(_livePreview!),

                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _livePreview?.triageFlag == TriageFlag.red
                                        ? Colors.red
                                        : (_livePreview?.triageFlag == TriageFlag.yellow ? Colors.orange.shade800 : Theme.of(context).colorScheme.primary),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  icon: _isSaving
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.check_circle),
                                  label: Text(_isSaving ? 'Evaluating & Saving...' : 'Save Growth Measurement'),
                                  onPressed: _isSaving ? null : _saveMeasurement,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPreviewCard(GrowthMeasurement preview) {
    Color badgeColor;
    switch (preview.triageFlag) {
      case TriageFlag.red:
        badgeColor = Colors.red;
        break;
      case TriageFlag.yellow:
        badgeColor = Colors.orange.shade800;
        break;
      case TriageFlag.green:
        badgeColor = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: badgeColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Instant Classification (${preview.triageFlag.name.toUpperCase()})',
                style: TextStyle(fontWeight: FontWeight.bold, color: badgeColor, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  preview.wastingStatus.label.split('(').first.trim(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'WAZ: ${preview.waz.toStringAsFixed(2)} ${preview.haz != null ? "• HAZ: ${preview.haz!.toStringAsFixed(2)}" : ""} ${preview.wfhz != null ? "• WFHZ: ${preview.wfhz!.toStringAsFixed(2)}" : ""}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          ...preview.clinicalFindings.map((f) => Text('• $f', style: TextStyle(fontSize: 12, color: Colors.grey.shade900))),
        ],
      ),
    );
  }
}
