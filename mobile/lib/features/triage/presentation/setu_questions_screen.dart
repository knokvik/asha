import 'dart:convert';

import 'package:core_triage/core_triage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:triage/triage.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/bhasha/settings_store.dart';
import '../../../core/voice/tts_service.dart';
import '../domain/adaptive_session.dart';
import '../domain/setu_case.dart';
import 'adaptive_referral_screen.dart';
import 'language_bridge_screen.dart';
import 'setu_question_catalogue.dart';
import 'setu_referral_qr_screen.dart';

/// Setu's one-question walk. Unknown records nothing, so the rules ask again
/// instead of reading the gap as "no".
class SetuQuestionsScreen extends StatefulWidget {
  const SetuQuestionsScreen({super.key});

  @override
  State<SetuQuestionsScreen> createState() => _SetuQuestionsScreenState();
}

class _SetuQuestionsScreenState extends State<SetuQuestionsScreen> {
  final _ageController = TextEditingController();
  RuleSet? _ruleset;
  String? _loadError;
  int? _ageMonths;
  List<SetuQuestion> _questions = const [];
  int _index = 0;
  final Map<String, SourcedValue> _fields = {};
  var _answeredAny = false;
  var _stuck = false;
  ClinicalTriageResult? _held;
  AdaptiveSession? _session;
  FlowState? _flow;
  String _wardId = 'W3';
  var _booted = false;
  var _reaskedDanger = false;
  final _tts = TtsService();
  SettingsStore? _voiceSettings;
  String _askLang = 'hi';
  String? _spokenLine;
  String? _spokenFor;
  var _speaking = false;

  @override
  void initState() {
    super.initState();
    _loadRules();
    _loadVoiceLanguage();
  }

  Future<void> _loadVoiceLanguage() async {
    final store = SettingsStore();
    await store.load();
    if (!mounted) return;
    final iso = store.source.iso;
    setState(() {
      _voiceSettings = store;
      _askLang = iso == 'mr' || iso == 'hi' ? iso : 'en';
    });
  }

  Future<void> _setAskLanguage(String code) async {
    setState(() => _askLang = code);
    if (code == 'hi') await _voiceSettings?.setSource('hi-IN');
    if (code == 'mr') await _voiceSettings?.setSource('mr-IN');
  }

  String _questionInLanguage(SetuQuestion question) {
    final bank = _flow?.questionById(question.path);
    return bank?.prompt(_askLang) ?? question.prompt;
  }

