import 'package:drift/drift.dart';

class SyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get targetTable => text()();
  TextColumn get recordId => text()();
  IntColumn  get priority => integer().withDefault(const Constant(3))();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  TextColumn get eventLogJson => text().withDefault(const Constant('[]'))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn  get createdAt => integer()();
  IntColumn  get lastAttemptAt => integer().nullable()();
  IntColumn  get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
