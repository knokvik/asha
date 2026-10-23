// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../referral/presentation/referral_slip_screen.dart';
import '../data/hbnc_repository.dart';
import '../domain/hbnc_models.dart';
import '../domain/kmc_guidance.dart';
import '../../presentation/clinical_card_helpers.dart';

/// Screen presenting the guided Home Based Newborn Care (HBNC) visit checklist.
class HbncVisitScreen extends ConsumerStatefulWidget {
  final String newbornId;
  final String? newbornName;
  final String motherId;
  final String visitScheduleId;
  final String visitTitle;
  final int visitDay;
  final double birthWeightKg;
  final bool isPreterm;
  final String? ashaId;

  const HbncVisitScreen({
    super.key,
    required this.newbornId,
    this.newbornName,
    required this.motherId,
    required this.visitScheduleId,
    this.visitTitle = 'HBNC Day 7 Newborn Visit',
    this.visitDay = 7,
    this.birthWeightKg = 2.8,
    this.isPreterm = false,
    this.ashaId,
  });

  @override
  ConsumerState<HbncVisitScreen> createState() => _HbncVisitScreenState();
}

class _HbncVisitScreenState extends ConsumerState<HbncVisitScreen> {
  double? _currentWeightKg;
  double? _temperatureC = 36.8;
  int? _respiratoryRate = 42;
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
                  ? 'HBNC Episode Complete! Incentive registered.'
                  : 'HBNC Visit successfully saved.',
            ),
            backgroundColor: AshaColors.primary,
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
        title: Text(
          widget.visitTitle,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildVisitSummaryCard(),
          const SizedBox(height: 12),

          // Danger Signs Banner
          if (hasDangers)
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
                          'Newborn / Maternal Danger Detected',
                          style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (final sign in [...dangerSigns, ...maternalDangers])
                    Text('• $sign', style: TextStyle(color: Colors.red.shade900, fontSize: 12.5)),
                  const SizedBox(height: 6),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _submitVisit,
                    icon: const Icon(Icons.emergency, size: 18),
                    label: const Text('Open Referral Slip (108)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          if (_isHighRisk)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: ExpansionTile(
                initiallyExpanded: _showKmcDetails,
                onExpansionChanged: (v) => setState(() => _showKmcDetails = v),
                leading: Icon(Icons.favorite, color: Colors.amber.shade900),
                title: Text(
                  'High-risk newborn · ${widget.birthWeightKg.toStringAsFixed(1)} kg',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.amber.shade900),
                ),
                subtitle: const Text('KMC guidance active', style: TextStyle(fontSize: 12)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final step in KmcGuidance.coreSteps)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text('• $step', style: const TextStyle(fontSize: 12)),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Target: ≥ ${KmcGuidance.recommendedTargetHours(widget.birthWeightKg)} hrs/day',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── SECTION 1: Vitals & Weight ──
          ClinicalFormCard(
            title: '1. Newborn Measurements',
            icon: Icons.monitor_weight_outlined,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: _currentWeightKg?.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Current Weight',
                          suffixText: 'kg',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (v) => setState(() => _currentWeightKg = double.tryParse(v)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _temperatureC?.toString(),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Temp',
                          suffixText: '°C',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (v) => setState(() => _temperatureC = double.tryParse(v)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _respiratoryRate?.toString(),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Breathing',
                          suffixText: '/min',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (v) => setState(() => _respiratoryRate = int.tryParse(v)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClinicalSwitchTile(
                  title: 'Chest In-drawing Present',
                  value: _chestIndrawing,
                  onChanged: (v) => setState(() => _chestIndrawing = v),
                  isDanger: true,
                ),
                ClinicalSwitchTile(
                  title: 'Grunting Sound on Expiration',
                  value: _grunting,
                  onChanged: (v) => setState(() => _grunting = v),
                  isDanger: true,
                ),
              ],
            ),
          ),

          // ── SECTION 2: Feeding & Clinical Status ──
          ClinicalFormCard(
            title: '2. Feeding & Clinical Checks',
            icon: Icons.baby_changing_station_outlined,
            child: Column(
              children: [
                DropdownButtonFormField<FeedingStatus>(
                  initialValue: _feedingStatus,
                  decoration: InputDecoration(
                    labelText: 'Breastfeeding Status',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: FeedingStatus.values.map((f) => DropdownMenuItem(value: f, child: Text(f.label))).toList(),
                  onChanged: (v) => setState(() => _feedingStatus = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<CordStatus>(
                  initialValue: _cordStatus,
                  decoration: InputDecoration(
                    labelText: 'Umbilical Cord',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: CordStatus.values.map((c) => DropdownMenuItem(value: c, child: Text(c.label))).toList(),
                  onChanged: (v) => setState(() => _cordStatus = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<JaundiceStatus>(
                  initialValue: _jaundiceStatus,
                  decoration: InputDecoration(
                    labelText: 'Jaundice / Yellowness',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: JaundiceStatus.values.map((j) => DropdownMenuItem(value: j, child: Text(j.label))).toList(),
                  onChanged: (v) => setState(() => _jaundiceStatus = v!),
                ),
              ],
            ),
          ),

          // ── SECTION 3: Thermal Care & KMC ──
          ClinicalFormCard(
            title: '3. Warmth & Kangaroo Care',
            icon: Icons.thermostat,
            child: Column(
              children: [
                ClinicalSwitchTile(
                  title: 'Kept Warm in Warm Chain (Clothing & Hat)',
                  value: _warmChain,
                  onChanged: (v) => setState(() => _warmChain = v),
                ),
                ClinicalSwitchTile(
                  title: 'Delayed Bathing Practiced',
                  value: _delayedBathing,
                  onChanged: (v) => setState(() => _delayedBathing = v),
                ),
                ClinicalSwitchTile(
                  title: 'Kangaroo Mother Care Practiced Today',
                  value: _kmcPracticed,
                  onChanged: (v) => setState(() => _kmcPracticed = v),
                ),
                if (_kmcPracticed) ...[
                  const SizedBox(height: 6),
                  TextFormField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Hours of KMC Per Day',
                      suffixText: 'hours',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setState(() => _kmcHours = double.tryParse(v)),
                  ),
                ],
              ],
            ),
          ),

          // ── SECTION 4: Maternal Health ──
          ClinicalFormCard(
            title: '4. Mother Status in HBNC',
            icon: Icons.favorite_border,
            child: Column(
              children: [
                DropdownButtonFormField<MaternalBleedingStatus>(
                  initialValue: _maternalBleeding,
                  decoration: InputDecoration(
                    labelText: 'Maternal Bleeding',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: MaternalBleedingStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                  onChanged: (v) => setState(() => _maternalBleeding = v!),
                ),
                const SizedBox(height: 10),
                ClinicalSwitchTile(
                  title: 'Maternal High Fever with Chills',
                  value: _maternalFever,
                  onChanged: (v) => setState(() => _maternalFever = v),
                  isDanger: true,
                ),
                ClinicalSwitchTile(
                  title: 'Maternal Severe Headache',
                  value: _maternalSevereHeadache,
                  onChanged: (v) => setState(() => _maternalSevereHeadache = v),
                  isDanger: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          ClinicalSubmitButton(
            label: hasDangers ? 'Danger Sign: Open Referral Slip' : 'Save HBNC Visit',
            isSaving: _isSaving,
            isEmergency: hasDangers,
            onPressed: _submitVisit,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildVisitSummaryCard() {
    final displayName = widget.newbornName?.trim().isNotEmpty == true
        ? widget.newbornName!
        : 'Newborn Beneficiary';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AshaColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AshaColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.child_care, color: AshaColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Birth Weight: ${widget.birthWeightKg} kg · Day ${widget.visitDay}', style: const TextStyle(fontSize: 12, color: AshaColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
