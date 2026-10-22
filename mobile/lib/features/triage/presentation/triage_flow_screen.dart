import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:record/record.dart';
import 'package:triage/triage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/l10n/language_selector_dialog.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/triage/models/age_band.dart';
import '../../../core/voice/tts_service.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/adaptive_session.dart';
import 'language_bridge_screen.dart';

String _triageCopy(String language, String key) {
  const copy = <String, Map<String, String>>{
    'en': {
      'triage': 'Triage',
      'referralTicket': 'Referral ticket',
      'speakerLanguage': 'Speaker language',
      'question': 'Question',
      'of': 'of',
      'patientName': 'Patient name',
      'age': 'Age',
      'ageHint': 'Enter months for a child or years for an older patient',
      'ageUnit': 'Age unit',
      'months': 'Months',
      'years': 'Years',
      'sexContext': 'Sex / patient context',
      'unknown': 'Unknown / prefer not to say',
      'female': 'Female',
      'male': 'Male',
      'other': 'Other',
      'location': 'Village / location',
      'locationHint': 'Where is the child or patient located?',
      'details': 'Other details (optional)',
      'detailsHint': 'Add any context to carry with this triage case.',
      'nearbyIllness': 'Nearby illness',
      'reportedContext': 'Reported context to consider',
      'contextFilters': 'Clinical context filters',
      'contextFiltersSub': 'Select nearby illness and reported symptoms',
      'startQuestions': 'Start questions',
      'commonQuestion': 'Common question',
      'adaptive': 'Adaptive',
      'speakIn': 'Speak in',
      'nextQuestion': 'Next question',
      'previousQuestion': 'Previous question',
      'reviewHint': 'Tap any question to review it',
      'yes': 'Yes',
      'no': 'No',
      'notSure': 'Not sure',
      'enterValue': 'Enter value',
      'saveValue': 'Save value',
      'enterResponse': 'Enter response',
      'saveResponse': 'Save response',
      'notSureCheck': 'Not sure / cannot check',
      'assessmentComplete': 'Assessment complete',
    },
    'hi': {
      'triage': 'ट्राइएज',
      'referralTicket': 'रेफरल टिकट',
      'speakerLanguage': 'बोलने की भाषा',
      'question': 'प्रश्न',
      'of': 'में से',
      'patientName': 'मरीज़ का नाम',
      'age': 'उम्र',
      'ageHint': 'बच्चे के लिए महीने या बड़े मरीज़ के लिए वर्ष दर्ज करें',
      'ageUnit': 'उम्र की इकाई',
      'months': 'महीने',
      'years': 'वर्ष',
      'sexContext': 'लिंग / मरीज़ का संदर्भ',
      'unknown': 'अज्ञात / बताना नहीं चाहते',
      'female': 'महिला',
      'male': 'पुरुष',
      'other': 'अन्य',
      'location': 'गाँव / स्थान',
      'locationHint': 'बच्चा या मरीज़ कहाँ रहता है?',
      'details': 'अन्य विवरण (वैकल्पिक)',
      'detailsHint': 'इस ट्राइएज केस के लिए कोई अतिरिक्त जानकारी दें।',
      'nearbyIllness': 'आस-पास की बीमारी',
      'reportedContext': 'ध्यान देने योग्य संदर्भ',
      'contextFilters': 'क्लिनिकल संदर्भ फ़िल्टर',
      'contextFiltersSub': 'आस-पास की बीमारी और बताए गए लक्षण चुनें',
      'startQuestions': 'प्रश्न शुरू करें',
      'commonQuestion': 'सामान्य प्रश्न',
      'adaptive': 'अनुकूली',
      'speakIn': 'इस भाषा में बोलें',
      'nextQuestion': 'अगला प्रश्न',
      'previousQuestion': 'पिछला प्रश्न',
      'reviewHint': 'समीक्षा के लिए किसी प्रश्न पर टैप करें',
      'yes': 'हाँ',
      'no': 'नहीं',
      'notSure': 'पक्का नहीं',
      'enterValue': 'मान दर्ज करें',
      'saveValue': 'मान सहेजें',
      'enterResponse': 'उत्तर दर्ज करें',
      'saveResponse': 'उत्तर सहेजें',
      'notSureCheck': 'पक्का नहीं / जाँच नहीं कर सकते',
      'assessmentComplete': 'जाँच पूरी हुई',
    },
    'mr': {
      'triage': 'ट्रायेज',
      'referralTicket': 'रेफरल तिकीट',
      'speakerLanguage': 'बोलण्याची भाषा',
      'question': 'प्रश्न',
      'of': 'पैकी',
      'patientName': 'रुग्णाचे नाव',
      'age': 'वय',
      'ageHint': 'मुलासाठी महिने किंवा मोठ्या रुग्णासाठी वर्षे भरा',
      'ageUnit': 'वयाचे एकक',
      'months': 'महिने',
      'years': 'वर्षे',
      'sexContext': 'लिंग / रुग्ण संदर्भ',
      'unknown': 'माहित नाही / सांगू इच्छित नाही',
      'female': 'स्त्री',
      'male': 'पुरुष',
      'other': 'इतर',
      'location': 'गाव / ठिकाण',
      'locationHint': 'मूल किंवा रुग्ण कुठे राहतो?',
      'details': 'इतर तपशील (पर्यायी)',
      'detailsHint': 'या ट्रायेज केससाठी अतिरिक्त माहिती द्या.',
      'nearbyIllness': 'जवळची आजाराची माहिती',
      'reportedContext': 'विचारात घ्यायचा संदर्भ',
      'contextFilters': 'क्लिनिकल संदर्भ फिल्टर',
      'contextFiltersSub': 'जवळचा आजार आणि सांगितलेली लक्षणे निवडा',
      'startQuestions': 'प्रश्न सुरू करा',
      'commonQuestion': 'सामान्य प्रश्न',
      'adaptive': 'अनुकूली',
      'speakIn': 'या भाषेत बोला',
      'nextQuestion': 'पुढील प्रश्न',
      'previousQuestion': 'मागील प्रश्न',
      'reviewHint': 'पुनरावलोकनासाठी प्रश्नावर टॅप करा',
      'yes': 'होय',
      'no': 'नाही',
      'notSure': 'नक्की नाही',
      'enterValue': 'मूल्य भरा',
      'saveValue': 'मूल्य जतन करा',
      'enterResponse': 'उत्तर भरा',
      'saveResponse': 'उत्तर जतन करा',
      'notSureCheck': 'नक्की नाही / तपासता येत नाही',
      'assessmentComplete': 'तपासणी पूर्ण झाली',
    },
  };
  return copy[language]?[key] ?? copy['en']![key]!;
}

