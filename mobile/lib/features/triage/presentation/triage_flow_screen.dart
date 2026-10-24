import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:triage/triage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/l10n/language_selector_dialog.dart';
import '../../../core/bhasha/indic_translator.dart';
import '../../../core/bhasha/languages.dart';
import '../../../core/bhasha/model_store.dart';
import '../../../core/bhasha/speech_engine.dart';
import '../../../core/packs/pack_manager.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/triage/models/age_band.dart';
import '../../../core/voice/tts_service.dart';
import '../../../shared/providers/core_providers.dart';
import '../../clinical_programs/nutrition/domain/who_growth_calculator.dart';
import '../domain/adaptive_session.dart';
import '../domain/triage_input_validation.dart';
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
      'sexContext': 'Gender',
      'readingsTitle': 'Common readings',
      'readingsHint': 'Respiratory rate, pulse, oximeter, temperature, weight, and blood pressure. Leave a value blank if it was not measured.',
      'continueTicket': 'Continue to ticket',
      'referralNote': 'Referral note',
      'referralHint': 'Write what the receiving facility should know.',
      'referralRequired': 'Add a referral note before sending.',
      'unknown': 'Not told',
      'female': 'Female',
      'male': 'Male',
      'transgender': 'Transgender',
      'other': 'Other',
      'location': 'Village / location',
      'locationHint': 'Where is the child or patient located?',
      'details': 'Other details (optional)',
      'detailsHint': 'Add any context to carry with this triage case.',
      'nearbyIllness': 'Is this illness going around your village?',
      'reportedContext': 'What is the patient complaining of?',
      'contextFilters': 'Clinical context filters',
      'contextFiltersSub': 'Select nearby illness and reported symptoms',
      'startQuestions': 'Start questions',
      'commonQuestion': 'Common question',
      'adaptive': 'Adaptive',
      'childProtocol': 'Child flow: based on WHO IMCI',
      'adultProtocol': 'Adult flow: pilot, needs clinical validation',
      'addedAreaSignal': 'Added from your area disease signal',
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
      'sexContext': 'लिंग',
      'readingsTitle': 'सामान्य रीडिंग',
      'readingsHint': 'श्वसन दर, नाड़ी, ऑक्सीमीटर, तापमान, वज़न और रक्तचाप। जो नापी नहीं गई उसे खाली छोड़ें।',
      'continueTicket': 'टिकट पर जाएँ',
      'referralNote': 'रेफरल नोट',
      'referralHint': 'प्राप्त करने वाली सुविधा को क्या बताना है।',
      'referralRequired': 'भेजने से पहले रेफरल नोट लिखें।',
      'unknown': 'नहीं बताया',
      'female': 'महिला',
      'male': 'पुरुष',
      'transgender': 'ट्रांसजेंडर',
      'other': 'अन्य',
      'location': 'गाँव / स्थान',
      'locationHint': 'बच्चा या मरीज़ कहाँ रहता है?',
      'details': 'अन्य विवरण (वैकल्पिक)',
      'detailsHint': 'इस ट्राइएज केस के लिए कोई अतिरिक्त जानकारी दें।',
      'nearbyIllness': 'क्या यह बीमारी आपके गाँव में फैल रही है?',
      'reportedContext': 'मरीज़ को क्या शिकायत है?',
      'contextFilters': 'क्लिनिकल संदर्भ फ़िल्टर',
      'contextFiltersSub': 'आस-पास की बीमारी और बताए गए लक्षण चुनें',
      'startQuestions': 'प्रश्न शुरू करें',
      'commonQuestion': 'सामान्य प्रश्न',
      'adaptive': 'अनुकूली',
      'childProtocol': 'बाल प्रवाह: WHO IMCI पर आधारित',
      'adultProtocol': 'वयस्क प्रवाह: पायलट, चिकित्सकीय सत्यापन आवश्यक',
      'addedAreaSignal': 'आपके क्षेत्र के रोग संकेत से जोड़ा गया',
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
      'sexContext': 'लिंग',
      'readingsTitle': 'सामान्य रीडिंग',
      'readingsHint': 'श्वसन दर, नाडी, ऑक्सिमीटर, तापमान, वजन आणि रक्तदाब. मोजले नसेल तर रिकामे ठेवा.',
      'continueTicket': 'तिकीटाकडे जा',
      'referralNote': 'रेफरल नोंद',
      'referralHint': 'घेणाऱ्या सुविधेला काय कळवायचे आहे.',
      'referralRequired': 'पाठवण्यापूर्वी रेफरल नोंद लिहा.',
      'unknown': 'सांगितले नाही',
      'female': 'स्त्री',
      'male': 'पुरुष',
      'transgender': 'तृतीयपंथी / ट्रान्सजेंडर',
      'other': 'इतर',
      'location': 'गाव / ठिकाण',
      'locationHint': 'मूल किंवा रुग्ण कुठे राहतो?',
      'details': 'इतर तपशील (पर्यायी)',
      'detailsHint': 'या ट्रायेज केससाठी अतिरिक्त माहिती द्या.',
      'nearbyIllness': 'हा आजार तुमच्या गावात पसरत आहे का?',
      'reportedContext': 'रुग्णाची तक्रार काय आहे?',
      'contextFilters': 'क्लिनिकल संदर्भ फिल्टर',
      'contextFiltersSub': 'जवळचा आजार आणि सांगितलेली लक्षणे निवडा',
      'startQuestions': 'प्रश्न सुरू करा',
      'commonQuestion': 'सामान्य प्रश्न',
      'adaptive': 'अनुकूली',
      'childProtocol': 'बाल प्रवाह: WHO IMCI वर आधारित',
      'adultProtocol': 'प्रौढ प्रवाह: पायलट, वैद्यकीय पडताळणी आवश्यक',
      'addedAreaSignal': 'तुमच्या क्षेत्राच्या रोग संकेतावरून जोडले',
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

