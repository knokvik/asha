import 'package:drift/drift.dart';
import 'members_table.dart';

class IncentiveEvents extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text().references(Members, #id)();
  TextColumn get encounterId => text().nullable()();
  TextColumn get activityCode => text()();
  TextColumn get catalogueVersionId => text()();
  IntColumn  get eventDate => integer()();
  TextColumn get status => text().withDefault(const Constant('eligible'))();
  TextColumn get ineligibilityReason => text().nullable()();
  TextColumn get evidenceRecordId => text().nullable()();
  IntColumn  get createdAt => integer()();
  TextColumn get idempotencyKey => text().unique()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
