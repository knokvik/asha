import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../referral/presentation/referral_slip_screen.dart';
import '../data/anc_repository.dart';
import '../domain/anc_models.dart';
import '../../presentation/clinical_form_feedback.dart';
import '../../presentation/clinical_card_helpers.dart';

/// Interactive guided checklist screen for ANC Contacts.
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
    this.contactNumber = 3,
    this.gestationWeeks = 28,
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReferralSlipScreen(
              memberId: widget.womanId,
              triageResult: result.triageResult,
              rawVitals: {
                if (data.systolicBp != null)
                  'bp': '${data.systolicBp}/${data.diastolicBp} mmHg',
                if (data.haemoglobin != null)
                  'haemoglobin': '${data.haemoglobin} g/dL',
                'danger_signs': data.clinicalDangerSigns.join(', '),
              },
            ),
          ),
        );
      } else if (result.isHighRisk) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.event_available, color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                Text('PMSMA Checkup Due'),
              ],
            ),
            content: Text(
              'Moderate risk factors identified (${data.moderateRiskSigns.join(", ")}). '
              'Ensure doctor checkup on 9th of this month (PMSMA).',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  Navigator.pop(context, true);
                },
                child: const Text('Acknowledge'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ANC Contact saved successfully.'),
            backgroundColor: AshaColors.primary,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showClinicalSaveError(
          context,
          program: 'ANC visit',
          error: e,
          onRetry: _submitVisit,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _buildContactData();
    final dangerSigns = data.clinicalDangerSigns;
    final hasRed = dangerSigns.isNotEmpty;
    final hasYellow = data.moderateRiskSigns.isNotEmpty;
    final isBirthPlanDue = widget.gestationWeeks >= 34;

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: const Text('ANC Visit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          ClinicalPatientContextCard(
            name: widget.womanName.trim().isNotEmpty ? widget.womanName : 'ANC Beneficiary',
            details: 'Contact ${widget.contactNumber} · ${widget.gestationWeeks} weeks pregnant',
            contextLabel: 'Registered ANC Beneficiary',
          ),
          const SizedBox(height: 12),

          // Red Danger Signs Alert Banner
          if (hasRed)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade400),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red.shade800, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Danger Signs Detected',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...dangerSigns.map((s) => Text('• $s', style: TextStyle(color: Colors.red.shade900, fontSize: 12.5))),
                  const SizedBox(height: 4),
                  Text(
                    'Immediate transfer to CHC/Hospital recommended via 108.',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade900, fontSize: 11.5),
                  ),
                ],
              ),
            ),

          if (isBirthPlanDue)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment_turned_in, color: Colors.blue.shade800, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Birth plan due (${widget.gestationWeeks}w): Verify hospital, 108 transport, and blood donor.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                    ),
                  ),
                ],
              ),
            ),

          // ── SECTION 1: Vitals & Lab Measurements ──
          ClinicalFormCard(
            title: '1. Vitals & Lab Measurements',
            icon: Icons.monitor_heart_outlined,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _systolicBp?.toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Systolic BP',
                          suffixText: 'mmHg',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AshaColors.borderSubtle)),
                        ),
                        onChanged: (v) => setState(() => _systolicBp = int.tryParse(v)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _diastolicBp?.toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Diastolic BP',
                          suffixText: 'mmHg',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AshaColors.borderSubtle)),
                        ),
                        onChanged: (v) => setState(() => _diastolicBp = int.tryParse(v)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _haemoglobin?.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Haemoglobin (Hb)',
                          suffixText: 'g/dL',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AshaColors.borderSubtle)),
                        ),
                        onChanged: (v) => setState(() => _haemoglobin = double.tryParse(v)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _weightKg?.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Weight',
                          suffixText: 'kg',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AshaColors.borderSubtle)),
                        ),
                        onChanged: (v) => setState(() => _weightKg = double.tryParse(v)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── SECTION 2: Fetal Assessment ──
          ClinicalFormCard(
            title: '2. Fetal & Uterine Assessment',
            icon: Icons.pregnant_woman_outlined,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _fundalHeightWeeks?.toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Fundal Height',
                          suffixText: 'cm',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AshaColors.borderSubtle)),
                        ),
                        onChanged: (v) => setState(() => _fundalHeightWeeks = int.tryParse(v)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: _fetalHeartRateBpm?.toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Heart Rate (FHR)',
                          suffixText: 'bpm',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AshaColors.borderSubtle)),
                        ),
                        onChanged: (v) => setState(() => _fetalHeartRateBpm = int.tryParse(v)),
                      ),
                    ),
                  ],
                ),
                if (widget.gestationWeeks >= 20) ...[
                  const SizedBox(height: 10),
                  ClinicalSwitchTile(
                    title: 'Fetal movements actively felt',
                    value: _fetalMovementPresent,
                    onChanged: (v) => setState(() => _fetalMovementPresent = v),
                  ),
                ],
              ],
            ),
          ),

          // ── SECTION 3: Dipstick & Supplementation ──
          ClinicalFormCard(
            title: '3. Tests & Supplements',
            icon: Icons.medication_outlined,
            child: Column(
              children: [
                ClinicalSwitchTile(
                  title: 'Urine Albumin (+ / ++)',
                  value: _urineAlbuminPresent,
                  onChanged: (v) => setState(() => _urineAlbuminPresent = v),
                  isDanger: true,
                ),
                ClinicalSwitchTile(
                  title: 'Urine Sugar Present',
                  value: _urineSugarPresent,
                  onChanged: (v) => setState(() => _urineSugarPresent = v),
                ),
                ClinicalSwitchTile(
                  title: 'IFA Tablets Distributed (30)',
                  value: _ifaTabletsGiven,
                  onChanged: (v) => setState(() => _ifaTabletsGiven = v),
                ),
                ClinicalSwitchTile(
                  title: 'Calcium Tablets Distributed (60)',
                  value: _calciumTabletsGiven,
                  onChanged: (v) => setState(() => _calciumTabletsGiven = v),
                ),
                ClinicalSwitchTile(
                  title: 'Td Vaccine Dose Given Today',
                  value: _tdAdministered,
                  onChanged: (v) => setState(() => _tdAdministered = v),
                ),
                if (_tdAdministered) ...[
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _tdDoseType ?? 'Td-1',
                    decoration: InputDecoration(
                      labelText: 'Td Dose Type',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Td-1', child: Text('Td-1 Dose')),
                      DropdownMenuItem(value: 'Td-2', child: Text('Td-2 Dose (4w later)')),
                      DropdownMenuItem(value: 'Td-Booster', child: Text('Td-Booster')),
                    ],
                    onChanged: (v) => setState(() => _tdDoseType = v),
                  ),
                ],
              ],
            ),
          ),

          // ── SECTION 4: Danger Signs Screening ──
          ClinicalFormCard(
            title: '4. Danger Signs Screening',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.red.shade700,
            child: Column(
              children: [
                ClinicalSwitchTile(
                  title: 'Vaginal Bleeding',
                  value: _vaginalBleeding,
                  onChanged: (v) => setState(() => _vaginalBleeding = v),
                  isDanger: true,
                ),
                ClinicalSwitchTile(
                  title: 'Severe Headache / Blurred Vision',
                  value: _severeHeadacheOrVision,
                  onChanged: (v) => setState(() => _severeHeadacheOrVision = v),
                  isDanger: true,
                ),
                ClinicalSwitchTile(
                  title: 'Severe Swelling (Face / Hands)',
                  value: _severeSwellingFaceHands,
                  onChanged: (v) => setState(() => _severeSwellingFaceHands = v),
                  isDanger: true,
                ),
                ClinicalSwitchTile(
                  title: 'High Fever with Chills',
                  value: _highFever,
                  onChanged: (v) => setState(() => _highFever = v),
                  isDanger: true,
                ),
                ClinicalSwitchTile(
                  title: 'Leaking Amniotic Fluid',
                  value: _leakingAmnioticFluid,
                  onChanged: (v) => setState(() => _leakingAmnioticFluid = v),
                  isDanger: true,
                ),
                ClinicalSwitchTile(
                  title: 'Severe Abdominal Pain',
                  value: _severeAbdominalPain,
                  onChanged: (v) => setState(() => _severeAbdominalPain = v),
                  isDanger: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          ClinicalSubmitButton(
            label: hasRed
                ? 'Record Danger Signs & Open Emergency Referral'
                : (hasYellow ? 'Save High-Risk Contact & Schedule PMSMA' : 'Save ANC Contact'),
            isSaving: _isSaving,
            isEmergency: hasRed,
            onPressed: _submitVisit,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
