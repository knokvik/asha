import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'hi_mr_repair.dart';
import 'indic_translator.dart';
import 'languages.dart';
import 'model_store.dart';
import 'settings_store.dart';
import 'speech_engine.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.settings,
    this.title = 'Bhasha',
    this.notice,
  });

  final SettingsStore settings;
  final String title;

  /// Shown under the mode switch. The triage screen uses this to say that
  /// speech does not choose the colour.
  final String? notice;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _Turn {
  _Turn({
    required this.languageCode,
    required this.heard,
    required this.translation,
    required this.fromEnglish,
  });

  final String languageCode;
  final String heard;
  final String translation;
  final bool fromEnglish;
  String? audioPath;
  int? hearMs;
  int? translateMs;
}

class _HomePageState extends State<HomePage> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _typed = TextEditingController();
  final List<_Turn> _turns = [];
  final ValueNotifier<double> _level = ValueNotifier(0);

  Timer? _ticker;
  Timer? _liveTimer;
  StreamSubscription<Amplitude>? _levels;
  StreamSubscription<Uint8List>? _pcmSub;
  final BytesBuilder _pcm = BytesBuilder(copy: false);
  HearingSession? _hearing;
  IndicTranslator? _indicToEnglish;
  StreamSubscription<PlayerState>? _playerState;
  DateTime? _started;
  DateTime _lastProgressPaint = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastAskPaint = DateTime.fromMillisecondsSinceEpoch(0);
  bool _recording = false;
  bool _streamLive = false;
  bool _decodeBusy = false;
  bool _decodeAgain = false;
  bool _finalRequested = false;
  bool _stopInFlight = false;
  bool _busy = false;
  bool _speaking = false;
  bool _showType = false;
  bool _preparing = true;
  bool _ready = false;
  bool _downloading = false;
  bool _askDownloading = false;
  String _status = '';
  String _liveHeard = '';
  String _liveEnglish = '';
  int? _liveHearMs;
  int? _liveTranslateMs;
  String? _downloadError;
  String? _askError;
  int _elapsedSeconds = 0;
  ModelStore? _models;
  DownloadProgress? _progress;
  DownloadProgress? _askProgress;
  Future<void>? _askJob;

  static const _maxSeconds = 25;

  SettingsStore get settings => widget.settings;

  @override
  void initState() {
    super.initState();
    _playerState = _player.onPlayerStateChanged.listen((state) {
      final speaking = state == PlayerState.playing;
      if (!mounted || speaking == _speaking) return;
      setState(() => _speaking = speaking);
    });
    unawaited(_loadModels());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _liveTimer?.cancel();
    unawaited(_pcmSub?.cancel());
    _closeHearStack();
    unawaited(_levels?.cancel());
    unawaited(_playerState?.cancel());
    _typed.dispose();
    _level.dispose();
    unawaited(_recorder.dispose());
    unawaited(_player.dispose());
    super.dispose();
  }

  Future<void> _loadModels() async {
    final support = await getApplicationSupportDirectory();
    final store = ModelStore(Directory('${support.path}/bhasha-models'));
    final ready = store.isReady;
    if (!mounted) return;
    setState(() {
      _models = store;
      _ready = ready;
      _preparing = false;
    });
    if (!ready) {
      await _downloadModels();
      return;
    }
    if (settings.askInEnglish) unawaited(_ensureAsk());
  }

  Future<void> _downloadModels() async {
    final store = _models;
    if (store == null || _downloading) return;
    setState(() {
      _downloading = true;
      _downloadError = null;
    });
    try {
      await store.ensure((progress) {
        final now = DateTime.now();
        final complete = progress.total > 0 && progress.received >= progress.total;
        if (!complete &&
            now.difference(_lastProgressPaint) < const Duration(milliseconds: 200)) {
          _progress = progress;
          return;
        }
        _lastProgressPaint = now;
        if (!mounted) return;
        setState(() => _progress = progress);
      });
      if (!mounted) return;
      setState(() {
        _ready = true;
        _downloadError = null;
      });
      if (settings.askInEnglish) unawaited(_ensureAsk());
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _downloadError =
            'The download needs a connection. After the models are on the phone, translation works with no network.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _downloadError = '$error');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<bool> _ensureAsk() async {
    final store = _models;
    if (store == null) return false;
    if (store.askReady) return true;
    final running = _askJob;
    if (running != null) {
      await running;
      return store.askReady;
    }
    final job = _downloadAsk();
    _askJob = job;
    try {
      await job;
    } finally {
      if (identical(_askJob, job)) _askJob = null;
    }
    return store.askReady;
  }

  Future<void> _downloadAsk() async {
    final store = _models;
    if (store == null || store.askReady || _askDownloading) return;
    setState(() {
      _askDownloading = true;
      _askError = null;
    });
    try {
      await store.ensureAsk((progress) {
        final now = DateTime.now();
        final complete = progress.total > 0 && progress.received >= progress.total;
        if (!complete && now.difference(_lastAskPaint) < const Duration(milliseconds: 200)) {
          _askProgress = progress;
          return;
        }
        _lastAskPaint = now;
        if (!mounted) return;
        setState(() => _askProgress = progress);
      });
      if (!mounted) return;
      setState(() => _askError = null);
    } on SocketException {
      if (!mounted) return;
      setState(() {
        _askError =
            'The download needs a connection. Hearing still works. Ask-back starts once this model is on the phone.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _askError = '$error');
    } finally {
      if (mounted) setState(() => _askDownloading = false);
    }
  }

  Future<void> _setMode(bool ask) async {
    if (settings.askInEnglish == ask || _busy || _recording) return;
    await settings.setAskInEnglish(ask);
    if (ask) {
      _closeHearStack();
      unawaited(_ensureAsk());
    }
  }

  void _closeHearStack() {
    _indicToEnglish?.close();
    _indicToEnglish = null;
    _hearing?.close();
    _hearing = null;
  }

  Future<void> _openHearStack() async {
    final store = _models;
    if (store == null || !store.isReady) return;
    if (_hearing != null && _indicToEnglish != null) return;
    if (mounted) setState(() => _status = 'Preparing Hindi and Marathi hearing');
    _hearing ??= HearingSession.open(
      modelPath: store.asrModelPath,
      tokensPath: store.asrTokensPath,
    );
    _indicToEnglish ??= await IndicTranslator.open(store.mtDirectory);
    if (mounted) setState(() => _status = '');
  }

  Future<void> _toggleRecording() async {
    if (_busy || !_ready || settings.askInEnglish) return;
    if (_recording) {
      await _finishRecording();
      return;
    }
    if (!settings.source.speech) {
      _showMessage(
        '${settings.source.name} can be typed. The listener covers Hindi, Marathi, Bengali, Tamil, Telugu, Gujarati, Punjabi, and Odia.',
      );
      setState(() => _showType = true);
      return;
    }
    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      _showMessage('Allow the microphone so the phone can hear you.');
      return;
    }
    _streamLive = false;
    try {
      await _openHearStack();
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      _pcm.clear();
      _liveHeard = '';
      _liveEnglish = '';
      _liveHearMs = null;
      _liveTranslateMs = null;
      await _pcmSub?.cancel();
      _pcmSub = stream.listen(_pcm.add);
      _streamLive = true;
    } catch (error) {
      _streamLive = false;
      final dir = await getTemporaryDirectory();
      final wav = File('${dir.path}/speech.wav');
      try {
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: wav.path,
        );
      } catch (startError) {
        _showMessage('Could not start the microphone. $startError');
        return;
      }
    }
    await _levels?.cancel();
    _levels = _recorder.onAmplitudeChanged(const Duration(milliseconds: 80)).listen((amp) {
      final db = amp.current.clamp(-50.0, -5.0);
      _level.value = ((db + 50) / 45).clamp(0.0, 1.0);
    });
    if (!mounted) return;
    setState(() {
      _recording = true;
      _elapsedSeconds = 0;
      _status = 'Listening';
      _started = DateTime.now();
    });
    _liveTimer?.cancel();
    if (_streamLive) {
      _liveTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
        unawaited(_decodeLive(finalPass: false));
      });
    }
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = _started;
      if (start == null || !mounted) return;
      final seconds = DateTime.now().difference(start).inSeconds;
      setState(() => _elapsedSeconds = seconds);
      if (seconds >= _maxSeconds) unawaited(_finishRecording());
    });
  }

  void _stopLevels() {
    unawaited(_levels?.cancel());
    _levels = null;
    _level.value = 0;
  }

  Future<void> _finishRecording() async {
    if (!_recording || _stopInFlight) return;
    _stopInFlight = true;
    _ticker?.cancel();
    _liveTimer?.cancel();
    _stopLevels();
    if (_streamLive) {
      await _pcmSub?.cancel();
      _pcmSub = null;
      try {
        await _recorder.stop();
      } catch (error) {
        if (mounted) _showMessage('Could not stop the microphone. $error');
      } finally {
        _stopInFlight = false;
      }
      if (!mounted) return;
      setState(() => _recording = false);
      await _decodeLive(finalPass: true);
      return;
    }
    String? path;
    try {
      path = await _recorder.stop();
    } catch (error) {
      if (mounted) {
        setState(() => _recording = false);
        _showMessage('Could not stop the microphone. $error');
      }
      return;
    } finally {
      _stopInFlight = false;
    }
    if (!mounted) return;
    setState(() => _recording = false);
    if (path == null || path.isEmpty) {
      _showMessage('No audio was captured.');
      return;
    }
    final file = File(path);
    if (!await file.exists() || await file.length() < 800) {
      _showMessage('That was too short. Speak for a full sentence.');
      return;
    }
    await _translate(audio: file);
  }

  Future<void> _decodeLive({required bool finalPass}) async {
    if (finalPass) _finalRequested = true;
    if (_decodeBusy) {
      _decodeAgain = true;
      return;
    }
    final hearing = _hearing;
    final translator = _indicToEnglish;
    if (hearing == null || translator == null) {
      if (finalPass && mounted) {
        _showMessage('The hearing model is not ready.');
      }
      return;
    }
    _decodeBusy = true;
    try {
      while (mounted) {
        final isFinal = _finalRequested;
        _decodeAgain = false;
        final bytes = _pcm.toBytes();
        if (bytes.length < 16000) {
          if (isFinal && mounted) {
            _showMessage('That was too short. Speak for a full sentence.');
            setState(() {
              _liveEnglish = '';
              _liveHeard = '';
            });
          }
          if (isFinal) _finalRequested = false;
          break;
        }
        final language = settings.source;
        final hearWatch = Stopwatch()..start();
        final raw = hearing.transcribe(pcm16ToFloat(Uint8List.fromList(bytes)), 16000);
        final hearMs = hearWatch.elapsedMilliseconds;
        final heard = prepareHeardForTranslation(raw, language.iso);
        if (heard.isEmpty) {
          if (isFinal && mounted) {
            _showMessage('I did not catch that. Speak a full sentence, closer to the phone.');
          }
          if (isFinal) _finalRequested = false;
          break;
        }
        if (!isFinal && heard == _liveHeard) {
          if (!_decodeAgain && !_finalRequested) break;
          continue;
        }
        final translateWatch = Stopwatch()..start();
        final english = translator.translate(heard, language);
        final translateMs = translateWatch.elapsedMilliseconds;
        if (!mounted) break;
        if (english.trim().isEmpty) {
          if (isFinal) {
            _showMessage('The translation came back empty. Try a shorter sentence.');
            _finalRequested = false;
          }
          break;
        }
        setState(() {
          _liveHeard = heard;
          _liveEnglish = english.trim();
          _liveHearMs = hearMs;
          _liveTranslateMs = translateMs;
        });
        if (!isFinal) {
          if (_decodeAgain || _finalRequested) continue;
          break;
        }
        _finalRequested = false;
        final turn = _Turn(
          languageCode: language.code,
          heard: heard,
          translation: english.trim(),
          fromEnglish: false,
        )
          ..hearMs = hearMs
          ..translateMs = translateMs;
        setState(() {
          _turns.insert(0, turn);
          _liveHeard = '';
          _liveEnglish = '';
          _status = '';
        });
        if (settings.autoSpeak) {
          await _speakEnglish(turn);
        }
        break;
      }
    } on SpeechException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Something went wrong. $error');
    } finally {
      _decodeBusy = false;
      if (_finalRequested) unawaited(_decodeLive(finalPass: true));
    }
  }

  Future<void> _speakEnglish(_Turn turn) async {
    final store = _models;
    if (store == null || !store.isReady) return;
    try {
      if (mounted) setState(() => _status = 'Speaking the English');
      final dir = await getTemporaryDirectory();
      final spoken = File('${dir.path}/reply-${DateTime.now().millisecondsSinceEpoch}.wav');
      SpeechEngine.speakToFile(
        text: _speechText(turn.translation),
        modelPath: store.ttsModelPath,
        tokensPath: store.ttsTokensPath,
        dataDir: store.espeakDirectory,
        destPath: spoken.path,
      );
      turn.audioPath = spoken.path;
      await _player.stop();
      await _player.play(DeviceFileSource(spoken.path));
      if (mounted) setState(() {});
    } on SpeechException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Something went wrong. $error');
    }
  }

  Future<void> _submitTyped() async {
    if (settings.askInEnglish) {
      await _onAskPressed();
      return;
    }
    final text = _typed.text.trim();
    if (text.isEmpty || _busy || !_ready) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await _translate(typed: text);
  }

  Future<void> _onAskPressed() async {
    if (_busy || !_ready) return;
    final text = _typed.text.trim();
    if (text.isEmpty) {
      _showMessage('Write the question in English.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    final language = settings.source;
    final ready = await _ensureAsk();
    if (!mounted) return;
    if (!ready) {
      if (_askError == null) {
        _showMessage('The ask model is not on the phone yet.');
      }
      return;
    }
    await _translate(typed: text, fromEnglish: true, language: language);
  }

  Future<void> _translate({
    File? audio,
    String? typed,
    bool fromEnglish = false,
    IndicLanguage? language,
  }) async {
    final store = _models;
    if (_busy || store == null || !store.isReady) return;
    final source = language ?? settings.source;
    final typedText = typed?.trim() ?? '';
    if (fromEnglish && typedText.isEmpty) return;
    setState(() {
      _busy = true;
      _status = audio != null ? 'Hearing the recording' : 'Translating on this phone';
    });
    await Future<void>.delayed(Duration.zero);
    try {
      final String heard;
      int? hearMs;
      if (audio != null) {
        final watch = Stopwatch()..start();
        final raw = SpeechEngine.transcribe(
          wavPath: audio.path,
          modelPath: store.asrModelPath,
          tokensPath: store.asrTokensPath,
        );
        hearMs = watch.elapsedMilliseconds;
        heard = prepareHeardForTranslation(raw, source.iso);
        if (heard.isEmpty) {
          _showMessage('I did not catch that. Speak a full sentence, closer to the phone.');
          return;
        }
        if (mounted) setState(() => _status = 'Translating on this phone');
        await Future<void>.delayed(Duration.zero);
      } else {
        heard = typedText;
      }

      final translateWatch = Stopwatch()..start();
      final translation = fromEnglish
          ? await translateEnglishOnPhone(
              modelDirectory: store.enMtDirectory.path,
              text: heard,
              languageCode: source.code,
            )
          : _indicToEnglish != null
              ? _indicToEnglish!.translate(heard, source)
              : await translateOnPhone(
                  modelDirectory: store.mtDirectory.path,
                  text: heard,
                  languageCode: source.code,
                );
      final translateMs = translateWatch.elapsedMilliseconds;
      if (translation.trim().isEmpty) {
        _showMessage('The translation came back empty. Try a shorter sentence.');
        return;
      }

      final turn = _Turn(
        languageCode: source.code,
        heard: heard,
        translation: translation,
        fromEnglish: fromEnglish,
      )
        ..hearMs = hearMs
        ..translateMs = translateMs;
      final speakHindi = fromEnglish && settings.autoSpeak && source.iso == 'hi';
      final speakEnglish = !fromEnglish && settings.autoSpeak;
      if (speakHindi || speakEnglish) {
        try {
          if (speakHindi && !store.hindiVoiceReady) {
            await _downloadHindiVoice(store);
          }
          if (speakHindi && !store.hindiVoiceReady) {
            _showMessage('The Hindi voice is not on the phone yet. The words are on the screen.');
          } else {
            if (mounted) {
              setState(() {
                _status = speakHindi ? 'Speaking the Hindi' : 'Speaking the English';
              });
            }
            await Future<void>.delayed(Duration.zero);
            final dir = await getTemporaryDirectory();
            final spoken = File(
              '${dir.path}/reply-${DateTime.now().millisecondsSinceEpoch}.wav',
            );
            SpeechEngine.speakToFile(
              text: _speechText(translation),
              modelPath: speakHindi ? store.hindiTtsModelPath : store.ttsModelPath,
              tokensPath: speakHindi ? store.hindiTtsTokensPath : store.ttsTokensPath,
              dataDir: store.espeakDirectory,
              destPath: spoken.path,
            );
            turn.audioPath = spoken.path;
            await _player.stop();
            await _player.play(DeviceFileSource(spoken.path));
          }
        } on SpeechException catch (error) {
          _showMessage(error.message);
        } catch (error) {
          _showMessage(
            speakHindi
                ? 'The Hindi voice did not play. The words are on the screen. $error'
                : 'Something went wrong. $error',
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _turns.insert(0, turn);
        _status = '';
        _typed.clear();
      });
    } on SpeechException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Something went wrong. $error');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          if (!_recording) _status = '';
        });
      }
    }
  }

  Future<void> _downloadHindiVoice(ModelStore store) async {
    var last = DateTime.fromMillisecondsSinceEpoch(0);
    await store.ensureHindiVoice((progress) {
      final now = DateTime.now();
      final complete = progress.total > 0 && progress.received >= progress.total;
      if (!complete && now.difference(last) < const Duration(milliseconds: 200)) return;
      last = now;
      if (!mounted) return;
      final total = progress.total > 0 ? ' of ${_formatSize(progress.total)}' : '';
      setState(() => _status = 'Hindi voice · ${_formatSize(progress.received)}$total');
    });
  }

  String _speechText(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 400) return trimmed;
    final cut = trimmed.substring(0, 400);
    final lastStop = cut.lastIndexOf(RegExp(r'[.!?।]'));
    if (lastStop > 80) return cut.substring(0, lastStop + 1);
    return cut;
  }

  Future<void> _replay(String path) async {
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickLanguage() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFCF7),
      builder: (context) {
        return SafeArea(
          child: ListView(
            children: [
              for (final language in indicLanguages)
                ListTile(
                  title: Text(language.nativeName),
                  subtitle: Text(
                    language.speech ? language.name : '${language.name} · type only',
                  ),
                  onTap: () => Navigator.pop(context, language.code),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    await settings.setSource(selected);
  }

  Future<void> _openSettings() {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFFCF7),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voice',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'They speak: the phone reads the English. I ask, and the language is Hindi: the phone reads the Hindi. Other languages stay on the screen.',
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Speak when a voice is on the phone'),
                    value: settings.autoSpeak,
                    onChanged: (value) async {
                      await settings.setAutoSpeak(value);
                      setSheetState(() {});
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _openInfo() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('What this phone is running'),
          content: const Text(
            'This phone build is not Sarvam Edge. Those weights are not public.\n\n'
            'Hearing uses Dolphin. It covers Hindi, Marathi, Bengali, Tamil, Telugu, Gujarati, Punjabi, and Odia.\n\n'
            'Translation uses AI4Bharat IndicTrans2, the 200 million parameter model. '
            'Checked sentences include Hindi “चुनाव कौन जीतेगा?”, which comes out as “Who will win the election?”.\n\n'
            'Field words such as dhokla, meter, ORS, vaccines, and ASHA are kept from a glossary on the phone, in both directions.\n\n'
            'I ask downloads a second model, about 300 MB, the first time you use it. '
            'Hindi can be read aloud. The Hindi voice is about 20 MB. Other languages are shown large so you can hold the phone up.\n\n'
            'The first launch downloads about 400 MB for hearing and English. After a model is on the phone it needs no key and no network.\n\n'
            'Kannada and Malayalam can be typed. The listener does not cover them. You can still ask in them.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        final from = settings.source;
        final ask = settings.askInEnglish;
        final locked = _busy || _recording;
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                Text(
                  ask
                      ? 'You write English · they read ${from.name}'
                      : 'Hears an Indian language · speaks English',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5C564C)),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'About this build',
                onPressed: _openInfo,
                icon: const Icon(Icons.info_outline),
              ),
              IconButton(
                tooltip: 'Voice',
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: !_ready
                ? _DownloadGate(
                    preparing: _preparing,
                    downloading: _downloading,
                    progress: _progress,
                    error: _downloadError,
                    onRetry: _downloadModels,
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _ModeSwitch(
                          ask: ask,
                          onChanged: locked ? null : _setMode,
                        ),
                      ),
                      if (widget.notice != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            widget.notice!,
                            style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF5C564C)),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: _LanguageChip(
                                caption: ask ? 'You write' : 'They speak',
                                title: ask ? 'English' : from.nativeName,
                                subtitle: ask
                                    ? 'Type the question'
                                    : (from.speech ? from.name : '${from.name} · type'),
                                onTap: ask || locked ? null : _pickLanguage,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.arrow_forward, color: Color(0xFF5C564C)),
                            ),
                            Expanded(
                              child: _LanguageChip(
                                caption: ask ? 'They read' : 'You read',
                                title: ask ? from.nativeName : 'English',
                                subtitle: ask
                                    ? (from.iso == 'hi' ? 'Read aloud' : 'On the screen')
                                    : 'Read aloud',
                                onTap: ask && !locked ? _pickLanguage : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!ask && (_recording || _liveEnglish.isNotEmpty))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: _LiveEnglish(
                            english: _liveEnglish,
                            heard: _liveHeard,
                            hearMs: _liveHearMs,
                            translateMs: _liveTranslateMs,
                            tuned: from.iso == 'hi' || from.iso == 'mr',
                          ),
                        ),
                      Expanded(
                        child: _turns.isEmpty
                            ? LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                      child: _EmptyHint(ask: ask, language: from),
                                    ),
                                  );
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                itemCount: _turns.length,
                                itemBuilder: (context, index) {
                                  final turn = _turns[index];
                                  return _TurnCard(
                                    turn: turn,
                                    onReplay: turn.audioPath == null
                                        ? null
                                        : () => _replay(turn.audioPath!),
                                  );
                                },
                              ),
                      ),
                      if (ask && _models != null && !_models!.askReady)
                        _AskPanel(
                          downloading: _askDownloading,
                          progress: _askProgress,
                          error: _askError,
                          onRetry: _ensureAsk,
                        ),
                      if (ask || _showType)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _typed,
                                  minLines: 1,
                                  maxLines: 3,
                                  textInputAction: TextInputAction.send,
                                  onSubmitted: (_) => _submitTyped(),
                                  style: const TextStyle(fontSize: 18),
                                  decoration: InputDecoration(
                                    hintText: ask
                                        ? 'Write the question in English'
                                        : 'Type a sentence',
                                    filled: true,
                                    fillColor: const Color(0xFFFFFCF7),
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                onPressed: _busy ? null : _submitTyped,
                                icon: const Icon(Icons.send),
                              ),
                            ],
                          ),
                        ),
                      if (!ask)
                        TextButton(
                          onPressed: () => setState(() => _showType = !_showType),
                          child: Text(
                            _showType ? 'Hide typing' : 'Type instead of speaking',
                          ),
                        ),
                      if (_status.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            _recording ? '$_status  ${_elapsedSeconds}s' : _status,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        child: _LiveButton(
                          recording: _recording,
                          busy: _busy || _askWaiting(ask),
                          speaking: _speaking,
                          level: _level,
                          label: _buttonLabel(from, ask),
                          icon: _recording
                              ? Icons.stop_rounded
                              : (ask ? Icons.campaign_rounded : Icons.mic_rounded),
                          onPressed: _buttonPressed(ask),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  bool _askWaiting(bool ask) {
    return ask && _askDownloading && _models?.askReady != true;
  }

  String _buttonLabel(IndicLanguage from, bool ask) {
    if (_askWaiting(ask)) return 'Downloading';
    if (ask) {
      if (_busy) return 'Working';
      return 'Ask in ${from.nativeName}';
    }
    if (_recording) return 'Tap to stop';
    if (_busy) return 'Working';
    return 'Tap to speak';
  }

  VoidCallback? _buttonPressed(bool ask) {
    if (_recording) return _toggleRecording;
    if (_busy || _askWaiting(ask)) return null;
    return ask ? _onAskPressed : _toggleRecording;
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.ask, required this.onChanged});

  final bool ask;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _modeButton('They speak', selected: !ask, onTap: onChanged == null ? null : () => onChanged!(false))),
        const SizedBox(width: 8),
        Expanded(child: _modeButton('I ask', selected: ask, onTap: onChanged == null ? null : () => onChanged!(true))),
      ],
    );
  }

  Widget _modeButton(String label, {required bool selected, required VoidCallback? onTap}) {
    return Material(
      color: selected ? const Color(0xFF0F6E56) : const Color(0xFFFFFCF7),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF0F6E56) : const Color(0xFFE4DDD2),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF1C1915),
            ),
          ),
        ),
      ),
    );
  }
}