  Future<void> _speakQuestion(SetuQuestion question) async {
    final text = _questionInLanguage(question);
    setState(() {
      _spokenLine = text;
      _spokenFor = question.path;
      _speaking = true;
    });
    await _tts.speak(text: text, language: _askLang);
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _loadRules() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/triage/imci-mvp-1.0.0.json',
      );
      final ruleset = RuleSet.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
      final session = await AdaptiveSession.load();
      if (!mounted) return;
      final ward = session.resolve(session.loop.pack.sampleFix).wardId ?? 'W3';
      setState(() {
        _ruleset = ruleset;
        _session = session;
        _wardId = ward;
        _booted = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _loadError = 'Could not load the triage questions. $error',
      );
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _start() {
    final months = int.tryParse(_ageController.text.trim());
    if (months == null || months < 0 || months > 240) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the child’s age in months.')),
      );
      return;
    }
    final session = _session;
    if (session != null) {
      if (months >= 60) {
        _showOutOfScope(months);
        return;
      }
      final flow = session.loop.openAssessment(wardId: _wardId, month: months);
      final visible = _visible(flow);
      setState(() {
        _ageMonths = months;
        _flow = flow;
        _questions = visible.map(_asSetu).toList(growable: false);
        _index = 0;
        _fields.clear();
        _answeredAny = false;
        _stuck = false;
        _held = null;
        _reaskedDanger = false;
      });
      return;
    }
    if (months < 2 || months >= 60) {
      _showOutOfScope(months);
      return;
    }
    final questions = SetuQuestionCatalogue.forPaths(
      FieldPaths.redRequiredFields,
    );
    setState(() {
      _ageMonths = months;
      _questions = questions;
      _index = 0;
      _fields.clear();
      _answeredAny = false;
      _stuck = false;
      _held = null;
    });
  }

  SetuQuestion _asSetu(BankQuestion question) {
    final kind = switch (question.type) {
      'number' => SetuAnswerKind.numeric,
      'choice' => SetuAnswerKind.choice,
      _ => SetuAnswerKind.yesNo,
    };
    final bounds = question.numeric;
    return SetuQuestion(
      path: question.id,
      icon: Icons.health_and_safety_outlined,
      prompt: question.prompt('en'),
      kind: kind,
      options: [
        for (final option in question.options)
          SetuQuestionOption(
            value: option.value,
            label: option.label,
            icon: Icons.circle_outlined,
          ),
      ],
      numeric: bounds == null
          ? null
          : SetuNumericSpec(
              unit: bounds.unit,
              min: bounds.min,
              max: bounds.max,
              decimals: bounds.decimals,
            ),
    );
  }

  void _showOutOfScope(int months) {
    final ruleset = _ruleset;
    if (ruleset == null) return;
    final result = SetuCase(ageMonths: months).evaluate(ruleset);
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => _OutOfScopePage(result: result)));
  }

  void _answer(String path, SourcedValue? value) {
    final flow = _flow;
    final question = flow?.questionById(path);
    if (flow != null && question != null) {
      if (value == null) {
        flow.answer(question.id, null);
      } else if (question.type == 'bool') {
        flow.answer(question.id, value.value == 'YES');
      } else {
        flow.answer(question.id, value.value);
      }
      _answeredAny = true;
      _syncVisible(flow);
      return;
    }
    if (value != null) {
      _fields[path] = value;
      _answeredAny = true;
    }
    _advance();
  }

  /// Follow-up questions stay hidden until the symptom that needs them is Yes.
  /// A danger sign is stored, but it does not open a referral in the middle of the list.
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
      case 'core.zscore':
      case 'core.weight':
        return yes('symptoms.visible_severe_wasting') ||
            yes('symptoms.oedema_both_feet');
      case 'dengue.breeding':
        return false;
      default:
        return true;
    }
  }

  List<BankQuestion> _visible(FlowState flow) => [
    for (final question in flow.questions)
      if (_show(flow, question)) question,
  ];

  void _syncVisible(FlowState flow) {
    final visible = _visible(flow);
    final next = visible.indexWhere(
      (question) => !flow.answeredIds.contains(question.id),
    );
    if (next < 0) {
      setState(() => _questions = visible.map(_asSetu).toList(growable: false));
      _finish();
      return;
    }
    setState(() {
      _questions = visible.map(_asSetu).toList(growable: false);
      _index = next;
    });
  }

  void _advance() {
    final flow = _flow;
    if (flow != null) {
      _syncVisible(flow);
      return;
    }
    if (_index < _questions.length - 1) {
      setState(() => _index++);
      return;
    }
    _finish();
  }

  void _finish() {
    final flow = _flow;
    final session = _session;
    final age = _ageMonths;
    if (flow != null && session != null && age != null) {
      _finishAdaptive(flow, session, age);
      return;
    }
    final ruleset = _ruleset;
    if (ruleset == null || age == null) return;
    final result = SetuCase(ageMonths: age, fields: _fields).evaluate(ruleset);
    if (result.band == TriageBand.needsMoreInfo) {
      final again = SetuQuestionCatalogue.forPaths(result.blockingQuestions);
      if (!_answeredAny || again.isEmpty) {
        setState(() {
          _stuck = true;
          _held = result;
        });
        return;
      }
      setState(() {
        _questions = again;
        _index = 0;
        _answeredAny = false;
        _stuck = false;
      });
      return;
    }
    if (!result.band.isDecision) {
      setState(() {
        _stuck = true;
        _held = result;
      });
      return;
    }
    final code = 'CASE-${DateTime.now().millisecondsSinceEpoch % 100000}';
    final note = SetuCase(
      ageMonths: age,
      fields: _fields,
    ).referral(result, caseCode: code);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SetuReferralQrScreen(note: note, result: result),
      ),
    );
  }

  void _finishAdaptive(FlowState flow, AdaptiveSession session, int age) {
    if (flow.answers['symptoms.convulsions'] != true &&
        !flow.answers.containsKey('symptoms.convulsing_now')) {
      flow.answers['symptoms.convulsing_now'] = false;
    }
    if (!flow.earlyStopped && !flow.dangerComplete) {
      final missing = [
        for (final question in flow.questions)
          if (dangerFields.contains(question.inputField) &&
              !flow.answers.containsKey(question.inputField))
            question,
      ];
      if (missing.isNotEmpty && !_reaskedDanger) {
        setState(() {
          _reaskedDanger = true;
          _questions = missing.map(_asSetu).toList(growable: false);
          _index = 0;
          _stuck = false;
        });
        return;
      }
      if (missing.isNotEmpty) {
        setState(() => _stuck = true);
        return;
      }
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
        name: 'Demo child',
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdaptiveReferralScreen(decision: decision, note: note),
      ),
    );
  }

  String _moduleLine() {
    final active =
        _session?.loop.pack.activeModuleIds(_wardId) ?? const <String>[];
    if (active.isEmpty) return 'Ward $_wardId · no outbreak module';
    return 'Ward $_wardId · ${active.join(', ')}';
  }

  void _openLanguage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LanguageBridgeScreen(
          notice: 'Use this to hear the family, or to ask this question in their language. Come back and tap Yes or No yourself. The voice model does not answer the question.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Triage questions')),
        body: Center(child: Text(_loadError!)),
      );
    }
    if (!_booted || _ruleset == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_ageMonths == null) return _agePage();
    if (_stuck) return _heldPage();
    final question = _index < _questions.length ? _questions[_index] : null;
    if (question == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _questionPage(question);
  }

  Widget _agePage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Triage questions'),
        actions: [
          IconButton(
            key: const Key('open_language_bridge'),
            tooltip: 'They speak / I ask',
            onPressed: _openLanguage,
            icon: const Icon(Icons.translate),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            _session == null
                ? 'These are the Setu questions for a child from 2 months up to 5 years. You tap each answer. They speak and I ask can help with the language. They do not choose the colour.'
                : 'Questions for a child from birth to 59 months, IMCI and IMNCI. The sample location is ward $_wardId. You tap each answer. They speak and I ask do not choose the colour.',
            style: const TextStyle(fontSize: 16, height: 1.35),
          ),
          if (_session != null) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('ward_picker'),
              initialValue: _wardId,
              decoration: const InputDecoration(
                labelText: 'Ward',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final ward in _session!.loop.pack.wards)
                  DropdownMenuItem(
                    value: ward.wardId,
                    child: Text(ward.wardId),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _wardId = value);
              },
            ),
            const SizedBox(height: 8),
            Text(_moduleLine(), key: const Key('active_modules')),
          ],
          const SizedBox(height: 20),
          TextField(
            key: const Key('setu_age_months'),
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Age in months',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('start_questions_button'),
            onPressed: _start,
            child: const Text('Start questions'),
          ),
        ],
      ),
    );
  }

  Widget _questionPage(SetuQuestion question) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${_index + 1} of ${_questions.length}'),
        actions: [
          IconButton(
            key: const Key('open_language_bridge'),
            tooltip: 'They speak / I ask',
            onPressed: _openLanguage,
            icon: const Icon(Icons.translate),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_flow != null)
                Text(
                  'Ward ${_flow!.wardId}',
                  key: const Key('question_ward'),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AshaColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                question.prompt,
                key: const Key('question_prompt'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: AshaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  DropdownButton<String>(
                    key: const Key('question_language'),
                    value: _askLang,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                      DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      _setAskLanguage(value);
                    },
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    key: const Key('speak_question'),
                    onPressed: _speaking
                        ? null
                        : () => _speakQuestion(question),
                    icon: Icon(
                      _speaking ? Icons.hearing : Icons.volume_up_rounded,
                      size: 18,
                    ),
                    label: const Text('Speak'),
                  ),
                ],
              ),
              if (_spokenLine != null && _spokenFor == question.path) ...[
                const SizedBox(height: 8),
                Text(
                  _spokenLine!,
                  key: const Key('spoken_question'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: AshaColors.primaryDark,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              const Text(
                'Unknown leaves this blank.',
                style: TextStyle(color: AshaColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _AnswerArea(
                  question: question,
                  safeYes:
                      _flow?.questionById(question.path)?.invertYes ?? false,
                  onAnswer: (value) => _answer(question.path, value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heldPage() {
    final result = _held;
    final missing = result?.blockingQuestions ?? const <String>[];
    return Scaffold(
      appBar: AppBar(title: const Text('More answers needed')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'The rules will not give a colour until the missing answers are in. Nothing was saved as a referral.',
            style: TextStyle(fontSize: 16, height: 1.35),
          ),
          const SizedBox(height: 12),
          for (final path in missing) Text('• $path'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final again = SetuQuestionCatalogue.forPaths(missing);
              setState(() {
                _stuck = false;
                _held = null;
                _answeredAny = false;
                if (again.isNotEmpty) {
                  _questions = again;
                  _index = 0;
                }
              });
            },
            child: const Text('Ask the missing questions'),
          ),
        ],
      ),
    );
  }
}

class _OutOfScopePage extends StatelessWidget {
  const _OutOfScopePage({required this.result});

  final ClinicalTriageResult result;

  @override
  Widget build(BuildContext context) {
    final reason = result.firedRules.isEmpty
        ? 'Outside the Setu age range.'
        : result.firedRules.first.reasonText;
    return Scaffold(
      appBar: AppBar(title: const Text('Outside these questions')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          '$reason\n\nThe Setu questions cover a child from 2 months up to 5 years. No referral QR was made.',
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
      ),
    );
  }
}

class _AnswerArea extends StatefulWidget {
  const _AnswerArea({
    required this.question,
    required this.onAnswer,
    this.safeYes = false,
  });

  final SetuQuestion question;
  final void Function(SourcedValue? value) onAnswer;

  /// True when Yes means the child is able (drink / breastfeed). That button stays first.
  /// For a danger sign, No stays first so a tap does not mark the child severely ill.
  final bool safeYes;

  @override
  State<_AnswerArea> createState() => _AnswerAreaState();
}

class _AnswerAreaState extends State<_AnswerArea> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitNumeric() {
    final spec = widget.question.numeric!;
    final parsed = num.tryParse(_controller.text.trim());
    if (parsed == null) {
      setState(() => _error = 'Enter a number');
      return;
    }
    if (!spec.isPlausible(parsed)) {
      setState(() => _error = 'That number is outside ${spec.min}–${spec.max}');
      return;
    }
    final value = spec.decimals == 0 ? parsed.toInt() : parsed;
    widget.onAnswer(SourcedValue.measured(value));
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.question.kind) {
      SetuAnswerKind.yesNo => ListView(
        children: [
          if (widget.safeYes) ...[
            _AnswerButton(
              key: const Key('answer_yes'),
              label: 'Yes',
              icon: Icons.check_circle_outline_rounded,
              color: AshaColors.primary,
              onTap: () => widget.onAnswer(const SourcedValue.guided('YES')),
            ),
            const SizedBox(height: 8),
            _AnswerButton(
              key: const Key('answer_no'),
              label: 'No',
              icon: Icons.cancel_outlined,
              color: AshaColors.alertHighRisk,
              onTap: () => widget.onAnswer(const SourcedValue.guided('NO')),
            ),
          ] else ...[
            _AnswerButton(
              key: const Key('answer_no'),
              label: 'No',
              icon: Icons.cancel_outlined,
              color: AshaColors.primary,
              onTap: () => widget.onAnswer(const SourcedValue.guided('NO')),
            ),
            const SizedBox(height: 8),
            _AnswerButton(
              key: const Key('answer_yes'),
              label: 'Yes',
              icon: Icons.check_circle_outline_rounded,
              color: AshaColors.alertHighRisk,
              onTap: () => widget.onAnswer(const SourcedValue.guided('YES')),
            ),
          ],
          const SizedBox(height: 8),
          _AnswerButton(
            key: const Key('answer_unknown'),
            label: 'Unknown',
            icon: Icons.help_outline_rounded,
            color: AshaColors.warningPending,
            onTap: () => widget.onAnswer(null),
          ),
        ],
      ),
      SetuAnswerKind.choice => ListView(
        children: [
          for (final option in widget.question.options) ...[
            _AnswerButton(
              label: option.label,
              icon: option.icon,
              color: AshaColors.primary,
              onTap: () =>
                  widget.onAnswer(SourcedValue.confirmed(option.value)),
            ),
            const SizedBox(height: 12),
          ],
          _AnswerButton(
            label: 'Unknown',
            icon: Icons.help_outline_rounded,
            color: AshaColors.warningPending,
            onTap: () => widget.onAnswer(null),
          ),
        ],
      ),
      SetuAnswerKind.numeric => ListView(
        children: [
          TextField(
            key: const Key('setu_numeric'),
            controller: _controller,
            keyboardType: TextInputType.numberWithOptions(
              decimal: widget.question.numeric!.decimals > 0,
            ),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              suffixText: widget.question.numeric!.unit,
              errorText: _error,
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitNumeric,
            child: const Text('Save measurement'),
          ),
          if (widget.question.allowUnobtainable) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  widget.onAnswer(const SourcedValue.notAvailable()),
              child: const Text('Cannot check'),
            ),
          ],
        ],
      ),
    };
  }
}

class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: AshaShapes.buttonRadius,
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        icon: Icon(icon, size: 22),
        label: Text(label),
      ),
    );
  }
}
