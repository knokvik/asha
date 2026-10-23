import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../referral/presentation/referral_slip_screen.dart';
import '../data/pnc_repository.dart';
import '../domain/pnc_models.dart';
import '../../presentation/clinical_form_feedback.dart';
import '../../presentation/clinical_card_helpers.dart';

/// Guided postpartum maternal visit checklist screen.
class PncVisitScreen extends ConsumerStatefulWidget {
  final String motherId;
  final String motherName;
  final String visitScheduleId;
  final int visitDay;
  final bool isInstitutionalDelivery;
  final String? ashaId;

  const PncVisitScreen({
    super.key,
    required this.motherId,
    required this.motherName,
    required this.visitScheduleId,
    this.visitDay = 7,
    this.isInstitutionalDelivery = true,
    this.ashaId,
  });

  @override
  ConsumerState<PncVisitScreen> createState() => _PncVisitScreenState();
}

class _PncVisitScreenState extends ConsumerState<PncVisitScreen> {
  // ── Vitals ─────────────────────────────────────────────────────────────────
  double? _temperatureC = 37.0;
  int? _systolicBp = 120;
  int? _diastolicBp = 80;

  // ── Clinical Statuses ──────────────────────────────────────────────────────
  PncBleedingStatus _bleedingStatus = PncBleedingStatus.normalLochia;
  PncBreastStatus _breastStatus = PncBreastStatus.normalLactating;
  PncWoundStatus _woundStatus = PncWoundStatus.normalHealing;

  // ── PPD Screening ──────────────────────────────────────────────────────────
  bool _feelsOverwhelmed = false;
  bool _persistentSadness = false;
  bool _difficultyBonding = false;
  bool _severeAnxiety = false;
  bool _thoughtsOfSelfHarm = false;

  // ── General Danger Signs ───────────────────────────────────────────────────
  bool _severeHeadache = false;
  bool _convulsions = false;
  bool _severeAbdominalPain = false;
  bool _severeBreathlessness = false;

  // ── Counselling & PPFP ─────────────────────────────────────────────────────
  bool _nutritionCounsellingGiven = true;
  bool _restHydrationCounseled = true;
  bool _ppfpCounseled = true;
  String? _chosenContraception = 'LAM';

