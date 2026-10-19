import 'package:flutter/material.dart';

import '../../core/voice/tap_to_hear_button.dart';

/// One-question-per-screen scaffold framework for clinical assessments.
///
/// Adheres strictly to low-literacy and accessibility requirements:
/// - One question per screen by default (Requirement 3.4).
/// - 48×48 dp minimum touch targets for all interactive controls (Requirement 3.4, 49.4).
/// - WCAG AA high-contrast color scheme (Requirement 3.4, 49.1).
/// - Clinical concept icon / illustration (Requirement 3.2).
/// - Integrated tap-to-hear audio prompt on every screen (Requirement 3.3).
/// - Flat navigation hierarchy capped at two levels (Requirement 3.4).
class ClinicalQuestionScaffold extends StatelessWidget {
  final int currentQuestionIndex;
  final int totalQuestions;
  final String questionTitle;
  final String? questionSubtitle;
  final String? audioPromptText;
  final String? familyFacingText;
  final IconData? clinicalIcon;
  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onSkip;
  final bool isNextEnabled;
  final bool isLastQuestion;
  final bool isSkippable;
  final String language;

  const ClinicalQuestionScaffold({
    super.key,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.questionTitle,
    this.questionSubtitle,
    this.audioPromptText,
    this.familyFacingText,
    this.clinicalIcon,
    required this.child,
    this.onNext,
    this.onPrevious,
    this.onSkip,
    this.isNextEnabled = true,
    this.isLastQuestion = false,
    this.isSkippable = false,
    this.language = 'en',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalQuestions > 0
        ? (currentQuestionIndex / totalQuestions).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Clean, high-contrast background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: Text(
          'Question $currentQuestionIndex of $totalQuestions',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            minHeight: 6,
          ),
        ),
        actions: [
          // Screen-level audio guidance button (Requirement 3.3)
          if (audioPromptText != null || questionSubtitle != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TapToHearButton(
                key: const Key('scaffold_audio_prompt_button'),
                text: audioPromptText ?? '$questionTitle. ${questionSubtitle ?? ""}',
                familyExplanation: familyFacingText,
                language: language,
                tooltip: 'Listen to instructions',
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Concept Icon & Title Row (Requirement 3.2)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (clinicalIcon != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        clinicalIcon,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          questionTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827), // WCAG AA compliant >= 7:1
                            height: 1.3,
                          ),
                        ),
                        if (questionSubtitle != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            questionSubtitle!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4B5563), // WCAG AA compliant >= 4.5:1
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Main question input content
              Expanded(
                child: SingleChildScrollView(
                  child: child,
                ),
              ),
              const SizedBox(height: 16),
              // Bottom Navigation Bar (All touch targets >= 48×48 dp)
              Row(
                children: [
                  // Previous Button
                  if (currentQuestionIndex > 1) ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48, minWidth: 80),
                      child: OutlinedButton(
                        key: const Key('scaffold_prev_button'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(80, 48),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: onPrevious,
                        child: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Skip Button (for skippable fields, Requirement 4.1)
                  if (isSkippable) ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48, minWidth: 70),
                      child: TextButton(
                        key: const Key('scaffold_skip_button'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(70, 48),
                        ),
                        onPressed: onSkip,
                        child: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  // Next / Submit Button
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48, minWidth: 120),
                    child: ElevatedButton(
                      key: const Key('scaffold_next_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        minimumSize: const Size(120, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        elevation: 1,
                      ),
                      onPressed: isNextEnabled ? onNext : null,
                      child: Text(
                        isLastQuestion ? 'Submit' : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}
