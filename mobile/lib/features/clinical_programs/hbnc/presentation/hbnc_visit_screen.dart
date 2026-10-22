// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../referral/presentation/referral_slip_screen.dart';
import '../data/hbnc_repository.dart';
import '../domain/hbnc_models.dart';
import '../domain/kmc_guidance.dart';

/// Screen presenting the guided Home Based Newborn Care (HBNC) visit checklist.
///
/// Implements Requirements 12.2, 12.3, 12.4, 12.7:
/// - Guided flow: feeding, weight, temperature, breathing, cord, skin, eyes, activity, jaundice, thermal/KMC, maternal PNC.
/// - Immediate RED alert and referral handoff upon danger sign detection.
/// - High-risk KMC card for low-birth-weight (<2.5 kg) or preterm infants.
/// - Persists discrete clinical observations and auto-generates incentive on episode completion.
class HbncVisitScreen extends ConsumerStatefulWidget {
  final String newbornId;
  final String motherId;
  final String visitScheduleId;
  final String visitTitle;
  final double birthWeightKg;
  final bool isPreterm;
  final String? ashaId;

  const HbncVisitScreen({
    super.key,
    required this.newbornId,
    required this.motherId,
    required this.visitScheduleId,
    required this.visitTitle,
    this.birthWeightKg = 2.8,
    this.isPreterm = false,
    this.ashaId,
  });

  @override
  ConsumerState<HbncVisitScreen> createState() => _HbncVisitScreenState();
}

class _HbncVisitScreenState extends ConsumerState<HbncVisitScreen> {
  // Checklist State Variables
  double? _currentWeightKg;
  double? _temperatureC;
  int? _respiratoryRate;
  bool _chestIndrawing = false;
  bool _grunting = false;
  FeedingStatus _feedingStatus = FeedingStatus.exclusiveBreastfeeding;
  CordStatus _cordStatus = CordStatus.cleanAndDry;
  SkinStatus _skinStatus = SkinStatus.clearNormal;
  EyeStatus _eyeStatus = EyeStatus.clear;
  ActivityStatus _activityStatus = ActivityStatus.activeAndAlert;
  JaundiceStatus _jaundiceStatus = JaundiceStatus.none;
  bool _delayedBathing = true;
  bool _warmChain = true;
  bool _kmcPracticed = false;
  double? _kmcHours;
  MaternalBleedingStatus _maternalBleeding = MaternalBleedingStatus.normalLochia;
  bool _maternalFever = false;
  bool _maternalSevereHeadache = false;
  String _maternalWound = 'normal';

  bool _isSaving = false;
  bool _showKmcDetails = false;

  bool get _isLbw => widget.birthWeightKg < 2.5;
  bool get _isHighRisk => _isLbw || widget.isPreterm;

  HbncChecklistData _buildChecklist() {
    return HbncChecklistData(
      currentWeightKg: _currentWeightKg,
      temperatureC: _temperatureC,
      respiratoryRate: _respiratoryRate,
      chestIndrawing: _chestIndrawing,
      grunting: _grunting,
      feedingStatus: _feedingStatus,
      cordStatus: _cordStatus,
      skinStatus: _skinStatus,
      eyeStatus: _eyeStatus,
      activityStatus: _activityStatus,
      jaundiceStatus: _jaundiceStatus,
      delayedBathingPracticed: _delayedBathing,
      keptWarmInWarmChain: _warmChain,
      kmcPracticed: _kmcPracticed,
      kmcHoursPerDay: _kmcHours,
      maternalBleeding: _maternalBleeding,
      maternalFever: _maternalFever,
      maternalSevereHeadache: _maternalSevereHeadache,
      maternalWoundHealing: _maternalWound,
    );
  }

