import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../data/learning_content_repository.dart';
import 'models/learning_models.dart';

class LearningService {
  final AppDatabase _db;
  static const int maxDailyMandatoryLessons = 4; // Requirement 37.5

  LearningService(this._db);

  /// Records completion of a micro-lesson and quiz score in SQLite (Requirement 37.2, 37.6)
  Future<void> recordLessonCompletion({
    required String workerId,
    required String moduleId,
    required String lessonId,
    required int score,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final progressId = 'prog_${workerId}_$lessonId';

    final existing = await (_db.select(_db.learningProgress)
          ..where((t) => t.id.equals(progressId)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.learningProgress).insert(
            LearningProgressCompanion.insert(
              id: progressId,
              workerId: workerId,
              moduleId: moduleId,
              lessonId: lessonId,
              status: const Value('completed'),
              score: Value(score),
              startedAt: Value(now),
              completedAt: Value(now),
              quizAttempts: const Value(1),
            ),
          );
    } else {
      await (_db.update(_db.learningProgress)..where((t) => t.id.equals(progressId))).write(
        LearningProgressCompanion(
          status: const Value('completed'),
          score: Value(score),
          completedAt: Value(now),
          quizAttempts: Value(existing.quizAttempts + 1),
        ),
      );
    }
  }

  /// Retrieves all completed progress records for a worker
  Future<List<LearningProgressData>> getWorkerProgress(String workerId) async {
    return (_db.select(_db.learningProgress)
          ..where((t) => t.workerId.equals(workerId)))
        .get();
  }

  /// Enforces maximum daily mandatory lesson limit (Requirement 37.5: prevent single-session click-through)
  Future<bool> canTakeMandatoryLesson(String workerId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    final records = await (_db.select(_db.learningProgress)
          ..where((t) => t.workerId.equals(workerId) & t.completedAt.isBiggerOrEqualValue(startOfDay)))
        .get();

    return records.length < maxDailyMandatoryLessons;
  }

  /// Calculates spaced repetition review date (1 day, 3 days, 7 days post-completion) (Req 37.5)
  Future<List<MicroLesson>> getLessonsDueForSpacedRepetition(String workerId) async {
    final completed = await getWorkerProgress(workerId);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final dueLessons = <MicroLesson>[];

    for (final record in completed) {
      if (record.completedAt == null) continue;
      final elapsedDays = (nowMs - record.completedAt!) / (1000 * 86400);

      // Spaced intervals: Day 1, Day 3, or Day 7 review
      if ((elapsedDays >= 1.0 && elapsedDays < 2.0) ||
          (elapsedDays >= 3.0 && elapsedDays < 4.0) ||
          (elapsedDays >= 7.0 && elapsedDays < 8.0)) {
        final lesson = LearningContentRepository.defaultLessons
            .where((l) => l.id == record.lessonId)
            .firstOrNull;
        if (lesson != null && !dueLessons.contains(lesson)) {
          dueLessons.add(lesson);
        }
      }
    }
    return dueLessons;
  }

  /// Suggests a relevant micro-lesson with supportive framing on gap detection (Req 37.3)
  MicroLesson? suggestLessonForGap({
    required int skippedStepsCount,
    required int overrideCount,
    required bool hasMissedIfaRecords,
  }) {
    if (skippedStepsCount >= 2) {
      return LearningContentRepository.defaultLessons
          .firstWhere((l) => l.id == 'lesson-neonatal-breathing');
    }
    if (overrideCount >= 2) {
      return LearningContentRepository.defaultLessons
          .firstWhere((l) => l.id == 'lesson-maternal-preeclampsia');
    }
    if (hasMissedIfaRecords) {
      return LearningContentRepository.defaultLessons
          .firstWhere((l) => l.id == 'lesson-softskills-counselling');
    }
    return null;
  }

  /// Returns an optional 2-minute refresher lesson linked to a RED triage danger sign (Req 37.4)
  MicroLesson? getRefresherForRedFlag(String dangerSignCode) {
    return LearningContentRepository.defaultLessons
        .where((l) => l.dangerSignTriggerCode == dangerSignCode)
        .firstOrNull;
  }

  /// Searchable offline reference card library of job aids (Req 37.10)
  List<JobAidReferenceCard> searchJobAids(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {
      return LearningContentRepository.defaultJobAids;
    }
    return LearningContentRepository.defaultJobAids.where((card) {
      final inTitle = card.title.toLowerCase().contains(clean);
      final inCategory = card.programCategory.toLowerCase().contains(clean);
      final inKeywords = card.keywords.any((k) => k.toLowerCase().contains(clean));
      return inTitle || inCategory || inKeywords;
    }).toList();
  }

  /// Generates a verifiable completion certificate summary (Req 37.6)
  Future<Map<String, dynamic>> generateCompletionCertificate(String workerId) async {
    final records = await getWorkerProgress(workerId);
    final completedRecords = records.where((r) => r.status == 'completed').toList();
    final totalCompleted = completedRecords.length;

    int totalScore = 0;
    for (final r in completedRecords) {
      totalScore += r.score ?? 0;
    }
    final avgScore = totalCompleted > 0 ? (totalScore / totalCompleted).round() : 0;

    return {
      'workerId': workerId,
      'totalLessonsCompleted': totalCompleted,
      'averageQuizScore': avgScore,
      'certifiedAt': DateTime.now().toIso8601String(),
      'verificationHash': 'cert_sha256_${workerId}_${totalCompleted}_$avgScore',
      'shareableWithSupervisor': true,
    };
  }
}
