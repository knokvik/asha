import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/features/learning/domain/learning_service.dart';

void main() {
  late AppDatabase db;
  late LearningService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = LearningService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Task 15.1: Micro-Learning, Spaced Repetition & Job Aids (Requirement 37)', () {
    test('37.2, 37.6: Records lesson completion and score in Local_Store', () async {
      await service.recordLessonCompletion(
        workerId: 'worker_01',
        moduleId: 'mod_hbnc',
        lessonId: 'lesson-neonatal-breathing',
        score: 100,
      );

      final progress = await service.getWorkerProgress('worker_01');
      expect(progress.length, equals(1));
      expect(progress.first.lessonId, equals('lesson-neonatal-breathing'));
      expect(progress.first.status, equals('completed'));
      expect(progress.first.score, equals(100));
      expect(progress.first.completedAt, isNotNull);
    });

    test('37.5: Enforces maximum daily mandatory lesson count to prevent click-through', () async {
      expect(await service.canTakeMandatoryLesson('worker_02'), isTrue);

      // Complete 4 mandatory lessons
      for (int i = 1; i <= 4; i++) {
        await service.recordLessonCompletion(
          workerId: 'worker_02',
          moduleId: 'mod_daily',
          lessonId: 'lesson_day_$i',
          score: 80,
        );
      }

      // 5th mandatory lesson should be capped for the day
      expect(await service.canTakeMandatoryLesson('worker_02'), isFalse);
    });

    test('37.3: Suggests relevant micro-lesson with supportive framing on gap detection', () {
      final suggestionForSkippedSteps = service.suggestLessonForGap(
        skippedStepsCount: 3,
        overrideCount: 0,
        hasMissedIfaRecords: false,
      );
      expect(suggestionForSkippedSteps?.id, equals('lesson-neonatal-breathing'));

      final suggestionForOverrides = service.suggestLessonForGap(
        skippedStepsCount: 0,
        overrideCount: 2,
        hasMissedIfaRecords: false,
      );
      expect(suggestionForOverrides?.id, equals('lesson-maternal-preeclampsia'));

      final suggestionForIfa = service.suggestLessonForGap(
        skippedStepsCount: 0,
        overrideCount: 0,
        hasMissedIfaRecords: true,
      );
      expect(suggestionForIfa?.id, equals('lesson-softskills-counselling'));
    });

    test('37.4: Offers 2-minute refresher on specific RED triage danger sign', () {
      final refresher = service.getRefresherForRedFlag('FAST_BREATHING_NEONATE');
      expect(refresher, isNotNull);
      expect(refresher!.title, contains('Neonatal Fast Breathing'));
      expect(refresher.durationMinutes, lessThanOrEqualTo(3));
    });

    test('37.10: Searchable offline reference-card library returns relevant job aids', () {
      final hbncAids = service.searchJobAids('HBNC');
      expect(hbncAids.length, greaterThanOrEqualTo(1));
      expect(hbncAids.first.title, contains('HBNC Home Visit Schedule'));

      final paracetamolAids = service.searchJobAids('paracetamol');
      expect(paracetamolAids.length, greaterThanOrEqualTo(1));
      expect(paracetamolAids.first.summarySteps, contains('ORS'));

      final cbacAids = service.searchJobAids('cbac');
      expect(cbacAids.length, greaterThanOrEqualTo(1));
      expect(cbacAids.first.dosageOrThresholdTable, contains('Waist'));
    });

    test('37.6: Generates verifiable completion certificate summary for supervisor sync', () async {
      await service.recordLessonCompletion(
        workerId: 'worker_cert',
        moduleId: 'mod_1',
        lessonId: 'l1',
        score: 90,
      );
      await service.recordLessonCompletion(
        workerId: 'worker_cert',
        moduleId: 'mod_2',
        lessonId: 'l2',
        score: 100,
      );

      final cert = await service.generateCompletionCertificate('worker_cert');
      expect(cert['totalLessonsCompleted'], equals(2));
      expect(cert['averageQuizScore'], equals(95));
      expect(cert['shareableWithSupervisor'], isTrue);
      expect(cert['verificationHash'], contains('worker_cert'));
    });
  });
}
