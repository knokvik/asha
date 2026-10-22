import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../referral/presentation/referral_slip_screen.dart';
import '../data/pnc_repository.dart';
import '../domain/pnc_models.dart';
import '../../presentation/clinical_form_feedback.dart';

/// Guided postpartum maternal visit checklist screen (Requirements 15.1 – 15.6).
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
    required this.visitDay,
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
  String? _chosenContraception = 'LAM'; // Lactational Amenorrhea Method

  // ── Institutional Delivery Escort Incentive ────────────────────────────────
  bool _claimDeliveryIncentive = false;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _claimDeliveryIncentive = widget.isInstitutionalDelivery && widget.visitDay <= 3;
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

      // Claim institutional delivery escort incentive if checked
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
        // Immediate emergency referral handoff
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReferralSlipScreen(
              memberId: widget.motherId,
              triageResult: result.triageResult,
              rawVitals: {
                if (checklist.temperatureC != null) 'temperature': '${checklist.temperatureC} °C',
                if (checklist.systolicBp != null) 'bp': '${checklist.systolicBp}/${checklist.diastolicBp} mmHg',
                'bleeding': checklist.bleedingStatus.label,
              },
            ),
          ),
        );
      } else if (result.hasPpd) {
        // Show mental health supportive counselling dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.support_agent, color: Colors.purple.shade800),
                const SizedBox(width: 8),
                const Text('Maternal Mental Health'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Postpartum depression indicators observed. Connect mother and family with supportive mental health guidance.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Observations:\n${result.ppdFindings.map((e) => '• $e').join('\n')}'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.phone_in_talk, color: Colors.purple),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tele-MANAS Toll-Free: 14416 (24x7 National Mental Health Helpline in 20 languages)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context, true);
                },
                child: const Text('Close & Complete'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade800,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReferralSlipScreen(
                        memberId: widget.motherId,
                        triageResult: result.triageResult,
                        rawVitals: {
                          'ppd_status': 'Positive',
                          'support_helpline': 'Tele-MANAS (14416)',
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Create PHC Mental Health Slip'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _claimDeliveryIncentive
                  ? 'PNC Visit recorded and Institutional Delivery Escort incentive claimed!'
                  : 'PNC visit saved on this phone.',
            ),
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
    final hasPpd = checklist.hasPpd;

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PNC visit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          ],
        ),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClinicalPatientContextCard(
            name: widget.motherName,
            details: 'Postpartum day ${widget.visitDay} · maternal follow-up',
            contextLabel: 'Patient selected from the local register',
          ),
          const SizedBox(height: 12),
          // ── Red Danger Signs Alert Banner (Requirement 15.4) ───────────────
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
                            'MATERNAL POSTPARTUM DANGER SIGN(S) DETECTED',
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
                      'Immediate referral to Community Health Centre (FRU) or District Hospital required. PPH or puerperal sepsis risk.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          // ── PPD Support Banner (Requirement 15.5) ──────────────────────────
          if (!hasRed && hasPpd)
            Card(
              color: Colors.purple.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.purple.shade700, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.purple.shade800, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Postpartum Emotional Well-Being Need Detected',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Provide calm empathetic listening. Offer Tele-MANAS (14416) or PHC counsellor referral upon visit completion.',
                            style: TextStyle(fontSize: 12, color: Colors.purple.shade900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── SECTION 1: Maternal Vitals ─────────────────────────────────────
          _buildSectionHeader('1. Temperature & Blood Pressure', Icons.thermostat),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('pnc_temp_field'),
                    initialValue: _temperatureC?.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Temp (°C)',
                      helperText: '>=38.0°C RED',
                      suffixText: '°C',
                      border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                      filled: true,
                      fillColor: (_temperatureC ?? 0) >= 38.0 ? Colors.red.shade50 : null,
                    ),
                    onChanged: (v) => setState(() => _temperatureC = double.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: const Key('pnc_systolic_bp_field'),
                    initialValue: _systolicBp?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Systolic BP',
                      helperText: '>=160 RED',
                      suffixText: 'mmHg',
                      border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                      filled: true,
                      fillColor: (_systolicBp ?? 0) >= 160 ? Colors.red.shade50 : null,
                    ),
                    onChanged: (v) => setState(() => _systolicBp = int.tryParse(v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: const Key('pnc_diastolic_bp_field'),
                    initialValue: _diastolicBp?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Diastolic BP',
                      helperText: '>=110 RED',
                      suffixText: 'mmHg',
                      border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                      filled: true,
                      fillColor: (_diastolicBp ?? 0) >= 110 ? Colors.red.shade50 : null,
                    ),
                    onChanged: (v) => setState(() => _diastolicBp = int.tryParse(v)),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // ── Danger Signs Check ─────────────────────────────────────────────
          _buildSectionHeader('Severe Danger Symptoms', Icons.warning_amber),
          SwitchListTile(
            title: const Text('Severe persistent headache or blurred vision'),
            value: _severeHeadache,
            activeTrackColor: Colors.red.shade800,
            onChanged: (v) => setState(() => _severeHeadache = v),
          ),
          SwitchListTile(
            title: const Text('Convulsions or loss of consciousness'),
            value: _convulsions,
            activeTrackColor: Colors.red.shade800,
            onChanged: (v) => setState(() => _convulsions = v),
          ),
          SwitchListTile(
            title: const Text('Severe lower abdominal pain'),
            value: _severeAbdominalPain,
            activeTrackColor: Colors.red.shade800,
            onChanged: (v) => setState(() => _severeAbdominalPain = v),
          ),
          SwitchListTile(
            title: const Text('Severe breathlessness or chest tightness'),
            value: _severeBreathlessness,
            activeTrackColor: Colors.red.shade800,
            onChanged: (v) => setState(() => _severeBreathlessness = v),
          ),

          const Divider(),

          // ── SECTION 2: Postpartum Bleeding & Lochia ─────────────────────────
          _buildSectionHeader('2. Bleeding & Vaginal Discharge', Icons.water_drop),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<PncBleedingStatus>(
              initialValue: _bleedingStatus,
              decoration: const InputDecoration(
                labelText: 'Maternal Bleeding / Lochia Status',
                border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
              ),
              items: PncBleedingStatus.values.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.label));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _bleedingStatus = v);
              },
            ),
          ),

          const Divider(),

          // ── SECTION 3: Breast & Wound Examination ───────────────────────────
          _buildSectionHeader('3. Breast & Surgical / Episiotomy Wound', Icons.health_and_safety),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<PncBreastStatus>(
              initialValue: _breastStatus,
              decoration: const InputDecoration(
                labelText: 'Breast Condition',
                border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
              ),
              items: PncBreastStatus.values.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.label));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _breastStatus = v);
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<PncWoundStatus>(
              initialValue: _woundStatus,
              decoration: const InputDecoration(
                labelText: 'Episiotomy / Cesarean Wound Healing',
                border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
              ),
              items: PncWoundStatus.values.map((s) {
                return DropdownMenuItem(value: s, child: Text(s.label));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _woundStatus = v);
              },
            ),
          ),

          const Divider(),

          // ── SECTION 4: Postpartum Depression (PPD) Screening ───────────────
          _buildSectionHeader('4. Postpartum Emotional Well-Being (PPD Screening)', Icons.sentiment_dissatisfied),
          SwitchListTile(
            title: const Text('Feeling overwhelmed, hopeless, or empty most of the time'),
            value: _feelsOverwhelmed,
            onChanged: (v) => setState(() => _feelsOverwhelmed = v),
          ),
          SwitchListTile(
            title: const Text('Frequent persistent crying, sadness, or lack of joy'),
            value: _persistentSadness,
            onChanged: (v) => setState(() => _persistentSadness = v),
          ),
          SwitchListTile(
            title: const Text('Difficulty bonding with or feeling love towards newborn'),
            value: _difficultyBonding,
            onChanged: (v) => setState(() => _difficultyBonding = v),
          ),
          SwitchListTile(
            title: const Text('Severe anxiety, racing thoughts, or inability to rest'),
            value: _severeAnxiety,
            onChanged: (v) => setState(() => _severeAnxiety = v),
          ),
          SwitchListTile(
            title: const Text('Thoughts of hurting self or baby [CRISIS RED FLAG]'),
            value: _thoughtsOfSelfHarm,
            activeTrackColor: Colors.red.shade800,
            onChanged: (v) => setState(() => _thoughtsOfSelfHarm = v),
          ),

          const Divider(),

          // ── SECTION 5: Nutrition & Family Planning (PPFP) ───────────────────
          _buildSectionHeader('5. Postpartum Family Planning & Nutrition', Icons.family_restroom),
          SwitchListTile(
            title: const Text('Maternal nutrition counselled (extra food + IFA/Calcium continuation)'),
            value: _nutritionCounsellingGiven,
            onChanged: (v) => setState(() => _nutritionCounsellingGiven = v),
          ),
          SwitchListTile(
            title: const Text('Adequate rest, fluids and hydration counselled'),
            value: _restHydrationCounseled,
            onChanged: (v) => setState(() => _restHydrationCounseled = v),
          ),
          SwitchListTile(
            title: const Text('Postpartum Family Planning (PPFP) methods counselled'),
            value: _ppfpCounseled,
            onChanged: (v) => setState(() => _ppfpCounseled = v),
          ),
          if (_ppfpCounseled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String>(
                initialValue: _chosenContraception,
                decoration: const InputDecoration(labelText: 'Method Discussed / Selected', border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle))),
                items: const [
                  DropdownMenuItem(value: 'LAM', child: Text('Lactational Amenorrhea Method (LAM)')),
                  DropdownMenuItem(value: 'PPIUCD', child: Text('Postpartum IUCD (PPIUCD / Cu-T)')),
                  DropdownMenuItem(value: 'Chhaya', child: Text('Chhaya (Centchroman non-hormonal pill)')),
                  DropdownMenuItem(value: 'Antara', child: Text('Antara (DMPA Injection)')),
                  DropdownMenuItem(value: 'Condoms', child: Text('Nirodh / Condoms')),
                  DropdownMenuItem(value: 'Female Sterilisation', child: Text('Postpartum Tubectomy')),
                ],
                onChanged: (v) => setState(() => _chosenContraception = v),
              ),
            ),

          const Divider(),

          // ── SECTION 6: Institutional Delivery Incentive (Requirement 15.6) ─
          if (widget.isInstitutionalDelivery) ...[
            _buildSectionHeader('6. Facilitated Institutional Delivery Incentive', Icons.currency_rupee),
            CheckboxListTile(
              title: const Text('Facilitated Institutional Delivery Escort (JSY Scheme)'),
              subtitle: const Text('ASHA escorted and supported mother at health facility delivery'),
              value: _claimDeliveryIncentive,
              onChanged: (v) => setState(() => _claimDeliveryIncentive = v ?? false),
            ),
            const Divider(),
          ],

          const SizedBox(height: 20),

          // ── Submit Visit Button ────────────────────────────────────────────
          ElevatedButton(
            key: const Key('submit_pnc_visit_button'),
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
                        ? 'Record Maternal Danger Signs & Proceed to Referral'
                        : (hasPpd ? 'Complete PNC Visit & Review Tele-MANAS Referral' : 'Save & Complete PNC Visit'),
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
