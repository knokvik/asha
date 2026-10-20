import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:triage/triage.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/l10n/language_selector_dialog.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/voice/tts_service.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/adaptive_session.dart';
import 'language_bridge_screen.dart';

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
  final _answerController = TextEditingController();
  final _questionScrollController = ScrollController();
  final _questionKeys = <String, GlobalKey>{};
  final _tts = TtsService();
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

  static const _illnesses = <(String, String)>[
    ('dengue', 'Dengue-like'),
    ('measles', 'Measles-like'),
    ('diarrhoea_cluster', 'Diarrhoea'),
    ('aes', 'AES / brain fever'),
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
    _answerController.dispose();
    _questionScrollController.dispose();
    super.dispose();
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
    final age = int.tryParse(_age.text.trim());
    if (session == null ||
        age == null ||
        age < 0 ||
        age > 59 ||
        _name.text.trim().isEmpty) {
      setState(
        () => _error = 'Enter the child’s name and an age from 0 to 59 months.',
      );
      return;
    }
    final flow = FlowBuilder(session.loop.pack)
        .build(wardId: _wardId, extraModules: _chosen);
    session.loop.openAssessment(wardId: _wardId);
    final visible = [
      for (final question in flow.questions)
        if (_show(flow, question)) question,
    ];
    setState(() {
      _flow = flow;
      _visible = visible;
      _index = 0;
      _phase = _Phase.questions;
      _error = null;
      _answerError = null;
    });
    _questionKeys
      ..clear()
      ..addEntries(
        visible.map((question) => MapEntry(question.id, GlobalKey())),
      );
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
      default:
        return true;
    }
  }

  Future<void> _speak(BankQuestion question) async {
    await _tts.speak(text: question.prompt(_lang), language: _lang);
  }

  void _answer(Object? raw) {
    final flow = _flow;
    if (flow == null || _index >= _visible.length) return;
    flow.answer(_visible[_index].id, raw);
    final visible = [
      for (final question in flow.questions)
        if (_show(flow, question)) question,
    ];
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

  Future<void> _finish(FlowState flow) async {
    final session = _session;
    final age = int.tryParse(_age.text.trim());
    if (session == null || age == null) return;
    if (flow.answers['symptoms.convulsions'] != true &&
        !flow.answers.containsKey('symptoms.convulsing_now')) {
      flow.answers['symptoms.convulsing_now'] = false;
    }
    final code = 'CASE-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final input = flow.toAssessmentInput(
      patientId: code,
      ageMonths: age,
      sex: 'F',
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
        sex: 'F',
        village: 'Pimpri',
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
    var queueNote =
        'Ticket is in the sync queue. It sends when the network is up, and retries on a fixed interval.';
    try {
      await ref
          .read(syncEngineProvider)
          .enqueue(
            table: 'triage_tickets',
            recordId: code,
            operation: 'insert',
            payload: {
              'name': _name.text.trim(),
              'age_months': age,
              'ward_id': flow.wardId,
              'flag': decision.flag.wireName,
              'sms': note.toSms(),
              'modules': flow.activeModules,
              'worker_modules': _chosen.toList(),
            },
            priority: decision.flag == TriageFlag.red
                ? SyncPriority.critical
                : SyncPriority.metadata,
          );
      await ref.read(syncCoordinatorProvider)?.syncNow();
    } catch (error) {
      queueNote =
          'QR is ready. The phone queue opens after the PIN session: $error';
    }
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
      answers.add((question.prompt(_lang), shown));
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
        title: Text(_phase == _Phase.ticket ? 'Referral ticket' : 'Triage'),
        actions: [
          IconButton(
            tooltip: 'Speaker language',
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
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Child’s name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _age,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Age in months',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nearby illness',
          style: TextStyle(fontWeight: FontWeight.w700),
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
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(color: Color(0xFF9F2D2D))),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _session == null ? null : _startQuestions,
          child: Text('Start questions ($lang)'),
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
                    'Question ${_index + 1} of ${_visible.length}',
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
    return Container(
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
                  question.prompt(lang),
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
                  ? 'Common question'
                  : 'Adaptive · ${question.module}',
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
              label: Text('Speak in ${_languageName(lang)}'),
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
                    ? 'Not sure / cannot check'
                    : stored == true
                    ? 'Yes'
                    : stored == false
                    ? 'No'
                    : '$stored',
                style: const TextStyle(
                  color: AshaColors.primaryDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 40),
              child: Text(
                'Next question',
                style: TextStyle(color: AshaColors.textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _answerBar(BankQuestion question) {
    final isBoolean = question.type == 'bool';
    return Material(
      color: Colors.white,
      elevation: 10,
      shadowColor: const Color(0x24000000),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Row(
            children: [
              if (isBoolean) ...[
                _bottomAnswer(
                  label: 'Yes',
                  icon: Icons.check_rounded,
                  color: AshaColors.primary,
                  onPressed: () => _answer(true),
                ),
                const SizedBox(width: 6),
                _bottomAnswer(
                  label: 'No',
                  icon: Icons.close_rounded,
                  color: AshaColors.alertHighRisk,
                  onPressed: () => _answer(false),
                ),
                const SizedBox(width: 6),
                _bottomAnswer(
                  label: 'Not sure',
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
        ),
      ),
    );
  }

  Widget _bottomAnswer({
    required String label,
    required IconData icon,
    required Color color,
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
            foregroundColor: Colors.white,
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

  Widget _answerControls(BankQuestion question) {
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
                labelText: 'Enter value',
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
              label: const Text('Save value'),
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
                labelText: 'Enter response',
                errorText: _answerError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _submitText,
              icon: const Icon(Icons.check_rounded),
              label: const Text('Save response'),
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
    return OutlinedButton.icon(
      key: const Key('triage_answer_unknown'),
      onPressed: () => _answer(null),
      icon: const Icon(Icons.help_outline_rounded),
      label: const Text('Not sure / cannot check'),
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
                          ('Age', '${_ageMonths ?? ''} months'),
                          ('Ward', _flow?.wardId ?? '—'),
                          ('Facility', note.facility.name),
                          ('Status', _online ? 'Online' : 'Offline queue'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _TicketDashedDivider(),
                      const SizedBox(height: 14),
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
