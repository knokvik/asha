import 'package:drift/drift.dart';

class FacilityDirectory extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get facilityLevel => text()();
  TextColumn get district => text().nullable()();
  TextColumn get block => text().nullable()();
  TextColumn get village => text().nullable()();
  RealColumn  get latitude => real().nullable()();
  RealColumn  get longitude => real().nullable()();
  TextColumn get contactPhone => text().nullable()();
  TextColumn get servicesJson => text().withDefault(const Constant('[]'))();
  BoolColumn  get isActive => boolean().withDefault(const Constant(true))();
  IntColumn  get lastUpdatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
