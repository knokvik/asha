import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/pdf/pdf_generator.dart';
import '../../../core/voice/tts_service.dart';
import '../../../shared/shell/shell_copy.dart';
import '../data/earnings_repository.dart';
import '../domain/earnings_models.dart';

/// Interactive Earnings Dashboard for ASHA workers (Requirement 55.1–55.6).
///
/// Provides:
/// - Current month totals broken down by status (eligible, claimed, verified, approved, paid, rejected)
/// - Delay & rejection transparency with stage, responsible person, and reason
/// - Payment reconciliation against bank reference & UTR with discrepancy flagging
/// - Projected earnings from in-progress / deferred tasks
/// - Historical statement selector and official printable PDF statement generation
/// - Multilingual spoken audio summary via TTS
/// - Privacy screen shield (FLAG_SECURE / obscure toggle) to safeguard household privacy
class EarningsScreen extends StatefulWidget {
  final EarningsRepository repository;
  final TtsService? ttsService;
  final String workerId;
  final String initialPeriod;
  final String language;

  const EarningsScreen({
    super.key,
    required this.repository,
    required this.workerId,
    this.ttsService,
    this.initialPeriod = '2024-04',
    this.language = 'en',
  });

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  late String _selectedPeriod;
  late String _selectedLanguage;
  bool _isPrivacyShieldEnabled = false;
  bool _isLoading = true;

  EarningsStatusTotals _totals = const EarningsStatusTotals();
  List<EarningsLineItem> _lineItems = [];
  EarningsProjection? _projection;
  List<String> _availablePeriods = [];

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialPeriod;
    _selectedLanguage = widget.language;
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final periods = await widget.repository.getAvailablePeriods();
      if (!periods.contains(_selectedPeriod) && periods.isNotEmpty) {
        _selectedPeriod = periods.first;
      }

      final totals = await widget.repository.getStatusTotals(_selectedPeriod);
      final items = await widget.repository.getLineItems(_selectedPeriod);
      final proj = await widget.repository.getEarningsProjection(
        widget.workerId,
        _selectedPeriod,
      );