  // ── Institutional Delivery Escort Incentive ────────────────────────────────
  bool _claimDeliveryIncentive = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _claimDeliveryIncentive =
        widget.isInstitutionalDelivery && widget.visitDay <= 3;
  }

  PncChecklistData _buildChecklist() {
    return PncChecklistData(
      visitDay: widget.visitDay,
      temperatureC: _temperatureC,
      systolicBp: _systolicBp,
      diastolicBp: _diastolicBp,
      bleedingStatus: _bleedingStatus,
      breastStatus: _breastStatus,
      woundStatus: _woundStatus,
      depressionScreening: PncDepressionScreening(
        feelsOverwhelmedOrHopeless: _feelsOverwhelmed,
        persistentCryingOrSadness: _persistentSadness,
        difficultyBondingWithBaby: _difficultyBonding,
        severeAnxietyOrInsomnia: _severeAnxiety,
        thoughtsOfSelfHarmOrHarmToBaby: _thoughtsOfSelfHarm,
      ),
      severeHeadacheOrBlurredVision: _severeHeadache,
      convulsionsOrLossOfConsciousness: _convulsions,
      severeAbdominalPain: _severeAbdominalPain,
      severeBreathlessness: _severeBreathlessness,
      nutritionCounsellingGiven: _nutritionCounsellingGiven,
      restAndHydrationCounseled: _restHydrationCounseled,
      postpartumContraceptionCounseled: _ppfpCounseled,
      chosenContraceptionMethod: _chosenContraception,
    );
  }

  Future<void> _submitVisit() async {
    setState(() => _isSaving = true);
    try {
      final checklist = _buildChecklist();
      final repo = ref.read(pncRepositoryProvider);

      final result = await repo.recordPncVisit(
        motherId: widget.motherId,
        visitScheduleId: widget.visitScheduleId,
        checklist: checklist,
        ashaId: widget.ashaId ?? 'asha_local',
      );

      if (_claimDeliveryIncentive) {
        await repo.confirmInstitutionalDelivery(
          motherId: widget.motherId,
          placeOfDelivery: 'institutional',
          ashaId: widget.ashaId ?? 'asha_local',
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (result.isRedFlag) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReferralSlipScreen(
              memberId: widget.motherId,
              triageResult: result.triageResult,
              rawVitals: {
                if (checklist.temperatureC != null)
                  'temperature': '${checklist.temperatureC} °C',
                if (checklist.systolicBp != null)
                  'bp': '${checklist.systolicBp}/${checklist.diastolicBp} mmHg',
                'bleeding': checklist.bleedingStatus.label,
              },
            ),
          ),
        );
      } else if (result.hasPpd) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.support_agent, color: Colors.purple),
                SizedBox(width: 8),
                Text('Support Needed'),
              ],
            ),
            content: const Text(
              'Mild postpartum emotional stress noted. Empathetic counseling offered. '
              'Tele-MANAS helpline: 14416.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context, true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PNC Visit saved on this phone.'),
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
          program: 'PNC visit',
          error: e,
          onRetry: _submitVisit,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checklist = _buildChecklist();
    final dangerSigns = checklist.maternalDangerSigns;
    final hasRed = dangerSigns.isNotEmpty;

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: const Text('PNC Visit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          ClinicalPatientContextCard(
            name: widget.motherName.trim().isNotEmpty ? widget.motherName : 'Postnatal Beneficiary',
            details: 'Postpartum Day ${widget.visitDay} · Maternal follow-up',
            contextLabel: 'Postpartum Mother',
          ),
          const SizedBox(height: 12),

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
                          'Maternal Danger Signs',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...dangerSigns.map((s) => Text('• $s', style: TextStyle(color: Colors.red.shade900, fontSize: 12.5))),
                  const SizedBox(height: 4),
                  Text(
                    'Urgent referral to CHC / District Hospital needed.',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade900, fontSize: 11.5),
                  ),
                ],
              ),
            ),

          // ── SECTION 1: Vitals ──
          ClinicalFormCard(
            title: '1. Vitals & BP',
            icon: Icons.thermostat_outlined,
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _temperatureC?.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Temp (°C)',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setState(() => _temperatureC = double.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: _systolicBp?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Systolic BP',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setState(() => _systolicBp = int.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: _diastolicBp?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Diastolic BP',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setState(() => _diastolicBp = int.tryParse(v)),
                  ),
                ),
              ],
            ),
          ),

          // ── SECTION 2: Physical Check ──
          ClinicalFormCard(
            title: '2. Lochia & Physical Examination',
            icon: Icons.health_and_safety_outlined,
            child: Column(
              children: [
                DropdownButtonFormField<PncBleedingStatus>(
                  initialValue: _bleedingStatus,
                  decoration: InputDecoration(
                    labelText: 'Bleeding / Lochia',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: PncBleedingStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                  onChanged: (v) => setState(() => _bleedingStatus = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<PncBreastStatus>(
                  initialValue: _breastStatus,
                  decoration: InputDecoration(
                    labelText: 'Breast Condition',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: PncBreastStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                  onChanged: (v) => setState(() => _breastStatus = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<PncWoundStatus>(
                  initialValue: _woundStatus,
                  decoration: InputDecoration(
                    labelText: 'Perineal / C-Section Wound',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: PncWoundStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                  onChanged: (v) => setState(() => _woundStatus = v!),
                ),
              ],
            ),
          ),

          // ── SECTION 3: Danger Signs ──
          ClinicalFormCard(
            title: '3. Maternal Danger Signs',
            icon: Icons.warning_amber_rounded,
            iconColor: Colors.red.shade700,
            child: Column(
              children: [
                ClinicalSwitchTile(
                  title: 'Severe Headache / Blurred Vision',
                  value: _severeHeadache,
                  onChanged: (v) => setState(() => _severeHeadache = v),
                  isDanger: true,
                ),
                ClinicalSwitchTile(
                  title: 'Convulsions or Fainting',
                  value: _convulsions,
                  onChanged: (v) => setState(() => _convulsions = v),
                  isDanger: true,
                ),
                ClinicalSwitchTile(
                  title: 'Severe Lower Abdominal Pain',
                  value: _severeAbdominalPain,
                  onChanged: (v) => setState(() => _severeAbdominalPain = v),
                  isDanger: true,
                ),
                ClinicalSwitchTile(
                  title: 'Difficulty Breathing / Chest Pain',
                  value: _severeBreathlessness,
                  onChanged: (v) => setState(() => _severeBreathlessness = v),
                  isDanger: true,
                ),
              ],
            ),
          ),

          // ── SECTION 4: Well-being & Counseling ──
          ClinicalFormCard(
            title: '4. Well-being & Family Planning',
            icon: Icons.psychology_outlined,
            child: Column(
              children: [
                ClinicalSwitchTile(
                  title: 'Feels Overwhelmed or Very Sad',
                  value: _feelsOverwhelmed,
                  onChanged: (v) => setState(() => _feelsOverwhelmed = v),
                ),
                ClinicalSwitchTile(
                  title: 'Difficulty Bonding with Baby',
                  value: _difficultyBonding,
                  onChanged: (v) => setState(() => _difficultyBonding = v),
                ),
                ClinicalSwitchTile(
                  title: 'Nutrition & Hydration Counseling Given',
                  value: _nutritionCounsellingGiven,
                  onChanged: (v) => setState(() => _nutritionCounsellingGiven = v),
                ),
                ClinicalSwitchTile(
                  title: 'Postpartum Family Planning Discussed',
                  value: _ppfpCounseled,
                  onChanged: (v) => setState(() => _ppfpCounseled = v),
                ),
                if (widget.isInstitutionalDelivery && widget.visitDay <= 3) ...[
                  const SizedBox(height: 6),
                  ClinicalSwitchTile(
                    title: 'Claim Institutional Escort Incentive',
                    subtitle: 'Day 1–3 verification',
                    value: _claimDeliveryIncentive,
                    onChanged: (v) => setState(() => _claimDeliveryIncentive = v),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          ClinicalSubmitButton(
            label: hasRed ? 'Danger Sign: Open Emergency Referral' : 'Save PNC Visit',
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
