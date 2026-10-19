import 'package:drift/drift.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get ashaId => text().withLength(min: 1, max: 50)();
  TextColumn get name => text()();
  TextColumn get role => text()(); // ASHA | ASHA_Facilitator | ANM_CHO | PHC_MO | Block_District_Officer | State_Admin | Auditor
  TextColumn get areaVillage => text().nullable()();
  TextColumn get areaSubcentre => text().nullable()();
  TextColumn get areaPhc => text().nullable()();
  TextColumn get areaBlock => text().nullable()();
  TextColumn get areaDistrict => text().nullable()();
  TextColumn get areaState => text().nullable()();
  TextColumn get hashedPin => text().nullable()();
  BlobColumn get pinSalt => blob().nullable()();
  TextColumn get offlineCredentialHash => text().nullable()();
  IntColumn get offlineCredExpiresAt => integer().nullable()();
  TextColumn get jwtRefreshToken => text().nullable()();
  IntColumn get lastJwtRefreshAt => integer().nullable()();
  IntColumn get failedPinAttempts =>
      integer().withDefault(const Constant(0))();
  IntColumn get lockoutUntil => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}