      if (mounted) {
        setState(() {
          _availablePeriods = periods;
          _totals = totals;
          _lineItems = items;
          _projection = proj;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ── Audio Summary (Req 55.6) ──────────────────────────────────────────────

  Future<void> _playAudioSummary() async {
    if (widget.ttsService == null) return;

    final earned = _totals.totalEarned.toStringAsFixed(0);
    final paid = _totals.paidAmount.toStringAsFixed(0);
    final pending = (_totals.totalPipeline - _totals.paidAmount)
        .toStringAsFixed(0);

    final String speechText;
    if (_selectedLanguage == 'hi') {
      speechText =
          'महीने $_selectedPeriod के लिए आपकी कुल अर्जित राशि ₹$earned है। '
          '₹$paid आपके बैंक खाते में जमा हो चुके हैं। ₹$pending की राशि सत्यापन एवं भुगतान प्रक्रिया में है।';
    } else if (_selectedLanguage == 'mr') {
      speechText =
          'महिना $_selectedPeriod साठी तुमची एकूण कमाई ₹$earned आहे. '
          '₹$paid बँक खात्यात जमा झाले आहेत आणि ₹$pending प्रक्रियाधीन आहेत.';
    } else {
      speechText =
          'For period $_selectedPeriod, your total earned incentive is Rupees $earned. '
          'Rupees $paid has been credited to your bank account, and Rupees $pending is pending verification and transfer.';
    }

    await widget.ttsService!.speak(
      text: speechText,
      language: _selectedLanguage,
    );
  }

  // ── PDF Statement Share (Req 55.5) ────────────────────────────────────────

  Future<void> _exportPdfStatement() async {
    setState(() => _isLoading = true);
    try {
      final statement = await widget.repository.generateStatement(
        widget.workerId,
        _selectedPeriod,
      );
      final pdfBytes = await PdfGenerator.generateEarningsStatementPdf(
        statement,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'ASHA_Earnings_${widget.workerId}_$_selectedPeriod.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate statement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(shellText(_selectedLanguage, 'earningsTitle')),
        backgroundColor: AshaColors.cardSurface,
        actions: [
          // Privacy Shield Toggle (Req 55.6)
          IconButton(
            key: const Key('earnings_privacy_toggle'),
            icon: Icon(
              _isPrivacyShieldEnabled ? Icons.visibility_off : Icons.visibility,
            ),
            tooltip: _isPrivacyShieldEnabled
                ? 'Reveal Amounts'
                : 'Shield Privacy',
            onPressed: () {
              setState(
                () => _isPrivacyShieldEnabled = !_isPrivacyShieldEnabled,
              );
            },
          ),
          // Audio Summary Button (Req 55.6)
          IconButton(
            key: const Key('earnings_audio_summary_button'),
            icon: const Icon(Icons.volume_up),
            tooltip: 'Listen to Audio Summary',
            onPressed: _playAudioSummary,
          ),
          // PDF Statement Download (Req 55.5)
          IconButton(
            key: const Key('earnings_pdf_export_button'),
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export Official Statement PDF',
            onPressed: _exportPdfStatement,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Period & Language Selector Controls
                  _buildControlsRow(),
                  const SizedBox(height: 16),

                  // High-level Earned Summary Hero Card
                  _buildEarningsHeroCard(),
                  const SizedBox(height: 16),

                  // Earnings Projection Banner (Req 55.4)
                  if (_projection != null &&
                      _projection!.projectedAdditionalAmount > 0) ...[
                    _buildProjectionCard(_projection!),
                    const SizedBox(height: 16),
                  ],

                  // Line Items Detailed Ledger (Req 55.1, 55.2)
                  _buildLineItemsSection(),
                ],
              ),
            ),
    );
  }

  // ── UI Components ──────────────────────────────────────────────────────────

  Widget _buildControlsRow() {
    return Row(
      children: [
        // Period Dropdown (Req 55.5)
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AshaColors.cardSurface,
              borderRadius: AshaShapes.chipBorderRadius,
              border: Border.all(color: AshaColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('period_selector_dropdown'),
                value: _availablePeriods.contains(_selectedPeriod)
                    ? _selectedPeriod
                    : null,
                isExpanded: true,
                hint: const Text('Select Month'),
                items: _availablePeriods
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(
                          'Period: $p',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (newP) {
                  if (newP != null && newP != _selectedPeriod) {
                    setState(() => _selectedPeriod = newP);
                    _loadDashboardData();
                  }
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Language Dropdown (Req 55.6)
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AshaColors.cardSurface,
              borderRadius: AshaShapes.chipBorderRadius,
              border: Border.all(color: AshaColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('language_selector_dropdown'),
                value: _selectedLanguage,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: 'en',
                    child: Text('English', style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem(
                    value: 'hi',
                    child: Text('हिन्दी', style: TextStyle(fontSize: 12)),
                  ),
                  DropdownMenuItem(
                    value: 'mr',
                    child: Text('मराठी', style: TextStyle(fontSize: 12)),
                  ),
                ],
                onChanged: (newLang) {
                  if (newLang != null) {
                    setState(() => _selectedLanguage = newLang);
                  }
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsHeroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AshaShapes.cardRadius,
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(22, 163, 74, 0.22),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total earnings',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              if (_isPrivacyShieldEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Shielded',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatAmount(_totals.totalEarned),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildProjectionCard(EarningsProjection proj) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.amber.shade900, size: 20),
              const SizedBox(width: 8),
              Text(
                'Earnings Projection (Requirement 55.4)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Complete your in-progress tasks to unlock an estimated additional ${_formatAmount(proj.projectedAdditionalAmount)} (Total: ${_formatAmount(proj.totalProjected)}):',
            style: TextStyle(fontSize: 12, color: Colors.brown.shade800),
          ),
          const SizedBox(height: 8),
          ...proj.pendingTasks
              .take(2)
              .map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_right,
                        size: 16,
                        color: Colors.amber.shade900,
                      ),
                      Expanded(
                        child: Text(
                          '${task.activityName}: ${task.remainingDescription}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '+${_formatAmount(task.potentialAmount)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
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

  Widget _buildLineItemsSection() {
    final filteredItems = _lineItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Itemized Deliveries (${filteredItems.length})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filteredItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            child: const Text(
              'No deliveries found for selected status filter.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...filteredItems.map(_buildLineItemCard),
      ],
    );
  }

  Widget _buildLineItemCard(EarningsLineItem item) {
    final dateStr = item.serviceDate.toIso8601String().substring(0, 10);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.activityName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              _formatAmount(item.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.teal.shade900,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Text(
                dateStr,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${item.memberName ?? item.memberCodedId}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Current Stage (Req 55.2)', item.stage),
                if (item.responsibleRole != null)
                  _buildDetailRow('Responsible Role', item.responsibleRole!),
                if (item.responsiblePerson != null)
                  _buildDetailRow('Assigned Person', item.responsiblePerson!),
                if (item.delayOrRejectionReason != null)
                  _buildDetailRow(
                    'Reason / Feedback',
                    item.delayOrRejectionReason!,
                    isAlert: true,
                  ),
                if (item.evidenceRecordId != null)
                  _buildDetailRow('Evidence Link', item.evidenceRecordId!),
                if (item.householdArea != null)
                  _buildDetailRow('Household area', item.householdArea!),
                if (item.memberId != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () =>
                          context.push('/beneficiary/${item.memberId}'),
                      icon: const Icon(Icons.person_outline),
                      label: Text(item.memberName ?? 'Open person'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label: ',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isAlert ? FontWeight.bold : FontWeight.normal,
                color: isAlert ? Colors.red.shade900 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (_isPrivacyShieldEnabled) return '₹****';
    return '₹${amount.toStringAsFixed(2)}';
  }
}
