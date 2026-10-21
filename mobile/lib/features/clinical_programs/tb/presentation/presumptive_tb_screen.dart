import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/language_provider.dart';
import '../../../../core/triage/models/models.dart';
import '../../../../shared/shell/shell_copy.dart';
import '../data/tb_repository.dart';
import '../domain/tb_models.dart';

/// Screen for recording Presumptive TB screening and Sputum sample collection,
/// featuring strict anti-stigma privacy controls (Requirement 20.1, 20.2, 20.8).
class PresumptiveTbScreen extends ConsumerStatefulWidget {
  final String memberId;
  final String beneficiaryName;
  final String ashaId;

  const PresumptiveTbScreen({
    super.key,
    required this.memberId,
    required this.beneficiaryName,
    required this.ashaId,
  });

  @override
  ConsumerState<PresumptiveTbScreen> createState() => _PresumptiveTbScreenState();
}

class _PresumptiveTbScreenState extends ConsumerState<PresumptiveTbScreen> {
  TbPrivacyMode _privacyMode = TbPrivacyMode.ashaPrivateView;

  // Symptom checklist (Requirement 20.1)
  bool _coughGt2Weeks = false;
  bool _feverGt2Weeks = false;
  bool _weightLoss = false;
  bool _nightSweats = false;
  bool _haemoptysis = false;
  bool _chestPain = false;
  bool _contactWithTbPatient = false;

  // Sputum sample fields (Requirement 20.2)
  bool _collectSputumNow = false;
  final _sampleIdController = TextEditingController();
  final _collectionSiteController = TextEditingController(text: 'Village Health Post');
  SputumTransportStatus _transportStatus = SputumTransportStatus.collectedAtVillage;

  bool _isSaving = false;

  @override
  void dispose() {
    _sampleIdController.dispose();
    _collectionSiteController.dispose();
    super.dispose();
  }

