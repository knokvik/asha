import 'package:drift/drift.dart';
import 'members_table.dart';

class VisitSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text().references(Members, #id)();
  TextColumn get programCode => text()();
  TextColumn get visitType => text()();
  IntColumn  get dueDate => integer()();
  IntColumn  get dueWindowStart => integer().nullable()();
  IntColumn  get dueWindowEnd => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get skipReason => text().nullable()();
  IntColumn  get completedAt => integer().nullable()();
  TextColumn get completedEncounterId => text().nullable()();
  IntColumn  get createdAt => integer()();
  IntColumn  get rescheduledCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
