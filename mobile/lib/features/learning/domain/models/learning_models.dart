import 'package:flutter/foundation.dart';

enum LessonFormat { audio, video, illustrated }

enum LessonCategory {
  maternal,
  neonatal,
  child,
  immunization,
  ncd,
  tb,
  softSkills,
}

@immutable
class QuizQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionText': questionText,
    'options': options,
    'correctOptionIndex': correctOptionIndex,
    'explanation': explanation,
  };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    id: json['id'] as String,
    questionText: json['questionText'] as String,
    options: List<String>.from(json['options'] as List),
    correctOptionIndex: json['correctOptionIndex'] as int,
    explanation: json['explanation'] as String,
  );
}

@immutable
class MicroLesson {
  final String id;
  final String moduleId;
  final String title;
  final String description;
  final int durationMinutes;
  final LessonCategory category;
  final LessonFormat format;
  final String contentMarkdown;
  final List<QuizQuestion> quizQuestions;
  final String? dangerSignTriggerCode; // e.g. FAST_BREATHING_NEONATE
  final bool isMandatory;

  const MicroLesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.category,
    required this.format,
    required this.contentMarkdown,
    required this.quizQuestions,
    this.dangerSignTriggerCode,
    this.isMandatory = false,
  });
}

@immutable
class SimulatedClinicalScenario {
  final String id;
  final String title;
  final String patientProfile;
  final String presentingSymptoms;
  final List<String> availableObservations;
  final String correctSeverity; // RED, YELLOW, GREEN
  final String correctNextAction;
  final String teachingPoints;

  const SimulatedClinicalScenario({
    required this.id,
    required this.title,
    required this.patientProfile,
    required this.presentingSymptoms,
    required this.availableObservations,
    required this.correctSeverity,
    required this.correctNextAction,
    required this.teachingPoints,
  });
}

@immutable
class JobAidReferenceCard {
  final String id;
  final String title;
  final String programCategory;
  final List<String> keywords;
  final String summarySteps;
  final String dosageOrThresholdTable;
  final String redFlags;

  const JobAidReferenceCard({
    required this.id,
    required this.title,
    required this.programCategory,
    required this.keywords,
    required this.summarySteps,
    required this.dosageOrThresholdTable,
    required this.redFlags,
  });
}
