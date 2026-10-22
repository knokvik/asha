import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../referral/presentation/referral_slip_screen.dart';
import '../data/anc_repository.dart';
import '../domain/anc_models.dart';

/// Interactive guided checklist screen for ANC Contacts (Requirements 14.2, 14.3, 14.4, 14.5).
class AncVisitScreen extends ConsumerStatefulWidget {
  final String womanId;
  final String womanName;
  final String visitScheduleId;
  final int contactNumber;
  final int gestationWeeks;
  final String? ashaId;

  const AncVisitScreen({
    super.key,
    required this.womanId,
    required this.womanName,
    required this.visitScheduleId,
    required this.contactNumber,
    required this.gestationWeeks,
    this.ashaId,
  });

  @override
  ConsumerState<AncVisitScreen> createState() => _AncVisitScreenState();
}

class _AncVisitScreenState extends ConsumerState<AncVisitScreen> {
  // ── Vitals & Lab Measurements ──────────────────────────────────────────────
  double? _weightKg;
  int? _systolicBp = 120;
  int? _diastolicBp = 80;
  double? _haemoglobin = 11.5;
  int? _fundalHeightWeeks;
  int? _fetalHeartRateBpm = 140;
  bool _fetalMovementPresent = true;
  bool _urineAlbuminPresent = false;
  bool _urineSugarPresent = false;

  // ── Supplementation & Td ───────────────────────────────────────────────────
  bool _ifaTabletsGiven = true;
  final int _ifaCount = 30;
  bool _calciumTabletsGiven = true;
  final int _calciumCount = 60;
  bool _tdAdministered = false;
  String? _tdDoseType;

