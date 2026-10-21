import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/triage/models/models.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/triage_service.dart';

/// Presentation screen for viewing and acting upon a triage evaluation result.
///
/// Implements Requirements 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.9, 46.1, 46.2.
class TriageResultScreen extends ConsumerStatefulWidget {
  final TriageResult initialResult;
  final String? memberId;
  final VoidCallback? onReferralRequested;

  const TriageResultScreen({
    super.key,
    required this.initialResult,
    this.memberId,
    this.onReferralRequested,
  });

  @override
  ConsumerState<TriageResultScreen> createState() => _TriageResultScreenState();
}

class _TriageResultScreenState extends ConsumerState<TriageResultScreen> {
  late TriageResult _result;
  TriageOverride? _override;
  bool _isSpeaking = false;
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  XFile? _triageImage;
  String? _triageAudioPath;
  bool _recordingAttachment = false;
  bool _isSavingEvidence = false;
  String? _attachmentMessage;

  @override
  void initState() {
    super.initState();
    _result = widget.initialResult;

    // Automatic referral trigger if RED (Requirement 8.5)
    if (_result.flag == TriageFlag.red) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.onReferralRequested != null) {
          widget.onReferralRequested!();
        }
      });
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _captureTriageImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 72,
      );
      if (image == null || !mounted) return;
      setState(() {
        _triageImage = image;
        _attachmentMessage =
            'Image captured. It will be compressed before sync.';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _attachmentMessage = 'Could not capture image: $error');
      }
    }
  }

  Future<void> _toggleTriageAudio() async {
    if (_recordingAttachment) {
      final path = await _audioRecorder.stop();
      if (!mounted) return;
      setState(() {
        _recordingAttachment = false;
        _triageAudioPath = path;
        _attachmentMessage = path == null
            ? 'No voice note was captured.'
            : 'Voice note captured. It will be compressed before sync.';
      });
      return;
    }

    try {
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) {
          setState(
            () => _attachmentMessage =
                'Allow microphone access to record a voice note.',
          );
        }
        return;
      }
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/triage_result_${_result.id}.m4a';
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      if (mounted) {
        setState(() {
          _recordingAttachment = true;
          _attachmentMessage = 'Recording voice note… tap again to stop.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _attachmentMessage = 'Could not record audio: $error');
      }
    }
  }

  Future<Map<String, dynamic>> _compressAttachment(
    String path, {
    required String type,
    required String mimeType,
  }) async {
    final raw = await File(path).readAsBytes();
    if (raw.length > 6 * 1024 * 1024) {
      throw StateError(
        'Attachment is larger than 6 MB. Please capture a shorter file.',
      );
    }
    final compressed = GZipEncoder().encode(raw) ?? const <int>[];
    return {
      'type': type,
      'mime_type': mimeType,
      'encoding': 'gzip+base64',
      'original_bytes': raw.length,
      'compressed_bytes': compressed.length,
      'data_base64': base64Encode(compressed),
    };
  }

  Future<void> _sendEvidence() async {
    if (_recordingAttachment) await _toggleTriageAudio();
    if (_triageImage == null && _triageAudioPath == null) {
      setState(
        () => _attachmentMessage =
            'Capture an image or record a voice note first.',
      );
      return;
    }

    setState(() => _isSavingEvidence = true);
    try {
      final queue = await ref.read(syncEngineProvider).fetchQueue(limit: 100);
      dynamic row;
      for (final candidate in queue) {
        if (candidate.targetTable == 'triage_results' &&
            candidate.recordId == _result.id &&
            candidate.syncStatus != 'synced') {
          row = candidate;
          break;
        }
      }
      if (row == null) {
        throw StateError(
          'The triage result is already synced or its queue record is unavailable.',
        );
      }

      final payload = jsonDecode(row.payloadJson) as Map<String, dynamic>;
      final attachments = <Map<String, dynamic>>[];
      final existing = payload['attachments_json'];
      if (existing is String && existing.isNotEmpty) {
        final decoded = jsonDecode(existing);
        if (decoded is List) {
          attachments.addAll(
            decoded.whereType<Map>().map(
              (item) => Map<String, dynamic>.from(item),
            ),
          );
        }
      }
      if (_triageImage != null) {
        attachments.add(
          await _compressAttachment(
            _triageImage!.path,
            type: 'image',
            mimeType: 'image/jpeg',
          ),
        );
      }
      if (_triageAudioPath != null && await File(_triageAudioPath!).exists()) {
        attachments.add(
          await _compressAttachment(
            _triageAudioPath!,
            type: 'audio',
            mimeType: 'audio/mp4',
          ),
        );
      }
      payload['attachments_json'] = jsonEncode(attachments);
      await ref
          .read(syncEngineProvider)
          .updatePendingPayload(
            table: 'triage_results',
            recordId: _result.id,
            payload: payload,
          );
      await ref.read(syncCoordinatorProvider)?.syncNow();

      await _deleteTemporaryFile(_triageImage?.path);
      await _deleteTemporaryFile(_triageAudioPath);
      if (mounted) {
        setState(() {
          _triageImage = null;
          _triageAudioPath = null;
          _attachmentMessage =
              '${attachments.length} compressed attachment(s) queued for server sync.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _attachmentMessage = 'Evidence could not be prepared: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingEvidence = false);
    }
  }

  Future<void> _deleteTemporaryFile(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  Color _flagColor(TriageFlag flag) {
    switch (flag) {
      case TriageFlag.red:
        return const Color(0xFFD32F2F);
      case TriageFlag.yellow:
        return const Color(0xFFF57C00);
      case TriageFlag.green:
        return const Color(0xFF388E3C);
    }
  }

  IconData _flagIcon(TriageFlag flag) {
    switch (flag) {
      case TriageFlag.red:
        return Icons.emergency;
      case TriageFlag.yellow:
        return Icons.warning_amber_rounded;
      case TriageFlag.green:
        return Icons.check_circle_outline;
    }
  }

  String _flagTitle(TriageFlag flag) {
    switch (flag) {
      case TriageFlag.red:
        return 'RED — Refer immediately';
      case TriageFlag.yellow:
        return 'YELLOW — Monitor closely';
      case TriageFlag.green:
        return 'GREEN — Continue home care';
    }
  }

  Future<void> _speakResult() async {
    setState(() => _isSpeaking = true);
    final triageService = ref.read(triageServiceProvider);
    await triageService.speakTriageResult(_result);
    if (mounted) setState(() => _isSpeaking = false);
  }

  void _showOverrideDialog() {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _OverrideSheet(
        originalFlag: _result.flag,
        onSubmit: (overrideFlag, reason, voicePath) async {
          final override = TriageOverride(
            encounterId: _result.encounterId ?? 'enc_${_result.id}',
            originalFlag: _result.flag,
            overrideFlag: overrideFlag,
            reason: reason,
            voiceNotePath: voicePath,
            overridingUserId: 'asha_current',
          );

          final service = ref.read(triageServiceProvider);
          await service.recordOverride(
            triageResultId: _result.id,
            override: override,
          );

          if (mounted) {
            setState(() {
              _override = override;
            });
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Clinical override recorded successfully'),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeFlag = _override != null
        ? _override!.overrideFlag
        : _result.flag;
    final color = _flagColor(activeFlag);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Triage Assessment'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('speak_result_button'),
            icon: Icon(
              _isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
            ),
            tooltip: 'Hear result',
            onPressed: _speakResult,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Prominent Decision Support Disclaimer (Requirement 8.7)
            Container(
              key: const Key('triage_disclaimer_banner'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blueGrey.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      TriageResult.disclaimer,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Main Severity Flag Card
            Card(
              key: const Key('triage_flag_card'),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: color, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(_flagIcon(activeFlag), size: 56, color: color),
                    const SizedBox(height: 12),
                    Text(
                      _flagTitle(activeFlag),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    if (_override != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: Text(
                          'Overridden by ASHA (Engine output: ${_result.flag.label})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reason: "${_override!.reason}"',
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Missing Inputs Escalation Notice (Requirement 8.4)
            if (_result.escalatedForMissingData)
              Container(
                key: const Key('missing_data_escalation_card'),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.report_problem_outlined,
                          color: Colors.amber.shade900,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Severity Escalated for Missing Data',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The flag was elevated by one level because the following required values were not entered:',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._result.missingFields.map(
                      (field) => Text(
                        '• $field',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Contributing Clinical Findings (Requirement 8.2, 8.3)
            const Text(
              'Contributing Findings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_result.findings.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No danger signs or abnormal clinical rules triggered.',
                  ),
                ),
              )
            else
              ..._result.findings.map(
                (f) => Card(
                  key: Key('finding_${f.ruleId}'),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      _flagIcon(f.severity),
                      color: _flagColor(f.severity),
                    ),
                    title: Text(
                      f.findingText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Action: ${f.action.replaceAll('_', ' ')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (f.sourceCitation != null)
                          Text(
                            'Citation: ${f.sourceCitation}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // 5. ML Component Contribution Hook (Requirement 8.9)
            if (_result.mlContribution != null)
              Card(
                key: const Key('ml_contribution_card'),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.purple.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.psychology, color: Colors.purple.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Machine Learning Risk Score (Advisory)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ML Flag: ${_result.mlContribution!.mlFlag.label} (Confidence: ${(_result.mlContribution!.confidenceScore * 100).toStringAsFixed(1)}%)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Note: The ML model can only elevate severity caution, never lower it.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Divider(),
                      const Text(
                        'Contributing Features & Relative Weights:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._result.mlContribution!.featureWeights.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                '${(entry.value * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            Card(
              key: const Key('triage_evidence_panel'),
              color: Colors.blueGrey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add evidence (optional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'At the end of the questions, capture a relevant image or voice note. Files are compressed and added to the encrypted sync queue.',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('triage_result_add_image_button'),
                            onPressed: _isSavingEvidence
                                ? null
                                : _captureTriageImage,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: Text(
                              _triageImage == null
                                  ? 'Capture image'
                                  : 'Image ready',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const Key('triage_result_record_audio_button'),
                            onPressed: _isSavingEvidence
                                ? null
                                : _toggleTriageAudio,
                            icon: Icon(
                              _recordingAttachment
                                  ? Icons.stop
                                  : Icons.mic_none,
                            ),
                            label: Text(
                              _recordingAttachment
                                  ? 'Stop recording'
                                  : (_triageAudioPath == null
                                        ? 'Record audio'
                                        : 'Audio ready'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      key: const Key('triage_result_send_evidence_button'),
                      onPressed: _isSavingEvidence ? null : _sendEvidence,
                      icon: _isSavingEvidence
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Compress and sync evidence'),
                    ),
                    if (_attachmentMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _attachmentMessage!,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 6. Action Buttons: Referral and Override
            if (activeFlag == TriageFlag.red)
              ElevatedButton.icon(
                key: const Key('referral_action_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.forward),
                label: const Text(
                  'Open Urgent Referral Workflow',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  if (widget.onReferralRequested != null) {
                    widget.onReferralRequested!();
                  } else {
                    context.push('/referral/${widget.memberId ?? 'urgent'}');
                  }
                },
              ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              key: const Key('triage_override_button'),
              icon: const Icon(Icons.edit_note),
              label: const Text('Override Triage Result'),
              onPressed: _showOverrideDialog,
            ),
          ],
        ),
      ),
    );
  }
}

class _OverrideSheet extends StatefulWidget {
  final TriageFlag originalFlag;
  final Function(TriageFlag overrideFlag, String reason, String? voicePath)
  onSubmit;

  const _OverrideSheet({required this.originalFlag, required this.onSubmit});

  @override
  State<_OverrideSheet> createState() => _OverrideSheetState();
}

class _OverrideSheetState extends State<_OverrideSheet> {
  late TriageFlag _selectedFlag;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedFlag = widget.originalFlag == TriageFlag.red
        ? TriageFlag.yellow
        : TriageFlag.red;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charCount = _reasonController.text.trim().length;
    final isValid = charCount >= 10 && charCount <= 500;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Clinical Decision Override',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Requirement 8.6: You may override the triage level based on clinical judgment. An explicit reason of 10–500 characters is required.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            'Select Override Flag:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<TriageFlag>(
            segments: const [
              ButtonSegment(value: TriageFlag.green, label: Text('Green')),
              ButtonSegment(value: TriageFlag.yellow, label: Text('Yellow')),
              ButtonSegment(value: TriageFlag.red, label: Text('Red')),
            ],
            selected: {_selectedFlag},
            onSelectionChanged: (set) =>
                setState(() => _selectedFlag = set.first),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('override_reason_field'),
            controller: _reasonController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Clinical Justification (10–500 chars)',
              hintText: 'Explain why the triage level should be changed...',
              border: const OutlineInputBorder(),
              errorText: charCount > 0 && charCount < 10
                  ? 'Must be at least 10 characters (${10 - charCount} more needed)'
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            key: const Key('confirm_override_button'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: isValid
                ? () {
                    widget.onSubmit(
                      _selectedFlag,
                      _reasonController.text.trim(),
                      null,
                    );
                    Navigator.pop(context);
                  }
                : null,
            child: const Text('Confirm Override'),
          ),
        ],
      ),
    );
  }
}
