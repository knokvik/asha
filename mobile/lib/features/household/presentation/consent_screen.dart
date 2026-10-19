import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/voice/tts_service.dart';
import '../domain/consent_service.dart';
import 'household_providers.dart';

/// Screen presenting the plain-language informed consent statement, audio read-aloud,
/// guardian consent branch for minors/incapacitated persons, and consent actions.
///
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5
class ConsentScreen extends ConsumerStatefulWidget {
  final String memberId;
  final String ashaId;

  const ConsentScreen({
    super.key,
    required this.memberId,
    this.ashaId = 'asha_worker_1',
  });

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  WitnessType _selectedWitnessType = WitnessType.tapAck;
  bool _isGuardianConsent = false;
  String _guardianRelationship = 'Parent';
  final _guardianRelationshipController = TextEditingController();
  final _withdrawalReasonController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _commonRelationships = [
    'Parent',
    'Mother',
    'Father',
    'Spouse',
    'Grandparent',
    'Legal Guardian',
    'Sibling',
    'Other',
  ];

  @override
  void dispose() {
    _guardianRelationshipController.dispose();
    _withdrawalReasonController.dispose();
    super.dispose();
  }

  void _speakStatement(String text) {
    final tts = ref.read(ttsServiceProvider);
    tts.speak(text: text);
  }

