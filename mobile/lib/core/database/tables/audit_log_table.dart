import 'package:drift/drift.dart';

class AuditLog extends Table {
  TextColumn get id => text()();
  TextColumn get entityTable => text().named('table_name')();
  TextColumn get recordId => text()();
  TextColumn get fieldName => text().nullable()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  TextColumn get changedBy => text()();
  TextColumn get deviceId => text()();
  TextColumn get appVersion => text()();
  TextColumn get ruleVersionId => text().nullable()();
  IntColumn  get deviceTimestamp => integer()();
  IntColumn  get serverTimestamp => integer().nullable()();
  TextColumn get chainHash => text()();

  @override
  Set<Column> get primaryKey => {id};
}