/// Common IMCI questions, then outbreak questions from the ward pack or from
/// illnesses the worker marks herself when the phone is offline.
class TriageFlowScreen extends ConsumerStatefulWidget {
  const TriageFlowScreen({super.key});

  @override
  ConsumerState<TriageFlowScreen> createState() => _TriageFlowScreenState();
}

class _TriageFlowScreenState extends ConsumerState<TriageFlowScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _location = TextEditingController();
  final _details = TextEditingController();
  final _ageDays = TextEditingController();
  final _respiratoryRate = TextEditingController();
  final _temperature = TextEditingController();
  final _systolicBp = TextEditingController();
  final _diastolicBp = TextEditingController();
  final _pulseRate = TextEditingController();
  final _answerController = TextEditingController();
  final _questionScrollController = ScrollController();
  final _questionKeys = <String, GlobalKey>{};
  final _tts = TtsService();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  AdaptiveSession? _session;
  FlowState? _flow;
  String _wardId = 'W3';
  var _online = false;
  var _phase = _Phase.intake;
  final _chosen = <String>{};
  List<BankQuestion> _visible = const [];
  var _index = 0;
  HybridDecision? _decision;
  ReferralNote? _note;
  String? _queueNote;
  String? _caseCode;
  int? _ageMonths;
  String? _scoreLine;
  List<(String, String)> _answers = const [];
  String? _error;
  String? _answerError;
  XFile? _triageImage;
  String? _triageAudioPath;
  bool _recordingAttachment = false;
  bool _sendingPacket = false;
  bool _ticketQueued = false;
  String? _attachmentMessage;
  List<Map<String, dynamic>> _queuedAttachments = const [];
  String _sex = 'Unknown';
  bool _adaptiveFromRadar = false;
  final _reportedContext = <String>{};
  AgeBandCode _ageBand = AgeBandCode.child2m5y;
  String _ageUnit = 'months';
  bool _chestIndrawing = false;
  bool _vomitingEverything = false;
  bool _convulsions = false;

  String get _engineVersion =>
      'imci-engine/pack-${_session?.loop.pack.version ?? 'unknown'}';

  String get _modelVersion => _session?.model?.modelVersion ?? 'rules-only';

  static const _illnesses = <(String, String)>[
    ('dengue', 'Dengue-like'),
    ('measles', 'Measles-like'),
    ('diarrhoea_cluster', 'Diarrhoea'),
    ('aes', 'AES / brain fever'),
  ];

  static const _reportedContexts = <(String, String)>[
    ('fever', 'Fever'),
    ('cough_breathing', 'Cough / breathing'),
    ('diarrhoea', 'Diarrhoea'),
    ('rash', 'Rash'),
    ('weakness', 'Weakness / fall'),
    ('bp_diabetes', 'BP / diabetes'),
    ('pregnancy', 'Pregnancy'),
  ];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _location.dispose();
    _details.dispose();
    _ageDays.dispose();
    _respiratoryRate.dispose();
    _temperature.dispose();
    _systolicBp.dispose();
    _diastolicBp.dispose();
    _pulseRate.dispose();
    _answerController.dispose();
    _questionScrollController.dispose();
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
        _attachmentMessage = 'Image added and ready to compress.';
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
            : 'Voice note added and ready to compress.';
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
      final path =
          '${directory.path}/triage_${_caseCode ?? DateTime.now().millisecondsSinceEpoch}.m4a';
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

  Future<Map<String, dynamic>> _compressedAttachment(
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

  Future<List<Map<String, dynamic>>> _compressedTriageAttachments() async {
    final attachments = <Map<String, dynamic>>[..._queuedAttachments];
    final image = _triageImage;
    if (image != null && !attachments.any((item) => item['type'] == 'image')) {
      attachments.add(
        await _compressedAttachment(
          image.path,
          type: 'image',
          mimeType: 'image/jpeg',
        ),
      );
    }
    final audioPath = _triageAudioPath;
    if (audioPath != null &&
        !attachments.any((item) => item['type'] == 'audio') &&
        await File(audioPath).exists()) {
      attachments.add(
        await _compressedAttachment(
          audioPath,
          type: 'audio',
          mimeType: 'audio/mp4',
        ),
      );
    }
    return attachments;
  }

  Map<String, dynamic> _ticketPayload(List<Map<String, dynamic>> attachments) =>
      {
        ..._wardCoordinates(),
        'name': _name.text.trim(),
        'age_months': _ageMonths,
        'age_days': int.tryParse(_ageDays.text.trim()),
        'age_band': _ageBand.code,
        'patient_group': _patientGroupLabel,
        'age_unit': _ageUnit,
        'location': _location.text.trim(),
        'additional_details': _details.text.trim(),
        'sex': _sex,
        'reported_context_json': jsonEncode(_reportedContext.toList()),
        'adaptive_from_disease_radar':
            _adaptiveFromRadar ||
            (_session?.loop.pack.activeModuleIds(_wardId).isNotEmpty ?? false),
        'radar_modules_json': jsonEncode(
          _session?.loop.pack.activeModuleIds(_wardId) ?? const <String>[],
        ),
        'engine_version': _engineVersion,
        'model_version': _modelVersion,
        'ward_id': _flow?.wardId,
        'flag': _decision?.flag.wireName,
        'sms': _note?.toSms(),
        'modules_json': jsonEncode(_flow?.activeModules ?? const <String>[]),
        'worker_modules_json': jsonEncode(_chosen.toList()),
        'clinical_context_json': jsonEncode({
          'respiratory_rate': num.tryParse(_respiratoryRate.text.trim()),
          'temperature': num.tryParse(_temperature.text.trim()),
          'systolic_bp': int.tryParse(_systolicBp.text.trim()),
          'diastolic_bp': int.tryParse(_diastolicBp.text.trim()),
          'pulse_rate': int.tryParse(_pulseRate.text.trim()),
          'chest_indrawing': _chestIndrawing,
          'vomiting_everything': _vomitingEverything,
          'convulsions': _convulsions,
        }),
        'attachments_json': jsonEncode(attachments),
      };

  Map<String, dynamic> _wardCoordinates() {
    final center = _session?.loop.pack.centerForWard(_flow?.wardId ?? _wardId);
    return {'latitude': center?.latitude, 'longitude': center?.longitude};
  }

  Future<bool> _queueTriageTicket() async {
    final caseCode = _caseCode;
    if (caseCode == null || _decision == null) return false;
    try {
      final attachments = await _compressedTriageAttachments();
      await ref
          .read(syncEngineProvider)
          .enqueue(
            table: 'triage_tickets',
            recordId: caseCode,
            operation: 'insert',
            payload: _ticketPayload(attachments),
            priority: _decision!.flag == TriageFlag.red
                ? SyncPriority.critical
                : SyncPriority.clinical,
          );
      _queuedAttachments = attachments;
      if (_triageImage != null) {
        await _deleteTemporaryFile(_triageImage!.path);
      }
      if (_triageAudioPath != null) {
        await _deleteTemporaryFile(_triageAudioPath!);
      }
      if (mounted) {
        setState(
          () => _attachmentMessage = attachments.isEmpty
              ? 'No attachments selected.'
              : '${attachments.length} attachment(s) compressed and queued.',
        );
      }
      return true;
    } catch (error) {
      if (mounted) {
        setState(
          () => _attachmentMessage = 'Attachment could not be prepared: $error',
        );
      }
      return false;
    }
  }

  Future<void> _deleteTemporaryFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // The compressed copy is already in the encrypted queue; cleanup is
      // best effort because camera providers may own their cache file.
    }
  }

  Future<void> _sendTriagePacket() async {
    if (_sendingPacket || _ticketQueued) return;
    setState(() => _sendingPacket = true);
    if (_recordingAttachment) {
      await _toggleTriageAudio();
    }
    final queued = await _queueTriageTicket();
    if (!queued || !mounted) {
      if (mounted) setState(() => _sendingPacket = false);
      return;
    }
    await ref.read(syncCoordinatorProvider)?.syncNow();
    if (!mounted) return;
    setState(() {
      _sendingPacket = false;
      _ticketQueued = true;
      _queueNote = 'Ticket sent to the secure sync queue. It will upload when the server connection is available.';
    });
  }

  Future<void> _boot() async {
    try {
      final session = await AdaptiveSession.load();
      final online = await _probe();
      if (!mounted) return;
      setState(() {
        _session = session;
        _wardId = session.resolve(session.loop.pack.sampleFix).wardId ?? 'W3';
        _online = online;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  Future<bool> _probe() async {
    try {
      final response = await http
          .get(Uri.parse('http://10.255.102.24:8000/healthz'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  String get _lang => ref.read(languageProvider).languageCode;

  Future<void> _startQuestions() async {
    final session = _session;
    final age = _ageMonthsValue();
    final name = _name.text.trim();
    final location = _location.text.trim();
    if (session == null || age == null || name.isEmpty || location.isEmpty) {
      setState(
        () => _error = 'Enter the name, age, and location before starting.',
      );
      return;
    }
    final exactAgeDays = int.tryParse(_ageDays.text.trim());
    if (exactAgeDays != null && exactAgeDays < 0) {
      setState(() => _error = 'Exact age in days cannot be negative.');
      return;
    }
    // Do not inject the demo/sample ward's disease module into every case.
    // Radar context is applied only after the worker explicitly enables the
    // adaptive-radar option; otherwise questions are driven by age, vitals,
    // and answers in this assessment.
    final radarModules = _adaptiveFromRadar
        ? session.loop.pack.activeModuleIds(_wardId)
        : const <String>[];
    final contextModules = <String>{..._chosen, ...radarModules};
    if (_extendedClinicalContext) contextModules.add('adult_vitals');
    // Always include adult module for patients >= 5 years
    if (age >= 60) contextModules.add('adult');
    final flow = session.loop.openAssessment(
      wardId: _wardId,
      calendarMonth: DateTime.now().month,
      ageMonths: age,
      extraModules: contextModules,
    );
    _seedClinicalContext(flow);
    final visible = _visibleQuestions(flow);
    final firstUnanswered = visible.indexWhere(
      (question) => !flow.answeredIds.contains(question.id),
    );
    setState(() {
      _flow = flow;
      _visible = visible;
      _index = firstUnanswered < 0 ? 0 : firstUnanswered;
      _phase = _Phase.questions;
      _error = null;
      _answerError = null;
      _ageMonths = age;
    });
    _questionKeys
      ..clear()
      ..addEntries(
        visible.map((question) => MapEntry(question.id, GlobalKey())),
      );
  }

  void _seedClinicalContext(FlowState flow) {
    int? integer(TextEditingController controller) =>
        int.tryParse(controller.text.trim());
    num? decimal(TextEditingController controller) =>
        num.tryParse(controller.text.trim());

    final values = <String, Object?>{
      'vitals.respiratory_rate': integer(_respiratoryRate),
      'vitals.temp_c': decimal(_temperature),
      'vitals.systolic_bp': integer(_systolicBp),
      'vitals.diastolic_bp': integer(_diastolicBp),
      'vitals.pulse_rate': integer(_pulseRate),
      'symptoms.chest_indrawing': _chestIndrawing ? true : null,
      'symptoms.vomits_everything': _vomitingEverything ? true : null,
      'symptoms.convulsions': _convulsions ? true : null,
    };
    for (final entry in values.entries) {
      if (entry.value != null) flow.seedInput(entry.key, entry.value);
    }
  }

  bool _show(FlowState flow, BankQuestion question) {
    bool yes(String field) => flow.answers[field] == true;
    switch (question.id) {
      case 'core.convulsing_now':
        return yes('symptoms.convulsions');
      case 'core.indrawing':
      case 'core.stridor':
      case 'core.cough_days':
      case 'core.rr':
        return yes('symptoms.cough');
      case 'core.blood':
      case 'core.diarrhoea_days':
      case 'core.sunken':
      case 'core.restless':
      case 'core.eager':
      case 'core.skin_pinch':
      case 'core.drinking_poorly':
        return yes('symptoms.diarrhoea');
      case 'core.stiff_neck':
      case 'core.temp':
      case 'core.malaria_test':
      case 'core.severe_malaria':
        return yes('symptoms.fever');
      case 'core.mastoid':
      case 'core.ear_days':
        return yes('symptoms.ear_pain') || yes('symptoms.ear_discharge');
      // Adult follow-up: pregnancy danger only for female / other patients
      case 'adult.pregnancy_danger':
        return _sex == 'Female' || _sex == 'Other';
      default:
        return true;
    }
  }

  /// Keep the common rules-based screen first. Adaptive questions from the
  /// selected symptoms, radar, and age band are appended after the common
  /// screening block rather than interrupting it.
  List<BankQuestion> _visibleQuestions(FlowState flow) {
    final common = <BankQuestion>[];
    final adaptive = <BankQuestion>[];
    for (final question in flow.questions) {
      if (!_show(flow, question)) continue;
      final isCoreOrAdult = question.module == 'core' ||
          question.module == 'adult' ||
          question.module == 'adult_vitals';
      (isCoreOrAdult ? common : adaptive).add(question);
    }
    return [...common, ...adaptive];
  }

  Future<void> _speak(BankQuestion question) async {
    await _tts.speak(text: _questionPrompt(question, _lang), language: _lang);
  }

  void _answer(Object? raw) {
    final flow = _flow;
    if (flow == null || _index >= _visible.length) return;
    flow.answer(_visible[_index].id, raw);
    final visible = _visibleQuestions(flow);
    final next = visible.indexWhere(
      (question) => !flow.answeredIds.contains(question.id),
    );
    // A danger sign still colours the ticket, but the worker finishes every
    // question that is on screen before the tag, QR, and queue.
    if (next < 0) {
      _finish(flow);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _visible = visible;
      _index = next;
      _answerError = null;
    });
    _answerController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _questionKeys[visible[next].id];
      final target = key?.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
      }
    });
  }

  void _submitNumber(BankQuestion question) {
    final bounds = question.numeric;
    final value = num.tryParse(_answerController.text.trim());
    if (bounds == null || value == null) {
      setState(() => _answerError = 'Enter a number before saving.');
      return;
    }
    if (value < bounds.min || value > bounds.max) {
      setState(
        () => _answerError =
            'Use a value from ${bounds.min} to ${bounds.max} ${bounds.unit}.',
      );
      return;
    }
    _answer(bounds.decimals == 0 ? value.toInt() : value);
  }

  void _submitText() {
    final value = _answerController.text.trim();
    if (value.isEmpty) {
      setState(() => _answerError = 'Enter a response or choose Not sure.');
      return;
    }
    _answer(value);
  }

  void _moveQuestion(int delta) {
    if (_visible.isEmpty) return;
    final next = (_index + delta).clamp(0, _visible.length - 1);
    if (next == _index) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _index = next;
      _answerError = null;
    });
    _answerController.clear();
  }

  Future<void> _finish(FlowState flow) async {
    final session = _session;
    final age = _ageMonthsValue();
    final location = _location.text.trim();
    if (session == null || age == null || location.isEmpty) return;
    if (flow.answers['symptoms.convulsions'] != true &&
        !flow.answers.containsKey('symptoms.convulsing_now')) {
      flow.answers['symptoms.convulsing_now'] = false;
    }
    final code = 'CASE-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final input = flow.toAssessmentInput(
      patientId: code,
      ageMonths: age,
      sex: _sex,
    );
    final score = session.model?.score(input, session.prior);
    final decision = session.loop.decide(input, score: score);
    final facility = session.loop.pack.facilityForWard(flow.wardId);
    final note = ReferralNote.fromResult(
      decision.engineView,
      PatientProfile(
        id: code,
        abhaId: '91-0000-0000-${age.toString().padLeft(4, '0')}',
        name: _name.text.trim(),
        ageMonths: age,
        sex: _sex,
        village: location,
      ),
      FacilityProfile(
        id: facility?.id ?? 'HFR-UNSET',
        name: facility?.name ?? 'Facility not chosen',
      ),
      wardId: flow.wardId,
      referralId: code,
      vitals: input.vitals,
      symptoms: input.symptoms,
      outbreakContext: decision.outbreakContext,
      suggestedFacilityId: facility?.id,
    );
    session.loop.enqueue(input, decision, note);
    const queueNote =
        'Ticket is only on this phone. Add any evidence, then choose Send ticket with attachments.';
    final answers = <(String, String)>[];
    for (final question in flow.questions) {
      if (!flow.answeredIds.contains(question.id)) continue;
      final stored = flow.answers[question.inputField];
      final shown = stored == null
          ? 'Not sure'
          : stored == true
          ? 'Yes'
          : stored == false
          ? 'No'
          : '$stored';
      answers.add((_questionPrompt(question, _lang), shown));
    }
    final model = decision.modelContribution.score;
    final scoreLine = model == null
        ? decision.modelContribution.note
        : 'Model ${model.likelyFlag}  red ${model.pRed.toStringAsFixed(2)}  yellow ${model.pYellow.toStringAsFixed(2)}  green ${model.pGreen.toStringAsFixed(2)}';
    if (!mounted) return;
    setState(() {
      _decision = decision;
      _note = note;
      _queueNote = queueNote;
      _caseCode = code;
      _ageMonths = age;
      _scoreLine = scoreLine;
      _answers = answers;
      _phase = _Phase.ticket;
    });
  }

  Future<void> _callEmergencyNumber() async {
    final uri = Uri(scheme: 'tel', path: '108');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the phone dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).languageCode;
    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AshaColors.textPrimary,
        title: Text(
          _phase == _Phase.ticket
              ? _triageCopy(lang, 'referralTicket')
              : _triageCopy(lang, 'triage'),
        ),
        actions: [
          IconButton(
            tooltip: _triageCopy(lang, 'speakerLanguage'),
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => const LanguageSelectorDialog(),
              );
            },
            icon: const Icon(Icons.translate),
          ),
          IconButton(
            tooltip: 'They speak / I ask',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LanguageBridgeScreen(),
                ),
              );
            },
            icon: const Icon(Icons.record_voice_over_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: _error != null && _session == null
            ? Center(child: Text(_error!))
            : switch (_phase) {
                _Phase.intake => _intake(lang),
                _Phase.questions => _question(lang),
                _Phase.ticket => _ticket(),
              },
      ),
    );
  }

  Widget _intake(String lang) {
    final packModules =
        _session?.loop.pack.activeModuleIds(_wardId) ?? const <String>[];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          _online
              ? 'Ward $_wardId pack is on this phone${packModules.isEmpty ? '' : ': ${packModules.join(', ')}'}.'
              : 'Offline. The common questions still run. Mark any illness you have already heard about nearby.',
          style: const TextStyle(height: 1.35),
        ),
        if (packModules.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Shared area signals are active: ${packModules.join(', ')}. Related questions will be added automatically.',
            style: const TextStyle(
              height: 1.35,
              color: AshaColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: _triageCopy(lang, 'patientName'),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _age,
          keyboardType: TextInputType.number,
          onChanged: _syncAgeBandFromInput,
          decoration: InputDecoration(
            labelText: _triageCopy(lang, 'age'),
            hintText: _triageCopy(lang, 'ageHint'),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          key: const Key('triage_age_unit_dropdown'),
          initialValue: _ageUnit,
          decoration: InputDecoration(
            labelText: _triageCopy(lang, 'ageUnit'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          items: [
            DropdownMenuItem(
              value: 'months',
              child: Text(_triageCopy(lang, 'months')),
            ),
            DropdownMenuItem(
              value: 'years',
              child: Text(_triageCopy(lang, 'years')),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _ageUnit = value);
            _syncAgeBandFromInput(_age.text);
          },
        ),
        const SizedBox(height: 16),
        if (_extendedClinicalContext) ...[
          _extendedClinicalIntake(),
          const SizedBox(height: 16),
        ],
        DropdownButtonFormField<String>(
          key: const Key('triage_sex_dropdown'),
          initialValue: _sex,
          decoration: InputDecoration(
            labelText: _triageCopy(lang, 'sexContext'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          items: [
            DropdownMenuItem(
              value: 'Unknown',
              child: Text(_triageCopy(lang, 'unknown')),
            ),
            DropdownMenuItem(
              value: 'Female',
              child: Text(_triageCopy(lang, 'female')),
            ),
            DropdownMenuItem(
              value: 'Male',
              child: Text(_triageCopy(lang, 'male')),
            ),
            DropdownMenuItem(
              value: 'Other',
              child: Text(_triageCopy(lang, 'other')),
            ),
          ],
          onChanged: (value) => setState(() => _sex = value ?? 'Unknown'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _location,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: _triageCopy(lang, 'location'),
            hintText: _triageCopy(lang, 'locationHint'),
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _details,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: _triageCopy(lang, 'details'),
            hintText: _triageCopy(lang, 'detailsHint'),
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.notes_outlined),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          key: const Key('triage_context_filters'),
          margin: EdgeInsets.zero,
          elevation: 0,
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(
              _triageCopy(lang, 'contextFilters'),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(_triageCopy(lang, 'contextFiltersSub')),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _triageCopy(lang, 'nearbyIllness'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final illness in _illnesses)
                    FilterChip(
                      label: Text(illness.$2),
                      selected: _chosen.contains(illness.$1),
                      onSelected: (on) => setState(() {
                        if (on) {
                          _chosen.add(illness.$1);
                        } else {
                          _chosen.remove(illness.$1);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _triageCopy(lang, 'reportedContext'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final contextChip in _reportedContexts)
                    FilterChip(
                      label: Text(contextChip.$2),
                      selected: _reportedContext.contains(contextChip.$1),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          _reportedContext.add(contextChip.$1);
                        } else {
                          _reportedContext.remove(contextChip.$1);
                        }
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('triage_adaptive_radar_button'),
          onPressed: () => setState(() => _adaptiveFromRadar = true),
          icon: const Icon(Icons.radar_outlined),
          label: Text(
            _adaptiveFromRadar
                ? 'Disease-radar adaptive triage enabled'
                : 'Area disease radar is applied automatically',
          ),
        ),
        if (_adaptiveFromRadar && packModules.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'The local radar will add: ${packModules.join(', ')}. The adaptive flow and risk model will use these modules.',
              style: const TextStyle(
                fontSize: 12,
                color: AshaColors.textSecondary,
              ),
            ),
          ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Color(0xFF9F2D2D))),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _session == null ? null : _startQuestions,
          child: Text(
            '${_triageCopy(lang, 'startQuestions')} (${_languageName(lang)})',
          ),
        ),
      ],
    );
  }

  Widget _extendedClinicalIntake() {
    return Card(
      key: const Key('triage_extended_clinical_intake'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.monitor_heart_outlined,
                  color: AshaColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$_patientGroupLabel details',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Optional measurements are carried into the same adaptive triage flow. Leave a value blank if it was not measured.',
              style: TextStyle(color: AshaColors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('triage_exact_age_days'),
              controller: _ageDays,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Exact age in days (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _clinicalNumber(
                    key: const Key('triage_respiratory_rate'),
                    controller: _respiratoryRate,
                    label: 'Respiratory rate',
                    suffix: '/min',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _clinicalNumber(
                    key: const Key('triage_temperature'),
                    controller: _temperature,
                    label: 'Temperature',
                    suffix: '°C',
                    decimal: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _clinicalNumber(
                    key: const Key('triage_systolic_bp'),
                    controller: _systolicBp,
                    label: 'Systolic BP',
                    suffix: 'mmHg',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _clinicalNumber(
                    key: const Key('triage_diastolic_bp'),
                    controller: _diastolicBp,
                    label: 'Diastolic BP',
                    suffix: 'mmHg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _clinicalNumber(
              key: const Key('triage_pulse_rate'),
              controller: _pulseRate,
              label: 'Pulse rate',
              suffix: 'beats/min',
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lower chest wall indrawing'),
              value: _chestIndrawing,
              onChanged: (value) =>
                  setState(() => _chestIndrawing = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vomits everything'),
              value: _vomitingEverything,
              onChanged: (value) =>
                  setState(() => _vomitingEverything = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Convulsions during this illness'),
              value: _convulsions,
              onChanged: (value) =>
                  setState(() => _convulsions = value ?? false),
            ),
            if (_ageBand == AgeBandCode.pregnant)
              const Text(
                'Pregnancy context is included in this triage packet. Confirm gestational age and ANC details in the notes if known.',
                style: TextStyle(color: AshaColors.textSecondary, height: 1.3),
              ),
          ],
        ),
      ),
    );
  }

  Widget _clinicalNumber({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String suffix,
    bool decimal = false,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _question(String lang) {
    if (_index >= _visible.length) return const SizedBox.shrink();
    final question = _visible[_index];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_triageCopy(lang, 'question')} ${_index + 1} ${_triageCopy(lang, 'of')} ${_visible.length}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${((_index + 1) / _visible.length * 100).round()}%',
                    style: const TextStyle(color: AshaColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: (_index + 1) / _visible.length,
                  backgroundColor: const Color(0xFFF1F3F5),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFD1D5DB),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _questionScrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: _visible.length,
            itemBuilder: (context, index) =>
                _questionCard(lang, _visible[index], index),
          ),
        ),
        _answerBar(question),
      ],
    );
  }

  Widget _questionCard(String lang, BankQuestion question, int index) {
    final isFocused = index == _index;
    final answered = _flow?.answeredIds.contains(question.id) ?? false;
    final stored = _flow?.answers[question.inputField];
    return GestureDetector(
      onTap: () {
        if (_index == index) return;
        FocusScope.of(context).unfocus();
        setState(() {
          _index = index;
          _answerError = null;
        });
        _answerController.clear();
      },
      child: Container(
        key: _questionKeys.putIfAbsent(question.id, GlobalKey.new),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFocused ? Colors.white : const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isFocused ? AshaColors.primary : AshaColors.borderSubtle,
            width: isFocused ? 1.8 : 1,
          ),
          boxShadow: isFocused
              ? const [
                  BoxShadow(
                    color: Color(0x140F5138),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isFocused
                        ? AshaColors.primary
                        : answered
                        ? const Color(0xFFDDEFE4)
                        : const Color(0xFFE9F0EC),
                    shape: BoxShape.circle,
                  ),
                  child: answered
                      ? const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AshaColors.primary,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isFocused
                                ? Colors.white
                                : AshaColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _questionPrompt(question, lang),
                    style: TextStyle(
                      fontSize: isFocused ? 19 : 16,
                      fontWeight: FontWeight.w800,
                      height: 1.28,
                      color: AshaColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Text(
                question.module == 'core'
                    ? _triageCopy(lang, 'commonQuestion')
                    : '${_triageCopy(lang, 'adaptive')} · ${question.module}',
                style: const TextStyle(color: AshaColors.textSecondary),
              ),
            ),
            if (isFocused) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('triage_language_button'),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => const LanguageSelectorDialog(),
                  );
                },
                icon: const Icon(Icons.language_rounded),
                label: Text(
                  '${_triageCopy(lang, 'speakIn')} ${_languageName(lang)}',
                ),
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: AshaColors.primaryDark,
                  side: const BorderSide(color: AshaColors.borderSubtle),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AshaShapes.buttonRadius,
                  ),
                ),
              ),
              if (question.type != 'bool') ...[
                const SizedBox(height: 14),
                _answerControls(question),
              ],
            ] else if (answered) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  stored == null
                      ? _triageCopy(lang, 'notSureCheck')
                      : stored == true
                      ? _triageCopy(lang, 'yes')
                      : stored == false
                      ? _triageCopy(lang, 'no')
                      : '$stored',
                  style: const TextStyle(
                    color: AshaColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(left: 40),
                child: Text(
                  _triageCopy(lang, 'nextQuestion'),
                  style: TextStyle(color: AshaColors.textMuted),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _answerBar(BankQuestion question) {
    final isBoolean = question.type == 'bool';
    final lang = ref.read(languageProvider).languageCode;
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: const Color(0x24000000),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: _triageCopy(lang, 'previousQuestion'),
                    onPressed: _index == 0 ? null : () => _moveQuestion(-1),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      _triageCopy(lang, 'reviewHint'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AshaColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _triageCopy(lang, 'nextQuestion'),
                    onPressed: _index >= _visible.length - 1
                        ? null
                        : () => _moveQuestion(1),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
              Row(
                children: [
                  if (isBoolean) ...[
                    _bottomAnswer(
                      label: _triageCopy(lang, 'yes'),
                      icon: Icons.check_rounded,
                      color: AshaColors.primary,
                      onPressed: () => _answer(true),
                    ),
                    const SizedBox(width: 6),
                    _bottomAnswer(
                      label: _triageCopy(lang, 'no'),
                      icon: Icons.close_rounded,
                      color: const Color(0xFFD1D5DB),
                      foregroundColor: AshaColors.textPrimary,
                      onPressed: () => _answer(false),
                    ),
                    const SizedBox(width: 6),
                    _bottomAnswer(
                      label: _triageCopy(lang, 'notSure'),
                      icon: Icons.help_outline_rounded,
                      color: AshaColors.textSecondary,
                      onPressed: () => _answer(null),
                    ),
                  ] else ...[
                    Expanded(child: _notSureButton()),
                  ],
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton.filledTonal(
                      key: const Key('triage_speak_button'),
                      tooltip: 'Speak question',
                      onPressed: () => _speak(question),
                      icon: const Icon(Icons.volume_up_rounded),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomAnswer({
    required String label,
    required IconData icon,
    required Color color,
    Color foregroundColor = Colors.white,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: SizedBox(
        height: 48,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 17),
          label: FittedBox(child: Text(label)),
          style: FilledButton.styleFrom(
            backgroundColor: color,
            foregroundColor: foregroundColor,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: AshaShapes.buttonRadius,
            ),
          ),
        ),
      ),
    );
  }

  String _languageName(String code) {
    for (final language in supportedLanguages) {
      if (language.code == code) return language.nativeName;
    }
    return code.toUpperCase();
  }

  bool get _extendedClinicalContext =>
      _ageBand == AgeBandCode.adolescent ||
      _ageBand == AgeBandCode.adult ||
      _ageBand == AgeBandCode.pregnant ||
      (_ageMonthsValue() ?? 0) >= 60;

  int? _ageMonthsValue() {
    final value = int.tryParse(_age.text.trim());
    if (value == null || value < 0) return null;
    return _ageUnit == 'years' ? value * 12 : value;
  }

  String get _patientGroupLabel => switch (_ageBand) {
    AgeBandCode.infant02m => 'Young infant (0–2 months)',
    AgeBandCode.child2m5y => 'Child (2 months–5 years)',
    AgeBandCode.adolescent => 'Adolescent (5–19 years)',
    AgeBandCode.adult => 'Adult / older adult',
    AgeBandCode.pregnant => 'Pregnant / ANC',
  };

  String get _displayAge {
    final months = _ageMonths ?? _ageMonthsValue();
    if (months == null) return '—';
    if (months < 60) return '$months months';
    final years = months / 12;
    return years == years.roundToDouble()
        ? '${years.round()} years'
        : '${years.toStringAsFixed(1)} years';
  }

  String _questionPrompt(BankQuestion question, String language) {
    final prompt = question.prompt(language);
    // Adult-module questions already have patient-appropriate text
    if (question.module == 'adult' || question.module == 'adult_vitals') {
      return prompt;
    }
    if (!_extendedClinicalContext) return prompt;
    return prompt
        .replaceAll('the child', 'the patient')
        .replaceAll('child ', 'patient ')
        .replaceAll('Child ', 'Patient ')
        .replaceAll('बच्चे', 'मरीज़')
        .replaceAll('बच्चा', 'मरीज़')
        .replaceAll('मुलाला', 'रुग्णाला')
        .replaceAll('मुलाची', 'रुग्णाची')
        .replaceAll('मूल ', 'रुग्ण ')
        .replaceAll('मुलामध्ये', 'रुग्णामध्ये');
  }

  void _syncAgeBandFromInput(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null || value < 0) return;
    final next = _ageBandForInput(value);
    if (next != _ageBand) {
      setState(() => _ageBand = next);
    }
  }

  AgeBandCode _ageBandForInput(int value) {
    if (_ageUnit == 'months') {
      if (value <= 2) return AgeBandCode.infant02m;
      if (value <= 60) return AgeBandCode.child2m5y;
      if (value < 228) return AgeBandCode.adolescent;
      return AgeBandCode.adult;
    }
    if (value == 0) return AgeBandCode.infant02m;
    if (value <= 5) return AgeBandCode.child2m5y;
    if (value < 19) return AgeBandCode.adolescent;
    return AgeBandCode.adult;
  }

  Widget _answerControls(BankQuestion question) {
    final lang = ref.read(languageProvider).languageCode;
    switch (question.type) {
      case 'number':
        final bounds = question.numeric;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('triage_numeric_answer'),
              controller: _answerController,
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(
                decimal: bounds?.decimals != 0,
                signed: bounds != null && bounds.min < 0,
              ),
              decoration: InputDecoration(
                labelText: _triageCopy(lang, 'enterValue'),
                suffixText: bounds?.unit,
                errorText: _answerError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (_answerError != null) setState(() => _answerError = null);
              },
              onSubmitted: (_) => _submitNumber(question),
            ),
            if (bounds != null) ...[
              const SizedBox(height: 8),
              Text(
                'Expected range: ${bounds.min}–${bounds.max} ${bounds.unit}',
                style: const TextStyle(color: AshaColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('triage_save_value'),
              onPressed: () => _submitNumber(question),
              icon: const Icon(Icons.check_rounded),
              label: Text(_triageCopy(lang, 'saveValue')),
            ),
          ],
        );
      case 'choice':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final option in question.options) ...[
              _choiceButton(option),
              const SizedBox(height: 8),
            ],
          ],
        );
      case 'text':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('triage_text_answer'),
              controller: _answerController,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: _triageCopy(lang, 'enterResponse'),
                errorText: _answerError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _submitText,
              icon: const Icon(Icons.check_rounded),
              label: Text(_triageCopy(lang, 'saveResponse')),
            ),
          ],
        );
      case 'bool':
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _choiceButton(ChoiceOption option) {
    return SizedBox(
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () => _answer(option.value),
        icon: const Icon(Icons.radio_button_unchecked_rounded),
        label: Align(
          alignment: Alignment.centerLeft,
          child: Text(option.label),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AshaColors.primaryDark,
          side: const BorderSide(color: AshaColors.borderSubtle, width: 1.5),
          shape: const RoundedRectangleBorder(
            borderRadius: AshaShapes.cardRadius,
          ),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Widget _notSureButton() {
    final lang = ref.read(languageProvider).languageCode;
    return OutlinedButton.icon(
      key: const Key('triage_answer_unknown'),
      onPressed: () => _answer(null),
      icon: const Icon(Icons.help_outline_rounded),
      label: Text(_triageCopy(lang, 'notSureCheck')),
      style: OutlinedButton.styleFrom(
        foregroundColor: AshaColors.textSecondary,
        minimumSize: const Size.fromHeight(52),
        shape: const RoundedRectangleBorder(
          borderRadius: AshaShapes.buttonRadius,
        ),
      ),
    );
  }

  Widget _ticket() {
    final decision = _decision;
    final note = _note;
    if (decision == null || note == null) return const SizedBox.shrink();
    final sms = note.toSms();
    final flag = decision.flag.wireName;
    final flagColor = switch (flag) {
      'RED' => const Color(0xFFB42318),
      'YELLOW' => const Color(0xFFB45309),
      _ => const Color(0xFF166534),
    };
    final isRed = flag == 'RED';
    final statusText = isRed
        ? 'Immediate referral'
        : decision.flag == TriageFlag.yellow
        ? 'Review and follow up'
        : 'Routine follow-up';
    return ListView(
      key: const Key('triage_ticket_page'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Text('Assessment complete', style: AshaTypography.screenTitle),
        const SizedBox(height: 4),
        const Text(
          'Show this ticket at the receiving facility.',
          style: AshaTypography.bodyMedium,
        ),
        const SizedBox(height: 14),
        Container(
          key: const Key('triage_ticket_card'),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: flagColor, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  color: flagColor.withValues(alpha: 0.10),
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: flagColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRed
                              ? Icons.priority_high_rounded
                              : Icons.health_and_safety_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$flag TRIAGE',
                              key: const Key('triage_ticket_status'),
                              style: TextStyle(
                                color: flagColor,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              statusText,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.verified_rounded,
                        color: AshaColors.primary,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CHILD / PATIENT',
                                  style: AshaTypography.subtitleSmall,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _name.text.trim(),
                                  style: AshaTypography.sectionTitle,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _caseCode ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AshaColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _TicketGrid(
                        values: [
                          ('Age', _displayAge),
                          ('Location', note.patient.village),
                          ('Ward', _flow?.wardId ?? '—'),
                          ('Facility', note.facility.name),
                          ('Status', _online ? 'Online' : 'Offline queue'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _TicketDashedDivider(),
                      const SizedBox(height: 14),
                      if (_details.text.trim().isNotEmpty) ...[
                        _TicketSection(
                          title: 'Additional details',
                          icon: Icons.notes_rounded,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _details.text.trim(),
                              style: AshaTypography.bodyMedium,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: AshaColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              decision.followUpDays == null
                                  ? 'Take to facility now'
                                  : 'Follow up in ${decision.followUpDays} days',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            flag,
                            style: TextStyle(
                              color: flagColor,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_queueNote ?? '', style: AshaTypography.bodyMedium),
                      const SizedBox(height: 14),
                      const _TicketDashedDivider(),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.qr_code_2_rounded,
                            color: AshaColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Scan at receiving facility',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: QrImageView(
                          key: const Key('triage_ticket_qr'),
                          data: sms,
                          size: 156,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        sms,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AshaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _TriageAttachmentPanel(
          imageAdded: _triageImage != null,
          audioAdded: _triageAudioPath != null,
          recording: _recordingAttachment,
          message: _attachmentMessage,
          onCaptureImage: _captureTriageImage,
          onToggleAudio: _toggleTriageAudio,
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          key: const Key('triage_emergency_call_button'),
          onPressed: _callEmergencyNumber,
          icon: const Icon(Icons.phone_in_talk_rounded),
          label: const Text('Call emergency ambulance · 108'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB42318),
            side: const BorderSide(color: Color(0xFFF2B8B5)),
            minimumSize: const Size.fromHeight(52),
            shape: const RoundedRectangleBorder(
              borderRadius: AshaShapes.buttonRadius,
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          key: const Key('triage_send_packet_button'),
          onPressed: _sendingPacket || _ticketQueued ? null : _sendTriagePacket,
          icon: Icon(
            _ticketQueued
                ? Icons.check_circle_outline_rounded
                : Icons.cloud_upload_outlined,
          ),
          label: Text(
            _ticketQueued
                ? 'Ticket added to sync queue'
                : _sendingPacket
                ? 'Preparing secure packet…'
                : 'Send ticket with attachments',
          ),
        ),
        const SizedBox(height: 12),
        _TicketSection(
          title: 'Assessment findings',
          icon: Icons.fact_check_outlined,
          initiallyExpanded: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final row in _answers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.circle,
                          size: 7,
                          color: AshaColors.primary,
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(row.$1, style: AshaTypography.bodyMedium),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        row.$2,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (decision.firedRules.isNotEmpty) ...[
          const SizedBox(height: 12),
          _TicketSection(
            title: 'Why this flag was chosen',
            icon: Icons.rule_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final rule in decision.firedRules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${rule.severity.name.toUpperCase()} · ${rule.reasonText}',
                      style: AshaTypography.bodyMedium,
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (_scoreLine != null) ...[
          const SizedBox(height: 12),
          Text(_scoreLine!, style: AshaTypography.subtitleSmall),
        ],
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: () => context.go('/sync'),
          icon: const Icon(Icons.sync_rounded),
          label: const Text('Open sync queue'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Back to dashboard'),
        ),
      ],
    );
  }
}

class _TriageAttachmentPanel extends StatelessWidget {
  const _TriageAttachmentPanel({
    required this.imageAdded,
    required this.audioAdded,
    required this.recording,
    required this.message,
    required this.onCaptureImage,
    required this.onToggleAudio,
  });

  final bool imageAdded;
  final bool audioAdded;
  final bool recording;
  final String? message;
  final VoidCallback onCaptureImage;
  final VoidCallback onToggleAudio;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: const Color(0xFFF4F8F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AshaColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.attach_file_rounded, color: AshaColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add supporting evidence',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Optional image and voice note. They are compressed before being placed in the encrypted sync queue.',
              style: TextStyle(color: AshaColors.textSecondary, height: 1.3),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('triage_add_image_button'),
                    onPressed: onCaptureImage,
                    icon: Icon(
                      imageAdded
                          ? Icons.check_circle
                          : Icons.camera_alt_outlined,
                    ),
                    label: Text(imageAdded ? 'Image added' : 'Add image'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('triage_record_audio_button'),
                    onPressed: onToggleAudio,
                    icon: Icon(
                      recording
                          ? Icons.stop_circle_outlined
                          : audioAdded
                          ? Icons.check_circle
                          : Icons.mic_none_rounded,
                    ),
                    label: Text(
                      recording
                          ? 'Stop recording'
                          : audioAdded
                          ? 'Audio added'
                          : 'Record audio',
                    ),
                  ),
                ),
              ],
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: const TextStyle(
                  color: AshaColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TicketGrid extends StatelessWidget {
  const _TicketGrid({required this.values});

  final List<(String, String)> values;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 48,
      ),
      itemBuilder: (_, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            values[index].$1.toUpperCase(),
            style: AshaTypography.subtitleSmall,
          ),
          const SizedBox(height: 3),
          Text(
            values[index].$2,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TicketSection extends StatelessWidget {
  const _TicketSection({
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = true,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AshaColors.borderSubtle),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(icon, size: 20, color: AshaColors.primary),
          title: Text(title, style: AshaTypography.cardTitle),
          children: [child],
        ),
      ),
    );
  }
}

class _TicketDashedDivider extends StatelessWidget {
  const _TicketDashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (
            var index = 0;
            index < (constraints.maxWidth / 8).floor();
            index++
          )
            const SizedBox(
              width: 4,
              height: 1,
              child: ColoredBox(color: AshaColors.borderSubtle),
            ),
        ],
      ),
    );
  }
}

enum _Phase { intake, questions, ticket }
