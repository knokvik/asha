import 'package:drift/drift.dart';
import 'clinical_encounters_table.dart';
import 'members_table.dart';

class ReferralRecords extends Table {
  TextColumn get id => text()();
  TextColumn get encounterId => text().references(ClinicalEncounters, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  TextColumn get triageFlag => text()();
  TextColumn get destinationFacilityId => text().nullable()();
  TextColumn get destinationLevel => text().nullable()();
  TextColumn get transportArranged => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('created'))();
  TextColumn get outcome => text().nullable()();
  TextColumn get outcomeRecordedBy => text().nullable()();
  IntColumn  get outcomeRecordedAt => integer().nullable()();
  TextColumn get referralNoteText => text().nullable()();
  TextColumn get referralPdfPath => text().nullable()();
  TextColumn get referralQrData => text().nullable()();
  IntColumn  get createdAt => integer()();
  IntColumn  get updatedAt => integer()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