  String _t(String text) => TbPrivacyFilter.filterTerm(text, _privacyMode);

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).languageCode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _privacyMode == TbPrivacyMode.sharedSupervisorView
                  ? _t('Presumptive TB Screening')
                  : (lang == 'en'
                      ? 'Presumptive TB Screening'
                      : shellText(lang, 'presumptiveTbTitle')),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(widget.beneficiaryName, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          // Privacy Toggle (Requirement 20.8)
          IconButton(
            tooltip: _privacyMode == TbPrivacyMode.ashaPrivateView
                ? 'Switch to Shared-Device Stigma-Free View'
                : 'Switch to ASHA Private Clinical View',
            icon: Icon(
              _privacyMode == TbPrivacyMode.sharedSupervisorView ? Icons.visibility_off : Icons.visibility,
              color: Colors.amberAccent,
            ),
            onPressed: () {
              setState(() {
                _privacyMode = _privacyMode == TbPrivacyMode.ashaPrivateView
                    ? TbPrivacyMode.sharedSupervisorView
                    : TbPrivacyMode.ashaPrivateView;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _privacyMode == TbPrivacyMode.sharedSupervisorView
                        ? 'Shared-Device Mode: TB labels replaced with neutral respiratory terms'
                        : 'ASHA Private Mode: Standard NTEP clinical terminology visible',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Privacy Banner
          if (_privacyMode == TbPrivacyMode.sharedSupervisorView)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stigma Protection Active: Sensitive TB terms are hidden and displayed as neutral respiratory care terms.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),

          // Symptoms Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medical_services, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        _t('Presumptive TB Symptoms Checklist (Req 20.1)'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: Text(_t('Cough of 2 or more weeks duration')),
                    value: _coughGt2Weeks,
                    onChanged: (v) => setState(() => _coughGt2Weeks = v ?? false),
                  ),
                  CheckboxListTile(
                    title: Text(_t('Fever of 2 or more weeks duration')),
                    value: _feverGt2Weeks,
                    onChanged: (v) => setState(() => _feverGt2Weeks = v ?? false),
                  ),
                  CheckboxListTile(
                    title: Text(_t('Significant unexplained weight loss')),
                    value: _weightLoss,
                    onChanged: (v) => setState(() => _weightLoss = v ?? false),
                  ),
                  CheckboxListTile(
                    title: Text(_t('Drenching night sweats')),
                    value: _nightSweats,
                    onChanged: (v) => setState(() => _nightSweats = v ?? false),
                  ),
                  CheckboxListTile(
                    title: Text(_t('Haemoptysis (blood in sputum / cough) - URGENT')),
                    value: _haemoptysis,
                    activeColor: Colors.red,
                    onChanged: (v) => setState(() => _haemoptysis = v ?? false),
                  ),
                  CheckboxListTile(
                    title: Text(_t('Pleuritic chest pain')),
                    value: _chestPain,
                    onChanged: (v) => setState(() => _chestPain = v ?? false),
                  ),
                  CheckboxListTile(
                    title: Text(_t('Close contact with active TB patient in household')),
                    value: _contactWithTbPatient,
                    onChanged: (v) => setState(() => _contactWithTbPatient = v ?? false),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sputum Collection Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.science, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(
                        _t('Sputum Sample Collection & Tracking (Req 20.2)'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: Text(_t('Collect Sputum Sample Now')),
                    subtitle: Text(_t('Collect 2 samples in falcon cups and dispatch to DMC')),
                    value: _collectSputumNow,
                    onChanged: (v) => setState(() => _collectSputumNow = v),
                  ),
                  if (_collectSputumNow) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _sampleIdController,
                      decoration: InputDecoration(
                        labelText: _t('Sputum Sample Barcode / ID'),
                        hintText: 'e.g. SP-RAMPUR-2026-001',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _collectionSiteController,
                      decoration: InputDecoration(
                        labelText: _t('Collection Site / Facility'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<SputumTransportStatus>(
                      initialValue: _transportStatus,
                      decoration: InputDecoration(labelText: _t('Transport Status'), border: const OutlineInputBorder()),
                      items: SputumTransportStatus.values
                          .map((s) => DropdownMenuItem(value: s, child: Text(_t(s.label))))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _transportStatus = v);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _haemoptysis ? Colors.red : theme.colorScheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save_outlined),
            label: Text(
              _isSaving ? 'Saving...' : _t('Save Presumptive TB Assessment'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: _isSaving ? null : _saveAssessment,
          ),
        ],
      ),
    );
  }

  Future<void> _saveAssessment() async {
    setState(() => _isSaving = true);

    try {
      final repo = ref.read(tbRepositoryProvider);

      final assessment = await repo.recordPresumptiveTbScreening(
        memberId: widget.memberId,
        coughGt2Weeks: _coughGt2Weeks,
        feverGt2Weeks: _feverGt2Weeks,
        unexplainedWeightLoss: _weightLoss,
        nightSweats: _nightSweats,
        haemoptysis: _haemoptysis,
        chestPain: _chestPain,
        contactWithKnownTbPatient: _contactWithTbPatient,
        ashaId: widget.ashaId,
      );

      if (_collectSputumNow && _sampleIdController.text.trim().isNotEmpty) {
        await repo.recordSputumSample(
          memberId: widget.memberId,
          sampleId: _sampleIdController.text.trim(),
          collectionSite: _collectionSiteController.text.trim(),
          transportStatus: _transportStatus,
          ashaId: widget.ashaId,
        );
      }

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
                    : (assessment.triageFlag == TriageFlag.yellow ? Icons.info : Icons.check_circle),
                color: assessment.triageFlag == TriageFlag.red
                    ? Colors.red
                    : (assessment.triageFlag == TriageFlag.yellow ? Colors.amber.shade800 : Colors.green),
              ),
              const SizedBox(width: 8),
              Text('Triage: ${assessment.triageFlag.name.toUpperCase()}'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  assessment.isPresumptiveTb
                      ? _t('Presumptive TB Identified — Referral to DMC Required')
                      : _t('No Cardinal TB Symptoms Detected'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Divider(),
                const Text('Clinical Findings:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...assessment.clinicalFindings.map((f) => Text('• ${_t(f)}', style: const TextStyle(fontSize: 13))),
                const SizedBox(height: 8),
                const Text('Recommended Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...assessment.recommendedActions.map((a) => Text('✓ ${_t(a)}', style: const TextStyle(fontSize: 13, color: Colors.blueGrey))),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