  // ── Danger Signs ───────────────────────────────────────────────────────────
  bool _vaginalBleeding = false;
  bool _severeHeadacheOrVision = false;
  bool _severeSwellingFaceHands = false;
  bool _highFever = false;
  bool _leakingAmnioticFluid = false;
  bool _severeAbdominalPain = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fundalHeightWeeks = widget.gestationWeeks;
  }

  AncContactData _buildContactData() {
    return AncContactData(
      contactNumber: widget.contactNumber,
      gestationWeeks: widget.gestationWeeks,
      weightKg: _weightKg,
      systolicBp: _systolicBp,
      diastolicBp: _diastolicBp,
      haemoglobin: _haemoglobin,
      fundalHeightWeeks: _fundalHeightWeeks,
      fetalHeartRateBpm: _fetalHeartRateBpm,
      fetalMovementPresent: _fetalMovementPresent,
      urineAlbuminPresent: _urineAlbuminPresent,
      urineSugarPresent: _urineSugarPresent,
      ifaTabletsGiven: _ifaTabletsGiven,
      ifaCount: _ifaCount,
      calciumTabletsGiven: _calciumTabletsGiven,
      calciumCount: _calciumCount,
      tdAdministered: _tdAdministered,
      tdDoseType: _tdDoseType,
      vaginalBleeding: _vaginalBleeding,
      severeHeadacheOrBlurredVision: _severeHeadacheOrVision,
      severeSwellingFaceHands: _severeSwellingFaceHands,
      highFever: _highFever,
      leakingAmnioticFluid: _leakingAmnioticFluid,
      severeAbdominalPain: _severeAbdominalPain,
    );
  }

  Future<void> _submitVisit() async {
    setState(() => _isSaving = true);
    try {
      final data = _buildContactData();
      final repo = ref.read(ancRepositoryProvider);

      final result = await repo.recordAncVisit(
        womanId: widget.womanId,
        visitScheduleId: widget.visitScheduleId,
        visitData: data,
        ashaId: widget.ashaId ?? 'asha_local',
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (result.isRedFlag) {
        // Immediate emergency referral handoff
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReferralSlipScreen(
              memberId: widget.womanId,
              triageResult: result.triageResult,
              rawVitals: {
                if (data.systolicBp != null) 'bp': '${data.systolicBp}/${data.diastolicBp} mmHg',
                if (data.haemoglobin != null) 'hb': '${data.haemoglobin} g/dL',
                if (data.fundalHeightWeeks != null) 'fundal_height': '${data.fundalHeightWeeks} wks',
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isHighRisk
                  ? 'ANC Contact saved. High-risk alert registered for PMSMA follow-up.'
                  : 'ANC Contact successfully completed.',
            ),
            backgroundColor: result.isHighRisk ? Colors.orange.shade800 : AshaColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving ANC contact: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _buildContactData();
    final dangerSigns = data.clinicalDangerSigns;
    final moderateSigns = data.moderateRiskSigns;
    final hasRed = dangerSigns.isNotEmpty;
    final hasYellow = moderateSigns.isNotEmpty;
    final isBirthPlanDue = widget.gestationWeeks >= 34;

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ANC Contact ${widget.contactNumber} (${widget.gestationWeeks}w)',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
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
          // ── Red Danger Signs Alert Banner (Requirement 14.3) ───────────────
          if (hasRed)
            Card(
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.red.shade700, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'EMERGENCY OBSTETRIC DANGER SIGN(S) DETECTED',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...dangerSigns.map(
                      (s) => Text('• $s', style: TextStyle(color: Colors.red.shade900, fontSize: 13)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Immediate referral to Community Health Centre (FRU) or District Hospital required. Do not delay transport.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // ── Birth Plan Reminder Card at 34 Weeks (Requirement 14.5) ─────────
          if (isBirthPlanDue)
            Card(
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.blue.shade700, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.assignment_turned_in, color: Colors.blue.shade800, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Birth Plan Due (${widget.gestationWeeks} Weeks Gestation)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Review chosen delivery facility, 108 transport, escort, and emergency blood donor with family.',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── SECTION 1: Blood Pressure & Haemoglobin ────────────────────────
          _buildSectionHeader('1. Maternal Vitals & Haemoglobin', Icons.monitor_heart),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('anc_systolic_bp_field'),
                    initialValue: _systolicBp?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Systolic BP (mmHg)',
                      helperText: '>= 140 = High | >= 160 = RED',
                      suffixText: 'mmHg',
                      border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                      filled: true,
                      fillColor: (_systolicBp ?? 0) >= 160
                          ? Colors.red.shade50
                          : ((_systolicBp ?? 0) >= 140 ? Colors.orange.shade50 : null),
                    ),
                    onChanged: (v) => setState(() => _systolicBp = int.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: const Key('anc_diastolic_bp_field'),
                    initialValue: _diastolicBp?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Diastolic BP (mmHg)',
                      helperText: '>= 90 = High | >= 110 = RED',
                      suffixText: 'mmHg',
                      border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                      filled: true,
                      fillColor: (_diastolicBp ?? 0) >= 110
                          ? Colors.red.shade50
                          : ((_diastolicBp ?? 0) >= 90 ? Colors.orange.shade50 : null),
                    ),
                    onChanged: (v) => setState(() => _diastolicBp = int.tryParse(v)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('anc_hb_field'),
                    initialValue: _haemoglobin?.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Haemoglobin (Hb in g/dL)',
                      helperText: '< 11.0 = Anaemia | < 7.0 = Severe (RED)',
                      suffixText: 'g/dL',
                      border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                      filled: true,
                      fillColor: (_haemoglobin ?? 12.0) < 7.0
                          ? Colors.red.shade50
                          : ((_haemoglobin ?? 12.0) < 11.0 ? Colors.yellow.shade50 : null),
                    ),
                    onChanged: (v) => setState(() => _haemoglobin = double.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: _weightKg?.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Maternal Weight (kg)',
                      suffixText: 'kg',
                      border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                    ),
                    onChanged: (v) => setState(() => _weightKg = double.tryParse(v)),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // ── SECTION 2: Obstetric Assessment ────────────────────────────────
          _buildSectionHeader('2. Fetal & Uterine Assessment', Icons.pregnant_woman),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _fundalHeightWeeks?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fundal Height (Weeks/cm)',
                      border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                    ),
                    onChanged: (v) => setState(() => _fundalHeightWeeks = int.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: _fetalHeartRateBpm?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fetal Heart Rate (bpm)',
                      helperText: 'Normal: 110–160 bpm',
                      suffixText: 'bpm',
                      border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                    ),
                    onChanged: (v) => setState(() => _fetalHeartRateBpm = int.tryParse(v)),
                  ),
                ),
              ],
            ),
          ),
          if (widget.gestationWeeks >= 20)
            SwitchListTile(
              title: const Text('Fetal movements actively felt by mother'),
              subtitle: const Text('Absent or reduced movement at >= 24 weeks is an emergency danger sign'),
              value: _fetalMovementPresent,
              onChanged: (v) => setState(() => _fetalMovementPresent = v),
            ),

          const Divider(),

          // ── SECTION 3: Urine Testing (Albumin & Sugar) ──────────────────────
          _buildSectionHeader('3. Urine Dipstick Tests', Icons.science),
          SwitchListTile(
            title: const Text('Urine Albumin / Protein Present (+, ++, or +++)'),
            subtitle: const Text('Indicator for pre-eclampsia when paired with elevated BP'),
            value: _urineAlbuminPresent,
            onChanged: (v) => setState(() => _urineAlbuminPresent = v),
          ),
          SwitchListTile(
            title: const Text('Urine Sugar Present'),
            subtitle: const Text('Indicator for gestational diabetes mellitus (GDM)'),
            value: _urineSugarPresent,
            onChanged: (v) => setState(() => _urineSugarPresent = v),
          ),

          const Divider(),

          // ── SECTION 4: Supplementation & Td Doses ──────────────────────────
          _buildSectionHeader('4. IFA, Calcium & Td Administration', Icons.medication),
          SwitchListTile(
            title: const Text('Iron Folic Acid (IFA) Tablets Given (180 tablets course)'),
            value: _ifaTabletsGiven,
            onChanged: (v) => setState(() => _ifaTabletsGiven = v),
          ),
          SwitchListTile(
            title: const Text('Calcium Tablets Given (360 tablets course from 14 weeks)'),
            value: _calciumTabletsGiven,
            onChanged: (v) => setState(() => _calciumTabletsGiven = v),
          ),
          SwitchListTile(
            title: const Text('Td Vaccine Dose Administered Today'),
            value: _tdAdministered,
            onChanged: (v) => setState(() => _tdAdministered = v),
          ),
          if (_tdAdministered)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                initialValue: _tdDoseType ?? 'Td-1',
                decoration: const InputDecoration(labelText: 'Dose Type', border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle))),
                items: const [
                  DropdownMenuItem(value: 'Td-1', child: Text('Td-1 Dose')),
                  DropdownMenuItem(value: 'Td-2', child: Text('Td-2 Dose (4 weeks after Td-1)')),
                  DropdownMenuItem(value: 'Td-Booster', child: Text('Td-Booster (Pregnancy within 3 years)')),
                ],
                onChanged: (v) => setState(() => _tdDoseType = v),
              ),
            ),

          const Divider(),

          // ── SECTION 5: Danger Signs Checklist (Requirement 14.3) ────────────
          _buildSectionHeader('5. Danger Signs Screening', Icons.warning),
          SwitchListTile(
            title: const Text('Vaginal Bleeding (Antepartum Haemorrhage) [DANGER SIGN]'),
            value: _vaginalBleeding,
            onChanged: (v) => setState(() => _vaginalBleeding = v),
          ),
          SwitchListTile(
            title: const Text('Severe Headache, Blurred Vision, or Epigastric Pain [DANGER SIGN]'),
            value: _severeHeadacheOrVision,
            onChanged: (v) => setState(() => _severeHeadacheOrVision = v),
          ),
          SwitchListTile(
            title: const Text('Severe Swelling of Face, Hands, or Abdomen [DANGER SIGN]'),
            value: _severeSwellingFaceHands,
            onChanged: (v) => setState(() => _severeSwellingFaceHands = v),
          ),
          SwitchListTile(
            title: const Text('High Fever with Chills / Shivering [DANGER SIGN]'),
            value: _highFever,
            onChanged: (v) => setState(() => _highFever = v),
          ),
          SwitchListTile(
            title: const Text('Leaking Amniotic Fluid / Water Breaking [DANGER SIGN]'),
            value: _leakingAmnioticFluid,
            onChanged: (v) => setState(() => _leakingAmnioticFluid = v),
          ),
          SwitchListTile(
            title: const Text('Severe Persistent Abdominal Pain [DANGER SIGN]'),
            value: _severeAbdominalPain,
            onChanged: (v) => setState(() => _severeAbdominalPain = v),
          ),

          const SizedBox(height: 24),

          // ── Submit Visit Button ────────────────────────────────────────────
          ElevatedButton(
            key: const Key('submit_anc_visit_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AshaColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: _isSaving ? null : _submitVisit,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    hasRed
                        ? 'Record Danger Signs & Proceed to Emergency Referral'
                        : (hasYellow ? 'Save High-Risk Contact & Schedule PMSMA' : 'Complete & Save ANC Contact'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
