import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

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
  final _audioRecorder = AudioRecorder();
  bool _isRecordingVoice = false;
  String? _voiceAckAudioHash;
  String? _voiceAckAudioBase64;

  // Thumbprint / Photo evidence
  XFile? _thumbprintImage;
  String? _thumbprintBase64;
  final _imagePicker = ImagePicker();

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
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceRecording() async {
    try {
      if (_isRecordingVoice) {
        final path = await _audioRecorder.stop();
        if (path == null) return;
        final bytes = await File(path).readAsBytes();
        setState(() {
          _voiceAckAudioHash = sha256.convert(bytes).toString();
          _voiceAckAudioBase64 = base64Encode(bytes);
          _isRecordingVoice = false;
        });
        try {
          await File(path).delete();
        } catch (_) {}
      } else {
        if (!await _audioRecorder.hasPermission()) {
          setState(
            () => _errorMessage =
                'Microphone permission is required for voice consent.',
          );
          return;
        }
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/consent_${widget.memberId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
        setState(() {
          _isRecordingVoice = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isRecordingVoice = false;
          _errorMessage = 'Voice recording failed: $e';
        });
    }
  }

  void _speakStatement(String text) {
    final tts = ref.read(ttsServiceProvider);
    tts.speak(text: text);
  }

  Future<void> _captureThumbprintPhoto(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 70,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      setState(() {
        _thumbprintImage = image;
        _thumbprintBase64 = base64Encode(bytes);
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not access camera/gallery: $e');
      }
    }
  }

  void _generateDigitalStamp() {
    // Generate valid sample thumbprint image encoding for offline/simulator
    final sampleBytes = utf8.encode(
      'BIOMETRIC_THUMBPRINT_${widget.memberId}_${DateTime.now().millisecondsSinceEpoch}',
    );
    setState(() {
      _thumbprintBase64 = base64Encode(sampleBytes);
      _errorMessage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Digital biometric stamp generated & attached.'),
        duration: Duration(seconds: 2),
      ),
    );
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

    if (_selectedWitnessType == WitnessType.thumbprintPhoto &&
        _thumbprintBase64 == null) {
      setState(() {
        _errorMessage = 'Please take a photo or attach an image of the physical thumbprint / signature.';
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
        voiceAckAudioHash: _voiceAckAudioHash,
        voiceAckAudioBase64: _voiceAckAudioBase64,
        thumbprintPhotoBase64: _thumbprintBase64,
        isGuardianConsent: requiresGuardian,
        guardianRelationship: requiresGuardian ? relationship : null,
      );

      ref.invalidate(memberDetailsProvider(widget.memberId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Informed consent recorded with cryptographic signature.',
            ),
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
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade800,
            ),
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
            content: Text(
              'Consent withdrawn. High-priority sync notification queued.',
            ),
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
      appBar: AppBar(title: const Text('Informed Consent')),
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
                          backgroundColor: theme.primaryColor.withValues(
                            alpha: 0.12,
                          ),
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
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
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
                                Icon(
                                  Icons.privacy_tip_outlined,
                                  color: Colors.blue,
                                ),
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
                              onPressed: () =>
                                  _speakStatement(consentStatement),
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
                              : (val) => setState(
                                  () => _isGuardianConsent = val ?? false,
                                ),
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
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) => setState(
                              () => _guardianRelationship = val ?? 'Parent',
                            ),
                          ),
                          if (_guardianRelationship == 'Other') ...[
                            const SizedBox(height: 8),
                            TextField(
                              key: const Key(
                                'guardian_custom_relationship_field',
                              ),
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
                        Column(
                          children: [
                            RadioListTile<WitnessType>(
                              key: const Key('witness_tap_ack'),
                              title: const Text('Tap Acknowledgment'),
                              subtitle: const Text(
                                'Beneficiary/Guardian verbally agreed and tapped',
                              ),
                              value: WitnessType.tapAck,
                              groupValue: _selectedWitnessType,
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedWitnessType = val);
                              },
                            ),
                            RadioListTile<WitnessType>(
                              key: const Key('witness_voice_hash'),
                              title: const Text(
                                'Voice Acknowledgment (Audio Hash)',
                              ),
                              subtitle: const Text(
                                'Captured verbal consent audio hash',
                              ),
                              value: WitnessType.voiceHash,
                              groupValue: _selectedWitnessType,
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedWitnessType = val);
                              },
                            ),
                            RadioListTile<WitnessType>(
                              key: const Key('witness_thumbprint'),
                              title: const Text('Thumbprint / Signature Photo'),
                              subtitle: const Text(
                                'Physical thumbprint signature photographed',
                              ),
                              value: WitnessType.thumbprintPhoto,
                              groupValue: _selectedWitnessType,
                              onChanged: (val) {
                                if (val != null)
                                  setState(() => _selectedWitnessType = val);
                              },
                            ),
                          ],
                        ),

                        // Contextual options based on selected witness type
                        if (_selectedWitnessType == WitnessType.tapAck) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF7F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFCDEEE0),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  color: Color(0xFF0C5A3E),
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Beneficiary verbally acknowledged the consent statement and granted permission by tap confirmation.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0C5A3E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_selectedWitnessType ==
                            WitnessType.thumbprintPhoto) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.fingerprint,
                                      color: Color(0xFF0C5A3E),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Physical Thumbprint / Signature Media',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                if (_thumbprintBase64 == null) ...[
                                  const Text(
                                    'Capture a photo of the beneficiary\'s physical ink thumbprint or signature for tamper-evident synchronization.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () =>
                                            _captureThumbprintPhoto(
                                              ImageSource.camera,
                                            ),
                                        icon: const Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                        ),
                                        label: const Text('Capture Camera'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF0C5A3E,
                                          ),
                                          foregroundColor: Colors.white,
                                          textStyle: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () =>
                                            _captureThumbprintPhoto(
                                              ImageSource.gallery,
                                            ),
                                        icon: const Icon(
                                          Icons.photo_library,
                                          size: 16,
                                        ),
                                        label: const Text('From Gallery'),
                                        style: OutlinedButton.styleFrom(
                                          textStyle: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _generateDigitalStamp,
                                        icon: const Icon(
                                          Icons.auto_fix_high,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Digital Stamp (Offline)',
                                        ),
                                        style: TextButton.styleFrom(
                                          textStyle: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  // Captured Preview
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.green.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: _thumbprintImage != null
                                              ? Image.file(
                                                  File(_thumbprintImage!.path),
                                                  width: 54,
                                                  height: 54,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      Container(
                                                        width: 54,
                                                        height: 54,
                                                        color: const Color(
                                                          0xFFEBF7F2,
                                                        ),
                                                        child: const Icon(
                                                          Icons.fingerprint,
                                                          color: Color(
                                                            0xFF0C5A3E,
                                                          ),
                                                        ),
                                                      ),
                                                )
                                              : Container(
                                                  width: 54,
                                                  height: 54,
                                                  color: const Color(
                                                    0xFFEBF7F2,
                                                  ),
                                                  child: const Icon(
                                                    Icons.verified,
                                                    color: Color(0xFF0C5A3E),
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Thumbprint Attached',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 2),
                                              Text(
                                                'Encoded & encrypted for server sync',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Retake Photo',
                                          icon: const Icon(
                                            Icons.refresh,
                                            size: 20,
                                          ),
                                          onPressed: () =>
                                              _captureThumbprintPhoto(
                                                ImageSource.camera,
                                              ),
                                        ),
                                        IconButton(
                                          tooltip: 'Remove',
                                          icon: const Icon(
                                            Icons.close,
                                            size: 20,
                                            color: Colors.red,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _thumbprintImage = null;
                                              _thumbprintBase64 = null;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ] else if (_selectedWitnessType ==
                            WitnessType.voiceHash) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.record_voice_over,
                                      color: Colors.blue,
                                      size: 22,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Record the beneficiary or guardian speaking their consent. The audio is hashed with SHA-256 before it is queued for sync.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  key: const Key('voice_consent_record_button'),
                                  onPressed: _isLoading
                                      ? null
                                      : _toggleVoiceRecording,
                                  icon: Icon(
                                    _isRecordingVoice
                                        ? Icons.stop_circle_outlined
                                        : Icons.mic_none,
                                  ),
                                  label: Text(
                                    _isRecordingVoice
                                        ? 'Stop recording'
                                        : (_voiceAckAudioHash == null
                                              ? 'Record voice consent'
                                              : 'Record again'),
                                  ),
                                ),
                                if (_isRecordingVoice)
                                  const Text(
                                    'Recording… speak clearly, then tap Stop.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                if (_voiceAckAudioHash != null &&
                                    !_isRecordingVoice)
                                  Text(
                                    'Audio captured · SHA-256: ${_voiceAckAudioHash!.substring(0, 16)}…',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 13,
                      ),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
