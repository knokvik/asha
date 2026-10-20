import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/triage/models/models.dart';
import '../data/phc_api_client.dart';
import '../domain/referral_models.dart';
import '../domain/sms_fallback.dart';

/// Screen presenting the scannable offline QR Code and PHC dispatch controls.
class ReferralQrScreen extends StatefulWidget {
  const ReferralQrScreen({
    super.key,
    required this.note,
    this.apiClient,
  });

  final StructuredReferralNote note;
  final PhcApiClient? apiClient;

  @override
  State<ReferralQrScreen> createState() => _ReferralQrScreenState();
}

class _ReferralQrScreenState extends State<ReferralQrScreen> {
  late final PhcApiClient _client;
  bool _isSending = false;
  PhcDispatchResult? _dispatchResult;
  bool _isEnglish = true;

  @override
  void initState() {
    super.initState();
    _client = widget.apiClient ?? PhcApiClient();
  }

  Color _getFlagColor(TriageFlag flag) {
    return switch (flag) {
      TriageFlag.red => const Color(0xFFD32F2F),
      TriageFlag.yellow => const Color(0xFFF57C00),
      TriageFlag.green => const Color(0xFF388E3C),
    };
  }

  Future<void> _handleSendToPhc() async {
    setState(() {
      _isSending = true;
    });

    final res = await _client.sendReferralToPhc(widget.note);

    if (mounted) {
      setState(() {
        _isSending = false;
        _dispatchResult = res;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: res.isQueuedOffline ? Colors.orange.shade800 : Colors.teal.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flagColor = _getFlagColor(widget.note.triageFlag);
    final qrPayload = widget.note.toQrPayload();
    final smsText = SmsFallbackFormatter.formatSms(widget.note);
    final summaryText = widget.note.formatSummary(english: _isEnglish);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PHC Referral & QR Pass'),
        backgroundColor: flagColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: _isEnglish ? 'Switch to Hindi' : 'Switch to English',
            icon: Icon(_isEnglish ? Icons.translate_rounded : Icons.language_rounded),
            onPressed: () => setState(() => _isEnglish = !_isEnglish),
          ),
          IconButton(
            tooltip: 'Copy Referral Note',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () => _copyToClipboard(summaryText, 'Referral note'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Priority Status Banner ──
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: flagColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: flagColor, width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.note.triageFlag == TriageFlag.red
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline_rounded,
                    color: flagColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.note.triageFlag.wireName} PRIORITY REFERRAL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: flagColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.note.primaryReason,
                          style: const TextStyle(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── High-Contrast QR Code Card ──
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: QrImageView(
                        data: qrPayload,
                        version: QrVersions.auto,
                        size: 220,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.note.referralId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Scan with receiving PHC Doctor / Emergency Tablet to instantly import record offline',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Send to PHC Action Button ──
            ElevatedButton.icon(
              key: const Key('send_to_phc_button'),
              onPressed: _isSending ? null : _handleSendToPhc,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isSending
                    ? 'Transmitting Request to PHC...'
                    : 'Send Referral Request to PHC',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            // ── Real-Time Dispatch Status Card ──
            if (_dispatchResult != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _dispatchResult!.isQueuedOffline
                      ? Colors.orange.shade50
                      : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _dispatchResult!.isQueuedOffline
                        ? Colors.orange.shade400
                        : Colors.teal.shade400,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _dispatchResult!.isQueuedOffline
                          ? Icons.cloud_off_rounded
                          : Icons.check_circle_rounded,
                      color: _dispatchResult!.isQueuedOffline
                          ? Colors.orange.shade800
                          : Colors.teal.shade800,
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dispatchResult!.message,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _dispatchResult!.isQueuedOffline
                              ? Colors.orange.shade900
                              : Colors.teal.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Key Referral Details ──
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Referral Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 20),
                    _buildRow('Patient Name', '${widget.note.patient.name} (${widget.note.patient.sex})'),
                    _buildRow('Age', widget.note.patient.formattedAge),
                    _buildRow('Village', widget.note.patient.village ?? ''),
                    if (widget.note.patient.abhaId != null && widget.note.patient.abhaId!.isNotEmpty)
                      _buildRow('ABHA ID', widget.note.patient.abhaId!),
                    _buildRow('Destination', widget.note.destinationFacility?.name ?? 'Nearest PHC'),
                    _buildRow('Transport', widget.note.transportArranged ?? 'Arranging...'),
                    _buildRow('Referring ASHA', '${widget.note.asha.name} (${widget.note.asha.phone})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── SMS Quick Fallback (<=160 chars) ──
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '2G / SMS Fallback',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${smsText.length}/160 chars',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        smsText,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.sms_rounded, size: 18),
                      label: const Text('Copy SMS Text to Send'),
                      onPressed: () => _copyToClipboard(smsText, 'SMS text'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
