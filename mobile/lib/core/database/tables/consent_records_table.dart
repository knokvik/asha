import 'package:drift/drift.dart';
import 'members_table.dart';

class ConsentRecords extends Table {
  TextColumn get id => text()();
  TextColumn get memberId => text().references(Members, #id)();
  TextColumn get consentVersion => text()();
  IntColumn get consentedAt => integer()();
  TextColumn get ashaId => text()();
  TextColumn get witnessType =>
      text()(); // TAP_ACK | THUMBPRINT_PHOTO | VOICE_HASH
  TextColumn get signatureHash => text()();
  TextColumn get voiceAckAudioHash => text().nullable()();
  BoolColumn get isGuardianConsent =>
      boolean().withDefault(const Constant(false))();
  TextColumn get guardianRelationship => text().nullable()();
  IntColumn get withdrawnAt => integer().nullable()();
  TextColumn get withdrawalReason => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
