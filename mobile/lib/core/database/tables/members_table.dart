import 'package:drift/drift.dart';
import 'households_table.dart';

class Members extends Table {
  TextColumn get id => text()();
  TextColumn get householdId => text().references(Households, #id)();
  TextColumn get name => text()();
  TextColumn get namePhonetic => text().nullable()();
  IntColumn get dobApprox => integer().nullable()();
  BoolColumn get isDobApprox =>
      boolean().withDefault(const Constant(false))();
  TextColumn get sex => text()(); // M | F | Other
  TextColumn get relationshipToHead => text().nullable()();
  TextColumn get abhaId => text().nullable()();
  TextColumn get rchId => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get socialCategory => text().nullable()();
  BoolColumn get isBpl => boolean().nullable()();
  TextColumn get lifecycleStatus =>
      text().withDefault(const Constant('active'))(); // active | deceased | migrated | married_out
  TextColumn get consentStatus =>
      text().withDefault(const Constant('pending'))(); // pending | given | declined | withdrawn
  IntColumn get consentUpdatedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get createdBy => text()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();
  IntColumn get serverVersion => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
