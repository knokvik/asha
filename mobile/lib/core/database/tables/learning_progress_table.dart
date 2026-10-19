import 'package:drift/drift.dart';

class LearningProgress extends Table {
  TextColumn get id => text()();
  TextColumn get workerId => text()();
  TextColumn get moduleId => text()();
  TextColumn get lessonId => text()();
  TextColumn get status => text().withDefault(const Constant('not_started'))();
  IntColumn  get score => integer().nullable()();
  IntColumn  get startedAt => integer().nullable()();
  IntColumn  get completedAt => integer().nullable()();
  IntColumn  get quizAttempts => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
