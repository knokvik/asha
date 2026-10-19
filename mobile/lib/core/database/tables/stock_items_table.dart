import 'package:drift/drift.dart';

class StockItems extends Table {
  TextColumn get id => text()();
  TextColumn get workerId => text()();
  TextColumn get itemCode => text()();
  TextColumn get itemName => text()();
  RealColumn  get quantity => real().withDefault(const Constant(0.0))();
  RealColumn  get minThreshold => real().withDefault(const Constant(5.0))();
  TextColumn get unit => text()();
  IntColumn  get lastUpdatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
