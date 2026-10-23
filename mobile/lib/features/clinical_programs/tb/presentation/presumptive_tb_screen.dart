import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../shared/shell/shell_copy.dart';
import '../data/tb_repository.dart';
import '../domain/tb_models.dart';
import '../../presentation/clinical_card_helpers.dart';

/// Screen for recording Presumptive TB screening and Sputum sample collection.
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

  // Symptom checklist
  bool _coughGt2Weeks = false;
  bool _feverGt2Weeks = false;
  bool _weightLoss = false;
  bool _nightSweats = false;
  bool _haemoptysis = false;
  bool _chestPain = false;
  bool _contactWithTbPatient = false;

  // Sputum sample fields
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

    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _privacyMode == TbPrivacyMode.sharedSupervisorView
                  ? _t('Presumptive TB Screening')
                  : (lang == 'en'
                      ? 'Presumptive TB Screening'
                      : shellText(lang, 'presumptiveTbTitle')),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            Text(widget.beneficiaryName, style: const TextStyle(fontSize: 12, color: AshaColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Privacy / Stigma-Protection View',
            icon: Icon(
              _privacyMode == TbPrivacyMode.sharedSupervisorView ? Icons.visibility_off : Icons.visibility,
              color: AshaColors.primary,
            ),
            onPressed: () {
              setState(() {
                _privacyMode = _privacyMode == TbPrivacyMode.ashaPrivateView
                    ? TbPrivacyMode.sharedSupervisorView
                    : TbPrivacyMode.ashaPrivateView;
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          if (_privacyMode == TbPrivacyMode.sharedSupervisorView)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade400),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Stigma Protection Active: Sensitive terms replaced with general respiratory labels.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown),
                    ),
                  ),
                ],
              ),
            ),

          // ── SECTION 1: Symptoms Checklist ──
          ClinicalFormCard(
            title: _t('Presumptive TB Symptoms'),
            icon: Icons.medical_services_outlined,
            child: Column(
              children: [
                ClinicalSwitchTile(
                  title: _t('Cough of 2 or more weeks duration'),
                  value: _coughGt2Weeks,
                  onChanged: (v) => setState(() => _coughGt2Weeks = v),
                ),
                ClinicalSwitchTile(
                  title: _t('Fever of 2 or more weeks duration'),
                  value: _feverGt2Weeks,
                  onChanged: (v) => setState(() => _feverGt2Weeks = v),
                ),
                ClinicalSwitchTile(
                  title: _t('Significant unexplained weight loss'),
                  value: _weightLoss,
                  onChanged: (v) => setState(() => _weightLoss = v),
                ),
                ClinicalSwitchTile(
                  title: _t('Drenching night sweats'),
                  value: _nightSweats,
                  onChanged: (v) => setState(() => _nightSweats = v),
                ),
                ClinicalSwitchTile(
                  title: _t('Blood in sputum / cough (Haemoptysis)'),
                  value: _haemoptysis,
                  onChanged: (v) => setState(() => _haemoptysis = v),
                  isDanger: true,
                ),
                ClinicalSwitchTile(
                  title: _t('Chest pain while breathing'),
                  value: _chestPain,
                  onChanged: (v) => setState(() => _chestPain = v),
                ),
                ClinicalSwitchTile(
                  title: _t('Contact with active patient in household'),
                  value: _contactWithTbPatient,
                  onChanged: (v) => setState(() => _contactWithTbPatient = v),
                ),
              ],
            ),
          ),

          // ── SECTION 2: Sputum Sample Collection ──
          ClinicalFormCard(
            title: _t('Sputum Sample Collection'),
            icon: Icons.science_outlined,
            child: Column(
              children: [
                ClinicalSwitchTile(
                  title: _t('Collect Sputum Sample Now'),
                  subtitle: 'Dispatch sample to DMC for testing',
                  value: _collectSputumNow,
                  onChanged: (v) => setState(() => _collectSputumNow = v),
                ),
                if (_collectSputumNow) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _sampleIdController,
                    decoration: InputDecoration(
                      labelText: _t('Sputum Sample Barcode / ID'),
                      hintText: 'e.g. SP-DEL-2026-001',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _collectionSiteController,
                    decoration: InputDecoration(
                      labelText: _t('Collection Site / Facility'),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<SputumTransportStatus>(
                    initialValue: _transportStatus,
                    decoration: InputDecoration(
                      labelText: _t('Transport Status'),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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

          const SizedBox(height: 12),

          ClinicalSubmitButton(
            label: _haemoptysis ? 'Emergency: Save & Refer to Specialist' : _t('Save Assessment'),
            isSaving: _isSaving,
            isEmergency: _haemoptysis,
            onPressed: _saveAssessment,
          ),
          const SizedBox(height: 24),
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
        ashaId: widget.ashaId,
        coughGt2Weeks: _coughGt2Weeks,
        feverGt2Weeks: _feverGt2Weeks,
        unexplainedWeightLoss: _weightLoss,
        nightSweats: _nightSweats,
        haemoptysis: _haemoptysis,
        chestPain: _chestPain,
        contactWithKnownTbPatient: _contactWithTbPatient,
      );

      if (_collectSputumNow) {
        final sampleId = _sampleIdController.text.trim().isNotEmpty
            ? _sampleIdController.text.trim()
            : 'SPUTUM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

        await repo.recordSputumSample(
          memberId: widget.memberId,
          ashaId: widget.ashaId,
          sampleId: sampleId,
          collectionSite: _collectionSiteController.text.trim().isNotEmpty
              ? _collectionSiteController.text.trim()
              : 'Village Health Post',
          transportStatus: _transportStatus,
        );
      }

      if (!mounted) return;
      setState(() => _isSaving = false);

      final message = assessment.isPresumptiveTb
          ? 'Presumptive case identified. Sputum tracking & CBNAAT follow-up scheduled.'
          : 'Presumptive screening recorded.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: assessment.isPresumptiveTb ? const Color(0xFFF59E0B) : AshaColors.primary,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving screening: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
