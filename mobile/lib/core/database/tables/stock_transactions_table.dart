import 'package:drift/drift.dart';
import 'stock_items_table.dart';

class StockTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(StockItems, #id)();
  TextColumn get transactionType => text()();
  RealColumn  get quantityDelta => real()();
  TextColumn get relatedEncounterId => text().nullable()();
  TextColumn get relatedMemberId => text().nullable()();
  IntColumn  get recordedAt => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