const _referralNoteCopy = <String, (String, String)>{
  'en': ('Referral note', 'Write what the receiving facility should know.'),
  'hi': (
    'रेफरल नोट',
    'प्राप्त करने वाली सुविधा को क्या बताना है, वही भाषा में लिखें।',
  ),
  'mr': ('रेफरल नोंद', 'घेणाऱ्या सुविधेला काय कळवायचे आहे, त्या भाषेत लिहा.'),
  'bn': ('রেফারাল নোট', 'যে ভাষায় বলা হচ্ছে, সেই ভাষায় লিখুন।'),
  'te': ('రిఫరల్ నోట్', 'మాట్లాడిన భాషలోనే రాయండి.'),
  'ta': ('பரிந்துரை குறிப்பு', 'பேசும் மொழியிலேயே எழுதுங்கள்.'),
  'kn': ('ರೆಫರಲ್ ಟಿಪ್ಪಣಿ', 'ಮಾತನಾಡಿದ ಭಾಷೆಯಲ್ಲಿಯೇ ಬರೆಯಿರಿ.'),
  'ml': ('റഫറൽ കുറിപ്പ്', 'സംസാരിക്കുന്ന ഭാഷയിൽ തന്നെ എഴുതുക.'),
  'or': ('ରେଫରାଲ୍ ନୋଟ୍', 'କୁହାଯାଉଥିବା ଭାଷାରେ ଲେଖନ୍ତୁ।'),
  'gu': ('રેફરલ નોંધ', 'બોલાતી ભાષામાં જ લખો.'),
  'pa': ('ਰੈਫਰਲ ਨੋਟ', 'ਜਿਸ ਭਾਸ਼ਾ ਵਿੱਚ ਗੱਲ ਹੋਈ ਹੈ, ਉਸੇ ਵਿੱਚ ਲਿਖੋ।'),
  'as': ('ৰেফাৰেল টোকা', 'কথা হোৱা ভাষাতেই লিখক।'),
};

/// Common IMCI questions, then outbreak questions from the ward pack or from
/// illnesses the worker marks herself when the phone is offline.
class TriageFlowScreen extends ConsumerStatefulWidget {
  const TriageFlowScreen({super.key});

  @override
  ConsumerState<TriageFlowScreen> createState() => _TriageFlowScreenState();
}

class _TriageFlowScreenState extends ConsumerState<TriageFlowScreen> {
  final _name = TextEditingController();
  final _householdHeadSearch = TextEditingController();
  final _age = TextEditingController();
  final _ageMonthsPart = TextEditingController();
  final _location = TextEditingController();
  final _details = TextEditingController();
  final _ageDays = TextEditingController();
  final _respiratoryRate = TextEditingController();
  final _temperature = TextEditingController();
  final _systolicBp = TextEditingController();
  final _diastolicBp = TextEditingController();
  final _pulseRate = TextEditingController();
  final _spo2 = TextEditingController();
  final _weight = TextEditingController();
  final _referralNote = TextEditingController();
  String _referralNoteLanguage = 'en';
  bool _referralVoiceBusy = false;
  bool _referralTranslateBusy = false;
  String _referralNoteEnglish = '';
  bool _readingsExpanded = false;
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
  String _sex = '';
  final _intakeSeededFields = <String>{};
  final _derivedFields = <String>{};
  bool _adaptiveFromRadar = false;
  final _reportedContext = <String>{};
  AgeBandCode _ageBand = AgeBandCode.child2m5y;
  String _ageUnit = 'months';
  final bool _chestIndrawing = false;
  final bool _vomitingEverything = false;
  final bool _convulsions = false;
  List<TriageInputIssue> _intakeIssues = const [];
  List<Household> _householdSuggestions = const [];
  List<Member> _householdMembers = const [];
  Household? _selectedHousehold;
  Member? _selectedMember;

  String get _engineVersion =>
      'imci-engine/pack-${_session?.loop.pack.version ?? 'unknown'}';

  String get _modelVersion => _session?.model?.modelVersion ?? 'rules-only';