class _AskPanel extends StatelessWidget {
  const _AskPanel({
    required this.downloading,
    required this.progress,
    required this.error,
    required this.onRetry,
  });

  final bool downloading;
  final DownloadProgress? progress;
  final String? error;
  final Future<bool> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final fraction = progress?.fraction ?? 0;
    final received = progress == null ? '' : _formatSize(progress!.received);
    final total = progress == null || progress!.total <= 0 ? '' : _formatSize(progress!.total);
    final fileLine = progress == null
        ? 'About 300 MB, the first time you ask.'
        : total.isEmpty
        ? '${progress!.label} · $received'
        : '${progress!.label} · $received of $total';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4DDD2)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ask-back model',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                error ?? fileLine,
                style: const TextStyle(fontSize: 14, height: 1.3),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: downloading && fraction > 0 ? fraction : (downloading ? null : 0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF0F6E56),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(onPressed: () => onRetry(), child: const Text('Try again')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadGate extends StatelessWidget {
  const _DownloadGate({
    required this.preparing,
    required this.downloading,
    required this.progress,
    required this.error,
    required this.onRetry,
  });

  final bool preparing;
  final bool downloading;
  final DownloadProgress? progress;
  final String? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final fraction = progress?.fraction ?? 0;
    final received = progress == null ? '' : _formatSize(progress!.received);
    final total = progress == null || progress!.total <= 0 ? '' : _formatSize(progress!.total);
    final fileLine = progress == null
        ? ''
        : total.isEmpty
        ? '${progress!.label} · $received'
        : '${progress!.label} · $received of $total';
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Download once, then it stays on the phone',
            style: TextStyle(fontSize: 26, height: 1.25, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text(
            'About 400 MB. This covers hearing, translation into English, and the English voice. After this, the phone needs no key and no network.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 28),
          if (preparing)
            const Text('Looking for models already on this phone.')
          else ...[
            LinearProgressIndicator(
              value: downloading && fraction > 0 ? fraction : (downloading ? null : 0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFF0F6E56),
            ),
            const SizedBox(height: 12),
            Text(
              error ?? (downloading ? fileLine : 'Ready to download.'),
              style: const TextStyle(fontSize: 16, height: 1.35),
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: downloading ? null : () => onRetry(),
                child: const Text('Try again'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.caption,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String caption;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFCF7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE4DDD2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caption,
                style: const TextStyle(fontSize: 12, color: Color(0xFF5C564C)),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(subtitle, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.ask, required this.language});

  final bool ask;
  final IndicLanguage language;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            ask
                ? 'Write the question in English, then tap Ask in ${language.nativeName}.'
                : 'Tap the button and speak one sentence. Tap again to stop.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, height: 1.35),
          ),
          const SizedBox(height: 12),
          Text(
            ask
                ? 'The phone shows ${language.name}. Hindi is read aloud. For the other languages, hold the screen up.'
                : 'The phone hears the Indian language, keeps field words such as dhokla and meter, and reads the English.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF5C564C), height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _LiveEnglish extends StatelessWidget {
  const _LiveEnglish({
    required this.english,
    required this.heard,
    required this.hearMs,
    required this.translateMs,
    required this.tuned,
  });

  final String english;
  final String heard;
  final int? hearMs;
  final int? translateMs;
  final bool tuned;

  @override
  Widget build(BuildContext context) {
    final timing = [
      if (hearMs != null) 'Heard $hearMs ms',
      if (translateMs != null) 'translated $translateMs ms',
    ].join(' · ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F6E56)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tuned ? 'English · Hindi or Marathi' : 'English, as they speak',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F6E56)),
          ),
          const SizedBox(height: 6),
          Text(
            english.isEmpty ? 'Listening…' : english,
            style: const TextStyle(fontSize: 22, height: 1.3, fontWeight: FontWeight.w700),
          ),
          if (heard.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(heard, style: const TextStyle(fontSize: 14, height: 1.3, color: Color(0xFF5C564C))),
          ],
          if (timing.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(timing, style: const TextStyle(fontSize: 12, color: Color(0xFF5C564C))),
          ],
        ],
      ),
    );
  }
}

class _TurnCard extends StatelessWidget {
  const _TurnCard({required this.turn, required this.onReplay});

  final _Turn turn;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    final name = languageLabel(turn.languageCode);
    final direction = turn.fromEnglish ? 'English → $name' : '$name → English';
    final showHoldUp = turn.fromEnglish && turn.languageCode != 'hi-IN';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: const Color(0xFFFFFCF7),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE4DDD2)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              direction,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F6E56),
              ),
            ),
            const SizedBox(height: 6),
            Text(turn.heard, style: const TextStyle(fontSize: 15, height: 1.35)),
            const SizedBox(height: 8),
            SelectableText(
              turn.translation,
              style: TextStyle(
                fontSize: turn.fromEnglish ? 26 : 20,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (turn.hearMs != null || turn.translateMs != null) ...[
              const SizedBox(height: 6),
              Text(
                [
                  if (turn.hearMs != null) 'Heard ${turn.hearMs} ms',
                  if (turn.translateMs != null) 'translated ${turn.translateMs} ms',
                ].join(' · '),
                style: const TextStyle(fontSize: 12, color: Color(0xFF5C564C)),
              ),
            ],
            if (showHoldUp) ...[
              const SizedBox(height: 6),
              Text(
                'Hold the phone up. This phone reads Hindi aloud, so $name stays on the screen.',
                style: const TextStyle(fontSize: 13, height: 1.3, color: Color(0xFF5C564C)),
              ),
            ],
            if (onReplay != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onReplay,
                  icon: const Icon(Icons.volume_up_outlined, size: 18),
                  label: const Text('Play again'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LiveButton extends StatefulWidget {
  const _LiveButton({
    required this.recording,
    required this.busy,
    required this.speaking,
    required this.level,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final bool recording;
  final bool busy;
  final bool speaking;
  final ValueNotifier<double> level;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<_LiveButton> createState() => _LiveButtonState();
}

class _LiveButtonState extends State<_LiveButton> with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();
  double _level = 0;

  @override
  void initState() {
    super.initState();
    _level = widget.level.value;
    widget.level.addListener(_onLevel);
  }

  @override
  void didUpdateWidget(_LiveButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      oldWidget.level.removeListener(_onLevel);
      _level = widget.level.value;
      widget.level.addListener(_onLevel);
    }
  }

  void _onLevel() {
    _level = widget.level.value;
  }

  @override
  void dispose() {
    widget.level.removeListener(_onLevel);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final base = widget.recording ? const Color(0xFF9F2D2D) : const Color(0xFF0F6E56);
    final color = enabled ? base : base.withValues(alpha: 0.45);
    return SizedBox(
      width: double.infinity,
      height: 84,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 64,
                  child: AnimatedBuilder(
                    animation: _motion,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _ButtonMotion(
                          t: _motion.value,
                          recording: widget.recording,
                          busy: widget.busy,
                          speaking: widget.speaking,
                          level: _level,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ),
                Icon(widget.icon, color: Colors.white, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ButtonMotion extends CustomPainter {
  const _ButtonMotion({
    required this.t,
    required this.recording,
    required this.busy,
    required this.speaking,
    required this.level,
  });

  final double t;
  final bool recording;
  final bool busy;
  final bool speaking;
  final double level;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    if (recording) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.35 + 0.45 * level);
      canvas.drawCircle(center, 8 + 18 * (0.35 + 0.65 * level), ring);
      _bars(canvas, center, count: 5, spread: 8, driven: true);
      return;
    }
    if (speaking) {
      _bars(canvas, center, count: 7, spread: 7, driven: false);
      return;
    }
    if (busy) {
      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 16),
        t * math.pi * 2,
        1.35,
        false,
        arc,
      );
      canvas.drawCircle(center, 4, Paint()..color = Colors.white.withValues(alpha: 0.9));
      return;
    }
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1;
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: (1 - p) * 0.9);
      canvas.drawCircle(center, 7 + p * 22, ring);
    }
    canvas.drawCircle(center, 5, Paint()..color = Colors.white);
  }

  void _bars(
    Canvas canvas,
    Offset center, {
    required int count,
    required double spread,
    required bool driven,
  }) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    final origin = center.dx - ((count - 1) * spread) / 2;
    for (var i = 0; i < count; i++) {
      final wave = 0.5 + 0.5 * math.sin(t * math.pi * 2 + i * 0.65);
      final energy = driven ? (0.25 + 0.75 * level) : 0.85;
      final height = 8 + (driven ? 28 : 24) * wave * energy;
      final x = origin + i * spread;
      canvas.drawLine(
        Offset(x, center.dy - height / 2),
        Offset(x, center.dy + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ButtonMotion oldDelegate) => true;
}

String _formatSize(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
}
