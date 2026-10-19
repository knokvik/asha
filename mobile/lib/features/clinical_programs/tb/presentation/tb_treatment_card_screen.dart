import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tb_repository.dart';
import '../domain/tb_models.dart';

/// Screen displaying the TB Treatment Card (DOTS), daily dose observation logger,
/// consecutive-miss alert warnings, contact tracing with TPT eligibility, and
/// Nikshay Poshan Yojana status with stigma-free privacy filter (Requirements 20.3, 20.4, 20.5, 20.7, 20.8).
class TbTreatmentCardScreen extends ConsumerStatefulWidget {
  final TbTreatmentPatient patient;
  final String ashaId;

  const TbTreatmentCardScreen({
    super.key,
    required this.patient,
    required this.ashaId,
  });

  @override
  ConsumerState<TbTreatmentCardScreen> createState() => _TbTreatmentCardScreenState();
}

class _TbTreatmentCardScreenState extends ConsumerState<TbTreatmentCardScreen> {
  TbPrivacyMode _privacyMode = TbPrivacyMode.ashaPrivateView;

  String _t(String text) => TbPrivacyFilter.filterTerm(text, _privacyMode);

  @override
  Widget build(BuildContext context) {
    final p = widget.patient;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('TB Treatment Card (DOTS)'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${p.beneficiaryName} | ${_t(p.regimen.label)}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
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
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Consecutive Miss Alert Banner (Requirement 20.4)
          if (p.hasConsecutiveMissAlert) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                border: Border.all(color: Colors.red.shade700, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _t('URGENT: ${p.consecutiveMissedDoses} Consecutive Missed Doses!'),
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _t('Immediate home visit required. Alert forwarded to Senior Treatment Supervisor (STS).'),
                          style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Treatment Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.medication, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.beneficiaryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            if (p.nikshayId != null)
                              Text('${_t("Ni-kshay ID")}: ${p.nikshayId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildDetailRow('Regimen', _t(p.regimen.label)),
                  _buildDetailRow('Disease Site', _t(p.site.label)),
                  _buildDetailRow('Start Date', p.startDate.toIso8601String().split('T').first),
                  _buildDetailRow('Treatment Supporter', '${p.treatmentSupporterName} (${p.treatmentSupporterPhone})'),
                  _buildDetailRow('Nikshay Poshan DBT', _t(p.nikshayPoshanStatus.label)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Daily Dose Action Card
          Card(
            color: Colors.teal.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_t('Record Today\'s Dose Observation (Req 20.4)'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.check),
                          label: Text(_t('Observed Taken')),
                          onPressed: () => _recordDose(DoseIntakeStatus.observedTaken),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade800,
                            side: BorderSide(color: Colors.red.shade400),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.close),
                          label: Text(_t('Missed Dose')),
                          onPressed: () => _recordDose(DoseIntakeStatus.missed),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact Tracing & TPT Quick Action (Requirement 20.5)
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            leading: const CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Icon(Icons.people, color: Colors.white),
            ),
            title: Text(_t('Household Contact Tracing & TPT'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_t('Screen household members and enrol in preventive therapy (Req 20.5)')),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showContactTracingDialog,
          ),
          const SizedBox(height: 12),

          // Nikshay Poshan DBT Linkage (Requirement 20.7)
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.currency_rupee, color: Colors.white),
            ),
            title: Text(_t('Ni-kshay Poshan Yojana (Rs 500/mo DBT)'), style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(_t('Status: ${p.nikshayPoshanStatus.label} (Req 20.7)')),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showNikshayPoshanDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(_t(label), style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _recordDose(DoseIntakeStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(tbRepositoryProvider);
      await repo.recordDoseObservation(
        memberId: widget.patient.memberId,
        status: status,
        ashaId: widget.ashaId,
      );

      messenger.showSnackBar(
        SnackBar(
          content: Text(_t('Dose observation recorded: ${status.label}')),
          backgroundColor: status == DoseIntakeStatus.missed ? Colors.amber.shade900 : Colors.teal,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  void _showContactTracingDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('Household Contact Tracing (Req 20.5)')),
        content: Text(
          _t('List all household contacts of the index patient. Children < 5 years and asymptomatic contacts are evaluated for TB Preventive Therapy (TPT).'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showNikshayPoshanDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('Ni-kshay Poshan Yojana (Req 20.7)')),
        content: Text(
          _t('Under NTEP, all registered TB patients are entitled to Rs 500 per month for nutritional support via Direct Benefit Transfer (DBT). Ensure bank details are submitted and verified on Ni-kshay.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
