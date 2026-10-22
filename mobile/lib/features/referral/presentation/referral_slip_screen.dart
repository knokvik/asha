import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/database/app_database.dart' hide TriageResult;
import '../../../core/pdf/pdf_generator.dart';
import '../../../core/triage/models/models.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/referral_repository.dart';
import '../domain/offline_referral_router.dart';
import '../domain/facility_matcher.dart';
import '../domain/referral_models.dart';
import '../domain/referral_note_generator.dart';
import '../domain/sms_fallback.dart';

/// Screen presenting the clinical referral slip with offline facility matching,
/// emergency dialer, bilingual toggle, print/PDF rendering, QR code, and SMS sharing.
///
/// Implements Requirements 10.1, 10.2, 10.3, 10.7, 10.8.
class ReferralSlipScreen extends ConsumerStatefulWidget {
  final TriageResult? triageResult;
  final Member? member;
  final String? memberId;
  final Household? household;
  final User? ashaUser;
  final Map<String, dynamic>? rawVitals;

  const ReferralSlipScreen({
    super.key,
    this.triageResult,
    this.member,
    this.memberId,
    this.household,
    this.ashaUser,
    this.rawVitals,
  });

  @override
  ConsumerState<ReferralSlipScreen> createState() => _ReferralSlipScreenState();
}

class _ReferralSlipScreenState extends ConsumerState<ReferralSlipScreen> {
  final bool _useEnglish = true;
  bool _isLoading = true;
  List<FacilityInfo> _candidateFacilities = [];
  FacilityRoutePlan? _routingPlan;
  FacilityInfo? _selectedFacility;
  String _selectedTransport = '108 — National Emergency Ambulance';
  bool _isSaving = false;
  ReferralRecord? _savedRecord;

  Member? _activeMember;
  TriageResult? _activeTriageResult;
  StructuredReferralNote? _note;

  @override
  void initState() {
    super.initState();
    _loadDataAndFacilities();
  }

