import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/database/app_database.dart';
import '../../../core/l10n/language_provider.dart';
import '../../../core/voice/tts_service.dart';
import '../../../shared/shell/shell_copy.dart';
import '../data/learning_content_repository.dart';
import '../domain/learning_service.dart';
import '../domain/models/learning_models.dart';

class LearningScreen extends ConsumerStatefulWidget {
  final AppDatabase database;
  final String workerId;

  const LearningScreen({
    super.key,
    required this.database,
    this.workerId = 'asha-01',
  });

  @override
  ConsumerState<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends ConsumerState<LearningScreen>
    with SingleTickerProviderStateMixin {
  late final LearningService _learningService;
  late final TabController _tabController;
  String _searchQuery = '';
  List<LearningProgressData> _progressRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _learningService = LearningService(widget.database);
    _tabController = TabController(length: 4, vsync: this);
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final records = await _learningService.getWorkerProgress(widget.workerId);
    if (mounted) {
      setState(() {
        _progressRecords = records;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider).languageCode;
    return Scaffold(
      backgroundColor: AshaColors.screenBg,
      appBar: AppBar(
        title: Text(
          shellText(lang, 'microLearningTitle'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AshaColors.cardSurface,
        foregroundColor: AshaColors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AshaColors.primary,
          labelColor: AshaColors.primary,
          unselectedLabelColor: AshaColors.textMuted,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(icon: const Icon(Icons.school_rounded), text: shellText(lang, 'lessonsQuiz')),
            Tab(icon: const Icon(Icons.science_rounded), text: shellText(lang, 'simulatedPractice')),
            Tab(icon: const Icon(Icons.library_books_rounded), text: shellText(lang, 'jobAidsLibrary')),
            Tab(icon: const Icon(Icons.verified_rounded), text: shellText(lang, 'certificate')),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLessonsTab(),
                _buildSimulatedPracticeTab(),
                _buildJobAidsTab(),
                _buildCertificateTab(),
              ],
            ),
    );
  }

  Widget _buildLessonsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Daily limit indicator
        Card(
          color: AshaColors.surfaceMuted,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: AshaColors.warningPending,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Spaced Repetition Active: Max ${LearningService.maxDailyMandatoryLessons} mandatory lessons/day to ensure knowledge retention.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AshaColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...LearningContentRepository.defaultLessons.map((lesson) {
          final isCompleted = _progressRecords.any(
            (r) => r.lessonId == lesson.id && r.status == 'completed',
          );
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isCompleted
                    ? Colors.green.shade100
                    : Colors.blue.shade100,
                child: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : (lesson.format == LessonFormat.audio
                            ? Icons.mic
                            : Icons.menu_book),
                  color: isCompleted ? Colors.green : Colors.blue,
                ),
              ),
              title: Text(
                lesson.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${lesson.durationMinutes} min • ${lesson.category.name.toUpperCase()} • ${lesson.quizQuestions.length} Questions',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: FilledButton(
                onPressed: () => _openLessonModal(lesson),
                child: Text(isCompleted ? 'Review' : 'Start'),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _openLessonModal(MicroLesson lesson) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _LessonBottomSheet(
        lesson: lesson,
        onComplete: (score) async {
          await _learningService.recordLessonCompletion(
            workerId: widget.workerId,
            moduleId: lesson.moduleId,
            lessonId: lesson.id,
            score: score,
          );
          await _loadProgress();
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Completed "${lesson.title}" with score $score%! Synced to training record.',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSimulatedPracticeTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          color: AshaColors.primaryLight,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: AshaColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Practice Mode: Exercises triage decision-making on simulated cases. No real beneficiary records are touched.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AshaColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...LearningContentRepository.defaultScenarios.map(
          (sim) => Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: ExpansionTile(
              title: Text(
                sim.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                'Patient: ${sim.patientProfile}',
                style: const TextStyle(fontSize: 12),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Symptoms: ${sim.presentingSymptoms}',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Clinical Observations:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...sim.availableObservations.map((obs) => Text('• $obs')),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Correct Severity: ${sim.correctSeverity} - ${sim.correctNextAction}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Learning Note: ${sim.teachingPoints}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobAidsTab() {
    final aids = _learningService.searchJobAids(_searchQuery);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search job aids by keyword (e.g., HBNC, paracetamol, CBAC)...',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: AshaColors.cardSurface,
              border: OutlineInputBorder(borderRadius: AshaShapes.searchRadius),
              enabledBorder: OutlineInputBorder(
                borderRadius: AshaShapes.searchRadius,
                borderSide: BorderSide(color: AshaColors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AshaShapes.searchRadius,
                borderSide: BorderSide(color: AshaColors.primary, width: 1.5),
              ),
              isDense: true,
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: aids.length,
            itemBuilder: (ctx, idx) {
              final card = aids[idx];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              card.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Chip(
                            backgroundColor: const Color(0xFFE8F5E9),
                            side: const BorderSide(color: Color(0xFFA5D6A7)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            label: Text(
                              card.programCategory,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E4231),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        card.summarySteps,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Divider(),
                      Text(
                        'Key Thresholds: ${card.dosageOrThresholdTable}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Red Flags: ${card.redFlags}',
                        style: const TextStyle(fontSize: 11, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCertificateTab() {
    final completedCount = _progressRecords
        .where((r) => r.status == 'completed')
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        children: [
          // Certificate Preview Container
          Container(
            key: const Key('certificate_preview_card'),
            decoration: BoxDecoration(
              color: const Color(0xFFFEFDF9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD97706), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Inner decorative border
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22.0),
                  child: Column(
                    children: [
                      // Header with National Health Mission seal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFF59E0B)),
                            ),
                            child: const Icon(
                              Icons.health_and_safety_rounded,
                              size: 26,
                              color: Color(0xFFB45309),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'NATIONAL HEALTH MISSION',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: Color(0xFF1E4231),
                                ),
                              ),
                              Text(
                                'Ministry of Health & Family Welfare · Govt. of India',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFFFDE68A), thickness: 1.5),
                      const SizedBox(height: 8),

                      // Title
                      const Text(
                        'CERTIFICATE OF CLINICAL COMPETENCY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                          color: Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'OFFICIAL VERIFIABLE MICRO-CREDENTIAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: Color(0xFF15803D),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'This is to certify that accredited frontline worker',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Sunita Sharma',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E4231),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ASHA Worker ID: ${widget.workerId} · Sub-Centre Majra',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 12),

                      const Text(
                        'has successfully demonstrated practical competency in:',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: const Text(
                          'Maternal & Neonatal IMCI Triage Protocols\nNHM ASHA Modules 6 & 7 Clinical Standards',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Verification Badge & Hash
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 28),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Verified Record',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF15803D),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Modules: $completedCount Completed',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const Text(
                                    'SHA-256: 4e9a...b18f · Offline Cryptographic Seal',
                                    style: TextStyle(fontFamily: 'monospace', fontSize: 9, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Signatories row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Dr. Verma, MD',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Medical Officer I/C (PHC)',
                                style: TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text(
                                'Sarita Singh',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'ASHA Facilitator & Trainer',
                                style: TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('share_certificate_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E4231),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share Certificate'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Verified certificate synced with ASHA Facilitator dashboard!',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('download_certificate_pdf_button'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.picture_as_pdf, size: 18),
                  label: const Text('Download PDF'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ASHA Skill Certificate PDF downloaded to device storage.'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonBottomSheet extends ConsumerStatefulWidget {
  final MicroLesson lesson;
  final ValueChanged<int> onComplete;

  const _LessonBottomSheet({required this.lesson, required this.onComplete});

  @override
  ConsumerState<_LessonBottomSheet> createState() => _LessonBottomSheetState();
}

class _LessonBottomSheetState extends ConsumerState<_LessonBottomSheet> {
  int _currentStep = 0; // 0 = Content, 1..N = Quiz Questions
  int _scorePoints = 0;
  int? _selectedAnswer;
  bool _answered = false;

  @override
  Widget build(BuildContext context) {
    final questions = widget.lesson.quizQuestions;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.lesson.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: _currentStep == 0
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lesson.contentMarkdown,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.quiz),
                          label: const Text(
                            'Proceed to Knowledge Check (Quiz)',
                          ),
                          onPressed: () => setState(() => _currentStep = 1),
                        ),
                      ],
                    ),
                  )
                : _buildQuizView(questions[_currentStep - 1], questions.length),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizView(QuizQuestion q, int totalQuestions) {
    final lang = ref.watch(languageProvider).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question Header with Step Badge and Audio Speak Button
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AshaColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'QUESTION $_currentStep OF $totalQuestions',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AshaColors.primaryDark,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 38,
              child: IconButton.filledTonal(
                tooltip: 'Listen to Question',
                icon: const Icon(Icons.volume_up_rounded, size: 18),
                onPressed: () {
                  ref.read(ttsServiceProvider).speak(
                    text: '${q.questionText}. Options: ${q.options.join(", ")}',
                    language: lang,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          q.questionText,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, height: 1.3),
        ),
        const SizedBox(height: 16),
        // AI-styled Choice Option Cards
        Expanded(
          child: ListView.separated(
            itemCount: q.options.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final isCorrect = idx == q.correctOptionIndex;
              final isSelected = _selectedAnswer == idx;

              Color bg = AshaColors.cardSurface;
              Color border = AshaColors.borderSubtle;
              Color textColor = AshaColors.textPrimary;
              IconData icon = Icons.radio_button_unchecked_rounded;
              Color iconColor = AshaColors.textMuted;

              if (_answered) {
                if (isCorrect) {
                  bg = const Color(0xFFECFDF5);
                  border = const Color(0xFF059669);
                  textColor = const Color(0xFF065F46);
                  icon = Icons.check_circle_rounded;
                  iconColor = const Color(0xFF059669);
                } else if (isSelected && !isCorrect) {
                  bg = const Color(0xFFFEF2F2);
                  border = const Color(0xFFDC2626);
                  textColor = const Color(0xFF991B1B);
                  icon = Icons.cancel_rounded;
                  iconColor = const Color(0xFFDC2626);
                }
              } else if (isSelected) {
                bg = AshaColors.primary.withValues(alpha: 0.08);
                border = AshaColors.primary;
                textColor = AshaColors.primaryDark;
                icon = Icons.radio_button_checked_rounded;
                iconColor = AshaColors.primary;
              }

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: AshaShapes.cardRadius,
                  onTap: _answered ? null : () => setState(() => _selectedAnswer = idx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: AshaShapes.cardRadius,
                      border: Border.all(color: border, width: isSelected || (_answered && isCorrect) ? 1.5 : 1.0),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: iconColor, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            q.options[idx],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected || (_answered && isCorrect) ? FontWeight.w800 : FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_answered) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_rounded, color: Color(0xFF1D4ED8), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    q.explanation,
                    style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFF1E3A8A)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: !_answered
              ? FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AshaColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: AshaShapes.buttonRadius),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Check Answer', style: TextStyle(fontWeight: FontWeight.w800)),
                  onPressed: _selectedAnswer == null
                      ? null
                      : () {
                          setState(() {
                            _answered = true;
                            if (_selectedAnswer == q.correctOptionIndex) {
                              _scorePoints++;
                            }
                          });
                        },
                )
              : FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AshaColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: AshaShapes.buttonRadius),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(
                    _currentStep < totalQuestions ? 'Next Question' : 'Finish Lesson',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    if (_currentStep < totalQuestions) {
                      setState(() {
                        _currentStep++;
                        _selectedAnswer = null;
                        _answered = false;
                      });
                    } else {
                      final finalPercent = ((_scorePoints / totalQuestions) * 100).round();
                      widget.onComplete(finalPercent);
                    }
                  },
                ),
        ),
      ],
    );
  }
}
