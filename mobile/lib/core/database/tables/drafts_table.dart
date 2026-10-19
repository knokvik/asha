import 'package:drift/drift.dart';

class Drafts extends Table {
  TextColumn get id => text()();
  TextColumn get formType => text()();
  TextColumn get memberId => text().nullable()();
  TextColumn get partialDataJson => text()();
  IntColumn  get lastModifiedAt => integer()();
  IntColumn  get recoveryCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
