import 'package:drift/drift.dart';

class Households extends Table {
  TextColumn get id => text()();
  TextColumn get village => text()();
  TextColumn get hamlet => text().nullable()();
  TextColumn get headName => text()();
  TextColumn get socialCategory =>
      text().nullable()(); // SC | ST | OBC | General
  BoolColumn get isBpl => boolean().withDefault(const Constant(false))();
  TextColumn get contactPhone => text().nullable()();
  TextColumn get latitude => text().nullable()();
  TextColumn get longitude => text().nullable()();
  TextColumn get landmarkNotes => text().nullable()();
  IntColumn get memberCount => integer().withDefault(const Constant(0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get createdBy => text()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();
  IntColumn get serverVersion => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