  Future<void> _loadDataAndFacilities() async {
    setState(() => _isLoading = true);
    final db = ref.read(appDatabaseProvider);

    Member? member = widget.member;
    TriageResult? result = widget.triageResult;

    if (member == null && widget.memberId != null) {
      member = await (db.select(
        db.members,
      )..where((t) => t.id.equals(widget.memberId!))).getSingleOrNull();
    }
    member ??= Member(
      id: widget.memberId ?? 'unregistered_patient',
      householdId: 'hh_emergency',
      name: 'Emergency Referral Subject',
      sex: 'U',
      isDobApprox: true,
      syncStatus: 'pending',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      createdBy: 'asha_system',
      lifecycleStatus: 'active',
      consentStatus: 'emergency_only',
    );

    result ??= TriageResult(
      id: 'res_emergency',
      flag: TriageFlag.red,
      ruleFlag: TriageFlag.red,
      ruleVersionId: '1.0.0',
      evaluatedAt: DateTime.now(),
      findings: const [
        TriageFinding(
          ruleId: 'DANGER_SIGN_REFERRAL',
          severity: TriageFlag.red,
          findingText: 'Identified general danger sign — urgent facility transfer required',
          action: 'REFER_IMMEDIATELY',
          triggeringValues: {},
        ),
      ],
    );

    _activeMember = member;
    _activeTriageResult = result;

    try {
      final rows = await db.select(db.facilityDirectory).get();
      final routingRequest = OfflineRoutingRequest.fromTriageInputs(
        TriageInputs(values: widget.rawVitals ?? const <String, dynamic>{}),
        triageFlag: result.flag,
      );
      final routingPlan = OfflineReferralRouter.plan(
        allFacilities: rows,
        request: routingRequest,
        district: widget.ashaUser?.areaDistrict,
      );
      final matched = routingPlan.destinations
          .map((item) => item.facility)
          .toList();

      if (mounted) {
        setState(() {
          _candidateFacilities = matched;
          _routingPlan = routingPlan;
          if (matched.isNotEmpty) {
            _selectedFacility = matched.first;
          }
          _initNote();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        _initNote();
        setState(() => _isLoading = false);
      }
    }
  }

  void _initNote() {
    if (_activeMember == null || _activeTriageResult == null) return;
    _note = ReferralNoteGenerator.generate(
      triageResult: _activeTriageResult!,
      member: _activeMember!,
      household: widget.household,
      ashaUser: widget.ashaUser,
      destinationFacility: _selectedFacility,
      transportArranged: _selectedTransport,
      rawVitals: widget.rawVitals,
    );
  }

  Color get _flagColor {
    switch (_activeTriageResult?.flag ?? TriageFlag.red) {
      case TriageFlag.red:
        return const Color(0xFFD32F2F);
      case TriageFlag.yellow:
        return const Color(0xFFF57C00);
      case TriageFlag.green:
        return const Color(0xFF388E3C);
    }
  }

  Future<void> _saveReferral() async {
    if (_note == null) return;
    if (_savedRecord != null) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(referralRepositoryProvider);
      final pdfBytes = await PdfGenerator.generateReferralPdf(
        _note!,
        thermalLayout: false,
      );
      final pdfFile = await PdfGenerator.savePdfToFile(
        pdfBytes,
        _note!.referralId,
      );

      final record = await repo.createReferral(
        note: _note!,
        pdfPath: pdfFile.path,
        transportArranged: _selectedTransport,
      );
      await repo.updateStatus(
        referralId: record.id,
        newStatus: ReferralStatus.enRoute,
      );
      final dispatched = await repo.getReferral(record.id) ?? record;

      if (mounted) {
        setState(() {
          _savedRecord = dispatched;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Referral confirmed and dispatched. Sync queued.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save referral: $e')));
      }
    }
  }

  Future<void> _launchPhone(String number, String label) async {
    final uri = Uri.parse('tel:${number.replaceAll(RegExp(r'[^0-9+]'), '')}');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open phone dialler for $label.')),
      );
    }
  }

  Future<void> _sendSms() async {
    if (_note == null) return;
    final smsText = SmsFallbackFormatter.formatSms(_note!);
    final uri = Uri(
      scheme: 'sms',
      queryParameters: <String, String>{'body': smsText},
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) _showSmsDialog();
  }

  void _showQrDialog() {
    if (_note == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Referral QR Code'),
        content: SizedBox(
          width: 260,
          height: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                key: const Key('referral_qr_view'),
                data: _note!.toQrPayload(),
                version: QrVersions.auto,
                size: 220.0,
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan at receiving facility dashboard or tablet for instant registration',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSmsDialog() {
    if (_note == null) return;
    final smsText = SmsFallbackFormatter.formatSms(_note!);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency SMS Fallback'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Length: ${smsText.length}/160 characters (1 standard SMS PDU)',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                smsText,
                key: const Key('sms_preview_text'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _printPdf({bool thermal = false}) async {
    if (_note == null) return;
    final bytes = await PdfGenerator.generateReferralPdf(
      _note!,
      thermalLayout: thermal,
    );
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading || _note == null || _activeTriageResult == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Referral ticket',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
          backgroundColor: _flagColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final note = _note!;
    final triageResult = _activeTriageResult!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Referral ticket',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        backgroundColor: _flagColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('referral_qr_button'),
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'Show QR Code',
            onPressed: _showQrDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTicketCard(note, triageResult),
            const SizedBox(height: 16),

            // 2. Patient Demographics Summary Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Demographics',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    Text(
                      'Name: ${note.patient.name} (${note.patient.formattedAge}, ${note.patient.sex})',
                    ),
                    if (note.patient.abhaId != null &&
                        note.patient.abhaId!.isNotEmpty)
                      Text('ABHA ID: ${note.patient.abhaId}'),
                    Text(
                      'Village: ${note.patient.village ?? "Community"} (${note.patient.hamlet ?? "Main"})',
                    ),
                    if (note.patient.contactPhone != null)
                      Text('Family Phone: ${note.patient.contactPhone}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Offline Facility Matching (Requirement 10.3, 10.5)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Destination Facility',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Chip(
                          label: Text(
                            'Offline Directory',
                            style: TextStyle(fontSize: 10),
                          ),
                          backgroundColor: Color(0xFFE8F5E9),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_candidateFacilities.isEmpty)
                      Text(
                        _routingPlan?.warnings.isNotEmpty == true
                            ? _routingPlan!.warnings.first
                            : 'No designated facilities found in local directory.',
                        style: const TextStyle(color: Colors.red),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_routingPlan != null) ...[
                            Text(
                              _routingPlan!.rationale,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          DropdownButtonFormField<FacilityInfo>(
                            key: const Key('facility_dropdown'),
                            initialValue: _selectedFacility,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Select Receiving Facility',
                            ),
                            items: _candidateFacilities.map((f) {
                              final dist = f.distanceKm != null
                                  ? ' (${f.distanceKm} km)'
                                  : '';
                              return DropdownMenuItem(
                                value: f,
                                child: Text(
                                  '${f.name} — ${f.level.value}$dist',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedFacility = val;
                                _initNote();
                              });
                            },
                          ),
                        ],
                      ),
                    if (_routingPlan?.warnings.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        _routingPlan!.warnings.join(' '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ],
                    if (_selectedFacility != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Care Tier: ${_selectedFacility!.level.displayName}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (_selectedFacility!.contactPhone != null)
                        Text('Phone: ${_selectedFacility!.contactPhone}'),
                      if (_selectedFacility!.services.isNotEmpty)
                        Text(
                          'Services: ${_selectedFacility!.services.join(", ")}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Transport Selection & One-Tap Emergency Dial (Requirement 10.8)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Transit & Dial Actions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: const Key('transport_dropdown'),
                      initialValue: _selectedTransport,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Arranged Transport',
                      ),
                      items:
                          FacilityMatcher.getTransportOptions(
                            triageResult.flag,
                          ).map((t) {
                            return DropdownMenuItem(value: t, child: Text(t));
                          }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedTransport = val;
                            _initNote();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          key: const Key('dial_108_button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _launchPhone('108', '108 Ambulance'),
                          icon: const Icon(Icons.emergency),
                          label: const Text('Call 108'),
                        ),
                        ElevatedButton.icon(
                          key: const Key('dial_102_button'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () =>
                              _launchPhone('102', '102 Janani Shishu Vahan'),
                          icon: const Icon(Icons.local_hospital),
                          label: const Text('Call 102'),
                        ),
                        if (_selectedFacility?.contactPhone != null)
                          OutlinedButton.icon(
                            key: const Key('dial_facility_button'),
                            onPressed: () => _launchPhone(
                              _selectedFacility!.contactPhone!,
                              'the receiving facility',
                            ),
                            icon: const Icon(Icons.phone),
                            label: const Text('Call Facility'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5. Formatted Note Summary (Doctor Readout < 30s)
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Structured Medical Summary (< 30s Readout)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blueGrey.shade200),
                      ),
                      child: Text(
                        note.formatSummary(english: _useEnglish),
                        key: const Key('formatted_note_summary_text'),
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 6. Share & Print Output Actions (Requirement 10.2)
            LayoutBuilder(
              builder: (context, constraints) {
                final buttonWidth = (constraints.maxWidth - 16) / 3;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      child: OutlinedButton.icon(
                        key: const Key('sms_share_button'),
                        onPressed: _sendSms,
                        icon: const Icon(Icons.sms),
                        label: const Text('SMS'),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: OutlinedButton.icon(
                        key: const Key('thermal_print_button'),
                        onPressed: () => _printPdf(thermal: true),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Thermal'),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: OutlinedButton.icon(
                        key: const Key('standard_pdf_button'),
                        onPressed: () => _printPdf(thermal: false),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('A4 PDF'),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // 7. Complete & Dispatch Referral
            ElevatedButton(
              key: const Key('complete_referral_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _flagColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isSaving || _savedRecord != null
                  ? null
                  : _saveReferral,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _savedRecord != null
                          ? 'Referral Dispatched (ID: ${_savedRecord!.id})'
                          : 'Confirm & Dispatch Referral',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketCard(
    StructuredReferralNote note,
    TriageResult triageResult,
  ) {
    final status = _savedRecord?.status ?? 'draft';
    final statusLabel = switch (status) {
      'en_route' => 'Dispatched · syncing with PHC',
      'arrived' => 'Received at facility',
      'outcome_recorded' => 'Outcome recorded',
      'created' => 'Queued for PHC sync',
      _ => 'Ready to send',
    };
    return Container(
      key: const Key('referral_ticket_card'),
      decoration: BoxDecoration(
        color: AshaColors.cardSurface,
        borderRadius: AshaShapes.cardRadius,
        border: Border.all(color: _flagColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AshaShapes.cardRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: _flagColor.withValues(alpha: 0.1),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _flagColor,
                    foregroundColor: Colors.white,
                    child: Icon(
                      triageResult.flag == TriageFlag.red
                          ? Icons.priority_high_rounded
                          : Icons.health_and_safety_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${triageResult.flag.label} referral',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _flagColor,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          statusLabel,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_rounded, color: AshaColors.primary),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ticketValue('PATIENT', note.patient.name),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: _ticketValue(
                          'TICKET ID',
                          note.referralId,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ticketChip('Age · ${note.patient.formattedAge}'),
                      _ticketChip('Location · ${note.patient.village ?? 'Community'}'),
                      _ticketChip('Sync · ${_savedRecord?.syncStatus ?? 'pending'}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(note.primaryReason, style: AshaTypography.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ticketValue(String label, String value, {bool alignEnd = false}) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: AshaTypography.subtitleSmall),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: AshaTypography.cardTitle,
        ),
      ],
    );
  }

  Widget _ticketChip(String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 230),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AshaColors.surfaceMuted,
        borderRadius: AshaShapes.chipBorderRadius,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AshaTypography.subtitleSmall.copyWith(
          color: AshaColors.primaryDark,
        ),
      ),
    );
  }
}
