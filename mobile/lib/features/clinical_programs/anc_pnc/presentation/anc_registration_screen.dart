import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../data/anc_repository.dart';
import '../domain/anc_models.dart';

/// Interactive pregnancy registration screen (Requirements 14.1, 14.2, 14.3, 14.4).
class AncRegistrationScreen extends ConsumerStatefulWidget {
  final String womanId;
  final String womanName;
  final int? maternalAgeYears;
  final String? ashaId;

  const AncRegistrationScreen({
    super.key,
    required this.womanId,
    required this.womanName,
    this.maternalAgeYears,
    this.ashaId,
  });

  @override
  ConsumerState<AncRegistrationScreen> createState() =>
      _AncRegistrationScreenState();
}

class _AncRegistrationScreenState extends ConsumerState<AncRegistrationScreen> {
  DateTime _lmp = DateTime.now().subtract(
    const Duration(days: 70),
  ); // Default ~10 weeks
  int _gravida = 1;
  int _para = 0;
  int _livingChildren = 0;
  int _stillbirths = 0;
  int _abortions = 0;
  bool _previousCesarean = false;
  String? _bloodGroup = 'B+';
  final TextEditingController _mcpController = TextEditingController();
  final TextEditingController _rchController = TextEditingController();
  final TextEditingController _complicationsController =
      TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _mcpController.dispose();
    _rchController.dispose();
    _complicationsController.dispose();
    super.dispose();
  }

  PregnancyRegistration _buildRegistration() {
    final complications = _complicationsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return PregnancyRegistration(
      womanId: widget.womanId,
      lmp: _lmp,
      gravida: _gravida,
      para: _para,
      livingChildren: _livingChildren,
      stillbirths: _stillbirths,
      abortions: _abortions,
      previousCesarean: _previousCesarean,
      previousComplications: complications,
      mcpCardNumber: _mcpController.text.trim().isEmpty
          ? null
          : _mcpController.text.trim(),
      rchId: _rchController.text.trim().isEmpty
          ? null
          : _rchController.text.trim(),
      bloodGroup: _bloodGroup,
      maternalAgeYears: widget.maternalAgeYears,
    );
  }

  Future<void> _pickLmpDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lmp,
      firstDate: DateTime.now().subtract(const Duration(days: 300)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _lmp = picked);
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _isSaving = true);
    try {
      final reg = _buildRegistration();
      final repo = ref.read(ancRepositoryProvider);

      final schedules = await repo.registerPregnancy(
        registration: reg,
        ashaId: widget.ashaId ?? 'asha_local',
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pregnancy registered! Generated ${schedules.length} ANC schedule contacts and visits.',
          ),
          backgroundColor: AshaColors.primary,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error registering pregnancy: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reg = _buildRegistration();
    final gestationWeeks = reg.gestationWeeksAt();
    final highRiskReasons = reg.baselineHighRiskReasons;
    final isHighRisk = reg.isBaselineHighRisk;

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Register Pregnancy',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              widget.womanName,
              style: const TextStyle(fontSize: 12, color: AshaColors.textMuted),
            ),
          ],
        ),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── High Risk Pregnancy Preview Alert (Requirement 14.3) ────────────
          if (isHighRisk)
            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.orange.shade800, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade900,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'HIGH-RISK PREGNANCY (HRP) CRITERIA DETECTED',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...highRiskReasons.map(
                      (r) => Text(
                        '• $r',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'App will automatically increase ANC contact frequency and sync priority alert to ANM/AF.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── Gestation & EDD Card ───────────────────────────────────────────
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month, color: AshaColors.primary),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Gestational Age & Delivery Dates',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Last Menstrual Period (LMP)'),
                    subtitle: Text('${_lmp.day}/${_lmp.month}/${_lmp.year}'),
                    trailing: OutlinedButton.icon(
                      onPressed: _pickLmpDate,
                      icon: const Icon(Icons.edit_calendar),
                      label: const Text('Change'),
                    ),
                  ),
                  ListTile(
                    title: const Text(
                      'Estimated Date of Delivery (EDD) [Naegele]',
                    ),
                    subtitle: Text(
                      '${reg.edd.day}/${reg.edd.month}/${reg.edd.year}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  ListTile(
                    title: const Text('Current Gestation'),
                    subtitle: Text(
                      '$gestationWeeks Weeks (${reg.gestationDaysAt()} days)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Obstetric History Section ──────────────────────────────────────
          _buildSectionHeader('Obstetric History', Icons.pregnant_woman),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _gravida.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Gravida (Total pregnancies)',
                    border: OutlineInputBorder(
                      borderRadius: AshaShapes.searchRadius,
                      borderSide: BorderSide(color: AshaColors.borderSubtle),
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => _gravida = int.tryParse(v) ?? 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: _para.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Para (Viable births)',
                    border: OutlineInputBorder(
                      borderRadius: AshaShapes.searchRadius,
                      borderSide: BorderSide(color: AshaColors.borderSubtle),
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => _para = int.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _livingChildren.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Living Children',
                    border: OutlineInputBorder(
                      borderRadius: AshaShapes.searchRadius,
                      borderSide: BorderSide(color: AshaColors.borderSubtle),
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => _livingChildren = int.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: _stillbirths.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Previous Stillbirths',
                    border: OutlineInputBorder(
                      borderRadius: AshaShapes.searchRadius,
                      borderSide: BorderSide(color: AshaColors.borderSubtle),
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => _stillbirths = int.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: _abortions.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Prior Abortions',
                    border: OutlineInputBorder(
                      borderRadius: AshaShapes.searchRadius,
                      borderSide: BorderSide(color: AshaColors.borderSubtle),
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => _abortions = int.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text(
              'History of previous Cesarean Section (C-Section)',
            ),
            subtitle: const Text(
              'High risk — requires facility delivery planning',
            ),
            value: _previousCesarean,
            onChanged: (val) => setState(() => _previousCesarean = val),
          ),

          const Divider(),

          // ── Identifiers & Linkage ──────────────────────────────────────────
          _buildSectionHeader('MCP Card & Government Identifiers', Icons.badge),
          TextFormField(
            controller: _mcpController,
            decoration: const InputDecoration(
              labelText: 'Mother & Child Protection (MCP) Card Number',
              border: OutlineInputBorder(
                borderRadius: AshaShapes.searchRadius,
                borderSide: BorderSide(color: AshaColors.borderSubtle),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rchController,
            decoration: const InputDecoration(
              labelText: 'RCH Portal ID / ABHA ID',
              border: OutlineInputBorder(
                borderRadius: AshaShapes.searchRadius,
                borderSide: BorderSide(color: AshaColors.borderSubtle),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _bloodGroup,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Maternal Blood Group & Rh Factor',
              border: OutlineInputBorder(
                borderRadius: AshaShapes.searchRadius,
                borderSide: BorderSide(color: AshaColors.borderSubtle),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: 'A+',
                child: Text(
                  'A Positive (A+)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'B+',
                child: Text(
                  'B Positive (B+)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'O+',
                child: Text(
                  'O Positive (O+)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'AB+',
                child: Text(
                  'AB Positive (AB+)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'A-',
                child: Text(
                  'A Negative (A-) — Rh negative',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'B-',
                child: Text(
                  'B Negative (B-) — Rh negative',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'O-',
                child: Text(
                  'O Negative (O-) — Rh negative',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              DropdownMenuItem(
                value: 'AB-',
                child: Text(
                  'AB Negative (AB-) — Rh negative',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            onChanged: (v) => setState(() => _bloodGroup = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _complicationsController,
            decoration: const InputDecoration(
              labelText: 'Prior Complications (e.g. pre-eclampsia, PPH, GDM)',
              helperText: 'Separate multiple conditions with commas',
              border: OutlineInputBorder(
                borderRadius: AshaShapes.searchRadius,
                borderSide: BorderSide(color: AshaColors.borderSubtle),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Save & Generate Schedule Button ────────────────────────────────
          ElevatedButton(
            key: const Key('submit_anc_registration_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AshaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isSaving ? null : _submitRegistration,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Complete Registration & Generate ANC Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AshaColors.primary, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AshaColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
