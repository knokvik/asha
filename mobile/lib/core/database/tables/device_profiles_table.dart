import 'package:drift/drift.dart';

class DeviceProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get deviceName => text()();
  TextColumn get bleServiceUuid => text().nullable()();
  TextColumn get bleCharacteristicUuid => text().nullable()();
  TextColumn get measurementType => text()();
  TextColumn get unit => text()();
  RealColumn  get minPlausible => real()();
  RealColumn  get maxPlausible => real()();
  TextColumn get unitConversionJson => text().nullable()();
  BoolColumn  get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