  Future<void> _handleGrantConsent(Member member) async {
    final isMinor = ConsentService.isMemberMinor(member);
    final requiresGuardian = _isGuardianConsent || isMinor;
    final relationship = _guardianRelationship == 'Other'
        ? _guardianRelationshipController.text.trim()
        : _guardianRelationship;

    if (requiresGuardian && relationship.isEmpty) {
      setState(() {
        _errorMessage = 'Guardian relationship is required for minor or incapacitated consent.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final consentService = ref.read(consentServiceProvider);
      await consentService.grantConsent(
        memberId: member.id,
        ashaId: widget.ashaId,
        witnessType: _selectedWitnessType,
        isGuardianConsent: requiresGuardian,
        guardianRelationship: requiresGuardian ? relationship : null,
      );

      ref.invalidate(memberDetailsProvider(widget.memberId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Informed consent recorded with cryptographic signature.'),
            backgroundColor: Colors.green,
          ),
        );
        if (context.canPop()) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDeclineConsent(Member member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Full Consent?'),
        content: const Text(
          'Declining consent will place this beneficiary into Emergency-Only Mode. '
          'You may still perform emergency triage and referrals, but longitudinal tracking '
          'and non-emergency data sharing will be restricted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Emergency-Only Mode'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final consentService = ref.read(consentServiceProvider);
      await consentService.declineConsent(
        memberId: member.id,
        ashaId: widget.ashaId,
      );

      ref.invalidate(memberDetailsProvider(widget.memberId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beneficiary set to Emergency-Only Mode.'),
            backgroundColor: Colors.orange,
          ),
        );
        if (context.canPop()) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleWithdrawConsent(Member member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Withdraw Consent?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Withdrawal will immediately stop optional data sharing and flag the record. '
              'Emergency care and essential health services remain guaranteed.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _withdrawalReasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for withdrawal (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Withdraw Consent'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final consentService = ref.read(consentServiceProvider);
      await consentService.withdrawConsent(
        memberId: member.id,
        reason: _withdrawalReasonController.text.trim().isNotEmpty
            ? _withdrawalReasonController.text.trim()
            : 'Beneficiary requested withdrawal',
        ashaId: widget.ashaId,
      );

      ref.invalidate(memberDetailsProvider(widget.memberId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consent withdrawn. High-priority sync notification queued.'),
            backgroundColor: Colors.red,
          ),
        );
        if (context.canPop()) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final memberAsync = ref.watch(memberDetailsProvider(widget.memberId));
    final consentStatement = ConsentTextProvider.getPlainLanguageStatement();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informed Consent'),
      ),
      body: memberAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (member) {
          if (member == null) {
            return const Center(child: Text('Beneficiary not found'));
          }

          final isMinor = ConsentService.isMemberMinor(member);
          final isAlreadyGiven = member.consentStatus == 'given';
          final isDeclined = member.consentStatus == 'declined';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Beneficiary Profile Header ──────────────────────────────
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: theme.primaryColor.withValues(alpha: 0.12),
                          child: Icon(
                            member.sex == 'F' ? Icons.face_3 : Icons.face,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${member.sex} • Status: ${member.consentStatus.toUpperCase()}',
                                style: TextStyle(
                                  color: isAlreadyGiven
                                      ? Colors.green.shade800
                                      : isDeclined
                                          ? Colors.orange.shade800
                                          : Colors.grey.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Minor / Incapacitated Warning Banner ────────────────────
                if (isMinor)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.child_care, color: Colors.blue.shade800),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Beneficiary is under 18 years old. Consent must be provided by a parent or legal guardian.',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isMinor) const SizedBox(height: 16),

                // ── Plain-Language Consent Card ─────────────────────────────
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.privacy_tip_outlined, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Consent Statement',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton.filledTonal(
                              key: const Key('read_aloud_consent_button'),
                              icon: const Icon(Icons.volume_up),
                              tooltip: 'Read Aloud (TTS)',
                              onPressed: () => _speakStatement(consentStatement),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          consentStatement,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Version: ${ConsentTextProvider.currentVersion} • Tamper-Evident SHA-256 Enabled',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Guardian Consent Branch ─────────────────────────────────
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Guardian Consent Branch',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Check if consent is provided by a parent, legal guardian, or caregiver',
                            style: TextStyle(fontSize: 12),
                          ),
                          value: isMinor || _isGuardianConsent,
                          onChanged: isMinor
                              ? null // Always required for minors
                              : (val) => setState(() => _isGuardianConsent = val ?? false),
                        ),
                        if (isMinor || _isGuardianConsent) ...[
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            key: const Key('guardian_relationship_dropdown'),
                            initialValue: _guardianRelationship,
                            decoration: const InputDecoration(
                              labelText: 'Relationship to Beneficiary',
                              border: OutlineInputBorder(),
                            ),
                            items: _commonRelationships
                                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _guardianRelationship = val ?? 'Parent'),
                          ),
                          if (_guardianRelationship == 'Other') ...[
                            const SizedBox(height: 8),
                            TextField(
                              key: const Key('guardian_custom_relationship_field'),
                              controller: _guardianRelationshipController,
                              decoration: const InputDecoration(
                                labelText: 'Specify Relationship',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Witness & Signature Type ────────────────────────────────
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Witness Acknowledgment Mode',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        RadioGroup<WitnessType>(
                          groupValue: _selectedWitnessType,
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedWitnessType = val);
                          },
                          child: Column(
                            children: [
                              RadioListTile<WitnessType>(
                                key: const Key('witness_tap_ack'),
                                title: const Text('Tap Acknowledgment'),
                                subtitle: const Text('Beneficiary/Guardian verbally agreed and tapped'),
                                value: WitnessType.tapAck,
                              ),
                              RadioListTile<WitnessType>(
                                key: const Key('witness_voice_hash'),
                                title: const Text('Voice Acknowledgment (Audio Hash)'),
                                subtitle: const Text('Captured verbal consent audio hash'),
                                value: WitnessType.voiceHash,
                              ),
                              RadioListTile<WitnessType>(
                                key: const Key('witness_thumbprint'),
                                title: const Text('Thumbprint Photo'),
                                subtitle: const Text('Physical thumbprint signature photographed'),
                                value: WitnessType.thumbprintPhoto,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 16),

                // ── Action Buttons ──────────────────────────────────────────
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        key: const Key('grant_consent_button'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _handleGrantConsent(member),
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          isAlreadyGiven
                              ? 'Re-Confirm / Update Consent'
                              : 'Grant Informed Consent',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const Key('decline_consent_button'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Colors.orange.shade800,
                          side: BorderSide(color: Colors.orange.shade800),
                        ),
                        onPressed: () => _handleDeclineConsent(member),
                        icon: const Icon(Icons.warning_amber),
                        label: const Text('Decline (Emergency Care Only)'),
                      ),
                      if (isAlreadyGiven) ...[
                        const SizedBox(height: 10),
                        TextButton.icon(
                          key: const Key('withdraw_consent_button'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade800,
                          ),
                          onPressed: () => _handleWithdrawConsent(member),
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Withdraw Consent'),
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
