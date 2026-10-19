import 'package:drift/drift.dart';
import 'users_table.dart';

class IncentiveClaims extends Table {
  TextColumn get id => text()();
  TextColumn get workerId => text().references(Users, #id)();
  TextColumn get claimPeriod => text()();
  TextColumn get status => text().withDefault(const Constant('generated'))();
  TextColumn get lineItemsJson => text().withDefault(const Constant('[]'))();
  RealColumn  get totalAmount => real().withDefault(const Constant(0.0))();
  TextColumn get pdfPath => text().nullable()();
  TextColumn get paymentReference => text().nullable()();
  IntColumn  get submittedAt => integer().nullable()();
  IntColumn  get verifiedAt => integer().nullable()();
  IntColumn  get paidAt => integer().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
