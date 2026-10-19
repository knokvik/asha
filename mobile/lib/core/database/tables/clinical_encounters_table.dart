import 'package:drift/drift.dart';
import 'members_table.dart';

class ClinicalEncounters extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text().references(Members, #id)();
  TextColumn get encounterType => text()();
  TextColumn get programCode => text()();
  IntColumn  get encounterDate => integer()();
  TextColumn get ashaId => text()();
  TextColumn get ruleVersionId => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('draft'))();
  TextColumn get visitNotes => text().nullable()();
  IntColumn  get createdAt => integer()();
  IntColumn  get updatedAt => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn  get serverVersion => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
