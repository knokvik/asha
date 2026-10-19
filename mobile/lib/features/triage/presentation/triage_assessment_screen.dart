import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/triage/models/models.dart';
import '../../../shared/widgets/asha_badge.dart';
import '../../../shared/widgets/asha_card.dart';
import '../domain/triage_service.dart';
import 'language_bridge_screen.dart';
import 'setu_questions_screen.dart';
import 'triage_result_screen.dart';

/// Interactive clinical assessment and triage entry flow.
///
/// Implements Requirements 8.1, 8.4, 8.5, 11.1, 46.1, 46.2.
class TriageAssessmentScreen extends ConsumerStatefulWidget {
  final String? memberId;
  final int? initialAgeDays;
  final bool? initialIsPregnant;

  const TriageAssessmentScreen({
    super.key,
    this.memberId,
    this.initialAgeDays,
    this.initialIsPregnant,
  });

  @override
  ConsumerState<TriageAssessmentScreen> createState() =>
      _TriageAssessmentScreenState();
}

class _TriageAssessmentScreenState extends ConsumerState<TriageAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Patient Demographic Controls (Requirement 11.1)
  AgeBandCode _selectedAgeBand = AgeBandCode.infant02m;
  bool _isPregnant = false;
  final _ageDaysController = TextEditingController();

  // Clinical Vitals & Observation Inputs
  final _respiratoryRateController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _systolicBpController = TextEditingController();
  final _diastolicBpController = TextEditingController();
  final _pulseRateController = TextEditingController();
  bool _chestIndrawing = false;
  bool _vomitingEverything = false;
  bool _convulsions = false;

  bool _isEvaluating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialIsPregnant == true) {
      _isPregnant = true;
      _selectedAgeBand = AgeBandCode.pregnant;
    } else if (widget.initialAgeDays != null) {
      _ageDaysController.text = widget.initialAgeDays.toString();
      _selectedAgeBand =
          AgeBandResolver.resolve(ageInDays: widget.initialAgeDays);
    }
  }

  @override
  void dispose() {
    _ageDaysController.dispose();
    _respiratoryRateController.dispose();
    _temperatureController.dispose();
    _systolicBpController.dispose();
    _diastolicBpController.dispose();
    _pulseRateController.dispose();
    super.dispose();
  }

  void _onAgeBandChanged(AgeBandCode? code) {
    if (code == null) return;
    setState(() {
      _selectedAgeBand = code;
      _isPregnant = code == AgeBandCode.pregnant;
    });
  }

  Future<void> _submitAssessment() async {
    setState(() => _isEvaluating = true);

    try {
      final ageDays = int.tryParse(_ageDaysController.text.trim());
      final rr = int.tryParse(_respiratoryRateController.text.trim());
      final temp = double.tryParse(_temperatureController.text.trim());
      final sbp = int.tryParse(_systolicBpController.text.trim());
      final dbp = int.tryParse(_diastolicBpController.text.trim());
      final pulse = int.tryParse(_pulseRateController.text.trim());

      final values = <String, dynamic>{};
      if (rr != null) values['respiratory_rate'] = rr;
      if (temp != null) values['temperature'] = temp;
      if (sbp != null) values['systolic_bp'] = sbp;
      if (dbp != null) values['diastolic_bp'] = dbp;
      if (pulse != null) values['pulse_rate'] = pulse;
      if (_chestIndrawing) values['chest_indrawing'] = true;
      if (_vomitingEverything) values['vomiting_everything'] = true;
      if (_convulsions) values['convulsions'] = true;

      final inputs = TriageInputs(
        memberId: widget.memberId,
        ageInDays: ageDays,
        isPregnant: _isPregnant,
        explicitAgeBand: _selectedAgeBand,
        values: values,
      );

      // Pure on-device evaluation (Requirement 8.1: < 1s, pure on-device)
      final triageService = ref.read(triageServiceProvider);
      final result = await triageService.evaluateAssessment(
        inputs,
        memberId: widget.memberId,
        speakAudio: true, // Speaks via TTS (Requirement 46.1, 46.2)
      );

      if (mounted) {
        setState(() => _isEvaluating = false);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TriageResultScreen(
              initialResult: result,
              memberId: widget.memberId,
            ),
          ),
        );
      }
    } finally {
      if (mounted && _isEvaluating) {
        setState(() => _isEvaluating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical Assessment'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AshaCard(
              statusStripeColor: AshaColors.primary,
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AshaColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.fact_check_outlined, color: AshaColors.primary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Language and Setu questions',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AshaColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ask the Setu questions one at a time, then make a referral QR. They speak and I ask help with the language. The voice model does not choose the colour.',
                    style: TextStyle(fontSize: 13, color: AshaColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('setu_questions_button'),
                    style: FilledButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: AshaShapes.buttonRadius),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SetuQuestionsScreen()),
                      );
                    },
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Ask the triage questions', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    key: const Key('language_bridge_button'),
                    style: OutlinedButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: AshaShapes.buttonRadius),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LanguageBridgeScreen()),
                      );
                    },
                    icon: const Icon(Icons.translate),
                    label: const Text('They speak / I ask', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Protocol age-band selection (Requirement 11.1)
            AshaCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patient Group (Protocol Scope)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AshaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AgeBandCode>(
                    key: const Key('age_band_dropdown'),
                    isExpanded: true,
                    initialValue: _selectedAgeBand,
                    decoration: const InputDecoration(
                      labelText: 'Select Age Band / Condition',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AgeBandCode.infant02m,
                        child: Text(
                          'Young Infant (0–2 Months) — IMNCI / HBNC',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: AgeBandCode.child2m5y,
                        child: Text(
                          'Child (2 Months–5 Years) — IMNCI / HBYC',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: AgeBandCode.adolescent,
                        child: Text(
                          'Adolescent (5–19 Years) — WIFS',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: AgeBandCode.adult,
                        child: Text(
                          'Adult — NP-NCD',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: AgeBandCode.pregnant,
                        child: Text(
                          'Pregnant Woman — PMSMA / ANC',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: _onAgeBandChanged,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('age_days_field'),
                    controller: _ageDaysController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Exact Age in Days (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Clinical Vitals Entry
            AshaCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Measured Vitals',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AshaColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('respiratory_rate_field'),
                    controller: _respiratoryRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Respiratory Rate (breaths/min)',
                      hintText: 'e.g. 62',
                      border: OutlineInputBorder(),
                      suffixText: '/min',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('temperature_field'),
                    controller: _temperatureController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Axillary Temperature (°C)',
                      hintText: 'e.g. 38.5',
                      border: OutlineInputBorder(),
                      suffixText: '°C',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          key: const Key('systolic_bp_field'),
                          controller: _systolicBpController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Systolic BP',
                            hintText: '120',
                            border: OutlineInputBorder(),
                            suffixText: 'mmHg',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          key: const Key('diastolic_bp_field'),
                          controller: _diastolicBpController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Diastolic BP',
                            hintText: '80',
                            border: OutlineInputBorder(),
                            suffixText: 'mmHg',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('pulse_rate_field'),
                    controller: _pulseRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Pulse Rate (bpm)',
                      hintText: '72',
                      border: OutlineInputBorder(),
                      suffixText: 'bpm',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Danger Sign Observations Checklist (Requirement 11.2)
            AshaCard(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Danger Sign Observations',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AshaColors.textPrimary,
                    ),
                  ),
                  CheckboxListTile(
                    key: const Key('chest_indrawing_checkbox'),
                    title: const Text('Severe chest indrawing'),
                    value: _chestIndrawing,
                    onChanged: (val) => setState(() => _chestIndrawing = val ?? false),
                  ),
                  CheckboxListTile(
                    key: const Key('vomiting_checkbox'),
                    title: const Text('Vomiting everything'),
                    value: _vomitingEverything,
                    onChanged: (val) => setState(() => _vomitingEverything = val ?? false),
                  ),
                  CheckboxListTile(
                    key: const Key('convulsions_checkbox'),
                    title: const Text('Convulsions or lethargy'),
                    value: _convulsions,
                    onChanged: (val) => setState(() => _convulsions = val ?? false),
                  ),
                ],
              ),
            ),

            // Designated Submit Button (Requirement 8.1)
            ElevatedButton(
              key: const Key('submit_triage_button'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AshaColors.primary,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(borderRadius: AshaShapes.buttonRadius),
                elevation: 0,
              ),
              onPressed: _isEvaluating ? null : _submitAssessment,
              child: _isEvaluating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Compute Triage & Action Plan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
