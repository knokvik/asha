import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/voice/tts_service.dart';
import '../../../referral/presentation/referral_slip_screen.dart';
import '../data/hbyc_repository.dart';
import '../domain/hbyc_models.dart';
import '../domain/hbyc_storyboards.dart';

/// Interactive guided checklist screen for Home Based Care for Young Child (HBYC) visits.
///
/// Implements Requirements 13.1 – 13.5:
/// - Full clinical checklist: feeding, growth, immunization, milestones, illnesses, responsive caregiving
/// - Severe Acute Malnutrition (SAM) detection -> auto-triggers nutrition pathway / RED referral
/// - Developmental milestone delay evaluation -> pre-populates RBSK/DEIC referral
/// - Pictorial storyboard cards & audio caregiver messages in Hindi / English
class HbycVisitScreen extends ConsumerStatefulWidget {
  final String childId;
  final String childName;
  final DateTime childDob;
  final String visitScheduleId;
  final HbycMilestone milestone;
  final String? ashaId;

  const HbycVisitScreen({
    super.key,
    required this.childId,
    required this.childName,
    required this.childDob,
    required this.visitScheduleId,
    required this.milestone,
    this.ashaId,
  });

  @override
  ConsumerState<HbycVisitScreen> createState() => _HbycVisitScreenState();
}

class _HbycVisitScreenState extends ConsumerState<HbycVisitScreen> {
  // ── Growth & Nutrition State ───────────────────────────────────────────────
  double? _weightKg;
  double? _lengthCm;
  double? _muacCm;
  bool _hasBilateralOedema = false;
  bool _hasSevereWasting = false;
  bool _appetiteTestPassed = true;

  // ── Feeding Practices State ────────────────────────────────────────────────
  late FeedingPractice _feedingPractice;
  bool _complementaryFeedingStarted = false;
  int _mealsPerDay = 2;
  final Set<int> _selectedFoodGroups = {0, 1}; // default grains + dal
  bool _washedHandsBeforeFeeding = true;

  // ── Immunization State ─────────────────────────────────────────────────────
  bool _immunizationUpToDate = true;
  final TextEditingController _missingVaccinesController = TextEditingController();

  // ── Developmental Milestones State ─────────────────────────────────────────
  final Map<String, bool> _milestoneAchievements = {};

  // ── Illness Interval State ─────────────────────────────────────────────────
  bool _hadDiarrhoea = false;
  int _diarrhoeaDays = 0;
  bool _bloodInStool = false;
  bool _hadCoughFastBreathing = false;
  bool _hadFever = false;
  int _feverDays = 0;
  bool _hadConvulsions = false;
  bool _isLethargic = false;

  // ── Counselling State ──────────────────────────────────────────────────────
  bool _responsiveCaregivingCounseled = true;
  bool _hygieneWashCounseled = true;
  bool _storyboardShown = true;
  bool _audioMessagePlayed = false;
  bool _isPlayingAudio = false;
  TtsService? _ttsService;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Default feeding practice based on age
    if (widget.milestone == HbycMilestone.month3) {
      _feedingPractice = FeedingPractice.exclusiveBreastfeeding;
      _complementaryFeedingStarted = false;
    } else {
      _feedingPractice = FeedingPractice.complementaryWithBf;
      _complementaryFeedingStarted = true;
    }

    // Initialize all milestones for this age to true by default
    final items = HbycMilestonesCatalog.forMilestone(widget.milestone);
    for (final item in items) {
      _milestoneAchievements[item.id] = true;
    }

