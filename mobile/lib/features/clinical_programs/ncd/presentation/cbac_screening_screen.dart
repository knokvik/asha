import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/triage/models/models.dart';
import '../data/ncd_repository.dart';
import '../domain/cbac_calculator.dart';
import '../domain/cbac_models.dart';
import '../../presentation/clinical_form_feedback.dart';

/// Screen guiding ASHA through the official Community Based Assessment Checklist (CBAC)
/// for adults >= 30 years, evaluating risk score offline, checking cancer warning signs,
/// classifying BP & glucose, providing lifestyle counselling, and generating referrals.
///
/// Implements Requirements 19.1 – 19.3, 19.7.
class CbacScreeningScreen extends ConsumerStatefulWidget {
  final String memberId;
  final String beneficiaryName;
  final int ageYears;
  final String sex; // 'M' or 'F'
  final String ashaId;

  const CbacScreeningScreen({
    super.key,
    required this.memberId,
    required this.beneficiaryName,
    required this.ageYears,
    required this.sex,
    required this.ashaId,
  });

  @override
  ConsumerState<CbacScreeningScreen> createState() =>
      _CbacScreeningScreenState();
}

class _CbacScreeningScreenState extends ConsumerState<CbacScreeningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Part A: Risk Assessment Fields ──────────────────────────────────────────
  late TobaccoUse _tobaccoUse;
  late AlcoholConsumption _alcoholConsumption;
  late PhysicalActivity _physicalActivity;
  late FamilyHistoryNcd _familyHistory;
  final _waistController = TextEditingController(text: '82');

  // ── Part B: Cancer & Warning Signs ──────────────────────────────────────────
  bool _oralUlcer = false;
  bool _oralPatch = false;
  bool _oralDifficulty = false;
  bool _oralGrowth = false;

  bool _breastLump = false;
  bool _breastDischarge = false;
  bool _breastShape = false;
  bool _breastDimpling = false;

  bool _cervicalIntermenstrual = false;
  bool _cervicalPostcoital = false;
  bool _cervicalPostmenopausal = false;
  bool _cervicalFoulDischarge = false;

  bool _persistentCough = false;
  bool _chronicShortnessOfBreath = false;
  bool _bloodInSputum = false;
  bool _bloodInStoolOrUrine = false;
  bool _historyOfFits = false;

  // ── Part C: Direct Clinical Measurements ────────────────────────────────────
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _glucoseController = TextEditingController();
  GlucoseType _glucoseType = GlucoseType.random;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tobaccoUse = TobaccoUse.never;
    _alcoholConsumption = AlcoholConsumption.no;
    _physicalActivity = PhysicalActivity.atLeast150Mins;
    _familyHistory = FamilyHistoryNcd.no;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _waistController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _glucoseController.dispose();
    super.dispose();
  }

  double get _currentWaist =>
      double.tryParse(_waistController.text.trim()) ?? 80.0;
  int? get _currentSystolic => int.tryParse(_systolicController.text.trim());
  int? get _currentDiastolic => int.tryParse(_diastolicController.text.trim());
  double? get _currentGlucose =>
      double.tryParse(_glucoseController.text.trim());

  int get _liveCbacScore {
    return CbacCalculator.computeTotalCbacScore(
      ageYears: widget.ageYears,
      tobaccoUse: _tobaccoUse,
      alcoholConsumption: _alcoholConsumption,
      waistCircumferenceCm: _currentWaist,
      sex: widget.sex,
      physicalActivity: _physicalActivity,
      familyHistory: _familyHistory,
    );
  }

  bool get _isScoreHighRisk => _liveCbacScore > 4;

  CancerWarningSigns get _warningSigns => CancerWarningSigns(
    oralUlcerGt2Weeks: _oralUlcer,
    oralRedWhitePatch: _oralPatch,
    oralDifficultyChewingOpeningMouth: _oralDifficulty,
    oralUnexplainedGrowth: _oralGrowth,
    breastLump: _breastLump,
    breastBloodStainedDischarge: _breastDischarge,
    breastShapeChange: _breastShape,
    breastSkinDimpling: _breastDimpling,
    cervicalBleedingBetweenPeriods: _cervicalIntermenstrual,
    cervicalPostCoitalBleeding: _cervicalPostcoital,
    cervicalPostMenopausalBleeding: _cervicalPostmenopausal,
    cervicalFoulDischarge: _cervicalFoulDischarge,
    persistentCoughGt2Weeks: _persistentCough,
    chronicShortnessOfBreath: _chronicShortnessOfBreath,
    bloodInSputum: _bloodInSputum,
    bloodInUrineOrStool: _bloodInStoolOrUrine,
    historyOfFitsOrFainting: _historyOfFits,
  );

  @override
  Widget build(BuildContext context) {
    final score = _liveCbacScore;
    final isFemale = widget.sex.toUpperCase() == 'F';

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NCD screening',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AshaColors.primary,
          unselectedLabelColor: AshaColors.textMuted,
          indicatorColor: AshaColors.primary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.assessment), text: 'Part A: Risk'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Part B: Cancer Signs'),
            Tab(icon: Icon(Icons.favorite), text: 'Part C: BP & Sugar'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Lifestyle Counselling',
            icon: const Icon(
              Icons.health_and_safety,
              color: AshaColors.primary,
            ),
            onPressed: _showLifestyleCounsellingDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ClinicalPatientContextCard(
              name: widget.beneficiaryName,
              details: '${widget.ageYears} years · ${widget.sex}',
              contextLabel: 'CBAC risk assessment',
            ),
          ),
          // Live Score Badge Header
          _buildScoreBanner(score),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPartARiskTab(),
                _buildPartBCancerTab(isFemale),
                _buildPartCMeasurementsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isScoreHighRisk
                  ? const Color(0xFFD97706)
                  : AshaColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle_outline),
            label: Text(
              _isSaving
                  ? 'Evaluating & Saving...'
                  : 'Save CBAC & Evaluate Triage',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _isSaving ? null : _saveAndEvaluateCbac,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBanner(int score) {
    final isHigh = score > 4;
    return Container(
      color: isHigh ? Colors.amber.shade100 : Colors.teal.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isHigh
                ? Colors.amber.shade800
                : Colors.teal.shade700,
            child: Text(
              '$score',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHigh
                      ? 'CBAC Score: $score/10 (High Risk > 4)'
                      : 'CBAC Score: $score/10 (Normal / Low Risk)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHigh
                        ? Colors.amber.shade900
                        : Colors.teal.shade900,
                  ),
                ),
                Text(
                  isHigh
                      ? 'Refer to PHC / Ayushman Arogya Mandir for confirmation'
                      : 'Annual rescreening & lifestyle counselling recommended',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartARiskTab() {
    final ageBand = CbacAgeBand.fromAge(widget.ageYears);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Age Category (Auto-Calculated)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.ageYears} years: ${ageBand.label}',
                  style: TextStyle(color: Colors.teal.shade800),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2. Smoking & Tobacco Consumption',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...TobaccoUse.values.map(
                  (val) => RadioListTile<TobaccoUse>(
                    title: Text(val.label),
                    value: val,
                    groupValue: _tobaccoUse,
                    onChanged: (selected) {
                      if (selected != null)
                        setState(() => _tobaccoUse = selected);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '3. Alcohol Consumption',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...AlcoholConsumption.values.map(
                  (val) => RadioListTile<AlcoholConsumption>(
                    title: Text(val.label),
                    value: val,
                    groupValue: _alcoholConsumption,
                    onChanged: (selected) {
                      if (selected != null)
                        setState(() => _alcoholConsumption = selected);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '4. Waist Circumference (cm)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.sex == 'F'
                      ? 'Cutoff: <=80cm (0), 81-90cm (+1), >90cm (+2)'
                      : 'Cutoff: <=90cm (0), 91-100cm (+1), >100cm (+2)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _waistController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Waist Circumference',
                    suffixText: 'cm',
                    border: OutlineInputBorder(
                      borderRadius: AshaShapes.searchRadius,
                      borderSide: BorderSide(color: AshaColors.borderSubtle),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '5. Physical Activity (>= 150 mins / week)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...PhysicalActivity.values.map(
                  (val) => RadioListTile<PhysicalActivity>(
                    title: Text(val.label),
                    value: val,
                    groupValue: _physicalActivity,
                    onChanged: (selected) {
                      if (selected != null)
                        setState(() => _physicalActivity = selected);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '6. Family History (High BP, Diabetes, Heart Disease)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...FamilyHistoryNcd.values.map(
                  (val) => RadioListTile<FamilyHistoryNcd>(
                    title: Text(val.label),
                    value: val,
                    groupValue: _familyHistory,
                    onChanged: (selected) {
                      if (selected != null)
                        setState(() => _familyHistory = selected);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartBCancerTab(bool isFemale) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Part B: Early Warning Signs & Cancer Screening (Requirement 19.3)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Any positive symptom triggers referral for confirmatory cancer examination at PHC/CHC.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),

        // Oral Cancer
        Card(
          child: ExpansionTile(
            initiallyExpanded: true,
            leading: const Icon(Icons.face, color: Colors.deepOrange),
            title: const Text(
              'Oral Cancer Symptoms (Both Sexes)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              CheckboxListTile(
                title: const Text('Non-healing ulcer in mouth > 2 weeks'),
                value: _oralUlcer,
                onChanged: (v) => setState(() => _oralUlcer = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('White or red patch in mouth'),
                value: _oralPatch,
                onChanged: (v) => setState(() => _oralPatch = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Difficulty in opening mouth or chewing'),
                value: _oralDifficulty,
                onChanged: (v) => setState(() => _oralDifficulty = v ?? false),
              ),
              CheckboxListTile(
                title: const Text(
                  'Unexplained growth or swelling in mouth/neck',
                ),
                value: _oralGrowth,
                onChanged: (v) => setState(() => _oralGrowth = v ?? false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Breast Cancer (Women)
        if (isFemale)
          Card(
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.woman, color: Colors.pink),
              title: const Text(
                'Breast Cancer Symptoms (Women)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                CheckboxListTile(
                  title: const Text('Palpable lump in breast or armpit'),
                  value: _breastLump,
                  onChanged: (v) => setState(() => _breastLump = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Blood-stained or serous nipple discharge'),
                  value: _breastDischarge,
                  onChanged: (v) =>
                      setState(() => _breastDischarge = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text(
                    'Noticeable change in size or shape of breast',
                  ),
                  value: _breastShape,
                  onChanged: (v) => setState(() => _breastShape = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text(
                    'Skin dimpling, puckering or nipple retraction',
                  ),
                  value: _breastDimpling,
                  onChanged: (v) =>
                      setState(() => _breastDimpling = v ?? false),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),

        // Cervical Cancer (Women)
        if (isFemale)
          Card(
            child: ExpansionTile(
              initiallyExpanded: true,
              leading: const Icon(Icons.female, color: Colors.purple),
              title: const Text(
                'Cervical Cancer Symptoms (Women)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              children: [
                CheckboxListTile(
                  title: const Text(
                    'Bleeding between regular menstrual periods',
                  ),
                  value: _cervicalIntermenstrual,
                  onChanged: (v) =>
                      setState(() => _cervicalIntermenstrual = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Bleeding after intercourse (post-coital)'),
                  value: _cervicalPostcoital,
                  onChanged: (v) =>
                      setState(() => _cervicalPostcoital = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text('Bleeding after menopause'),
                  value: _cervicalPostmenopausal,
                  onChanged: (v) =>
                      setState(() => _cervicalPostmenopausal = v ?? false),
                ),
                CheckboxListTile(
                  title: const Text(
                    'Persistent foul-smelling vaginal discharge',
                  ),
                  value: _cervicalFoulDischarge,
                  onChanged: (v) =>
                      setState(() => _cervicalFoulDischarge = v ?? false),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),

        // Chronic Respiratory & Other Signs
        Card(
          child: ExpansionTile(
            leading: const Icon(
              Icons.medical_services_outlined,
              color: Colors.blueGrey,
            ),
            title: const Text(
              'Other Chronic Warning Signs',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            children: [
              CheckboxListTile(
                title: const Text(
                  'Persistent cough > 2 weeks (Presumptive TB)',
                ),
                value: _persistentCough,
                onChanged: (v) => setState(() => _persistentCough = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Blood in sputum (Haemoptysis) - URGENT'),
                value: _bloodInSputum,
                onChanged: (v) => setState(() => _bloodInSputum = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Chronic shortness of breath / wheezing'),
                value: _chronicShortnessOfBreath,
                onChanged: (v) =>
                    setState(() => _chronicShortnessOfBreath = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('Blood in urine or stool'),
                value: _bloodInStoolOrUrine,
                onChanged: (v) =>
                    setState(() => _bloodInStoolOrUrine = v ?? false),
              ),
              CheckboxListTile(
                title: const Text('History of seizures / fainting spells'),
                value: _historyOfFits,
                onChanged: (v) => setState(() => _historyOfFits = v ?? false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartCMeasurementsTab() {
    BloodPressureCategory? bpCat;
    if (_currentSystolic != null && _currentDiastolic != null) {
      bpCat = CbacCalculator.classifyBloodPressure(
        systolic: _currentSystolic!,
        diastolic: _currentDiastolic!,
      );
    }

    BloodGlucoseCategory? glucCat;
    if (_currentGlucose != null) {
      glucCat = CbacCalculator.classifyBloodGlucose(
        glucoseMgDl: _currentGlucose!,
        type: _glucoseType,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Part C: Blood Pressure & Blood Glucose (Requirement 19.2)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),

        // BP Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.monitor_heart, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Blood Pressure (mmHg)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _systolicController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Systolic (SBP)',
                          hintText: 'e.g. 120',
                          border: OutlineInputBorder(
                            borderRadius: AshaShapes.searchRadius,
                            borderSide: BorderSide(
                              color: AshaColors.borderSubtle,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        '/',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _diastolicController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Diastolic (DBP)',
                          hintText: 'e.g. 80',
                          border: OutlineInputBorder(
                            borderRadius: AshaShapes.searchRadius,
                            borderSide: BorderSide(
                              color: AshaColors.borderSubtle,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                if (bpCat != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bpCat.triageFlag == TriageFlag.red
                          ? Colors.red.shade100
                          : (bpCat.triageFlag == TriageFlag.yellow
                                ? Colors.amber.shade100
                                : Colors.green.shade100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          bpCat.triageFlag == TriageFlag.red
                              ? Icons.error
                              : (bpCat.triageFlag == TriageFlag.yellow
                                    ? Icons.warning
                                    : Icons.check_circle),
                          color: bpCat.triageFlag == TriageFlag.red
                              ? Colors.red.shade900
                              : (bpCat.triageFlag == TriageFlag.yellow
                                    ? Colors.amber.shade900
                                    : Colors.green.shade900),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bpCat.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: bpCat.triageFlag == TriageFlag.red
                                  ? Colors.red.shade900
                                  : (bpCat.triageFlag == TriageFlag.yellow
                                        ? Colors.amber.shade900
                                        : Colors.green.shade900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Glucose Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.water_drop, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Blood Glucose (mg/dL)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<GlucoseType>(
                  initialValue: _glucoseType,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Test Type',
                    border: OutlineInputBorder(
                      borderRadius: AshaShapes.searchRadius,
                      borderSide: BorderSide(color: AshaColors.borderSubtle),
                    ),
                  ),
                  items: GlucoseType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _glucoseType = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _glucoseController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Blood Glucose Reading',
                    suffixText: 'mg/dL',
                    hintText: 'e.g. 110',
                    border: OutlineInputBorder(
                      borderRadius: AshaShapes.searchRadius,
                      borderSide: BorderSide(color: AshaColors.borderSubtle),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (glucCat != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: glucCat.triageFlag == TriageFlag.red
                          ? Colors.red.shade100
                          : (glucCat.triageFlag == TriageFlag.yellow
                                ? Colors.amber.shade100
                                : Colors.green.shade100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          glucCat.triageFlag == TriageFlag.red
                              ? Icons.error
                              : (glucCat.triageFlag == TriageFlag.yellow
                                    ? Icons.warning
                                    : Icons.check_circle),
                          color: glucCat.triageFlag == TriageFlag.red
                              ? Colors.red.shade900
                              : (glucCat.triageFlag == TriageFlag.yellow
                                    ? Colors.amber.shade900
                                    : Colors.green.shade900),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            glucCat.label,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: glucCat.triageFlag == TriageFlag.red
                                  ? Colors.red.shade900
                                  : (glucCat.triageFlag == TriageFlag.yellow
                                        ? Colors.amber.shade900
                                        : Colors.green.shade900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showLifestyleCounsellingDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                const Icon(
                  Icons.health_and_safety,
                  color: Colors.teal,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lifestyle Counselling (Req 19.7)',
                  style: Theme.of(ctx).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Deliver short pictorial and spoken messages to the beneficiary:',
              style: TextStyle(color: Colors.grey),
            ),
            const Divider(height: 24),
            ...LifestyleTopic.values.map(
              (topic) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.volume_up, color: Colors.white),
                  ),
                  title: Text(
                    topic.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(topic.guidance),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndEvaluateCbac() async {
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(ncdRepositoryProvider);

      final assessment = await repo.recordCbacScreening(
        memberId: widget.memberId,
        tobaccoUse: _tobaccoUse,
        alcoholConsumption: _alcoholConsumption,
        waistCircumferenceCm: _currentWaist,
        physicalActivity: _physicalActivity,
        familyHistory: _familyHistory,
        warningSigns: _warningSigns,
        systolicBp: _currentSystolic,
        diastolicBp: _currentDiastolic,
        bloodGlucoseMgDl: _currentGlucose,
        glucoseType: _glucoseType,
        ashaId: widget.ashaId,
      );

      if (!mounted) return;

      // Show Result Dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(
                assessment.triageFlag == TriageFlag.red
                    ? Icons.warning
                    : (assessment.triageFlag == TriageFlag.yellow
                          ? Icons.info
                          : Icons.check_circle),
                color: assessment.triageFlag == TriageFlag.red
                    ? Colors.red
                    : (assessment.triageFlag == TriageFlag.yellow
                          ? Colors.amber.shade800
                          : Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Triage: ${assessment.triageFlag.name.toUpperCase()}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CBAC Score: ${assessment.totalCbacScore}/10 (${assessment.isHighRiskScore ? "HIGH RISK" : "Normal"})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Divider(),
                const Text(
                  'Clinical Findings:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...assessment.clinicalFindings.map(
                  (f) => Text('• $f', style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Recommended Actions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...assessment.recommendedActions.map(
                  (a) => Text(
                    '✓ $a',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
                if (assessment.referralDestination != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Referral Destination: ${assessment.referralDestination}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Done & Return'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showClinicalSaveError(
        context,
        program: 'CBAC screening',
        error: e,
        onRetry: _saveAndEvaluateCbac,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
