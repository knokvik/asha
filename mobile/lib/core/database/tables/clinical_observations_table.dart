import 'package:drift/drift.dart';
import 'clinical_encounters_table.dart';

class ClinicalObservations extends Table {
  TextColumn get id => text()();
  TextColumn get encounterId => text().references(ClinicalEncounters, #id)();
  TextColumn get observationCode => text()();
  TextColumn get valueText => text().nullable()();
  RealColumn  get valueNumeric => real().nullable()();
  TextColumn get valueUnit => text().nullable()();
  TextColumn get valueEnum => text().nullable()();
  TextColumn get source => text().withDefault(const Constant('MANUAL'))();
  IntColumn  get observedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