    _ttsService = TtsService();
  }

  @override
  void dispose() {
    _missingVaccinesController.dispose();
    _ttsService?.stop();
    super.dispose();
  }

  HbycChecklistData _buildChecklist() {
    return HbycChecklistData(
      milestone: widget.milestone,
      feedingPractice: _feedingPractice,
      complementaryFeedingStarted: _complementaryFeedingStarted,
      mealsPerDay: _mealsPerDay,
      foodGroupsCount: _selectedFoodGroups.length,
      washedHandsBeforeFeeding: _washedHandsBeforeFeeding,
      immunizationUpToDate: _immunizationUpToDate,
      missingVaccinesNotes: _missingVaccinesController.text.trim().isEmpty
          ? null
          : _missingVaccinesController.text.trim(),
      growth: HbycGrowthData(
        weightKg: _weightKg ?? 5.0,
        lengthCm: _lengthCm,
        muacCm: _muacCm,
        hasBilateralOedema: _hasBilateralOedema,
        hasSevereWasting: _hasSevereWasting,
        appetiteTestPassed: _appetiteTestPassed,
      ),
      milestoneAchievements: Map.from(_milestoneAchievements),
      illness: HbycIllnessInterval(
        hadDiarrhoea: _hadDiarrhoea,
        diarrhoeaDays: _diarrhoeaDays > 0 ? _diarrhoeaDays : null,
        bloodInStool: _bloodInStool,
        hadCoughFastBreathing: _hadCoughFastBreathing,
        hadFever: _hadFever,
        feverDays: _feverDays > 0 ? _feverDays : null,
        hadConvulsions: _hadConvulsions,
        isLethargicOrUnconscious: _isLethargic,
      ),
      responsiveCaregivingCounseled: _responsiveCaregivingCounseled,
      hygieneWashCounseled: _hygieneWashCounseled,
      storyboardShown: _storyboardShown,
      audioMessagePlayed: _audioMessagePlayed,
    );
  }

  Future<void> _playCounsellingAudio(HbycStoryboardCard card, {bool inHindi = true}) async {
    if (_ttsService == null) return;
    setState(() => _isPlayingAudio = true);

    try {
      final script = inHindi ? card.audioScriptHi : card.audioScriptEn;
      final lang = inHindi ? 'hi-IN' : 'en-IN';
      await _ttsService!.speak(text: script, language: lang);
      if (mounted) {
        setState(() {
          _audioMessagePlayed = true;
          _isPlayingAudio = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isPlayingAudio = false);
    }
  }

  Future<void> _submitVisit() async {
    if (_weightKg == null || _weightKg! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record valid weight in kg before saving')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final checklist = _buildChecklist();
      final repo = ref.read(hbycRepositoryProvider);

      final result = await repo.recordVisit(
        childId: widget.childId,
        visitScheduleId: widget.visitScheduleId,
        checklist: checklist,
        ashaId: widget.ashaId ?? 'asha_local',
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (result.isRedFlag) {
        // Requirement 13.4: SAM or Danger Sign -> Navigate directly to Referral Slip
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReferralSlipScreen(
              memberId: widget.childId,
              triageResult: result.triageResult,
              rawVitals: {
                'weight': '${checklist.growth.weightKg} kg',
                if (checklist.growth.lengthCm != null) 'length': '${checklist.growth.lengthCm} cm',
                if (checklist.growth.muacCm != null) 'muac': '${checklist.growth.muacCm} cm',
              },
            ),
          ),
        );
      } else if (result.hasMilestoneDelay) {
        // Requirement 13.3: Show dialog suggesting RBSK/DEIC referral with pre-populated note
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.psychology, color: Colors.orange.shade800),
                const SizedBox(width: 8),
                const Text('Developmental Delay'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'One or more developmental milestones were delayed. Referral to RBSK / DEIC or Anganwadi is recommended.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Delayed Milestones:\n${result.delayedMilestoneNames.map((e) => '• $e').join('\n')}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context, true);
                },
                child: const Text('Save & Close'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade800,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReferralSlipScreen(
                        memberId: widget.childId,
                        triageResult: result.triageResult,
                        rawVitals: {
                          'weight': '${checklist.growth.weightKg} kg',
                          'milestones_delayed': '${result.delayedMilestoneNames.length}',
                        },
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Create RBSK Referral Slip'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('HBYC Visit successfully completed! Incentive event recorded.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving HBYC visit: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final checklist = _buildChecklist();
    final isSam = checklist.isSam;
    final isMam = checklist.isMam;
    final hasMilestoneDelay = checklist.hasMilestoneDelay;
    final delayedMilestones = checklist.delayedMilestones;
    final storyboardCard = HbycStoryboardsCatalog.forMilestone(widget.milestone);

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.milestone.visitTitle,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(
              widget.childName,
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
          // ── SAM Alert Banner (Requirement 13.4) ───────────────────────────
          if (isSam)
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
                            'SEVERE ACUTE MALNUTRITION (SAM) DETECTED',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• MUAC < 11.5 cm or Bilateral Pitting Oedema observed.\n'
                      '• Auto-triggers Nutrition Pathway: immediate referral to Nutritional Rehabilitation Centre (NRC) or First Referral Unit (FRU).',
                      style: TextStyle(color: Colors.red.shade900, fontSize: 13, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),

          // ── Developmental Delay Alert (Requirement 13.3) ───────────────────
          if (!isSam && hasMilestoneDelay)
            Card(
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.orange.shade700, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.orange.shade800, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Developmental Delay Identified (${delayedMilestones.length} milestone(s) not met)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pre-populated referral to RBSK / DEIC or Anganwadi Centre will be prepared upon submission.',
                            style: TextStyle(color: Colors.orange.shade900, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── SECTION 1: Growth Measurements & Malnutrition ──────────────────
          _buildSectionHeader('1. Growth & Malnutrition Screening', Icons.monitor_weight),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('hbyc_weight_field'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Weight (kg) *',
                      suffixText: 'kg',
                      border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                    ),
                    onChanged: (val) {
                      final w = double.tryParse(val);
                      setState(() => _weightKg = w);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: const Key('hbyc_length_field'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Length/Height (cm)',
                      suffixText: 'cm',
                      border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                    ),
                    onChanged: (val) {
                      final l = double.tryParse(val);
                      setState(() => _lengthCm = l);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // MUAC tape measurement (for children >= 6 months)
          if (widget.milestone.ageInDays >= 180) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                key: const Key('hbyc_muac_field'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Mid-Upper Arm Circumference (MUAC in cm)',
                  helperText: '< 11.5 cm = SAM (RED) | 11.5–12.4 cm = MAM (YELLOW) | >= 12.5 cm = Normal',
                  suffixText: 'cm',
                  border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                  filled: true,
                  fillColor: isSam
                      ? Colors.red.shade50
                      : (isMam ? Colors.yellow.shade50 : Colors.green.shade50),
                ),
                onChanged: (val) {
                  final m = double.tryParse(val);
                  setState(() => _muacCm = m);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Bilateral Pitting Oedema Check
          SwitchListTile(
            title: const Text('Bilateral Pitting Oedema (+, ++, +++)'),
            subtitle: const Text('Press both feet firmly for 3 seconds; check for persistent pits'),
            value: _hasBilateralOedema,
            onChanged: (val) => setState(() => _hasBilateralOedema = val),
          ),

          // Severe Visible Wasting Check
          SwitchListTile(
            title: const Text('Severe Visible Wasting (Baggy pants sign / rib cage prominence)'),
            value: _hasSevereWasting,
            onChanged: (val) => setState(() => _hasSevereWasting = val),
          ),

          // Appetite Test Passed Check
          SwitchListTile(
            title: const Text('Appetite test passed / Able to eat home porridge or RUTF'),
            value: _appetiteTestPassed,
            onChanged: (val) => setState(() => _appetiteTestPassed = val),
          ),

          const Divider(),

          // ── SECTION 2: Feeding Practices & Complementary Feeding ───────────
          _buildSectionHeader('2. Feeding & Complementary Nutrition', Icons.restaurant),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButtonFormField<FeedingPractice>(
              initialValue: _feedingPractice,
              decoration: const InputDecoration(
                labelText: 'Current Feeding Practice',
                border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
              ),
              items: FeedingPractice.values.map((f) {
                return DropdownMenuItem(value: f, child: Text(f.label));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _feedingPractice = val);
              },
            ),
          ),

          if (widget.milestone.ageInDays >= 180) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _mealsPerDay,
                      decoration: const InputDecoration(
                        labelText: 'Meals per day',
                        border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 time / day (Too low)')),
                        DropdownMenuItem(value: 2, child: Text('2 times / day')),
                        DropdownMenuItem(value: 3, child: Text('3 times / day (Recommended)')),
                        DropdownMenuItem(value: 4, child: Text('4+ times / day')),
                      ],
                      onChanged: (val) => setState(() => _mealsPerDay = val ?? 2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Dietary Diversity (Minimum 4 of 7 food groups recommended):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _foodGroupChip(0, 'Grains/Cereals'),
                  _foodGroupChip(1, 'Pulses/Dal/Nuts'),
                  _foodGroupChip(2, 'Dairy/Milk/Curd'),
                  _foodGroupChip(3, 'Eggs'),
                  _foodGroupChip(4, 'Flesh Foods'),
                  _foodGroupChip(5, 'Vit-A Fruits/Greens'),
                  _foodGroupChip(6, 'Other Fruits/Veg'),
                ],
              ),
            ),
            SwitchListTile(
              title: const Text('Caregiver washes hands with soap before feeding'),
              value: _washedHandsBeforeFeeding,
              onChanged: (val) => setState(() => _washedHandsBeforeFeeding = val),
            ),
          ],

          const Divider(),

          // ── SECTION 3: Immunization Check ─────────────────────────────────
          _buildSectionHeader('3. Immunization Verification', Icons.vaccines),
          SwitchListTile(
            title: Text('All vaccines due for ${widget.milestone.label} are administered'),
            subtitle: const Text('Cross-verify with MCP Card / U-WIN portal'),
            value: _immunizationUpToDate,
            onChanged: (val) => setState(() => _immunizationUpToDate = val),
          ),
          if (!_immunizationUpToDate)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextFormField(
                controller: _missingVaccinesController,
                decoration: const InputDecoration(
                  labelText: 'List missing vaccines or reason for delay',
                  border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                ),
              ),
            ),

          const Divider(),

          // ── SECTION 4: Developmental Milestones ─────────────────────────────
          _buildSectionHeader(
            '4. Developmental Milestones for ${widget.milestone.label}',
            Icons.child_care,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Ask mother/observe child. Check each milestone achieved:',
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ),
          ...HbycMilestonesCatalog.forMilestone(widget.milestone).map((item) {
            final isAchieved = _milestoneAchievements[item.id] ?? false;
            return CheckboxListTile(
              key: Key('milestone_${item.id}'),
              title: Text(item.prompt, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${item.promptHi} • [${item.domain}]',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
              ),
              value: isAchieved,
              onChanged: (val) {
                setState(() => _milestoneAchievements[item.id] = val ?? false);
              },
            );
          }),

          const Divider(),

          // ── SECTION 5: Illness in Interval ─────────────────────────────────
          _buildSectionHeader('5. Illness in Previous Interval', Icons.sick),
          SwitchListTile(
            title: const Text('Diarrhoea in the past 2 weeks'),
            value: _hadDiarrhoea,
            onChanged: (val) => setState(() => _hadDiarrhoea = val),
          ),
          if (_hadDiarrhoea) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration in days',
                        border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                      ),
                      onChanged: (v) => setState(() => _diarrhoeaDays = int.tryParse(v) ?? 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('Blood in stool'),
                      value: _bloodInStool,
                      onChanged: (v) => setState(() => _bloodInStool = v ?? false),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SwitchListTile(
            title: const Text('Cough or fast breathing in past 2 weeks'),
            value: _hadCoughFastBreathing,
            onChanged: (val) => setState(() => _hadCoughFastBreathing = val),
          ),
          SwitchListTile(
            title: const Text('Fever in past 2 weeks'),
            value: _hadFever,
            onChanged: (val) => setState(() => _hadFever = val),
          ),
          if (_hadFever)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Fever duration in days',
                  border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius, borderSide: BorderSide(color: AshaColors.borderSubtle)),
                ),
                onChanged: (v) => setState(() => _feverDays = int.tryParse(v) ?? 0),
              ),
            ),
          SwitchListTile(
            title: const Text('Convulsions / Fits / Abnormal movements (DANGER SIGN)'),
            value: _hadConvulsions,
            onChanged: (val) => setState(() => _hadConvulsions = val),
          ),
          SwitchListTile(
            title: const Text('Child is unusually lethargic or unconscious (DANGER SIGN)'),
            value: _isLethargic,
            onChanged: (val) => setState(() => _isLethargic = val),
          ),

          const Divider(),

          // ── SECTION 6: Pictorial Storyboard & Caregiver Counselling ─────────
          _buildSectionHeader('6. Caregiver Counselling & Storyboard', Icons.auto_stories),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette, color: AshaColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          storyboardCard.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    storyboardCard.titleHi,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.image_outlined, size: 24, color: Colors.blueGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Illustration: ${storyboardCard.visualDescription}',
                            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...storyboardCard.bulletTipsHi.map(
                    (tip) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(child: Text(tip, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        key: const Key('play_audio_counselling_hi_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AshaColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isPlayingAudio
                            ? null
                            : () => _playCounsellingAudio(storyboardCard, inHindi: true),
                        icon: Icon(_isPlayingAudio ? Icons.volume_up : Icons.play_arrow),
                        label: Text(_isPlayingAudio ? 'Playing...' : 'Play Audio (हिंदी)'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isPlayingAudio
                            ? null
                            : () => _playCounsellingAudio(storyboardCard, inHindi: false),
                        icon: const Icon(Icons.volume_down),
                        label: const Text('English'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SwitchListTile(
            title: const Text('Caregiver counselled on responsive play & communication'),
            value: _responsiveCaregivingCounseled,
            onChanged: (val) => setState(() => _responsiveCaregivingCounseled = val),
          ),
          SwitchListTile(
            title: const Text('WASH & handwashing practices counselled'),
            value: _hygieneWashCounseled,
            onChanged: (val) => setState(() => _hygieneWashCounseled = val),
          ),
          SwitchListTile(
            title: const Text('Pictorial storyboard shown and explained to family'),
            value: _storyboardShown,
            onChanged: (val) => setState(() => _storyboardShown = val),
          ),

          const SizedBox(height: 20),

          // ── Submit HBYC Visit Button ───────────────────────────────────────
          ElevatedButton(
            key: const Key('submit_hbyc_visit_button'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isSam
                  ? Colors.red.shade800
                  : (hasMilestoneDelay ? Colors.orange.shade800 : AshaColors.primary),
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
                    isSam
                        ? 'Record SAM Alert & Proceed to NRC Referral'
                        : (hasMilestoneDelay
                            ? 'Complete Visit & Review RBSK Referral'
                            : 'Save & Complete HBYC Visit'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _foodGroupChip(int index, String label) {
    final selected = _selectedFoodGroups.contains(index);
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (val) {
        setState(() {
          if (val) {
            _selectedFoodGroups.add(index);
          } else {
            _selectedFoodGroups.remove(index);
          }
        });
      },
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
