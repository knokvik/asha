import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../domain/measurement_aids.dart';

/// Clinical Calculators, MUAC Colour-coded Reference, Timers, and Experimental AI Safety Guard
/// (Requirements 29.2, 29.3, 29.4, 29.5).
class ClinicalCalculatorsScreen extends StatefulWidget {
  const ClinicalCalculatorsScreen({super.key});

  @override
  State<ClinicalCalculatorsScreen> createState() =>
      _ClinicalCalculatorsScreenState();
}

class _ClinicalCalculatorsScreenState extends State<ClinicalCalculatorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // EDD & Gestational Age State
  DateTime? _selectedLmp;
  DateTime? _calculatedEdd;
  Map<String, int>? _gestationalAge;

  // Drug Dosage State
  double _childWeightKg = 10.0;
  String _selectedDrug = 'Paracetamol';
  int _childAgeMonths = 12;

  // BMI State
  double _bmiWeightKg = 60.0;
  double _bmiHeightCm = 160.0;
  Map<String, dynamic>? _bmiResult;

  // MUAC State
  double _muacSliderValue = 12.0;

  // Experimental Camera AI State
  ClinicalTriageTier _clinicalProtocolTier = ClinicalTriageTier.yellow;
  ClinicalTriageTier _cameraEstimatedTier = ClinicalTriageTier.green;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _calculateBmi();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _calculateEddAndGa(DateTime lmp) {
    setState(() {
      _selectedLmp = lmp;
      _calculatedEdd = ClinicalCalculators.calculateEdd(lmp);
      _gestationalAge = ClinicalCalculators.calculateGestationalAge(lmp);
    });
  }

  void _calculateBmi() {
    setState(() {
      _bmiResult = ClinicalCalculators.calculateBmi(
        weightKg: _bmiWeightKg,
        heightCm: _bmiHeightCm,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: const Text('Clinical Aids & Calculators'),
        backgroundColor: AshaColors.screenBg,
        foregroundColor: AshaColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AshaColors.primary,
          labelColor: AshaColors.primaryDark,
          unselectedLabelColor: AshaColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.pregnant_woman), text: 'EDD & GA'),
            Tab(icon: Icon(Icons.medication), text: 'Drug Dosing'),
            Tab(icon: Icon(Icons.straighten), text: 'MUAC Tape'),
            Tab(icon: Icon(Icons.monitor_weight), text: 'BMI & Growth'),
            Tab(icon: Icon(Icons.camera_alt), text: 'Experimental AI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEddTab(context),
          _buildDrugDosingTab(context),
          _buildMuacTab(context),
          _buildBmiTab(context),
          _buildExperimentalAiTab(context),
        ],
      ),
    );
  }

  // ── Tab 1: EDD from LMP & Gestational Age (Requirement 29.5) ─────────────────
  Widget _buildEddTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expected Date of Delivery (EDD) & Gestational Age',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Computed offline using Naegele\'s rule (LMP + 280 days / 40 weeks).',
          ),
          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 60)),
                firstDate: DateTime.now().subtract(const Duration(days: 300)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                _calculateEddAndGa(picked);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _selectedLmp != null
                  ? 'LMP: ${_selectedLmp!.day}/${_selectedLmp!.month}/${_selectedLmp!.year}'
                  : 'Select Last Menstrual Period (LMP)',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AshaColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 24),

          if (_calculatedEdd != null && _gestationalAge != null) ...[
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.event_available,
                        color: AshaColors.primary,
                        size: 36,
                      ),
                      title: const Text('Expected Date of Delivery (EDD)'),
                      subtitle: Text(
                        '${_calculatedEdd!.day}/${_calculatedEdd!.month}/${_calculatedEdd!.year}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AshaColors.primary,
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(
                        Icons.timelapse,
                        color: Colors.blue,
                        size: 36,
                      ),
                      title: const Text('Current Gestational Age'),
                      subtitle: Text(
                        '${_gestationalAge!['weeks']} weeks and ${_gestationalAge!['days']} days (${_gestationalAge!['total_days']} days total)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab 2: ASHA-Scope Drug Dosage Calculator (Requirement 29.5) ──────────────
  Widget _buildDrugDosingTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ASHA-Scope Drug Dosing Calculator',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Guidance for Oral Rehydration Salts (ORS), Zinc, Paracetamol, and IFA tablets.',
          ),
          const SizedBox(height: 20),

          DropdownButtonFormField<String>(
            value: _selectedDrug,
            decoration: const InputDecoration(
              labelText: 'Select Medication',
              border: OutlineInputBorder(),
            ),
            items: [
              'Paracetamol',
              'Zinc Supplement',
              'ORS Solution',
              'IFA Tablets',
            ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedDrug = val);
            },
          ),
          const SizedBox(height: 16),

          if (_selectedDrug == 'Paracetamol') ...[
            Text('Child Weight: ${_childWeightKg.toStringAsFixed(1)} kg'),
            Slider(
              value: _childWeightKg,
              min: 3.0,
              max: 30.0,
              divisions: 54,
              activeColor: AshaColors.primary,
              onChanged: (val) => setState(() => _childWeightKg = val),
            ),
            const SizedBox(height: 12),
            _buildDoseCard(
              title: 'Pediatric Paracetamol Syrup (120 mg / 5 mL)',
              details: ClinicalCalculators.calculateParacetamolDose(
                weightKg: _childWeightKg,
              ),
            ),
          ] else if (_selectedDrug == 'Zinc Supplement') ...[
            Text('Child Age: $_childAgeMonths months'),
            Slider(
              value: _childAgeMonths.toDouble(),
              min: 1.0,
              max: 59.0,
              divisions: 58,
              activeColor: AshaColors.primary,
              onChanged: (val) => setState(() => _childAgeMonths = val.round()),
            ),
            const SizedBox(height: 12),
            _buildZincDoseCard(
              ClinicalCalculators.calculateZincDose(_childAgeMonths),
            ),
          ] else if (_selectedDrug == 'ORS Solution') ...[
            Text('Child Weight: ${_childWeightKg.toStringAsFixed(1)} kg'),
            Slider(
              value: _childWeightKg,
              min: 3.0,
              max: 20.0,
              divisions: 34,
              activeColor: AshaColors.primary,
              onChanged: (val) => setState(() => _childWeightKg = val),
            ),
            const SizedBox(height: 12),
            _buildOrsDoseCard(
              ClinicalCalculators.calculateOrsDosage(
                weightKg: _childWeightKg,
                hasSomeDehydration: true,
              ),
            ),
          ] else if (_selectedDrug == 'IFA Tablets') ...[
            _buildIfaCard(),
          ],
        ],
      ),
    );
  }

  // ── Tab 3: WHO/UNICEF MUAC Colour-Coded Guide (Requirement 29.2) ────────────
  Widget _buildMuacTab(BuildContext context) {
    final category = MuacClassifier.classify(_muacSliderValue);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MUAC Tape Colour-Coded Reference Guide',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'WHO/UNICEF Standard Mid-Upper Arm Circumference tape for children 6–59 months.',
          ),
          const SizedBox(height: 24),

          // Interactive Visual MUAC Tape Ruler
          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black26),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 115, // < 11.5 cm
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFD32F2F),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(7),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'RED (<11.5)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 10, // 11.5 - 12.5 cm
                  child: Container(
                    color: const Color(0xFFFBC02D),
                    alignment: Alignment.center,
                    child: const Text(
                      'YEL',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 125, // > 12.5 cm
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF388E3C),
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(7),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'GREEN (>12.5 cm)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Measured Reading: ${_muacSliderValue.toStringAsFixed(1)} cm',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _muacSliderValue,
            min: 8.0,
            max: 18.0,
            divisions: 100,
            activeColor: Color(category.colorValue),
            onChanged: (val) => setState(() => _muacSliderValue = val),
          ),
          const SizedBox(height: 16),

          Card(
            color: Color(category.colorValue).withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(category.colorValue),
                    radius: 20,
                    child: const Icon(Icons.assessment, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(category.colorValue),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category == MuacCategory.redSam
                              ? 'RED ALERT: Immediate referral to Nutrition Rehabilitation Centre (NRC).'
                              : (category == MuacCategory.yellowMam
                                    ? 'YELLOW ALERT: Enroll in supplementary nutrition; intensive counseling.'
                                    : 'Adequate nutritional status. Continue routine feeding and growth monitoring.'),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab 4: BMI & Growth Calculator (Requirement 29.5) ────────────────────────
  Widget _buildBmiTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adult BMI & Nutritional Status Calculator',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'WHO Asian-Indian population risk cutoffs (Normal: 18.5 – 22.9 kg/m²).',
          ),
          const SizedBox(height: 20),

          Text('Weight: ${_bmiWeightKg.toStringAsFixed(1)} kg'),
          Slider(
            value: _bmiWeightKg,
            min: 30.0,
            max: 140.0,
            divisions: 110,
            activeColor: AshaColors.primary,
            onChanged: (val) {
              _bmiWeightKg = val;
              _calculateBmi();
            },
          ),
          const SizedBox(height: 10),

          Text('Height: ${_bmiHeightCm.toStringAsFixed(1)} cm'),
          Slider(
            value: _bmiHeightCm,
            min: 120.0,
            max: 200.0,
            divisions: 80,
            activeColor: AshaColors.primary,
            onChanged: (val) {
              _bmiHeightCm = val;
              _calculateBmi();
            },
          ),
          const SizedBox(height: 20),

          if (_bmiResult != null) ...[
            Card(
              color: Color(_bmiResult!['color_value'] as int)
                  .withValues(alpha: 0.1),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(_bmiResult!['color_value'] as int),
                  child: Text(
                    '${(_bmiResult!['bmi'] as double).round()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  'BMI: ${_bmiResult!['bmi']} kg/m²',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Classification: ${_bmiResult!['classification']}',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Tab 5: Experimental Camera Aid with Mandatory CDSCO Notice (Req 29.4) ───
  Widget _buildExperimentalAiTab(BuildContext context) {
    final reconciledTier = ExperimentalAiGuard.reconcileTriageSeverity(
      clinicalTier: _clinicalProtocolTier,
      experimentalCameraTier: _cameraEstimatedTier,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mandatory Prominent Regulatory Disclaimer (Requirement 29.4)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade400, width: 2),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.gavel, color: Colors.red, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ExperimentalAiGuard.disclaimerText,
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Safety Invariant Demonstration: Non-Downgrade Protocol',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Under Requirement 29.4, an experimental camera reading cannot downgrade an established RED or YELLOW clinical severity.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<ClinicalTriageTier>(
            value: _clinicalProtocolTier,
            decoration: const InputDecoration(
              labelText: 'Clinical Protocol Assessment (Ground Truth)',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: ClinicalTriageTier.red,
                child: Text('RED Alert (Emergency)'),
              ),
              DropdownMenuItem(
                value: ClinicalTriageTier.yellow,
                child: Text('YELLOW Alert (Routine Priority)'),
              ),
              DropdownMenuItem(
                value: ClinicalTriageTier.green,
                child: Text('GREEN (Normal)'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _clinicalProtocolTier = val);
            },
          ),
          const SizedBox(height: 14),

          DropdownButtonFormField<ClinicalTriageTier>(
            value: _cameraEstimatedTier,
            decoration: const InputDecoration(
              labelText: 'Experimental Camera AI Output',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: ClinicalTriageTier.red,
                child: Text('Camera AI: RED'),
              ),
              DropdownMenuItem(
                value: ClinicalTriageTier.yellow,
                child: Text('Camera AI: YELLOW'),
              ),
              DropdownMenuItem(
                value: ClinicalTriageTier.green,
                child: Text('Camera AI: GREEN'),
              ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _cameraEstimatedTier = val);
            },
          ),
          const SizedBox(height: 20),

          Card(
            color: reconciledTier == ClinicalTriageTier.red
                ? Colors.red.shade50
                : (reconciledTier == ClinicalTriageTier.yellow
                      ? Colors.amber.shade50
                      : Colors.green.shade50),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Final Reconciled Triage Tier:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reconciledTier.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: reconciledTier == ClinicalTriageTier.red
                          ? Colors.red
                          : (reconciledTier == ClinicalTriageTier.yellow
                                ? Colors.orange.shade800
                                : Colors.green),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reconciledTier == _clinicalProtocolTier &&
                            _cameraEstimatedTier == ClinicalTriageTier.green &&
                            _clinicalProtocolTier != ClinicalTriageTier.green
                        ? 'Safety Guard Active: Experimental GREEN AI output was rejected from downgrading clinical ${_clinicalProtocolTier.name.toUpperCase()}.'
                        : 'Protocol compliant result.',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseCard({
    required String title,
    required Map<String, dynamic> details,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            Text(
              'Single Dose: ${details['target_dose_mg']} mg (${details['syrup_volume_ml']} mL)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AshaColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Allowable Range: ${details['min_dose_mg']} – ${details['max_dose_mg']} mg',
            ),
            const SizedBox(height: 6),
            Text(
              'Frequency: ${details['frequency']}',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZincDoseCard(Map<String, dynamic> details) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pediatric Zinc Sulfate Diarrhea Regimen',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            Text(
              'Daily Dose: ${details['dose_mg']} mg',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AshaColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text('Form: ${details['form']}'),
            const SizedBox(height: 6),
            Text(
              'Duration: ${details['duration_days']} Days (${details['instructions']})',
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrsDoseCard(Map<String, dynamic> details) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              details['regimen'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            Text(
              'Volume to Prepare: ${details['volume_ml']} mL over ${details['duration_hours']} hours',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AshaColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              details['instructions'] as String,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIfaCard() {
    return const Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anemia Mukt Bharat IFA Protocols',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Divider(),
            Text(
              '• Pregnant Women: 1 Red Tablet daily (60mg iron + 500mcg FA) for 180 days after 1st trimester.',
            ),
            SizedBox(height: 6),
            Text(
              '• Lactating Mothers: 1 Red Tablet daily for 180 days postpartum.',
            ),
            SizedBox(height: 6),
            Text(
              '• Children 6–59 months: 1 mL IFA Syrup bi-weekly (20mg iron + 100mcg FA).',
            ),
            SizedBox(height: 6),
            Text(
              '• Children 5–9 years: 1 Pink Tablet weekly (45mg iron + 400mcg FA).',
            ),
            SizedBox(height: 6),
            Text(
              '• Adolescents 10–19 years: 1 Blue Tablet weekly (60mg iron + 500mcg FA).',
            ),
          ],
        ),
      ),
    );
  }
}
