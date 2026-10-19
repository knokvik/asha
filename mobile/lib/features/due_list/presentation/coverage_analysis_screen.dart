import 'package:flutter/material.dart';
import '../domain/route_models.dart';

/// Supervisor Coverage Analysis Screen presenting area-level visit frequency,
/// access barriers, and workload rebalance suggestions with ASHA consent enforcement (Requirement 25.5).
class CoverageAnalysisScreen extends StatelessWidget {
  final CoverageAnalysisReport report;
  final ValueChanged<bool>? onConsentToggled;

  const CoverageAnalysisScreen({
    super.key,
    required this.report,
    this.onConsentToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Area Coverage & Workload Analysis'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Village Summary Header ─────────────────────────────────────
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Village: ${report.village}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatTile('Total Hamlets', '${report.totalHamlets}', Colors.blue),
                        _buildStatTile('Accessible', '${report.accessibleHamlets}', Colors.green),
                        _buildStatTile('Blocked / Seasonal', '${report.seasonallyBlockedHamlets}', Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── 2. ASHA Consent Banner (Requirement 25.5) ─────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: report.ashaConsentGiven ? Colors.green.shade50 : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: report.ashaConsentGiven ? Colors.green.shade300 : Colors.amber.shade400,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    report.ashaConsentGiven ? Icons.verified_user : Icons.lock_outline,
                    color: report.ashaConsentGiven ? Colors.green.shade800 : Colors.amber.shade900,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.ashaConsentGiven
                              ? 'ASHA Consent Granted'
                              : 'ASHA Consent Required (Req 25.5)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: report.ashaConsentGiven ? Colors.green.shade900 : Colors.amber.shade900,
                          ),
                        ),
                        Text(
                          report.ashaConsentGiven
                              ? 'Worker consent active. Full area-level analysis enabled for workload rebalancing.'
                              : 'Detailed hamlet visit frequencies and worker movements are withheld without explicit consent.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (onConsentToggled != null)
                    Switch(
                      value: report.ashaConsentGiven,
                      onChanged: onConsentToggled,
                      activeColor: const Color(0xFF1B5E20),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // If consent is not given, stop here and show placeholder
            if (!report.ashaConsentGiven) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'Workload analysis requires ASHA consent',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please request the ASHA worker to grant consent for workload rebalancing.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // ── 3. Hamlet Visit Frequency & Completion Rates ──────────────────
              const Text(
                'Hamlet Visit Completion Rates',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...report.hamletCompletionRates.entries.map((entry) {
                final hamlet = entry.key;
                final rate = entry.value;
                final totalVisits = report.hamletVisitFrequencies[hamlet] ?? 0;
                final color = rate >= 80.0
                    ? Colors.green
                    : (rate >= 60.0 ? Colors.orange : Colors.red);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(hamlet, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '$rate% ($totalVisits visits)',
                            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: rate / 100.0,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),

              // ── 4. Access Barriers History ────────────────────────────────────
              if (report.accessBarriersHistory.isNotEmpty) ...[
                const Text(
                  'Access Barriers History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...report.accessBarriersHistory.map((barrier) => Card(
                      color: Colors.red.shade50,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                        title: Text(barrier, style: const TextStyle(fontSize: 13)),
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              // ── 5. Workload Rebalancing Suggestions ───────────────────────────
              if (report.workloadRebalanceSuggestions.isNotEmpty) ...[
                const Text(
                  'Workload Rebalancing Suggestions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...report.workloadRebalanceSuggestions.map((suggestion) => Card(
                      color: Colors.blue.shade50,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.lightbulb_outline, color: Colors.blue),
                        title: Text(
                          suggestion,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    )),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
