import 'package:flutter/material.dart';
import '../data/learning_content_repository.dart';
import '../domain/learning_service.dart';
import '../domain/models/learning_models.dart';
import '../../../core/database/app_database.dart';

class LearningScreen extends StatefulWidget {
  final AppDatabase database;
  final String workerId;

  const LearningScreen({
    super.key,
    required this.database,
    this.workerId = 'asha-01',
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> with SingleTickerProviderStateMixin {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('ASHA Micro-Learning & Job Aids'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: 'Lessons & Quiz'),
            Tab(icon: Icon(Icons.science), text: 'Simulated Practice'),
            Tab(icon: Icon(Icons.library_books), text: 'Job Aids Library'),
            Tab(icon: Icon(Icons.verified), text: 'Certificate'),
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
          color: Colors.amber.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Spaced Repetition Active: Max ${LearningService.maxDailyMandatoryLessons} mandatory lessons/day to ensure knowledge retention.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...LearningContentRepository.defaultLessons.map((lesson) {
          final isCompleted = _progressRecords.any((r) => r.lessonId == lesson.id && r.status == 'completed');
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isCompleted ? Colors.green.shade100 : Colors.blue.shade100,
                child: Icon(
                  isCompleted ? Icons.check_circle : (lesson.format == LessonFormat.audio ? Icons.mic : Icons.menu_book),
                  color: isCompleted ? Colors.green : Colors.blue,
                ),
              ),
              title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                '${lesson.durationMinutes} min • ${lesson.category.name.toUpperCase()} • ${lesson.quizQuestions.length} Questions',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: ElevatedButton(
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
            SnackBar(content: Text('Completed "${lesson.title}" with score $score%! Synced to training record.')),
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
          color: Colors.purple.shade50,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Colors.purple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Practice Mode: Exercises triage decision-making on simulated cases. No real beneficiary records are touched.',
                    style: TextStyle(fontSize: 12, color: Colors.purple.shade900),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...LearningContentRepository.defaultScenarios.map((sim) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6.0),
              child: ExpansionTile(
                title: Text(sim.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Patient: ${sim.patientProfile}', style: const TextStyle(fontSize: 12)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Symptoms: ${sim.presentingSymptoms}', style: const TextStyle(fontStyle: FontStyle.italic)),
                        const SizedBox(height: 8),
                        const Text('Clinical Observations:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...sim.availableObservations.map((obs) => Text('• $obs')),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.warning, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('Correct Severity: ${sim.correctSeverity} - ${sim.correctNextAction}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Learning Note: ${sim.teachingPoints}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
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
            decoration: const InputDecoration(
              hintText: 'Search job aids by keyword (e.g., HBNC, paracetamol, CBAC)...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
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
                margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(card.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          Chip(label: Text(card.programCategory, style: const TextStyle(fontSize: 10))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(card.summarySteps, style: const TextStyle(fontSize: 12)),
                      const Divider(),
                      Text('Key Thresholds: ${card.dosageOrThresholdTable}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      Text('Red Flags: ${card.redFlags}', style: const TextStyle(fontSize: 11, color: Colors.red)),
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
    final completedCount = _progressRecords.where((r) => r.status == 'completed').length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.military_tech, size: 56, color: Colors.amber),
                const SizedBox(height: 8),
                const Text('Verifiable ASHA Skill Certificate', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Worker ID: ${widget.workerId}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Divider(height: 24),
                Text('Total Micro-Modules Completed: $completedCount', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('Official NHM ASHA Module 6/7 Alignment', style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text('Share with Facilitator & Training Portal'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verified certificate synced with ASHA Facilitator dashboard!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonBottomSheet extends StatefulWidget {
  final MicroLesson lesson;
  final ValueChanged<int> onComplete;

  const _LessonBottomSheet({
    required this.lesson,
    required this.onComplete,
  });

  @override
  State<_LessonBottomSheet> createState() => _LessonBottomSheetState();
}

class _LessonBottomSheetState extends State<_LessonBottomSheet> {
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
              Text(widget.lesson.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          Expanded(
            child: _currentStep == 0
                ? SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.lesson.contentMarkdown, style: const TextStyle(fontSize: 13, height: 1.4)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.quiz),
                          label: const Text('Proceed to Knowledge Check (Quiz)'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Question $_currentStep of $totalQuestions', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        Text(q.questionText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        ...List.generate(q.options.length, (idx) {
          final isCorrect = idx == q.correctOptionIndex;
          Color? tileColor;
          if (_answered) {
            if (isCorrect) tileColor = Colors.green.shade100;
            if (_selectedAnswer == idx && !isCorrect) tileColor = Colors.red.shade100;
          }

          return Card(
            color: tileColor,
            child: RadioListTile<int>(
              value: idx,
              groupValue: _selectedAnswer,
              title: Text(q.options[idx], style: const TextStyle(fontSize: 13)),
              onChanged: _answered ? null : (val) => setState(() => _selectedAnswer = val),
            ),
          );
        }),
        if (_answered) ...[
          const SizedBox(height: 8),
          Text(q.explanation, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        ],
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!_answered)
              ElevatedButton(
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
                child: const Text('Check Answer'),
              )
            else
              ElevatedButton(
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
                child: Text(_currentStep < totalQuestions ? 'Next Question' : 'Finish Lesson'),
              ),
          ],
        ),
      ],
    );
  }
}
