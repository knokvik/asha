import 'package:drift/drift.dart';
import 'clinical_encounters_table.dart';

class TriageResults extends Table {
  TextColumn get id => text()();
  TextColumn get encounterId => text().references(ClinicalEncounters, #id)();
  TextColumn get flag => text()();
  TextColumn get ruleVersionId => text()();
  TextColumn get findingsJson => text()();
  TextColumn get missingFieldsJson => text().withDefault(const Constant('[]'))();
  BoolColumn  get escalatedForMissingData => boolean().withDefault(const Constant(false))();
  TextColumn get mlContributionJson => text().nullable()();
  TextColumn get overrideFlag => text().nullable()();
  TextColumn get overrideReason => text().nullable()();
  TextColumn get overrideVoiceNotePath => text().nullable()();
  TextColumn get overridingUserId => text().nullable()();
  IntColumn  get evaluatedAt => integer()();
  IntColumn  get overriddenAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
