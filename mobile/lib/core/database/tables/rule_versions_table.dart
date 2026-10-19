import 'package:drift/drift.dart';

class RuleVersions extends Table {
  TextColumn get id => text()();
  TextColumn get versionString => text()();
  IntColumn  get publishedAt => integer()();
  TextColumn get bundleHash => text()();
  TextColumn get bundlePath => text().nullable()();
  BoolColumn  get isActive => boolean().withDefault(const Constant(false))();
  TextColumn get clinicalLeadId => text().nullable()();
  TextColumn get approvalSignature => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
