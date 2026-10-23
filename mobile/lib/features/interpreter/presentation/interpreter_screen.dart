import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/voice/tts_service.dart';
import '../../../shared/widgets/asha_svg_illustrations.dart';

/// Screen 8: Interpreter (They Speak / I Ask) matching the exact Asha Platform mobile design.
class InterpreterScreen extends StatefulWidget {
  const InterpreterScreen({super.key});

  @override
  State<InterpreterScreen> createState() => _InterpreterScreenState();
}

class _InterpreterScreenState extends State<InterpreterScreen>
    with SingleTickerProviderStateMixin {
  String _sourceLanguage = 'Hindi';
  String _targetLanguage = 'Marathi';
  bool _theySpeak = true;
  bool _isListening = false;
  final TtsService _ttsService = TtsService();

  final String _spokenText = 'क्या आपको बुखार हैं?';
  final String _translatedText = 'Do you have fever?';

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });

    if (!_isListening) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio recognized and translated offline.'),
        ),
      );
    }
  }

  void _speakTranslated() {
    _ttsService.speak(text: _spokenText, language: 'hi');
  }

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLanguage;
      _sourceLanguage = _targetLanguage;
      _targetLanguage = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AshaColors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: GestureDetector(
          onTap: _swapLanguages,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AshaColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _sourceLanguage,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AshaColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: AshaColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _targetLanguage,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AshaColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AshaColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AshaColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AshaColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _modeButton(
                        label: 'They speak',
                        selected: _theySpeak,
                        onTap: () => setState(() => _theySpeak = true),
                      ),
                    ),
                    Expanded(
                      child: _modeButton(
                        label: 'I ask',
                        selected: !_theySpeak,
                        onTap: () => setState(() => _theySpeak = false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Spacer(),

              // Microphone & Waveform Area
              GestureDetector(
                onTap: _toggleListening,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer pulse waves
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Container(
                          width:
                              170 +
                              (_isListening ? _animController.value * 24 : 0),
                          height:
                              170 +
                              (_isListening ? _animController.value * 24 : 0),
                          decoration: BoxDecoration(
                            color: AshaColors.primary.withValues(
                              alpha: _isListening ? 0.15 : 0.06,
                            ),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),

                    // SVG Vector mic with waveforms
                    SvgPicture.string(
                      AshaSvgIllustrations.interpreterMicSvg,
                      width: 150,
                      height: 150,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Instructions: Tap and speak | I will translate
              Text(
                _isListening
                    ? 'Listening...'
                    : (_theySpeak ? 'They speak' : 'Tap and ask'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AshaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'I will translate',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AshaColors.textSecondary,
                ),
              ),

              const Spacer(),

              // Translation Result Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AshaColors.cardSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AshaColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Devnagari / Local Speech Output
                    Text(
                      _spokenText,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AshaColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Translated Subtext & Speaker button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            _translatedText,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AshaColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.volume_up_rounded,
                            color: AshaColors.primary,
                            size: 26,
                          ),
                          tooltip: 'Speak audio',
                          onPressed: _speakTranslated,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AshaColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AshaColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