  String get _normalizedPatientName {
    final words = _name.text.trim().split(RegExp(r'\s+'));
    return words
        .where((word) => word.isNotEmpty)
        .map(
          (word) => word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  static const _deviceReadingFields = <String>{
    'vitals.respiratory_rate',
    'vitals.temp_c',
    'vitals.weight_kg',
    'vitals.weight_for_age_zscore',
    'vitals.systolic_bp',
    'vitals.diastolic_bp',
    'vitals.pulse_rate',
  };

  static const _illnesses = <(String, String)>[
    ('dengue', 'Dengue-like'),
    ('measles', 'Measles-like'),
    ('diarrhoea_cluster', 'Diarrhoea'),
    ('aes', 'AES / brain fever'),
  ];

  static const _reportedContexts = <(String, String)>[
    ('fever', 'Fever'),
    ('cough_breathing', 'Cough / breathing'),
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
    _householdHeadSearch.dispose();
    _age.dispose();
    _ageMonthsPart.dispose();
    _location.dispose();
    _details.dispose();
    _ageDays.dispose();
    _respiratoryRate.dispose();
    _temperature.dispose();
    _systolicBp.dispose();
    _diastolicBp.dispose();
    _pulseRate.dispose();
    _spo2.dispose();
    _weight.dispose();
    _referralNote.dispose();
    _answerController.dispose();
    _questionScrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _searchHouseholdHeads(String value) async {
    final query = value.trim();
    if (query.isEmpty) {
      if (mounted) setState(() => _householdSuggestions = const []);
      return;
    }
    final db = ref.read(appDatabaseProvider);
    final rows = (await db.select(db.households).get())
        .where(
          (household) =>
              household.headName.toLowerCase().contains(query.toLowerCase()),
        )
        .take(8)
        .toList();
    if (!mounted || _householdHeadSearch.text.trim() != query) return;
    setState(() => _householdSuggestions = rows);
  }

  Future<void> _selectHousehold(Household household) async {
    final db = ref.read(appDatabaseProvider);
    final members = await (db.select(
      db.members,
    )..where((m) => m.householdId.equals(household.id))).get();
    if (!mounted) return;
    setState(() {
      _selectedHousehold = household;
      _householdSuggestions = const [];
      _householdMembers = members;
      _selectedMember = null;
      _householdHeadSearch.text = household.headName;
    });
  }

  void _selectMember(Member member) {
    final ageMonths = member.dobApprox == null
        ? null
        : DateTime.now()
                  .difference(
                    DateTime.fromMillisecondsSinceEpoch(member.dobApprox!),
                  )
                  .inDays ~/
              30;
    final years = ageMonths == null ? null : ageMonths ~/ 12;
    final monthsLeft = ageMonths == null ? null : ageMonths % 12;
    setState(() {
      _selectedMember = member;
      _name.text = member.name;
      _sex = member.sex == 'F'
          ? 'Female'
          : member.sex == 'M'
          ? 'Male'
          : '';
      _location.text = _selectedHousehold?.village ?? '';
      if (ageMonths != null && ageMonths < 60) {
        _ageUnit = 'child';
        _age.text = '$years';
        _ageMonthsPart.text = '$monthsLeft';
      } else {
        _ageUnit = 'years';
        _age.text = '${years ?? ''}';
        _ageMonthsPart.clear();
      }
    });
    _syncAgeBandFromInput(_age.text);
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
        'name': _normalizedPatientName,
        'age_months': _ageMonths,
        'age_days': int.tryParse(_ageDays.text.trim()),
        'age_band': _ageBand.code,
        'patient_group': _patientGroupLabel,
        'age_unit': _ageUnit,
        'location': _location.text.trim(),
        'additional_details': _details.text.trim(),
        'referral_note': _referralNote.text.trim(),
        'referral_note_language': _referralNoteLanguage,
        'referral_note_english': _referralNoteLanguage == 'en'
            ? _referralNote.text.trim()
            : _referralNoteEnglish.trim(),
        'sex': _sex,
        'reported_context_json': jsonEncode(_reportedContext.toList()),
        'adaptive_from_disease_radar': _adaptiveFromRadar,
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
          'spo2': int.tryParse(_spo2.text.trim()),
          'weight_kg': num.tryParse(_weight.text.trim()),
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
    if (_referralNote.text.trim().isEmpty) {
      setState(() => _error = _triageCopy(_lang, 'referralRequired'));
      return;
    }
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
    if (session == null ||
        age == null ||
        name.isEmpty ||
        location.isEmpty ||
        _sex.isEmpty) {
      setState(
        () => _error =
            'Enter the name, age, location, and gender before starting.',
      );
      return;
    }
    final intakeIssues = _validateIntakeMeasurements();
    if (intakeIssues.isNotEmpty) {
      TriageInputIssue? blockingIssue;
      for (final issue in intakeIssues) {
        if (!issue.confirmable) {
          blockingIssue = issue;
          break;
        }
      }
      setState(() {
        _intakeIssues = intakeIssues;
        _error = blockingIssue?.message;
      });
      if (blockingIssue != null) return;
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
      _intakeIssues = const [];
      _ageMonths = age;
    });
    _questionKeys
      ..clear()
      ..addEntries(
        visible.map((question) => MapEntry(question.id, GlobalKey())),
      );
    if (visible.isEmpty) {
      await _continueFromReadings();
    }
  }

  Map<String, num?> _intakeMeasurementValues() => {
    'vitals.respiratory_rate': int.tryParse(_respiratoryRate.text.trim()),
    'vitals.temp_c': num.tryParse(_temperature.text.trim()),
    'vitals.systolic_bp': int.tryParse(_systolicBp.text.trim()),
    'vitals.diastolic_bp': int.tryParse(_diastolicBp.text.trim()),
    'vitals.pulse_rate': int.tryParse(_pulseRate.text.trim()),
    'vitals.weight_kg': num.tryParse(_weight.text.trim()),
    'vitals.spo2': int.tryParse(_spo2.text.trim()),
  };

  List<TriageInputIssue> _validateIntakeMeasurements() =>
      TriageInputValidation.validate(_intakeMeasurementValues());

  TriageInputIssue? _intakeIssueFor(String fieldKey) {
    for (final issue in _intakeIssues) {
      if (issue.fieldKey == fieldKey) return issue;
    }
    return null;
  }

  void _seedClinicalContext(FlowState flow) {
    _intakeSeededFields.clear();
    _derivedFields.clear();
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
      'vitals.weight_kg': decimal(_weight),
      'symptoms.chest_indrawing': _chestIndrawing ? true : null,
      'symptoms.vomits_everything': _vomitingEverything ? true : null,
      'symptoms.convulsions': _convulsions ? true : null,
    };
    for (final entry in values.entries) {
      if (entry.value != null) {
        flow.seedInput(entry.key, entry.value);
        _intakeSeededFields.add(entry.key);
      }
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
      // Adult follow-up: pregnancy danger only for female / transgender patients
      case 'adult.pregnancy_danger':
        return _sex == 'Female' || _sex == 'Transgender';
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
      if (_deviceReadingFields.contains(question.inputField)) continue;
      if (!_show(flow, question)) continue;
      final isCoreOrAdult =
          question.module == 'core' ||
          question.module == 'adult' ||
          question.module == 'adult_vitals';
      (isCoreOrAdult ? common : adaptive).add(question);
    }
    final ordered = [...common, ...adaptive];
    final weightIndex = ordered.indexWhere(
      (question) => question.inputField == 'vitals.weight_kg',
    );
    final zScoreIndex = ordered.indexWhere(
      (question) => question.inputField == 'vitals.weight_for_age_zscore',
    );
    if (weightIndex >= 0 && zScoreIndex >= 0 && weightIndex > zScoreIndex) {
      // NEEDS CLINICIAN VALIDATION: keep the measured input before its
      // derived value without changing the scoring rule or its threshold.
      final zScoreQuestion = ordered.removeAt(zScoreIndex);
      final adjustedWeightIndex = ordered.indexWhere(
        (question) => question.inputField == 'vitals.weight_kg',
      );
      ordered.insert(adjustedWeightIndex + 1, zScoreQuestion);
    }
    return ordered;
  }

  /// Keep the worker's current question sequence stable while adaptive
  /// questions are added. Recomputing the filtered bank after an answer can
  /// otherwise remove the answered question and shift the next index several
  /// positions forward in one tap.
  List<BankQuestion> _stableVisibleQuestions(
    List<BankQuestion> previous,
    FlowState flow,
  ) {
    final next = _visibleQuestions(flow);
    if (previous.isEmpty) return next;
    final byId = {for (final question in next) question.id: question};
    final merged = <BankQuestion>[];
    for (final question in previous) {
      final current = byId.remove(question.id);
      // Keep already-present questions in the review sequence even if a new
      // answer makes their conditional prompt ineligible. This preserves the
      // current index and prevents a single answer from jumping ahead.
      merged.add(current ?? question);
    }
    merged.addAll(byId.values);
    return merged;
  }

  Future<void> _speak(BankQuestion question) async {
    await _tts.speak(text: _questionPrompt(question, _lang), language: _lang);
  }

  Future<void> _showHowToCheck(BankQuestion question, String language) async {
    final guidance = switch (question.inputField) {
      'symptoms.chest_indrawing' => (
        'Look at the lower ribs while the patient is calm. The lower chest wall pulling inward with each breath is a danger sign.',
        'Watch the lower ribs while the patient is calm. Do not count normal movement between the ribs.',
      ),
      'symptoms.palmar_pallor' => (
        'Open the palm in good light and compare the palm colour with the caregiver’s. Very pale palms need referral review.',
        'Check the palm in good light and compare the colour with the caregiver’s palm.',
      ),
      'symptoms.lethargic_or_unconscious' => (
        'Call the patient’s name and gently touch the shoulder. Record yes if they are difficult to wake or do not respond normally.',
        'Call the patient and gently touch the shoulder. Note whether they respond normally.',
      ),
      'symptoms.skin_pinch' => (
        'Pinch the skin of the abdomen for one second, release, and watch how quickly it returns. Ask the caregiver before checking.',
        'With consent, pinch abdominal skin for one second and observe how quickly it returns.',
      ),
      'symptoms.sunken_eyes' => (
        'Ask the caregiver whether the eyes look deeper or more sunken than usual for this patient.',
        'Ask whether the eyes look deeper or more sunken than usual.',
      ),
      _ => null,
    };
    if (guidance == null || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to check'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.medical_information_outlined, size: 48),
            const SizedBox(height: 12),
            Text(guidance.$1),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _tts.speak(
                text: language == 'en' ? guidance.$1 : guidance.$2,
                language: language,
              ),
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text('Read aloud'),
            ),
          ],
        ),
      ),
    );
  }

  void _answer(Object? raw) {
    final flow = _flow;
    if (flow == null || _index >= _visible.length) return;
    final currentQuestion = _visible[_index];
    flow.answer(currentQuestion.id, raw);
    _deriveWeightForAgeScore(flow, currentQuestion, raw);
    final visible = _stableVisibleQuestions(_visible, flow);

    // Natural sequential progression: step forward to the immediate next question
    // (currentIndex + 1) without erratic jumps.
    final currentIdx = visible.indexWhere((q) => q.id == currentQuestion.id);

    // Check if every answerable question has been answered
    bool isAnswerable(BankQuestion q) =>
        _show(flow, q) && !_derivedFields.contains(q.inputField);

    final firstUnanswered = visible.indexWhere(
      (question) =>
          isAnswerable(question) && !flow.answeredIds.contains(question.id),
    );

    // If all answerable questions are answered, complete assessment immediately
    if (firstUnanswered < 0) {
      _openReadings();
      return;
    }

    int next;
    if (currentIdx >= 0 && currentIdx + 1 < visible.length) {
      next = currentIdx + 1;
    } else {
      next = firstUnanswered;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _visible = visible;
      _index = next;
      _answerError = null;
    });
    _loadAnswerIntoEditor(visible[next]);
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

  void _deriveWeightForAgeScore(
    FlowState flow,
    BankQuestion question,
    Object? raw,
  ) {
    if (question.inputField != 'vitals.weight_kg' || raw is! num) return;
    final age = _ageMonthsValue();
    if (age == null || age > 60 || (_sex != 'Female' && _sex != 'Male')) {
      return;
    }
    // NEEDS CLINICIAN VALIDATION: the bundled WHO LMS lookup is reused here
    // only to replace an unmeasurable Z-score question with a derived value.
    final zScore = WhoGrowthCalculator.calculateWaz(
      weightKg: raw.toDouble(),
      ageMonths: age.toDouble(),
      sex: _sex == 'Male' ? 'M' : 'F',
    );
    flow.seedInput('vitals.weight_for_age_zscore', zScore);
    _derivedFields.add('vitals.weight_for_age_zscore');
  }

  void _submitNumber(BankQuestion question) {
    final bounds = _numericBoundsFor(question);
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

    final flow = _flow;
    if (flow != null &&
        (question.inputField == 'vitals.systolic_bp' ||
            question.inputField == 'vitals.diastolic_bp')) {
      final systolic = question.inputField == 'vitals.systolic_bp'
          ? value
          : flow.answers['vitals.systolic_bp'] as num?;
      final diastolic = question.inputField == 'vitals.diastolic_bp'
          ? value
          : flow.answers['vitals.diastolic_bp'] as num?;
      if (systolic != null && diastolic != null && systolic <= diastolic) {
        setState(
          () => _answerError =
              'Check blood pressure: systolic must be higher than diastolic.',
        );
        return;
      }
    }
    _answer(bounds.decimals == 0 ? value.toInt() : value);
  }

  void _submitText() {
    final value = _answerController.text.trim();
    if (value.isEmpty) {
      setState(() => _answerError = 'Enter a response.');
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
    _loadAnswerIntoEditor(_visible[next]);
  }

  void _loadAnswerIntoEditor(BankQuestion question) {
    final stored = _flow?.answers[question.inputField];
    if (question.type == 'number' || question.type == 'text') {
      _answerController.text = stored?.toString() ?? '';
      _answerController.selection = TextSelection.fromPosition(
        TextPosition(offset: _answerController.text.length),
      );
    } else {
      _answerController.clear();
    }
  }

  Future<void> _openReadings() async {
    if (_flow == null) return;
    FocusScope.of(context).unfocus();
    await _continueFromReadings();
  }

  Future<void> _continueFromReadings() async {
    final flow = _flow;
    if (flow == null) return;
    final issues = _validateIntakeMeasurements();
    if (issues.isNotEmpty) {
      setState(() {
        _intakeIssues = issues;
        _error = issues.first.message;
        _phase = _Phase.intake;
        _readingsExpanded = true;
      });
      return;
    }
    _seedClinicalContext(flow);
    final weight = num.tryParse(_weight.text.trim());
    if (weight != null) {
      BankQuestion? weightQuestion;
      for (final question in flow.questions) {
        if (question.inputField == 'vitals.weight_kg') {
          weightQuestion = question;
          break;
        }
      }
      if (weightQuestion != null) {
        _deriveWeightForAgeScore(flow, weightQuestion, weight);
      }
    }
    await _finish(flow);
  }

  Future<void> _finish(FlowState flow) async {
    final session = _session;
    if (session == null) return;
    final age = _ageMonthsValue() ?? 24;
    final location = _location.text.trim().isNotEmpty
        ? _location.text.trim()
        : (_wardId.isNotEmpty ? 'Ward $_wardId' : 'Local Community');
    if (flow.answers['symptoms.convulsions'] != true &&
        !flow.answers.containsKey('symptoms.convulsing_now')) {
      flow.answers['symptoms.convulsing_now'] = false;
    }
    final code = 'CASE-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final patientName = _normalizedPatientName.isNotEmpty
        ? _normalizedPatientName
        : 'Patient ($code)';
    final input = flow.toAssessmentInput(
      patientId: code,
      ageMonths: age,
      sex: _sex.isNotEmpty ? _sex : 'Female',
    );
    final score = session.model?.score(input, session.prior);
    final decision = session.loop.decide(input, score: score);
    final facility = session.loop.pack.facilityForWard(flow.wardId);
    final note = ReferralNote.fromResult(
      decision.engineView,
      PatientProfile(
        id: code,
        abhaId: '91-0000-0000-${age.toString().padLeft(4, '0')}',
        name: patientName,
        ageMonths: age,
        sex: _sex.isNotEmpty ? _sex : 'Female',
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
          ? '—'
          : stored == true
          ? 'Yes'
          : stored == false
          ? 'No'
          : '$stored';
      answers.add((_questionPrompt(question, _lang), shown));
    }
    void addReading(String label, String raw) {
      final value = raw.trim();
      if (value.isEmpty) return;
      answers.add((label, value));
    }

    addReading('Respiratory rate', _respiratoryRate.text);
    addReading('Pulse', _pulseRate.text);
    addReading('Oximeter', _spo2.text);
    addReading('Temperature', _temperature.text);
    addReading('Weight', _weight.text);
    addReading('Systolic BP', _systolicBp.text);
    addReading('Diastolic BP', _diastolicBp.text);
    final noteText = _referralNote.text.trim();
    if (noteText.isNotEmpty) answers.add(('Referral note', noteText));
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
      _error = null;
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
        title: Text(switch (_phase) {
          _Phase.ticket => _triageCopy(lang, 'referralTicket'),
          _ => _triageCopy(lang, 'triage'),
        }),
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
          controller: _householdHeadSearch,
          textCapitalization: TextCapitalization.words,
          onChanged: _searchHouseholdHeads,
          decoration: const InputDecoration(
            labelText: 'Household head',
            hintText: 'Search household head name',
            prefixIcon: Icon(Icons.home_work_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        if (_householdSuggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: _householdSuggestions.map((household) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.home_outlined),
                  title: Text(household.headName),
                  subtitle: Text(
                    '${household.village}${household.hamlet == null ? '' : ' · ${household.hamlet}'}',
                  ),
                  onTap: () => _selectHousehold(household),
                );
              }).toList(),
            ),
          ),
        ],
        if (_selectedHousehold != null) ...[
          const SizedBox(height: 12),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: const Icon(Icons.home_work_outlined),
            title: Text(_selectedHousehold!.headName),
            subtitle: const Text('Household head'),
          ),
          if (_householdMembers.isNotEmpty)
            DropdownButtonFormField<String>(
              value: _selectedMember?.id,
              decoration: const InputDecoration(
                labelText: 'Select household member',
                prefixIcon: Icon(Icons.person_search_outlined),
                border: OutlineInputBorder(),
              ),
              items: _householdMembers
                  .map(
                    (member) => DropdownMenuItem(
                      value: member.id,
                      child: Text(member.name),
                    ),
                  )
                  .toList(),
              onChanged: (id) {
                final member = _householdMembers.firstWhere((m) => m.id == id);
                _selectMember(member);
              },
            ),
          if (_householdMembers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('No registered members in this household yet.'),
            ),
          if (_selectedMember != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${_selectedMember!.name} · $_displayAge · ${_sex.isEmpty ? 'Gender not recorded' : _sex}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AshaColors.textSecondary,
                ),
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
          readOnly: _selectedMember != null,
        ),
        const SizedBox(height: 12),
        if (_ageUnit == 'child') ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  onChanged: _syncAgeBandFromInput,
                  decoration: InputDecoration(
                    labelText: _triageCopy(lang, 'years'),
                    border: const OutlineInputBorder(),
                  ),
                  readOnly: _selectedMember != null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _ageMonthsPart,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _syncAgeBandFromInput(_age.text),
                  decoration: InputDecoration(
                    labelText: _triageCopy(lang, 'months'),
                    border: const OutlineInputBorder(),
                  ),
                  readOnly: _selectedMember != null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _displayAge,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ] else ...[
          TextField(
            controller: _age,
            keyboardType: TextInputType.number,
            onChanged: _syncAgeBandFromInput,
            decoration: InputDecoration(
              labelText: _triageCopy(lang, 'age'),
              hintText: _triageCopy(lang, 'ageHint'),
              border: const OutlineInputBorder(),
            ),
            readOnly: _selectedMember != null,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            key: const Key('triage_age_unit_dropdown'),
            initialValue: _ageUnit,
            decoration: InputDecoration(
              labelText: _triageCopy(lang, 'ageUnit'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
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
        ],
        if ((_ageMonthsValue() ?? 999) < 24) ...[
          const SizedBox(height: 12),
          TextField(
            key: const Key('triage_exact_age_days'),
            controller: _ageDays,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Exact age in days (optional)',
              helperText: 'Shown for infants and young children only.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: const Key('triage_sex_dropdown'),
          initialValue: _sex.isEmpty ? null : _sex,
          decoration: InputDecoration(
            labelText: _triageCopy(lang, 'sexContext'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          items: [
            DropdownMenuItem(
              value: 'Male',
              child: Text(_triageCopy(lang, 'male')),
            ),
            DropdownMenuItem(
              value: 'Female',
              child: Text(_triageCopy(lang, 'female')),
            ),
            DropdownMenuItem(
              value: 'Transgender',
              child: Text(_triageCopy(lang, 'transgender')),
            ),
          ],
          onChanged: _selectedMember == null
              ? (value) => setState(() => _sex = value ?? 'Male')
              : null,
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
          readOnly: _selectedMember != null,
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
          child: Column(
            children: [
              ExpansionTile(
                initiallyExpanded: true,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                expandedAlignment: Alignment.centerLeft,
                title: Text(
                  _triageCopy(lang, 'contextFilters'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(_triageCopy(lang, 'contextFiltersSub')),
                childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _triageCopy(lang, 'nearbyIllness'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final illness in _illnesses)
                          Builder(
                            builder: (context) {
                              final isSelected = _chosen.contains(illness.$1);
                              return FilterChip(
                                label: Text(
                                  illness.$2,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AshaColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AshaColors.primary,
                                backgroundColor: AshaColors.surfaceMuted,
                                checkmarkColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? AshaColors.primary
                                      : AshaColors.borderSubtle,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (on) => setState(() {
                                  if (on) {
                                    _chosen.add(illness.$1);
                                  } else {
                                    _chosen.remove(illness.$1);
                                  }
                                }),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _triageCopy(lang, 'reportedContext'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final contextChip in _reportedContexts)
                          Builder(
                            builder: (context) {
                              final isSelected = _reportedContext.contains(
                                contextChip.$1,
                              );
                              return FilterChip(
                                label: Text(
                                  contextChip.$2,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AshaColors.textPrimary,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AshaColors.primary,
                                backgroundColor: AshaColors.surfaceMuted,
                                checkmarkColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected
                                      ? AshaColors.primary
                                      : AshaColors.borderSubtle,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (selected) => setState(() {
                                  if (selected) {
                                    _reportedContext.add(contextChip.$1);
                                  } else {
                                    _reportedContext.remove(contextChip.$1);
                                  }
                                }),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),
              ExpansionTile(
                key: ValueKey('triage-readings-$_readingsExpanded'),
                initiallyExpanded: _readingsExpanded,
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                expandedAlignment: Alignment.centerLeft,
                title: Text(
                  _triageCopy(lang, 'readingsTitle'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(_triageCopy(lang, 'readingsHint')),
                childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                children: [
                  _clinicalNumber(
                    key: const Key('triage_respiratory_rate'),
                    controller: _respiratoryRate,
                    fieldKey: 'vitals.respiratory_rate',
                    label: 'Respiratory rate',
                    suffix: '/min',
                  ),
                  const SizedBox(height: 10),
                  _clinicalNumber(
                    key: const Key('triage_pulse_rate'),
                    controller: _pulseRate,
                    fieldKey: 'vitals.pulse_rate',
                    label: 'Pulse',
                    suffix: 'beats/min',
                  ),
                  const SizedBox(height: 10),
                  _clinicalNumber(
                    key: const Key('triage_spo2'),
                    controller: _spo2,
                    fieldKey: 'vitals.spo2',
                    label: 'Oximeter',
                    suffix: '%',
                  ),
                  const SizedBox(height: 10),
                  _clinicalNumber(
                    key: const Key('triage_temperature'),
                    controller: _temperature,
                    fieldKey: 'vitals.temp_c',
                    label: 'Temperature',
                    suffix: '°C',
                    decimal: true,
                  ),
                  const SizedBox(height: 10),
                  _clinicalNumber(
                    key: const Key('triage_weight'),
                    controller: _weight,
                    fieldKey: 'vitals.weight_kg',
                    label: 'Weight',
                    suffix: 'kg',
                    decimal: true,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _clinicalNumber(
                          key: const Key('triage_systolic_bp'),
                          controller: _systolicBp,
                          fieldKey: 'vitals.systolic_bp',
                          label: 'Systolic BP',
                          suffix: 'mmHg',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _clinicalNumber(
                          key: const Key('triage_diastolic_bp'),
                          controller: _diastolicBp,
                          fieldKey: 'vitals.diastolic_bp',
                          label: 'Diastolic BP',
                          suffix: 'mmHg',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          key: const Key('triage_hotspot_weightage_card'),
          margin: EdgeInsets.zero,
          elevation: 0,
          color: _adaptiveFromRadar
              ? AshaColors.primary.withValues(alpha: 0.05)
              : AshaColors.surfaceMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: _adaptiveFromRadar
                  ? AshaColors.primary
                  : AshaColors.borderSubtle,
              width: _adaptiveFromRadar ? 1.5 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _adaptiveFromRadar
                            ? AshaColors.primary.withValues(alpha: 0.15)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.radar_rounded,
                        color: _adaptiveFromRadar
                            ? AshaColors.primary
                            : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Disease Radar & Hotspot Weightage',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AshaColors.textPrimary,
                            ),
                          ),
                          Text(
                            packModules.isNotEmpty
                                ? 'Active signals: ${packModules.join(', ')}'
                                : 'Active signals: Regional disease surveillance',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AshaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      key: const Key('triage_adaptive_radar_button'),
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => setState(
                        () => _adaptiveFromRadar = !_adaptiveFromRadar,
                      ),
                      child: Transform.scale(
                        scale: 0.85,
                        child: Switch.adaptive(
                          key: const Key('triage_hotspot_weightage_switch'),
                          value: _adaptiveFromRadar,
                          activeColor: AshaColors.primary,
                          onChanged: (enabled) {
                            setState(() => _adaptiveFromRadar = enabled);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _adaptiveFromRadar
                      ? (packModules.isNotEmpty
                            ? '✓ Outbreak weightage ENABLED: ${packModules.join(', ')} questions & risk priors will influence triage score.'
                            : '✓ Outbreak weightage ENABLED: Regional epidemiological radar active.')
                      : '○ Outbreak weightage DISABLED: Evaluating symptoms strictly from patient observations without area bias.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _adaptiveFromRadar
                        ? const Color(0xFF15803D)
                        : AshaColors.textSecondary,
                  ),
                ),
              ],
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

  Widget _referralNoteEditor() {
    final installed = ref.watch(offlinePackProvider).appLanguageCodes;
    final languages = [
      for (final language in supportedLanguages)
        if (installed.contains(language.code)) language,
    ];
    if (languages.isEmpty) {
      languages.add(supportedLanguages.first);
    }
    final selected =
        languages.any((language) => language.code == _referralNoteLanguage)
        ? _referralNoteLanguage
        : languages.first.code;
    final noteCopy = _referralNoteCopy[selected] ?? _referralNoteCopy['en']!;
    final selectedLanguage = languages.firstWhere(
      (language) => language.code == selected,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('triage-referral-language-$selected'),
          initialValue: selected,
          decoration: const InputDecoration(
            labelText: 'Note language',
            helperText: 'Only languages downloaded on this phone',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final language in languages)
              DropdownMenuItem(
                value: language.code,
                child: Text('${language.nativeName} · ${language.englishName}'),
              ),
          ],
          onChanged: (code) {
            if (code == null) return;
            setState(() => _referralNoteLanguage = code);
          },
        ),
        const SizedBox(height: 10),
        TextField(
          key: const Key('triage_referral_note'),
          controller: _referralNote,
          minLines: 3,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: noteCopy.$1,
            hintText: '${noteCopy.$2} (${selectedLanguage.nativeName})',
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('triage_referral_translate'),
          icon: _referralTranslateBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.translate_rounded),
          label: Text(
            _referralTranslateBusy
                ? 'Translating with Bhasha…'
                : 'Translate ${selectedLanguage.nativeName} to English',
          ),
          onPressed: _referralBusy
              ? null
              : () => _translateReferralNote(selectedLanguage),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: _referralVoiceBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.mic_none_rounded),
          label: Text(
            _referralVoiceBusy
                ? 'Listening and translating…'
                : 'Speak in ${selectedLanguage.nativeName} → English',
          ),
          onPressed: _referralBusy
              ? null
              : () => _captureReferralVoice(selectedLanguage),
        ),
        if (_referralNoteEnglish.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'English',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            child: Text(
              _referralNoteEnglish.trim(),
              style: const TextStyle(height: 1.35),
            ),
          ),
        ],
      ],
    );
  }

  bool get _referralBusy => _referralVoiceBusy || _referralTranslateBusy;

  IndicLanguage? _indicFor(AppLanguage language) {
    for (final candidate in indicLanguages) {
      if (candidate.iso == language.code || candidate.code == language.code) {
        return candidate;
      }
    }
    return null;
  }

  Future<String> _bhashaToEnglish(String text, AppLanguage language) async {
    final source = text.trim();
    if (source.isEmpty) {
      throw StateError('Write the referral note before translating.');
    }
    if (language.code == 'en') return source;
    final indic = _indicFor(language);
    if (indic == null) {
      throw StateError(
        'Bhasha cannot translate ${language.englishName} to English on this phone.',
      );
    }
    final directory = await getApplicationSupportDirectory();
    final store = ModelStore(Directory('${directory.path}/bhasha-models'));
    if (!store.isReady) {
      throw StateError(
        'Install the Bhasha interpreter pack before translating.',
      );
    }
    final translator = await IndicTranslator.open(store.mtDirectory);
    try {
      return translator.translate(source, indic).trim();
    } finally {
      translator.close();
    }
  }

  Future<void> _translateReferralNote(AppLanguage language) async {
    setState(() {
      _referralTranslateBusy = true;
      _error = null;
    });
    try {
      final english = await _bhashaToEnglish(_referralNote.text, language);
      if (!mounted) return;
      setState(() => _referralNoteEnglish = english);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _referralTranslateBusy = false);
    }
  }

  Future<void> _captureReferralVoice(AppLanguage language) async {
    final directory = await getApplicationSupportDirectory();
    final store = ModelStore(Directory('${directory.path}/bhasha-models'));
    if (!store.isReady) {
      if (mounted) {
        setState(
          () => _error =
              'Install the Bhasha interpreter pack before using voice typing.',
        );
      }
      return;
    }
    final recorder = AudioRecorder();
    String? path;
    try {
      if (!await recorder.hasPermission()) {
        if (mounted) {
          setState(() => _error = 'Allow microphone access for voice typing.');
        }
        return;
      }
      setState(() {
        _referralVoiceBusy = true;
        _error = null;
      });
      path = '${directory.path}/triage_referral_note.wav';
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text('Speak in ${language.nativeName}'),
          content: const Text('Speak the referral note, then tap Done.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      await recorder.stop();
      final heard = SpeechEngine.transcribe(
        wavPath: path,
        modelPath: store.asrModelPath,
        tokensPath: store.asrTokensPath,
      );
      final spoken = heard.trim();
      if (spoken.isEmpty) {
        throw SpeechException('No speech was detected.');
      }
      if (mounted) {
        setState(() {
          _referralNote.text = _referralNote.text.trim().isEmpty
              ? spoken
              : '${_referralNote.text.trim()} $spoken';
          _referralNote.selection = TextSelection.collapsed(
            offset: _referralNote.text.length,
          );
        });
      }
      final english = await _bhashaToEnglish(spoken, language);
      if (mounted) setState(() => _referralNoteEnglish = english);
    } catch (error) {
      if (mounted) setState(() => _error = 'Voice typing failed: $error');
    } finally {
      await recorder.dispose();
      if (path != null) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _referralVoiceBusy = false);
    }
  }

  Widget _clinicalNumber({
    required Key key,
    required TextEditingController controller,
    required String fieldKey,
    required String label,
    required String suffix,
    bool decimal = false,
  }) {
    final bounds = TriageInputValidation.boundsFor(fieldKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: key,
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          decoration: InputDecoration(
            labelText: label,
            suffixText: suffix,
            helperText: bounds == null
                ? null
                : 'Plausible range: ${bounds.rangeLabel}',
            errorText: _intakeIssueFor(fieldKey)?.message,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
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
              const SizedBox(height: 8),
              Text(
                _extendedClinicalContext
                    ? _triageCopy(lang, 'adultProtocol')
                    : _triageCopy(lang, 'childProtocol'),
                style: const TextStyle(
                  color: AshaColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
        _loadAnswerIntoEditor(question);
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
            if (question.module != 'core' &&
                question.module != 'adult' &&
                question.module != 'adult_vitals') ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  '${_triageCopy(lang, 'addedAreaSignal')}: ${question.module}',
                  style: const TextStyle(
                    color: AshaColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (_intakeSeededFields.contains(question.inputField))
              Padding(
                padding: const EdgeInsets.only(left: 40, top: 6),
                child: Text(
                  'Answered from intake — tap to review',
                  style: const TextStyle(
                    color: AshaColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_derivedFields.contains(question.inputField))
              const Padding(
                padding: EdgeInsets.only(left: 40, top: 6),
                child: Text(
                  'Calculated offline from measured weight and age',
                  style: TextStyle(
                    color: AshaColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
              if (const {
                'symptoms.chest_indrawing',
                'symptoms.palmar_pallor',
                'symptoms.lethargic_or_unconscious',
                'symptoms.skin_pinch',
                'symptoms.sunken_eyes',
              }.contains(question.inputField)) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _showHowToCheck(question, lang),
                  icon: const Icon(Icons.info_outline_rounded),
                  label: const Text('How to check'),
                ),
              ],
            ] else if (answered) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Text(
                  stored == null
                      ? '—'
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _answerBar(BankQuestion question) {
    final isBoolean = question.type == 'bool';
    final lang = ref.read(languageProvider).languageCode;
    final stored = _flow?.answers[question.inputField];
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
                    tooltip: _index >= _visible.length - 1
                        ? _triageCopy(lang, 'continueTicket')
                        : _triageCopy(lang, 'nextQuestion'),
                    onPressed: () {
                      final flow = _flow;
                      final done =
                          flow != null &&
                          _visible.every(
                            (question) =>
                                !_show(flow, question) ||
                                _derivedFields.contains(question.inputField) ||
                                flow.answeredIds.contains(question.id),
                          );
                      if (done) {
                        _openReadings();
                      } else {
                        _moveQuestion(1);
                      }
                    },
                    icon: Icon(
                      _index >= _visible.length - 1
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      color: _index >= _visible.length - 1
                          ? AshaColors.primary
                          : null,
                    ),
                  ),
                ],
              ),
              Builder(
                builder: (context) {
                  final flow = _flow;
                  final allAnswered =
                      flow != null &&
                      _visible.every(
                        (q) =>
                            !_show(flow, q) ||
                            _derivedFields.contains(q.inputField) ||
                            flow.answeredIds.contains(q.id),
                      );
                  if (allAnswered) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SizedBox(
                        height: 44,
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('triage_complete_button'),
                          onPressed: () {
                            _openReadings();
                          },
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                          ),
                          label: Text(
                            _triageCopy(lang, 'continueTicket'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AshaColors.primary,
                            foregroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: AshaShapes.buttonRadius,
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              Row(
                children: [
                  if (isBoolean) ...[
                    _bottomAnswer(
                      label: _triageCopy(lang, 'yes'),
                      icon: Icons.check_rounded,
                      color: const Color(0xFFE9F0EC),
                      foregroundColor: AshaColors.textPrimary,
                      selected: stored == true,
                      onPressed: () => _answer(true),
                    ),
                    const SizedBox(width: 6),
                    _bottomAnswer(
                      label: _triageCopy(lang, 'no'),
                      icon: Icons.close_rounded,
                      color: const Color(0xFFF2F4F3),
                      foregroundColor: AshaColors.textPrimary,
                      selected: stored == false,
                      onPressed: () => _answer(false),
                    ),
                  ] else
                    const Spacer(),
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
    bool selected = false,
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
            shape: RoundedRectangleBorder(
              borderRadius: AshaShapes.buttonRadius,
              side: selected
                  ? BorderSide(color: AshaColors.primaryDark, width: 2)
                  : BorderSide.none,
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
    if (_ageUnit == 'child') {
      final years = int.tryParse(_age.text.trim());
      final months = int.tryParse(_ageMonthsPart.text.trim()) ?? 0;
      if (years == null || years < 0 || months < 0 || months > 11) return null;
      return years * 12 + months;
    }
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
    if (months < 60) return '${months ~/ 12} year ${months % 12} month';
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
    if (_ageUnit == 'child') {
      final total = _ageMonthsValue();
      if (total == null) return;
      setState(() {
        _ageBand = total <= 2 ? AgeBandCode.infant02m : AgeBandCode.child2m5y;
      });
      return;
    }
    final value = int.tryParse(raw.trim());
    if (value == null || value < 0) return;
    final next = _ageBandForInput(value);
    setState(() => _ageBand = next);
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

  ({String unit, num min, num max, int decimals})? _numericBoundsFor(
    BankQuestion question,
  ) {
    final safety = TriageInputValidation.boundsFor(question.inputField);
    if (safety != null) {
      return (
        unit: safety.unit,
        min: safety.min,
        max: safety.max,
        decimals: safety.decimals,
      );
    }
    final bounds = question.numeric;
    if (bounds == null) return null;
    return (
      unit: bounds.unit,
      min: bounds.min,
      max: bounds.max,
      decimals: bounds.decimals,
    );
  }

  Widget _answerControls(BankQuestion question) {
    final lang = ref.read(languageProvider).languageCode;
    switch (question.type) {
      case 'number':
        final bounds = _numericBoundsFor(question);
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
                'Plausible range: ${bounds.min}–${bounds.max} ${bounds.unit}',
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
    final selected =
        _flow?.answers[_visible[_index].inputField] == option.value;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? AshaColors.primary.withValues(alpha: .06)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: AshaShapes.cardRadius,
          side: BorderSide(
            color: selected ? AshaColors.primary : AshaColors.borderSubtle,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: AshaShapes.cardRadius,
          onTap: () => _answer(option.value),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: AshaColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected
                      ? AshaColors.primary
                      : const Color(0xFF9CA3AF),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ticket() {
    final decision = _decision;
    final note = _note;
    if (decision == null || note == null) return const SizedBox.shrink();
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
        _referralNoteEditor(),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Color(0xFF9F2D2D))),
        ],
        const SizedBox(height: 12),
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
