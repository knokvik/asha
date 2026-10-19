import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tts_service.dart';

/// Interactive modal sheet offering step-by-step audio guidance for clinical procedures.
///
/// Features:
/// - Manual or timer-based step progression (Requirement 7.2).
/// - Spoken audio guidance using pre-recorded clips or TTS (Requirement 7.3).
/// - Family-facing pictorial and audio explanation toggle (Requirement 7.4).
/// - Accessible >= 48×48 dp controls.
class ProcedureGuidanceSheet extends ConsumerStatefulWidget {
  final ClinicalProcedure procedure;
  final String language;
  final bool enableTimer;

  const ProcedureGuidanceSheet({
    super.key,
    required this.procedure,
    this.language = 'en',
    this.enableTimer = true,
  });

  static Future<void> show(
    BuildContext context, {
    required ClinicalProcedure procedure,
    String language = 'en',
    bool enableTimer = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProcedureGuidanceSheet(
        procedure: procedure,
        language: language,
        enableTimer: enableTimer,
      ),
    );
  }

  @override
  ConsumerState<ProcedureGuidanceSheet> createState() =>
      _ProcedureGuidanceSheetState();
}

class _ProcedureGuidanceSheetState extends ConsumerState<ProcedureGuidanceSheet> {
  late final TtsService _tts;
  late final List<ProcedureStep> _steps;
  int _currentStepIndex = 0;
  bool _isFamilyFacing = false;
  Timer? _stepTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _tts = ref.read(ttsServiceProvider);
    _steps = TtsService.getProcedureSteps(widget.procedure, language: widget.language);
    _startCurrentStep();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _tts.stop();
    super.dispose();
  }

  void _startCurrentStep() {
    _stepTimer?.cancel();
    final step = _steps[_currentStepIndex];

    if (widget.enableTimer && step.timerDuration != null) {
      _secondsRemaining = step.timerDuration!.inSeconds;
      _stepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 1) {
          if (mounted) setState(() => _secondsRemaining--);
        } else {
          timer.cancel();
          if (mounted) {
            setState(() => _secondsRemaining = 0);
            _handleAutoAdvance();
          }
        }
      });
    } else {
      _secondsRemaining = 0;
    }

    _playStepAudio(step);
  }

  Future<void> _playStepAudio(ProcedureStep step) async {
    final text = _isFamilyFacing
        ? step.familyFacingExplanation
        : '${step.title}. ${step.instructionText}';

    await _tts.speak(
      text: text,
      language: widget.language,
      clipId: step.clipId,
    );
  }

  void _handleAutoAdvance() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() => _currentStepIndex++);
      _startCurrentStep();
    }
  }

  void _goToNextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() => _currentStepIndex++);
      _startCurrentStep();
    }
  }

  void _goToPreviousStep() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
      _startCurrentStep();
    }
  }

  String _procedureTitle() {
    switch (widget.procedure) {
      case ClinicalProcedure.breathCounting:
        return 'Breath Counting Procedure';
      case ClinicalProcedure.muac:
        return 'MUAC Arm Measurement';
      case ClinicalProcedure.orsPreparation:
        return 'ORS Solution Preparation';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentStep = _steps[_currentStepIndex];
    final isFirstStep = _currentStepIndex == 0;
    final isLastStep = _currentStepIndex == _steps.length - 1;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  _procedureTitle(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                key: const Key('close_procedure_button'),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Step Counter & Family Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStepIndex + 1} of ${_steps.length}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              // Family mode toggle
              TextButton.icon(
                key: const Key('guidance_family_toggle'),
                icon: Icon(
                  _isFamilyFacing ? Icons.family_restroom : Icons.medical_services,
                  size: 18,
                ),
                label: Text(
                  _isFamilyFacing ? 'Family View' : 'Clinician View',
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  setState(() => _isFamilyFacing = !_isFamilyFacing);
                  _playStepAudio(currentStep);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Step Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentStep.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isFamilyFacing
                      ? currentStep.familyFacingExplanation
                      : currentStep.instructionText,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                if (_secondsRemaining > 0) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Timer: $_secondsRemaining s',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Audio Re-play and Navigation Controls (min 48x48 dp)
          Row(
            children: [
              // Listen again button
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                child: OutlinedButton.icon(
                  key: const Key('repeat_audio_button'),
                  icon: const Icon(Icons.volume_up, size: 20),
                  label: const Text('Listen'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 48),
                  ),
                  onPressed: () => _playStepAudio(currentStep),
                ),
              ),
              const Spacer(),
              // Previous Step
              if (!isFirstStep) ...[
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                  child: TextButton(
                    key: const Key('prev_step_button'),
                    onPressed: _goToPreviousStep,
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Next or Complete Step
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 100),
                child: ElevatedButton(
                  key: const Key('next_step_button'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 48),
                  ),
                  onPressed: isLastStep
                      ? () => Navigator.of(context).pop()
                      : _goToNextStep,
                  child: Text(isLastStep ? 'Done' : 'Next Step'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