  Future<void> _submitVisit() async {
    setState(() => _isSaving = true);
    final checklist = _buildChecklist();
    final repo = ref.read(hbncRepositoryProvider);

    try {
      final result = await repo.recordVisit(
        newbornId: widget.newbornId,
        visitScheduleId: widget.visitScheduleId,
        checklist: checklist,
        ashaId: widget.ashaId ?? 'asha_local',
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (result.hasDangerSign) {
        // Requirement 12.3: Immediate RED referral handoff
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReferralSlipScreen(
              memberId: widget.newbornId,
              triageResult: result.triageResult,
              rawVitals: {
                'weight': '${checklist.currentWeightKg ?? widget.birthWeightKg} kg',
                'temperature': '${checklist.temperatureC ?? "unrecorded"} °C',
                'respiratory_rate': '${checklist.respiratoryRate ?? "unrecorded"} /min',
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isEpisodeCompleted
                  ? 'HBNC Episode Complete! Incentive event registered.'
                  : 'HBNC Visit successfully recorded.',
            ),
            backgroundColor: Colors.green.shade800,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving HBNC visit: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checklist = _buildChecklist();
    final dangerSigns = checklist.newbornDangerSigns;
    final maternalDangers = checklist.maternalDangerSigns;
    final hasDangers = dangerSigns.isNotEmpty || maternalDangers.isNotEmpty;

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.visitTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const Text(
              'Home-Based Newborn Care (HBNC)',
              style: TextStyle(fontSize: 12, color: AshaColors.textMuted),
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
          // ── Danger Signs Alert Banner (Requirement 12.3) ───────────────────
          if (hasDangers)
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
                        Icon(Icons.warning, color: Colors.red.shade800, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'DANGER SIGN DETECTED — URGENT',
                          style: TextStyle(
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (final sign in [...dangerSigns, ...maternalDangers])
                      Text('• $sign', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800, foregroundColor: Colors.white),
                      onPressed: _submitVisit,
                      icon: const Icon(Icons.emergency),
                      label: const Text('Open Emergency Referral Slip (108)'),
                    ),
                  ],
                ),
              ),
            ),

          if (hasDangers) const SizedBox(height: 16),

          // ── High-Risk KMC Guidance Banner (Requirement 12.4) ───────────────
          if (_isHighRisk)
            Card(
              color: Colors.amber.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.amber.shade700, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ExpansionTile(
                initiallyExpanded: _showKmcDetails,
                onExpansionChanged: (v) => setState(() => _showKmcDetails = v),
                leading: Icon(Icons.favorite, color: Colors.amber.shade900),
                title: Text(
                  'High Risk Newborn: Low Birth Weight (${widget.birthWeightKg} kg)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                ),
                subtitle: const Text('Kangaroo Mother Care (KMC) guidance active'),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          KmcGuidance.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 6),
                        for (final step in KmcGuidance.coreSteps)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $step', style: const TextStyle(fontSize: 12.5)),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'Target: At least ${KmcGuidance.recommendedTargetHours(widget.birthWeightKg)} hours/day skin-to-skin',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (_isHighRisk) const SizedBox(height: 16),

          // ── 1. Feeding & Breastfeeding ──────────────────────────────────────
          _buildSectionHeader('1. Feeding & Breastfeeding', Icons.baby_changing_station),
          for (final f in FeedingStatus.values)
            RadioListTile<FeedingStatus>(
              title: Text(f.label, style: TextStyle(color: f.isDangerSign ? Colors.red.shade900 : null)),
              value: f,
              groupValue: _feedingStatus,
              onChanged: (val) => setState(() => _feedingStatus = val!),
            ),

          const Divider(),

          // ── 2. Weight Measurement ──────────────────────────────────────────
          _buildSectionHeader('2. Weight Measurement', Icons.monitor_weight),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Current Weight in kg (Birth Weight: ${widget.birthWeightKg} kg)',
                suffixText: 'kg',
                border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
              ),
              onChanged: (val) {
                final d = double.tryParse(val);
                setState(() => _currentWeightKg = d);
              },
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // ── 3. Body Temperature ───────────────────────────────────────────
          _buildSectionHeader('3. Body Temperature', Icons.thermostat),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Axillary Temperature (°C) [Normal: 36.5–37.4°C]',
                suffixText: '°C',
                border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
              ),
              onChanged: (val) {
                final t = double.tryParse(val);
                setState(() => _temperatureC = t);
              },
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // ── 4. Breathing & Respiratory Rate ───────────────────────────────
          _buildSectionHeader('4. Breathing & Respiratory Rate', Icons.air),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Breaths per minute',
                      suffixText: '/min',
                      border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                    ),
                    onChanged: (val) {
                      final rr = int.tryParse(val);
                      setState(() => _respiratoryRate = rr);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    // Quick simulated 60-second counter prompt
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Count chest rises over 60 seconds using phone timer')),
                    );
                  },
                  icon: const Icon(Icons.timer),
                  label: const Text('Timer (60s)'),
                ),
              ],
            ),
          ),
          CheckboxListTile(
            title: const Text('Chest Indrawing Present (Danger Sign)'),
            value: _chestIndrawing,
            onChanged: (v) => setState(() => _chestIndrawing = v ?? false),
          ),
          CheckboxListTile(
            title: const Text('Grunting Present (Danger Sign)'),
            value: _grunting,
            onChanged: (v) => setState(() => _grunting = v ?? false),
          ),

          const Divider(),

          // ── 5. Umbilical Cord Examination ─────────────────────────────────
          _buildSectionHeader('5. Umbilical Cord Examination', Icons.healing),
          for (final c in CordStatus.values)
            RadioListTile<CordStatus>(
              title: Text(c.label, style: TextStyle(color: c.isDangerSign ? Colors.red.shade900 : null)),
              value: c,
              groupValue: _cordStatus,
              onChanged: (v) => setState(() => _cordStatus = v!),
            ),

          const Divider(),

          // ── 6. Skin & Jaundice ────────────────────────────────────────────
          _buildSectionHeader('6. Skin & Jaundice Examination', Icons.visibility),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Skin Pustules / Condition:', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final s in SkinStatus.values)
            RadioListTile<SkinStatus>(
              title: Text(s.label, style: TextStyle(color: s.isDangerSign ? Colors.red.shade900 : null)),
              value: s,
              groupValue: _skinStatus,
              onChanged: (v) => setState(() => _skinStatus = v!),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Jaundice Severity:', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final j in JaundiceStatus.values)
            RadioListTile<JaundiceStatus>(
              title: Text(j.label, style: TextStyle(color: j.isDangerSign ? Colors.red.shade900 : null)),
              value: j,
              groupValue: _jaundiceStatus,
              onChanged: (v) => setState(() => _jaundiceStatus = v!),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text('Eye Condition:', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final e in EyeStatus.values)
            RadioListTile<EyeStatus>(
              title: Text(e.label, style: TextStyle(color: e.isDangerSign ? Colors.red.shade900 : null)),
              value: e,
              groupValue: _eyeStatus,
              onChanged: (v) => setState(() => _eyeStatus = v!),
            ),

          const Divider(),

          // ── 7. Activity & Alertness ───────────────────────────────────────
          _buildSectionHeader('7. Activity, Tone & Consciousness', Icons.psychology),
          for (final a in ActivityStatus.values)
            RadioListTile<ActivityStatus>(
              title: Text(a.label, style: TextStyle(color: a.isDangerSign ? Colors.red.shade900 : null)),
              value: a,
              groupValue: _activityStatus,
              onChanged: (v) => setState(() => _activityStatus = v!),
            ),

          const Divider(),

          // ── 8. Thermal Care & KMC ─────────────────────────────────────────
          _buildSectionHeader('8. Thermal Care & Warm Chain', Icons.shield),
          CheckboxListTile(
            title: const Text('Delayed Bathing Practiced (Warmth Preserved)'),
            value: _delayedBathing,
            onChanged: (v) => setState(() => _delayedBathing = v ?? true),
          ),
          CheckboxListTile(
            title: const Text('Baby Wrapped warmly with Cap and Socks'),
            value: _warmChain,
            onChanged: (v) => setState(() => _warmChain = v ?? true),
          ),
          CheckboxListTile(
            title: const Text('Kangaroo Mother Care (KMC) Provided Daily'),
            value: _kmcPracticed,
            onChanged: (v) => setState(() => _kmcPracticed = v ?? false),
          ),
          if (_kmcPracticed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'KMC Duration in Hours / Day',
                  suffixText: 'hours',
                  border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                ),
                onChanged: (v) => setState(() => _kmcHours = double.tryParse(v)),
              ),
            ),

          const Divider(),

          // ── 9. Maternal Postpartum Health (PNC) ───────────────────────────
          _buildSectionHeader('9. Maternal Postpartum Assessment', Icons.pregnant_woman),
          for (final b in MaternalBleedingStatus.values)
            RadioListTile<MaternalBleedingStatus>(
              title: Text(b.label, style: TextStyle(color: b.isDangerSign ? Colors.red.shade900 : null)),
              value: b,
              groupValue: _maternalBleeding,
              onChanged: (v) => setState(() => _maternalBleeding = v!),
            ),
          CheckboxListTile(
            title: const Text('Mother has Postpartum High Fever (Danger Sign)'),
            value: _maternalFever,
            onChanged: (v) => setState(() => _maternalFever = v ?? false),
          ),
          CheckboxListTile(
            title: const Text('Mother has Severe Headache / Blurred Vision (Danger Sign)'),
            value: _maternalSevereHeadache,
            onChanged: (v) => setState(() => _maternalSevereHeadache = v ?? false),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: DropdownButtonFormField<String>(
              initialValue: _maternalWound,
              decoration: const InputDecoration(
                labelText: 'Maternal Wound / Episiotomy Healing',
                border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
              ),
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('Normal Healing — Clean, No Infection')),
                DropdownMenuItem(value: 'infected', child: Text('Infected / Pus Discharge (Danger Sign)')),
                DropdownMenuItem(value: 'dehiscence', child: Text('Wound Breakdown / Gaping (Danger Sign)')),
              ],
              onChanged: (val) => setState(() => _maternalWound = val ?? 'normal'),
            ),
          ),

          const SizedBox(height: 24),

          // ── Submit / Save Visit Button ────────────────────────────────────
          ElevatedButton(
            key: const Key('submit_hbnc_visit_button'),
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
                    hasDangers ? 'Record Danger Signs & Proceed to Referral' : 'Complete & Save HBNC Visit',
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
