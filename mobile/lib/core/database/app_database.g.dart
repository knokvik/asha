// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ashaIdMeta = const VerificationMeta('ashaId');
  @override
  late final GeneratedColumn<String> ashaId = GeneratedColumn<String>(
    'asha_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _areaVillageMeta = const VerificationMeta(
    'areaVillage',
  );
  @override
  late final GeneratedColumn<String> areaVillage = GeneratedColumn<String>(
    'area_village',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaSubcentreMeta = const VerificationMeta(
    'areaSubcentre',
  );
  @override
  late final GeneratedColumn<String> areaSubcentre = GeneratedColumn<String>(
    'area_subcentre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaPhcMeta = const VerificationMeta(
    'areaPhc',
  );
  @override
  late final GeneratedColumn<String> areaPhc = GeneratedColumn<String>(
    'area_phc',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaBlockMeta = const VerificationMeta(
    'areaBlock',
  );
  @override
  late final GeneratedColumn<String> areaBlock = GeneratedColumn<String>(
    'area_block',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaDistrictMeta = const VerificationMeta(
    'areaDistrict',
  );
  @override
  late final GeneratedColumn<String> areaDistrict = GeneratedColumn<String>(
    'area_district',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _areaStateMeta = const VerificationMeta(
    'areaState',
  );
  @override
  late final GeneratedColumn<String> areaState = GeneratedColumn<String>(
    'area_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hashedPinMeta = const VerificationMeta(
    'hashedPin',
  );
  @override
  late final GeneratedColumn<String> hashedPin = GeneratedColumn<String>(
    'hashed_pin',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pinSaltMeta = const VerificationMeta(
    'pinSalt',
  );
  @override
  late final GeneratedColumn<Uint8List> pinSalt = GeneratedColumn<Uint8List>(
    'pin_salt',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offlineCredentialHashMeta =
      const VerificationMeta('offlineCredentialHash');
  @override
  late final GeneratedColumn<String> offlineCredentialHash =
      GeneratedColumn<String>(
        'offline_credential_hash',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _offlineCredExpiresAtMeta =
      const VerificationMeta('offlineCredExpiresAt');
  @override
  late final GeneratedColumn<int> offlineCredExpiresAt = GeneratedColumn<int>(
    'offline_cred_expires_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jwtRefreshTokenMeta = const VerificationMeta(
    'jwtRefreshToken',
  );
  @override
  late final GeneratedColumn<String> jwtRefreshToken = GeneratedColumn<String>(
    'jwt_refresh_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastJwtRefreshAtMeta = const VerificationMeta(
    'lastJwtRefreshAt',
  );
  @override
  late final GeneratedColumn<int> lastJwtRefreshAt = GeneratedColumn<int>(
    'last_jwt_refresh_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failedPinAttemptsMeta = const VerificationMeta(
    'failedPinAttempts',
  );
  @override
  late final GeneratedColumn<int> failedPinAttempts = GeneratedColumn<int>(
    'failed_pin_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lockoutUntilMeta = const VerificationMeta(
    'lockoutUntil',
  );
  @override
  late final GeneratedColumn<int> lockoutUntil = GeneratedColumn<int>(
    'lockout_until',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ashaId,
    name,
    role,
    areaVillage,
    areaSubcentre,
    areaPhc,
    areaBlock,
    areaDistrict,
    areaState,
    hashedPin,
    pinSalt,
    offlineCredentialHash,
    offlineCredExpiresAt,
    jwtRefreshToken,
    lastJwtRefreshAt,
    failedPinAttempts,
    lockoutUntil,
    createdAt,
    updatedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('asha_id')) {
      context.handle(
        _ashaIdMeta,
        ashaId.isAcceptableOrUnknown(data['asha_id']!, _ashaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ashaIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('area_village')) {
      context.handle(
        _areaVillageMeta,
        areaVillage.isAcceptableOrUnknown(
          data['area_village']!,
          _areaVillageMeta,
        ),
      );
    }
    if (data.containsKey('area_subcentre')) {
      context.handle(
        _areaSubcentreMeta,
        areaSubcentre.isAcceptableOrUnknown(
          data['area_subcentre']!,
          _areaSubcentreMeta,
        ),
      );
    }
    if (data.containsKey('area_phc')) {
      context.handle(
        _areaPhcMeta,
        areaPhc.isAcceptableOrUnknown(data['area_phc']!, _areaPhcMeta),
      );
    }
    if (data.containsKey('area_block')) {
      context.handle(
        _areaBlockMeta,
        areaBlock.isAcceptableOrUnknown(data['area_block']!, _areaBlockMeta),
      );
    }
    if (data.containsKey('area_district')) {
      context.handle(
        _areaDistrictMeta,
        areaDistrict.isAcceptableOrUnknown(
          data['area_district']!,
          _areaDistrictMeta,
        ),
      );
    }
    if (data.containsKey('area_state')) {
      context.handle(
        _areaStateMeta,
        areaState.isAcceptableOrUnknown(data['area_state']!, _areaStateMeta),
      );
    }
    if (data.containsKey('hashed_pin')) {
      context.handle(
        _hashedPinMeta,
        hashedPin.isAcceptableOrUnknown(data['hashed_pin']!, _hashedPinMeta),
      );
    }
    if (data.containsKey('pin_salt')) {
      context.handle(
        _pinSaltMeta,
        pinSalt.isAcceptableOrUnknown(data['pin_salt']!, _pinSaltMeta),
      );
    }
    if (data.containsKey('offline_credential_hash')) {
      context.handle(
        _offlineCredentialHashMeta,
        offlineCredentialHash.isAcceptableOrUnknown(
          data['offline_credential_hash']!,
          _offlineCredentialHashMeta,
        ),
      );
    }
    if (data.containsKey('offline_cred_expires_at')) {
      context.handle(
        _offlineCredExpiresAtMeta,
        offlineCredExpiresAt.isAcceptableOrUnknown(
          data['offline_cred_expires_at']!,
          _offlineCredExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('jwt_refresh_token')) {
      context.handle(
        _jwtRefreshTokenMeta,
        jwtRefreshToken.isAcceptableOrUnknown(
          data['jwt_refresh_token']!,
          _jwtRefreshTokenMeta,
        ),
      );
    }
    if (data.containsKey('last_jwt_refresh_at')) {
      context.handle(
        _lastJwtRefreshAtMeta,
        lastJwtRefreshAt.isAcceptableOrUnknown(
          data['last_jwt_refresh_at']!,
          _lastJwtRefreshAtMeta,
        ),
      );
    }
    if (data.containsKey('failed_pin_attempts')) {
      context.handle(
        _failedPinAttemptsMeta,
        failedPinAttempts.isAcceptableOrUnknown(
          data['failed_pin_attempts']!,
          _failedPinAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('lockout_until')) {
      context.handle(
        _lockoutUntilMeta,
        lockoutUntil.isAcceptableOrUnknown(
          data['lockout_until']!,
          _lockoutUntilMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ashaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asha_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      areaVillage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_village'],
      ),
      areaSubcentre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_subcentre'],
      ),
      areaPhc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_phc'],
      ),
      areaBlock: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_block'],
      ),
      areaDistrict: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_district'],
      ),
      areaState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area_state'],
      ),
      hashedPin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hashed_pin'],
      ),
      pinSalt: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}pin_salt'],
      ),
      offlineCredentialHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}offline_credential_hash'],
      ),
      offlineCredExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offline_cred_expires_at'],
      ),
      jwtRefreshToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jwt_refresh_token'],
      ),
      lastJwtRefreshAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_jwt_refresh_at'],
      ),
      failedPinAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_pin_attempts'],
      )!,
      lockoutUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lockout_until'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String ashaId;
  final String name;
  final String role;
  final String? areaVillage;
  final String? areaSubcentre;
  final String? areaPhc;
  final String? areaBlock;
  final String? areaDistrict;
  final String? areaState;
  final String? hashedPin;
  final Uint8List? pinSalt;
  final String? offlineCredentialHash;
  final int? offlineCredExpiresAt;
  final String? jwtRefreshToken;
  final int? lastJwtRefreshAt;
  final int failedPinAttempts;
  final int? lockoutUntil;
  final int createdAt;
  final int updatedAt;
  final String syncStatus;
  const User({
    required this.id,
    required this.ashaId,
    required this.name,
    required this.role,
    this.areaVillage,
    this.areaSubcentre,
    this.areaPhc,
    this.areaBlock,
    this.areaDistrict,
    this.areaState,
    this.hashedPin,
    this.pinSalt,
    this.offlineCredentialHash,
    this.offlineCredExpiresAt,
    this.jwtRefreshToken,
    this.lastJwtRefreshAt,
    required this.failedPinAttempts,
    this.lockoutUntil,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['asha_id'] = Variable<String>(ashaId);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || areaVillage != null) {
      map['area_village'] = Variable<String>(areaVillage);
    }
    if (!nullToAbsent || areaSubcentre != null) {
      map['area_subcentre'] = Variable<String>(areaSubcentre);
    }
    if (!nullToAbsent || areaPhc != null) {
      map['area_phc'] = Variable<String>(areaPhc);
    }
    if (!nullToAbsent || areaBlock != null) {
      map['area_block'] = Variable<String>(areaBlock);
    }
    if (!nullToAbsent || areaDistrict != null) {
      map['area_district'] = Variable<String>(areaDistrict);
    }
    if (!nullToAbsent || areaState != null) {
      map['area_state'] = Variable<String>(areaState);
    }
    if (!nullToAbsent || hashedPin != null) {
      map['hashed_pin'] = Variable<String>(hashedPin);
    }
    if (!nullToAbsent || pinSalt != null) {
      map['pin_salt'] = Variable<Uint8List>(pinSalt);
    }
    if (!nullToAbsent || offlineCredentialHash != null) {
      map['offline_credential_hash'] = Variable<String>(offlineCredentialHash);
    }
    if (!nullToAbsent || offlineCredExpiresAt != null) {
      map['offline_cred_expires_at'] = Variable<int>(offlineCredExpiresAt);
    }
    if (!nullToAbsent || jwtRefreshToken != null) {
      map['jwt_refresh_token'] = Variable<String>(jwtRefreshToken);
    }
    if (!nullToAbsent || lastJwtRefreshAt != null) {
      map['last_jwt_refresh_at'] = Variable<int>(lastJwtRefreshAt);
    }
    map['failed_pin_attempts'] = Variable<int>(failedPinAttempts);
    if (!nullToAbsent || lockoutUntil != null) {
      map['lockout_until'] = Variable<int>(lockoutUntil);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      ashaId: Value(ashaId),
      name: Value(name),
      role: Value(role),
      areaVillage: areaVillage == null && nullToAbsent
          ? const Value.absent()
          : Value(areaVillage),
      areaSubcentre: areaSubcentre == null && nullToAbsent
          ? const Value.absent()
          : Value(areaSubcentre),
      areaPhc: areaPhc == null && nullToAbsent
          ? const Value.absent()
          : Value(areaPhc),
      areaBlock: areaBlock == null && nullToAbsent
          ? const Value.absent()
          : Value(areaBlock),
      areaDistrict: areaDistrict == null && nullToAbsent
          ? const Value.absent()
          : Value(areaDistrict),
      areaState: areaState == null && nullToAbsent
          ? const Value.absent()
          : Value(areaState),
      hashedPin: hashedPin == null && nullToAbsent
          ? const Value.absent()
          : Value(hashedPin),
      pinSalt: pinSalt == null && nullToAbsent
          ? const Value.absent()
          : Value(pinSalt),
      offlineCredentialHash: offlineCredentialHash == null && nullToAbsent
          ? const Value.absent()
          : Value(offlineCredentialHash),
      offlineCredExpiresAt: offlineCredExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(offlineCredExpiresAt),
      jwtRefreshToken: jwtRefreshToken == null && nullToAbsent
          ? const Value.absent()
          : Value(jwtRefreshToken),
      lastJwtRefreshAt: lastJwtRefreshAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastJwtRefreshAt),
      failedPinAttempts: Value(failedPinAttempts),
      lockoutUntil: lockoutUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(lockoutUntil),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      ashaId: serializer.fromJson<String>(json['ashaId']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      areaVillage: serializer.fromJson<String?>(json['areaVillage']),
      areaSubcentre: serializer.fromJson<String?>(json['areaSubcentre']),
      areaPhc: serializer.fromJson<String?>(json['areaPhc']),
      areaBlock: serializer.fromJson<String?>(json['areaBlock']),
      areaDistrict: serializer.fromJson<String?>(json['areaDistrict']),
      areaState: serializer.fromJson<String?>(json['areaState']),
      hashedPin: serializer.fromJson<String?>(json['hashedPin']),
      pinSalt: serializer.fromJson<Uint8List?>(json['pinSalt']),
      offlineCredentialHash: serializer.fromJson<String?>(
        json['offlineCredentialHash'],
      ),
      offlineCredExpiresAt: serializer.fromJson<int?>(
        json['offlineCredExpiresAt'],
      ),
      jwtRefreshToken: serializer.fromJson<String?>(json['jwtRefreshToken']),
      lastJwtRefreshAt: serializer.fromJson<int?>(json['lastJwtRefreshAt']),
      failedPinAttempts: serializer.fromJson<int>(json['failedPinAttempts']),
      lockoutUntil: serializer.fromJson<int?>(json['lockoutUntil']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ashaId': serializer.toJson<String>(ashaId),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'areaVillage': serializer.toJson<String?>(areaVillage),
      'areaSubcentre': serializer.toJson<String?>(areaSubcentre),
      'areaPhc': serializer.toJson<String?>(areaPhc),
      'areaBlock': serializer.toJson<String?>(areaBlock),
      'areaDistrict': serializer.toJson<String?>(areaDistrict),
      'areaState': serializer.toJson<String?>(areaState),
      'hashedPin': serializer.toJson<String?>(hashedPin),
      'pinSalt': serializer.toJson<Uint8List?>(pinSalt),
      'offlineCredentialHash': serializer.toJson<String?>(
        offlineCredentialHash,
      ),
      'offlineCredExpiresAt': serializer.toJson<int?>(offlineCredExpiresAt),
      'jwtRefreshToken': serializer.toJson<String?>(jwtRefreshToken),
      'lastJwtRefreshAt': serializer.toJson<int?>(lastJwtRefreshAt),
      'failedPinAttempts': serializer.toJson<int>(failedPinAttempts),
      'lockoutUntil': serializer.toJson<int?>(lockoutUntil),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  User copyWith({
    String? id,
    String? ashaId,
    String? name,
    String? role,
    Value<String?> areaVillage = const Value.absent(),
    Value<String?> areaSubcentre = const Value.absent(),
    Value<String?> areaPhc = const Value.absent(),
    Value<String?> areaBlock = const Value.absent(),
    Value<String?> areaDistrict = const Value.absent(),
    Value<String?> areaState = const Value.absent(),
    Value<String?> hashedPin = const Value.absent(),
    Value<Uint8List?> pinSalt = const Value.absent(),
    Value<String?> offlineCredentialHash = const Value.absent(),
    Value<int?> offlineCredExpiresAt = const Value.absent(),
    Value<String?> jwtRefreshToken = const Value.absent(),
    Value<int?> lastJwtRefreshAt = const Value.absent(),
    int? failedPinAttempts,
    Value<int?> lockoutUntil = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    String? syncStatus,
  }) => User(
    id: id ?? this.id,
    ashaId: ashaId ?? this.ashaId,
    name: name ?? this.name,
    role: role ?? this.role,
    areaVillage: areaVillage.present ? areaVillage.value : this.areaVillage,
    areaSubcentre: areaSubcentre.present
        ? areaSubcentre.value
        : this.areaSubcentre,
    areaPhc: areaPhc.present ? areaPhc.value : this.areaPhc,
    areaBlock: areaBlock.present ? areaBlock.value : this.areaBlock,
    areaDistrict: areaDistrict.present ? areaDistrict.value : this.areaDistrict,
    areaState: areaState.present ? areaState.value : this.areaState,
    hashedPin: hashedPin.present ? hashedPin.value : this.hashedPin,
    pinSalt: pinSalt.present ? pinSalt.value : this.pinSalt,
    offlineCredentialHash: offlineCredentialHash.present
        ? offlineCredentialHash.value
        : this.offlineCredentialHash,
    offlineCredExpiresAt: offlineCredExpiresAt.present
        ? offlineCredExpiresAt.value
        : this.offlineCredExpiresAt,
    jwtRefreshToken: jwtRefreshToken.present
        ? jwtRefreshToken.value
        : this.jwtRefreshToken,
    lastJwtRefreshAt: lastJwtRefreshAt.present
        ? lastJwtRefreshAt.value
        : this.lastJwtRefreshAt,
    failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
    lockoutUntil: lockoutUntil.present ? lockoutUntil.value : this.lockoutUntil,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      ashaId: data.ashaId.present ? data.ashaId.value : this.ashaId,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      areaVillage: data.areaVillage.present
          ? data.areaVillage.value
          : this.areaVillage,
      areaSubcentre: data.areaSubcentre.present
          ? data.areaSubcentre.value
          : this.areaSubcentre,
      areaPhc: data.areaPhc.present ? data.areaPhc.value : this.areaPhc,
      areaBlock: data.areaBlock.present ? data.areaBlock.value : this.areaBlock,
      areaDistrict: data.areaDistrict.present
          ? data.areaDistrict.value
          : this.areaDistrict,
      areaState: data.areaState.present ? data.areaState.value : this.areaState,
      hashedPin: data.hashedPin.present ? data.hashedPin.value : this.hashedPin,
      pinSalt: data.pinSalt.present ? data.pinSalt.value : this.pinSalt,
      offlineCredentialHash: data.offlineCredentialHash.present
          ? data.offlineCredentialHash.value
          : this.offlineCredentialHash,
      offlineCredExpiresAt: data.offlineCredExpiresAt.present
          ? data.offlineCredExpiresAt.value
          : this.offlineCredExpiresAt,
      jwtRefreshToken: data.jwtRefreshToken.present
          ? data.jwtRefreshToken.value
          : this.jwtRefreshToken,
      lastJwtRefreshAt: data.lastJwtRefreshAt.present
          ? data.lastJwtRefreshAt.value
          : this.lastJwtRefreshAt,
      failedPinAttempts: data.failedPinAttempts.present
          ? data.failedPinAttempts.value
          : this.failedPinAttempts,
      lockoutUntil: data.lockoutUntil.present
          ? data.lockoutUntil.value
          : this.lockoutUntil,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('ashaId: $ashaId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('areaVillage: $areaVillage, ')
          ..write('areaSubcentre: $areaSubcentre, ')
          ..write('areaPhc: $areaPhc, ')
          ..write('areaBlock: $areaBlock, ')
          ..write('areaDistrict: $areaDistrict, ')
          ..write('areaState: $areaState, ')
          ..write('hashedPin: $hashedPin, ')
          ..write('pinSalt: $pinSalt, ')
          ..write('offlineCredentialHash: $offlineCredentialHash, ')
          ..write('offlineCredExpiresAt: $offlineCredExpiresAt, ')
          ..write('jwtRefreshToken: $jwtRefreshToken, ')
          ..write('lastJwtRefreshAt: $lastJwtRefreshAt, ')
          ..write('failedPinAttempts: $failedPinAttempts, ')
          ..write('lockoutUntil: $lockoutUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    ashaId,
    name,
    role,
    areaVillage,
    areaSubcentre,
    areaPhc,
    areaBlock,
    areaDistrict,
    areaState,
    hashedPin,
    $driftBlobEquality.hash(pinSalt),
    offlineCredentialHash,
    offlineCredExpiresAt,
    jwtRefreshToken,
    lastJwtRefreshAt,
    failedPinAttempts,
    lockoutUntil,
    createdAt,
    updatedAt,
    syncStatus,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.ashaId == this.ashaId &&
          other.name == this.name &&
          other.role == this.role &&
          other.areaVillage == this.areaVillage &&
          other.areaSubcentre == this.areaSubcentre &&
          other.areaPhc == this.areaPhc &&
          other.areaBlock == this.areaBlock &&
          other.areaDistrict == this.areaDistrict &&
          other.areaState == this.areaState &&
          other.hashedPin == this.hashedPin &&
          $driftBlobEquality.equals(other.pinSalt, this.pinSalt) &&
          other.offlineCredentialHash == this.offlineCredentialHash &&
          other.offlineCredExpiresAt == this.offlineCredExpiresAt &&
          other.jwtRefreshToken == this.jwtRefreshToken &&
          other.lastJwtRefreshAt == this.lastJwtRefreshAt &&
          other.failedPinAttempts == this.failedPinAttempts &&
          other.lockoutUntil == this.lockoutUntil &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> ashaId;
  final Value<String> name;
  final Value<String> role;
  final Value<String?> areaVillage;
  final Value<String?> areaSubcentre;
  final Value<String?> areaPhc;
  final Value<String?> areaBlock;
  final Value<String?> areaDistrict;
  final Value<String?> areaState;
  final Value<String?> hashedPin;
  final Value<Uint8List?> pinSalt;
  final Value<String?> offlineCredentialHash;
  final Value<int?> offlineCredExpiresAt;
  final Value<String?> jwtRefreshToken;
  final Value<int?> lastJwtRefreshAt;
  final Value<int> failedPinAttempts;
  final Value<int?> lockoutUntil;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.ashaId = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.areaVillage = const Value.absent(),
    this.areaSubcentre = const Value.absent(),
    this.areaPhc = const Value.absent(),
    this.areaBlock = const Value.absent(),
    this.areaDistrict = const Value.absent(),
    this.areaState = const Value.absent(),
    this.hashedPin = const Value.absent(),
    this.pinSalt = const Value.absent(),
    this.offlineCredentialHash = const Value.absent(),
    this.offlineCredExpiresAt = const Value.absent(),
    this.jwtRefreshToken = const Value.absent(),
    this.lastJwtRefreshAt = const Value.absent(),
    this.failedPinAttempts = const Value.absent(),
    this.lockoutUntil = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String ashaId,
    required String name,
    required String role,
    this.areaVillage = const Value.absent(),
    this.areaSubcentre = const Value.absent(),
    this.areaPhc = const Value.absent(),
    this.areaBlock = const Value.absent(),
    this.areaDistrict = const Value.absent(),
    this.areaState = const Value.absent(),
    this.hashedPin = const Value.absent(),
    this.pinSalt = const Value.absent(),
    this.offlineCredentialHash = const Value.absent(),
    this.offlineCredExpiresAt = const Value.absent(),
    this.jwtRefreshToken = const Value.absent(),
    this.lastJwtRefreshAt = const Value.absent(),
    this.failedPinAttempts = const Value.absent(),
    this.lockoutUntil = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ashaId = Value(ashaId),
       name = Value(name),
       role = Value(role),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? ashaId,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? areaVillage,
    Expression<String>? areaSubcentre,
    Expression<String>? areaPhc,
    Expression<String>? areaBlock,
    Expression<String>? areaDistrict,
    Expression<String>? areaState,
    Expression<String>? hashedPin,
    Expression<Uint8List>? pinSalt,
    Expression<String>? offlineCredentialHash,
    Expression<int>? offlineCredExpiresAt,
    Expression<String>? jwtRefreshToken,
    Expression<int>? lastJwtRefreshAt,
    Expression<int>? failedPinAttempts,
    Expression<int>? lockoutUntil,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ashaId != null) 'asha_id': ashaId,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (areaVillage != null) 'area_village': areaVillage,
      if (areaSubcentre != null) 'area_subcentre': areaSubcentre,
      if (areaPhc != null) 'area_phc': areaPhc,
      if (areaBlock != null) 'area_block': areaBlock,
      if (areaDistrict != null) 'area_district': areaDistrict,
      if (areaState != null) 'area_state': areaState,
      if (hashedPin != null) 'hashed_pin': hashedPin,
      if (pinSalt != null) 'pin_salt': pinSalt,
      if (offlineCredentialHash != null)
        'offline_credential_hash': offlineCredentialHash,
      if (offlineCredExpiresAt != null)
        'offline_cred_expires_at': offlineCredExpiresAt,
      if (jwtRefreshToken != null) 'jwt_refresh_token': jwtRefreshToken,
      if (lastJwtRefreshAt != null) 'last_jwt_refresh_at': lastJwtRefreshAt,
      if (failedPinAttempts != null) 'failed_pin_attempts': failedPinAttempts,
      if (lockoutUntil != null) 'lockout_until': lockoutUntil,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? ashaId,
    Value<String>? name,
    Value<String>? role,
    Value<String?>? areaVillage,
    Value<String?>? areaSubcentre,
    Value<String?>? areaPhc,
    Value<String?>? areaBlock,
    Value<String?>? areaDistrict,
    Value<String?>? areaState,
    Value<String?>? hashedPin,
    Value<Uint8List?>? pinSalt,
    Value<String?>? offlineCredentialHash,
    Value<int?>? offlineCredExpiresAt,
    Value<String?>? jwtRefreshToken,
    Value<int?>? lastJwtRefreshAt,
    Value<int>? failedPinAttempts,
    Value<int?>? lockoutUntil,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      ashaId: ashaId ?? this.ashaId,
      name: name ?? this.name,
      role: role ?? this.role,
      areaVillage: areaVillage ?? this.areaVillage,
      areaSubcentre: areaSubcentre ?? this.areaSubcentre,
      areaPhc: areaPhc ?? this.areaPhc,
      areaBlock: areaBlock ?? this.areaBlock,
      areaDistrict: areaDistrict ?? this.areaDistrict,
      areaState: areaState ?? this.areaState,
      hashedPin: hashedPin ?? this.hashedPin,
      pinSalt: pinSalt ?? this.pinSalt,
      offlineCredentialHash:
          offlineCredentialHash ?? this.offlineCredentialHash,
      offlineCredExpiresAt: offlineCredExpiresAt ?? this.offlineCredExpiresAt,
      jwtRefreshToken: jwtRefreshToken ?? this.jwtRefreshToken,
      lastJwtRefreshAt: lastJwtRefreshAt ?? this.lastJwtRefreshAt,
      failedPinAttempts: failedPinAttempts ?? this.failedPinAttempts,
      lockoutUntil: lockoutUntil ?? this.lockoutUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ashaId.present) {
      map['asha_id'] = Variable<String>(ashaId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (areaVillage.present) {
      map['area_village'] = Variable<String>(areaVillage.value);
    }
    if (areaSubcentre.present) {
      map['area_subcentre'] = Variable<String>(areaSubcentre.value);
    }
    if (areaPhc.present) {
      map['area_phc'] = Variable<String>(areaPhc.value);
    }
    if (areaBlock.present) {
      map['area_block'] = Variable<String>(areaBlock.value);
    }
    if (areaDistrict.present) {
      map['area_district'] = Variable<String>(areaDistrict.value);
    }
    if (areaState.present) {
      map['area_state'] = Variable<String>(areaState.value);
    }
    if (hashedPin.present) {
      map['hashed_pin'] = Variable<String>(hashedPin.value);
    }
    if (pinSalt.present) {
      map['pin_salt'] = Variable<Uint8List>(pinSalt.value);
    }
    if (offlineCredentialHash.present) {
      map['offline_credential_hash'] = Variable<String>(
        offlineCredentialHash.value,
      );
    }
    if (offlineCredExpiresAt.present) {
      map['offline_cred_expires_at'] = Variable<int>(
        offlineCredExpiresAt.value,
      );
    }
    if (jwtRefreshToken.present) {
      map['jwt_refresh_token'] = Variable<String>(jwtRefreshToken.value);
    }
    if (lastJwtRefreshAt.present) {
      map['last_jwt_refresh_at'] = Variable<int>(lastJwtRefreshAt.value);
    }
    if (failedPinAttempts.present) {
      map['failed_pin_attempts'] = Variable<int>(failedPinAttempts.value);
    }
    if (lockoutUntil.present) {
      map['lockout_until'] = Variable<int>(lockoutUntil.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('ashaId: $ashaId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('areaVillage: $areaVillage, ')
          ..write('areaSubcentre: $areaSubcentre, ')
          ..write('areaPhc: $areaPhc, ')
          ..write('areaBlock: $areaBlock, ')
          ..write('areaDistrict: $areaDistrict, ')
          ..write('areaState: $areaState, ')
          ..write('hashedPin: $hashedPin, ')
          ..write('pinSalt: $pinSalt, ')
          ..write('offlineCredentialHash: $offlineCredentialHash, ')
          ..write('offlineCredExpiresAt: $offlineCredExpiresAt, ')
          ..write('jwtRefreshToken: $jwtRefreshToken, ')
          ..write('lastJwtRefreshAt: $lastJwtRefreshAt, ')
          ..write('failedPinAttempts: $failedPinAttempts, ')
          ..write('lockoutUntil: $lockoutUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HouseholdsTable extends Households
    with TableInfo<$HouseholdsTable, Household> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HouseholdsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _villageMeta = const VerificationMeta(
    'village',
  );
  @override
  late final GeneratedColumn<String> village = GeneratedColumn<String>(
    'village',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hamletMeta = const VerificationMeta('hamlet');
  @override
  late final GeneratedColumn<String> hamlet = GeneratedColumn<String>(
    'hamlet',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headNameMeta = const VerificationMeta(
    'headName',
  );
  @override
  late final GeneratedColumn<String> headName = GeneratedColumn<String>(
    'head_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _socialCategoryMeta = const VerificationMeta(
    'socialCategory',
  );
  @override
  late final GeneratedColumn<String> socialCategory = GeneratedColumn<String>(
    'social_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBplMeta = const VerificationMeta('isBpl');
  @override
  late final GeneratedColumn<bool> isBpl = GeneratedColumn<bool>(
    'is_bpl',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bpl" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _contactPhoneMeta = const VerificationMeta(
    'contactPhone',
  );
  @override
  late final GeneratedColumn<String> contactPhone = GeneratedColumn<String>(
    'contact_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<String> latitude = GeneratedColumn<String>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<String> longitude = GeneratedColumn<String>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _landmarkNotesMeta = const VerificationMeta(
    'landmarkNotes',
  );
  @override
  late final GeneratedColumn<String> landmarkNotes = GeneratedColumn<String>(
    'landmark_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _memberCountMeta = const VerificationMeta(
    'memberCount',
  );
  @override
  late final GeneratedColumn<int> memberCount = GeneratedColumn<int>(
    'member_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    village,
    hamlet,
    headName,
    socialCategory,
    isBpl,
    contactPhone,
    latitude,
    longitude,
    landmarkNotes,
    memberCount,
    createdAt,
    updatedAt,
    createdBy,
    syncStatus,
    serverVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'households';
  @override
  VerificationContext validateIntegrity(
    Insertable<Household> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('village')) {
      context.handle(
        _villageMeta,
        village.isAcceptableOrUnknown(data['village']!, _villageMeta),
      );
    } else if (isInserting) {
      context.missing(_villageMeta);
    }
    if (data.containsKey('hamlet')) {
      context.handle(
        _hamletMeta,
        hamlet.isAcceptableOrUnknown(data['hamlet']!, _hamletMeta),
      );
    }
    if (data.containsKey('head_name')) {
      context.handle(
        _headNameMeta,
        headName.isAcceptableOrUnknown(data['head_name']!, _headNameMeta),
      );
    } else if (isInserting) {
      context.missing(_headNameMeta);
    }
    if (data.containsKey('social_category')) {
      context.handle(
        _socialCategoryMeta,
        socialCategory.isAcceptableOrUnknown(
          data['social_category']!,
          _socialCategoryMeta,
        ),
      );
    }
    if (data.containsKey('is_bpl')) {
      context.handle(
        _isBplMeta,
        isBpl.isAcceptableOrUnknown(data['is_bpl']!, _isBplMeta),
      );
    }
    if (data.containsKey('contact_phone')) {
      context.handle(
        _contactPhoneMeta,
        contactPhone.isAcceptableOrUnknown(
          data['contact_phone']!,
          _contactPhoneMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('landmark_notes')) {
      context.handle(
        _landmarkNotesMeta,
        landmarkNotes.isAcceptableOrUnknown(
          data['landmark_notes']!,
          _landmarkNotesMeta,
        ),
      );
    }
    if (data.containsKey('member_count')) {
      context.handle(
        _memberCountMeta,
        memberCount.isAcceptableOrUnknown(
          data['member_count']!,
          _memberCountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Household map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Household(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      village: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}village'],
      )!,
      hamlet: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hamlet'],
      ),
      headName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}head_name'],
      )!,
      socialCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}social_category'],
      ),
      isBpl: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bpl'],
      )!,
      contactPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_phone'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}longitude'],
      ),
      landmarkNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}landmark_notes'],
      ),
      memberCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}member_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
    );
  }

  @override
  $HouseholdsTable createAlias(String alias) {
    return $HouseholdsTable(attachedDatabase, alias);
  }
}

class Household extends DataClass implements Insertable<Household> {
  final String id;
  final String village;
  final String? hamlet;
  final String headName;
  final String? socialCategory;
  final bool isBpl;
  final String? contactPhone;
  final String? latitude;
  final String? longitude;
  final String? landmarkNotes;
  final int memberCount;
  final int createdAt;
  final int updatedAt;
  final String createdBy;
  final String syncStatus;
  final int? serverVersion;
  const Household({
    required this.id,
    required this.village,
    this.hamlet,
    required this.headName,
    this.socialCategory,
    required this.isBpl,
    this.contactPhone,
    this.latitude,
    this.longitude,
    this.landmarkNotes,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.syncStatus,
    this.serverVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['village'] = Variable<String>(village);
    if (!nullToAbsent || hamlet != null) {
      map['hamlet'] = Variable<String>(hamlet);
    }
    map['head_name'] = Variable<String>(headName);
    if (!nullToAbsent || socialCategory != null) {
      map['social_category'] = Variable<String>(socialCategory);
    }
    map['is_bpl'] = Variable<bool>(isBpl);
    if (!nullToAbsent || contactPhone != null) {
      map['contact_phone'] = Variable<String>(contactPhone);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<String>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<String>(longitude);
    }
    if (!nullToAbsent || landmarkNotes != null) {
      map['landmark_notes'] = Variable<String>(landmarkNotes);
    }
    map['member_count'] = Variable<int>(memberCount);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['created_by'] = Variable<String>(createdBy);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    return map;
  }

  HouseholdsCompanion toCompanion(bool nullToAbsent) {
    return HouseholdsCompanion(
      id: Value(id),
      village: Value(village),
      hamlet: hamlet == null && nullToAbsent
          ? const Value.absent()
          : Value(hamlet),
      headName: Value(headName),
      socialCategory: socialCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(socialCategory),
      isBpl: Value(isBpl),
      contactPhone: contactPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(contactPhone),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      landmarkNotes: landmarkNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(landmarkNotes),
      memberCount: Value(memberCount),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      createdBy: Value(createdBy),
      syncStatus: Value(syncStatus),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
    );
  }

  factory Household.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Household(
      id: serializer.fromJson<String>(json['id']),
      village: serializer.fromJson<String>(json['village']),
      hamlet: serializer.fromJson<String?>(json['hamlet']),
      headName: serializer.fromJson<String>(json['headName']),
      socialCategory: serializer.fromJson<String?>(json['socialCategory']),
      isBpl: serializer.fromJson<bool>(json['isBpl']),
      contactPhone: serializer.fromJson<String?>(json['contactPhone']),
      latitude: serializer.fromJson<String?>(json['latitude']),
      longitude: serializer.fromJson<String?>(json['longitude']),
      landmarkNotes: serializer.fromJson<String?>(json['landmarkNotes']),
      memberCount: serializer.fromJson<int>(json['memberCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'village': serializer.toJson<String>(village),
      'hamlet': serializer.toJson<String?>(hamlet),
      'headName': serializer.toJson<String>(headName),
      'socialCategory': serializer.toJson<String?>(socialCategory),
      'isBpl': serializer.toJson<bool>(isBpl),
      'contactPhone': serializer.toJson<String?>(contactPhone),
      'latitude': serializer.toJson<String?>(latitude),
      'longitude': serializer.toJson<String?>(longitude),
      'landmarkNotes': serializer.toJson<String?>(landmarkNotes),
      'memberCount': serializer.toJson<int>(memberCount),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverVersion': serializer.toJson<int?>(serverVersion),
    };
  }

  Household copyWith({
    String? id,
    String? village,
    Value<String?> hamlet = const Value.absent(),
    String? headName,
    Value<String?> socialCategory = const Value.absent(),
    bool? isBpl,
    Value<String?> contactPhone = const Value.absent(),
    Value<String?> latitude = const Value.absent(),
    Value<String?> longitude = const Value.absent(),
    Value<String?> landmarkNotes = const Value.absent(),
    int? memberCount,
    int? createdAt,
    int? updatedAt,
    String? createdBy,
    String? syncStatus,
    Value<int?> serverVersion = const Value.absent(),
  }) => Household(
    id: id ?? this.id,
    village: village ?? this.village,
    hamlet: hamlet.present ? hamlet.value : this.hamlet,
    headName: headName ?? this.headName,
    socialCategory: socialCategory.present
        ? socialCategory.value
        : this.socialCategory,
    isBpl: isBpl ?? this.isBpl,
    contactPhone: contactPhone.present ? contactPhone.value : this.contactPhone,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    landmarkNotes: landmarkNotes.present
        ? landmarkNotes.value
        : this.landmarkNotes,
    memberCount: memberCount ?? this.memberCount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
    syncStatus: syncStatus ?? this.syncStatus,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
  );
  Household copyWithCompanion(HouseholdsCompanion data) {
    return Household(
      id: data.id.present ? data.id.value : this.id,
      village: data.village.present ? data.village.value : this.village,
      hamlet: data.hamlet.present ? data.hamlet.value : this.hamlet,
      headName: data.headName.present ? data.headName.value : this.headName,
      socialCategory: data.socialCategory.present
          ? data.socialCategory.value
          : this.socialCategory,
      isBpl: data.isBpl.present ? data.isBpl.value : this.isBpl,
      contactPhone: data.contactPhone.present
          ? data.contactPhone.value
          : this.contactPhone,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      landmarkNotes: data.landmarkNotes.present
          ? data.landmarkNotes.value
          : this.landmarkNotes,
      memberCount: data.memberCount.present
          ? data.memberCount.value
          : this.memberCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Household(')
          ..write('id: $id, ')
          ..write('village: $village, ')
          ..write('hamlet: $hamlet, ')
          ..write('headName: $headName, ')
          ..write('socialCategory: $socialCategory, ')
          ..write('isBpl: $isBpl, ')
          ..write('contactPhone: $contactPhone, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('landmarkNotes: $landmarkNotes, ')
          ..write('memberCount: $memberCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverVersion: $serverVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    village,
    hamlet,
    headName,
    socialCategory,
    isBpl,
    contactPhone,
    latitude,
    longitude,
    landmarkNotes,
    memberCount,
    createdAt,
    updatedAt,
    createdBy,
    syncStatus,
    serverVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Household &&
          other.id == this.id &&
          other.village == this.village &&
          other.hamlet == this.hamlet &&
          other.headName == this.headName &&
          other.socialCategory == this.socialCategory &&
          other.isBpl == this.isBpl &&
          other.contactPhone == this.contactPhone &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.landmarkNotes == this.landmarkNotes &&
          other.memberCount == this.memberCount &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.createdBy == this.createdBy &&
          other.syncStatus == this.syncStatus &&
          other.serverVersion == this.serverVersion);
}

class HouseholdsCompanion extends UpdateCompanion<Household> {
  final Value<String> id;
  final Value<String> village;
  final Value<String?> hamlet;
  final Value<String> headName;
  final Value<String?> socialCategory;
  final Value<bool> isBpl;
  final Value<String?> contactPhone;
  final Value<String?> latitude;
  final Value<String?> longitude;
  final Value<String?> landmarkNotes;
  final Value<int> memberCount;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> createdBy;
  final Value<String> syncStatus;
  final Value<int?> serverVersion;
  final Value<int> rowid;
  const HouseholdsCompanion({
    this.id = const Value.absent(),
    this.village = const Value.absent(),
    this.hamlet = const Value.absent(),
    this.headName = const Value.absent(),
    this.socialCategory = const Value.absent(),
    this.isBpl = const Value.absent(),
    this.contactPhone = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.landmarkNotes = const Value.absent(),
    this.memberCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HouseholdsCompanion.insert({
    required String id,
    required String village,
    this.hamlet = const Value.absent(),
    required String headName,
    this.socialCategory = const Value.absent(),
    this.isBpl = const Value.absent(),
    this.contactPhone = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.landmarkNotes = const Value.absent(),
    this.memberCount = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    required String createdBy,
    this.syncStatus = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       village = Value(village),
       headName = Value(headName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       createdBy = Value(createdBy);
  static Insertable<Household> custom({
    Expression<String>? id,
    Expression<String>? village,
    Expression<String>? hamlet,
    Expression<String>? headName,
    Expression<String>? socialCategory,
    Expression<bool>? isBpl,
    Expression<String>? contactPhone,
    Expression<String>? latitude,
    Expression<String>? longitude,
    Expression<String>? landmarkNotes,
    Expression<int>? memberCount,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? createdBy,
    Expression<String>? syncStatus,
    Expression<int>? serverVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (village != null) 'village': village,
      if (hamlet != null) 'hamlet': hamlet,
      if (headName != null) 'head_name': headName,
      if (socialCategory != null) 'social_category': socialCategory,
      if (isBpl != null) 'is_bpl': isBpl,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (landmarkNotes != null) 'landmark_notes': landmarkNotes,
      if (memberCount != null) 'member_count': memberCount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverVersion != null) 'server_version': serverVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HouseholdsCompanion copyWith({
    Value<String>? id,
    Value<String>? village,
    Value<String?>? hamlet,
    Value<String>? headName,
    Value<String?>? socialCategory,
    Value<bool>? isBpl,
    Value<String?>? contactPhone,
    Value<String?>? latitude,
    Value<String?>? longitude,
    Value<String?>? landmarkNotes,
    Value<int>? memberCount,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? createdBy,
    Value<String>? syncStatus,
    Value<int?>? serverVersion,
    Value<int>? rowid,
  }) {
    return HouseholdsCompanion(
      id: id ?? this.id,
      village: village ?? this.village,
      hamlet: hamlet ?? this.hamlet,
      headName: headName ?? this.headName,
      socialCategory: socialCategory ?? this.socialCategory,
      isBpl: isBpl ?? this.isBpl,
      contactPhone: contactPhone ?? this.contactPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      landmarkNotes: landmarkNotes ?? this.landmarkNotes,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      syncStatus: syncStatus ?? this.syncStatus,
      serverVersion: serverVersion ?? this.serverVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (village.present) {
      map['village'] = Variable<String>(village.value);
    }
    if (hamlet.present) {
      map['hamlet'] = Variable<String>(hamlet.value);
    }
    if (headName.present) {
      map['head_name'] = Variable<String>(headName.value);
    }
    if (socialCategory.present) {
      map['social_category'] = Variable<String>(socialCategory.value);
    }
    if (isBpl.present) {
      map['is_bpl'] = Variable<bool>(isBpl.value);
    }
    if (contactPhone.present) {
      map['contact_phone'] = Variable<String>(contactPhone.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<String>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<String>(longitude.value);
    }
    if (landmarkNotes.present) {
      map['landmark_notes'] = Variable<String>(landmarkNotes.value);
    }
    if (memberCount.present) {
      map['member_count'] = Variable<int>(memberCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HouseholdsCompanion(')
          ..write('id: $id, ')
          ..write('village: $village, ')
          ..write('hamlet: $hamlet, ')
          ..write('headName: $headName, ')
          ..write('socialCategory: $socialCategory, ')
          ..write('isBpl: $isBpl, ')
          ..write('contactPhone: $contactPhone, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('landmarkNotes: $landmarkNotes, ')
          ..write('memberCount: $memberCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, Member> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES households (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _namePhoneticMeta = const VerificationMeta(
    'namePhonetic',
  );
  @override
  late final GeneratedColumn<String> namePhonetic = GeneratedColumn<String>(
    'name_phonetic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dobApproxMeta = const VerificationMeta(
    'dobApprox',
  );
  @override
  late final GeneratedColumn<int> dobApprox = GeneratedColumn<int>(
    'dob_approx',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDobApproxMeta = const VerificationMeta(
    'isDobApprox',
  );
  @override
  late final GeneratedColumn<bool> isDobApprox = GeneratedColumn<bool>(
    'is_dob_approx',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_dob_approx" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sexMeta = const VerificationMeta('sex');
  @override
  late final GeneratedColumn<String> sex = GeneratedColumn<String>(
    'sex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relationshipToHeadMeta =
      const VerificationMeta('relationshipToHead');
  @override
  late final GeneratedColumn<String> relationshipToHead =
      GeneratedColumn<String>(
        'relationship_to_head',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _abhaIdMeta = const VerificationMeta('abhaId');
  @override
  late final GeneratedColumn<String> abhaId = GeneratedColumn<String>(
    'abha_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rchIdMeta = const VerificationMeta('rchId');
  @override
  late final GeneratedColumn<String> rchId = GeneratedColumn<String>(
    'rch_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _socialCategoryMeta = const VerificationMeta(
    'socialCategory',
  );
  @override
  late final GeneratedColumn<String> socialCategory = GeneratedColumn<String>(
    'social_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isBplMeta = const VerificationMeta('isBpl');
  @override
  late final GeneratedColumn<bool> isBpl = GeneratedColumn<bool>(
    'is_bpl',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_bpl" IN (0, 1))',
    ),
  );
  static const VerificationMeta _lifecycleStatusMeta = const VerificationMeta(
    'lifecycleStatus',
  );
  @override
  late final GeneratedColumn<String> lifecycleStatus = GeneratedColumn<String>(
    'lifecycle_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('active'),
  );
  static const VerificationMeta _consentStatusMeta = const VerificationMeta(
    'consentStatus',
  );
  @override
  late final GeneratedColumn<String> consentStatus = GeneratedColumn<String>(
    'consent_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _consentUpdatedAtMeta = const VerificationMeta(
    'consentUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> consentUpdatedAt = GeneratedColumn<int>(
    'consent_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    householdId,
    name,
    namePhonetic,
    dobApprox,
    isDobApprox,
    sex,
    relationshipToHead,
    abhaId,
    rchId,
    phone,
    socialCategory,
    isBpl,
    lifecycleStatus,
    consentStatus,
    consentUpdatedAt,
    createdAt,
    updatedAt,
    createdBy,
    syncStatus,
    serverVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<Member> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('name_phonetic')) {
      context.handle(
        _namePhoneticMeta,
        namePhonetic.isAcceptableOrUnknown(
          data['name_phonetic']!,
          _namePhoneticMeta,
        ),
      );
    }
    if (data.containsKey('dob_approx')) {
      context.handle(
        _dobApproxMeta,
        dobApprox.isAcceptableOrUnknown(data['dob_approx']!, _dobApproxMeta),
      );
    }
    if (data.containsKey('is_dob_approx')) {
      context.handle(
        _isDobApproxMeta,
        isDobApprox.isAcceptableOrUnknown(
          data['is_dob_approx']!,
          _isDobApproxMeta,
        ),
      );
    }
    if (data.containsKey('sex')) {
      context.handle(
        _sexMeta,
        sex.isAcceptableOrUnknown(data['sex']!, _sexMeta),
      );
    } else if (isInserting) {
      context.missing(_sexMeta);
    }
    if (data.containsKey('relationship_to_head')) {
      context.handle(
        _relationshipToHeadMeta,
        relationshipToHead.isAcceptableOrUnknown(
          data['relationship_to_head']!,
          _relationshipToHeadMeta,
        ),
      );
    }
    if (data.containsKey('abha_id')) {
      context.handle(
        _abhaIdMeta,
        abhaId.isAcceptableOrUnknown(data['abha_id']!, _abhaIdMeta),
      );
    }
    if (data.containsKey('rch_id')) {
      context.handle(
        _rchIdMeta,
        rchId.isAcceptableOrUnknown(data['rch_id']!, _rchIdMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('social_category')) {
      context.handle(
        _socialCategoryMeta,
        socialCategory.isAcceptableOrUnknown(
          data['social_category']!,
          _socialCategoryMeta,
        ),
      );
    }
    if (data.containsKey('is_bpl')) {
      context.handle(
        _isBplMeta,
        isBpl.isAcceptableOrUnknown(data['is_bpl']!, _isBplMeta),
      );
    }
    if (data.containsKey('lifecycle_status')) {
      context.handle(
        _lifecycleStatusMeta,
        lifecycleStatus.isAcceptableOrUnknown(
          data['lifecycle_status']!,
          _lifecycleStatusMeta,
        ),
      );
    }
    if (data.containsKey('consent_status')) {
      context.handle(
        _consentStatusMeta,
        consentStatus.isAcceptableOrUnknown(
          data['consent_status']!,
          _consentStatusMeta,
        ),
      );
    }
    if (data.containsKey('consent_updated_at')) {
      context.handle(
        _consentUpdatedAtMeta,
        consentUpdatedAt.isAcceptableOrUnknown(
          data['consent_updated_at']!,
          _consentUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Member map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Member(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      namePhonetic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name_phonetic'],
      ),
      dobApprox: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dob_approx'],
      ),
      isDobApprox: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_dob_approx'],
      )!,
      sex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sex'],
      )!,
      relationshipToHead: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relationship_to_head'],
      ),
      abhaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}abha_id'],
      ),
      rchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rch_id'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      socialCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}social_category'],
      ),
      isBpl: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_bpl'],
      ),
      lifecycleStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lifecycle_status'],
      )!,
      consentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}consent_status'],
      )!,
      consentUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consent_updated_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class Member extends DataClass implements Insertable<Member> {
  final String id;
  final String householdId;
  final String name;
  final String? namePhonetic;
  final int? dobApprox;
  final bool isDobApprox;
  final String sex;
  final String? relationshipToHead;
  final String? abhaId;
  final String? rchId;
  final String? phone;
  final String? socialCategory;
  final bool? isBpl;
  final String lifecycleStatus;
  final String consentStatus;
  final int? consentUpdatedAt;
  final int createdAt;
  final int updatedAt;
  final String createdBy;
  final String syncStatus;
  final int? serverVersion;
  const Member({
    required this.id,
    required this.householdId,
    required this.name,
    this.namePhonetic,
    this.dobApprox,
    required this.isDobApprox,
    required this.sex,
    this.relationshipToHead,
    this.abhaId,
    this.rchId,
    this.phone,
    this.socialCategory,
    this.isBpl,
    required this.lifecycleStatus,
    required this.consentStatus,
    this.consentUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.syncStatus,
    this.serverVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || namePhonetic != null) {
      map['name_phonetic'] = Variable<String>(namePhonetic);
    }
    if (!nullToAbsent || dobApprox != null) {
      map['dob_approx'] = Variable<int>(dobApprox);
    }
    map['is_dob_approx'] = Variable<bool>(isDobApprox);
    map['sex'] = Variable<String>(sex);
    if (!nullToAbsent || relationshipToHead != null) {
      map['relationship_to_head'] = Variable<String>(relationshipToHead);
    }
    if (!nullToAbsent || abhaId != null) {
      map['abha_id'] = Variable<String>(abhaId);
    }
    if (!nullToAbsent || rchId != null) {
      map['rch_id'] = Variable<String>(rchId);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || socialCategory != null) {
      map['social_category'] = Variable<String>(socialCategory);
    }
    if (!nullToAbsent || isBpl != null) {
      map['is_bpl'] = Variable<bool>(isBpl);
    }
    map['lifecycle_status'] = Variable<String>(lifecycleStatus);
    map['consent_status'] = Variable<String>(consentStatus);
    if (!nullToAbsent || consentUpdatedAt != null) {
      map['consent_updated_at'] = Variable<int>(consentUpdatedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['created_by'] = Variable<String>(createdBy);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      householdId: Value(householdId),
      name: Value(name),
      namePhonetic: namePhonetic == null && nullToAbsent
          ? const Value.absent()
          : Value(namePhonetic),
      dobApprox: dobApprox == null && nullToAbsent
          ? const Value.absent()
          : Value(dobApprox),
      isDobApprox: Value(isDobApprox),
      sex: Value(sex),
      relationshipToHead: relationshipToHead == null && nullToAbsent
          ? const Value.absent()
          : Value(relationshipToHead),
      abhaId: abhaId == null && nullToAbsent
          ? const Value.absent()
          : Value(abhaId),
      rchId: rchId == null && nullToAbsent
          ? const Value.absent()
          : Value(rchId),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      socialCategory: socialCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(socialCategory),
      isBpl: isBpl == null && nullToAbsent
          ? const Value.absent()
          : Value(isBpl),
      lifecycleStatus: Value(lifecycleStatus),
      consentStatus: Value(consentStatus),
      consentUpdatedAt: consentUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(consentUpdatedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      createdBy: Value(createdBy),
      syncStatus: Value(syncStatus),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
    );
  }

  factory Member.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Member(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      name: serializer.fromJson<String>(json['name']),
      namePhonetic: serializer.fromJson<String?>(json['namePhonetic']),
      dobApprox: serializer.fromJson<int?>(json['dobApprox']),
      isDobApprox: serializer.fromJson<bool>(json['isDobApprox']),
      sex: serializer.fromJson<String>(json['sex']),
      relationshipToHead: serializer.fromJson<String?>(
        json['relationshipToHead'],
      ),
      abhaId: serializer.fromJson<String?>(json['abhaId']),
      rchId: serializer.fromJson<String?>(json['rchId']),
      phone: serializer.fromJson<String?>(json['phone']),
      socialCategory: serializer.fromJson<String?>(json['socialCategory']),
      isBpl: serializer.fromJson<bool?>(json['isBpl']),
      lifecycleStatus: serializer.fromJson<String>(json['lifecycleStatus']),
      consentStatus: serializer.fromJson<String>(json['consentStatus']),
      consentUpdatedAt: serializer.fromJson<int?>(json['consentUpdatedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'name': serializer.toJson<String>(name),
      'namePhonetic': serializer.toJson<String?>(namePhonetic),
      'dobApprox': serializer.toJson<int?>(dobApprox),
      'isDobApprox': serializer.toJson<bool>(isDobApprox),
      'sex': serializer.toJson<String>(sex),
      'relationshipToHead': serializer.toJson<String?>(relationshipToHead),
      'abhaId': serializer.toJson<String?>(abhaId),
      'rchId': serializer.toJson<String?>(rchId),
      'phone': serializer.toJson<String?>(phone),
      'socialCategory': serializer.toJson<String?>(socialCategory),
      'isBpl': serializer.toJson<bool?>(isBpl),
      'lifecycleStatus': serializer.toJson<String>(lifecycleStatus),
      'consentStatus': serializer.toJson<String>(consentStatus),
      'consentUpdatedAt': serializer.toJson<int?>(consentUpdatedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'createdBy': serializer.toJson<String>(createdBy),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverVersion': serializer.toJson<int?>(serverVersion),
    };
  }

  Member copyWith({
    String? id,
    String? householdId,
    String? name,
    Value<String?> namePhonetic = const Value.absent(),
    Value<int?> dobApprox = const Value.absent(),
    bool? isDobApprox,
    String? sex,
    Value<String?> relationshipToHead = const Value.absent(),
    Value<String?> abhaId = const Value.absent(),
    Value<String?> rchId = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> socialCategory = const Value.absent(),
    Value<bool?> isBpl = const Value.absent(),
    String? lifecycleStatus,
    String? consentStatus,
    Value<int?> consentUpdatedAt = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    String? createdBy,
    String? syncStatus,
    Value<int?> serverVersion = const Value.absent(),
  }) => Member(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    name: name ?? this.name,
    namePhonetic: namePhonetic.present ? namePhonetic.value : this.namePhonetic,
    dobApprox: dobApprox.present ? dobApprox.value : this.dobApprox,
    isDobApprox: isDobApprox ?? this.isDobApprox,
    sex: sex ?? this.sex,
    relationshipToHead: relationshipToHead.present
        ? relationshipToHead.value
        : this.relationshipToHead,
    abhaId: abhaId.present ? abhaId.value : this.abhaId,
    rchId: rchId.present ? rchId.value : this.rchId,
    phone: phone.present ? phone.value : this.phone,
    socialCategory: socialCategory.present
        ? socialCategory.value
        : this.socialCategory,
    isBpl: isBpl.present ? isBpl.value : this.isBpl,
    lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
    consentStatus: consentStatus ?? this.consentStatus,
    consentUpdatedAt: consentUpdatedAt.present
        ? consentUpdatedAt.value
        : this.consentUpdatedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    createdBy: createdBy ?? this.createdBy,
    syncStatus: syncStatus ?? this.syncStatus,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
  );
  Member copyWithCompanion(MembersCompanion data) {
    return Member(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      name: data.name.present ? data.name.value : this.name,
      namePhonetic: data.namePhonetic.present
          ? data.namePhonetic.value
          : this.namePhonetic,
      dobApprox: data.dobApprox.present ? data.dobApprox.value : this.dobApprox,
      isDobApprox: data.isDobApprox.present
          ? data.isDobApprox.value
          : this.isDobApprox,
      sex: data.sex.present ? data.sex.value : this.sex,
      relationshipToHead: data.relationshipToHead.present
          ? data.relationshipToHead.value
          : this.relationshipToHead,
      abhaId: data.abhaId.present ? data.abhaId.value : this.abhaId,
      rchId: data.rchId.present ? data.rchId.value : this.rchId,
      phone: data.phone.present ? data.phone.value : this.phone,
      socialCategory: data.socialCategory.present
          ? data.socialCategory.value
          : this.socialCategory,
      isBpl: data.isBpl.present ? data.isBpl.value : this.isBpl,
      lifecycleStatus: data.lifecycleStatus.present
          ? data.lifecycleStatus.value
          : this.lifecycleStatus,
      consentStatus: data.consentStatus.present
          ? data.consentStatus.value
          : this.consentStatus,
      consentUpdatedAt: data.consentUpdatedAt.present
          ? data.consentUpdatedAt.value
          : this.consentUpdatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Member(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('namePhonetic: $namePhonetic, ')
          ..write('dobApprox: $dobApprox, ')
          ..write('isDobApprox: $isDobApprox, ')
          ..write('sex: $sex, ')
          ..write('relationshipToHead: $relationshipToHead, ')
          ..write('abhaId: $abhaId, ')
          ..write('rchId: $rchId, ')
          ..write('phone: $phone, ')
          ..write('socialCategory: $socialCategory, ')
          ..write('isBpl: $isBpl, ')
          ..write('lifecycleStatus: $lifecycleStatus, ')
          ..write('consentStatus: $consentStatus, ')
          ..write('consentUpdatedAt: $consentUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverVersion: $serverVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    householdId,
    name,
    namePhonetic,
    dobApprox,
    isDobApprox,
    sex,
    relationshipToHead,
    abhaId,
    rchId,
    phone,
    socialCategory,
    isBpl,
    lifecycleStatus,
    consentStatus,
    consentUpdatedAt,
    createdAt,
    updatedAt,
    createdBy,
    syncStatus,
    serverVersion,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Member &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.name == this.name &&
          other.namePhonetic == this.namePhonetic &&
          other.dobApprox == this.dobApprox &&
          other.isDobApprox == this.isDobApprox &&
          other.sex == this.sex &&
          other.relationshipToHead == this.relationshipToHead &&
          other.abhaId == this.abhaId &&
          other.rchId == this.rchId &&
          other.phone == this.phone &&
          other.socialCategory == this.socialCategory &&
          other.isBpl == this.isBpl &&
          other.lifecycleStatus == this.lifecycleStatus &&
          other.consentStatus == this.consentStatus &&
          other.consentUpdatedAt == this.consentUpdatedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.createdBy == this.createdBy &&
          other.syncStatus == this.syncStatus &&
          other.serverVersion == this.serverVersion);
}

class MembersCompanion extends UpdateCompanion<Member> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> name;
  final Value<String?> namePhonetic;
  final Value<int?> dobApprox;
  final Value<bool> isDobApprox;
  final Value<String> sex;
  final Value<String?> relationshipToHead;
  final Value<String?> abhaId;
  final Value<String?> rchId;
  final Value<String?> phone;
  final Value<String?> socialCategory;
  final Value<bool?> isBpl;
  final Value<String> lifecycleStatus;
  final Value<String> consentStatus;
  final Value<int?> consentUpdatedAt;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> createdBy;
  final Value<String> syncStatus;
  final Value<int?> serverVersion;
  final Value<int> rowid;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.name = const Value.absent(),
    this.namePhonetic = const Value.absent(),
    this.dobApprox = const Value.absent(),
    this.isDobApprox = const Value.absent(),
    this.sex = const Value.absent(),
    this.relationshipToHead = const Value.absent(),
    this.abhaId = const Value.absent(),
    this.rchId = const Value.absent(),
    this.phone = const Value.absent(),
    this.socialCategory = const Value.absent(),
    this.isBpl = const Value.absent(),
    this.lifecycleStatus = const Value.absent(),
    this.consentStatus = const Value.absent(),
    this.consentUpdatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    required String householdId,
    required String name,
    this.namePhonetic = const Value.absent(),
    this.dobApprox = const Value.absent(),
    this.isDobApprox = const Value.absent(),
    required String sex,
    this.relationshipToHead = const Value.absent(),
    this.abhaId = const Value.absent(),
    this.rchId = const Value.absent(),
    this.phone = const Value.absent(),
    this.socialCategory = const Value.absent(),
    this.isBpl = const Value.absent(),
    this.lifecycleStatus = const Value.absent(),
    this.consentStatus = const Value.absent(),
    this.consentUpdatedAt = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    required String createdBy,
    this.syncStatus = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       name = Value(name),
       sex = Value(sex),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       createdBy = Value(createdBy);
  static Insertable<Member> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? name,
    Expression<String>? namePhonetic,
    Expression<int>? dobApprox,
    Expression<bool>? isDobApprox,
    Expression<String>? sex,
    Expression<String>? relationshipToHead,
    Expression<String>? abhaId,
    Expression<String>? rchId,
    Expression<String>? phone,
    Expression<String>? socialCategory,
    Expression<bool>? isBpl,
    Expression<String>? lifecycleStatus,
    Expression<String>? consentStatus,
    Expression<int>? consentUpdatedAt,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? createdBy,
    Expression<String>? syncStatus,
    Expression<int>? serverVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (name != null) 'name': name,
      if (namePhonetic != null) 'name_phonetic': namePhonetic,
      if (dobApprox != null) 'dob_approx': dobApprox,
      if (isDobApprox != null) 'is_dob_approx': isDobApprox,
      if (sex != null) 'sex': sex,
      if (relationshipToHead != null)
        'relationship_to_head': relationshipToHead,
      if (abhaId != null) 'abha_id': abhaId,
      if (rchId != null) 'rch_id': rchId,
      if (phone != null) 'phone': phone,
      if (socialCategory != null) 'social_category': socialCategory,
      if (isBpl != null) 'is_bpl': isBpl,
      if (lifecycleStatus != null) 'lifecycle_status': lifecycleStatus,
      if (consentStatus != null) 'consent_status': consentStatus,
      if (consentUpdatedAt != null) 'consent_updated_at': consentUpdatedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (createdBy != null) 'created_by': createdBy,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverVersion != null) 'server_version': serverVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<String>? name,
    Value<String?>? namePhonetic,
    Value<int?>? dobApprox,
    Value<bool>? isDobApprox,
    Value<String>? sex,
    Value<String?>? relationshipToHead,
    Value<String?>? abhaId,
    Value<String?>? rchId,
    Value<String?>? phone,
    Value<String?>? socialCategory,
    Value<bool?>? isBpl,
    Value<String>? lifecycleStatus,
    Value<String>? consentStatus,
    Value<int?>? consentUpdatedAt,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? createdBy,
    Value<String>? syncStatus,
    Value<int?>? serverVersion,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      name: name ?? this.name,
      namePhonetic: namePhonetic ?? this.namePhonetic,
      dobApprox: dobApprox ?? this.dobApprox,
      isDobApprox: isDobApprox ?? this.isDobApprox,
      sex: sex ?? this.sex,
      relationshipToHead: relationshipToHead ?? this.relationshipToHead,
      abhaId: abhaId ?? this.abhaId,
      rchId: rchId ?? this.rchId,
      phone: phone ?? this.phone,
      socialCategory: socialCategory ?? this.socialCategory,
      isBpl: isBpl ?? this.isBpl,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      consentStatus: consentStatus ?? this.consentStatus,
      consentUpdatedAt: consentUpdatedAt ?? this.consentUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      syncStatus: syncStatus ?? this.syncStatus,
      serverVersion: serverVersion ?? this.serverVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (namePhonetic.present) {
      map['name_phonetic'] = Variable<String>(namePhonetic.value);
    }
    if (dobApprox.present) {
      map['dob_approx'] = Variable<int>(dobApprox.value);
    }
    if (isDobApprox.present) {
      map['is_dob_approx'] = Variable<bool>(isDobApprox.value);
    }
    if (sex.present) {
      map['sex'] = Variable<String>(sex.value);
    }
    if (relationshipToHead.present) {
      map['relationship_to_head'] = Variable<String>(relationshipToHead.value);
    }
    if (abhaId.present) {
      map['abha_id'] = Variable<String>(abhaId.value);
    }
    if (rchId.present) {
      map['rch_id'] = Variable<String>(rchId.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (socialCategory.present) {
      map['social_category'] = Variable<String>(socialCategory.value);
    }
    if (isBpl.present) {
      map['is_bpl'] = Variable<bool>(isBpl.value);
    }
    if (lifecycleStatus.present) {
      map['lifecycle_status'] = Variable<String>(lifecycleStatus.value);
    }
    if (consentStatus.present) {
      map['consent_status'] = Variable<String>(consentStatus.value);
    }
    if (consentUpdatedAt.present) {
      map['consent_updated_at'] = Variable<int>(consentUpdatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('name: $name, ')
          ..write('namePhonetic: $namePhonetic, ')
          ..write('dobApprox: $dobApprox, ')
          ..write('isDobApprox: $isDobApprox, ')
          ..write('sex: $sex, ')
          ..write('relationshipToHead: $relationshipToHead, ')
          ..write('abhaId: $abhaId, ')
          ..write('rchId: $rchId, ')
          ..write('phone: $phone, ')
          ..write('socialCategory: $socialCategory, ')
          ..write('isBpl: $isBpl, ')
          ..write('lifecycleStatus: $lifecycleStatus, ')
          ..write('consentStatus: $consentStatus, ')
          ..write('consentUpdatedAt: $consentUpdatedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('createdBy: $createdBy, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConsentRecordsTable extends ConsentRecords
    with TableInfo<$ConsentRecordsTable, ConsentRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsentRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _consentVersionMeta = const VerificationMeta(
    'consentVersion',
  );
  @override
  late final GeneratedColumn<String> consentVersion = GeneratedColumn<String>(
    'consent_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consentedAtMeta = const VerificationMeta(
    'consentedAt',
  );
  @override
  late final GeneratedColumn<int> consentedAt = GeneratedColumn<int>(
    'consented_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ashaIdMeta = const VerificationMeta('ashaId');
  @override
  late final GeneratedColumn<String> ashaId = GeneratedColumn<String>(
    'asha_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _witnessTypeMeta = const VerificationMeta(
    'witnessType',
  );
  @override
  late final GeneratedColumn<String> witnessType = GeneratedColumn<String>(
    'witness_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _signatureHashMeta = const VerificationMeta(
    'signatureHash',
  );
  @override
  late final GeneratedColumn<String> signatureHash = GeneratedColumn<String>(
    'signature_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voiceAckAudioHashMeta = const VerificationMeta(
    'voiceAckAudioHash',
  );
  @override
  late final GeneratedColumn<String> voiceAckAudioHash =
      GeneratedColumn<String>(
        'voice_ack_audio_hash',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isGuardianConsentMeta = const VerificationMeta(
    'isGuardianConsent',
  );
  @override
  late final GeneratedColumn<bool> isGuardianConsent = GeneratedColumn<bool>(
    'is_guardian_consent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_guardian_consent" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _guardianRelationshipMeta =
      const VerificationMeta('guardianRelationship');
  @override
  late final GeneratedColumn<String> guardianRelationship =
      GeneratedColumn<String>(
        'guardian_relationship',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _withdrawnAtMeta = const VerificationMeta(
    'withdrawnAt',
  );
  @override
  late final GeneratedColumn<int> withdrawnAt = GeneratedColumn<int>(
    'withdrawn_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _withdrawalReasonMeta = const VerificationMeta(
    'withdrawalReason',
  );
  @override
  late final GeneratedColumn<String> withdrawalReason = GeneratedColumn<String>(
    'withdrawal_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    consentVersion,
    consentedAt,
    ashaId,
    witnessType,
    signatureHash,
    voiceAckAudioHash,
    isGuardianConsent,
    guardianRelationship,
    withdrawnAt,
    withdrawalReason,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consent_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConsentRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('consent_version')) {
      context.handle(
        _consentVersionMeta,
        consentVersion.isAcceptableOrUnknown(
          data['consent_version']!,
          _consentVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consentVersionMeta);
    }
    if (data.containsKey('consented_at')) {
      context.handle(
        _consentedAtMeta,
        consentedAt.isAcceptableOrUnknown(
          data['consented_at']!,
          _consentedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consentedAtMeta);
    }
    if (data.containsKey('asha_id')) {
      context.handle(
        _ashaIdMeta,
        ashaId.isAcceptableOrUnknown(data['asha_id']!, _ashaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ashaIdMeta);
    }
    if (data.containsKey('witness_type')) {
      context.handle(
        _witnessTypeMeta,
        witnessType.isAcceptableOrUnknown(
          data['witness_type']!,
          _witnessTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_witnessTypeMeta);
    }
    if (data.containsKey('signature_hash')) {
      context.handle(
        _signatureHashMeta,
        signatureHash.isAcceptableOrUnknown(
          data['signature_hash']!,
          _signatureHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_signatureHashMeta);
    }
    if (data.containsKey('voice_ack_audio_hash')) {
      context.handle(
        _voiceAckAudioHashMeta,
        voiceAckAudioHash.isAcceptableOrUnknown(
          data['voice_ack_audio_hash']!,
          _voiceAckAudioHashMeta,
        ),
      );
    }
    if (data.containsKey('is_guardian_consent')) {
      context.handle(
        _isGuardianConsentMeta,
        isGuardianConsent.isAcceptableOrUnknown(
          data['is_guardian_consent']!,
          _isGuardianConsentMeta,
        ),
      );
    }
    if (data.containsKey('guardian_relationship')) {
      context.handle(
        _guardianRelationshipMeta,
        guardianRelationship.isAcceptableOrUnknown(
          data['guardian_relationship']!,
          _guardianRelationshipMeta,
        ),
      );
    }
    if (data.containsKey('withdrawn_at')) {
      context.handle(
        _withdrawnAtMeta,
        withdrawnAt.isAcceptableOrUnknown(
          data['withdrawn_at']!,
          _withdrawnAtMeta,
        ),
      );
    }
    if (data.containsKey('withdrawal_reason')) {
      context.handle(
        _withdrawalReasonMeta,
        withdrawalReason.isAcceptableOrUnknown(
          data['withdrawal_reason']!,
          _withdrawalReasonMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConsentRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConsentRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      consentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}consent_version'],
      )!,
      consentedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consented_at'],
      )!,
      ashaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asha_id'],
      )!,
      witnessType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}witness_type'],
      )!,
      signatureHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature_hash'],
      )!,
      voiceAckAudioHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_ack_audio_hash'],
      ),
      isGuardianConsent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_guardian_consent'],
      )!,
      guardianRelationship: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}guardian_relationship'],
      ),
      withdrawnAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}withdrawn_at'],
      ),
      withdrawalReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}withdrawal_reason'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $ConsentRecordsTable createAlias(String alias) {
    return $ConsentRecordsTable(attachedDatabase, alias);
  }
}

class ConsentRecord extends DataClass implements Insertable<ConsentRecord> {
  final String id;
  final String memberId;
  final String consentVersion;
  final int consentedAt;
  final String ashaId;
  final String witnessType;
  final String signatureHash;
  final String? voiceAckAudioHash;
  final bool isGuardianConsent;
  final String? guardianRelationship;
  final int? withdrawnAt;
  final String? withdrawalReason;
  final String syncStatus;
  const ConsentRecord({
    required this.id,
    required this.memberId,
    required this.consentVersion,
    required this.consentedAt,
    required this.ashaId,
    required this.witnessType,
    required this.signatureHash,
    this.voiceAckAudioHash,
    required this.isGuardianConsent,
    this.guardianRelationship,
    this.withdrawnAt,
    this.withdrawalReason,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['consent_version'] = Variable<String>(consentVersion);
    map['consented_at'] = Variable<int>(consentedAt);
    map['asha_id'] = Variable<String>(ashaId);
    map['witness_type'] = Variable<String>(witnessType);
    map['signature_hash'] = Variable<String>(signatureHash);
    if (!nullToAbsent || voiceAckAudioHash != null) {
      map['voice_ack_audio_hash'] = Variable<String>(voiceAckAudioHash);
    }
    map['is_guardian_consent'] = Variable<bool>(isGuardianConsent);
    if (!nullToAbsent || guardianRelationship != null) {
      map['guardian_relationship'] = Variable<String>(guardianRelationship);
    }
    if (!nullToAbsent || withdrawnAt != null) {
      map['withdrawn_at'] = Variable<int>(withdrawnAt);
    }
    if (!nullToAbsent || withdrawalReason != null) {
      map['withdrawal_reason'] = Variable<String>(withdrawalReason);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  ConsentRecordsCompanion toCompanion(bool nullToAbsent) {
    return ConsentRecordsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      consentVersion: Value(consentVersion),
      consentedAt: Value(consentedAt),
      ashaId: Value(ashaId),
      witnessType: Value(witnessType),
      signatureHash: Value(signatureHash),
      voiceAckAudioHash: voiceAckAudioHash == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceAckAudioHash),
      isGuardianConsent: Value(isGuardianConsent),
      guardianRelationship: guardianRelationship == null && nullToAbsent
          ? const Value.absent()
          : Value(guardianRelationship),
      withdrawnAt: withdrawnAt == null && nullToAbsent
          ? const Value.absent()
          : Value(withdrawnAt),
      withdrawalReason: withdrawalReason == null && nullToAbsent
          ? const Value.absent()
          : Value(withdrawalReason),
      syncStatus: Value(syncStatus),
    );
  }

  factory ConsentRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConsentRecord(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      consentVersion: serializer.fromJson<String>(json['consentVersion']),
      consentedAt: serializer.fromJson<int>(json['consentedAt']),
      ashaId: serializer.fromJson<String>(json['ashaId']),
      witnessType: serializer.fromJson<String>(json['witnessType']),
      signatureHash: serializer.fromJson<String>(json['signatureHash']),
      voiceAckAudioHash: serializer.fromJson<String?>(
        json['voiceAckAudioHash'],
      ),
      isGuardianConsent: serializer.fromJson<bool>(json['isGuardianConsent']),
      guardianRelationship: serializer.fromJson<String?>(
        json['guardianRelationship'],
      ),
      withdrawnAt: serializer.fromJson<int?>(json['withdrawnAt']),
      withdrawalReason: serializer.fromJson<String?>(json['withdrawalReason']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'consentVersion': serializer.toJson<String>(consentVersion),
      'consentedAt': serializer.toJson<int>(consentedAt),
      'ashaId': serializer.toJson<String>(ashaId),
      'witnessType': serializer.toJson<String>(witnessType),
      'signatureHash': serializer.toJson<String>(signatureHash),
      'voiceAckAudioHash': serializer.toJson<String?>(voiceAckAudioHash),
      'isGuardianConsent': serializer.toJson<bool>(isGuardianConsent),
      'guardianRelationship': serializer.toJson<String?>(guardianRelationship),
      'withdrawnAt': serializer.toJson<int?>(withdrawnAt),
      'withdrawalReason': serializer.toJson<String?>(withdrawalReason),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  ConsentRecord copyWith({
    String? id,
    String? memberId,
    String? consentVersion,
    int? consentedAt,
    String? ashaId,
    String? witnessType,
    String? signatureHash,
    Value<String?> voiceAckAudioHash = const Value.absent(),
    bool? isGuardianConsent,
    Value<String?> guardianRelationship = const Value.absent(),
    Value<int?> withdrawnAt = const Value.absent(),
    Value<String?> withdrawalReason = const Value.absent(),
    String? syncStatus,
  }) => ConsentRecord(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    consentVersion: consentVersion ?? this.consentVersion,
    consentedAt: consentedAt ?? this.consentedAt,
    ashaId: ashaId ?? this.ashaId,
    witnessType: witnessType ?? this.witnessType,
    signatureHash: signatureHash ?? this.signatureHash,
    voiceAckAudioHash: voiceAckAudioHash.present
        ? voiceAckAudioHash.value
        : this.voiceAckAudioHash,
    isGuardianConsent: isGuardianConsent ?? this.isGuardianConsent,
    guardianRelationship: guardianRelationship.present
        ? guardianRelationship.value
        : this.guardianRelationship,
    withdrawnAt: withdrawnAt.present ? withdrawnAt.value : this.withdrawnAt,
    withdrawalReason: withdrawalReason.present
        ? withdrawalReason.value
        : this.withdrawalReason,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  ConsentRecord copyWithCompanion(ConsentRecordsCompanion data) {
    return ConsentRecord(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      consentVersion: data.consentVersion.present
          ? data.consentVersion.value
          : this.consentVersion,
      consentedAt: data.consentedAt.present
          ? data.consentedAt.value
          : this.consentedAt,
      ashaId: data.ashaId.present ? data.ashaId.value : this.ashaId,
      witnessType: data.witnessType.present
          ? data.witnessType.value
          : this.witnessType,
      signatureHash: data.signatureHash.present
          ? data.signatureHash.value
          : this.signatureHash,
      voiceAckAudioHash: data.voiceAckAudioHash.present
          ? data.voiceAckAudioHash.value
          : this.voiceAckAudioHash,
      isGuardianConsent: data.isGuardianConsent.present
          ? data.isGuardianConsent.value
          : this.isGuardianConsent,
      guardianRelationship: data.guardianRelationship.present
          ? data.guardianRelationship.value
          : this.guardianRelationship,
      withdrawnAt: data.withdrawnAt.present
          ? data.withdrawnAt.value
          : this.withdrawnAt,
      withdrawalReason: data.withdrawalReason.present
          ? data.withdrawalReason.value
          : this.withdrawalReason,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConsentRecord(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('consentVersion: $consentVersion, ')
          ..write('consentedAt: $consentedAt, ')
          ..write('ashaId: $ashaId, ')
          ..write('witnessType: $witnessType, ')
          ..write('signatureHash: $signatureHash, ')
          ..write('voiceAckAudioHash: $voiceAckAudioHash, ')
          ..write('isGuardianConsent: $isGuardianConsent, ')
          ..write('guardianRelationship: $guardianRelationship, ')
          ..write('withdrawnAt: $withdrawnAt, ')
          ..write('withdrawalReason: $withdrawalReason, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    consentVersion,
    consentedAt,
    ashaId,
    witnessType,
    signatureHash,
    voiceAckAudioHash,
    isGuardianConsent,
    guardianRelationship,
    withdrawnAt,
    withdrawalReason,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConsentRecord &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.consentVersion == this.consentVersion &&
          other.consentedAt == this.consentedAt &&
          other.ashaId == this.ashaId &&
          other.witnessType == this.witnessType &&
          other.signatureHash == this.signatureHash &&
          other.voiceAckAudioHash == this.voiceAckAudioHash &&
          other.isGuardianConsent == this.isGuardianConsent &&
          other.guardianRelationship == this.guardianRelationship &&
          other.withdrawnAt == this.withdrawnAt &&
          other.withdrawalReason == this.withdrawalReason &&
          other.syncStatus == this.syncStatus);
}

class ConsentRecordsCompanion extends UpdateCompanion<ConsentRecord> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> consentVersion;
  final Value<int> consentedAt;
  final Value<String> ashaId;
  final Value<String> witnessType;
  final Value<String> signatureHash;
  final Value<String?> voiceAckAudioHash;
  final Value<bool> isGuardianConsent;
  final Value<String?> guardianRelationship;
  final Value<int?> withdrawnAt;
  final Value<String?> withdrawalReason;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const ConsentRecordsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.consentVersion = const Value.absent(),
    this.consentedAt = const Value.absent(),
    this.ashaId = const Value.absent(),
    this.witnessType = const Value.absent(),
    this.signatureHash = const Value.absent(),
    this.voiceAckAudioHash = const Value.absent(),
    this.isGuardianConsent = const Value.absent(),
    this.guardianRelationship = const Value.absent(),
    this.withdrawnAt = const Value.absent(),
    this.withdrawalReason = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConsentRecordsCompanion.insert({
    required String id,
    required String memberId,
    required String consentVersion,
    required int consentedAt,
    required String ashaId,
    required String witnessType,
    required String signatureHash,
    this.voiceAckAudioHash = const Value.absent(),
    this.isGuardianConsent = const Value.absent(),
    this.guardianRelationship = const Value.absent(),
    this.withdrawnAt = const Value.absent(),
    this.withdrawalReason = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       consentVersion = Value(consentVersion),
       consentedAt = Value(consentedAt),
       ashaId = Value(ashaId),
       witnessType = Value(witnessType),
       signatureHash = Value(signatureHash);
  static Insertable<ConsentRecord> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? consentVersion,
    Expression<int>? consentedAt,
    Expression<String>? ashaId,
    Expression<String>? witnessType,
    Expression<String>? signatureHash,
    Expression<String>? voiceAckAudioHash,
    Expression<bool>? isGuardianConsent,
    Expression<String>? guardianRelationship,
    Expression<int>? withdrawnAt,
    Expression<String>? withdrawalReason,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (consentVersion != null) 'consent_version': consentVersion,
      if (consentedAt != null) 'consented_at': consentedAt,
      if (ashaId != null) 'asha_id': ashaId,
      if (witnessType != null) 'witness_type': witnessType,
      if (signatureHash != null) 'signature_hash': signatureHash,
      if (voiceAckAudioHash != null) 'voice_ack_audio_hash': voiceAckAudioHash,
      if (isGuardianConsent != null) 'is_guardian_consent': isGuardianConsent,
      if (guardianRelationship != null)
        'guardian_relationship': guardianRelationship,
      if (withdrawnAt != null) 'withdrawn_at': withdrawnAt,
      if (withdrawalReason != null) 'withdrawal_reason': withdrawalReason,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConsentRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? consentVersion,
    Value<int>? consentedAt,
    Value<String>? ashaId,
    Value<String>? witnessType,
    Value<String>? signatureHash,
    Value<String?>? voiceAckAudioHash,
    Value<bool>? isGuardianConsent,
    Value<String?>? guardianRelationship,
    Value<int?>? withdrawnAt,
    Value<String?>? withdrawalReason,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return ConsentRecordsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      consentVersion: consentVersion ?? this.consentVersion,
      consentedAt: consentedAt ?? this.consentedAt,
      ashaId: ashaId ?? this.ashaId,
      witnessType: witnessType ?? this.witnessType,
      signatureHash: signatureHash ?? this.signatureHash,
      voiceAckAudioHash: voiceAckAudioHash ?? this.voiceAckAudioHash,
      isGuardianConsent: isGuardianConsent ?? this.isGuardianConsent,
      guardianRelationship: guardianRelationship ?? this.guardianRelationship,
      withdrawnAt: withdrawnAt ?? this.withdrawnAt,
      withdrawalReason: withdrawalReason ?? this.withdrawalReason,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (consentVersion.present) {
      map['consent_version'] = Variable<String>(consentVersion.value);
    }
    if (consentedAt.present) {
      map['consented_at'] = Variable<int>(consentedAt.value);
    }
    if (ashaId.present) {
      map['asha_id'] = Variable<String>(ashaId.value);
    }
    if (witnessType.present) {
      map['witness_type'] = Variable<String>(witnessType.value);
    }
    if (signatureHash.present) {
      map['signature_hash'] = Variable<String>(signatureHash.value);
    }
    if (voiceAckAudioHash.present) {
      map['voice_ack_audio_hash'] = Variable<String>(voiceAckAudioHash.value);
    }
    if (isGuardianConsent.present) {
      map['is_guardian_consent'] = Variable<bool>(isGuardianConsent.value);
    }
    if (guardianRelationship.present) {
      map['guardian_relationship'] = Variable<String>(
        guardianRelationship.value,
      );
    }
    if (withdrawnAt.present) {
      map['withdrawn_at'] = Variable<int>(withdrawnAt.value);
    }
    if (withdrawalReason.present) {
      map['withdrawal_reason'] = Variable<String>(withdrawalReason.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsentRecordsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('consentVersion: $consentVersion, ')
          ..write('consentedAt: $consentedAt, ')
          ..write('ashaId: $ashaId, ')
          ..write('witnessType: $witnessType, ')
          ..write('signatureHash: $signatureHash, ')
          ..write('voiceAckAudioHash: $voiceAckAudioHash, ')
          ..write('isGuardianConsent: $isGuardianConsent, ')
          ..write('guardianRelationship: $guardianRelationship, ')
          ..write('withdrawnAt: $withdrawnAt, ')
          ..write('withdrawalReason: $withdrawalReason, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClinicalEncountersTable extends ClinicalEncounters
    with TableInfo<$ClinicalEncountersTable, ClinicalEncounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClinicalEncountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _encounterTypeMeta = const VerificationMeta(
    'encounterType',
  );
  @override
  late final GeneratedColumn<String> encounterType = GeneratedColumn<String>(
    'encounter_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _programCodeMeta = const VerificationMeta(
    'programCode',
  );
  @override
  late final GeneratedColumn<String> programCode = GeneratedColumn<String>(
    'program_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encounterDateMeta = const VerificationMeta(
    'encounterDate',
  );
  @override
  late final GeneratedColumn<int> encounterDate = GeneratedColumn<int>(
    'encounter_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ashaIdMeta = const VerificationMeta('ashaId');
  @override
  late final GeneratedColumn<String> ashaId = GeneratedColumn<String>(
    'asha_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleVersionIdMeta = const VerificationMeta(
    'ruleVersionId',
  );
  @override
  late final GeneratedColumn<String> ruleVersionId = GeneratedColumn<String>(
    'rule_version_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _visitNotesMeta = const VerificationMeta(
    'visitNotes',
  );
  @override
  late final GeneratedColumn<String> visitNotes = GeneratedColumn<String>(
    'visit_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _serverVersionMeta = const VerificationMeta(
    'serverVersion',
  );
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
    'server_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    encounterType,
    programCode,
    encounterDate,
    ashaId,
    ruleVersionId,
    status,
    visitNotes,
    createdAt,
    updatedAt,
    syncStatus,
    serverVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clinical_encounters';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClinicalEncounter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('encounter_type')) {
      context.handle(
        _encounterTypeMeta,
        encounterType.isAcceptableOrUnknown(
          data['encounter_type']!,
          _encounterTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encounterTypeMeta);
    }
    if (data.containsKey('program_code')) {
      context.handle(
        _programCodeMeta,
        programCode.isAcceptableOrUnknown(
          data['program_code']!,
          _programCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_programCodeMeta);
    }
    if (data.containsKey('encounter_date')) {
      context.handle(
        _encounterDateMeta,
        encounterDate.isAcceptableOrUnknown(
          data['encounter_date']!,
          _encounterDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encounterDateMeta);
    }
    if (data.containsKey('asha_id')) {
      context.handle(
        _ashaIdMeta,
        ashaId.isAcceptableOrUnknown(data['asha_id']!, _ashaIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ashaIdMeta);
    }
    if (data.containsKey('rule_version_id')) {
      context.handle(
        _ruleVersionIdMeta,
        ruleVersionId.isAcceptableOrUnknown(
          data['rule_version_id']!,
          _ruleVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('visit_notes')) {
      context.handle(
        _visitNotesMeta,
        visitNotes.isAcceptableOrUnknown(data['visit_notes']!, _visitNotesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('server_version')) {
      context.handle(
        _serverVersionMeta,
        serverVersion.isAcceptableOrUnknown(
          data['server_version']!,
          _serverVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClinicalEncounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClinicalEncounter(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      encounterType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encounter_type'],
      )!,
      programCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_code'],
      )!,
      encounterDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}encounter_date'],
      )!,
      ashaId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asha_id'],
      )!,
      ruleVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_version_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      visitNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      serverVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_version'],
      ),
    );
  }

  @override
  $ClinicalEncountersTable createAlias(String alias) {
    return $ClinicalEncountersTable(attachedDatabase, alias);
  }
}

class ClinicalEncounter extends DataClass
    implements Insertable<ClinicalEncounter> {
  final String id;
  final String memberId;
  final String encounterType;
  final String programCode;
  final int encounterDate;
  final String ashaId;
  final String? ruleVersionId;
  final String status;
  final String? visitNotes;
  final int createdAt;
  final int updatedAt;
  final String syncStatus;
  final int? serverVersion;
  const ClinicalEncounter({
    required this.id,
    required this.memberId,
    required this.encounterType,
    required this.programCode,
    required this.encounterDate,
    required this.ashaId,
    this.ruleVersionId,
    required this.status,
    this.visitNotes,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.serverVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['encounter_type'] = Variable<String>(encounterType);
    map['program_code'] = Variable<String>(programCode);
    map['encounter_date'] = Variable<int>(encounterDate);
    map['asha_id'] = Variable<String>(ashaId);
    if (!nullToAbsent || ruleVersionId != null) {
      map['rule_version_id'] = Variable<String>(ruleVersionId);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || visitNotes != null) {
      map['visit_notes'] = Variable<String>(visitNotes);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    return map;
  }

  ClinicalEncountersCompanion toCompanion(bool nullToAbsent) {
    return ClinicalEncountersCompanion(
      id: Value(id),
      memberId: Value(memberId),
      encounterType: Value(encounterType),
      programCode: Value(programCode),
      encounterDate: Value(encounterDate),
      ashaId: Value(ashaId),
      ruleVersionId: ruleVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(ruleVersionId),
      status: Value(status),
      visitNotes: visitNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(visitNotes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
    );
  }

  factory ClinicalEncounter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClinicalEncounter(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      encounterType: serializer.fromJson<String>(json['encounterType']),
      programCode: serializer.fromJson<String>(json['programCode']),
      encounterDate: serializer.fromJson<int>(json['encounterDate']),
      ashaId: serializer.fromJson<String>(json['ashaId']),
      ruleVersionId: serializer.fromJson<String?>(json['ruleVersionId']),
      status: serializer.fromJson<String>(json['status']),
      visitNotes: serializer.fromJson<String?>(json['visitNotes']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'encounterType': serializer.toJson<String>(encounterType),
      'programCode': serializer.toJson<String>(programCode),
      'encounterDate': serializer.toJson<int>(encounterDate),
      'ashaId': serializer.toJson<String>(ashaId),
      'ruleVersionId': serializer.toJson<String?>(ruleVersionId),
      'status': serializer.toJson<String>(status),
      'visitNotes': serializer.toJson<String?>(visitNotes),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'serverVersion': serializer.toJson<int?>(serverVersion),
    };
  }

  ClinicalEncounter copyWith({
    String? id,
    String? memberId,
    String? encounterType,
    String? programCode,
    int? encounterDate,
    String? ashaId,
    Value<String?> ruleVersionId = const Value.absent(),
    String? status,
    Value<String?> visitNotes = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    String? syncStatus,
    Value<int?> serverVersion = const Value.absent(),
  }) => ClinicalEncounter(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    encounterType: encounterType ?? this.encounterType,
    programCode: programCode ?? this.programCode,
    encounterDate: encounterDate ?? this.encounterDate,
    ashaId: ashaId ?? this.ashaId,
    ruleVersionId: ruleVersionId.present
        ? ruleVersionId.value
        : this.ruleVersionId,
    status: status ?? this.status,
    visitNotes: visitNotes.present ? visitNotes.value : this.visitNotes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
    serverVersion: serverVersion.present
        ? serverVersion.value
        : this.serverVersion,
  );
  ClinicalEncounter copyWithCompanion(ClinicalEncountersCompanion data) {
    return ClinicalEncounter(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      encounterType: data.encounterType.present
          ? data.encounterType.value
          : this.encounterType,
      programCode: data.programCode.present
          ? data.programCode.value
          : this.programCode,
      encounterDate: data.encounterDate.present
          ? data.encounterDate.value
          : this.encounterDate,
      ashaId: data.ashaId.present ? data.ashaId.value : this.ashaId,
      ruleVersionId: data.ruleVersionId.present
          ? data.ruleVersionId.value
          : this.ruleVersionId,
      status: data.status.present ? data.status.value : this.status,
      visitNotes: data.visitNotes.present
          ? data.visitNotes.value
          : this.visitNotes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClinicalEncounter(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('encounterType: $encounterType, ')
          ..write('programCode: $programCode, ')
          ..write('encounterDate: $encounterDate, ')
          ..write('ashaId: $ashaId, ')
          ..write('ruleVersionId: $ruleVersionId, ')
          ..write('status: $status, ')
          ..write('visitNotes: $visitNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverVersion: $serverVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    encounterType,
    programCode,
    encounterDate,
    ashaId,
    ruleVersionId,
    status,
    visitNotes,
    createdAt,
    updatedAt,
    syncStatus,
    serverVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClinicalEncounter &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.encounterType == this.encounterType &&
          other.programCode == this.programCode &&
          other.encounterDate == this.encounterDate &&
          other.ashaId == this.ashaId &&
          other.ruleVersionId == this.ruleVersionId &&
          other.status == this.status &&
          other.visitNotes == this.visitNotes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus &&
          other.serverVersion == this.serverVersion);
}

class ClinicalEncountersCompanion extends UpdateCompanion<ClinicalEncounter> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> encounterType;
  final Value<String> programCode;
  final Value<int> encounterDate;
  final Value<String> ashaId;
  final Value<String?> ruleVersionId;
  final Value<String> status;
  final Value<String?> visitNotes;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> syncStatus;
  final Value<int?> serverVersion;
  final Value<int> rowid;
  const ClinicalEncountersCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.encounterType = const Value.absent(),
    this.programCode = const Value.absent(),
    this.encounterDate = const Value.absent(),
    this.ashaId = const Value.absent(),
    this.ruleVersionId = const Value.absent(),
    this.status = const Value.absent(),
    this.visitNotes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClinicalEncountersCompanion.insert({
    required String id,
    required String memberId,
    required String encounterType,
    required String programCode,
    required int encounterDate,
    required String ashaId,
    this.ruleVersionId = const Value.absent(),
    this.status = const Value.absent(),
    this.visitNotes = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.syncStatus = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       encounterType = Value(encounterType),
       programCode = Value(programCode),
       encounterDate = Value(encounterDate),
       ashaId = Value(ashaId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ClinicalEncounter> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? encounterType,
    Expression<String>? programCode,
    Expression<int>? encounterDate,
    Expression<String>? ashaId,
    Expression<String>? ruleVersionId,
    Expression<String>? status,
    Expression<String>? visitNotes,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? serverVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (encounterType != null) 'encounter_type': encounterType,
      if (programCode != null) 'program_code': programCode,
      if (encounterDate != null) 'encounter_date': encounterDate,
      if (ashaId != null) 'asha_id': ashaId,
      if (ruleVersionId != null) 'rule_version_id': ruleVersionId,
      if (status != null) 'status': status,
      if (visitNotes != null) 'visit_notes': visitNotes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (serverVersion != null) 'server_version': serverVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClinicalEncountersCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? encounterType,
    Value<String>? programCode,
    Value<int>? encounterDate,
    Value<String>? ashaId,
    Value<String?>? ruleVersionId,
    Value<String>? status,
    Value<String?>? visitNotes,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? syncStatus,
    Value<int?>? serverVersion,
    Value<int>? rowid,
  }) {
    return ClinicalEncountersCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      encounterType: encounterType ?? this.encounterType,
      programCode: programCode ?? this.programCode,
      encounterDate: encounterDate ?? this.encounterDate,
      ashaId: ashaId ?? this.ashaId,
      ruleVersionId: ruleVersionId ?? this.ruleVersionId,
      status: status ?? this.status,
      visitNotes: visitNotes ?? this.visitNotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      serverVersion: serverVersion ?? this.serverVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (encounterType.present) {
      map['encounter_type'] = Variable<String>(encounterType.value);
    }
    if (programCode.present) {
      map['program_code'] = Variable<String>(programCode.value);
    }
    if (encounterDate.present) {
      map['encounter_date'] = Variable<int>(encounterDate.value);
    }
    if (ashaId.present) {
      map['asha_id'] = Variable<String>(ashaId.value);
    }
    if (ruleVersionId.present) {
      map['rule_version_id'] = Variable<String>(ruleVersionId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (visitNotes.present) {
      map['visit_notes'] = Variable<String>(visitNotes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClinicalEncountersCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('encounterType: $encounterType, ')
          ..write('programCode: $programCode, ')
          ..write('encounterDate: $encounterDate, ')
          ..write('ashaId: $ashaId, ')
          ..write('ruleVersionId: $ruleVersionId, ')
          ..write('status: $status, ')
          ..write('visitNotes: $visitNotes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClinicalObservationsTable extends ClinicalObservations
    with TableInfo<$ClinicalObservationsTable, ClinicalObservation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClinicalObservationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encounterIdMeta = const VerificationMeta(
    'encounterId',
  );
  @override
  late final GeneratedColumn<String> encounterId = GeneratedColumn<String>(
    'encounter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clinical_encounters (id)',
    ),
  );
  static const VerificationMeta _observationCodeMeta = const VerificationMeta(
    'observationCode',
  );
  @override
  late final GeneratedColumn<String> observationCode = GeneratedColumn<String>(
    'observation_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueTextMeta = const VerificationMeta(
    'valueText',
  );
  @override
  late final GeneratedColumn<String> valueText = GeneratedColumn<String>(
    'value_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueNumericMeta = const VerificationMeta(
    'valueNumeric',
  );
  @override
  late final GeneratedColumn<double> valueNumeric = GeneratedColumn<double>(
    'value_numeric',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueUnitMeta = const VerificationMeta(
    'valueUnit',
  );
  @override
  late final GeneratedColumn<String> valueUnit = GeneratedColumn<String>(
    'value_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _valueEnumMeta = const VerificationMeta(
    'valueEnum',
  );
  @override
  late final GeneratedColumn<String> valueEnum = GeneratedColumn<String>(
    'value_enum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('MANUAL'),
  );
  static const VerificationMeta _observedAtMeta = const VerificationMeta(
    'observedAt',
  );
  @override
  late final GeneratedColumn<int> observedAt = GeneratedColumn<int>(
    'observed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    encounterId,
    observationCode,
    valueText,
    valueNumeric,
    valueUnit,
    valueEnum,
    source,
    observedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clinical_observations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClinicalObservation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('encounter_id')) {
      context.handle(
        _encounterIdMeta,
        encounterId.isAcceptableOrUnknown(
          data['encounter_id']!,
          _encounterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encounterIdMeta);
    }
    if (data.containsKey('observation_code')) {
      context.handle(
        _observationCodeMeta,
        observationCode.isAcceptableOrUnknown(
          data['observation_code']!,
          _observationCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_observationCodeMeta);
    }
    if (data.containsKey('value_text')) {
      context.handle(
        _valueTextMeta,
        valueText.isAcceptableOrUnknown(data['value_text']!, _valueTextMeta),
      );
    }
    if (data.containsKey('value_numeric')) {
      context.handle(
        _valueNumericMeta,
        valueNumeric.isAcceptableOrUnknown(
          data['value_numeric']!,
          _valueNumericMeta,
        ),
      );
    }
    if (data.containsKey('value_unit')) {
      context.handle(
        _valueUnitMeta,
        valueUnit.isAcceptableOrUnknown(data['value_unit']!, _valueUnitMeta),
      );
    }
    if (data.containsKey('value_enum')) {
      context.handle(
        _valueEnumMeta,
        valueEnum.isAcceptableOrUnknown(data['value_enum']!, _valueEnumMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('observed_at')) {
      context.handle(
        _observedAtMeta,
        observedAt.isAcceptableOrUnknown(data['observed_at']!, _observedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_observedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClinicalObservation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClinicalObservation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      encounterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encounter_id'],
      )!,
      observationCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observation_code'],
      )!,
      valueText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_text'],
      ),
      valueNumeric: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value_numeric'],
      ),
      valueUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_unit'],
      ),
      valueEnum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_enum'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      observedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}observed_at'],
      )!,
    );
  }

  @override
  $ClinicalObservationsTable createAlias(String alias) {
    return $ClinicalObservationsTable(attachedDatabase, alias);
  }
}

class ClinicalObservation extends DataClass
    implements Insertable<ClinicalObservation> {
  final String id;
  final String encounterId;
  final String observationCode;
  final String? valueText;
  final double? valueNumeric;
  final String? valueUnit;
  final String? valueEnum;
  final String source;
  final int observedAt;
  const ClinicalObservation({
    required this.id,
    required this.encounterId,
    required this.observationCode,
    this.valueText,
    this.valueNumeric,
    this.valueUnit,
    this.valueEnum,
    required this.source,
    required this.observedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['encounter_id'] = Variable<String>(encounterId);
    map['observation_code'] = Variable<String>(observationCode);
    if (!nullToAbsent || valueText != null) {
      map['value_text'] = Variable<String>(valueText);
    }
    if (!nullToAbsent || valueNumeric != null) {
      map['value_numeric'] = Variable<double>(valueNumeric);
    }
    if (!nullToAbsent || valueUnit != null) {
      map['value_unit'] = Variable<String>(valueUnit);
    }
    if (!nullToAbsent || valueEnum != null) {
      map['value_enum'] = Variable<String>(valueEnum);
    }
    map['source'] = Variable<String>(source);
    map['observed_at'] = Variable<int>(observedAt);
    return map;
  }

  ClinicalObservationsCompanion toCompanion(bool nullToAbsent) {
    return ClinicalObservationsCompanion(
      id: Value(id),
      encounterId: Value(encounterId),
      observationCode: Value(observationCode),
      valueText: valueText == null && nullToAbsent
          ? const Value.absent()
          : Value(valueText),
      valueNumeric: valueNumeric == null && nullToAbsent
          ? const Value.absent()
          : Value(valueNumeric),
      valueUnit: valueUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(valueUnit),
      valueEnum: valueEnum == null && nullToAbsent
          ? const Value.absent()
          : Value(valueEnum),
      source: Value(source),
      observedAt: Value(observedAt),
    );
  }

  factory ClinicalObservation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClinicalObservation(
      id: serializer.fromJson<String>(json['id']),
      encounterId: serializer.fromJson<String>(json['encounterId']),
      observationCode: serializer.fromJson<String>(json['observationCode']),
      valueText: serializer.fromJson<String?>(json['valueText']),
      valueNumeric: serializer.fromJson<double?>(json['valueNumeric']),
      valueUnit: serializer.fromJson<String?>(json['valueUnit']),
      valueEnum: serializer.fromJson<String?>(json['valueEnum']),
      source: serializer.fromJson<String>(json['source']),
      observedAt: serializer.fromJson<int>(json['observedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'encounterId': serializer.toJson<String>(encounterId),
      'observationCode': serializer.toJson<String>(observationCode),
      'valueText': serializer.toJson<String?>(valueText),
      'valueNumeric': serializer.toJson<double?>(valueNumeric),
      'valueUnit': serializer.toJson<String?>(valueUnit),
      'valueEnum': serializer.toJson<String?>(valueEnum),
      'source': serializer.toJson<String>(source),
      'observedAt': serializer.toJson<int>(observedAt),
    };
  }

  ClinicalObservation copyWith({
    String? id,
    String? encounterId,
    String? observationCode,
    Value<String?> valueText = const Value.absent(),
    Value<double?> valueNumeric = const Value.absent(),
    Value<String?> valueUnit = const Value.absent(),
    Value<String?> valueEnum = const Value.absent(),
    String? source,
    int? observedAt,
  }) => ClinicalObservation(
    id: id ?? this.id,
    encounterId: encounterId ?? this.encounterId,
    observationCode: observationCode ?? this.observationCode,
    valueText: valueText.present ? valueText.value : this.valueText,
    valueNumeric: valueNumeric.present ? valueNumeric.value : this.valueNumeric,
    valueUnit: valueUnit.present ? valueUnit.value : this.valueUnit,
    valueEnum: valueEnum.present ? valueEnum.value : this.valueEnum,
    source: source ?? this.source,
    observedAt: observedAt ?? this.observedAt,
  );
  ClinicalObservation copyWithCompanion(ClinicalObservationsCompanion data) {
    return ClinicalObservation(
      id: data.id.present ? data.id.value : this.id,
      encounterId: data.encounterId.present
          ? data.encounterId.value
          : this.encounterId,
      observationCode: data.observationCode.present
          ? data.observationCode.value
          : this.observationCode,
      valueText: data.valueText.present ? data.valueText.value : this.valueText,
      valueNumeric: data.valueNumeric.present
          ? data.valueNumeric.value
          : this.valueNumeric,
      valueUnit: data.valueUnit.present ? data.valueUnit.value : this.valueUnit,
      valueEnum: data.valueEnum.present ? data.valueEnum.value : this.valueEnum,
      source: data.source.present ? data.source.value : this.source,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClinicalObservation(')
          ..write('id: $id, ')
          ..write('encounterId: $encounterId, ')
          ..write('observationCode: $observationCode, ')
          ..write('valueText: $valueText, ')
          ..write('valueNumeric: $valueNumeric, ')
          ..write('valueUnit: $valueUnit, ')
          ..write('valueEnum: $valueEnum, ')
          ..write('source: $source, ')
          ..write('observedAt: $observedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    encounterId,
    observationCode,
    valueText,
    valueNumeric,
    valueUnit,
    valueEnum,
    source,
    observedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClinicalObservation &&
          other.id == this.id &&
          other.encounterId == this.encounterId &&
          other.observationCode == this.observationCode &&
          other.valueText == this.valueText &&
          other.valueNumeric == this.valueNumeric &&
          other.valueUnit == this.valueUnit &&
          other.valueEnum == this.valueEnum &&
          other.source == this.source &&
          other.observedAt == this.observedAt);
}

class ClinicalObservationsCompanion
    extends UpdateCompanion<ClinicalObservation> {
  final Value<String> id;
  final Value<String> encounterId;
  final Value<String> observationCode;
  final Value<String?> valueText;
  final Value<double?> valueNumeric;
  final Value<String?> valueUnit;
  final Value<String?> valueEnum;
  final Value<String> source;
  final Value<int> observedAt;
  final Value<int> rowid;
  const ClinicalObservationsCompanion({
    this.id = const Value.absent(),
    this.encounterId = const Value.absent(),
    this.observationCode = const Value.absent(),
    this.valueText = const Value.absent(),
    this.valueNumeric = const Value.absent(),
    this.valueUnit = const Value.absent(),
    this.valueEnum = const Value.absent(),
    this.source = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClinicalObservationsCompanion.insert({
    required String id,
    required String encounterId,
    required String observationCode,
    this.valueText = const Value.absent(),
    this.valueNumeric = const Value.absent(),
    this.valueUnit = const Value.absent(),
    this.valueEnum = const Value.absent(),
    this.source = const Value.absent(),
    required int observedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       encounterId = Value(encounterId),
       observationCode = Value(observationCode),
       observedAt = Value(observedAt);
  static Insertable<ClinicalObservation> custom({
    Expression<String>? id,
    Expression<String>? encounterId,
    Expression<String>? observationCode,
    Expression<String>? valueText,
    Expression<double>? valueNumeric,
    Expression<String>? valueUnit,
    Expression<String>? valueEnum,
    Expression<String>? source,
    Expression<int>? observedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (encounterId != null) 'encounter_id': encounterId,
      if (observationCode != null) 'observation_code': observationCode,
      if (valueText != null) 'value_text': valueText,
      if (valueNumeric != null) 'value_numeric': valueNumeric,
      if (valueUnit != null) 'value_unit': valueUnit,
      if (valueEnum != null) 'value_enum': valueEnum,
      if (source != null) 'source': source,
      if (observedAt != null) 'observed_at': observedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClinicalObservationsCompanion copyWith({
    Value<String>? id,
    Value<String>? encounterId,
    Value<String>? observationCode,
    Value<String?>? valueText,
    Value<double?>? valueNumeric,
    Value<String?>? valueUnit,
    Value<String?>? valueEnum,
    Value<String>? source,
    Value<int>? observedAt,
    Value<int>? rowid,
  }) {
    return ClinicalObservationsCompanion(
      id: id ?? this.id,
      encounterId: encounterId ?? this.encounterId,
      observationCode: observationCode ?? this.observationCode,
      valueText: valueText ?? this.valueText,
      valueNumeric: valueNumeric ?? this.valueNumeric,
      valueUnit: valueUnit ?? this.valueUnit,
      valueEnum: valueEnum ?? this.valueEnum,
      source: source ?? this.source,
      observedAt: observedAt ?? this.observedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (encounterId.present) {
      map['encounter_id'] = Variable<String>(encounterId.value);
    }
    if (observationCode.present) {
      map['observation_code'] = Variable<String>(observationCode.value);
    }
    if (valueText.present) {
      map['value_text'] = Variable<String>(valueText.value);
    }
    if (valueNumeric.present) {
      map['value_numeric'] = Variable<double>(valueNumeric.value);
    }
    if (valueUnit.present) {
      map['value_unit'] = Variable<String>(valueUnit.value);
    }
    if (valueEnum.present) {
      map['value_enum'] = Variable<String>(valueEnum.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (observedAt.present) {
      map['observed_at'] = Variable<int>(observedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClinicalObservationsCompanion(')
          ..write('id: $id, ')
          ..write('encounterId: $encounterId, ')
          ..write('observationCode: $observationCode, ')
          ..write('valueText: $valueText, ')
          ..write('valueNumeric: $valueNumeric, ')
          ..write('valueUnit: $valueUnit, ')
          ..write('valueEnum: $valueEnum, ')
          ..write('source: $source, ')
          ..write('observedAt: $observedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TriageResultsTable extends TriageResults
    with TableInfo<$TriageResultsTable, TriageResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TriageResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encounterIdMeta = const VerificationMeta(
    'encounterId',
  );
  @override
  late final GeneratedColumn<String> encounterId = GeneratedColumn<String>(
    'encounter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clinical_encounters (id)',
    ),
  );
  static const VerificationMeta _flagMeta = const VerificationMeta('flag');
  @override
  late final GeneratedColumn<String> flag = GeneratedColumn<String>(
    'flag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleVersionIdMeta = const VerificationMeta(
    'ruleVersionId',
  );
  @override
  late final GeneratedColumn<String> ruleVersionId = GeneratedColumn<String>(
    'rule_version_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _findingsJsonMeta = const VerificationMeta(
    'findingsJson',
  );
  @override
  late final GeneratedColumn<String> findingsJson = GeneratedColumn<String>(
    'findings_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _missingFieldsJsonMeta = const VerificationMeta(
    'missingFieldsJson',
  );
  @override
  late final GeneratedColumn<String> missingFieldsJson =
      GeneratedColumn<String>(
        'missing_fields_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _escalatedForMissingDataMeta =
      const VerificationMeta('escalatedForMissingData');
  @override
  late final GeneratedColumn<bool> escalatedForMissingData =
      GeneratedColumn<bool>(
        'escalated_for_missing_data',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("escalated_for_missing_data" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _mlContributionJsonMeta =
      const VerificationMeta('mlContributionJson');
  @override
  late final GeneratedColumn<String> mlContributionJson =
      GeneratedColumn<String>(
        'ml_contribution_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _overrideFlagMeta = const VerificationMeta(
    'overrideFlag',
  );
  @override
  late final GeneratedColumn<String> overrideFlag = GeneratedColumn<String>(
    'override_flag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overrideReasonMeta = const VerificationMeta(
    'overrideReason',
  );
  @override
  late final GeneratedColumn<String> overrideReason = GeneratedColumn<String>(
    'override_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overrideVoiceNotePathMeta =
      const VerificationMeta('overrideVoiceNotePath');
  @override
  late final GeneratedColumn<String> overrideVoiceNotePath =
      GeneratedColumn<String>(
        'override_voice_note_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _overridingUserIdMeta = const VerificationMeta(
    'overridingUserId',
  );
  @override
  late final GeneratedColumn<String> overridingUserId = GeneratedColumn<String>(
    'overriding_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _evaluatedAtMeta = const VerificationMeta(
    'evaluatedAt',
  );
  @override
  late final GeneratedColumn<int> evaluatedAt = GeneratedColumn<int>(
    'evaluated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overriddenAtMeta = const VerificationMeta(
    'overriddenAt',
  );
  @override
  late final GeneratedColumn<int> overriddenAt = GeneratedColumn<int>(
    'overridden_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    encounterId,
    flag,
    ruleVersionId,
    findingsJson,
    missingFieldsJson,
    escalatedForMissingData,
    mlContributionJson,
    overrideFlag,
    overrideReason,
    overrideVoiceNotePath,
    overridingUserId,
    evaluatedAt,
    overriddenAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'triage_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<TriageResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('encounter_id')) {
      context.handle(
        _encounterIdMeta,
        encounterId.isAcceptableOrUnknown(
          data['encounter_id']!,
          _encounterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encounterIdMeta);
    }
    if (data.containsKey('flag')) {
      context.handle(
        _flagMeta,
        flag.isAcceptableOrUnknown(data['flag']!, _flagMeta),
      );
    } else if (isInserting) {
      context.missing(_flagMeta);
    }
    if (data.containsKey('rule_version_id')) {
      context.handle(
        _ruleVersionIdMeta,
        ruleVersionId.isAcceptableOrUnknown(
          data['rule_version_id']!,
          _ruleVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ruleVersionIdMeta);
    }
    if (data.containsKey('findings_json')) {
      context.handle(
        _findingsJsonMeta,
        findingsJson.isAcceptableOrUnknown(
          data['findings_json']!,
          _findingsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_findingsJsonMeta);
    }
    if (data.containsKey('missing_fields_json')) {
      context.handle(
        _missingFieldsJsonMeta,
        missingFieldsJson.isAcceptableOrUnknown(
          data['missing_fields_json']!,
          _missingFieldsJsonMeta,
        ),
      );
    }
    if (data.containsKey('escalated_for_missing_data')) {
      context.handle(
        _escalatedForMissingDataMeta,
        escalatedForMissingData.isAcceptableOrUnknown(
          data['escalated_for_missing_data']!,
          _escalatedForMissingDataMeta,
        ),
      );
    }
    if (data.containsKey('ml_contribution_json')) {
      context.handle(
        _mlContributionJsonMeta,
        mlContributionJson.isAcceptableOrUnknown(
          data['ml_contribution_json']!,
          _mlContributionJsonMeta,
        ),
      );
    }
    if (data.containsKey('override_flag')) {
      context.handle(
        _overrideFlagMeta,
        overrideFlag.isAcceptableOrUnknown(
          data['override_flag']!,
          _overrideFlagMeta,
        ),
      );
    }
    if (data.containsKey('override_reason')) {
      context.handle(
        _overrideReasonMeta,
        overrideReason.isAcceptableOrUnknown(
          data['override_reason']!,
          _overrideReasonMeta,
        ),
      );
    }
    if (data.containsKey('override_voice_note_path')) {
      context.handle(
        _overrideVoiceNotePathMeta,
        overrideVoiceNotePath.isAcceptableOrUnknown(
          data['override_voice_note_path']!,
          _overrideVoiceNotePathMeta,
        ),
      );
    }
    if (data.containsKey('overriding_user_id')) {
      context.handle(
        _overridingUserIdMeta,
        overridingUserId.isAcceptableOrUnknown(
          data['overriding_user_id']!,
          _overridingUserIdMeta,
        ),
      );
    }
    if (data.containsKey('evaluated_at')) {
      context.handle(
        _evaluatedAtMeta,
        evaluatedAt.isAcceptableOrUnknown(
          data['evaluated_at']!,
          _evaluatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evaluatedAtMeta);
    }
    if (data.containsKey('overridden_at')) {
      context.handle(
        _overriddenAtMeta,
        overriddenAt.isAcceptableOrUnknown(
          data['overridden_at']!,
          _overriddenAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TriageResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TriageResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      encounterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encounter_id'],
      )!,
      flag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}flag'],
      )!,
      ruleVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_version_id'],
      )!,
      findingsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}findings_json'],
      )!,
      missingFieldsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}missing_fields_json'],
      )!,
      escalatedForMissingData: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}escalated_for_missing_data'],
      )!,
      mlContributionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ml_contribution_json'],
      ),
      overrideFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}override_flag'],
      ),
      overrideReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}override_reason'],
      ),
      overrideVoiceNotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}override_voice_note_path'],
      ),
      overridingUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}overriding_user_id'],
      ),
      evaluatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}evaluated_at'],
      )!,
      overriddenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overridden_at'],
      ),
    );
  }

  @override
  $TriageResultsTable createAlias(String alias) {
    return $TriageResultsTable(attachedDatabase, alias);
  }
}

class TriageResult extends DataClass implements Insertable<TriageResult> {
  final String id;
  final String encounterId;
  final String flag;
  final String ruleVersionId;
  final String findingsJson;
  final String missingFieldsJson;
  final bool escalatedForMissingData;
  final String? mlContributionJson;
  final String? overrideFlag;
  final String? overrideReason;
  final String? overrideVoiceNotePath;
  final String? overridingUserId;
  final int evaluatedAt;
  final int? overriddenAt;
  const TriageResult({
    required this.id,
    required this.encounterId,
    required this.flag,
    required this.ruleVersionId,
    required this.findingsJson,
    required this.missingFieldsJson,
    required this.escalatedForMissingData,
    this.mlContributionJson,
    this.overrideFlag,
    this.overrideReason,
    this.overrideVoiceNotePath,
    this.overridingUserId,
    required this.evaluatedAt,
    this.overriddenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['encounter_id'] = Variable<String>(encounterId);
    map['flag'] = Variable<String>(flag);
    map['rule_version_id'] = Variable<String>(ruleVersionId);
    map['findings_json'] = Variable<String>(findingsJson);
    map['missing_fields_json'] = Variable<String>(missingFieldsJson);
    map['escalated_for_missing_data'] = Variable<bool>(escalatedForMissingData);
    if (!nullToAbsent || mlContributionJson != null) {
      map['ml_contribution_json'] = Variable<String>(mlContributionJson);
    }
    if (!nullToAbsent || overrideFlag != null) {
      map['override_flag'] = Variable<String>(overrideFlag);
    }
    if (!nullToAbsent || overrideReason != null) {
      map['override_reason'] = Variable<String>(overrideReason);
    }
    if (!nullToAbsent || overrideVoiceNotePath != null) {
      map['override_voice_note_path'] = Variable<String>(overrideVoiceNotePath);
    }
    if (!nullToAbsent || overridingUserId != null) {
      map['overriding_user_id'] = Variable<String>(overridingUserId);
    }
    map['evaluated_at'] = Variable<int>(evaluatedAt);
    if (!nullToAbsent || overriddenAt != null) {
      map['overridden_at'] = Variable<int>(overriddenAt);
    }
    return map;
  }

  TriageResultsCompanion toCompanion(bool nullToAbsent) {
    return TriageResultsCompanion(
      id: Value(id),
      encounterId: Value(encounterId),
      flag: Value(flag),
      ruleVersionId: Value(ruleVersionId),
      findingsJson: Value(findingsJson),
      missingFieldsJson: Value(missingFieldsJson),
      escalatedForMissingData: Value(escalatedForMissingData),
      mlContributionJson: mlContributionJson == null && nullToAbsent
          ? const Value.absent()
          : Value(mlContributionJson),
      overrideFlag: overrideFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideFlag),
      overrideReason: overrideReason == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideReason),
      overrideVoiceNotePath: overrideVoiceNotePath == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideVoiceNotePath),
      overridingUserId: overridingUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(overridingUserId),
      evaluatedAt: Value(evaluatedAt),
      overriddenAt: overriddenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(overriddenAt),
    );
  }

  factory TriageResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TriageResult(
      id: serializer.fromJson<String>(json['id']),
      encounterId: serializer.fromJson<String>(json['encounterId']),
      flag: serializer.fromJson<String>(json['flag']),
      ruleVersionId: serializer.fromJson<String>(json['ruleVersionId']),
      findingsJson: serializer.fromJson<String>(json['findingsJson']),
      missingFieldsJson: serializer.fromJson<String>(json['missingFieldsJson']),
      escalatedForMissingData: serializer.fromJson<bool>(
        json['escalatedForMissingData'],
      ),
      mlContributionJson: serializer.fromJson<String?>(
        json['mlContributionJson'],
      ),
      overrideFlag: serializer.fromJson<String?>(json['overrideFlag']),
      overrideReason: serializer.fromJson<String?>(json['overrideReason']),
      overrideVoiceNotePath: serializer.fromJson<String?>(
        json['overrideVoiceNotePath'],
      ),
      overridingUserId: serializer.fromJson<String?>(json['overridingUserId']),
      evaluatedAt: serializer.fromJson<int>(json['evaluatedAt']),
      overriddenAt: serializer.fromJson<int?>(json['overriddenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'encounterId': serializer.toJson<String>(encounterId),
      'flag': serializer.toJson<String>(flag),
      'ruleVersionId': serializer.toJson<String>(ruleVersionId),
      'findingsJson': serializer.toJson<String>(findingsJson),
      'missingFieldsJson': serializer.toJson<String>(missingFieldsJson),
      'escalatedForMissingData': serializer.toJson<bool>(
        escalatedForMissingData,
      ),
      'mlContributionJson': serializer.toJson<String?>(mlContributionJson),
      'overrideFlag': serializer.toJson<String?>(overrideFlag),
      'overrideReason': serializer.toJson<String?>(overrideReason),
      'overrideVoiceNotePath': serializer.toJson<String?>(
        overrideVoiceNotePath,
      ),
      'overridingUserId': serializer.toJson<String?>(overridingUserId),
      'evaluatedAt': serializer.toJson<int>(evaluatedAt),
      'overriddenAt': serializer.toJson<int?>(overriddenAt),
    };
  }

  TriageResult copyWith({
    String? id,
    String? encounterId,
    String? flag,
    String? ruleVersionId,
    String? findingsJson,
    String? missingFieldsJson,
    bool? escalatedForMissingData,
    Value<String?> mlContributionJson = const Value.absent(),
    Value<String?> overrideFlag = const Value.absent(),
    Value<String?> overrideReason = const Value.absent(),
    Value<String?> overrideVoiceNotePath = const Value.absent(),
    Value<String?> overridingUserId = const Value.absent(),
    int? evaluatedAt,
    Value<int?> overriddenAt = const Value.absent(),
  }) => TriageResult(
    id: id ?? this.id,
    encounterId: encounterId ?? this.encounterId,
    flag: flag ?? this.flag,
    ruleVersionId: ruleVersionId ?? this.ruleVersionId,
    findingsJson: findingsJson ?? this.findingsJson,
    missingFieldsJson: missingFieldsJson ?? this.missingFieldsJson,
    escalatedForMissingData:
        escalatedForMissingData ?? this.escalatedForMissingData,
    mlContributionJson: mlContributionJson.present
        ? mlContributionJson.value
        : this.mlContributionJson,
    overrideFlag: overrideFlag.present ? overrideFlag.value : this.overrideFlag,
    overrideReason: overrideReason.present
        ? overrideReason.value
        : this.overrideReason,
    overrideVoiceNotePath: overrideVoiceNotePath.present
        ? overrideVoiceNotePath.value
        : this.overrideVoiceNotePath,
    overridingUserId: overridingUserId.present
        ? overridingUserId.value
        : this.overridingUserId,
    evaluatedAt: evaluatedAt ?? this.evaluatedAt,
    overriddenAt: overriddenAt.present ? overriddenAt.value : this.overriddenAt,
  );
  TriageResult copyWithCompanion(TriageResultsCompanion data) {
    return TriageResult(
      id: data.id.present ? data.id.value : this.id,
      encounterId: data.encounterId.present
          ? data.encounterId.value
          : this.encounterId,
      flag: data.flag.present ? data.flag.value : this.flag,
      ruleVersionId: data.ruleVersionId.present
          ? data.ruleVersionId.value
          : this.ruleVersionId,
      findingsJson: data.findingsJson.present
          ? data.findingsJson.value
          : this.findingsJson,
      missingFieldsJson: data.missingFieldsJson.present
          ? data.missingFieldsJson.value
          : this.missingFieldsJson,
      escalatedForMissingData: data.escalatedForMissingData.present
          ? data.escalatedForMissingData.value
          : this.escalatedForMissingData,
      mlContributionJson: data.mlContributionJson.present
          ? data.mlContributionJson.value
          : this.mlContributionJson,
      overrideFlag: data.overrideFlag.present
          ? data.overrideFlag.value
          : this.overrideFlag,
      overrideReason: data.overrideReason.present
          ? data.overrideReason.value
          : this.overrideReason,
      overrideVoiceNotePath: data.overrideVoiceNotePath.present
          ? data.overrideVoiceNotePath.value
          : this.overrideVoiceNotePath,
      overridingUserId: data.overridingUserId.present
          ? data.overridingUserId.value
          : this.overridingUserId,
      evaluatedAt: data.evaluatedAt.present
          ? data.evaluatedAt.value
          : this.evaluatedAt,
      overriddenAt: data.overriddenAt.present
          ? data.overriddenAt.value
          : this.overriddenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TriageResult(')
          ..write('id: $id, ')
          ..write('encounterId: $encounterId, ')
          ..write('flag: $flag, ')
          ..write('ruleVersionId: $ruleVersionId, ')
          ..write('findingsJson: $findingsJson, ')
          ..write('missingFieldsJson: $missingFieldsJson, ')
          ..write('escalatedForMissingData: $escalatedForMissingData, ')
          ..write('mlContributionJson: $mlContributionJson, ')
          ..write('overrideFlag: $overrideFlag, ')
          ..write('overrideReason: $overrideReason, ')
          ..write('overrideVoiceNotePath: $overrideVoiceNotePath, ')
          ..write('overridingUserId: $overridingUserId, ')
          ..write('evaluatedAt: $evaluatedAt, ')
          ..write('overriddenAt: $overriddenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    encounterId,
    flag,
    ruleVersionId,
    findingsJson,
    missingFieldsJson,
    escalatedForMissingData,
    mlContributionJson,
    overrideFlag,
    overrideReason,
    overrideVoiceNotePath,
    overridingUserId,
    evaluatedAt,
    overriddenAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TriageResult &&
          other.id == this.id &&
          other.encounterId == this.encounterId &&
          other.flag == this.flag &&
          other.ruleVersionId == this.ruleVersionId &&
          other.findingsJson == this.findingsJson &&
          other.missingFieldsJson == this.missingFieldsJson &&
          other.escalatedForMissingData == this.escalatedForMissingData &&
          other.mlContributionJson == this.mlContributionJson &&
          other.overrideFlag == this.overrideFlag &&
          other.overrideReason == this.overrideReason &&
          other.overrideVoiceNotePath == this.overrideVoiceNotePath &&
          other.overridingUserId == this.overridingUserId &&
          other.evaluatedAt == this.evaluatedAt &&
          other.overriddenAt == this.overriddenAt);
}

class TriageResultsCompanion extends UpdateCompanion<TriageResult> {
  final Value<String> id;
  final Value<String> encounterId;
  final Value<String> flag;
  final Value<String> ruleVersionId;
  final Value<String> findingsJson;
  final Value<String> missingFieldsJson;
  final Value<bool> escalatedForMissingData;
  final Value<String?> mlContributionJson;
  final Value<String?> overrideFlag;
  final Value<String?> overrideReason;
  final Value<String?> overrideVoiceNotePath;
  final Value<String?> overridingUserId;
  final Value<int> evaluatedAt;
  final Value<int?> overriddenAt;
  final Value<int> rowid;
  const TriageResultsCompanion({
    this.id = const Value.absent(),
    this.encounterId = const Value.absent(),
    this.flag = const Value.absent(),
    this.ruleVersionId = const Value.absent(),
    this.findingsJson = const Value.absent(),
    this.missingFieldsJson = const Value.absent(),
    this.escalatedForMissingData = const Value.absent(),
    this.mlContributionJson = const Value.absent(),
    this.overrideFlag = const Value.absent(),
    this.overrideReason = const Value.absent(),
    this.overrideVoiceNotePath = const Value.absent(),
    this.overridingUserId = const Value.absent(),
    this.evaluatedAt = const Value.absent(),
    this.overriddenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TriageResultsCompanion.insert({
    required String id,
    required String encounterId,
    required String flag,
    required String ruleVersionId,
    required String findingsJson,
    this.missingFieldsJson = const Value.absent(),
    this.escalatedForMissingData = const Value.absent(),
    this.mlContributionJson = const Value.absent(),
    this.overrideFlag = const Value.absent(),
    this.overrideReason = const Value.absent(),
    this.overrideVoiceNotePath = const Value.absent(),
    this.overridingUserId = const Value.absent(),
    required int evaluatedAt,
    this.overriddenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       encounterId = Value(encounterId),
       flag = Value(flag),
       ruleVersionId = Value(ruleVersionId),
       findingsJson = Value(findingsJson),
       evaluatedAt = Value(evaluatedAt);
  static Insertable<TriageResult> custom({
    Expression<String>? id,
    Expression<String>? encounterId,
    Expression<String>? flag,
    Expression<String>? ruleVersionId,
    Expression<String>? findingsJson,
    Expression<String>? missingFieldsJson,
    Expression<bool>? escalatedForMissingData,
    Expression<String>? mlContributionJson,
    Expression<String>? overrideFlag,
    Expression<String>? overrideReason,
    Expression<String>? overrideVoiceNotePath,
    Expression<String>? overridingUserId,
    Expression<int>? evaluatedAt,
    Expression<int>? overriddenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (encounterId != null) 'encounter_id': encounterId,
      if (flag != null) 'flag': flag,
      if (ruleVersionId != null) 'rule_version_id': ruleVersionId,
      if (findingsJson != null) 'findings_json': findingsJson,
      if (missingFieldsJson != null) 'missing_fields_json': missingFieldsJson,
      if (escalatedForMissingData != null)
        'escalated_for_missing_data': escalatedForMissingData,
      if (mlContributionJson != null)
        'ml_contribution_json': mlContributionJson,
      if (overrideFlag != null) 'override_flag': overrideFlag,
      if (overrideReason != null) 'override_reason': overrideReason,
      if (overrideVoiceNotePath != null)
        'override_voice_note_path': overrideVoiceNotePath,
      if (overridingUserId != null) 'overriding_user_id': overridingUserId,
      if (evaluatedAt != null) 'evaluated_at': evaluatedAt,
      if (overriddenAt != null) 'overridden_at': overriddenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TriageResultsCompanion copyWith({
    Value<String>? id,
    Value<String>? encounterId,
    Value<String>? flag,
    Value<String>? ruleVersionId,
    Value<String>? findingsJson,
    Value<String>? missingFieldsJson,
    Value<bool>? escalatedForMissingData,
    Value<String?>? mlContributionJson,
    Value<String?>? overrideFlag,
    Value<String?>? overrideReason,
    Value<String?>? overrideVoiceNotePath,
    Value<String?>? overridingUserId,
    Value<int>? evaluatedAt,
    Value<int?>? overriddenAt,
    Value<int>? rowid,
  }) {
    return TriageResultsCompanion(
      id: id ?? this.id,
      encounterId: encounterId ?? this.encounterId,
      flag: flag ?? this.flag,
      ruleVersionId: ruleVersionId ?? this.ruleVersionId,
      findingsJson: findingsJson ?? this.findingsJson,
      missingFieldsJson: missingFieldsJson ?? this.missingFieldsJson,
      escalatedForMissingData:
          escalatedForMissingData ?? this.escalatedForMissingData,
      mlContributionJson: mlContributionJson ?? this.mlContributionJson,
      overrideFlag: overrideFlag ?? this.overrideFlag,
      overrideReason: overrideReason ?? this.overrideReason,
      overrideVoiceNotePath:
          overrideVoiceNotePath ?? this.overrideVoiceNotePath,
      overridingUserId: overridingUserId ?? this.overridingUserId,
      evaluatedAt: evaluatedAt ?? this.evaluatedAt,
      overriddenAt: overriddenAt ?? this.overriddenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (encounterId.present) {
      map['encounter_id'] = Variable<String>(encounterId.value);
    }
    if (flag.present) {
      map['flag'] = Variable<String>(flag.value);
    }
    if (ruleVersionId.present) {
      map['rule_version_id'] = Variable<String>(ruleVersionId.value);
    }
    if (findingsJson.present) {
      map['findings_json'] = Variable<String>(findingsJson.value);
    }
    if (missingFieldsJson.present) {
      map['missing_fields_json'] = Variable<String>(missingFieldsJson.value);
    }
    if (escalatedForMissingData.present) {
      map['escalated_for_missing_data'] = Variable<bool>(
        escalatedForMissingData.value,
      );
    }
    if (mlContributionJson.present) {
      map['ml_contribution_json'] = Variable<String>(mlContributionJson.value);
    }
    if (overrideFlag.present) {
      map['override_flag'] = Variable<String>(overrideFlag.value);
    }
    if (overrideReason.present) {
      map['override_reason'] = Variable<String>(overrideReason.value);
    }
    if (overrideVoiceNotePath.present) {
      map['override_voice_note_path'] = Variable<String>(
        overrideVoiceNotePath.value,
      );
    }
    if (overridingUserId.present) {
      map['overriding_user_id'] = Variable<String>(overridingUserId.value);
    }
    if (evaluatedAt.present) {
      map['evaluated_at'] = Variable<int>(evaluatedAt.value);
    }
    if (overriddenAt.present) {
      map['overridden_at'] = Variable<int>(overriddenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TriageResultsCompanion(')
          ..write('id: $id, ')
          ..write('encounterId: $encounterId, ')
          ..write('flag: $flag, ')
          ..write('ruleVersionId: $ruleVersionId, ')
          ..write('findingsJson: $findingsJson, ')
          ..write('missingFieldsJson: $missingFieldsJson, ')
          ..write('escalatedForMissingData: $escalatedForMissingData, ')
          ..write('mlContributionJson: $mlContributionJson, ')
          ..write('overrideFlag: $overrideFlag, ')
          ..write('overrideReason: $overrideReason, ')
          ..write('overrideVoiceNotePath: $overrideVoiceNotePath, ')
          ..write('overridingUserId: $overridingUserId, ')
          ..write('evaluatedAt: $evaluatedAt, ')
          ..write('overriddenAt: $overriddenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReferralRecordsTable extends ReferralRecords
    with TableInfo<$ReferralRecordsTable, ReferralRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReferralRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encounterIdMeta = const VerificationMeta(
    'encounterId',
  );
  @override
  late final GeneratedColumn<String> encounterId = GeneratedColumn<String>(
    'encounter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clinical_encounters (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _triageFlagMeta = const VerificationMeta(
    'triageFlag',
  );
  @override
  late final GeneratedColumn<String> triageFlag = GeneratedColumn<String>(
    'triage_flag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _destinationFacilityIdMeta =
      const VerificationMeta('destinationFacilityId');
  @override
  late final GeneratedColumn<String> destinationFacilityId =
      GeneratedColumn<String>(
        'destination_facility_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _destinationLevelMeta = const VerificationMeta(
    'destinationLevel',
  );
  @override
  late final GeneratedColumn<String> destinationLevel = GeneratedColumn<String>(
    'destination_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transportArrangedMeta = const VerificationMeta(
    'transportArranged',
  );
  @override
  late final GeneratedColumn<String> transportArranged =
      GeneratedColumn<String>(
        'transport_arranged',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('created'),
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outcomeRecordedByMeta = const VerificationMeta(
    'outcomeRecordedBy',
  );
  @override
  late final GeneratedColumn<String> outcomeRecordedBy =
      GeneratedColumn<String>(
        'outcome_recorded_by',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _outcomeRecordedAtMeta = const VerificationMeta(
    'outcomeRecordedAt',
  );
  @override
  late final GeneratedColumn<int> outcomeRecordedAt = GeneratedColumn<int>(
    'outcome_recorded_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referralNoteTextMeta = const VerificationMeta(
    'referralNoteText',
  );
  @override
  late final GeneratedColumn<String> referralNoteText = GeneratedColumn<String>(
    'referral_note_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referralPdfPathMeta = const VerificationMeta(
    'referralPdfPath',
  );
  @override
  late final GeneratedColumn<String> referralPdfPath = GeneratedColumn<String>(
    'referral_pdf_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referralQrDataMeta = const VerificationMeta(
    'referralQrData',
  );
  @override
  late final GeneratedColumn<String> referralQrData = GeneratedColumn<String>(
    'referral_qr_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    encounterId,
    memberId,
    triageFlag,
    destinationFacilityId,
    destinationLevel,
    transportArranged,
    status,
    outcome,
    outcomeRecordedBy,
    outcomeRecordedAt,
    referralNoteText,
    referralPdfPath,
    referralQrData,
    createdAt,
    updatedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'referral_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReferralRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('encounter_id')) {
      context.handle(
        _encounterIdMeta,
        encounterId.isAcceptableOrUnknown(
          data['encounter_id']!,
          _encounterIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encounterIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('triage_flag')) {
      context.handle(
        _triageFlagMeta,
        triageFlag.isAcceptableOrUnknown(data['triage_flag']!, _triageFlagMeta),
      );
    } else if (isInserting) {
      context.missing(_triageFlagMeta);
    }
    if (data.containsKey('destination_facility_id')) {
      context.handle(
        _destinationFacilityIdMeta,
        destinationFacilityId.isAcceptableOrUnknown(
          data['destination_facility_id']!,
          _destinationFacilityIdMeta,
        ),
      );
    }
    if (data.containsKey('destination_level')) {
      context.handle(
        _destinationLevelMeta,
        destinationLevel.isAcceptableOrUnknown(
          data['destination_level']!,
          _destinationLevelMeta,
        ),
      );
    }
    if (data.containsKey('transport_arranged')) {
      context.handle(
        _transportArrangedMeta,
        transportArranged.isAcceptableOrUnknown(
          data['transport_arranged']!,
          _transportArrangedMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    }
    if (data.containsKey('outcome_recorded_by')) {
      context.handle(
        _outcomeRecordedByMeta,
        outcomeRecordedBy.isAcceptableOrUnknown(
          data['outcome_recorded_by']!,
          _outcomeRecordedByMeta,
        ),
      );
    }
    if (data.containsKey('outcome_recorded_at')) {
      context.handle(
        _outcomeRecordedAtMeta,
        outcomeRecordedAt.isAcceptableOrUnknown(
          data['outcome_recorded_at']!,
          _outcomeRecordedAtMeta,
        ),
      );
    }
    if (data.containsKey('referral_note_text')) {
      context.handle(
        _referralNoteTextMeta,
        referralNoteText.isAcceptableOrUnknown(
          data['referral_note_text']!,
          _referralNoteTextMeta,
        ),
      );
    }
    if (data.containsKey('referral_pdf_path')) {
      context.handle(
        _referralPdfPathMeta,
        referralPdfPath.isAcceptableOrUnknown(
          data['referral_pdf_path']!,
          _referralPdfPathMeta,
        ),
      );
    }
    if (data.containsKey('referral_qr_data')) {
      context.handle(
        _referralQrDataMeta,
        referralQrData.isAcceptableOrUnknown(
          data['referral_qr_data']!,
          _referralQrDataMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReferralRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReferralRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      encounterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encounter_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      triageFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}triage_flag'],
      )!,
      destinationFacilityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_facility_id'],
      ),
      destinationLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}destination_level'],
      ),
      transportArranged: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transport_arranged'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      ),
      outcomeRecordedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome_recorded_by'],
      ),
      outcomeRecordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}outcome_recorded_at'],
      ),
      referralNoteText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}referral_note_text'],
      ),
      referralPdfPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}referral_pdf_path'],
      ),
      referralQrData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}referral_qr_data'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $ReferralRecordsTable createAlias(String alias) {
    return $ReferralRecordsTable(attachedDatabase, alias);
  }
}

class ReferralRecord extends DataClass implements Insertable<ReferralRecord> {
  final String id;
  final String encounterId;
  final String memberId;
  final String triageFlag;
  final String? destinationFacilityId;
  final String? destinationLevel;
  final String? transportArranged;
  final String status;
  final String? outcome;
  final String? outcomeRecordedBy;
  final int? outcomeRecordedAt;
  final String? referralNoteText;
  final String? referralPdfPath;
  final String? referralQrData;
  final int createdAt;
  final int updatedAt;
  final String syncStatus;
  const ReferralRecord({
    required this.id,
    required this.encounterId,
    required this.memberId,
    required this.triageFlag,
    this.destinationFacilityId,
    this.destinationLevel,
    this.transportArranged,
    required this.status,
    this.outcome,
    this.outcomeRecordedBy,
    this.outcomeRecordedAt,
    this.referralNoteText,
    this.referralPdfPath,
    this.referralQrData,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['encounter_id'] = Variable<String>(encounterId);
    map['member_id'] = Variable<String>(memberId);
    map['triage_flag'] = Variable<String>(triageFlag);
    if (!nullToAbsent || destinationFacilityId != null) {
      map['destination_facility_id'] = Variable<String>(destinationFacilityId);
    }
    if (!nullToAbsent || destinationLevel != null) {
      map['destination_level'] = Variable<String>(destinationLevel);
    }
    if (!nullToAbsent || transportArranged != null) {
      map['transport_arranged'] = Variable<String>(transportArranged);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || outcome != null) {
      map['outcome'] = Variable<String>(outcome);
    }
    if (!nullToAbsent || outcomeRecordedBy != null) {
      map['outcome_recorded_by'] = Variable<String>(outcomeRecordedBy);
    }
    if (!nullToAbsent || outcomeRecordedAt != null) {
      map['outcome_recorded_at'] = Variable<int>(outcomeRecordedAt);
    }
    if (!nullToAbsent || referralNoteText != null) {
      map['referral_note_text'] = Variable<String>(referralNoteText);
    }
    if (!nullToAbsent || referralPdfPath != null) {
      map['referral_pdf_path'] = Variable<String>(referralPdfPath);
    }
    if (!nullToAbsent || referralQrData != null) {
      map['referral_qr_data'] = Variable<String>(referralQrData);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  ReferralRecordsCompanion toCompanion(bool nullToAbsent) {
    return ReferralRecordsCompanion(
      id: Value(id),
      encounterId: Value(encounterId),
      memberId: Value(memberId),
      triageFlag: Value(triageFlag),
      destinationFacilityId: destinationFacilityId == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationFacilityId),
      destinationLevel: destinationLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(destinationLevel),
      transportArranged: transportArranged == null && nullToAbsent
          ? const Value.absent()
          : Value(transportArranged),
      status: Value(status),
      outcome: outcome == null && nullToAbsent
          ? const Value.absent()
          : Value(outcome),
      outcomeRecordedBy: outcomeRecordedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(outcomeRecordedBy),
      outcomeRecordedAt: outcomeRecordedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(outcomeRecordedAt),
      referralNoteText: referralNoteText == null && nullToAbsent
          ? const Value.absent()
          : Value(referralNoteText),
      referralPdfPath: referralPdfPath == null && nullToAbsent
          ? const Value.absent()
          : Value(referralPdfPath),
      referralQrData: referralQrData == null && nullToAbsent
          ? const Value.absent()
          : Value(referralQrData),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory ReferralRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReferralRecord(
      id: serializer.fromJson<String>(json['id']),
      encounterId: serializer.fromJson<String>(json['encounterId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      triageFlag: serializer.fromJson<String>(json['triageFlag']),
      destinationFacilityId: serializer.fromJson<String?>(
        json['destinationFacilityId'],
      ),
      destinationLevel: serializer.fromJson<String?>(json['destinationLevel']),
      transportArranged: serializer.fromJson<String?>(
        json['transportArranged'],
      ),
      status: serializer.fromJson<String>(json['status']),
      outcome: serializer.fromJson<String?>(json['outcome']),
      outcomeRecordedBy: serializer.fromJson<String?>(
        json['outcomeRecordedBy'],
      ),
      outcomeRecordedAt: serializer.fromJson<int?>(json['outcomeRecordedAt']),
      referralNoteText: serializer.fromJson<String?>(json['referralNoteText']),
      referralPdfPath: serializer.fromJson<String?>(json['referralPdfPath']),
      referralQrData: serializer.fromJson<String?>(json['referralQrData']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'encounterId': serializer.toJson<String>(encounterId),
      'memberId': serializer.toJson<String>(memberId),
      'triageFlag': serializer.toJson<String>(triageFlag),
      'destinationFacilityId': serializer.toJson<String?>(
        destinationFacilityId,
      ),
      'destinationLevel': serializer.toJson<String?>(destinationLevel),
      'transportArranged': serializer.toJson<String?>(transportArranged),
      'status': serializer.toJson<String>(status),
      'outcome': serializer.toJson<String?>(outcome),
      'outcomeRecordedBy': serializer.toJson<String?>(outcomeRecordedBy),
      'outcomeRecordedAt': serializer.toJson<int?>(outcomeRecordedAt),
      'referralNoteText': serializer.toJson<String?>(referralNoteText),
      'referralPdfPath': serializer.toJson<String?>(referralPdfPath),
      'referralQrData': serializer.toJson<String?>(referralQrData),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  ReferralRecord copyWith({
    String? id,
    String? encounterId,
    String? memberId,
    String? triageFlag,
    Value<String?> destinationFacilityId = const Value.absent(),
    Value<String?> destinationLevel = const Value.absent(),
    Value<String?> transportArranged = const Value.absent(),
    String? status,
    Value<String?> outcome = const Value.absent(),
    Value<String?> outcomeRecordedBy = const Value.absent(),
    Value<int?> outcomeRecordedAt = const Value.absent(),
    Value<String?> referralNoteText = const Value.absent(),
    Value<String?> referralPdfPath = const Value.absent(),
    Value<String?> referralQrData = const Value.absent(),
    int? createdAt,
    int? updatedAt,
    String? syncStatus,
  }) => ReferralRecord(
    id: id ?? this.id,
    encounterId: encounterId ?? this.encounterId,
    memberId: memberId ?? this.memberId,
    triageFlag: triageFlag ?? this.triageFlag,
    destinationFacilityId: destinationFacilityId.present
        ? destinationFacilityId.value
        : this.destinationFacilityId,
    destinationLevel: destinationLevel.present
        ? destinationLevel.value
        : this.destinationLevel,
    transportArranged: transportArranged.present
        ? transportArranged.value
        : this.transportArranged,
    status: status ?? this.status,
    outcome: outcome.present ? outcome.value : this.outcome,
    outcomeRecordedBy: outcomeRecordedBy.present
        ? outcomeRecordedBy.value
        : this.outcomeRecordedBy,
    outcomeRecordedAt: outcomeRecordedAt.present
        ? outcomeRecordedAt.value
        : this.outcomeRecordedAt,
    referralNoteText: referralNoteText.present
        ? referralNoteText.value
        : this.referralNoteText,
    referralPdfPath: referralPdfPath.present
        ? referralPdfPath.value
        : this.referralPdfPath,
    referralQrData: referralQrData.present
        ? referralQrData.value
        : this.referralQrData,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  ReferralRecord copyWithCompanion(ReferralRecordsCompanion data) {
    return ReferralRecord(
      id: data.id.present ? data.id.value : this.id,
      encounterId: data.encounterId.present
          ? data.encounterId.value
          : this.encounterId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      triageFlag: data.triageFlag.present
          ? data.triageFlag.value
          : this.triageFlag,
      destinationFacilityId: data.destinationFacilityId.present
          ? data.destinationFacilityId.value
          : this.destinationFacilityId,
      destinationLevel: data.destinationLevel.present
          ? data.destinationLevel.value
          : this.destinationLevel,
      transportArranged: data.transportArranged.present
          ? data.transportArranged.value
          : this.transportArranged,
      status: data.status.present ? data.status.value : this.status,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      outcomeRecordedBy: data.outcomeRecordedBy.present
          ? data.outcomeRecordedBy.value
          : this.outcomeRecordedBy,
      outcomeRecordedAt: data.outcomeRecordedAt.present
          ? data.outcomeRecordedAt.value
          : this.outcomeRecordedAt,
      referralNoteText: data.referralNoteText.present
          ? data.referralNoteText.value
          : this.referralNoteText,
      referralPdfPath: data.referralPdfPath.present
          ? data.referralPdfPath.value
          : this.referralPdfPath,
      referralQrData: data.referralQrData.present
          ? data.referralQrData.value
          : this.referralQrData,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReferralRecord(')
          ..write('id: $id, ')
          ..write('encounterId: $encounterId, ')
          ..write('memberId: $memberId, ')
          ..write('triageFlag: $triageFlag, ')
          ..write('destinationFacilityId: $destinationFacilityId, ')
          ..write('destinationLevel: $destinationLevel, ')
          ..write('transportArranged: $transportArranged, ')
          ..write('status: $status, ')
          ..write('outcome: $outcome, ')
          ..write('outcomeRecordedBy: $outcomeRecordedBy, ')
          ..write('outcomeRecordedAt: $outcomeRecordedAt, ')
          ..write('referralNoteText: $referralNoteText, ')
          ..write('referralPdfPath: $referralPdfPath, ')
          ..write('referralQrData: $referralQrData, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    encounterId,
    memberId,
    triageFlag,
    destinationFacilityId,
    destinationLevel,
    transportArranged,
    status,
    outcome,
    outcomeRecordedBy,
    outcomeRecordedAt,
    referralNoteText,
    referralPdfPath,
    referralQrData,
    createdAt,
    updatedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReferralRecord &&
          other.id == this.id &&
          other.encounterId == this.encounterId &&
          other.memberId == this.memberId &&
          other.triageFlag == this.triageFlag &&
          other.destinationFacilityId == this.destinationFacilityId &&
          other.destinationLevel == this.destinationLevel &&
          other.transportArranged == this.transportArranged &&
          other.status == this.status &&
          other.outcome == this.outcome &&
          other.outcomeRecordedBy == this.outcomeRecordedBy &&
          other.outcomeRecordedAt == this.outcomeRecordedAt &&
          other.referralNoteText == this.referralNoteText &&
          other.referralPdfPath == this.referralPdfPath &&
          other.referralQrData == this.referralQrData &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncStatus == this.syncStatus);
}

class ReferralRecordsCompanion extends UpdateCompanion<ReferralRecord> {
  final Value<String> id;
  final Value<String> encounterId;
  final Value<String> memberId;
  final Value<String> triageFlag;
  final Value<String?> destinationFacilityId;
  final Value<String?> destinationLevel;
  final Value<String?> transportArranged;
  final Value<String> status;
  final Value<String?> outcome;
  final Value<String?> outcomeRecordedBy;
  final Value<int?> outcomeRecordedAt;
  final Value<String?> referralNoteText;
  final Value<String?> referralPdfPath;
  final Value<String?> referralQrData;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const ReferralRecordsCompanion({
    this.id = const Value.absent(),
    this.encounterId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.triageFlag = const Value.absent(),
    this.destinationFacilityId = const Value.absent(),
    this.destinationLevel = const Value.absent(),
    this.transportArranged = const Value.absent(),
    this.status = const Value.absent(),
    this.outcome = const Value.absent(),
    this.outcomeRecordedBy = const Value.absent(),
    this.outcomeRecordedAt = const Value.absent(),
    this.referralNoteText = const Value.absent(),
    this.referralPdfPath = const Value.absent(),
    this.referralQrData = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReferralRecordsCompanion.insert({
    required String id,
    required String encounterId,
    required String memberId,
    required String triageFlag,
    this.destinationFacilityId = const Value.absent(),
    this.destinationLevel = const Value.absent(),
    this.transportArranged = const Value.absent(),
    this.status = const Value.absent(),
    this.outcome = const Value.absent(),
    this.outcomeRecordedBy = const Value.absent(),
    this.outcomeRecordedAt = const Value.absent(),
    this.referralNoteText = const Value.absent(),
    this.referralPdfPath = const Value.absent(),
    this.referralQrData = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       encounterId = Value(encounterId),
       memberId = Value(memberId),
       triageFlag = Value(triageFlag),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ReferralRecord> custom({
    Expression<String>? id,
    Expression<String>? encounterId,
    Expression<String>? memberId,
    Expression<String>? triageFlag,
    Expression<String>? destinationFacilityId,
    Expression<String>? destinationLevel,
    Expression<String>? transportArranged,
    Expression<String>? status,
    Expression<String>? outcome,
    Expression<String>? outcomeRecordedBy,
    Expression<int>? outcomeRecordedAt,
    Expression<String>? referralNoteText,
    Expression<String>? referralPdfPath,
    Expression<String>? referralQrData,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (encounterId != null) 'encounter_id': encounterId,
      if (memberId != null) 'member_id': memberId,
      if (triageFlag != null) 'triage_flag': triageFlag,
      if (destinationFacilityId != null)
        'destination_facility_id': destinationFacilityId,
      if (destinationLevel != null) 'destination_level': destinationLevel,
      if (transportArranged != null) 'transport_arranged': transportArranged,
      if (status != null) 'status': status,
      if (outcome != null) 'outcome': outcome,
      if (outcomeRecordedBy != null) 'outcome_recorded_by': outcomeRecordedBy,
      if (outcomeRecordedAt != null) 'outcome_recorded_at': outcomeRecordedAt,
      if (referralNoteText != null) 'referral_note_text': referralNoteText,
      if (referralPdfPath != null) 'referral_pdf_path': referralPdfPath,
      if (referralQrData != null) 'referral_qr_data': referralQrData,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReferralRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? encounterId,
    Value<String>? memberId,
    Value<String>? triageFlag,
    Value<String?>? destinationFacilityId,
    Value<String?>? destinationLevel,
    Value<String?>? transportArranged,
    Value<String>? status,
    Value<String?>? outcome,
    Value<String?>? outcomeRecordedBy,
    Value<int?>? outcomeRecordedAt,
    Value<String?>? referralNoteText,
    Value<String?>? referralPdfPath,
    Value<String?>? referralQrData,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return ReferralRecordsCompanion(
      id: id ?? this.id,
      encounterId: encounterId ?? this.encounterId,
      memberId: memberId ?? this.memberId,
      triageFlag: triageFlag ?? this.triageFlag,
      destinationFacilityId:
          destinationFacilityId ?? this.destinationFacilityId,
      destinationLevel: destinationLevel ?? this.destinationLevel,
      transportArranged: transportArranged ?? this.transportArranged,
      status: status ?? this.status,
      outcome: outcome ?? this.outcome,
      outcomeRecordedBy: outcomeRecordedBy ?? this.outcomeRecordedBy,
      outcomeRecordedAt: outcomeRecordedAt ?? this.outcomeRecordedAt,
      referralNoteText: referralNoteText ?? this.referralNoteText,
      referralPdfPath: referralPdfPath ?? this.referralPdfPath,
      referralQrData: referralQrData ?? this.referralQrData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (encounterId.present) {
      map['encounter_id'] = Variable<String>(encounterId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (triageFlag.present) {
      map['triage_flag'] = Variable<String>(triageFlag.value);
    }
    if (destinationFacilityId.present) {
      map['destination_facility_id'] = Variable<String>(
        destinationFacilityId.value,
      );
    }
    if (destinationLevel.present) {
      map['destination_level'] = Variable<String>(destinationLevel.value);
    }
    if (transportArranged.present) {
      map['transport_arranged'] = Variable<String>(transportArranged.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (outcomeRecordedBy.present) {
      map['outcome_recorded_by'] = Variable<String>(outcomeRecordedBy.value);
    }
    if (outcomeRecordedAt.present) {
      map['outcome_recorded_at'] = Variable<int>(outcomeRecordedAt.value);
    }
    if (referralNoteText.present) {
      map['referral_note_text'] = Variable<String>(referralNoteText.value);
    }
    if (referralPdfPath.present) {
      map['referral_pdf_path'] = Variable<String>(referralPdfPath.value);
    }
    if (referralQrData.present) {
      map['referral_qr_data'] = Variable<String>(referralQrData.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReferralRecordsCompanion(')
          ..write('id: $id, ')
          ..write('encounterId: $encounterId, ')
          ..write('memberId: $memberId, ')
          ..write('triageFlag: $triageFlag, ')
          ..write('destinationFacilityId: $destinationFacilityId, ')
          ..write('destinationLevel: $destinationLevel, ')
          ..write('transportArranged: $transportArranged, ')
          ..write('status: $status, ')
          ..write('outcome: $outcome, ')
          ..write('outcomeRecordedBy: $outcomeRecordedBy, ')
          ..write('outcomeRecordedAt: $outcomeRecordedAt, ')
          ..write('referralNoteText: $referralNoteText, ')
          ..write('referralPdfPath: $referralPdfPath, ')
          ..write('referralQrData: $referralQrData, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VisitSchedulesTable extends VisitSchedules
    with TableInfo<$VisitSchedulesTable, VisitSchedule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VisitSchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _programCodeMeta = const VerificationMeta(
    'programCode',
  );
  @override
  late final GeneratedColumn<String> programCode = GeneratedColumn<String>(
    'program_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visitTypeMeta = const VerificationMeta(
    'visitType',
  );
  @override
  late final GeneratedColumn<String> visitType = GeneratedColumn<String>(
    'visit_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<int> dueDate = GeneratedColumn<int>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueWindowStartMeta = const VerificationMeta(
    'dueWindowStart',
  );
  @override
  late final GeneratedColumn<int> dueWindowStart = GeneratedColumn<int>(
    'due_window_start',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueWindowEndMeta = const VerificationMeta(
    'dueWindowEnd',
  );
  @override
  late final GeneratedColumn<int> dueWindowEnd = GeneratedColumn<int>(
    'due_window_end',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _skipReasonMeta = const VerificationMeta(
    'skipReason',
  );
  @override
  late final GeneratedColumn<String> skipReason = GeneratedColumn<String>(
    'skip_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedEncounterIdMeta =
      const VerificationMeta('completedEncounterId');
  @override
  late final GeneratedColumn<String> completedEncounterId =
      GeneratedColumn<String>(
        'completed_encounter_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rescheduledCountMeta = const VerificationMeta(
    'rescheduledCount',
  );
  @override
  late final GeneratedColumn<int> rescheduledCount = GeneratedColumn<int>(
    'rescheduled_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    programCode,
    visitType,
    dueDate,
    dueWindowStart,
    dueWindowEnd,
    status,
    skipReason,
    completedAt,
    completedEncounterId,
    createdAt,
    rescheduledCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'visit_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<VisitSchedule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('program_code')) {
      context.handle(
        _programCodeMeta,
        programCode.isAcceptableOrUnknown(
          data['program_code']!,
          _programCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_programCodeMeta);
    }
    if (data.containsKey('visit_type')) {
      context.handle(
        _visitTypeMeta,
        visitType.isAcceptableOrUnknown(data['visit_type']!, _visitTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_visitTypeMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('due_window_start')) {
      context.handle(
        _dueWindowStartMeta,
        dueWindowStart.isAcceptableOrUnknown(
          data['due_window_start']!,
          _dueWindowStartMeta,
        ),
      );
    }
    if (data.containsKey('due_window_end')) {
      context.handle(
        _dueWindowEndMeta,
        dueWindowEnd.isAcceptableOrUnknown(
          data['due_window_end']!,
          _dueWindowEndMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('skip_reason')) {
      context.handle(
        _skipReasonMeta,
        skipReason.isAcceptableOrUnknown(data['skip_reason']!, _skipReasonMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('completed_encounter_id')) {
      context.handle(
        _completedEncounterIdMeta,
        completedEncounterId.isAcceptableOrUnknown(
          data['completed_encounter_id']!,
          _completedEncounterIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('rescheduled_count')) {
      context.handle(
        _rescheduledCountMeta,
        rescheduledCount.isAcceptableOrUnknown(
          data['rescheduled_count']!,
          _rescheduledCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VisitSchedule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VisitSchedule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      programCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_code'],
      )!,
      visitType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}visit_type'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_date'],
      )!,
      dueWindowStart: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_window_start'],
      ),
      dueWindowEnd: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_window_end'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      skipReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skip_reason'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      completedEncounterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_encounter_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      rescheduledCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rescheduled_count'],
      )!,
    );
  }

  @override
  $VisitSchedulesTable createAlias(String alias) {
    return $VisitSchedulesTable(attachedDatabase, alias);
  }
}

class VisitSchedule extends DataClass implements Insertable<VisitSchedule> {
  final String id;
  final String memberId;
  final String programCode;
  final String visitType;
  final int dueDate;
  final int? dueWindowStart;
  final int? dueWindowEnd;
  final String status;
  final String? skipReason;
  final int? completedAt;
  final String? completedEncounterId;
  final int createdAt;
  final int rescheduledCount;
  const VisitSchedule({
    required this.id,
    required this.memberId,
    required this.programCode,
    required this.visitType,
    required this.dueDate,
    this.dueWindowStart,
    this.dueWindowEnd,
    required this.status,
    this.skipReason,
    this.completedAt,
    this.completedEncounterId,
    required this.createdAt,
    required this.rescheduledCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    map['program_code'] = Variable<String>(programCode);
    map['visit_type'] = Variable<String>(visitType);
    map['due_date'] = Variable<int>(dueDate);
    if (!nullToAbsent || dueWindowStart != null) {
      map['due_window_start'] = Variable<int>(dueWindowStart);
    }
    if (!nullToAbsent || dueWindowEnd != null) {
      map['due_window_end'] = Variable<int>(dueWindowEnd);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || skipReason != null) {
      map['skip_reason'] = Variable<String>(skipReason);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    if (!nullToAbsent || completedEncounterId != null) {
      map['completed_encounter_id'] = Variable<String>(completedEncounterId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['rescheduled_count'] = Variable<int>(rescheduledCount);
    return map;
  }

  VisitSchedulesCompanion toCompanion(bool nullToAbsent) {
    return VisitSchedulesCompanion(
      id: Value(id),
      memberId: Value(memberId),
      programCode: Value(programCode),
      visitType: Value(visitType),
      dueDate: Value(dueDate),
      dueWindowStart: dueWindowStart == null && nullToAbsent
          ? const Value.absent()
          : Value(dueWindowStart),
      dueWindowEnd: dueWindowEnd == null && nullToAbsent
          ? const Value.absent()
          : Value(dueWindowEnd),
      status: Value(status),
      skipReason: skipReason == null && nullToAbsent
          ? const Value.absent()
          : Value(skipReason),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      completedEncounterId: completedEncounterId == null && nullToAbsent
          ? const Value.absent()
          : Value(completedEncounterId),
      createdAt: Value(createdAt),
      rescheduledCount: Value(rescheduledCount),
    );
  }

  factory VisitSchedule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VisitSchedule(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      programCode: serializer.fromJson<String>(json['programCode']),
      visitType: serializer.fromJson<String>(json['visitType']),
      dueDate: serializer.fromJson<int>(json['dueDate']),
      dueWindowStart: serializer.fromJson<int?>(json['dueWindowStart']),
      dueWindowEnd: serializer.fromJson<int?>(json['dueWindowEnd']),
      status: serializer.fromJson<String>(json['status']),
      skipReason: serializer.fromJson<String?>(json['skipReason']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      completedEncounterId: serializer.fromJson<String?>(
        json['completedEncounterId'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      rescheduledCount: serializer.fromJson<int>(json['rescheduledCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'programCode': serializer.toJson<String>(programCode),
      'visitType': serializer.toJson<String>(visitType),
      'dueDate': serializer.toJson<int>(dueDate),
      'dueWindowStart': serializer.toJson<int?>(dueWindowStart),
      'dueWindowEnd': serializer.toJson<int?>(dueWindowEnd),
      'status': serializer.toJson<String>(status),
      'skipReason': serializer.toJson<String?>(skipReason),
      'completedAt': serializer.toJson<int?>(completedAt),
      'completedEncounterId': serializer.toJson<String?>(completedEncounterId),
      'createdAt': serializer.toJson<int>(createdAt),
      'rescheduledCount': serializer.toJson<int>(rescheduledCount),
    };
  }

  VisitSchedule copyWith({
    String? id,
    String? memberId,
    String? programCode,
    String? visitType,
    int? dueDate,
    Value<int?> dueWindowStart = const Value.absent(),
    Value<int?> dueWindowEnd = const Value.absent(),
    String? status,
    Value<String?> skipReason = const Value.absent(),
    Value<int?> completedAt = const Value.absent(),
    Value<String?> completedEncounterId = const Value.absent(),
    int? createdAt,
    int? rescheduledCount,
  }) => VisitSchedule(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    programCode: programCode ?? this.programCode,
    visitType: visitType ?? this.visitType,
    dueDate: dueDate ?? this.dueDate,
    dueWindowStart: dueWindowStart.present
        ? dueWindowStart.value
        : this.dueWindowStart,
    dueWindowEnd: dueWindowEnd.present ? dueWindowEnd.value : this.dueWindowEnd,
    status: status ?? this.status,
    skipReason: skipReason.present ? skipReason.value : this.skipReason,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    completedEncounterId: completedEncounterId.present
        ? completedEncounterId.value
        : this.completedEncounterId,
    createdAt: createdAt ?? this.createdAt,
    rescheduledCount: rescheduledCount ?? this.rescheduledCount,
  );
  VisitSchedule copyWithCompanion(VisitSchedulesCompanion data) {
    return VisitSchedule(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      programCode: data.programCode.present
          ? data.programCode.value
          : this.programCode,
      visitType: data.visitType.present ? data.visitType.value : this.visitType,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      dueWindowStart: data.dueWindowStart.present
          ? data.dueWindowStart.value
          : this.dueWindowStart,
      dueWindowEnd: data.dueWindowEnd.present
          ? data.dueWindowEnd.value
          : this.dueWindowEnd,
      status: data.status.present ? data.status.value : this.status,
      skipReason: data.skipReason.present
          ? data.skipReason.value
          : this.skipReason,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      completedEncounterId: data.completedEncounterId.present
          ? data.completedEncounterId.value
          : this.completedEncounterId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      rescheduledCount: data.rescheduledCount.present
          ? data.rescheduledCount.value
          : this.rescheduledCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VisitSchedule(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('programCode: $programCode, ')
          ..write('visitType: $visitType, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueWindowStart: $dueWindowStart, ')
          ..write('dueWindowEnd: $dueWindowEnd, ')
          ..write('status: $status, ')
          ..write('skipReason: $skipReason, ')
          ..write('completedAt: $completedAt, ')
          ..write('completedEncounterId: $completedEncounterId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rescheduledCount: $rescheduledCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    programCode,
    visitType,
    dueDate,
    dueWindowStart,
    dueWindowEnd,
    status,
    skipReason,
    completedAt,
    completedEncounterId,
    createdAt,
    rescheduledCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VisitSchedule &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.programCode == this.programCode &&
          other.visitType == this.visitType &&
          other.dueDate == this.dueDate &&
          other.dueWindowStart == this.dueWindowStart &&
          other.dueWindowEnd == this.dueWindowEnd &&
          other.status == this.status &&
          other.skipReason == this.skipReason &&
          other.completedAt == this.completedAt &&
          other.completedEncounterId == this.completedEncounterId &&
          other.createdAt == this.createdAt &&
          other.rescheduledCount == this.rescheduledCount);
}

class VisitSchedulesCompanion extends UpdateCompanion<VisitSchedule> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String> programCode;
  final Value<String> visitType;
  final Value<int> dueDate;
  final Value<int?> dueWindowStart;
  final Value<int?> dueWindowEnd;
  final Value<String> status;
  final Value<String?> skipReason;
  final Value<int?> completedAt;
  final Value<String?> completedEncounterId;
  final Value<int> createdAt;
  final Value<int> rescheduledCount;
  final Value<int> rowid;
  const VisitSchedulesCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.programCode = const Value.absent(),
    this.visitType = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.dueWindowStart = const Value.absent(),
    this.dueWindowEnd = const Value.absent(),
    this.status = const Value.absent(),
    this.skipReason = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completedEncounterId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rescheduledCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VisitSchedulesCompanion.insert({
    required String id,
    required String memberId,
    required String programCode,
    required String visitType,
    required int dueDate,
    this.dueWindowStart = const Value.absent(),
    this.dueWindowEnd = const Value.absent(),
    this.status = const Value.absent(),
    this.skipReason = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.completedEncounterId = const Value.absent(),
    required int createdAt,
    this.rescheduledCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       programCode = Value(programCode),
       visitType = Value(visitType),
       dueDate = Value(dueDate),
       createdAt = Value(createdAt);
  static Insertable<VisitSchedule> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? programCode,
    Expression<String>? visitType,
    Expression<int>? dueDate,
    Expression<int>? dueWindowStart,
    Expression<int>? dueWindowEnd,
    Expression<String>? status,
    Expression<String>? skipReason,
    Expression<int>? completedAt,
    Expression<String>? completedEncounterId,
    Expression<int>? createdAt,
    Expression<int>? rescheduledCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (programCode != null) 'program_code': programCode,
      if (visitType != null) 'visit_type': visitType,
      if (dueDate != null) 'due_date': dueDate,
      if (dueWindowStart != null) 'due_window_start': dueWindowStart,
      if (dueWindowEnd != null) 'due_window_end': dueWindowEnd,
      if (status != null) 'status': status,
      if (skipReason != null) 'skip_reason': skipReason,
      if (completedAt != null) 'completed_at': completedAt,
      if (completedEncounterId != null)
        'completed_encounter_id': completedEncounterId,
      if (createdAt != null) 'created_at': createdAt,
      if (rescheduledCount != null) 'rescheduled_count': rescheduledCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VisitSchedulesCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String>? programCode,
    Value<String>? visitType,
    Value<int>? dueDate,
    Value<int?>? dueWindowStart,
    Value<int?>? dueWindowEnd,
    Value<String>? status,
    Value<String?>? skipReason,
    Value<int?>? completedAt,
    Value<String?>? completedEncounterId,
    Value<int>? createdAt,
    Value<int>? rescheduledCount,
    Value<int>? rowid,
  }) {
    return VisitSchedulesCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      programCode: programCode ?? this.programCode,
      visitType: visitType ?? this.visitType,
      dueDate: dueDate ?? this.dueDate,
      dueWindowStart: dueWindowStart ?? this.dueWindowStart,
      dueWindowEnd: dueWindowEnd ?? this.dueWindowEnd,
      status: status ?? this.status,
      skipReason: skipReason ?? this.skipReason,
      completedAt: completedAt ?? this.completedAt,
      completedEncounterId: completedEncounterId ?? this.completedEncounterId,
      createdAt: createdAt ?? this.createdAt,
      rescheduledCount: rescheduledCount ?? this.rescheduledCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (programCode.present) {
      map['program_code'] = Variable<String>(programCode.value);
    }
    if (visitType.present) {
      map['visit_type'] = Variable<String>(visitType.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<int>(dueDate.value);
    }
    if (dueWindowStart.present) {
      map['due_window_start'] = Variable<int>(dueWindowStart.value);
    }
    if (dueWindowEnd.present) {
      map['due_window_end'] = Variable<int>(dueWindowEnd.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (skipReason.present) {
      map['skip_reason'] = Variable<String>(skipReason.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (completedEncounterId.present) {
      map['completed_encounter_id'] = Variable<String>(
        completedEncounterId.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rescheduledCount.present) {
      map['rescheduled_count'] = Variable<int>(rescheduledCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VisitSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('programCode: $programCode, ')
          ..write('visitType: $visitType, ')
          ..write('dueDate: $dueDate, ')
          ..write('dueWindowStart: $dueWindowStart, ')
          ..write('dueWindowEnd: $dueWindowEnd, ')
          ..write('status: $status, ')
          ..write('skipReason: $skipReason, ')
          ..write('completedAt: $completedAt, ')
          ..write('completedEncounterId: $completedEncounterId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rescheduledCount: $rescheduledCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IncentiveEventsTable extends IncentiveEvents
    with TableInfo<$IncentiveEventsTable, IncentiveEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncentiveEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _encounterIdMeta = const VerificationMeta(
    'encounterId',
  );
  @override
  late final GeneratedColumn<String> encounterId = GeneratedColumn<String>(
    'encounter_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activityCodeMeta = const VerificationMeta(
    'activityCode',
  );
  @override
  late final GeneratedColumn<String> activityCode = GeneratedColumn<String>(
    'activity_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catalogueVersionIdMeta =
      const VerificationMeta('catalogueVersionId');
  @override
  late final GeneratedColumn<String> catalogueVersionId =
      GeneratedColumn<String>(
        'catalogue_version_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _eventDateMeta = const VerificationMeta(
    'eventDate',
  );
  @override
  late final GeneratedColumn<int> eventDate = GeneratedColumn<int>(
    'event_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('eligible'),
  );
  static const VerificationMeta _ineligibilityReasonMeta =
      const VerificationMeta('ineligibilityReason');
  @override
  late final GeneratedColumn<String> ineligibilityReason =
      GeneratedColumn<String>(
        'ineligibility_reason',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _evidenceRecordIdMeta = const VerificationMeta(
    'evidenceRecordId',
  );
  @override
  late final GeneratedColumn<String> evidenceRecordId = GeneratedColumn<String>(
    'evidence_record_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    memberId,
    encounterId,
    activityCode,
    catalogueVersionId,
    eventDate,
    status,
    ineligibilityReason,
    evidenceRecordId,
    createdAt,
    idempotencyKey,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'incentive_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<IncentiveEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('encounter_id')) {
      context.handle(
        _encounterIdMeta,
        encounterId.isAcceptableOrUnknown(
          data['encounter_id']!,
          _encounterIdMeta,
        ),
      );
    }
    if (data.containsKey('activity_code')) {
      context.handle(
        _activityCodeMeta,
        activityCode.isAcceptableOrUnknown(
          data['activity_code']!,
          _activityCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_activityCodeMeta);
    }
    if (data.containsKey('catalogue_version_id')) {
      context.handle(
        _catalogueVersionIdMeta,
        catalogueVersionId.isAcceptableOrUnknown(
          data['catalogue_version_id']!,
          _catalogueVersionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catalogueVersionIdMeta);
    }
    if (data.containsKey('event_date')) {
      context.handle(
        _eventDateMeta,
        eventDate.isAcceptableOrUnknown(data['event_date']!, _eventDateMeta),
      );
    } else if (isInserting) {
      context.missing(_eventDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('ineligibility_reason')) {
      context.handle(
        _ineligibilityReasonMeta,
        ineligibilityReason.isAcceptableOrUnknown(
          data['ineligibility_reason']!,
          _ineligibilityReasonMeta,
        ),
      );
    }
    if (data.containsKey('evidence_record_id')) {
      context.handle(
        _evidenceRecordIdMeta,
        evidenceRecordId.isAcceptableOrUnknown(
          data['evidence_record_id']!,
          _evidenceRecordIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IncentiveEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncentiveEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      encounterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encounter_id'],
      ),
      activityCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_code'],
      )!,
      catalogueVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalogue_version_id'],
      )!,
      eventDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}event_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      ineligibilityReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ineligibility_reason'],
      ),
      evidenceRecordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evidence_record_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $IncentiveEventsTable createAlias(String alias) {
    return $IncentiveEventsTable(attachedDatabase, alias);
  }
}

class IncentiveEvent extends DataClass implements Insertable<IncentiveEvent> {
  final String id;
  final String memberId;
  final String? encounterId;
  final String activityCode;
  final String catalogueVersionId;
  final int eventDate;
  final String status;
  final String? ineligibilityReason;
  final String? evidenceRecordId;
  final int createdAt;
  final String idempotencyKey;
  final String syncStatus;
  const IncentiveEvent({
    required this.id,
    required this.memberId,
    this.encounterId,
    required this.activityCode,
    required this.catalogueVersionId,
    required this.eventDate,
    required this.status,
    this.ineligibilityReason,
    this.evidenceRecordId,
    required this.createdAt,
    required this.idempotencyKey,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['member_id'] = Variable<String>(memberId);
    if (!nullToAbsent || encounterId != null) {
      map['encounter_id'] = Variable<String>(encounterId);
    }
    map['activity_code'] = Variable<String>(activityCode);
    map['catalogue_version_id'] = Variable<String>(catalogueVersionId);
    map['event_date'] = Variable<int>(eventDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || ineligibilityReason != null) {
      map['ineligibility_reason'] = Variable<String>(ineligibilityReason);
    }
    if (!nullToAbsent || evidenceRecordId != null) {
      map['evidence_record_id'] = Variable<String>(evidenceRecordId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  IncentiveEventsCompanion toCompanion(bool nullToAbsent) {
    return IncentiveEventsCompanion(
      id: Value(id),
      memberId: Value(memberId),
      encounterId: encounterId == null && nullToAbsent
          ? const Value.absent()
          : Value(encounterId),
      activityCode: Value(activityCode),
      catalogueVersionId: Value(catalogueVersionId),
      eventDate: Value(eventDate),
      status: Value(status),
      ineligibilityReason: ineligibilityReason == null && nullToAbsent
          ? const Value.absent()
          : Value(ineligibilityReason),
      evidenceRecordId: evidenceRecordId == null && nullToAbsent
          ? const Value.absent()
          : Value(evidenceRecordId),
      createdAt: Value(createdAt),
      idempotencyKey: Value(idempotencyKey),
      syncStatus: Value(syncStatus),
    );
  }

  factory IncentiveEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncentiveEvent(
      id: serializer.fromJson<String>(json['id']),
      memberId: serializer.fromJson<String>(json['memberId']),
      encounterId: serializer.fromJson<String?>(json['encounterId']),
      activityCode: serializer.fromJson<String>(json['activityCode']),
      catalogueVersionId: serializer.fromJson<String>(
        json['catalogueVersionId'],
      ),
      eventDate: serializer.fromJson<int>(json['eventDate']),
      status: serializer.fromJson<String>(json['status']),
      ineligibilityReason: serializer.fromJson<String?>(
        json['ineligibilityReason'],
      ),
      evidenceRecordId: serializer.fromJson<String?>(json['evidenceRecordId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'memberId': serializer.toJson<String>(memberId),
      'encounterId': serializer.toJson<String?>(encounterId),
      'activityCode': serializer.toJson<String>(activityCode),
      'catalogueVersionId': serializer.toJson<String>(catalogueVersionId),
      'eventDate': serializer.toJson<int>(eventDate),
      'status': serializer.toJson<String>(status),
      'ineligibilityReason': serializer.toJson<String?>(ineligibilityReason),
      'evidenceRecordId': serializer.toJson<String?>(evidenceRecordId),
      'createdAt': serializer.toJson<int>(createdAt),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  IncentiveEvent copyWith({
    String? id,
    String? memberId,
    Value<String?> encounterId = const Value.absent(),
    String? activityCode,
    String? catalogueVersionId,
    int? eventDate,
    String? status,
    Value<String?> ineligibilityReason = const Value.absent(),
    Value<String?> evidenceRecordId = const Value.absent(),
    int? createdAt,
    String? idempotencyKey,
    String? syncStatus,
  }) => IncentiveEvent(
    id: id ?? this.id,
    memberId: memberId ?? this.memberId,
    encounterId: encounterId.present ? encounterId.value : this.encounterId,
    activityCode: activityCode ?? this.activityCode,
    catalogueVersionId: catalogueVersionId ?? this.catalogueVersionId,
    eventDate: eventDate ?? this.eventDate,
    status: status ?? this.status,
    ineligibilityReason: ineligibilityReason.present
        ? ineligibilityReason.value
        : this.ineligibilityReason,
    evidenceRecordId: evidenceRecordId.present
        ? evidenceRecordId.value
        : this.evidenceRecordId,
    createdAt: createdAt ?? this.createdAt,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  IncentiveEvent copyWithCompanion(IncentiveEventsCompanion data) {
    return IncentiveEvent(
      id: data.id.present ? data.id.value : this.id,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      encounterId: data.encounterId.present
          ? data.encounterId.value
          : this.encounterId,
      activityCode: data.activityCode.present
          ? data.activityCode.value
          : this.activityCode,
      catalogueVersionId: data.catalogueVersionId.present
          ? data.catalogueVersionId.value
          : this.catalogueVersionId,
      eventDate: data.eventDate.present ? data.eventDate.value : this.eventDate,
      status: data.status.present ? data.status.value : this.status,
      ineligibilityReason: data.ineligibilityReason.present
          ? data.ineligibilityReason.value
          : this.ineligibilityReason,
      evidenceRecordId: data.evidenceRecordId.present
          ? data.evidenceRecordId.value
          : this.evidenceRecordId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncentiveEvent(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('encounterId: $encounterId, ')
          ..write('activityCode: $activityCode, ')
          ..write('catalogueVersionId: $catalogueVersionId, ')
          ..write('eventDate: $eventDate, ')
          ..write('status: $status, ')
          ..write('ineligibilityReason: $ineligibilityReason, ')
          ..write('evidenceRecordId: $evidenceRecordId, ')
          ..write('createdAt: $createdAt, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    encounterId,
    activityCode,
    catalogueVersionId,
    eventDate,
    status,
    ineligibilityReason,
    evidenceRecordId,
    createdAt,
    idempotencyKey,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncentiveEvent &&
          other.id == this.id &&
          other.memberId == this.memberId &&
          other.encounterId == this.encounterId &&
          other.activityCode == this.activityCode &&
          other.catalogueVersionId == this.catalogueVersionId &&
          other.eventDate == this.eventDate &&
          other.status == this.status &&
          other.ineligibilityReason == this.ineligibilityReason &&
          other.evidenceRecordId == this.evidenceRecordId &&
          other.createdAt == this.createdAt &&
          other.idempotencyKey == this.idempotencyKey &&
          other.syncStatus == this.syncStatus);
}

class IncentiveEventsCompanion extends UpdateCompanion<IncentiveEvent> {
  final Value<String> id;
  final Value<String> memberId;
  final Value<String?> encounterId;
  final Value<String> activityCode;
  final Value<String> catalogueVersionId;
  final Value<int> eventDate;
  final Value<String> status;
  final Value<String?> ineligibilityReason;
  final Value<String?> evidenceRecordId;
  final Value<int> createdAt;
  final Value<String> idempotencyKey;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const IncentiveEventsCompanion({
    this.id = const Value.absent(),
    this.memberId = const Value.absent(),
    this.encounterId = const Value.absent(),
    this.activityCode = const Value.absent(),
    this.catalogueVersionId = const Value.absent(),
    this.eventDate = const Value.absent(),
    this.status = const Value.absent(),
    this.ineligibilityReason = const Value.absent(),
    this.evidenceRecordId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncentiveEventsCompanion.insert({
    required String id,
    required String memberId,
    this.encounterId = const Value.absent(),
    required String activityCode,
    required String catalogueVersionId,
    required int eventDate,
    this.status = const Value.absent(),
    this.ineligibilityReason = const Value.absent(),
    this.evidenceRecordId = const Value.absent(),
    required int createdAt,
    required String idempotencyKey,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       memberId = Value(memberId),
       activityCode = Value(activityCode),
       catalogueVersionId = Value(catalogueVersionId),
       eventDate = Value(eventDate),
       createdAt = Value(createdAt),
       idempotencyKey = Value(idempotencyKey);
  static Insertable<IncentiveEvent> custom({
    Expression<String>? id,
    Expression<String>? memberId,
    Expression<String>? encounterId,
    Expression<String>? activityCode,
    Expression<String>? catalogueVersionId,
    Expression<int>? eventDate,
    Expression<String>? status,
    Expression<String>? ineligibilityReason,
    Expression<String>? evidenceRecordId,
    Expression<int>? createdAt,
    Expression<String>? idempotencyKey,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (memberId != null) 'member_id': memberId,
      if (encounterId != null) 'encounter_id': encounterId,
      if (activityCode != null) 'activity_code': activityCode,
      if (catalogueVersionId != null)
        'catalogue_version_id': catalogueVersionId,
      if (eventDate != null) 'event_date': eventDate,
      if (status != null) 'status': status,
      if (ineligibilityReason != null)
        'ineligibility_reason': ineligibilityReason,
      if (evidenceRecordId != null) 'evidence_record_id': evidenceRecordId,
      if (createdAt != null) 'created_at': createdAt,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncentiveEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? memberId,
    Value<String?>? encounterId,
    Value<String>? activityCode,
    Value<String>? catalogueVersionId,
    Value<int>? eventDate,
    Value<String>? status,
    Value<String?>? ineligibilityReason,
    Value<String?>? evidenceRecordId,
    Value<int>? createdAt,
    Value<String>? idempotencyKey,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return IncentiveEventsCompanion(
      id: id ?? this.id,
      memberId: memberId ?? this.memberId,
      encounterId: encounterId ?? this.encounterId,
      activityCode: activityCode ?? this.activityCode,
      catalogueVersionId: catalogueVersionId ?? this.catalogueVersionId,
      eventDate: eventDate ?? this.eventDate,
      status: status ?? this.status,
      ineligibilityReason: ineligibilityReason ?? this.ineligibilityReason,
      evidenceRecordId: evidenceRecordId ?? this.evidenceRecordId,
      createdAt: createdAt ?? this.createdAt,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (encounterId.present) {
      map['encounter_id'] = Variable<String>(encounterId.value);
    }
    if (activityCode.present) {
      map['activity_code'] = Variable<String>(activityCode.value);
    }
    if (catalogueVersionId.present) {
      map['catalogue_version_id'] = Variable<String>(catalogueVersionId.value);
    }
    if (eventDate.present) {
      map['event_date'] = Variable<int>(eventDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (ineligibilityReason.present) {
      map['ineligibility_reason'] = Variable<String>(ineligibilityReason.value);
    }
    if (evidenceRecordId.present) {
      map['evidence_record_id'] = Variable<String>(evidenceRecordId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncentiveEventsCompanion(')
          ..write('id: $id, ')
          ..write('memberId: $memberId, ')
          ..write('encounterId: $encounterId, ')
          ..write('activityCode: $activityCode, ')
          ..write('catalogueVersionId: $catalogueVersionId, ')
          ..write('eventDate: $eventDate, ')
          ..write('status: $status, ')
          ..write('ineligibilityReason: $ineligibilityReason, ')
          ..write('evidenceRecordId: $evidenceRecordId, ')
          ..write('createdAt: $createdAt, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IncentiveClaimsTable extends IncentiveClaims
    with TableInfo<$IncentiveClaimsTable, IncentiveClaim> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncentiveClaimsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workerIdMeta = const VerificationMeta(
    'workerId',
  );
  @override
  late final GeneratedColumn<String> workerId = GeneratedColumn<String>(
    'worker_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const VerificationMeta _claimPeriodMeta = const VerificationMeta(
    'claimPeriod',
  );
  @override
  late final GeneratedColumn<String> claimPeriod = GeneratedColumn<String>(
    'claim_period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('generated'),
  );
  static const VerificationMeta _lineItemsJsonMeta = const VerificationMeta(
    'lineItemsJson',
  );
  @override
  late final GeneratedColumn<String> lineItemsJson = GeneratedColumn<String>(
    'line_items_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _pdfPathMeta = const VerificationMeta(
    'pdfPath',
  );
  @override
  late final GeneratedColumn<String> pdfPath = GeneratedColumn<String>(
    'pdf_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentReferenceMeta = const VerificationMeta(
    'paymentReference',
  );
  @override
  late final GeneratedColumn<String> paymentReference = GeneratedColumn<String>(
    'payment_reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<int> submittedAt = GeneratedColumn<int>(
    'submitted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  @override
  late final GeneratedColumn<int> verifiedAt = GeneratedColumn<int>(
    'verified_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<int> paidAt = GeneratedColumn<int>(
    'paid_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workerId,
    claimPeriod,
    status,
    lineItemsJson,
    totalAmount,
    pdfPath,
    paymentReference,
    submittedAt,
    verifiedAt,
    paidAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'incentive_claims';
  @override
  VerificationContext validateIntegrity(
    Insertable<IncentiveClaim> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('worker_id')) {
      context.handle(
        _workerIdMeta,
        workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workerIdMeta);
    }
    if (data.containsKey('claim_period')) {
      context.handle(
        _claimPeriodMeta,
        claimPeriod.isAcceptableOrUnknown(
          data['claim_period']!,
          _claimPeriodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_claimPeriodMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('line_items_json')) {
      context.handle(
        _lineItemsJsonMeta,
        lineItemsJson.isAcceptableOrUnknown(
          data['line_items_json']!,
          _lineItemsJsonMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('pdf_path')) {
      context.handle(
        _pdfPathMeta,
        pdfPath.isAcceptableOrUnknown(data['pdf_path']!, _pdfPathMeta),
      );
    }
    if (data.containsKey('payment_reference')) {
      context.handle(
        _paymentReferenceMeta,
        paymentReference.isAcceptableOrUnknown(
          data['payment_reference']!,
          _paymentReferenceMeta,
        ),
      );
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
      );
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  IncentiveClaim map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IncentiveClaim(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_id'],
      )!,
      claimPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}claim_period'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lineItemsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_items_json'],
      )!,
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      pdfPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_path'],
      ),
      paymentReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_reference'],
      ),
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}submitted_at'],
      ),
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verified_at'],
      ),
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_at'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $IncentiveClaimsTable createAlias(String alias) {
    return $IncentiveClaimsTable(attachedDatabase, alias);
  }
}

class IncentiveClaim extends DataClass implements Insertable<IncentiveClaim> {
  final String id;
  final String workerId;
  final String claimPeriod;
  final String status;
  final String lineItemsJson;
  final double totalAmount;
  final String? pdfPath;
  final String? paymentReference;
  final int? submittedAt;
  final int? verifiedAt;
  final int? paidAt;
  final String syncStatus;
  const IncentiveClaim({
    required this.id,
    required this.workerId,
    required this.claimPeriod,
    required this.status,
    required this.lineItemsJson,
    required this.totalAmount,
    this.pdfPath,
    this.paymentReference,
    this.submittedAt,
    this.verifiedAt,
    this.paidAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['worker_id'] = Variable<String>(workerId);
    map['claim_period'] = Variable<String>(claimPeriod);
    map['status'] = Variable<String>(status);
    map['line_items_json'] = Variable<String>(lineItemsJson);
    map['total_amount'] = Variable<double>(totalAmount);
    if (!nullToAbsent || pdfPath != null) {
      map['pdf_path'] = Variable<String>(pdfPath);
    }
    if (!nullToAbsent || paymentReference != null) {
      map['payment_reference'] = Variable<String>(paymentReference);
    }
    if (!nullToAbsent || submittedAt != null) {
      map['submitted_at'] = Variable<int>(submittedAt);
    }
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<int>(verifiedAt);
    }
    if (!nullToAbsent || paidAt != null) {
      map['paid_at'] = Variable<int>(paidAt);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  IncentiveClaimsCompanion toCompanion(bool nullToAbsent) {
    return IncentiveClaimsCompanion(
      id: Value(id),
      workerId: Value(workerId),
      claimPeriod: Value(claimPeriod),
      status: Value(status),
      lineItemsJson: Value(lineItemsJson),
      totalAmount: Value(totalAmount),
      pdfPath: pdfPath == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfPath),
      paymentReference: paymentReference == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentReference),
      submittedAt: submittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedAt),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
      paidAt: paidAt == null && nullToAbsent
          ? const Value.absent()
          : Value(paidAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory IncentiveClaim.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IncentiveClaim(
      id: serializer.fromJson<String>(json['id']),
      workerId: serializer.fromJson<String>(json['workerId']),
      claimPeriod: serializer.fromJson<String>(json['claimPeriod']),
      status: serializer.fromJson<String>(json['status']),
      lineItemsJson: serializer.fromJson<String>(json['lineItemsJson']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      pdfPath: serializer.fromJson<String?>(json['pdfPath']),
      paymentReference: serializer.fromJson<String?>(json['paymentReference']),
      submittedAt: serializer.fromJson<int?>(json['submittedAt']),
      verifiedAt: serializer.fromJson<int?>(json['verifiedAt']),
      paidAt: serializer.fromJson<int?>(json['paidAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workerId': serializer.toJson<String>(workerId),
      'claimPeriod': serializer.toJson<String>(claimPeriod),
      'status': serializer.toJson<String>(status),
      'lineItemsJson': serializer.toJson<String>(lineItemsJson),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'pdfPath': serializer.toJson<String?>(pdfPath),
      'paymentReference': serializer.toJson<String?>(paymentReference),
      'submittedAt': serializer.toJson<int?>(submittedAt),
      'verifiedAt': serializer.toJson<int?>(verifiedAt),
      'paidAt': serializer.toJson<int?>(paidAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  IncentiveClaim copyWith({
    String? id,
    String? workerId,
    String? claimPeriod,
    String? status,
    String? lineItemsJson,
    double? totalAmount,
    Value<String?> pdfPath = const Value.absent(),
    Value<String?> paymentReference = const Value.absent(),
    Value<int?> submittedAt = const Value.absent(),
    Value<int?> verifiedAt = const Value.absent(),
    Value<int?> paidAt = const Value.absent(),
    String? syncStatus,
  }) => IncentiveClaim(
    id: id ?? this.id,
    workerId: workerId ?? this.workerId,
    claimPeriod: claimPeriod ?? this.claimPeriod,
    status: status ?? this.status,
    lineItemsJson: lineItemsJson ?? this.lineItemsJson,
    totalAmount: totalAmount ?? this.totalAmount,
    pdfPath: pdfPath.present ? pdfPath.value : this.pdfPath,
    paymentReference: paymentReference.present
        ? paymentReference.value
        : this.paymentReference,
    submittedAt: submittedAt.present ? submittedAt.value : this.submittedAt,
    verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
    paidAt: paidAt.present ? paidAt.value : this.paidAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  IncentiveClaim copyWithCompanion(IncentiveClaimsCompanion data) {
    return IncentiveClaim(
      id: data.id.present ? data.id.value : this.id,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      claimPeriod: data.claimPeriod.present
          ? data.claimPeriod.value
          : this.claimPeriod,
      status: data.status.present ? data.status.value : this.status,
      lineItemsJson: data.lineItemsJson.present
          ? data.lineItemsJson.value
          : this.lineItemsJson,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      pdfPath: data.pdfPath.present ? data.pdfPath.value : this.pdfPath,
      paymentReference: data.paymentReference.present
          ? data.paymentReference.value
          : this.paymentReference,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IncentiveClaim(')
          ..write('id: $id, ')
          ..write('workerId: $workerId, ')
          ..write('claimPeriod: $claimPeriod, ')
          ..write('status: $status, ')
          ..write('lineItemsJson: $lineItemsJson, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('paymentReference: $paymentReference, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('paidAt: $paidAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workerId,
    claimPeriod,
    status,
    lineItemsJson,
    totalAmount,
    pdfPath,
    paymentReference,
    submittedAt,
    verifiedAt,
    paidAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IncentiveClaim &&
          other.id == this.id &&
          other.workerId == this.workerId &&
          other.claimPeriod == this.claimPeriod &&
          other.status == this.status &&
          other.lineItemsJson == this.lineItemsJson &&
          other.totalAmount == this.totalAmount &&
          other.pdfPath == this.pdfPath &&
          other.paymentReference == this.paymentReference &&
          other.submittedAt == this.submittedAt &&
          other.verifiedAt == this.verifiedAt &&
          other.paidAt == this.paidAt &&
          other.syncStatus == this.syncStatus);
}

class IncentiveClaimsCompanion extends UpdateCompanion<IncentiveClaim> {
  final Value<String> id;
  final Value<String> workerId;
  final Value<String> claimPeriod;
  final Value<String> status;
  final Value<String> lineItemsJson;
  final Value<double> totalAmount;
  final Value<String?> pdfPath;
  final Value<String?> paymentReference;
  final Value<int?> submittedAt;
  final Value<int?> verifiedAt;
  final Value<int?> paidAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const IncentiveClaimsCompanion({
    this.id = const Value.absent(),
    this.workerId = const Value.absent(),
    this.claimPeriod = const Value.absent(),
    this.status = const Value.absent(),
    this.lineItemsJson = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.paymentReference = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncentiveClaimsCompanion.insert({
    required String id,
    required String workerId,
    required String claimPeriod,
    this.status = const Value.absent(),
    this.lineItemsJson = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.pdfPath = const Value.absent(),
    this.paymentReference = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workerId = Value(workerId),
       claimPeriod = Value(claimPeriod);
  static Insertable<IncentiveClaim> custom({
    Expression<String>? id,
    Expression<String>? workerId,
    Expression<String>? claimPeriod,
    Expression<String>? status,
    Expression<String>? lineItemsJson,
    Expression<double>? totalAmount,
    Expression<String>? pdfPath,
    Expression<String>? paymentReference,
    Expression<int>? submittedAt,
    Expression<int>? verifiedAt,
    Expression<int>? paidAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workerId != null) 'worker_id': workerId,
      if (claimPeriod != null) 'claim_period': claimPeriod,
      if (status != null) 'status': status,
      if (lineItemsJson != null) 'line_items_json': lineItemsJson,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (pdfPath != null) 'pdf_path': pdfPath,
      if (paymentReference != null) 'payment_reference': paymentReference,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (paidAt != null) 'paid_at': paidAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncentiveClaimsCompanion copyWith({
    Value<String>? id,
    Value<String>? workerId,
    Value<String>? claimPeriod,
    Value<String>? status,
    Value<String>? lineItemsJson,
    Value<double>? totalAmount,
    Value<String?>? pdfPath,
    Value<String?>? paymentReference,
    Value<int?>? submittedAt,
    Value<int?>? verifiedAt,
    Value<int?>? paidAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return IncentiveClaimsCompanion(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      claimPeriod: claimPeriod ?? this.claimPeriod,
      status: status ?? this.status,
      lineItemsJson: lineItemsJson ?? this.lineItemsJson,
      totalAmount: totalAmount ?? this.totalAmount,
      pdfPath: pdfPath ?? this.pdfPath,
      paymentReference: paymentReference ?? this.paymentReference,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      paidAt: paidAt ?? this.paidAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<String>(workerId.value);
    }
    if (claimPeriod.present) {
      map['claim_period'] = Variable<String>(claimPeriod.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lineItemsJson.present) {
      map['line_items_json'] = Variable<String>(lineItemsJson.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (pdfPath.present) {
      map['pdf_path'] = Variable<String>(pdfPath.value);
    }
    if (paymentReference.present) {
      map['payment_reference'] = Variable<String>(paymentReference.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<int>(submittedAt.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<int>(verifiedAt.value);
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<int>(paidAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncentiveClaimsCompanion(')
          ..write('id: $id, ')
          ..write('workerId: $workerId, ')
          ..write('claimPeriod: $claimPeriod, ')
          ..write('status: $status, ')
          ..write('lineItemsJson: $lineItemsJson, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('pdfPath: $pdfPath, ')
          ..write('paymentReference: $paymentReference, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('paidAt: $paidAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTableMeta = const VerificationMeta(
    'targetTable',
  );
  @override
  late final GeneratedColumn<String> targetTable = GeneratedColumn<String>(
    'target_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventLogJsonMeta = const VerificationMeta(
    'eventLogJson',
  );
  @override
  late final GeneratedColumn<String> eventLogJson = GeneratedColumn<String>(
    'event_log_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<int> lastAttemptAt = GeneratedColumn<int>(
    'last_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    targetTable,
    recordId,
    priority,
    operation,
    payloadJson,
    eventLogJson,
    syncStatus,
    createdAt,
    lastAttemptAt,
    attemptCount,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_table')) {
      context.handle(
        _targetTableMeta,
        targetTable.isAcceptableOrUnknown(
          data['target_table']!,
          _targetTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('event_log_json')) {
      context.handle(
        _eventLogJsonMeta,
        eventLogJson.isAcceptableOrUnknown(
          data['event_log_json']!,
          _eventLogJsonMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      targetTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_table'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      eventLogJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_log_json'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_attempt_at'],
      ),
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final String id;
  final String targetTable;
  final String recordId;
  final int priority;
  final String operation;
  final String payloadJson;
  final String eventLogJson;
  final String syncStatus;
  final int createdAt;
  final int? lastAttemptAt;
  final int attemptCount;
  final String? errorMessage;
  const SyncQueueData({
    required this.id,
    required this.targetTable,
    required this.recordId,
    required this.priority,
    required this.operation,
    required this.payloadJson,
    required this.eventLogJson,
    required this.syncStatus,
    required this.createdAt,
    this.lastAttemptAt,
    required this.attemptCount,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['target_table'] = Variable<String>(targetTable);
    map['record_id'] = Variable<String>(recordId);
    map['priority'] = Variable<int>(priority);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['event_log_json'] = Variable<String>(eventLogJson);
    map['sync_status'] = Variable<String>(syncStatus);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt);
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      targetTable: Value(targetTable),
      recordId: Value(recordId),
      priority: Value(priority),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      eventLogJson: Value(eventLogJson),
      syncStatus: Value(syncStatus),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      attemptCount: Value(attemptCount),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory SyncQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      targetTable: serializer.fromJson<String>(json['targetTable']),
      recordId: serializer.fromJson<String>(json['recordId']),
      priority: serializer.fromJson<int>(json['priority']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      eventLogJson: serializer.fromJson<String>(json['eventLogJson']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<int?>(json['lastAttemptAt']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetTable': serializer.toJson<String>(targetTable),
      'recordId': serializer.toJson<String>(recordId),
      'priority': serializer.toJson<int>(priority),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'eventLogJson': serializer.toJson<String>(eventLogJson),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastAttemptAt': serializer.toJson<int?>(lastAttemptAt),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  SyncQueueData copyWith({
    String? id,
    String? targetTable,
    String? recordId,
    int? priority,
    String? operation,
    String? payloadJson,
    String? eventLogJson,
    String? syncStatus,
    int? createdAt,
    Value<int?> lastAttemptAt = const Value.absent(),
    int? attemptCount,
    Value<String?> errorMessage = const Value.absent(),
  }) => SyncQueueData(
    id: id ?? this.id,
    targetTable: targetTable ?? this.targetTable,
    recordId: recordId ?? this.recordId,
    priority: priority ?? this.priority,
    operation: operation ?? this.operation,
    payloadJson: payloadJson ?? this.payloadJson,
    eventLogJson: eventLogJson ?? this.eventLogJson,
    syncStatus: syncStatus ?? this.syncStatus,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    attemptCount: attemptCount ?? this.attemptCount,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      targetTable: data.targetTable.present
          ? data.targetTable.value
          : this.targetTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      priority: data.priority.present ? data.priority.value : this.priority,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      eventLogJson: data.eventLogJson.present
          ? data.eventLogJson.value
          : this.eventLogJson,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('priority: $priority, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('eventLogJson: $eventLogJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    targetTable,
    recordId,
    priority,
    operation,
    payloadJson,
    eventLogJson,
    syncStatus,
    createdAt,
    lastAttemptAt,
    attemptCount,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.targetTable == this.targetTable &&
          other.recordId == this.recordId &&
          other.priority == this.priority &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.eventLogJson == this.eventLogJson &&
          other.syncStatus == this.syncStatus &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.attemptCount == this.attemptCount &&
          other.errorMessage == this.errorMessage);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> targetTable;
  final Value<String> recordId;
  final Value<int> priority;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<String> eventLogJson;
  final Value<String> syncStatus;
  final Value<int> createdAt;
  final Value<int?> lastAttemptAt;
  final Value<int> attemptCount;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.targetTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.priority = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.eventLogJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String targetTable,
    required String recordId,
    this.priority = const Value.absent(),
    required String operation,
    required String payloadJson,
    this.eventLogJson = const Value.absent(),
    this.syncStatus = const Value.absent(),
    required int createdAt,
    this.lastAttemptAt = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       targetTable = Value(targetTable),
       recordId = Value(recordId),
       operation = Value(operation),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? targetTable,
    Expression<String>? recordId,
    Expression<int>? priority,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<String>? eventLogJson,
    Expression<String>? syncStatus,
    Expression<int>? createdAt,
    Expression<int>? lastAttemptAt,
    Expression<int>? attemptCount,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetTable != null) 'target_table': targetTable,
      if (recordId != null) 'record_id': recordId,
      if (priority != null) 'priority': priority,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (eventLogJson != null) 'event_log_json': eventLogJson,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith({
    Value<String>? id,
    Value<String>? targetTable,
    Value<String>? recordId,
    Value<int>? priority,
    Value<String>? operation,
    Value<String>? payloadJson,
    Value<String>? eventLogJson,
    Value<String>? syncStatus,
    Value<int>? createdAt,
    Value<int?>? lastAttemptAt,
    Value<int>? attemptCount,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      targetTable: targetTable ?? this.targetTable,
      recordId: recordId ?? this.recordId,
      priority: priority ?? this.priority,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      eventLogJson: eventLogJson ?? this.eventLogJson,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      attemptCount: attemptCount ?? this.attemptCount,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (targetTable.present) {
      map['target_table'] = Variable<String>(targetTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (eventLogJson.present) {
      map['event_log_json'] = Variable<String>(eventLogJson.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('targetTable: $targetTable, ')
          ..write('recordId: $recordId, ')
          ..write('priority: $priority, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('eventLogJson: $eventLogJson, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RuleVersionsTable extends RuleVersions
    with TableInfo<$RuleVersionsTable, RuleVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RuleVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _versionStringMeta = const VerificationMeta(
    'versionString',
  );
  @override
  late final GeneratedColumn<String> versionString = GeneratedColumn<String>(
    'version_string',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  @override
  late final GeneratedColumn<int> publishedAt = GeneratedColumn<int>(
    'published_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bundleHashMeta = const VerificationMeta(
    'bundleHash',
  );
  @override
  late final GeneratedColumn<String> bundleHash = GeneratedColumn<String>(
    'bundle_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bundlePathMeta = const VerificationMeta(
    'bundlePath',
  );
  @override
  late final GeneratedColumn<String> bundlePath = GeneratedColumn<String>(
    'bundle_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _clinicalLeadIdMeta = const VerificationMeta(
    'clinicalLeadId',
  );
  @override
  late final GeneratedColumn<String> clinicalLeadId = GeneratedColumn<String>(
    'clinical_lead_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _approvalSignatureMeta = const VerificationMeta(
    'approvalSignature',
  );
  @override
  late final GeneratedColumn<String> approvalSignature =
      GeneratedColumn<String>(
        'approval_signature',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    versionString,
    publishedAt,
    bundleHash,
    bundlePath,
    isActive,
    clinicalLeadId,
    approvalSignature,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rule_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<RuleVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('version_string')) {
      context.handle(
        _versionStringMeta,
        versionString.isAcceptableOrUnknown(
          data['version_string']!,
          _versionStringMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionStringMeta);
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_publishedAtMeta);
    }
    if (data.containsKey('bundle_hash')) {
      context.handle(
        _bundleHashMeta,
        bundleHash.isAcceptableOrUnknown(data['bundle_hash']!, _bundleHashMeta),
      );
    } else if (isInserting) {
      context.missing(_bundleHashMeta);
    }
    if (data.containsKey('bundle_path')) {
      context.handle(
        _bundlePathMeta,
        bundlePath.isAcceptableOrUnknown(data['bundle_path']!, _bundlePathMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('clinical_lead_id')) {
      context.handle(
        _clinicalLeadIdMeta,
        clinicalLeadId.isAcceptableOrUnknown(
          data['clinical_lead_id']!,
          _clinicalLeadIdMeta,
        ),
      );
    }
    if (data.containsKey('approval_signature')) {
      context.handle(
        _approvalSignatureMeta,
        approvalSignature.isAcceptableOrUnknown(
          data['approval_signature']!,
          _approvalSignatureMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RuleVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleVersion(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      versionString: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_string'],
      )!,
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}published_at'],
      )!,
      bundleHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bundle_hash'],
      )!,
      bundlePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bundle_path'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      clinicalLeadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clinical_lead_id'],
      ),
      approvalSignature: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}approval_signature'],
      ),
    );
  }

  @override
  $RuleVersionsTable createAlias(String alias) {
    return $RuleVersionsTable(attachedDatabase, alias);
  }
}

class RuleVersion extends DataClass implements Insertable<RuleVersion> {
  final String id;
  final String versionString;
  final int publishedAt;
  final String bundleHash;
  final String? bundlePath;
  final bool isActive;
  final String? clinicalLeadId;
  final String? approvalSignature;
  const RuleVersion({
    required this.id,
    required this.versionString,
    required this.publishedAt,
    required this.bundleHash,
    this.bundlePath,
    required this.isActive,
    this.clinicalLeadId,
    this.approvalSignature,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['version_string'] = Variable<String>(versionString);
    map['published_at'] = Variable<int>(publishedAt);
    map['bundle_hash'] = Variable<String>(bundleHash);
    if (!nullToAbsent || bundlePath != null) {
      map['bundle_path'] = Variable<String>(bundlePath);
    }
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || clinicalLeadId != null) {
      map['clinical_lead_id'] = Variable<String>(clinicalLeadId);
    }
    if (!nullToAbsent || approvalSignature != null) {
      map['approval_signature'] = Variable<String>(approvalSignature);
    }
    return map;
  }

  RuleVersionsCompanion toCompanion(bool nullToAbsent) {
    return RuleVersionsCompanion(
      id: Value(id),
      versionString: Value(versionString),
      publishedAt: Value(publishedAt),
      bundleHash: Value(bundleHash),
      bundlePath: bundlePath == null && nullToAbsent
          ? const Value.absent()
          : Value(bundlePath),
      isActive: Value(isActive),
      clinicalLeadId: clinicalLeadId == null && nullToAbsent
          ? const Value.absent()
          : Value(clinicalLeadId),
      approvalSignature: approvalSignature == null && nullToAbsent
          ? const Value.absent()
          : Value(approvalSignature),
    );
  }

  factory RuleVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleVersion(
      id: serializer.fromJson<String>(json['id']),
      versionString: serializer.fromJson<String>(json['versionString']),
      publishedAt: serializer.fromJson<int>(json['publishedAt']),
      bundleHash: serializer.fromJson<String>(json['bundleHash']),
      bundlePath: serializer.fromJson<String?>(json['bundlePath']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      clinicalLeadId: serializer.fromJson<String?>(json['clinicalLeadId']),
      approvalSignature: serializer.fromJson<String?>(
        json['approvalSignature'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'versionString': serializer.toJson<String>(versionString),
      'publishedAt': serializer.toJson<int>(publishedAt),
      'bundleHash': serializer.toJson<String>(bundleHash),
      'bundlePath': serializer.toJson<String?>(bundlePath),
      'isActive': serializer.toJson<bool>(isActive),
      'clinicalLeadId': serializer.toJson<String?>(clinicalLeadId),
      'approvalSignature': serializer.toJson<String?>(approvalSignature),
    };
  }

  RuleVersion copyWith({
    String? id,
    String? versionString,
    int? publishedAt,
    String? bundleHash,
    Value<String?> bundlePath = const Value.absent(),
    bool? isActive,
    Value<String?> clinicalLeadId = const Value.absent(),
    Value<String?> approvalSignature = const Value.absent(),
  }) => RuleVersion(
    id: id ?? this.id,
    versionString: versionString ?? this.versionString,
    publishedAt: publishedAt ?? this.publishedAt,
    bundleHash: bundleHash ?? this.bundleHash,
    bundlePath: bundlePath.present ? bundlePath.value : this.bundlePath,
    isActive: isActive ?? this.isActive,
    clinicalLeadId: clinicalLeadId.present
        ? clinicalLeadId.value
        : this.clinicalLeadId,
    approvalSignature: approvalSignature.present
        ? approvalSignature.value
        : this.approvalSignature,
  );
  RuleVersion copyWithCompanion(RuleVersionsCompanion data) {
    return RuleVersion(
      id: data.id.present ? data.id.value : this.id,
      versionString: data.versionString.present
          ? data.versionString.value
          : this.versionString,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
      bundleHash: data.bundleHash.present
          ? data.bundleHash.value
          : this.bundleHash,
      bundlePath: data.bundlePath.present
          ? data.bundlePath.value
          : this.bundlePath,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      clinicalLeadId: data.clinicalLeadId.present
          ? data.clinicalLeadId.value
          : this.clinicalLeadId,
      approvalSignature: data.approvalSignature.present
          ? data.approvalSignature.value
          : this.approvalSignature,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleVersion(')
          ..write('id: $id, ')
          ..write('versionString: $versionString, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('bundleHash: $bundleHash, ')
          ..write('bundlePath: $bundlePath, ')
          ..write('isActive: $isActive, ')
          ..write('clinicalLeadId: $clinicalLeadId, ')
          ..write('approvalSignature: $approvalSignature')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    versionString,
    publishedAt,
    bundleHash,
    bundlePath,
    isActive,
    clinicalLeadId,
    approvalSignature,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleVersion &&
          other.id == this.id &&
          other.versionString == this.versionString &&
          other.publishedAt == this.publishedAt &&
          other.bundleHash == this.bundleHash &&
          other.bundlePath == this.bundlePath &&
          other.isActive == this.isActive &&
          other.clinicalLeadId == this.clinicalLeadId &&
          other.approvalSignature == this.approvalSignature);
}

class RuleVersionsCompanion extends UpdateCompanion<RuleVersion> {
  final Value<String> id;
  final Value<String> versionString;
  final Value<int> publishedAt;
  final Value<String> bundleHash;
  final Value<String?> bundlePath;
  final Value<bool> isActive;
  final Value<String?> clinicalLeadId;
  final Value<String?> approvalSignature;
  final Value<int> rowid;
  const RuleVersionsCompanion({
    this.id = const Value.absent(),
    this.versionString = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.bundleHash = const Value.absent(),
    this.bundlePath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.clinicalLeadId = const Value.absent(),
    this.approvalSignature = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RuleVersionsCompanion.insert({
    required String id,
    required String versionString,
    required int publishedAt,
    required String bundleHash,
    this.bundlePath = const Value.absent(),
    this.isActive = const Value.absent(),
    this.clinicalLeadId = const Value.absent(),
    this.approvalSignature = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       versionString = Value(versionString),
       publishedAt = Value(publishedAt),
       bundleHash = Value(bundleHash);
  static Insertable<RuleVersion> custom({
    Expression<String>? id,
    Expression<String>? versionString,
    Expression<int>? publishedAt,
    Expression<String>? bundleHash,
    Expression<String>? bundlePath,
    Expression<bool>? isActive,
    Expression<String>? clinicalLeadId,
    Expression<String>? approvalSignature,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (versionString != null) 'version_string': versionString,
      if (publishedAt != null) 'published_at': publishedAt,
      if (bundleHash != null) 'bundle_hash': bundleHash,
      if (bundlePath != null) 'bundle_path': bundlePath,
      if (isActive != null) 'is_active': isActive,
      if (clinicalLeadId != null) 'clinical_lead_id': clinicalLeadId,
      if (approvalSignature != null) 'approval_signature': approvalSignature,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RuleVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? versionString,
    Value<int>? publishedAt,
    Value<String>? bundleHash,
    Value<String?>? bundlePath,
    Value<bool>? isActive,
    Value<String?>? clinicalLeadId,
    Value<String?>? approvalSignature,
    Value<int>? rowid,
  }) {
    return RuleVersionsCompanion(
      id: id ?? this.id,
      versionString: versionString ?? this.versionString,
      publishedAt: publishedAt ?? this.publishedAt,
      bundleHash: bundleHash ?? this.bundleHash,
      bundlePath: bundlePath ?? this.bundlePath,
      isActive: isActive ?? this.isActive,
      clinicalLeadId: clinicalLeadId ?? this.clinicalLeadId,
      approvalSignature: approvalSignature ?? this.approvalSignature,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (versionString.present) {
      map['version_string'] = Variable<String>(versionString.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<int>(publishedAt.value);
    }
    if (bundleHash.present) {
      map['bundle_hash'] = Variable<String>(bundleHash.value);
    }
    if (bundlePath.present) {
      map['bundle_path'] = Variable<String>(bundlePath.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (clinicalLeadId.present) {
      map['clinical_lead_id'] = Variable<String>(clinicalLeadId.value);
    }
    if (approvalSignature.present) {
      map['approval_signature'] = Variable<String>(approvalSignature.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RuleVersionsCompanion(')
          ..write('id: $id, ')
          ..write('versionString: $versionString, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('bundleHash: $bundleHash, ')
          ..write('bundlePath: $bundlePath, ')
          ..write('isActive: $isActive, ')
          ..write('clinicalLeadId: $clinicalLeadId, ')
          ..write('approvalSignature: $approvalSignature, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTableMeta = const VerificationMeta(
    'entityTable',
  );
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fieldNameMeta = const VerificationMeta(
    'fieldName',
  );
  @override
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
    'field_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _oldValueMeta = const VerificationMeta(
    'oldValue',
  );
  @override
  late final GeneratedColumn<String> oldValue = GeneratedColumn<String>(
    'old_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newValueMeta = const VerificationMeta(
    'newValue',
  );
  @override
  late final GeneratedColumn<String> newValue = GeneratedColumn<String>(
    'new_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _changedByMeta = const VerificationMeta(
    'changedBy',
  );
  @override
  late final GeneratedColumn<String> changedBy = GeneratedColumn<String>(
    'changed_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appVersionMeta = const VerificationMeta(
    'appVersion',
  );
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
    'app_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleVersionIdMeta = const VerificationMeta(
    'ruleVersionId',
  );
  @override
  late final GeneratedColumn<String> ruleVersionId = GeneratedColumn<String>(
    'rule_version_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deviceTimestampMeta = const VerificationMeta(
    'deviceTimestamp',
  );
  @override
  late final GeneratedColumn<int> deviceTimestamp = GeneratedColumn<int>(
    'device_timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverTimestampMeta = const VerificationMeta(
    'serverTimestamp',
  );
  @override
  late final GeneratedColumn<int> serverTimestamp = GeneratedColumn<int>(
    'server_timestamp',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _chainHashMeta = const VerificationMeta(
    'chainHash',
  );
  @override
  late final GeneratedColumn<String> chainHash = GeneratedColumn<String>(
    'chain_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityTable,
    recordId,
    fieldName,
    oldValue,
    newValue,
    changedBy,
    deviceId,
    appVersion,
    ruleVersionId,
    deviceTimestamp,
    serverTimestamp,
    chainHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('table_name')) {
      context.handle(
        _entityTableMeta,
        entityTable.isAcceptableOrUnknown(
          data['table_name']!,
          _entityTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('field_name')) {
      context.handle(
        _fieldNameMeta,
        fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta),
      );
    }
    if (data.containsKey('old_value')) {
      context.handle(
        _oldValueMeta,
        oldValue.isAcceptableOrUnknown(data['old_value']!, _oldValueMeta),
      );
    }
    if (data.containsKey('new_value')) {
      context.handle(
        _newValueMeta,
        newValue.isAcceptableOrUnknown(data['new_value']!, _newValueMeta),
      );
    }
    if (data.containsKey('changed_by')) {
      context.handle(
        _changedByMeta,
        changedBy.isAcceptableOrUnknown(data['changed_by']!, _changedByMeta),
      );
    } else if (isInserting) {
      context.missing(_changedByMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('app_version')) {
      context.handle(
        _appVersionMeta,
        appVersion.isAcceptableOrUnknown(data['app_version']!, _appVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_appVersionMeta);
    }
    if (data.containsKey('rule_version_id')) {
      context.handle(
        _ruleVersionIdMeta,
        ruleVersionId.isAcceptableOrUnknown(
          data['rule_version_id']!,
          _ruleVersionIdMeta,
        ),
      );
    }
    if (data.containsKey('device_timestamp')) {
      context.handle(
        _deviceTimestampMeta,
        deviceTimestamp.isAcceptableOrUnknown(
          data['device_timestamp']!,
          _deviceTimestampMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceTimestampMeta);
    }
    if (data.containsKey('server_timestamp')) {
      context.handle(
        _serverTimestampMeta,
        serverTimestamp.isAcceptableOrUnknown(
          data['server_timestamp']!,
          _serverTimestampMeta,
        ),
      );
    }
    if (data.containsKey('chain_hash')) {
      context.handle(
        _chainHashMeta,
        chainHash.isAcceptableOrUnknown(data['chain_hash']!, _chainHashMeta),
      );
    } else if (isInserting) {
      context.missing(_chainHashMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      fieldName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_name'],
      ),
      oldValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}old_value'],
      ),
      newValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}new_value'],
      ),
      changedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changed_by'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      appVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_version'],
      )!,
      ruleVersionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_version_id'],
      ),
      deviceTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}device_timestamp'],
      )!,
      serverTimestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_timestamp'],
      ),
      chainHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chain_hash'],
      )!,
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }
}

class AuditLogData extends DataClass implements Insertable<AuditLogData> {
  final String id;
  final String entityTable;
  final String recordId;
  final String? fieldName;
  final String? oldValue;
  final String? newValue;
  final String changedBy;
  final String deviceId;
  final String appVersion;
  final String? ruleVersionId;
  final int deviceTimestamp;
  final int? serverTimestamp;
  final String chainHash;
  const AuditLogData({
    required this.id,
    required this.entityTable,
    required this.recordId,
    this.fieldName,
    this.oldValue,
    this.newValue,
    required this.changedBy,
    required this.deviceId,
    required this.appVersion,
    this.ruleVersionId,
    required this.deviceTimestamp,
    this.serverTimestamp,
    required this.chainHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['table_name'] = Variable<String>(entityTable);
    map['record_id'] = Variable<String>(recordId);
    if (!nullToAbsent || fieldName != null) {
      map['field_name'] = Variable<String>(fieldName);
    }
    if (!nullToAbsent || oldValue != null) {
      map['old_value'] = Variable<String>(oldValue);
    }
    if (!nullToAbsent || newValue != null) {
      map['new_value'] = Variable<String>(newValue);
    }
    map['changed_by'] = Variable<String>(changedBy);
    map['device_id'] = Variable<String>(deviceId);
    map['app_version'] = Variable<String>(appVersion);
    if (!nullToAbsent || ruleVersionId != null) {
      map['rule_version_id'] = Variable<String>(ruleVersionId);
    }
    map['device_timestamp'] = Variable<int>(deviceTimestamp);
    if (!nullToAbsent || serverTimestamp != null) {
      map['server_timestamp'] = Variable<int>(serverTimestamp);
    }
    map['chain_hash'] = Variable<String>(chainHash);
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      entityTable: Value(entityTable),
      recordId: Value(recordId),
      fieldName: fieldName == null && nullToAbsent
          ? const Value.absent()
          : Value(fieldName),
      oldValue: oldValue == null && nullToAbsent
          ? const Value.absent()
          : Value(oldValue),
      newValue: newValue == null && nullToAbsent
          ? const Value.absent()
          : Value(newValue),
      changedBy: Value(changedBy),
      deviceId: Value(deviceId),
      appVersion: Value(appVersion),
      ruleVersionId: ruleVersionId == null && nullToAbsent
          ? const Value.absent()
          : Value(ruleVersionId),
      deviceTimestamp: Value(deviceTimestamp),
      serverTimestamp: serverTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(serverTimestamp),
      chainHash: Value(chainHash),
    );
  }

  factory AuditLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogData(
      id: serializer.fromJson<String>(json['id']),
      entityTable: serializer.fromJson<String>(json['entityTable']),
      recordId: serializer.fromJson<String>(json['recordId']),
      fieldName: serializer.fromJson<String?>(json['fieldName']),
      oldValue: serializer.fromJson<String?>(json['oldValue']),
      newValue: serializer.fromJson<String?>(json['newValue']),
      changedBy: serializer.fromJson<String>(json['changedBy']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      appVersion: serializer.fromJson<String>(json['appVersion']),
      ruleVersionId: serializer.fromJson<String?>(json['ruleVersionId']),
      deviceTimestamp: serializer.fromJson<int>(json['deviceTimestamp']),
      serverTimestamp: serializer.fromJson<int?>(json['serverTimestamp']),
      chainHash: serializer.fromJson<String>(json['chainHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityTable': serializer.toJson<String>(entityTable),
      'recordId': serializer.toJson<String>(recordId),
      'fieldName': serializer.toJson<String?>(fieldName),
      'oldValue': serializer.toJson<String?>(oldValue),
      'newValue': serializer.toJson<String?>(newValue),
      'changedBy': serializer.toJson<String>(changedBy),
      'deviceId': serializer.toJson<String>(deviceId),
      'appVersion': serializer.toJson<String>(appVersion),
      'ruleVersionId': serializer.toJson<String?>(ruleVersionId),
      'deviceTimestamp': serializer.toJson<int>(deviceTimestamp),
      'serverTimestamp': serializer.toJson<int?>(serverTimestamp),
      'chainHash': serializer.toJson<String>(chainHash),
    };
  }

  AuditLogData copyWith({
    String? id,
    String? entityTable,
    String? recordId,
    Value<String?> fieldName = const Value.absent(),
    Value<String?> oldValue = const Value.absent(),
    Value<String?> newValue = const Value.absent(),
    String? changedBy,
    String? deviceId,
    String? appVersion,
    Value<String?> ruleVersionId = const Value.absent(),
    int? deviceTimestamp,
    Value<int?> serverTimestamp = const Value.absent(),
    String? chainHash,
  }) => AuditLogData(
    id: id ?? this.id,
    entityTable: entityTable ?? this.entityTable,
    recordId: recordId ?? this.recordId,
    fieldName: fieldName.present ? fieldName.value : this.fieldName,
    oldValue: oldValue.present ? oldValue.value : this.oldValue,
    newValue: newValue.present ? newValue.value : this.newValue,
    changedBy: changedBy ?? this.changedBy,
    deviceId: deviceId ?? this.deviceId,
    appVersion: appVersion ?? this.appVersion,
    ruleVersionId: ruleVersionId.present
        ? ruleVersionId.value
        : this.ruleVersionId,
    deviceTimestamp: deviceTimestamp ?? this.deviceTimestamp,
    serverTimestamp: serverTimestamp.present
        ? serverTimestamp.value
        : this.serverTimestamp,
    chainHash: chainHash ?? this.chainHash,
  );
  AuditLogData copyWithCompanion(AuditLogCompanion data) {
    return AuditLogData(
      id: data.id.present ? data.id.value : this.id,
      entityTable: data.entityTable.present
          ? data.entityTable.value
          : this.entityTable,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      oldValue: data.oldValue.present ? data.oldValue.value : this.oldValue,
      newValue: data.newValue.present ? data.newValue.value : this.newValue,
      changedBy: data.changedBy.present ? data.changedBy.value : this.changedBy,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      appVersion: data.appVersion.present
          ? data.appVersion.value
          : this.appVersion,
      ruleVersionId: data.ruleVersionId.present
          ? data.ruleVersionId.value
          : this.ruleVersionId,
      deviceTimestamp: data.deviceTimestamp.present
          ? data.deviceTimestamp.value
          : this.deviceTimestamp,
      serverTimestamp: data.serverTimestamp.present
          ? data.serverTimestamp.value
          : this.serverTimestamp,
      chainHash: data.chainHash.present ? data.chainHash.value : this.chainHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogData(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('recordId: $recordId, ')
          ..write('fieldName: $fieldName, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('changedBy: $changedBy, ')
          ..write('deviceId: $deviceId, ')
          ..write('appVersion: $appVersion, ')
          ..write('ruleVersionId: $ruleVersionId, ')
          ..write('deviceTimestamp: $deviceTimestamp, ')
          ..write('serverTimestamp: $serverTimestamp, ')
          ..write('chainHash: $chainHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityTable,
    recordId,
    fieldName,
    oldValue,
    newValue,
    changedBy,
    deviceId,
    appVersion,
    ruleVersionId,
    deviceTimestamp,
    serverTimestamp,
    chainHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogData &&
          other.id == this.id &&
          other.entityTable == this.entityTable &&
          other.recordId == this.recordId &&
          other.fieldName == this.fieldName &&
          other.oldValue == this.oldValue &&
          other.newValue == this.newValue &&
          other.changedBy == this.changedBy &&
          other.deviceId == this.deviceId &&
          other.appVersion == this.appVersion &&
          other.ruleVersionId == this.ruleVersionId &&
          other.deviceTimestamp == this.deviceTimestamp &&
          other.serverTimestamp == this.serverTimestamp &&
          other.chainHash == this.chainHash);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogData> {
  final Value<String> id;
  final Value<String> entityTable;
  final Value<String> recordId;
  final Value<String?> fieldName;
  final Value<String?> oldValue;
  final Value<String?> newValue;
  final Value<String> changedBy;
  final Value<String> deviceId;
  final Value<String> appVersion;
  final Value<String?> ruleVersionId;
  final Value<int> deviceTimestamp;
  final Value<int?> serverTimestamp;
  final Value<String> chainHash;
  final Value<int> rowid;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.recordId = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    this.changedBy = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.ruleVersionId = const Value.absent(),
    this.deviceTimestamp = const Value.absent(),
    this.serverTimestamp = const Value.absent(),
    this.chainHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuditLogCompanion.insert({
    required String id,
    required String entityTable,
    required String recordId,
    this.fieldName = const Value.absent(),
    this.oldValue = const Value.absent(),
    this.newValue = const Value.absent(),
    required String changedBy,
    required String deviceId,
    required String appVersion,
    this.ruleVersionId = const Value.absent(),
    required int deviceTimestamp,
    this.serverTimestamp = const Value.absent(),
    required String chainHash,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityTable = Value(entityTable),
       recordId = Value(recordId),
       changedBy = Value(changedBy),
       deviceId = Value(deviceId),
       appVersion = Value(appVersion),
       deviceTimestamp = Value(deviceTimestamp),
       chainHash = Value(chainHash);
  static Insertable<AuditLogData> custom({
    Expression<String>? id,
    Expression<String>? entityTable,
    Expression<String>? recordId,
    Expression<String>? fieldName,
    Expression<String>? oldValue,
    Expression<String>? newValue,
    Expression<String>? changedBy,
    Expression<String>? deviceId,
    Expression<String>? appVersion,
    Expression<String>? ruleVersionId,
    Expression<int>? deviceTimestamp,
    Expression<int>? serverTimestamp,
    Expression<String>? chainHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityTable != null) 'table_name': entityTable,
      if (recordId != null) 'record_id': recordId,
      if (fieldName != null) 'field_name': fieldName,
      if (oldValue != null) 'old_value': oldValue,
      if (newValue != null) 'new_value': newValue,
      if (changedBy != null) 'changed_by': changedBy,
      if (deviceId != null) 'device_id': deviceId,
      if (appVersion != null) 'app_version': appVersion,
      if (ruleVersionId != null) 'rule_version_id': ruleVersionId,
      if (deviceTimestamp != null) 'device_timestamp': deviceTimestamp,
      if (serverTimestamp != null) 'server_timestamp': serverTimestamp,
      if (chainHash != null) 'chain_hash': chainHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuditLogCompanion copyWith({
    Value<String>? id,
    Value<String>? entityTable,
    Value<String>? recordId,
    Value<String?>? fieldName,
    Value<String?>? oldValue,
    Value<String?>? newValue,
    Value<String>? changedBy,
    Value<String>? deviceId,
    Value<String>? appVersion,
    Value<String?>? ruleVersionId,
    Value<int>? deviceTimestamp,
    Value<int?>? serverTimestamp,
    Value<String>? chainHash,
    Value<int>? rowid,
  }) {
    return AuditLogCompanion(
      id: id ?? this.id,
      entityTable: entityTable ?? this.entityTable,
      recordId: recordId ?? this.recordId,
      fieldName: fieldName ?? this.fieldName,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      changedBy: changedBy ?? this.changedBy,
      deviceId: deviceId ?? this.deviceId,
      appVersion: appVersion ?? this.appVersion,
      ruleVersionId: ruleVersionId ?? this.ruleVersionId,
      deviceTimestamp: deviceTimestamp ?? this.deviceTimestamp,
      serverTimestamp: serverTimestamp ?? this.serverTimestamp,
      chainHash: chainHash ?? this.chainHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityTable.present) {
      map['table_name'] = Variable<String>(entityTable.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (oldValue.present) {
      map['old_value'] = Variable<String>(oldValue.value);
    }
    if (newValue.present) {
      map['new_value'] = Variable<String>(newValue.value);
    }
    if (changedBy.present) {
      map['changed_by'] = Variable<String>(changedBy.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (ruleVersionId.present) {
      map['rule_version_id'] = Variable<String>(ruleVersionId.value);
    }
    if (deviceTimestamp.present) {
      map['device_timestamp'] = Variable<int>(deviceTimestamp.value);
    }
    if (serverTimestamp.present) {
      map['server_timestamp'] = Variable<int>(serverTimestamp.value);
    }
    if (chainHash.present) {
      map['chain_hash'] = Variable<String>(chainHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('entityTable: $entityTable, ')
          ..write('recordId: $recordId, ')
          ..write('fieldName: $fieldName, ')
          ..write('oldValue: $oldValue, ')
          ..write('newValue: $newValue, ')
          ..write('changedBy: $changedBy, ')
          ..write('deviceId: $deviceId, ')
          ..write('appVersion: $appVersion, ')
          ..write('ruleVersionId: $ruleVersionId, ')
          ..write('deviceTimestamp: $deviceTimestamp, ')
          ..write('serverTimestamp: $serverTimestamp, ')
          ..write('chainHash: $chainHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DraftsTable extends Drafts with TableInfo<$DraftsTable, Draft> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DraftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formTypeMeta = const VerificationMeta(
    'formType',
  );
  @override
  late final GeneratedColumn<String> formType = GeneratedColumn<String>(
    'form_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _partialDataJsonMeta = const VerificationMeta(
    'partialDataJson',
  );
  @override
  late final GeneratedColumn<String> partialDataJson = GeneratedColumn<String>(
    'partial_data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastModifiedAtMeta = const VerificationMeta(
    'lastModifiedAt',
  );
  @override
  late final GeneratedColumn<int> lastModifiedAt = GeneratedColumn<int>(
    'last_modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recoveryCountMeta = const VerificationMeta(
    'recoveryCount',
  );
  @override
  late final GeneratedColumn<int> recoveryCount = GeneratedColumn<int>(
    'recovery_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    formType,
    memberId,
    partialDataJson,
    lastModifiedAt,
    recoveryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drafts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Draft> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('form_type')) {
      context.handle(
        _formTypeMeta,
        formType.isAcceptableOrUnknown(data['form_type']!, _formTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_formTypeMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    }
    if (data.containsKey('partial_data_json')) {
      context.handle(
        _partialDataJsonMeta,
        partialDataJson.isAcceptableOrUnknown(
          data['partial_data_json']!,
          _partialDataJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_partialDataJsonMeta);
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
        _lastModifiedAtMeta,
        lastModifiedAt.isAcceptableOrUnknown(
          data['last_modified_at']!,
          _lastModifiedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedAtMeta);
    }
    if (data.containsKey('recovery_count')) {
      context.handle(
        _recoveryCountMeta,
        recoveryCount.isAcceptableOrUnknown(
          data['recovery_count']!,
          _recoveryCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Draft map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Draft(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      formType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}form_type'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      ),
      partialDataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}partial_data_json'],
      )!,
      lastModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_modified_at'],
      )!,
      recoveryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recovery_count'],
      )!,
    );
  }

  @override
  $DraftsTable createAlias(String alias) {
    return $DraftsTable(attachedDatabase, alias);
  }
}

class Draft extends DataClass implements Insertable<Draft> {
  final String id;
  final String formType;
  final String? memberId;
  final String partialDataJson;
  final int lastModifiedAt;
  final int recoveryCount;
  const Draft({
    required this.id,
    required this.formType,
    this.memberId,
    required this.partialDataJson,
    required this.lastModifiedAt,
    required this.recoveryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['form_type'] = Variable<String>(formType);
    if (!nullToAbsent || memberId != null) {
      map['member_id'] = Variable<String>(memberId);
    }
    map['partial_data_json'] = Variable<String>(partialDataJson);
    map['last_modified_at'] = Variable<int>(lastModifiedAt);
    map['recovery_count'] = Variable<int>(recoveryCount);
    return map;
  }

  DraftsCompanion toCompanion(bool nullToAbsent) {
    return DraftsCompanion(
      id: Value(id),
      formType: Value(formType),
      memberId: memberId == null && nullToAbsent
          ? const Value.absent()
          : Value(memberId),
      partialDataJson: Value(partialDataJson),
      lastModifiedAt: Value(lastModifiedAt),
      recoveryCount: Value(recoveryCount),
    );
  }

  factory Draft.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Draft(
      id: serializer.fromJson<String>(json['id']),
      formType: serializer.fromJson<String>(json['formType']),
      memberId: serializer.fromJson<String?>(json['memberId']),
      partialDataJson: serializer.fromJson<String>(json['partialDataJson']),
      lastModifiedAt: serializer.fromJson<int>(json['lastModifiedAt']),
      recoveryCount: serializer.fromJson<int>(json['recoveryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'formType': serializer.toJson<String>(formType),
      'memberId': serializer.toJson<String?>(memberId),
      'partialDataJson': serializer.toJson<String>(partialDataJson),
      'lastModifiedAt': serializer.toJson<int>(lastModifiedAt),
      'recoveryCount': serializer.toJson<int>(recoveryCount),
    };
  }

  Draft copyWith({
    String? id,
    String? formType,
    Value<String?> memberId = const Value.absent(),
    String? partialDataJson,
    int? lastModifiedAt,
    int? recoveryCount,
  }) => Draft(
    id: id ?? this.id,
    formType: formType ?? this.formType,
    memberId: memberId.present ? memberId.value : this.memberId,
    partialDataJson: partialDataJson ?? this.partialDataJson,
    lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    recoveryCount: recoveryCount ?? this.recoveryCount,
  );
  Draft copyWithCompanion(DraftsCompanion data) {
    return Draft(
      id: data.id.present ? data.id.value : this.id,
      formType: data.formType.present ? data.formType.value : this.formType,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      partialDataJson: data.partialDataJson.present
          ? data.partialDataJson.value
          : this.partialDataJson,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      recoveryCount: data.recoveryCount.present
          ? data.recoveryCount.value
          : this.recoveryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Draft(')
          ..write('id: $id, ')
          ..write('formType: $formType, ')
          ..write('memberId: $memberId, ')
          ..write('partialDataJson: $partialDataJson, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('recoveryCount: $recoveryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    formType,
    memberId,
    partialDataJson,
    lastModifiedAt,
    recoveryCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Draft &&
          other.id == this.id &&
          other.formType == this.formType &&
          other.memberId == this.memberId &&
          other.partialDataJson == this.partialDataJson &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.recoveryCount == this.recoveryCount);
}

class DraftsCompanion extends UpdateCompanion<Draft> {
  final Value<String> id;
  final Value<String> formType;
  final Value<String?> memberId;
  final Value<String> partialDataJson;
  final Value<int> lastModifiedAt;
  final Value<int> recoveryCount;
  final Value<int> rowid;
  const DraftsCompanion({
    this.id = const Value.absent(),
    this.formType = const Value.absent(),
    this.memberId = const Value.absent(),
    this.partialDataJson = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.recoveryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DraftsCompanion.insert({
    required String id,
    required String formType,
    this.memberId = const Value.absent(),
    required String partialDataJson,
    required int lastModifiedAt,
    this.recoveryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       formType = Value(formType),
       partialDataJson = Value(partialDataJson),
       lastModifiedAt = Value(lastModifiedAt);
  static Insertable<Draft> custom({
    Expression<String>? id,
    Expression<String>? formType,
    Expression<String>? memberId,
    Expression<String>? partialDataJson,
    Expression<int>? lastModifiedAt,
    Expression<int>? recoveryCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (formType != null) 'form_type': formType,
      if (memberId != null) 'member_id': memberId,
      if (partialDataJson != null) 'partial_data_json': partialDataJson,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (recoveryCount != null) 'recovery_count': recoveryCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DraftsCompanion copyWith({
    Value<String>? id,
    Value<String>? formType,
    Value<String?>? memberId,
    Value<String>? partialDataJson,
    Value<int>? lastModifiedAt,
    Value<int>? recoveryCount,
    Value<int>? rowid,
  }) {
    return DraftsCompanion(
      id: id ?? this.id,
      formType: formType ?? this.formType,
      memberId: memberId ?? this.memberId,
      partialDataJson: partialDataJson ?? this.partialDataJson,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      recoveryCount: recoveryCount ?? this.recoveryCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (formType.present) {
      map['form_type'] = Variable<String>(formType.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (partialDataJson.present) {
      map['partial_data_json'] = Variable<String>(partialDataJson.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<int>(lastModifiedAt.value);
    }
    if (recoveryCount.present) {
      map['recovery_count'] = Variable<int>(recoveryCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DraftsCompanion(')
          ..write('id: $id, ')
          ..write('formType: $formType, ')
          ..write('memberId: $memberId, ')
          ..write('partialDataJson: $partialDataJson, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('recoveryCount: $recoveryCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockItemsTable extends StockItems
    with TableInfo<$StockItemsTable, StockItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workerIdMeta = const VerificationMeta(
    'workerId',
  );
  @override
  late final GeneratedColumn<String> workerId = GeneratedColumn<String>(
    'worker_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemCodeMeta = const VerificationMeta(
    'itemCode',
  );
  @override
  late final GeneratedColumn<String> itemCode = GeneratedColumn<String>(
    'item_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemNameMeta = const VerificationMeta(
    'itemName',
  );
  @override
  late final GeneratedColumn<String> itemName = GeneratedColumn<String>(
    'item_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _minThresholdMeta = const VerificationMeta(
    'minThreshold',
  );
  @override
  late final GeneratedColumn<double> minThreshold = GeneratedColumn<double>(
    'min_threshold',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(5.0),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> lastUpdatedAt = GeneratedColumn<int>(
    'last_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workerId,
    itemCode,
    itemName,
    quantity,
    minThreshold,
    unit,
    lastUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('worker_id')) {
      context.handle(
        _workerIdMeta,
        workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workerIdMeta);
    }
    if (data.containsKey('item_code')) {
      context.handle(
        _itemCodeMeta,
        itemCode.isAcceptableOrUnknown(data['item_code']!, _itemCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCodeMeta);
    }
    if (data.containsKey('item_name')) {
      context.handle(
        _itemNameMeta,
        itemName.isAcceptableOrUnknown(data['item_name']!, _itemNameMeta),
      );
    } else if (isInserting) {
      context.missing(_itemNameMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('min_threshold')) {
      context.handle(
        _minThresholdMeta,
        minThreshold.isAcceptableOrUnknown(
          data['min_threshold']!,
          _minThresholdMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_id'],
      )!,
      itemCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_code'],
      )!,
      itemName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_name'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      minThreshold: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_threshold'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_updated_at'],
      )!,
    );
  }

  @override
  $StockItemsTable createAlias(String alias) {
    return $StockItemsTable(attachedDatabase, alias);
  }
}

class StockItem extends DataClass implements Insertable<StockItem> {
  final String id;
  final String workerId;
  final String itemCode;
  final String itemName;
  final double quantity;
  final double minThreshold;
  final String unit;
  final int lastUpdatedAt;
  const StockItem({
    required this.id,
    required this.workerId,
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    required this.minThreshold,
    required this.unit,
    required this.lastUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['worker_id'] = Variable<String>(workerId);
    map['item_code'] = Variable<String>(itemCode);
    map['item_name'] = Variable<String>(itemName);
    map['quantity'] = Variable<double>(quantity);
    map['min_threshold'] = Variable<double>(minThreshold);
    map['unit'] = Variable<String>(unit);
    map['last_updated_at'] = Variable<int>(lastUpdatedAt);
    return map;
  }

  StockItemsCompanion toCompanion(bool nullToAbsent) {
    return StockItemsCompanion(
      id: Value(id),
      workerId: Value(workerId),
      itemCode: Value(itemCode),
      itemName: Value(itemName),
      quantity: Value(quantity),
      minThreshold: Value(minThreshold),
      unit: Value(unit),
      lastUpdatedAt: Value(lastUpdatedAt),
    );
  }

  factory StockItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockItem(
      id: serializer.fromJson<String>(json['id']),
      workerId: serializer.fromJson<String>(json['workerId']),
      itemCode: serializer.fromJson<String>(json['itemCode']),
      itemName: serializer.fromJson<String>(json['itemName']),
      quantity: serializer.fromJson<double>(json['quantity']),
      minThreshold: serializer.fromJson<double>(json['minThreshold']),
      unit: serializer.fromJson<String>(json['unit']),
      lastUpdatedAt: serializer.fromJson<int>(json['lastUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workerId': serializer.toJson<String>(workerId),
      'itemCode': serializer.toJson<String>(itemCode),
      'itemName': serializer.toJson<String>(itemName),
      'quantity': serializer.toJson<double>(quantity),
      'minThreshold': serializer.toJson<double>(minThreshold),
      'unit': serializer.toJson<String>(unit),
      'lastUpdatedAt': serializer.toJson<int>(lastUpdatedAt),
    };
  }

  StockItem copyWith({
    String? id,
    String? workerId,
    String? itemCode,
    String? itemName,
    double? quantity,
    double? minThreshold,
    String? unit,
    int? lastUpdatedAt,
  }) => StockItem(
    id: id ?? this.id,
    workerId: workerId ?? this.workerId,
    itemCode: itemCode ?? this.itemCode,
    itemName: itemName ?? this.itemName,
    quantity: quantity ?? this.quantity,
    minThreshold: minThreshold ?? this.minThreshold,
    unit: unit ?? this.unit,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );
  StockItem copyWithCompanion(StockItemsCompanion data) {
    return StockItem(
      id: data.id.present ? data.id.value : this.id,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      itemCode: data.itemCode.present ? data.itemCode.value : this.itemCode,
      itemName: data.itemName.present ? data.itemName.value : this.itemName,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      minThreshold: data.minThreshold.present
          ? data.minThreshold.value
          : this.minThreshold,
      unit: data.unit.present ? data.unit.value : this.unit,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockItem(')
          ..write('id: $id, ')
          ..write('workerId: $workerId, ')
          ..write('itemCode: $itemCode, ')
          ..write('itemName: $itemName, ')
          ..write('quantity: $quantity, ')
          ..write('minThreshold: $minThreshold, ')
          ..write('unit: $unit, ')
          ..write('lastUpdatedAt: $lastUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workerId,
    itemCode,
    itemName,
    quantity,
    minThreshold,
    unit,
    lastUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockItem &&
          other.id == this.id &&
          other.workerId == this.workerId &&
          other.itemCode == this.itemCode &&
          other.itemName == this.itemName &&
          other.quantity == this.quantity &&
          other.minThreshold == this.minThreshold &&
          other.unit == this.unit &&
          other.lastUpdatedAt == this.lastUpdatedAt);
}

class StockItemsCompanion extends UpdateCompanion<StockItem> {
  final Value<String> id;
  final Value<String> workerId;
  final Value<String> itemCode;
  final Value<String> itemName;
  final Value<double> quantity;
  final Value<double> minThreshold;
  final Value<String> unit;
  final Value<int> lastUpdatedAt;
  final Value<int> rowid;
  const StockItemsCompanion({
    this.id = const Value.absent(),
    this.workerId = const Value.absent(),
    this.itemCode = const Value.absent(),
    this.itemName = const Value.absent(),
    this.quantity = const Value.absent(),
    this.minThreshold = const Value.absent(),
    this.unit = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockItemsCompanion.insert({
    required String id,
    required String workerId,
    required String itemCode,
    required String itemName,
    this.quantity = const Value.absent(),
    this.minThreshold = const Value.absent(),
    required String unit,
    required int lastUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workerId = Value(workerId),
       itemCode = Value(itemCode),
       itemName = Value(itemName),
       unit = Value(unit),
       lastUpdatedAt = Value(lastUpdatedAt);
  static Insertable<StockItem> custom({
    Expression<String>? id,
    Expression<String>? workerId,
    Expression<String>? itemCode,
    Expression<String>? itemName,
    Expression<double>? quantity,
    Expression<double>? minThreshold,
    Expression<String>? unit,
    Expression<int>? lastUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workerId != null) 'worker_id': workerId,
      if (itemCode != null) 'item_code': itemCode,
      if (itemName != null) 'item_name': itemName,
      if (quantity != null) 'quantity': quantity,
      if (minThreshold != null) 'min_threshold': minThreshold,
      if (unit != null) 'unit': unit,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? workerId,
    Value<String>? itemCode,
    Value<String>? itemName,
    Value<double>? quantity,
    Value<double>? minThreshold,
    Value<String>? unit,
    Value<int>? lastUpdatedAt,
    Value<int>? rowid,
  }) {
    return StockItemsCompanion(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      quantity: quantity ?? this.quantity,
      minThreshold: minThreshold ?? this.minThreshold,
      unit: unit ?? this.unit,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<String>(workerId.value);
    }
    if (itemCode.present) {
      map['item_code'] = Variable<String>(itemCode.value);
    }
    if (itemName.present) {
      map['item_name'] = Variable<String>(itemName.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (minThreshold.present) {
      map['min_threshold'] = Variable<double>(minThreshold.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<int>(lastUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockItemsCompanion(')
          ..write('id: $id, ')
          ..write('workerId: $workerId, ')
          ..write('itemCode: $itemCode, ')
          ..write('itemName: $itemName, ')
          ..write('quantity: $quantity, ')
          ..write('minThreshold: $minThreshold, ')
          ..write('unit: $unit, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockTransactionsTable extends StockTransactions
    with TableInfo<$StockTransactionsTable, StockTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stock_items (id)',
    ),
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityDeltaMeta = const VerificationMeta(
    'quantityDelta',
  );
  @override
  late final GeneratedColumn<double> quantityDelta = GeneratedColumn<double>(
    'quantity_delta',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relatedEncounterIdMeta =
      const VerificationMeta('relatedEncounterId');
  @override
  late final GeneratedColumn<String> relatedEncounterId =
      GeneratedColumn<String>(
        'related_encounter_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _relatedMemberIdMeta = const VerificationMeta(
    'relatedMemberId',
  );
  @override
  late final GeneratedColumn<String> relatedMemberId = GeneratedColumn<String>(
    'related_member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<int> recordedAt = GeneratedColumn<int>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    transactionType,
    quantityDelta,
    relatedEncounterId,
    relatedMemberId,
    recordedAt,
    syncStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('quantity_delta')) {
      context.handle(
        _quantityDeltaMeta,
        quantityDelta.isAcceptableOrUnknown(
          data['quantity_delta']!,
          _quantityDeltaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityDeltaMeta);
    }
    if (data.containsKey('related_encounter_id')) {
      context.handle(
        _relatedEncounterIdMeta,
        relatedEncounterId.isAcceptableOrUnknown(
          data['related_encounter_id']!,
          _relatedEncounterIdMeta,
        ),
      );
    }
    if (data.containsKey('related_member_id')) {
      context.handle(
        _relatedMemberIdMeta,
        relatedMemberId.isAcceptableOrUnknown(
          data['related_member_id']!,
          _relatedMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      quantityDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity_delta'],
      )!,
      relatedEncounterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_encounter_id'],
      ),
      relatedMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}related_member_id'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_at'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
    );
  }

  @override
  $StockTransactionsTable createAlias(String alias) {
    return $StockTransactionsTable(attachedDatabase, alias);
  }
}

class StockTransaction extends DataClass
    implements Insertable<StockTransaction> {
  final String id;
  final String itemId;
  final String transactionType;
  final double quantityDelta;
  final String? relatedEncounterId;
  final String? relatedMemberId;
  final int recordedAt;
  final String syncStatus;
  const StockTransaction({
    required this.id,
    required this.itemId,
    required this.transactionType,
    required this.quantityDelta,
    this.relatedEncounterId,
    this.relatedMemberId,
    required this.recordedAt,
    required this.syncStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['item_id'] = Variable<String>(itemId);
    map['transaction_type'] = Variable<String>(transactionType);
    map['quantity_delta'] = Variable<double>(quantityDelta);
    if (!nullToAbsent || relatedEncounterId != null) {
      map['related_encounter_id'] = Variable<String>(relatedEncounterId);
    }
    if (!nullToAbsent || relatedMemberId != null) {
      map['related_member_id'] = Variable<String>(relatedMemberId);
    }
    map['recorded_at'] = Variable<int>(recordedAt);
    map['sync_status'] = Variable<String>(syncStatus);
    return map;
  }

  StockTransactionsCompanion toCompanion(bool nullToAbsent) {
    return StockTransactionsCompanion(
      id: Value(id),
      itemId: Value(itemId),
      transactionType: Value(transactionType),
      quantityDelta: Value(quantityDelta),
      relatedEncounterId: relatedEncounterId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedEncounterId),
      relatedMemberId: relatedMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(relatedMemberId),
      recordedAt: Value(recordedAt),
      syncStatus: Value(syncStatus),
    );
  }

  factory StockTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockTransaction(
      id: serializer.fromJson<String>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      quantityDelta: serializer.fromJson<double>(json['quantityDelta']),
      relatedEncounterId: serializer.fromJson<String?>(
        json['relatedEncounterId'],
      ),
      relatedMemberId: serializer.fromJson<String?>(json['relatedMemberId']),
      recordedAt: serializer.fromJson<int>(json['recordedAt']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'itemId': serializer.toJson<String>(itemId),
      'transactionType': serializer.toJson<String>(transactionType),
      'quantityDelta': serializer.toJson<double>(quantityDelta),
      'relatedEncounterId': serializer.toJson<String?>(relatedEncounterId),
      'relatedMemberId': serializer.toJson<String?>(relatedMemberId),
      'recordedAt': serializer.toJson<int>(recordedAt),
      'syncStatus': serializer.toJson<String>(syncStatus),
    };
  }

  StockTransaction copyWith({
    String? id,
    String? itemId,
    String? transactionType,
    double? quantityDelta,
    Value<String?> relatedEncounterId = const Value.absent(),
    Value<String?> relatedMemberId = const Value.absent(),
    int? recordedAt,
    String? syncStatus,
  }) => StockTransaction(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    transactionType: transactionType ?? this.transactionType,
    quantityDelta: quantityDelta ?? this.quantityDelta,
    relatedEncounterId: relatedEncounterId.present
        ? relatedEncounterId.value
        : this.relatedEncounterId,
    relatedMemberId: relatedMemberId.present
        ? relatedMemberId.value
        : this.relatedMemberId,
    recordedAt: recordedAt ?? this.recordedAt,
    syncStatus: syncStatus ?? this.syncStatus,
  );
  StockTransaction copyWithCompanion(StockTransactionsCompanion data) {
    return StockTransaction(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      quantityDelta: data.quantityDelta.present
          ? data.quantityDelta.value
          : this.quantityDelta,
      relatedEncounterId: data.relatedEncounterId.present
          ? data.relatedEncounterId.value
          : this.relatedEncounterId,
      relatedMemberId: data.relatedMemberId.present
          ? data.relatedMemberId.value
          : this.relatedMemberId,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockTransaction(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('transactionType: $transactionType, ')
          ..write('quantityDelta: $quantityDelta, ')
          ..write('relatedEncounterId: $relatedEncounterId, ')
          ..write('relatedMemberId: $relatedMemberId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncStatus: $syncStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    itemId,
    transactionType,
    quantityDelta,
    relatedEncounterId,
    relatedMemberId,
    recordedAt,
    syncStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockTransaction &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.transactionType == this.transactionType &&
          other.quantityDelta == this.quantityDelta &&
          other.relatedEncounterId == this.relatedEncounterId &&
          other.relatedMemberId == this.relatedMemberId &&
          other.recordedAt == this.recordedAt &&
          other.syncStatus == this.syncStatus);
}

class StockTransactionsCompanion extends UpdateCompanion<StockTransaction> {
  final Value<String> id;
  final Value<String> itemId;
  final Value<String> transactionType;
  final Value<double> quantityDelta;
  final Value<String?> relatedEncounterId;
  final Value<String?> relatedMemberId;
  final Value<int> recordedAt;
  final Value<String> syncStatus;
  final Value<int> rowid;
  const StockTransactionsCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.quantityDelta = const Value.absent(),
    this.relatedEncounterId = const Value.absent(),
    this.relatedMemberId = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockTransactionsCompanion.insert({
    required String id,
    required String itemId,
    required String transactionType,
    required double quantityDelta,
    this.relatedEncounterId = const Value.absent(),
    this.relatedMemberId = const Value.absent(),
    required int recordedAt,
    this.syncStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       itemId = Value(itemId),
       transactionType = Value(transactionType),
       quantityDelta = Value(quantityDelta),
       recordedAt = Value(recordedAt);
  static Insertable<StockTransaction> custom({
    Expression<String>? id,
    Expression<String>? itemId,
    Expression<String>? transactionType,
    Expression<double>? quantityDelta,
    Expression<String>? relatedEncounterId,
    Expression<String>? relatedMemberId,
    Expression<int>? recordedAt,
    Expression<String>? syncStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (transactionType != null) 'transaction_type': transactionType,
      if (quantityDelta != null) 'quantity_delta': quantityDelta,
      if (relatedEncounterId != null)
        'related_encounter_id': relatedEncounterId,
      if (relatedMemberId != null) 'related_member_id': relatedMemberId,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? itemId,
    Value<String>? transactionType,
    Value<double>? quantityDelta,
    Value<String?>? relatedEncounterId,
    Value<String?>? relatedMemberId,
    Value<int>? recordedAt,
    Value<String>? syncStatus,
    Value<int>? rowid,
  }) {
    return StockTransactionsCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      transactionType: transactionType ?? this.transactionType,
      quantityDelta: quantityDelta ?? this.quantityDelta,
      relatedEncounterId: relatedEncounterId ?? this.relatedEncounterId,
      relatedMemberId: relatedMemberId ?? this.relatedMemberId,
      recordedAt: recordedAt ?? this.recordedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (quantityDelta.present) {
      map['quantity_delta'] = Variable<double>(quantityDelta.value);
    }
    if (relatedEncounterId.present) {
      map['related_encounter_id'] = Variable<String>(relatedEncounterId.value);
    }
    if (relatedMemberId.present) {
      map['related_member_id'] = Variable<String>(relatedMemberId.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<int>(recordedAt.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('transactionType: $transactionType, ')
          ..write('quantityDelta: $quantityDelta, ')
          ..write('relatedEncounterId: $relatedEncounterId, ')
          ..write('relatedMemberId: $relatedMemberId, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FacilityDirectoryTable extends FacilityDirectory
    with TableInfo<$FacilityDirectoryTable, FacilityDirectoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FacilityDirectoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _facilityLevelMeta = const VerificationMeta(
    'facilityLevel',
  );
  @override
  late final GeneratedColumn<String> facilityLevel = GeneratedColumn<String>(
    'facility_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _districtMeta = const VerificationMeta(
    'district',
  );
  @override
  late final GeneratedColumn<String> district = GeneratedColumn<String>(
    'district',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blockMeta = const VerificationMeta('block');
  @override
  late final GeneratedColumn<String> block = GeneratedColumn<String>(
    'block',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _villageMeta = const VerificationMeta(
    'village',
  );
  @override
  late final GeneratedColumn<String> village = GeneratedColumn<String>(
    'village',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactPhoneMeta = const VerificationMeta(
    'contactPhone',
  );
  @override
  late final GeneratedColumn<String> contactPhone = GeneratedColumn<String>(
    'contact_phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servicesJsonMeta = const VerificationMeta(
    'servicesJson',
  );
  @override
  late final GeneratedColumn<String> servicesJson = GeneratedColumn<String>(
    'services_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastUpdatedAtMeta = const VerificationMeta(
    'lastUpdatedAt',
  );
  @override
  late final GeneratedColumn<int> lastUpdatedAt = GeneratedColumn<int>(
    'last_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    facilityLevel,
    district,
    block,
    village,
    latitude,
    longitude,
    contactPhone,
    servicesJson,
    isActive,
    lastUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'facility_directory';
  @override
  VerificationContext validateIntegrity(
    Insertable<FacilityDirectoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('facility_level')) {
      context.handle(
        _facilityLevelMeta,
        facilityLevel.isAcceptableOrUnknown(
          data['facility_level']!,
          _facilityLevelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_facilityLevelMeta);
    }
    if (data.containsKey('district')) {
      context.handle(
        _districtMeta,
        district.isAcceptableOrUnknown(data['district']!, _districtMeta),
      );
    }
    if (data.containsKey('block')) {
      context.handle(
        _blockMeta,
        block.isAcceptableOrUnknown(data['block']!, _blockMeta),
      );
    }
    if (data.containsKey('village')) {
      context.handle(
        _villageMeta,
        village.isAcceptableOrUnknown(data['village']!, _villageMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('contact_phone')) {
      context.handle(
        _contactPhoneMeta,
        contactPhone.isAcceptableOrUnknown(
          data['contact_phone']!,
          _contactPhoneMeta,
        ),
      );
    }
    if (data.containsKey('services_json')) {
      context.handle(
        _servicesJsonMeta,
        servicesJson.isAcceptableOrUnknown(
          data['services_json']!,
          _servicesJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('last_updated_at')) {
      context.handle(
        _lastUpdatedAtMeta,
        lastUpdatedAt.isAcceptableOrUnknown(
          data['last_updated_at']!,
          _lastUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FacilityDirectoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FacilityDirectoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      facilityLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}facility_level'],
      )!,
      district: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}district'],
      ),
      block: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}block'],
      ),
      village: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}village'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      contactPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contact_phone'],
      ),
      servicesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}services_json'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      lastUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_updated_at'],
      )!,
    );
  }

  @override
  $FacilityDirectoryTable createAlias(String alias) {
    return $FacilityDirectoryTable(attachedDatabase, alias);
  }
}

class FacilityDirectoryData extends DataClass
    implements Insertable<FacilityDirectoryData> {
  final String id;
  final String name;
  final String facilityLevel;
  final String? district;
  final String? block;
  final String? village;
  final double? latitude;
  final double? longitude;
  final String? contactPhone;
  final String servicesJson;
  final bool isActive;
  final int lastUpdatedAt;
  const FacilityDirectoryData({
    required this.id,
    required this.name,
    required this.facilityLevel,
    this.district,
    this.block,
    this.village,
    this.latitude,
    this.longitude,
    this.contactPhone,
    required this.servicesJson,
    required this.isActive,
    required this.lastUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['facility_level'] = Variable<String>(facilityLevel);
    if (!nullToAbsent || district != null) {
      map['district'] = Variable<String>(district);
    }
    if (!nullToAbsent || block != null) {
      map['block'] = Variable<String>(block);
    }
    if (!nullToAbsent || village != null) {
      map['village'] = Variable<String>(village);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || contactPhone != null) {
      map['contact_phone'] = Variable<String>(contactPhone);
    }
    map['services_json'] = Variable<String>(servicesJson);
    map['is_active'] = Variable<bool>(isActive);
    map['last_updated_at'] = Variable<int>(lastUpdatedAt);
    return map;
  }

  FacilityDirectoryCompanion toCompanion(bool nullToAbsent) {
    return FacilityDirectoryCompanion(
      id: Value(id),
      name: Value(name),
      facilityLevel: Value(facilityLevel),
      district: district == null && nullToAbsent
          ? const Value.absent()
          : Value(district),
      block: block == null && nullToAbsent
          ? const Value.absent()
          : Value(block),
      village: village == null && nullToAbsent
          ? const Value.absent()
          : Value(village),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      contactPhone: contactPhone == null && nullToAbsent
          ? const Value.absent()
          : Value(contactPhone),
      servicesJson: Value(servicesJson),
      isActive: Value(isActive),
      lastUpdatedAt: Value(lastUpdatedAt),
    );
  }

  factory FacilityDirectoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FacilityDirectoryData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      facilityLevel: serializer.fromJson<String>(json['facilityLevel']),
      district: serializer.fromJson<String?>(json['district']),
      block: serializer.fromJson<String?>(json['block']),
      village: serializer.fromJson<String?>(json['village']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      contactPhone: serializer.fromJson<String?>(json['contactPhone']),
      servicesJson: serializer.fromJson<String>(json['servicesJson']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      lastUpdatedAt: serializer.fromJson<int>(json['lastUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'facilityLevel': serializer.toJson<String>(facilityLevel),
      'district': serializer.toJson<String?>(district),
      'block': serializer.toJson<String?>(block),
      'village': serializer.toJson<String?>(village),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'contactPhone': serializer.toJson<String?>(contactPhone),
      'servicesJson': serializer.toJson<String>(servicesJson),
      'isActive': serializer.toJson<bool>(isActive),
      'lastUpdatedAt': serializer.toJson<int>(lastUpdatedAt),
    };
  }

  FacilityDirectoryData copyWith({
    String? id,
    String? name,
    String? facilityLevel,
    Value<String?> district = const Value.absent(),
    Value<String?> block = const Value.absent(),
    Value<String?> village = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> contactPhone = const Value.absent(),
    String? servicesJson,
    bool? isActive,
    int? lastUpdatedAt,
  }) => FacilityDirectoryData(
    id: id ?? this.id,
    name: name ?? this.name,
    facilityLevel: facilityLevel ?? this.facilityLevel,
    district: district.present ? district.value : this.district,
    block: block.present ? block.value : this.block,
    village: village.present ? village.value : this.village,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    contactPhone: contactPhone.present ? contactPhone.value : this.contactPhone,
    servicesJson: servicesJson ?? this.servicesJson,
    isActive: isActive ?? this.isActive,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
  );
  FacilityDirectoryData copyWithCompanion(FacilityDirectoryCompanion data) {
    return FacilityDirectoryData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      facilityLevel: data.facilityLevel.present
          ? data.facilityLevel.value
          : this.facilityLevel,
      district: data.district.present ? data.district.value : this.district,
      block: data.block.present ? data.block.value : this.block,
      village: data.village.present ? data.village.value : this.village,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      contactPhone: data.contactPhone.present
          ? data.contactPhone.value
          : this.contactPhone,
      servicesJson: data.servicesJson.present
          ? data.servicesJson.value
          : this.servicesJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      lastUpdatedAt: data.lastUpdatedAt.present
          ? data.lastUpdatedAt.value
          : this.lastUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FacilityDirectoryData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('facilityLevel: $facilityLevel, ')
          ..write('district: $district, ')
          ..write('block: $block, ')
          ..write('village: $village, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('contactPhone: $contactPhone, ')
          ..write('servicesJson: $servicesJson, ')
          ..write('isActive: $isActive, ')
          ..write('lastUpdatedAt: $lastUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    facilityLevel,
    district,
    block,
    village,
    latitude,
    longitude,
    contactPhone,
    servicesJson,
    isActive,
    lastUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FacilityDirectoryData &&
          other.id == this.id &&
          other.name == this.name &&
          other.facilityLevel == this.facilityLevel &&
          other.district == this.district &&
          other.block == this.block &&
          other.village == this.village &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.contactPhone == this.contactPhone &&
          other.servicesJson == this.servicesJson &&
          other.isActive == this.isActive &&
          other.lastUpdatedAt == this.lastUpdatedAt);
}

class FacilityDirectoryCompanion
    extends UpdateCompanion<FacilityDirectoryData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> facilityLevel;
  final Value<String?> district;
  final Value<String?> block;
  final Value<String?> village;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> contactPhone;
  final Value<String> servicesJson;
  final Value<bool> isActive;
  final Value<int> lastUpdatedAt;
  final Value<int> rowid;
  const FacilityDirectoryCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.facilityLevel = const Value.absent(),
    this.district = const Value.absent(),
    this.block = const Value.absent(),
    this.village = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.contactPhone = const Value.absent(),
    this.servicesJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.lastUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FacilityDirectoryCompanion.insert({
    required String id,
    required String name,
    required String facilityLevel,
    this.district = const Value.absent(),
    this.block = const Value.absent(),
    this.village = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.contactPhone = const Value.absent(),
    this.servicesJson = const Value.absent(),
    this.isActive = const Value.absent(),
    required int lastUpdatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       facilityLevel = Value(facilityLevel),
       lastUpdatedAt = Value(lastUpdatedAt);
  static Insertable<FacilityDirectoryData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? facilityLevel,
    Expression<String>? district,
    Expression<String>? block,
    Expression<String>? village,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? contactPhone,
    Expression<String>? servicesJson,
    Expression<bool>? isActive,
    Expression<int>? lastUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (facilityLevel != null) 'facility_level': facilityLevel,
      if (district != null) 'district': district,
      if (block != null) 'block': block,
      if (village != null) 'village': village,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (servicesJson != null) 'services_json': servicesJson,
      if (isActive != null) 'is_active': isActive,
      if (lastUpdatedAt != null) 'last_updated_at': lastUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FacilityDirectoryCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? facilityLevel,
    Value<String?>? district,
    Value<String?>? block,
    Value<String?>? village,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? contactPhone,
    Value<String>? servicesJson,
    Value<bool>? isActive,
    Value<int>? lastUpdatedAt,
    Value<int>? rowid,
  }) {
    return FacilityDirectoryCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      facilityLevel: facilityLevel ?? this.facilityLevel,
      district: district ?? this.district,
      block: block ?? this.block,
      village: village ?? this.village,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      contactPhone: contactPhone ?? this.contactPhone,
      servicesJson: servicesJson ?? this.servicesJson,
      isActive: isActive ?? this.isActive,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (facilityLevel.present) {
      map['facility_level'] = Variable<String>(facilityLevel.value);
    }
    if (district.present) {
      map['district'] = Variable<String>(district.value);
    }
    if (block.present) {
      map['block'] = Variable<String>(block.value);
    }
    if (village.present) {
      map['village'] = Variable<String>(village.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (contactPhone.present) {
      map['contact_phone'] = Variable<String>(contactPhone.value);
    }
    if (servicesJson.present) {
      map['services_json'] = Variable<String>(servicesJson.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (lastUpdatedAt.present) {
      map['last_updated_at'] = Variable<int>(lastUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FacilityDirectoryCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('facilityLevel: $facilityLevel, ')
          ..write('district: $district, ')
          ..write('block: $block, ')
          ..write('village: $village, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('contactPhone: $contactPhone, ')
          ..write('servicesJson: $servicesJson, ')
          ..write('isActive: $isActive, ')
          ..write('lastUpdatedAt: $lastUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LearningProgressTable extends LearningProgress
    with TableInfo<$LearningProgressTable, LearningProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearningProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workerIdMeta = const VerificationMeta(
    'workerId',
  );
  @override
  late final GeneratedColumn<String> workerId = GeneratedColumn<String>(
    'worker_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moduleIdMeta = const VerificationMeta(
    'moduleId',
  );
  @override
  late final GeneratedColumn<String> moduleId = GeneratedColumn<String>(
    'module_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<String> lessonId = GeneratedColumn<String>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('not_started'),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quizAttemptsMeta = const VerificationMeta(
    'quizAttempts',
  );
  @override
  late final GeneratedColumn<int> quizAttempts = GeneratedColumn<int>(
    'quiz_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workerId,
    moduleId,
    lessonId,
    status,
    score,
    startedAt,
    completedAt,
    quizAttempts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learning_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearningProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('worker_id')) {
      context.handle(
        _workerIdMeta,
        workerId.isAcceptableOrUnknown(data['worker_id']!, _workerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_workerIdMeta);
    }
    if (data.containsKey('module_id')) {
      context.handle(
        _moduleIdMeta,
        moduleId.isAcceptableOrUnknown(data['module_id']!, _moduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_moduleIdMeta);
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('quiz_attempts')) {
      context.handle(
        _quizAttemptsMeta,
        quizAttempts.isAcceptableOrUnknown(
          data['quiz_attempts']!,
          _quizAttemptsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LearningProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearningProgressData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}worker_id'],
      )!,
      moduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}module_id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lesson_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      quizAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quiz_attempts'],
      )!,
    );
  }

  @override
  $LearningProgressTable createAlias(String alias) {
    return $LearningProgressTable(attachedDatabase, alias);
  }
}

class LearningProgressData extends DataClass
    implements Insertable<LearningProgressData> {
  final String id;
  final String workerId;
  final String moduleId;
  final String lessonId;
  final String status;
  final int? score;
  final int? startedAt;
  final int? completedAt;
  final int quizAttempts;
  const LearningProgressData({
    required this.id,
    required this.workerId,
    required this.moduleId,
    required this.lessonId,
    required this.status,
    this.score,
    this.startedAt,
    this.completedAt,
    required this.quizAttempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['worker_id'] = Variable<String>(workerId);
    map['module_id'] = Variable<String>(moduleId);
    map['lesson_id'] = Variable<String>(lessonId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<int>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    map['quiz_attempts'] = Variable<int>(quizAttempts);
    return map;
  }

  LearningProgressCompanion toCompanion(bool nullToAbsent) {
    return LearningProgressCompanion(
      id: Value(id),
      workerId: Value(workerId),
      moduleId: Value(moduleId),
      lessonId: Value(lessonId),
      status: Value(status),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      quizAttempts: Value(quizAttempts),
    );
  }

  factory LearningProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearningProgressData(
      id: serializer.fromJson<String>(json['id']),
      workerId: serializer.fromJson<String>(json['workerId']),
      moduleId: serializer.fromJson<String>(json['moduleId']),
      lessonId: serializer.fromJson<String>(json['lessonId']),
      status: serializer.fromJson<String>(json['status']),
      score: serializer.fromJson<int?>(json['score']),
      startedAt: serializer.fromJson<int?>(json['startedAt']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      quizAttempts: serializer.fromJson<int>(json['quizAttempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workerId': serializer.toJson<String>(workerId),
      'moduleId': serializer.toJson<String>(moduleId),
      'lessonId': serializer.toJson<String>(lessonId),
      'status': serializer.toJson<String>(status),
      'score': serializer.toJson<int?>(score),
      'startedAt': serializer.toJson<int?>(startedAt),
      'completedAt': serializer.toJson<int?>(completedAt),
      'quizAttempts': serializer.toJson<int>(quizAttempts),
    };
  }

  LearningProgressData copyWith({
    String? id,
    String? workerId,
    String? moduleId,
    String? lessonId,
    String? status,
    Value<int?> score = const Value.absent(),
    Value<int?> startedAt = const Value.absent(),
    Value<int?> completedAt = const Value.absent(),
    int? quizAttempts,
  }) => LearningProgressData(
    id: id ?? this.id,
    workerId: workerId ?? this.workerId,
    moduleId: moduleId ?? this.moduleId,
    lessonId: lessonId ?? this.lessonId,
    status: status ?? this.status,
    score: score.present ? score.value : this.score,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    quizAttempts: quizAttempts ?? this.quizAttempts,
  );
  LearningProgressData copyWithCompanion(LearningProgressCompanion data) {
    return LearningProgressData(
      id: data.id.present ? data.id.value : this.id,
      workerId: data.workerId.present ? data.workerId.value : this.workerId,
      moduleId: data.moduleId.present ? data.moduleId.value : this.moduleId,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      status: data.status.present ? data.status.value : this.status,
      score: data.score.present ? data.score.value : this.score,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      quizAttempts: data.quizAttempts.present
          ? data.quizAttempts.value
          : this.quizAttempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearningProgressData(')
          ..write('id: $id, ')
          ..write('workerId: $workerId, ')
          ..write('moduleId: $moduleId, ')
          ..write('lessonId: $lessonId, ')
          ..write('status: $status, ')
          ..write('score: $score, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('quizAttempts: $quizAttempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workerId,
    moduleId,
    lessonId,
    status,
    score,
    startedAt,
    completedAt,
    quizAttempts,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearningProgressData &&
          other.id == this.id &&
          other.workerId == this.workerId &&
          other.moduleId == this.moduleId &&
          other.lessonId == this.lessonId &&
          other.status == this.status &&
          other.score == this.score &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.quizAttempts == this.quizAttempts);
}

class LearningProgressCompanion extends UpdateCompanion<LearningProgressData> {
  final Value<String> id;
  final Value<String> workerId;
  final Value<String> moduleId;
  final Value<String> lessonId;
  final Value<String> status;
  final Value<int?> score;
  final Value<int?> startedAt;
  final Value<int?> completedAt;
  final Value<int> quizAttempts;
  final Value<int> rowid;
  const LearningProgressCompanion({
    this.id = const Value.absent(),
    this.workerId = const Value.absent(),
    this.moduleId = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.status = const Value.absent(),
    this.score = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.quizAttempts = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearningProgressCompanion.insert({
    required String id,
    required String workerId,
    required String moduleId,
    required String lessonId,
    this.status = const Value.absent(),
    this.score = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.quizAttempts = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workerId = Value(workerId),
       moduleId = Value(moduleId),
       lessonId = Value(lessonId);
  static Insertable<LearningProgressData> custom({
    Expression<String>? id,
    Expression<String>? workerId,
    Expression<String>? moduleId,
    Expression<String>? lessonId,
    Expression<String>? status,
    Expression<int>? score,
    Expression<int>? startedAt,
    Expression<int>? completedAt,
    Expression<int>? quizAttempts,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workerId != null) 'worker_id': workerId,
      if (moduleId != null) 'module_id': moduleId,
      if (lessonId != null) 'lesson_id': lessonId,
      if (status != null) 'status': status,
      if (score != null) 'score': score,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (quizAttempts != null) 'quiz_attempts': quizAttempts,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearningProgressCompanion copyWith({
    Value<String>? id,
    Value<String>? workerId,
    Value<String>? moduleId,
    Value<String>? lessonId,
    Value<String>? status,
    Value<int?>? score,
    Value<int?>? startedAt,
    Value<int?>? completedAt,
    Value<int>? quizAttempts,
    Value<int>? rowid,
  }) {
    return LearningProgressCompanion(
      id: id ?? this.id,
      workerId: workerId ?? this.workerId,
      moduleId: moduleId ?? this.moduleId,
      lessonId: lessonId ?? this.lessonId,
      status: status ?? this.status,
      score: score ?? this.score,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      quizAttempts: quizAttempts ?? this.quizAttempts,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workerId.present) {
      map['worker_id'] = Variable<String>(workerId.value);
    }
    if (moduleId.present) {
      map['module_id'] = Variable<String>(moduleId.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<String>(lessonId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (quizAttempts.present) {
      map['quiz_attempts'] = Variable<int>(quizAttempts.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearningProgressCompanion(')
          ..write('id: $id, ')
          ..write('workerId: $workerId, ')
          ..write('moduleId: $moduleId, ')
          ..write('lessonId: $lessonId, ')
          ..write('status: $status, ')
          ..write('score: $score, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('quizAttempts: $quizAttempts, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceProfilesTable extends DeviceProfiles
    with TableInfo<$DeviceProfilesTable, DeviceProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceNameMeta = const VerificationMeta(
    'deviceName',
  );
  @override
  late final GeneratedColumn<String> deviceName = GeneratedColumn<String>(
    'device_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bleServiceUuidMeta = const VerificationMeta(
    'bleServiceUuid',
  );
  @override
  late final GeneratedColumn<String> bleServiceUuid = GeneratedColumn<String>(
    'ble_service_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bleCharacteristicUuidMeta =
      const VerificationMeta('bleCharacteristicUuid');
  @override
  late final GeneratedColumn<String> bleCharacteristicUuid =
      GeneratedColumn<String>(
        'ble_characteristic_uuid',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _measurementTypeMeta = const VerificationMeta(
    'measurementType',
  );
  @override
  late final GeneratedColumn<String> measurementType = GeneratedColumn<String>(
    'measurement_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minPlausibleMeta = const VerificationMeta(
    'minPlausible',
  );
  @override
  late final GeneratedColumn<double> minPlausible = GeneratedColumn<double>(
    'min_plausible',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _maxPlausibleMeta = const VerificationMeta(
    'maxPlausible',
  );
  @override
  late final GeneratedColumn<double> maxPlausible = GeneratedColumn<double>(
    'max_plausible',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitConversionJsonMeta =
      const VerificationMeta('unitConversionJson');
  @override
  late final GeneratedColumn<String> unitConversionJson =
      GeneratedColumn<String>(
        'unit_conversion_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    deviceName,
    bleServiceUuid,
    bleCharacteristicUuid,
    measurementType,
    unit,
    minPlausible,
    maxPlausible,
    unitConversionJson,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('device_name')) {
      context.handle(
        _deviceNameMeta,
        deviceName.isAcceptableOrUnknown(data['device_name']!, _deviceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceNameMeta);
    }
    if (data.containsKey('ble_service_uuid')) {
      context.handle(
        _bleServiceUuidMeta,
        bleServiceUuid.isAcceptableOrUnknown(
          data['ble_service_uuid']!,
          _bleServiceUuidMeta,
        ),
      );
    }
    if (data.containsKey('ble_characteristic_uuid')) {
      context.handle(
        _bleCharacteristicUuidMeta,
        bleCharacteristicUuid.isAcceptableOrUnknown(
          data['ble_characteristic_uuid']!,
          _bleCharacteristicUuidMeta,
        ),
      );
    }
    if (data.containsKey('measurement_type')) {
      context.handle(
        _measurementTypeMeta,
        measurementType.isAcceptableOrUnknown(
          data['measurement_type']!,
          _measurementTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_measurementTypeMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('min_plausible')) {
      context.handle(
        _minPlausibleMeta,
        minPlausible.isAcceptableOrUnknown(
          data['min_plausible']!,
          _minPlausibleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minPlausibleMeta);
    }
    if (data.containsKey('max_plausible')) {
      context.handle(
        _maxPlausibleMeta,
        maxPlausible.isAcceptableOrUnknown(
          data['max_plausible']!,
          _maxPlausibleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_maxPlausibleMeta);
    }
    if (data.containsKey('unit_conversion_json')) {
      context.handle(
        _unitConversionJsonMeta,
        unitConversionJson.isAcceptableOrUnknown(
          data['unit_conversion_json']!,
          _unitConversionJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      deviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_name'],
      )!,
      bleServiceUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ble_service_uuid'],
      ),
      bleCharacteristicUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ble_characteristic_uuid'],
      ),
      measurementType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}measurement_type'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      minPlausible: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_plausible'],
      )!,
      maxPlausible: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_plausible'],
      )!,
      unitConversionJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_conversion_json'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $DeviceProfilesTable createAlias(String alias) {
    return $DeviceProfilesTable(attachedDatabase, alias);
  }
}

class DeviceProfile extends DataClass implements Insertable<DeviceProfile> {
  final String id;
  final String deviceName;
  final String? bleServiceUuid;
  final String? bleCharacteristicUuid;
  final String measurementType;
  final String unit;
  final double minPlausible;
  final double maxPlausible;
  final String? unitConversionJson;
  final bool isActive;
  const DeviceProfile({
    required this.id,
    required this.deviceName,
    this.bleServiceUuid,
    this.bleCharacteristicUuid,
    required this.measurementType,
    required this.unit,
    required this.minPlausible,
    required this.maxPlausible,
    this.unitConversionJson,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['device_name'] = Variable<String>(deviceName);
    if (!nullToAbsent || bleServiceUuid != null) {
      map['ble_service_uuid'] = Variable<String>(bleServiceUuid);
    }
    if (!nullToAbsent || bleCharacteristicUuid != null) {
      map['ble_characteristic_uuid'] = Variable<String>(bleCharacteristicUuid);
    }
    map['measurement_type'] = Variable<String>(measurementType);
    map['unit'] = Variable<String>(unit);
    map['min_plausible'] = Variable<double>(minPlausible);
    map['max_plausible'] = Variable<double>(maxPlausible);
    if (!nullToAbsent || unitConversionJson != null) {
      map['unit_conversion_json'] = Variable<String>(unitConversionJson);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  DeviceProfilesCompanion toCompanion(bool nullToAbsent) {
    return DeviceProfilesCompanion(
      id: Value(id),
      deviceName: Value(deviceName),
      bleServiceUuid: bleServiceUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(bleServiceUuid),
      bleCharacteristicUuid: bleCharacteristicUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(bleCharacteristicUuid),
      measurementType: Value(measurementType),
      unit: Value(unit),
      minPlausible: Value(minPlausible),
      maxPlausible: Value(maxPlausible),
      unitConversionJson: unitConversionJson == null && nullToAbsent
          ? const Value.absent()
          : Value(unitConversionJson),
      isActive: Value(isActive),
    );
  }

  factory DeviceProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceProfile(
      id: serializer.fromJson<String>(json['id']),
      deviceName: serializer.fromJson<String>(json['deviceName']),
      bleServiceUuid: serializer.fromJson<String?>(json['bleServiceUuid']),
      bleCharacteristicUuid: serializer.fromJson<String?>(
        json['bleCharacteristicUuid'],
      ),
      measurementType: serializer.fromJson<String>(json['measurementType']),
      unit: serializer.fromJson<String>(json['unit']),
      minPlausible: serializer.fromJson<double>(json['minPlausible']),
      maxPlausible: serializer.fromJson<double>(json['maxPlausible']),
      unitConversionJson: serializer.fromJson<String?>(
        json['unitConversionJson'],
      ),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'deviceName': serializer.toJson<String>(deviceName),
      'bleServiceUuid': serializer.toJson<String?>(bleServiceUuid),
      'bleCharacteristicUuid': serializer.toJson<String?>(
        bleCharacteristicUuid,
      ),
      'measurementType': serializer.toJson<String>(measurementType),
      'unit': serializer.toJson<String>(unit),
      'minPlausible': serializer.toJson<double>(minPlausible),
      'maxPlausible': serializer.toJson<double>(maxPlausible),
      'unitConversionJson': serializer.toJson<String?>(unitConversionJson),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  DeviceProfile copyWith({
    String? id,
    String? deviceName,
    Value<String?> bleServiceUuid = const Value.absent(),
    Value<String?> bleCharacteristicUuid = const Value.absent(),
    String? measurementType,
    String? unit,
    double? minPlausible,
    double? maxPlausible,
    Value<String?> unitConversionJson = const Value.absent(),
    bool? isActive,
  }) => DeviceProfile(
    id: id ?? this.id,
    deviceName: deviceName ?? this.deviceName,
    bleServiceUuid: bleServiceUuid.present
        ? bleServiceUuid.value
        : this.bleServiceUuid,
    bleCharacteristicUuid: bleCharacteristicUuid.present
        ? bleCharacteristicUuid.value
        : this.bleCharacteristicUuid,
    measurementType: measurementType ?? this.measurementType,
    unit: unit ?? this.unit,
    minPlausible: minPlausible ?? this.minPlausible,
    maxPlausible: maxPlausible ?? this.maxPlausible,
    unitConversionJson: unitConversionJson.present
        ? unitConversionJson.value
        : this.unitConversionJson,
    isActive: isActive ?? this.isActive,
  );
  DeviceProfile copyWithCompanion(DeviceProfilesCompanion data) {
    return DeviceProfile(
      id: data.id.present ? data.id.value : this.id,
      deviceName: data.deviceName.present
          ? data.deviceName.value
          : this.deviceName,
      bleServiceUuid: data.bleServiceUuid.present
          ? data.bleServiceUuid.value
          : this.bleServiceUuid,
      bleCharacteristicUuid: data.bleCharacteristicUuid.present
          ? data.bleCharacteristicUuid.value
          : this.bleCharacteristicUuid,
      measurementType: data.measurementType.present
          ? data.measurementType.value
          : this.measurementType,
      unit: data.unit.present ? data.unit.value : this.unit,
      minPlausible: data.minPlausible.present
          ? data.minPlausible.value
          : this.minPlausible,
      maxPlausible: data.maxPlausible.present
          ? data.maxPlausible.value
          : this.maxPlausible,
      unitConversionJson: data.unitConversionJson.present
          ? data.unitConversionJson.value
          : this.unitConversionJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceProfile(')
          ..write('id: $id, ')
          ..write('deviceName: $deviceName, ')
          ..write('bleServiceUuid: $bleServiceUuid, ')
          ..write('bleCharacteristicUuid: $bleCharacteristicUuid, ')
          ..write('measurementType: $measurementType, ')
          ..write('unit: $unit, ')
          ..write('minPlausible: $minPlausible, ')
          ..write('maxPlausible: $maxPlausible, ')
          ..write('unitConversionJson: $unitConversionJson, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    deviceName,
    bleServiceUuid,
    bleCharacteristicUuid,
    measurementType,
    unit,
    minPlausible,
    maxPlausible,
    unitConversionJson,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceProfile &&
          other.id == this.id &&
          other.deviceName == this.deviceName &&
          other.bleServiceUuid == this.bleServiceUuid &&
          other.bleCharacteristicUuid == this.bleCharacteristicUuid &&
          other.measurementType == this.measurementType &&
          other.unit == this.unit &&
          other.minPlausible == this.minPlausible &&
          other.maxPlausible == this.maxPlausible &&
          other.unitConversionJson == this.unitConversionJson &&
          other.isActive == this.isActive);
}

class DeviceProfilesCompanion extends UpdateCompanion<DeviceProfile> {
  final Value<String> id;
  final Value<String> deviceName;
  final Value<String?> bleServiceUuid;
  final Value<String?> bleCharacteristicUuid;
  final Value<String> measurementType;
  final Value<String> unit;
  final Value<double> minPlausible;
  final Value<double> maxPlausible;
  final Value<String?> unitConversionJson;
  final Value<bool> isActive;
  final Value<int> rowid;
  const DeviceProfilesCompanion({
    this.id = const Value.absent(),
    this.deviceName = const Value.absent(),
    this.bleServiceUuid = const Value.absent(),
    this.bleCharacteristicUuid = const Value.absent(),
    this.measurementType = const Value.absent(),
    this.unit = const Value.absent(),
    this.minPlausible = const Value.absent(),
    this.maxPlausible = const Value.absent(),
    this.unitConversionJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeviceProfilesCompanion.insert({
    required String id,
    required String deviceName,
    this.bleServiceUuid = const Value.absent(),
    this.bleCharacteristicUuid = const Value.absent(),
    required String measurementType,
    required String unit,
    required double minPlausible,
    required double maxPlausible,
    this.unitConversionJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       deviceName = Value(deviceName),
       measurementType = Value(measurementType),
       unit = Value(unit),
       minPlausible = Value(minPlausible),
       maxPlausible = Value(maxPlausible);
  static Insertable<DeviceProfile> custom({
    Expression<String>? id,
    Expression<String>? deviceName,
    Expression<String>? bleServiceUuid,
    Expression<String>? bleCharacteristicUuid,
    Expression<String>? measurementType,
    Expression<String>? unit,
    Expression<double>? minPlausible,
    Expression<double>? maxPlausible,
    Expression<String>? unitConversionJson,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (deviceName != null) 'device_name': deviceName,
      if (bleServiceUuid != null) 'ble_service_uuid': bleServiceUuid,
      if (bleCharacteristicUuid != null)
        'ble_characteristic_uuid': bleCharacteristicUuid,
      if (measurementType != null) 'measurement_type': measurementType,
      if (unit != null) 'unit': unit,
      if (minPlausible != null) 'min_plausible': minPlausible,
      if (maxPlausible != null) 'max_plausible': maxPlausible,
      if (unitConversionJson != null)
        'unit_conversion_json': unitConversionJson,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeviceProfilesCompanion copyWith({
    Value<String>? id,
    Value<String>? deviceName,
    Value<String?>? bleServiceUuid,
    Value<String?>? bleCharacteristicUuid,
    Value<String>? measurementType,
    Value<String>? unit,
    Value<double>? minPlausible,
    Value<double>? maxPlausible,
    Value<String?>? unitConversionJson,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return DeviceProfilesCompanion(
      id: id ?? this.id,
      deviceName: deviceName ?? this.deviceName,
      bleServiceUuid: bleServiceUuid ?? this.bleServiceUuid,
      bleCharacteristicUuid:
          bleCharacteristicUuid ?? this.bleCharacteristicUuid,
      measurementType: measurementType ?? this.measurementType,
      unit: unit ?? this.unit,
      minPlausible: minPlausible ?? this.minPlausible,
      maxPlausible: maxPlausible ?? this.maxPlausible,
      unitConversionJson: unitConversionJson ?? this.unitConversionJson,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (deviceName.present) {
      map['device_name'] = Variable<String>(deviceName.value);
    }
    if (bleServiceUuid.present) {
      map['ble_service_uuid'] = Variable<String>(bleServiceUuid.value);
    }
    if (bleCharacteristicUuid.present) {
      map['ble_characteristic_uuid'] = Variable<String>(
        bleCharacteristicUuid.value,
      );
    }
    if (measurementType.present) {
      map['measurement_type'] = Variable<String>(measurementType.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (minPlausible.present) {
      map['min_plausible'] = Variable<double>(minPlausible.value);
    }
    if (maxPlausible.present) {
      map['max_plausible'] = Variable<double>(maxPlausible.value);
    }
    if (unitConversionJson.present) {
      map['unit_conversion_json'] = Variable<String>(unitConversionJson.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceProfilesCompanion(')
          ..write('id: $id, ')
          ..write('deviceName: $deviceName, ')
          ..write('bleServiceUuid: $bleServiceUuid, ')
          ..write('bleCharacteristicUuid: $bleCharacteristicUuid, ')
          ..write('measurementType: $measurementType, ')
          ..write('unit: $unit, ')
          ..write('minPlausible: $minPlausible, ')
          ..write('maxPlausible: $maxPlausible, ')
          ..write('unitConversionJson: $unitConversionJson, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $HouseholdsTable households = $HouseholdsTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $ConsentRecordsTable consentRecords = $ConsentRecordsTable(this);
  late final $ClinicalEncountersTable clinicalEncounters =
      $ClinicalEncountersTable(this);
  late final $ClinicalObservationsTable clinicalObservations =
      $ClinicalObservationsTable(this);
  late final $TriageResultsTable triageResults = $TriageResultsTable(this);
  late final $ReferralRecordsTable referralRecords = $ReferralRecordsTable(
    this,
  );
  late final $VisitSchedulesTable visitSchedules = $VisitSchedulesTable(this);
  late final $IncentiveEventsTable incentiveEvents = $IncentiveEventsTable(
    this,
  );
  late final $IncentiveClaimsTable incentiveClaims = $IncentiveClaimsTable(
    this,
  );
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $RuleVersionsTable ruleVersions = $RuleVersionsTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $DraftsTable drafts = $DraftsTable(this);
  late final $StockItemsTable stockItems = $StockItemsTable(this);
  late final $StockTransactionsTable stockTransactions =
      $StockTransactionsTable(this);
  late final $FacilityDirectoryTable facilityDirectory =
      $FacilityDirectoryTable(this);
  late final $LearningProgressTable learningProgress = $LearningProgressTable(
    this,
  );
  late final $DeviceProfilesTable deviceProfiles = $DeviceProfilesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    households,
    members,
    consentRecords,
    clinicalEncounters,
    clinicalObservations,
    triageResults,
    referralRecords,
    visitSchedules,
    incentiveEvents,
    incentiveClaims,
    syncQueue,
    ruleVersions,
    auditLog,
    drafts,
    stockItems,
    stockTransactions,
    facilityDirectory,
    learningProgress,
    deviceProfiles,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      required String ashaId,
      required String name,
      required String role,
      Value<String?> areaVillage,
      Value<String?> areaSubcentre,
      Value<String?> areaPhc,
      Value<String?> areaBlock,
      Value<String?> areaDistrict,
      Value<String?> areaState,
      Value<String?> hashedPin,
      Value<Uint8List?> pinSalt,
      Value<String?> offlineCredentialHash,
      Value<int?> offlineCredExpiresAt,
      Value<String?> jwtRefreshToken,
      Value<int?> lastJwtRefreshAt,
      Value<int> failedPinAttempts,
      Value<int?> lockoutUntil,
      required int createdAt,
      required int updatedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String> ashaId,
      Value<String> name,
      Value<String> role,
      Value<String?> areaVillage,
      Value<String?> areaSubcentre,
      Value<String?> areaPhc,
      Value<String?> areaBlock,
      Value<String?> areaDistrict,
      Value<String?> areaState,
      Value<String?> hashedPin,
      Value<Uint8List?> pinSalt,
      Value<String?> offlineCredentialHash,
      Value<int?> offlineCredExpiresAt,
      Value<String?> jwtRefreshToken,
      Value<int?> lastJwtRefreshAt,
      Value<int> failedPinAttempts,
      Value<int?> lockoutUntil,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$UsersTableReferences
    extends BaseReferences<_$AppDatabase, $UsersTable, User> {
  $$UsersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IncentiveClaimsTable, List<IncentiveClaim>>
  _incentiveClaimsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.incentiveClaims,
    aliasName: $_aliasNameGenerator(db.users.id, db.incentiveClaims.workerId),
  );

  $$IncentiveClaimsTableProcessedTableManager get incentiveClaimsRefs {
    final manager = $$IncentiveClaimsTableTableManager(
      $_db,
      $_db.incentiveClaims,
    ).filter((f) => f.workerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _incentiveClaimsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ashaId => $composableBuilder(
    column: $table.ashaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaVillage => $composableBuilder(
    column: $table.areaVillage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaSubcentre => $composableBuilder(
    column: $table.areaSubcentre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaPhc => $composableBuilder(
    column: $table.areaPhc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaBlock => $composableBuilder(
    column: $table.areaBlock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaDistrict => $composableBuilder(
    column: $table.areaDistrict,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get areaState => $composableBuilder(
    column: $table.areaState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hashedPin => $composableBuilder(
    column: $table.hashedPin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get pinSalt => $composableBuilder(
    column: $table.pinSalt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get offlineCredentialHash => $composableBuilder(
    column: $table.offlineCredentialHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offlineCredExpiresAt => $composableBuilder(
    column: $table.offlineCredExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jwtRefreshToken => $composableBuilder(
    column: $table.jwtRefreshToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastJwtRefreshAt => $composableBuilder(
    column: $table.lastJwtRefreshAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedPinAttempts => $composableBuilder(
    column: $table.failedPinAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lockoutUntil => $composableBuilder(
    column: $table.lockoutUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> incentiveClaimsRefs(
    Expression<bool> Function($$IncentiveClaimsTableFilterComposer f) f,
  ) {
    final $$IncentiveClaimsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incentiveClaims,
      getReferencedColumn: (t) => t.workerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncentiveClaimsTableFilterComposer(
            $db: $db,
            $table: $db.incentiveClaims,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ashaId => $composableBuilder(
    column: $table.ashaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaVillage => $composableBuilder(
    column: $table.areaVillage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaSubcentre => $composableBuilder(
    column: $table.areaSubcentre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaPhc => $composableBuilder(
    column: $table.areaPhc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaBlock => $composableBuilder(
    column: $table.areaBlock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaDistrict => $composableBuilder(
    column: $table.areaDistrict,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get areaState => $composableBuilder(
    column: $table.areaState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hashedPin => $composableBuilder(
    column: $table.hashedPin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get pinSalt => $composableBuilder(
    column: $table.pinSalt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get offlineCredentialHash => $composableBuilder(
    column: $table.offlineCredentialHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offlineCredExpiresAt => $composableBuilder(
    column: $table.offlineCredExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jwtRefreshToken => $composableBuilder(
    column: $table.jwtRefreshToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastJwtRefreshAt => $composableBuilder(
    column: $table.lastJwtRefreshAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedPinAttempts => $composableBuilder(
    column: $table.failedPinAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lockoutUntil => $composableBuilder(
    column: $table.lockoutUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ashaId =>
      $composableBuilder(column: $table.ashaId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get areaVillage => $composableBuilder(
    column: $table.areaVillage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get areaSubcentre => $composableBuilder(
    column: $table.areaSubcentre,
    builder: (column) => column,
  );

  GeneratedColumn<String> get areaPhc =>
      $composableBuilder(column: $table.areaPhc, builder: (column) => column);

  GeneratedColumn<String> get areaBlock =>
      $composableBuilder(column: $table.areaBlock, builder: (column) => column);

  GeneratedColumn<String> get areaDistrict => $composableBuilder(
    column: $table.areaDistrict,
    builder: (column) => column,
  );

  GeneratedColumn<String> get areaState =>
      $composableBuilder(column: $table.areaState, builder: (column) => column);

  GeneratedColumn<String> get hashedPin =>
      $composableBuilder(column: $table.hashedPin, builder: (column) => column);

  GeneratedColumn<Uint8List> get pinSalt =>
      $composableBuilder(column: $table.pinSalt, builder: (column) => column);

  GeneratedColumn<String> get offlineCredentialHash => $composableBuilder(
    column: $table.offlineCredentialHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offlineCredExpiresAt => $composableBuilder(
    column: $table.offlineCredExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jwtRefreshToken => $composableBuilder(
    column: $table.jwtRefreshToken,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastJwtRefreshAt => $composableBuilder(
    column: $table.lastJwtRefreshAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failedPinAttempts => $composableBuilder(
    column: $table.failedPinAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lockoutUntil => $composableBuilder(
    column: $table.lockoutUntil,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  Expression<T> incentiveClaimsRefs<T extends Object>(
    Expression<T> Function($$IncentiveClaimsTableAnnotationComposer a) f,
  ) {
    final $$IncentiveClaimsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incentiveClaims,
      getReferencedColumn: (t) => t.workerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncentiveClaimsTableAnnotationComposer(
            $db: $db,
            $table: $db.incentiveClaims,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, $$UsersTableReferences),
          User,
          PrefetchHooks Function({bool incentiveClaimsRefs})
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ashaId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> areaVillage = const Value.absent(),
                Value<String?> areaSubcentre = const Value.absent(),
                Value<String?> areaPhc = const Value.absent(),
                Value<String?> areaBlock = const Value.absent(),
                Value<String?> areaDistrict = const Value.absent(),
                Value<String?> areaState = const Value.absent(),
                Value<String?> hashedPin = const Value.absent(),
                Value<Uint8List?> pinSalt = const Value.absent(),
                Value<String?> offlineCredentialHash = const Value.absent(),
                Value<int?> offlineCredExpiresAt = const Value.absent(),
                Value<String?> jwtRefreshToken = const Value.absent(),
                Value<int?> lastJwtRefreshAt = const Value.absent(),
                Value<int> failedPinAttempts = const Value.absent(),
                Value<int?> lockoutUntil = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                ashaId: ashaId,
                name: name,
                role: role,
                areaVillage: areaVillage,
                areaSubcentre: areaSubcentre,
                areaPhc: areaPhc,
                areaBlock: areaBlock,
                areaDistrict: areaDistrict,
                areaState: areaState,
                hashedPin: hashedPin,
                pinSalt: pinSalt,
                offlineCredentialHash: offlineCredentialHash,
                offlineCredExpiresAt: offlineCredExpiresAt,
                jwtRefreshToken: jwtRefreshToken,
                lastJwtRefreshAt: lastJwtRefreshAt,
                failedPinAttempts: failedPinAttempts,
                lockoutUntil: lockoutUntil,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ashaId,
                required String name,
                required String role,
                Value<String?> areaVillage = const Value.absent(),
                Value<String?> areaSubcentre = const Value.absent(),
                Value<String?> areaPhc = const Value.absent(),
                Value<String?> areaBlock = const Value.absent(),
                Value<String?> areaDistrict = const Value.absent(),
                Value<String?> areaState = const Value.absent(),
                Value<String?> hashedPin = const Value.absent(),
                Value<Uint8List?> pinSalt = const Value.absent(),
                Value<String?> offlineCredentialHash = const Value.absent(),
                Value<int?> offlineCredExpiresAt = const Value.absent(),
                Value<String?> jwtRefreshToken = const Value.absent(),
                Value<int?> lastJwtRefreshAt = const Value.absent(),
                Value<int> failedPinAttempts = const Value.absent(),
                Value<int?> lockoutUntil = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                ashaId: ashaId,
                name: name,
                role: role,
                areaVillage: areaVillage,
                areaSubcentre: areaSubcentre,
                areaPhc: areaPhc,
                areaBlock: areaBlock,
                areaDistrict: areaDistrict,
                areaState: areaState,
                hashedPin: hashedPin,
                pinSalt: pinSalt,
                offlineCredentialHash: offlineCredentialHash,
                offlineCredExpiresAt: offlineCredExpiresAt,
                jwtRefreshToken: jwtRefreshToken,
                lastJwtRefreshAt: lastJwtRefreshAt,
                failedPinAttempts: failedPinAttempts,
                lockoutUntil: lockoutUntil,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$UsersTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({incentiveClaimsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (incentiveClaimsRefs) db.incentiveClaims,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (incentiveClaimsRefs)
                    await $_getPrefetchedData<
                      User,
                      $UsersTable,
                      IncentiveClaim
                    >(
                      currentTable: table,
                      referencedTable: $$UsersTableReferences
                          ._incentiveClaimsRefsTable(db),
                      managerFromTypedResult: (p0) => $$UsersTableReferences(
                        db,
                        table,
                        p0,
                      ).incentiveClaimsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.workerId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, $$UsersTableReferences),
      User,
      PrefetchHooks Function({bool incentiveClaimsRefs})
    >;
typedef $$HouseholdsTableCreateCompanionBuilder =
    HouseholdsCompanion Function({
      required String id,
      required String village,
      Value<String?> hamlet,
      required String headName,
      Value<String?> socialCategory,
      Value<bool> isBpl,
      Value<String?> contactPhone,
      Value<String?> latitude,
      Value<String?> longitude,
      Value<String?> landmarkNotes,
      Value<int> memberCount,
      required int createdAt,
      required int updatedAt,
      required String createdBy,
      Value<String> syncStatus,
      Value<int?> serverVersion,
      Value<int> rowid,
    });
typedef $$HouseholdsTableUpdateCompanionBuilder =
    HouseholdsCompanion Function({
      Value<String> id,
      Value<String> village,
      Value<String?> hamlet,
      Value<String> headName,
      Value<String?> socialCategory,
      Value<bool> isBpl,
      Value<String?> contactPhone,
      Value<String?> latitude,
      Value<String?> longitude,
      Value<String?> landmarkNotes,
      Value<int> memberCount,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> createdBy,
      Value<String> syncStatus,
      Value<int?> serverVersion,
      Value<int> rowid,
    });

final class $$HouseholdsTableReferences
    extends BaseReferences<_$AppDatabase, $HouseholdsTable, Household> {
  $$HouseholdsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MembersTable, List<Member>> _membersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.members,
    aliasName: $_aliasNameGenerator(db.households.id, db.members.householdId),
  );

  $$MembersTableProcessedTableManager get membersRefs {
    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_membersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HouseholdsTableFilterComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get village => $composableBuilder(
    column: $table.village,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hamlet => $composableBuilder(
    column: $table.hamlet,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headName => $composableBuilder(
    column: $table.headName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get socialCategory => $composableBuilder(
    column: $table.socialCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBpl => $composableBuilder(
    column: $table.isBpl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactPhone => $composableBuilder(
    column: $table.contactPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get landmarkNotes => $composableBuilder(
    column: $table.landmarkNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> membersRefs(
    Expression<bool> Function($$MembersTableFilterComposer f) f,
  ) {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HouseholdsTableOrderingComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get village => $composableBuilder(
    column: $table.village,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hamlet => $composableBuilder(
    column: $table.hamlet,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headName => $composableBuilder(
    column: $table.headName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get socialCategory => $composableBuilder(
    column: $table.socialCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBpl => $composableBuilder(
    column: $table.isBpl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactPhone => $composableBuilder(
    column: $table.contactPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get landmarkNotes => $composableBuilder(
    column: $table.landmarkNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HouseholdsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HouseholdsTable> {
  $$HouseholdsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get village =>
      $composableBuilder(column: $table.village, builder: (column) => column);

  GeneratedColumn<String> get hamlet =>
      $composableBuilder(column: $table.hamlet, builder: (column) => column);

  GeneratedColumn<String> get headName =>
      $composableBuilder(column: $table.headName, builder: (column) => column);

  GeneratedColumn<String> get socialCategory => $composableBuilder(
    column: $table.socialCategory,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBpl =>
      $composableBuilder(column: $table.isBpl, builder: (column) => column);

  GeneratedColumn<String> get contactPhone => $composableBuilder(
    column: $table.contactPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<String> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get landmarkNotes => $composableBuilder(
    column: $table.landmarkNotes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get memberCount => $composableBuilder(
    column: $table.memberCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  Expression<T> membersRefs<T extends Object>(
    Expression<T> Function($$MembersTableAnnotationComposer a) f,
  ) {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HouseholdsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HouseholdsTable,
          Household,
          $$HouseholdsTableFilterComposer,
          $$HouseholdsTableOrderingComposer,
          $$HouseholdsTableAnnotationComposer,
          $$HouseholdsTableCreateCompanionBuilder,
          $$HouseholdsTableUpdateCompanionBuilder,
          (Household, $$HouseholdsTableReferences),
          Household,
          PrefetchHooks Function({bool membersRefs})
        > {
  $$HouseholdsTableTableManager(_$AppDatabase db, $HouseholdsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HouseholdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HouseholdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HouseholdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> village = const Value.absent(),
                Value<String?> hamlet = const Value.absent(),
                Value<String> headName = const Value.absent(),
                Value<String?> socialCategory = const Value.absent(),
                Value<bool> isBpl = const Value.absent(),
                Value<String?> contactPhone = const Value.absent(),
                Value<String?> latitude = const Value.absent(),
                Value<String?> longitude = const Value.absent(),
                Value<String?> landmarkNotes = const Value.absent(),
                Value<int> memberCount = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdsCompanion(
                id: id,
                village: village,
                hamlet: hamlet,
                headName: headName,
                socialCategory: socialCategory,
                isBpl: isBpl,
                contactPhone: contactPhone,
                latitude: latitude,
                longitude: longitude,
                landmarkNotes: landmarkNotes,
                memberCount: memberCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                syncStatus: syncStatus,
                serverVersion: serverVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String village,
                Value<String?> hamlet = const Value.absent(),
                required String headName,
                Value<String?> socialCategory = const Value.absent(),
                Value<bool> isBpl = const Value.absent(),
                Value<String?> contactPhone = const Value.absent(),
                Value<String?> latitude = const Value.absent(),
                Value<String?> longitude = const Value.absent(),
                Value<String?> landmarkNotes = const Value.absent(),
                Value<int> memberCount = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                required String createdBy,
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HouseholdsCompanion.insert(
                id: id,
                village: village,
                hamlet: hamlet,
                headName: headName,
                socialCategory: socialCategory,
                isBpl: isBpl,
                contactPhone: contactPhone,
                latitude: latitude,
                longitude: longitude,
                landmarkNotes: landmarkNotes,
                memberCount: memberCount,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                syncStatus: syncStatus,
                serverVersion: serverVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HouseholdsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({membersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (membersRefs) db.members],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (membersRefs)
                    await $_getPrefetchedData<
                      Household,
                      $HouseholdsTable,
                      Member
                    >(
                      currentTable: table,
                      referencedTable: $$HouseholdsTableReferences
                          ._membersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$HouseholdsTableReferences(
                            db,
                            table,
                            p0,
                          ).membersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.householdId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$HouseholdsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HouseholdsTable,
      Household,
      $$HouseholdsTableFilterComposer,
      $$HouseholdsTableOrderingComposer,
      $$HouseholdsTableAnnotationComposer,
      $$HouseholdsTableCreateCompanionBuilder,
      $$HouseholdsTableUpdateCompanionBuilder,
      (Household, $$HouseholdsTableReferences),
      Household,
      PrefetchHooks Function({bool membersRefs})
    >;
typedef $$MembersTableCreateCompanionBuilder =
    MembersCompanion Function({
      required String id,
      required String householdId,
      required String name,
      Value<String?> namePhonetic,
      Value<int?> dobApprox,
      Value<bool> isDobApprox,
      required String sex,
      Value<String?> relationshipToHead,
      Value<String?> abhaId,
      Value<String?> rchId,
      Value<String?> phone,
      Value<String?> socialCategory,
      Value<bool?> isBpl,
      Value<String> lifecycleStatus,
      Value<String> consentStatus,
      Value<int?> consentUpdatedAt,
      required int createdAt,
      required int updatedAt,
      required String createdBy,
      Value<String> syncStatus,
      Value<int?> serverVersion,
      Value<int> rowid,
    });
typedef $$MembersTableUpdateCompanionBuilder =
    MembersCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<String> name,
      Value<String?> namePhonetic,
      Value<int?> dobApprox,
      Value<bool> isDobApprox,
      Value<String> sex,
      Value<String?> relationshipToHead,
      Value<String?> abhaId,
      Value<String?> rchId,
      Value<String?> phone,
      Value<String?> socialCategory,
      Value<bool?> isBpl,
      Value<String> lifecycleStatus,
      Value<String> consentStatus,
      Value<int?> consentUpdatedAt,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> createdBy,
      Value<String> syncStatus,
      Value<int?> serverVersion,
      Value<int> rowid,
    });

final class $$MembersTableReferences
    extends BaseReferences<_$AppDatabase, $MembersTable, Member> {
  $$MembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HouseholdsTable _householdIdTable(_$AppDatabase db) =>
      db.households.createAlias(
        $_aliasNameGenerator(db.members.householdId, db.households.id),
      );

  $$HouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$HouseholdsTableTableManager(
      $_db,
      $_db.households,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ConsentRecordsTable, List<ConsentRecord>>
  _consentRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.consentRecords,
    aliasName: $_aliasNameGenerator(db.members.id, db.consentRecords.memberId),
  );

  $$ConsentRecordsTableProcessedTableManager get consentRecordsRefs {
    final manager = $$ConsentRecordsTableTableManager(
      $_db,
      $_db.consentRecords,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_consentRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ClinicalEncountersTable, List<ClinicalEncounter>>
  _clinicalEncountersRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.clinicalEncounters,
        aliasName: $_aliasNameGenerator(
          db.members.id,
          db.clinicalEncounters.memberId,
        ),
      );

  $$ClinicalEncountersTableProcessedTableManager get clinicalEncountersRefs {
    final manager = $$ClinicalEncountersTableTableManager(
      $_db,
      $_db.clinicalEncounters,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _clinicalEncountersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReferralRecordsTable, List<ReferralRecord>>
  _referralRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.referralRecords,
    aliasName: $_aliasNameGenerator(db.members.id, db.referralRecords.memberId),
  );

  $$ReferralRecordsTableProcessedTableManager get referralRecordsRefs {
    final manager = $$ReferralRecordsTableTableManager(
      $_db,
      $_db.referralRecords,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _referralRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VisitSchedulesTable, List<VisitSchedule>>
  _visitSchedulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.visitSchedules,
    aliasName: $_aliasNameGenerator(db.members.id, db.visitSchedules.memberId),
  );

  $$VisitSchedulesTableProcessedTableManager get visitSchedulesRefs {
    final manager = $$VisitSchedulesTableTableManager(
      $_db,
      $_db.visitSchedules,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_visitSchedulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$IncentiveEventsTable, List<IncentiveEvent>>
  _incentiveEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.incentiveEvents,
    aliasName: $_aliasNameGenerator(db.members.id, db.incentiveEvents.memberId),
  );

  $$IncentiveEventsTableProcessedTableManager get incentiveEventsRefs {
    final manager = $$IncentiveEventsTableTableManager(
      $_db,
      $_db.incentiveEvents,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _incentiveEventsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get namePhonetic => $composableBuilder(
    column: $table.namePhonetic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dobApprox => $composableBuilder(
    column: $table.dobApprox,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDobApprox => $composableBuilder(
    column: $table.isDobApprox,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relationshipToHead => $composableBuilder(
    column: $table.relationshipToHead,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get abhaId => $composableBuilder(
    column: $table.abhaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rchId => $composableBuilder(
    column: $table.rchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get socialCategory => $composableBuilder(
    column: $table.socialCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBpl => $composableBuilder(
    column: $table.isBpl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lifecycleStatus => $composableBuilder(
    column: $table.lifecycleStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consentStatus => $composableBuilder(
    column: $table.consentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consentUpdatedAt => $composableBuilder(
    column: $table.consentUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$HouseholdsTableFilterComposer get householdId {
    final $$HouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> consentRecordsRefs(
    Expression<bool> Function($$ConsentRecordsTableFilterComposer f) f,
  ) {
    final $$ConsentRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.consentRecords,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConsentRecordsTableFilterComposer(
            $db: $db,
            $table: $db.consentRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> clinicalEncountersRefs(
    Expression<bool> Function($$ClinicalEncountersTableFilterComposer f) f,
  ) {
    final $$ClinicalEncountersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.clinicalEncounters,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClinicalEncountersTableFilterComposer(
            $db: $db,
            $table: $db.clinicalEncounters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> referralRecordsRefs(
    Expression<bool> Function($$ReferralRecordsTableFilterComposer f) f,
  ) {
    final $$ReferralRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.referralRecords,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferralRecordsTableFilterComposer(
            $db: $db,
            $table: $db.referralRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> visitSchedulesRefs(
    Expression<bool> Function($$VisitSchedulesTableFilterComposer f) f,
  ) {
    final $$VisitSchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitSchedules,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitSchedulesTableFilterComposer(
            $db: $db,
            $table: $db.visitSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> incentiveEventsRefs(
    Expression<bool> Function($$IncentiveEventsTableFilterComposer f) f,
  ) {
    final $$IncentiveEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incentiveEvents,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncentiveEventsTableFilterComposer(
            $db: $db,
            $table: $db.incentiveEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get namePhonetic => $composableBuilder(
    column: $table.namePhonetic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dobApprox => $composableBuilder(
    column: $table.dobApprox,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDobApprox => $composableBuilder(
    column: $table.isDobApprox,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sex => $composableBuilder(
    column: $table.sex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relationshipToHead => $composableBuilder(
    column: $table.relationshipToHead,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get abhaId => $composableBuilder(
    column: $table.abhaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rchId => $composableBuilder(
    column: $table.rchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get socialCategory => $composableBuilder(
    column: $table.socialCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBpl => $composableBuilder(
    column: $table.isBpl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lifecycleStatus => $composableBuilder(
    column: $table.lifecycleStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consentStatus => $composableBuilder(
    column: $table.consentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consentUpdatedAt => $composableBuilder(
    column: $table.consentUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$HouseholdsTableOrderingComposer get householdId {
    final $$HouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get namePhonetic => $composableBuilder(
    column: $table.namePhonetic,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dobApprox =>
      $composableBuilder(column: $table.dobApprox, builder: (column) => column);

  GeneratedColumn<bool> get isDobApprox => $composableBuilder(
    column: $table.isDobApprox,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sex =>
      $composableBuilder(column: $table.sex, builder: (column) => column);

  GeneratedColumn<String> get relationshipToHead => $composableBuilder(
    column: $table.relationshipToHead,
    builder: (column) => column,
  );

  GeneratedColumn<String> get abhaId =>
      $composableBuilder(column: $table.abhaId, builder: (column) => column);

  GeneratedColumn<String> get rchId =>
      $composableBuilder(column: $table.rchId, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get socialCategory => $composableBuilder(
    column: $table.socialCategory,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBpl =>
      $composableBuilder(column: $table.isBpl, builder: (column) => column);

  GeneratedColumn<String> get lifecycleStatus => $composableBuilder(
    column: $table.lifecycleStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get consentStatus => $composableBuilder(
    column: $table.consentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consentUpdatedAt => $composableBuilder(
    column: $table.consentUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  $$HouseholdsTableAnnotationComposer get householdId {
    final $$HouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.households,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.households,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> consentRecordsRefs<T extends Object>(
    Expression<T> Function($$ConsentRecordsTableAnnotationComposer a) f,
  ) {
    final $$ConsentRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.consentRecords,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConsentRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.consentRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> clinicalEncountersRefs<T extends Object>(
    Expression<T> Function($$ClinicalEncountersTableAnnotationComposer a) f,
  ) {
    final $$ClinicalEncountersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.clinicalEncounters,
          getReferencedColumn: (t) => t.memberId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClinicalEncountersTableAnnotationComposer(
                $db: $db,
                $table: $db.clinicalEncounters,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> referralRecordsRefs<T extends Object>(
    Expression<T> Function($$ReferralRecordsTableAnnotationComposer a) f,
  ) {
    final $$ReferralRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.referralRecords,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferralRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.referralRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> visitSchedulesRefs<T extends Object>(
    Expression<T> Function($$VisitSchedulesTableAnnotationComposer a) f,
  ) {
    final $$VisitSchedulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.visitSchedules,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VisitSchedulesTableAnnotationComposer(
            $db: $db,
            $table: $db.visitSchedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> incentiveEventsRefs<T extends Object>(
    Expression<T> Function($$IncentiveEventsTableAnnotationComposer a) f,
  ) {
    final $$IncentiveEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incentiveEvents,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncentiveEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.incentiveEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembersTable,
          Member,
          $$MembersTableFilterComposer,
          $$MembersTableOrderingComposer,
          $$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (Member, $$MembersTableReferences),
          Member,
          PrefetchHooks Function({
            bool householdId,
            bool consentRecordsRefs,
            bool clinicalEncountersRefs,
            bool referralRecordsRefs,
            bool visitSchedulesRefs,
            bool incentiveEventsRefs,
          })
        > {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> namePhonetic = const Value.absent(),
                Value<int?> dobApprox = const Value.absent(),
                Value<bool> isDobApprox = const Value.absent(),
                Value<String> sex = const Value.absent(),
                Value<String?> relationshipToHead = const Value.absent(),
                Value<String?> abhaId = const Value.absent(),
                Value<String?> rchId = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> socialCategory = const Value.absent(),
                Value<bool?> isBpl = const Value.absent(),
                Value<String> lifecycleStatus = const Value.absent(),
                Value<String> consentStatus = const Value.absent(),
                Value<int?> consentUpdatedAt = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion(
                id: id,
                householdId: householdId,
                name: name,
                namePhonetic: namePhonetic,
                dobApprox: dobApprox,
                isDobApprox: isDobApprox,
                sex: sex,
                relationshipToHead: relationshipToHead,
                abhaId: abhaId,
                rchId: rchId,
                phone: phone,
                socialCategory: socialCategory,
                isBpl: isBpl,
                lifecycleStatus: lifecycleStatus,
                consentStatus: consentStatus,
                consentUpdatedAt: consentUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                syncStatus: syncStatus,
                serverVersion: serverVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                required String name,
                Value<String?> namePhonetic = const Value.absent(),
                Value<int?> dobApprox = const Value.absent(),
                Value<bool> isDobApprox = const Value.absent(),
                required String sex,
                Value<String?> relationshipToHead = const Value.absent(),
                Value<String?> abhaId = const Value.absent(),
                Value<String?> rchId = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> socialCategory = const Value.absent(),
                Value<bool?> isBpl = const Value.absent(),
                Value<String> lifecycleStatus = const Value.absent(),
                Value<String> consentStatus = const Value.absent(),
                Value<int?> consentUpdatedAt = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                required String createdBy,
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion.insert(
                id: id,
                householdId: householdId,
                name: name,
                namePhonetic: namePhonetic,
                dobApprox: dobApprox,
                isDobApprox: isDobApprox,
                sex: sex,
                relationshipToHead: relationshipToHead,
                abhaId: abhaId,
                rchId: rchId,
                phone: phone,
                socialCategory: socialCategory,
                isBpl: isBpl,
                lifecycleStatus: lifecycleStatus,
                consentStatus: consentStatus,
                consentUpdatedAt: consentUpdatedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                createdBy: createdBy,
                syncStatus: syncStatus,
                serverVersion: serverVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                householdId = false,
                consentRecordsRefs = false,
                clinicalEncountersRefs = false,
                referralRecordsRefs = false,
                visitSchedulesRefs = false,
                incentiveEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (consentRecordsRefs) db.consentRecords,
                    if (clinicalEncountersRefs) db.clinicalEncounters,
                    if (referralRecordsRefs) db.referralRecords,
                    if (visitSchedulesRefs) db.visitSchedules,
                    if (incentiveEventsRefs) db.incentiveEvents,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (householdId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.householdId,
                                    referencedTable: $$MembersTableReferences
                                        ._householdIdTable(db),
                                    referencedColumn: $$MembersTableReferences
                                        ._householdIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (consentRecordsRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          ConsentRecord
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._consentRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).consentRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (clinicalEncountersRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          ClinicalEncounter
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._clinicalEncountersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).clinicalEncountersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (referralRecordsRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          ReferralRecord
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._referralRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).referralRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (visitSchedulesRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          VisitSchedule
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._visitSchedulesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).visitSchedulesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (incentiveEventsRefs)
                        await $_getPrefetchedData<
                          Member,
                          $MembersTable,
                          IncentiveEvent
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._incentiveEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).incentiveEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.memberId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembersTable,
      Member,
      $$MembersTableFilterComposer,
      $$MembersTableOrderingComposer,
      $$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (Member, $$MembersTableReferences),
      Member,
      PrefetchHooks Function({
        bool householdId,
        bool consentRecordsRefs,
        bool clinicalEncountersRefs,
        bool referralRecordsRefs,
        bool visitSchedulesRefs,
        bool incentiveEventsRefs,
      })
    >;
typedef $$ConsentRecordsTableCreateCompanionBuilder =
    ConsentRecordsCompanion Function({
      required String id,
      required String memberId,
      required String consentVersion,
      required int consentedAt,
      required String ashaId,
      required String witnessType,
      required String signatureHash,
      Value<String?> voiceAckAudioHash,
      Value<bool> isGuardianConsent,
      Value<String?> guardianRelationship,
      Value<int?> withdrawnAt,
      Value<String?> withdrawalReason,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$ConsentRecordsTableUpdateCompanionBuilder =
    ConsentRecordsCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> consentVersion,
      Value<int> consentedAt,
      Value<String> ashaId,
      Value<String> witnessType,
      Value<String> signatureHash,
      Value<String?> voiceAckAudioHash,
      Value<bool> isGuardianConsent,
      Value<String?> guardianRelationship,
      Value<int?> withdrawnAt,
      Value<String?> withdrawalReason,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$ConsentRecordsTableReferences
    extends BaseReferences<_$AppDatabase, $ConsentRecordsTable, ConsentRecord> {
  $$ConsentRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias(
        $_aliasNameGenerator(db.consentRecords.memberId, db.members.id),
      );

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ConsentRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ConsentRecordsTable> {
  $$ConsentRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get consentVersion => $composableBuilder(
    column: $table.consentVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consentedAt => $composableBuilder(
    column: $table.consentedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ashaId => $composableBuilder(
    column: $table.ashaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get witnessType => $composableBuilder(
    column: $table.witnessType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signatureHash => $composableBuilder(
    column: $table.signatureHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voiceAckAudioHash => $composableBuilder(
    column: $table.voiceAckAudioHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGuardianConsent => $composableBuilder(
    column: $table.isGuardianConsent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get guardianRelationship => $composableBuilder(
    column: $table.guardianRelationship,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get withdrawnAt => $composableBuilder(
    column: $table.withdrawnAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get withdrawalReason => $composableBuilder(
    column: $table.withdrawalReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConsentRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConsentRecordsTable> {
  $$ConsentRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get consentVersion => $composableBuilder(
    column: $table.consentVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consentedAt => $composableBuilder(
    column: $table.consentedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ashaId => $composableBuilder(
    column: $table.ashaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get witnessType => $composableBuilder(
    column: $table.witnessType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signatureHash => $composableBuilder(
    column: $table.signatureHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceAckAudioHash => $composableBuilder(
    column: $table.voiceAckAudioHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGuardianConsent => $composableBuilder(
    column: $table.isGuardianConsent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get guardianRelationship => $composableBuilder(
    column: $table.guardianRelationship,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get withdrawnAt => $composableBuilder(
    column: $table.withdrawnAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get withdrawalReason => $composableBuilder(
    column: $table.withdrawalReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConsentRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConsentRecordsTable> {
  $$ConsentRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get consentVersion => $composableBuilder(
    column: $table.consentVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consentedAt => $composableBuilder(
    column: $table.consentedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ashaId =>
      $composableBuilder(column: $table.ashaId, builder: (column) => column);

  GeneratedColumn<String> get witnessType => $composableBuilder(
    column: $table.witnessType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get signatureHash => $composableBuilder(
    column: $table.signatureHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get voiceAckAudioHash => $composableBuilder(
    column: $table.voiceAckAudioHash,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isGuardianConsent => $composableBuilder(
    column: $table.isGuardianConsent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get guardianRelationship => $composableBuilder(
    column: $table.guardianRelationship,
    builder: (column) => column,
  );

  GeneratedColumn<int> get withdrawnAt => $composableBuilder(
    column: $table.withdrawnAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get withdrawalReason => $composableBuilder(
    column: $table.withdrawalReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ConsentRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConsentRecordsTable,
          ConsentRecord,
          $$ConsentRecordsTableFilterComposer,
          $$ConsentRecordsTableOrderingComposer,
          $$ConsentRecordsTableAnnotationComposer,
          $$ConsentRecordsTableCreateCompanionBuilder,
          $$ConsentRecordsTableUpdateCompanionBuilder,
          (ConsentRecord, $$ConsentRecordsTableReferences),
          ConsentRecord,
          PrefetchHooks Function({bool memberId})
        > {
  $$ConsentRecordsTableTableManager(
    _$AppDatabase db,
    $ConsentRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsentRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsentRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsentRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> consentVersion = const Value.absent(),
                Value<int> consentedAt = const Value.absent(),
                Value<String> ashaId = const Value.absent(),
                Value<String> witnessType = const Value.absent(),
                Value<String> signatureHash = const Value.absent(),
                Value<String?> voiceAckAudioHash = const Value.absent(),
                Value<bool> isGuardianConsent = const Value.absent(),
                Value<String?> guardianRelationship = const Value.absent(),
                Value<int?> withdrawnAt = const Value.absent(),
                Value<String?> withdrawalReason = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConsentRecordsCompanion(
                id: id,
                memberId: memberId,
                consentVersion: consentVersion,
                consentedAt: consentedAt,
                ashaId: ashaId,
                witnessType: witnessType,
                signatureHash: signatureHash,
                voiceAckAudioHash: voiceAckAudioHash,
                isGuardianConsent: isGuardianConsent,
                guardianRelationship: guardianRelationship,
                withdrawnAt: withdrawnAt,
                withdrawalReason: withdrawalReason,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String consentVersion,
                required int consentedAt,
                required String ashaId,
                required String witnessType,
                required String signatureHash,
                Value<String?> voiceAckAudioHash = const Value.absent(),
                Value<bool> isGuardianConsent = const Value.absent(),
                Value<String?> guardianRelationship = const Value.absent(),
                Value<int?> withdrawnAt = const Value.absent(),
                Value<String?> withdrawalReason = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConsentRecordsCompanion.insert(
                id: id,
                memberId: memberId,
                consentVersion: consentVersion,
                consentedAt: consentedAt,
                ashaId: ashaId,
                witnessType: witnessType,
                signatureHash: signatureHash,
                voiceAckAudioHash: voiceAckAudioHash,
                isGuardianConsent: isGuardianConsent,
                guardianRelationship: guardianRelationship,
                withdrawnAt: withdrawnAt,
                withdrawalReason: withdrawalReason,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConsentRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable: $$ConsentRecordsTableReferences
                                    ._memberIdTable(db),
                                referencedColumn:
                                    $$ConsentRecordsTableReferences
                                        ._memberIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ConsentRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConsentRecordsTable,
      ConsentRecord,
      $$ConsentRecordsTableFilterComposer,
      $$ConsentRecordsTableOrderingComposer,
      $$ConsentRecordsTableAnnotationComposer,
      $$ConsentRecordsTableCreateCompanionBuilder,
      $$ConsentRecordsTableUpdateCompanionBuilder,
      (ConsentRecord, $$ConsentRecordsTableReferences),
      ConsentRecord,
      PrefetchHooks Function({bool memberId})
    >;
typedef $$ClinicalEncountersTableCreateCompanionBuilder =
    ClinicalEncountersCompanion Function({
      required String id,
      required String memberId,
      required String encounterType,
      required String programCode,
      required int encounterDate,
      required String ashaId,
      Value<String?> ruleVersionId,
      Value<String> status,
      Value<String?> visitNotes,
      required int createdAt,
      required int updatedAt,
      Value<String> syncStatus,
      Value<int?> serverVersion,
      Value<int> rowid,
    });
typedef $$ClinicalEncountersTableUpdateCompanionBuilder =
    ClinicalEncountersCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> encounterType,
      Value<String> programCode,
      Value<int> encounterDate,
      Value<String> ashaId,
      Value<String?> ruleVersionId,
      Value<String> status,
      Value<String?> visitNotes,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> syncStatus,
      Value<int?> serverVersion,
      Value<int> rowid,
    });

final class $$ClinicalEncountersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ClinicalEncountersTable,
          ClinicalEncounter
        > {
  $$ClinicalEncountersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias(
        $_aliasNameGenerator(db.clinicalEncounters.memberId, db.members.id),
      );

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $ClinicalObservationsTable,
    List<ClinicalObservation>
  >
  _clinicalObservationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.clinicalObservations,
        aliasName: $_aliasNameGenerator(
          db.clinicalEncounters.id,
          db.clinicalObservations.encounterId,
        ),
      );

  $$ClinicalObservationsTableProcessedTableManager
  get clinicalObservationsRefs {
    final manager = $$ClinicalObservationsTableTableManager(
      $_db,
      $_db.clinicalObservations,
    ).filter((f) => f.encounterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _clinicalObservationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TriageResultsTable, List<TriageResult>>
  _triageResultsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.triageResults,
    aliasName: $_aliasNameGenerator(
      db.clinicalEncounters.id,
      db.triageResults.encounterId,
    ),
  );

  $$TriageResultsTableProcessedTableManager get triageResultsRefs {
    final manager = $$TriageResultsTableTableManager(
      $_db,
      $_db.triageResults,
    ).filter((f) => f.encounterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_triageResultsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReferralRecordsTable, List<ReferralRecord>>
  _referralRecordsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.referralRecords,
    aliasName: $_aliasNameGenerator(
      db.clinicalEncounters.id,
      db.referralRecords.encounterId,
    ),
  );

  $$ReferralRecordsTableProcessedTableManager get referralRecordsRefs {
    final manager = $$ReferralRecordsTableTableManager(
      $_db,
      $_db.referralRecords,
    ).filter((f) => f.encounterId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _referralRecordsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClinicalEncountersTableFilterComposer
    extends Composer<_$AppDatabase, $ClinicalEncountersTable> {
  $$ClinicalEncountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encounterType => $composableBuilder(
    column: $table.encounterType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get programCode => $composableBuilder(
    column: $table.programCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get encounterDate => $composableBuilder(
    column: $table.encounterDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ashaId => $composableBuilder(
    column: $table.ashaId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleVersionId => $composableBuilder(
    column: $table.ruleVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitNotes => $composableBuilder(
    column: $table.visitNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> clinicalObservationsRefs(
    Expression<bool> Function($$ClinicalObservationsTableFilterComposer f) f,
  ) {
    final $$ClinicalObservationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.clinicalObservations,
      getReferencedColumn: (t) => t.encounterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClinicalObservationsTableFilterComposer(
            $db: $db,
            $table: $db.clinicalObservations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> triageResultsRefs(
    Expression<bool> Function($$TriageResultsTableFilterComposer f) f,
  ) {
    final $$TriageResultsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.triageResults,
      getReferencedColumn: (t) => t.encounterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TriageResultsTableFilterComposer(
            $db: $db,
            $table: $db.triageResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> referralRecordsRefs(
    Expression<bool> Function($$ReferralRecordsTableFilterComposer f) f,
  ) {
    final $$ReferralRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.referralRecords,
      getReferencedColumn: (t) => t.encounterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferralRecordsTableFilterComposer(
            $db: $db,
            $table: $db.referralRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClinicalEncountersTableOrderingComposer
    extends Composer<_$AppDatabase, $ClinicalEncountersTable> {
  $$ClinicalEncountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encounterType => $composableBuilder(
    column: $table.encounterType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get programCode => $composableBuilder(
    column: $table.programCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get encounterDate => $composableBuilder(
    column: $table.encounterDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ashaId => $composableBuilder(
    column: $table.ashaId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleVersionId => $composableBuilder(
    column: $table.ruleVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitNotes => $composableBuilder(
    column: $table.visitNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClinicalEncountersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClinicalEncountersTable> {
  $$ClinicalEncountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get encounterType => $composableBuilder(
    column: $table.encounterType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get programCode => $composableBuilder(
    column: $table.programCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get encounterDate => $composableBuilder(
    column: $table.encounterDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ashaId =>
      $composableBuilder(column: $table.ashaId, builder: (column) => column);

  GeneratedColumn<String> get ruleVersionId => $composableBuilder(
    column: $table.ruleVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get visitNotes => $composableBuilder(
    column: $table.visitNotes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverVersion => $composableBuilder(
    column: $table.serverVersion,
    builder: (column) => column,
  );

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> clinicalObservationsRefs<T extends Object>(
    Expression<T> Function($$ClinicalObservationsTableAnnotationComposer a) f,
  ) {
    final $$ClinicalObservationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.clinicalObservations,
          getReferencedColumn: (t) => t.encounterId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClinicalObservationsTableAnnotationComposer(
                $db: $db,
                $table: $db.clinicalObservations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> triageResultsRefs<T extends Object>(
    Expression<T> Function($$TriageResultsTableAnnotationComposer a) f,
  ) {
    final $$TriageResultsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.triageResults,
      getReferencedColumn: (t) => t.encounterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TriageResultsTableAnnotationComposer(
            $db: $db,
            $table: $db.triageResults,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> referralRecordsRefs<T extends Object>(
    Expression<T> Function($$ReferralRecordsTableAnnotationComposer a) f,
  ) {
    final $$ReferralRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.referralRecords,
      getReferencedColumn: (t) => t.encounterId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReferralRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.referralRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClinicalEncountersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClinicalEncountersTable,
          ClinicalEncounter,
          $$ClinicalEncountersTableFilterComposer,
          $$ClinicalEncountersTableOrderingComposer,
          $$ClinicalEncountersTableAnnotationComposer,
          $$ClinicalEncountersTableCreateCompanionBuilder,
          $$ClinicalEncountersTableUpdateCompanionBuilder,
          (ClinicalEncounter, $$ClinicalEncountersTableReferences),
          ClinicalEncounter,
          PrefetchHooks Function({
            bool memberId,
            bool clinicalObservationsRefs,
            bool triageResultsRefs,
            bool referralRecordsRefs,
          })
        > {
  $$ClinicalEncountersTableTableManager(
    _$AppDatabase db,
    $ClinicalEncountersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClinicalEncountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClinicalEncountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClinicalEncountersTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> encounterType = const Value.absent(),
                Value<String> programCode = const Value.absent(),
                Value<int> encounterDate = const Value.absent(),
                Value<String> ashaId = const Value.absent(),
                Value<String?> ruleVersionId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> visitNotes = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClinicalEncountersCompanion(
                id: id,
                memberId: memberId,
                encounterType: encounterType,
                programCode: programCode,
                encounterDate: encounterDate,
                ashaId: ashaId,
                ruleVersionId: ruleVersionId,
                status: status,
                visitNotes: visitNotes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                serverVersion: serverVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String encounterType,
                required String programCode,
                required int encounterDate,
                required String ashaId,
                Value<String?> ruleVersionId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> visitNotes = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int?> serverVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClinicalEncountersCompanion.insert(
                id: id,
                memberId: memberId,
                encounterType: encounterType,
                programCode: programCode,
                encounterDate: encounterDate,
                ashaId: ashaId,
                ruleVersionId: ruleVersionId,
                status: status,
                visitNotes: visitNotes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                serverVersion: serverVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ClinicalEncountersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                memberId = false,
                clinicalObservationsRefs = false,
                triageResultsRefs = false,
                referralRecordsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (clinicalObservationsRefs) db.clinicalObservations,
                    if (triageResultsRefs) db.triageResults,
                    if (referralRecordsRefs) db.referralRecords,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (memberId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.memberId,
                                    referencedTable:
                                        $$ClinicalEncountersTableReferences
                                            ._memberIdTable(db),
                                    referencedColumn:
                                        $$ClinicalEncountersTableReferences
                                            ._memberIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (clinicalObservationsRefs)
                        await $_getPrefetchedData<
                          ClinicalEncounter,
                          $ClinicalEncountersTable,
                          ClinicalObservation
                        >(
                          currentTable: table,
                          referencedTable: $$ClinicalEncountersTableReferences
                              ._clinicalObservationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClinicalEncountersTableReferences(
                                db,
                                table,
                                p0,
                              ).clinicalObservationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.encounterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (triageResultsRefs)
                        await $_getPrefetchedData<
                          ClinicalEncounter,
                          $ClinicalEncountersTable,
                          TriageResult
                        >(
                          currentTable: table,
                          referencedTable: $$ClinicalEncountersTableReferences
                              ._triageResultsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClinicalEncountersTableReferences(
                                db,
                                table,
                                p0,
                              ).triageResultsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.encounterId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (referralRecordsRefs)
                        await $_getPrefetchedData<
                          ClinicalEncounter,
                          $ClinicalEncountersTable,
                          ReferralRecord
                        >(
                          currentTable: table,
                          referencedTable: $$ClinicalEncountersTableReferences
                              ._referralRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ClinicalEncountersTableReferences(
                                db,
                                table,
                                p0,
                              ).referralRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.encounterId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ClinicalEncountersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClinicalEncountersTable,
      ClinicalEncounter,
      $$ClinicalEncountersTableFilterComposer,
      $$ClinicalEncountersTableOrderingComposer,
      $$ClinicalEncountersTableAnnotationComposer,
      $$ClinicalEncountersTableCreateCompanionBuilder,
      $$ClinicalEncountersTableUpdateCompanionBuilder,
      (ClinicalEncounter, $$ClinicalEncountersTableReferences),
      ClinicalEncounter,
      PrefetchHooks Function({
        bool memberId,
        bool clinicalObservationsRefs,
        bool triageResultsRefs,
        bool referralRecordsRefs,
      })
    >;
typedef $$ClinicalObservationsTableCreateCompanionBuilder =
    ClinicalObservationsCompanion Function({
      required String id,
      required String encounterId,
      required String observationCode,
      Value<String?> valueText,
      Value<double?> valueNumeric,
      Value<String?> valueUnit,
      Value<String?> valueEnum,
      Value<String> source,
      required int observedAt,
      Value<int> rowid,
    });
typedef $$ClinicalObservationsTableUpdateCompanionBuilder =
    ClinicalObservationsCompanion Function({
      Value<String> id,
      Value<String> encounterId,
      Value<String> observationCode,
      Value<String?> valueText,
      Value<double?> valueNumeric,
      Value<String?> valueUnit,
      Value<String?> valueEnum,
      Value<String> source,
      Value<int> observedAt,
      Value<int> rowid,
    });

final class $$ClinicalObservationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ClinicalObservationsTable,
          ClinicalObservation
        > {
  $$ClinicalObservationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClinicalEncountersTable _encounterIdTable(_$AppDatabase db) =>
      db.clinicalEncounters.createAlias(
        $_aliasNameGenerator(
          db.clinicalObservations.encounterId,
          db.clinicalEncounters.id,
        ),
      );

  $$ClinicalEncountersTableProcessedTableManager get encounterId {
    final $_column = $_itemColumn<String>('encounter_id')!;

    final manager = $$ClinicalEncountersTableTableManager(
      $_db,
      $_db.clinicalEncounters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_encounterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ClinicalObservationsTableFilterComposer
    extends Composer<_$AppDatabase, $ClinicalObservationsTable> {
  $$ClinicalObservationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observationCode => $composableBuilder(
    column: $table.observationCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueText => $composableBuilder(
    column: $table.valueText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valueNumeric => $composableBuilder(
    column: $table.valueNumeric,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueUnit => $composableBuilder(
    column: $table.valueUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueEnum => $composableBuilder(
    column: $table.valueEnum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ClinicalEncountersTableFilterComposer get encounterId {
    final $$ClinicalEncountersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.encounterId,
      referencedTable: $db.clinicalEncounters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClinicalEncountersTableFilterComposer(
            $db: $db,
            $table: $db.clinicalEncounters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClinicalObservationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClinicalObservationsTable> {
  $$ClinicalObservationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observationCode => $composableBuilder(
    column: $table.observationCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueText => $composableBuilder(
    column: $table.valueText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valueNumeric => $composableBuilder(
    column: $table.valueNumeric,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueUnit => $composableBuilder(
    column: $table.valueUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueEnum => $composableBuilder(
    column: $table.valueEnum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClinicalEncountersTableOrderingComposer get encounterId {
    final $$ClinicalEncountersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.encounterId,
      referencedTable: $db.clinicalEncounters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClinicalEncountersTableOrderingComposer(
            $db: $db,
            $table: $db.clinicalEncounters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ClinicalObservationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClinicalObservationsTable> {
  $$ClinicalObservationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get observationCode => $composableBuilder(
    column: $table.observationCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valueText =>
      $composableBuilder(column: $table.valueText, builder: (column) => column);

  GeneratedColumn<double> get valueNumeric => $composableBuilder(
    column: $table.valueNumeric,
    builder: (column) => column,
  );

  GeneratedColumn<String> get valueUnit =>
      $composableBuilder(column: $table.valueUnit, builder: (column) => column);

  GeneratedColumn<String> get valueEnum =>
      $composableBuilder(column: $table.valueEnum, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => column,
  );

  $$ClinicalEncountersTableAnnotationComposer get encounterId {
    final $$ClinicalEncountersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.encounterId,
          referencedTable: $db.clinicalEncounters,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClinicalEncountersTableAnnotationComposer(
                $db: $db,
                $table: $db.clinicalEncounters,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$ClinicalObservationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClinicalObservationsTable,
          ClinicalObservation,
          $$ClinicalObservationsTableFilterComposer,
          $$ClinicalObservationsTableOrderingComposer,
          $$ClinicalObservationsTableAnnotationComposer,
          $$ClinicalObservationsTableCreateCompanionBuilder,
          $$ClinicalObservationsTableUpdateCompanionBuilder,
          (ClinicalObservation, $$ClinicalObservationsTableReferences),
          ClinicalObservation,
          PrefetchHooks Function({bool encounterId})
        > {
  $$ClinicalObservationsTableTableManager(
    _$AppDatabase db,
    $ClinicalObservationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClinicalObservationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClinicalObservationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ClinicalObservationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> encounterId = const Value.absent(),
                Value<String> observationCode = const Value.absent(),
                Value<String?> valueText = const Value.absent(),
                Value<double?> valueNumeric = const Value.absent(),
                Value<String?> valueUnit = const Value.absent(),
                Value<String?> valueEnum = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> observedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClinicalObservationsCompanion(
                id: id,
                encounterId: encounterId,
                observationCode: observationCode,
                valueText: valueText,
                valueNumeric: valueNumeric,
                valueUnit: valueUnit,
                valueEnum: valueEnum,
                source: source,
                observedAt: observedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String encounterId,
                required String observationCode,
                Value<String?> valueText = const Value.absent(),
                Value<double?> valueNumeric = const Value.absent(),
                Value<String?> valueUnit = const Value.absent(),
                Value<String?> valueEnum = const Value.absent(),
                Value<String> source = const Value.absent(),
                required int observedAt,
                Value<int> rowid = const Value.absent(),
              }) => ClinicalObservationsCompanion.insert(
                id: id,
                encounterId: encounterId,
                observationCode: observationCode,
                valueText: valueText,
                valueNumeric: valueNumeric,
                valueUnit: valueUnit,
                valueEnum: valueEnum,
                source: source,
                observedAt: observedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ClinicalObservationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({encounterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (encounterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.encounterId,
                                referencedTable:
                                    $$ClinicalObservationsTableReferences
                                        ._encounterIdTable(db),
                                referencedColumn:
                                    $$ClinicalObservationsTableReferences
                                        ._encounterIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ClinicalObservationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClinicalObservationsTable,
      ClinicalObservation,
      $$ClinicalObservationsTableFilterComposer,
      $$ClinicalObservationsTableOrderingComposer,
      $$ClinicalObservationsTableAnnotationComposer,
      $$ClinicalObservationsTableCreateCompanionBuilder,
      $$ClinicalObservationsTableUpdateCompanionBuilder,
      (ClinicalObservation, $$ClinicalObservationsTableReferences),
      ClinicalObservation,
      PrefetchHooks Function({bool encounterId})
    >;
typedef $$TriageResultsTableCreateCompanionBuilder =
    TriageResultsCompanion Function({
      required String id,
      required String encounterId,
      required String flag,
      required String ruleVersionId,
      required String findingsJson,
      Value<String> missingFieldsJson,
      Value<bool> escalatedForMissingData,
      Value<String?> mlContributionJson,
      Value<String?> overrideFlag,
      Value<String?> overrideReason,
      Value<String?> overrideVoiceNotePath,
      Value<String?> overridingUserId,
      required int evaluatedAt,
      Value<int?> overriddenAt,
      Value<int> rowid,
    });
typedef $$TriageResultsTableUpdateCompanionBuilder =
    TriageResultsCompanion Function({
      Value<String> id,
      Value<String> encounterId,
      Value<String> flag,
      Value<String> ruleVersionId,
      Value<String> findingsJson,
      Value<String> missingFieldsJson,
      Value<bool> escalatedForMissingData,
      Value<String?> mlContributionJson,
      Value<String?> overrideFlag,
      Value<String?> overrideReason,
      Value<String?> overrideVoiceNotePath,
      Value<String?> overridingUserId,
      Value<int> evaluatedAt,
      Value<int?> overriddenAt,
      Value<int> rowid,
    });

final class $$TriageResultsTableReferences
    extends BaseReferences<_$AppDatabase, $TriageResultsTable, TriageResult> {
  $$TriageResultsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClinicalEncountersTable _encounterIdTable(_$AppDatabase db) =>
      db.clinicalEncounters.createAlias(
        $_aliasNameGenerator(
          db.triageResults.encounterId,
          db.clinicalEncounters.id,
        ),
      );

  $$ClinicalEncountersTableProcessedTableManager get encounterId {
    final $_column = $_itemColumn<String>('encounter_id')!;

    final manager = $$ClinicalEncountersTableTableManager(
      $_db,
      $_db.clinicalEncounters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_encounterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TriageResultsTableFilterComposer
    extends Composer<_$AppDatabase, $TriageResultsTable> {
  $$TriageResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get flag => $composableBuilder(
    column: $table.flag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleVersionId => $composableBuilder(
    column: $table.ruleVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get findingsJson => $composableBuilder(
    column: $table.findingsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get missingFieldsJson => $composableBuilder(
    column: $table.missingFieldsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get escalatedForMissingData => $composableBuilder(
    column: $table.escalatedForMissingData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mlContributionJson => $composableBuilder(
    column: $table.mlContributionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overrideFlag => $composableBuilder(
    column: $table.overrideFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overrideReason => $composableBuilder(
    column: $table.overrideReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overrideVoiceNotePath => $composableBuilder(
    column: $table.overrideVoiceNotePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overridingUserId => $composableBuilder(
    column: $table.overridingUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get evaluatedAt => $composableBuilder(
    column: $table.evaluatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overriddenAt => $composableBuilder(
    column: $table.overriddenAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ClinicalEncountersTableFilterComposer get encounterId {
    final $$ClinicalEncountersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.encounterId,
      referencedTable: $db.clinicalEncounters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClinicalEncountersTableFilterComposer(
            $db: $db,
            $table: $db.clinicalEncounters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TriageResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $TriageResultsTable> {
  $$TriageResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get flag => $composableBuilder(
    column: $table.flag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleVersionId => $composableBuilder(
    column: $table.ruleVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get findingsJson => $composableBuilder(
    column: $table.findingsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get missingFieldsJson => $composableBuilder(
    column: $table.missingFieldsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get escalatedForMissingData => $composableBuilder(
    column: $table.escalatedForMissingData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mlContributionJson => $composableBuilder(
    column: $table.mlContributionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overrideFlag => $composableBuilder(
    column: $table.overrideFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overrideReason => $composableBuilder(
    column: $table.overrideReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overrideVoiceNotePath => $composableBuilder(
    column: $table.overrideVoiceNotePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overridingUserId => $composableBuilder(
    column: $table.overridingUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get evaluatedAt => $composableBuilder(
    column: $table.evaluatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overriddenAt => $composableBuilder(
    column: $table.overriddenAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClinicalEncountersTableOrderingComposer get encounterId {
    final $$ClinicalEncountersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.encounterId,
      referencedTable: $db.clinicalEncounters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClinicalEncountersTableOrderingComposer(
            $db: $db,
            $table: $db.clinicalEncounters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TriageResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TriageResultsTable> {
  $$TriageResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get flag =>
      $composableBuilder(column: $table.flag, builder: (column) => column);

  GeneratedColumn<String> get ruleVersionId => $composableBuilder(
    column: $table.ruleVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get findingsJson => $composableBuilder(
    column: $table.findingsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get missingFieldsJson => $composableBuilder(
    column: $table.missingFieldsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get escalatedForMissingData => $composableBuilder(
    column: $table.escalatedForMissingData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mlContributionJson => $composableBuilder(
    column: $table.mlContributionJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overrideFlag => $composableBuilder(
    column: $table.overrideFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overrideReason => $composableBuilder(
    column: $table.overrideReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overrideVoiceNotePath => $composableBuilder(
    column: $table.overrideVoiceNotePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get overridingUserId => $composableBuilder(
    column: $table.overridingUserId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get evaluatedAt => $composableBuilder(
    column: $table.evaluatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overriddenAt => $composableBuilder(
    column: $table.overriddenAt,
    builder: (column) => column,
  );

  $$ClinicalEncountersTableAnnotationComposer get encounterId {
    final $$ClinicalEncountersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.encounterId,
          referencedTable: $db.clinicalEncounters,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClinicalEncountersTableAnnotationComposer(
                $db: $db,
                $table: $db.clinicalEncounters,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$TriageResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TriageResultsTable,
          TriageResult,
          $$TriageResultsTableFilterComposer,
          $$TriageResultsTableOrderingComposer,
          $$TriageResultsTableAnnotationComposer,
          $$TriageResultsTableCreateCompanionBuilder,
          $$TriageResultsTableUpdateCompanionBuilder,
          (TriageResult, $$TriageResultsTableReferences),
          TriageResult,
          PrefetchHooks Function({bool encounterId})
        > {
  $$TriageResultsTableTableManager(_$AppDatabase db, $TriageResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TriageResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TriageResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TriageResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> encounterId = const Value.absent(),
                Value<String> flag = const Value.absent(),
                Value<String> ruleVersionId = const Value.absent(),
                Value<String> findingsJson = const Value.absent(),
                Value<String> missingFieldsJson = const Value.absent(),
                Value<bool> escalatedForMissingData = const Value.absent(),
                Value<String?> mlContributionJson = const Value.absent(),
                Value<String?> overrideFlag = const Value.absent(),
                Value<String?> overrideReason = const Value.absent(),
                Value<String?> overrideVoiceNotePath = const Value.absent(),
                Value<String?> overridingUserId = const Value.absent(),
                Value<int> evaluatedAt = const Value.absent(),
                Value<int?> overriddenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TriageResultsCompanion(
                id: id,
                encounterId: encounterId,
                flag: flag,
                ruleVersionId: ruleVersionId,
                findingsJson: findingsJson,
                missingFieldsJson: missingFieldsJson,
                escalatedForMissingData: escalatedForMissingData,
                mlContributionJson: mlContributionJson,
                overrideFlag: overrideFlag,
                overrideReason: overrideReason,
                overrideVoiceNotePath: overrideVoiceNotePath,
                overridingUserId: overridingUserId,
                evaluatedAt: evaluatedAt,
                overriddenAt: overriddenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String encounterId,
                required String flag,
                required String ruleVersionId,
                required String findingsJson,
                Value<String> missingFieldsJson = const Value.absent(),
                Value<bool> escalatedForMissingData = const Value.absent(),
                Value<String?> mlContributionJson = const Value.absent(),
                Value<String?> overrideFlag = const Value.absent(),
                Value<String?> overrideReason = const Value.absent(),
                Value<String?> overrideVoiceNotePath = const Value.absent(),
                Value<String?> overridingUserId = const Value.absent(),
                required int evaluatedAt,
                Value<int?> overriddenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TriageResultsCompanion.insert(
                id: id,
                encounterId: encounterId,
                flag: flag,
                ruleVersionId: ruleVersionId,
                findingsJson: findingsJson,
                missingFieldsJson: missingFieldsJson,
                escalatedForMissingData: escalatedForMissingData,
                mlContributionJson: mlContributionJson,
                overrideFlag: overrideFlag,
                overrideReason: overrideReason,
                overrideVoiceNotePath: overrideVoiceNotePath,
                overridingUserId: overridingUserId,
                evaluatedAt: evaluatedAt,
                overriddenAt: overriddenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TriageResultsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({encounterId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (encounterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.encounterId,
                                referencedTable: $$TriageResultsTableReferences
                                    ._encounterIdTable(db),
                                referencedColumn: $$TriageResultsTableReferences
                                    ._encounterIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$TriageResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TriageResultsTable,
      TriageResult,
      $$TriageResultsTableFilterComposer,
      $$TriageResultsTableOrderingComposer,
      $$TriageResultsTableAnnotationComposer,
      $$TriageResultsTableCreateCompanionBuilder,
      $$TriageResultsTableUpdateCompanionBuilder,
      (TriageResult, $$TriageResultsTableReferences),
      TriageResult,
      PrefetchHooks Function({bool encounterId})
    >;
typedef $$ReferralRecordsTableCreateCompanionBuilder =
    ReferralRecordsCompanion Function({
      required String id,
      required String encounterId,
      required String memberId,
      required String triageFlag,
      Value<String?> destinationFacilityId,
      Value<String?> destinationLevel,
      Value<String?> transportArranged,
      Value<String> status,
      Value<String?> outcome,
      Value<String?> outcomeRecordedBy,
      Value<int?> outcomeRecordedAt,
      Value<String?> referralNoteText,
      Value<String?> referralPdfPath,
      Value<String?> referralQrData,
      required int createdAt,
      required int updatedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$ReferralRecordsTableUpdateCompanionBuilder =
    ReferralRecordsCompanion Function({
      Value<String> id,
      Value<String> encounterId,
      Value<String> memberId,
      Value<String> triageFlag,
      Value<String?> destinationFacilityId,
      Value<String?> destinationLevel,
      Value<String?> transportArranged,
      Value<String> status,
      Value<String?> outcome,
      Value<String?> outcomeRecordedBy,
      Value<int?> outcomeRecordedAt,
      Value<String?> referralNoteText,
      Value<String?> referralPdfPath,
      Value<String?> referralQrData,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$ReferralRecordsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ReferralRecordsTable, ReferralRecord> {
  $$ReferralRecordsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ClinicalEncountersTable _encounterIdTable(_$AppDatabase db) =>
      db.clinicalEncounters.createAlias(
        $_aliasNameGenerator(
          db.referralRecords.encounterId,
          db.clinicalEncounters.id,
        ),
      );

  $$ClinicalEncountersTableProcessedTableManager get encounterId {
    final $_column = $_itemColumn<String>('encounter_id')!;

    final manager = $$ClinicalEncountersTableTableManager(
      $_db,
      $_db.clinicalEncounters,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_encounterIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias(
        $_aliasNameGenerator(db.referralRecords.memberId, db.members.id),
      );

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReferralRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $ReferralRecordsTable> {
  $$ReferralRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get triageFlag => $composableBuilder(
    column: $table.triageFlag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationFacilityId => $composableBuilder(
    column: $table.destinationFacilityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get destinationLevel => $composableBuilder(
    column: $table.destinationLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transportArranged => $composableBuilder(
    column: $table.transportArranged,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcomeRecordedBy => $composableBuilder(
    column: $table.outcomeRecordedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outcomeRecordedAt => $composableBuilder(
    column: $table.outcomeRecordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referralNoteText => $composableBuilder(
    column: $table.referralNoteText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referralPdfPath => $composableBuilder(
    column: $table.referralPdfPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referralQrData => $composableBuilder(
    column: $table.referralQrData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$ClinicalEncountersTableFilterComposer get encounterId {
    final $$ClinicalEncountersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.encounterId,
      referencedTable: $db.clinicalEncounters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClinicalEncountersTableFilterComposer(
            $db: $db,
            $table: $db.clinicalEncounters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReferralRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReferralRecordsTable> {
  $$ReferralRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get triageFlag => $composableBuilder(
    column: $table.triageFlag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationFacilityId => $composableBuilder(
    column: $table.destinationFacilityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get destinationLevel => $composableBuilder(
    column: $table.destinationLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transportArranged => $composableBuilder(
    column: $table.transportArranged,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcomeRecordedBy => $composableBuilder(
    column: $table.outcomeRecordedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outcomeRecordedAt => $composableBuilder(
    column: $table.outcomeRecordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referralNoteText => $composableBuilder(
    column: $table.referralNoteText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referralPdfPath => $composableBuilder(
    column: $table.referralPdfPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referralQrData => $composableBuilder(
    column: $table.referralQrData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$ClinicalEncountersTableOrderingComposer get encounterId {
    final $$ClinicalEncountersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.encounterId,
      referencedTable: $db.clinicalEncounters,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClinicalEncountersTableOrderingComposer(
            $db: $db,
            $table: $db.clinicalEncounters,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReferralRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReferralRecordsTable> {
  $$ReferralRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get triageFlag => $composableBuilder(
    column: $table.triageFlag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationFacilityId => $composableBuilder(
    column: $table.destinationFacilityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get destinationLevel => $composableBuilder(
    column: $table.destinationLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transportArranged => $composableBuilder(
    column: $table.transportArranged,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get outcomeRecordedBy => $composableBuilder(
    column: $table.outcomeRecordedBy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outcomeRecordedAt => $composableBuilder(
    column: $table.outcomeRecordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referralNoteText => $composableBuilder(
    column: $table.referralNoteText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referralPdfPath => $composableBuilder(
    column: $table.referralPdfPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referralQrData => $composableBuilder(
    column: $table.referralQrData,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$ClinicalEncountersTableAnnotationComposer get encounterId {
    final $$ClinicalEncountersTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.encounterId,
          referencedTable: $db.clinicalEncounters,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$ClinicalEncountersTableAnnotationComposer(
                $db: $db,
                $table: $db.clinicalEncounters,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReferralRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReferralRecordsTable,
          ReferralRecord,
          $$ReferralRecordsTableFilterComposer,
          $$ReferralRecordsTableOrderingComposer,
          $$ReferralRecordsTableAnnotationComposer,
          $$ReferralRecordsTableCreateCompanionBuilder,
          $$ReferralRecordsTableUpdateCompanionBuilder,
          (ReferralRecord, $$ReferralRecordsTableReferences),
          ReferralRecord,
          PrefetchHooks Function({bool encounterId, bool memberId})
        > {
  $$ReferralRecordsTableTableManager(
    _$AppDatabase db,
    $ReferralRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReferralRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReferralRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReferralRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> encounterId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> triageFlag = const Value.absent(),
                Value<String?> destinationFacilityId = const Value.absent(),
                Value<String?> destinationLevel = const Value.absent(),
                Value<String?> transportArranged = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
                Value<String?> outcomeRecordedBy = const Value.absent(),
                Value<int?> outcomeRecordedAt = const Value.absent(),
                Value<String?> referralNoteText = const Value.absent(),
                Value<String?> referralPdfPath = const Value.absent(),
                Value<String?> referralQrData = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReferralRecordsCompanion(
                id: id,
                encounterId: encounterId,
                memberId: memberId,
                triageFlag: triageFlag,
                destinationFacilityId: destinationFacilityId,
                destinationLevel: destinationLevel,
                transportArranged: transportArranged,
                status: status,
                outcome: outcome,
                outcomeRecordedBy: outcomeRecordedBy,
                outcomeRecordedAt: outcomeRecordedAt,
                referralNoteText: referralNoteText,
                referralPdfPath: referralPdfPath,
                referralQrData: referralQrData,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String encounterId,
                required String memberId,
                required String triageFlag,
                Value<String?> destinationFacilityId = const Value.absent(),
                Value<String?> destinationLevel = const Value.absent(),
                Value<String?> transportArranged = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> outcome = const Value.absent(),
                Value<String?> outcomeRecordedBy = const Value.absent(),
                Value<int?> outcomeRecordedAt = const Value.absent(),
                Value<String?> referralNoteText = const Value.absent(),
                Value<String?> referralPdfPath = const Value.absent(),
                Value<String?> referralQrData = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReferralRecordsCompanion.insert(
                id: id,
                encounterId: encounterId,
                memberId: memberId,
                triageFlag: triageFlag,
                destinationFacilityId: destinationFacilityId,
                destinationLevel: destinationLevel,
                transportArranged: transportArranged,
                status: status,
                outcome: outcome,
                outcomeRecordedBy: outcomeRecordedBy,
                outcomeRecordedAt: outcomeRecordedAt,
                referralNoteText: referralNoteText,
                referralPdfPath: referralPdfPath,
                referralQrData: referralQrData,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReferralRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({encounterId = false, memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (encounterId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.encounterId,
                                referencedTable:
                                    $$ReferralRecordsTableReferences
                                        ._encounterIdTable(db),
                                referencedColumn:
                                    $$ReferralRecordsTableReferences
                                        ._encounterIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable:
                                    $$ReferralRecordsTableReferences
                                        ._memberIdTable(db),
                                referencedColumn:
                                    $$ReferralRecordsTableReferences
                                        ._memberIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReferralRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReferralRecordsTable,
      ReferralRecord,
      $$ReferralRecordsTableFilterComposer,
      $$ReferralRecordsTableOrderingComposer,
      $$ReferralRecordsTableAnnotationComposer,
      $$ReferralRecordsTableCreateCompanionBuilder,
      $$ReferralRecordsTableUpdateCompanionBuilder,
      (ReferralRecord, $$ReferralRecordsTableReferences),
      ReferralRecord,
      PrefetchHooks Function({bool encounterId, bool memberId})
    >;
typedef $$VisitSchedulesTableCreateCompanionBuilder =
    VisitSchedulesCompanion Function({
      required String id,
      required String memberId,
      required String programCode,
      required String visitType,
      required int dueDate,
      Value<int?> dueWindowStart,
      Value<int?> dueWindowEnd,
      Value<String> status,
      Value<String?> skipReason,
      Value<int?> completedAt,
      Value<String?> completedEncounterId,
      required int createdAt,
      Value<int> rescheduledCount,
      Value<int> rowid,
    });
typedef $$VisitSchedulesTableUpdateCompanionBuilder =
    VisitSchedulesCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String> programCode,
      Value<String> visitType,
      Value<int> dueDate,
      Value<int?> dueWindowStart,
      Value<int?> dueWindowEnd,
      Value<String> status,
      Value<String?> skipReason,
      Value<int?> completedAt,
      Value<String?> completedEncounterId,
      Value<int> createdAt,
      Value<int> rescheduledCount,
      Value<int> rowid,
    });

final class $$VisitSchedulesTableReferences
    extends BaseReferences<_$AppDatabase, $VisitSchedulesTable, VisitSchedule> {
  $$VisitSchedulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias(
        $_aliasNameGenerator(db.visitSchedules.memberId, db.members.id),
      );

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VisitSchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $VisitSchedulesTable> {
  $$VisitSchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get programCode => $composableBuilder(
    column: $table.programCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get visitType => $composableBuilder(
    column: $table.visitType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueWindowStart => $composableBuilder(
    column: $table.dueWindowStart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueWindowEnd => $composableBuilder(
    column: $table.dueWindowEnd,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedEncounterId => $composableBuilder(
    column: $table.completedEncounterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rescheduledCount => $composableBuilder(
    column: $table.rescheduledCount,
    builder: (column) => ColumnFilters(column),
  );

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitSchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $VisitSchedulesTable> {
  $$VisitSchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get programCode => $composableBuilder(
    column: $table.programCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get visitType => $composableBuilder(
    column: $table.visitType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueWindowStart => $composableBuilder(
    column: $table.dueWindowStart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueWindowEnd => $composableBuilder(
    column: $table.dueWindowEnd,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedEncounterId => $composableBuilder(
    column: $table.completedEncounterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rescheduledCount => $composableBuilder(
    column: $table.rescheduledCount,
    builder: (column) => ColumnOrderings(column),
  );

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitSchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VisitSchedulesTable> {
  $$VisitSchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get programCode => $composableBuilder(
    column: $table.programCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get visitType =>
      $composableBuilder(column: $table.visitType, builder: (column) => column);

  GeneratedColumn<int> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get dueWindowStart => $composableBuilder(
    column: $table.dueWindowStart,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueWindowEnd => $composableBuilder(
    column: $table.dueWindowEnd,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get skipReason => $composableBuilder(
    column: $table.skipReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completedEncounterId => $composableBuilder(
    column: $table.completedEncounterId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get rescheduledCount => $composableBuilder(
    column: $table.rescheduledCount,
    builder: (column) => column,
  );

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VisitSchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VisitSchedulesTable,
          VisitSchedule,
          $$VisitSchedulesTableFilterComposer,
          $$VisitSchedulesTableOrderingComposer,
          $$VisitSchedulesTableAnnotationComposer,
          $$VisitSchedulesTableCreateCompanionBuilder,
          $$VisitSchedulesTableUpdateCompanionBuilder,
          (VisitSchedule, $$VisitSchedulesTableReferences),
          VisitSchedule,
          PrefetchHooks Function({bool memberId})
        > {
  $$VisitSchedulesTableTableManager(
    _$AppDatabase db,
    $VisitSchedulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VisitSchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VisitSchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VisitSchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String> programCode = const Value.absent(),
                Value<String> visitType = const Value.absent(),
                Value<int> dueDate = const Value.absent(),
                Value<int?> dueWindowStart = const Value.absent(),
                Value<int?> dueWindowEnd = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> skipReason = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<String?> completedEncounterId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rescheduledCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitSchedulesCompanion(
                id: id,
                memberId: memberId,
                programCode: programCode,
                visitType: visitType,
                dueDate: dueDate,
                dueWindowStart: dueWindowStart,
                dueWindowEnd: dueWindowEnd,
                status: status,
                skipReason: skipReason,
                completedAt: completedAt,
                completedEncounterId: completedEncounterId,
                createdAt: createdAt,
                rescheduledCount: rescheduledCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                required String programCode,
                required String visitType,
                required int dueDate,
                Value<int?> dueWindowStart = const Value.absent(),
                Value<int?> dueWindowEnd = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> skipReason = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<String?> completedEncounterId = const Value.absent(),
                required int createdAt,
                Value<int> rescheduledCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VisitSchedulesCompanion.insert(
                id: id,
                memberId: memberId,
                programCode: programCode,
                visitType: visitType,
                dueDate: dueDate,
                dueWindowStart: dueWindowStart,
                dueWindowEnd: dueWindowEnd,
                status: status,
                skipReason: skipReason,
                completedAt: completedAt,
                completedEncounterId: completedEncounterId,
                createdAt: createdAt,
                rescheduledCount: rescheduledCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VisitSchedulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable: $$VisitSchedulesTableReferences
                                    ._memberIdTable(db),
                                referencedColumn:
                                    $$VisitSchedulesTableReferences
                                        ._memberIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VisitSchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VisitSchedulesTable,
      VisitSchedule,
      $$VisitSchedulesTableFilterComposer,
      $$VisitSchedulesTableOrderingComposer,
      $$VisitSchedulesTableAnnotationComposer,
      $$VisitSchedulesTableCreateCompanionBuilder,
      $$VisitSchedulesTableUpdateCompanionBuilder,
      (VisitSchedule, $$VisitSchedulesTableReferences),
      VisitSchedule,
      PrefetchHooks Function({bool memberId})
    >;
typedef $$IncentiveEventsTableCreateCompanionBuilder =
    IncentiveEventsCompanion Function({
      required String id,
      required String memberId,
      Value<String?> encounterId,
      required String activityCode,
      required String catalogueVersionId,
      required int eventDate,
      Value<String> status,
      Value<String?> ineligibilityReason,
      Value<String?> evidenceRecordId,
      required int createdAt,
      required String idempotencyKey,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$IncentiveEventsTableUpdateCompanionBuilder =
    IncentiveEventsCompanion Function({
      Value<String> id,
      Value<String> memberId,
      Value<String?> encounterId,
      Value<String> activityCode,
      Value<String> catalogueVersionId,
      Value<int> eventDate,
      Value<String> status,
      Value<String?> ineligibilityReason,
      Value<String?> evidenceRecordId,
      Value<int> createdAt,
      Value<String> idempotencyKey,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$IncentiveEventsTableReferences
    extends
        BaseReferences<_$AppDatabase, $IncentiveEventsTable, IncentiveEvent> {
  $$IncentiveEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias(
        $_aliasNameGenerator(db.incentiveEvents.memberId, db.members.id),
      );

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IncentiveEventsTableFilterComposer
    extends Composer<_$AppDatabase, $IncentiveEventsTable> {
  $$IncentiveEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encounterId => $composableBuilder(
    column: $table.encounterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityCode => $composableBuilder(
    column: $table.activityCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogueVersionId => $composableBuilder(
    column: $table.catalogueVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ineligibilityReason => $composableBuilder(
    column: $table.ineligibilityReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evidenceRecordId => $composableBuilder(
    column: $table.evidenceRecordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncentiveEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $IncentiveEventsTable> {
  $$IncentiveEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encounterId => $composableBuilder(
    column: $table.encounterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityCode => $composableBuilder(
    column: $table.activityCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogueVersionId => $composableBuilder(
    column: $table.catalogueVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eventDate => $composableBuilder(
    column: $table.eventDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ineligibilityReason => $composableBuilder(
    column: $table.ineligibilityReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evidenceRecordId => $composableBuilder(
    column: $table.evidenceRecordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncentiveEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncentiveEventsTable> {
  $$IncentiveEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get encounterId => $composableBuilder(
    column: $table.encounterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get activityCode => $composableBuilder(
    column: $table.activityCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get catalogueVersionId => $composableBuilder(
    column: $table.catalogueVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get eventDate =>
      $composableBuilder(column: $table.eventDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get ineligibilityReason => $composableBuilder(
    column: $table.ineligibilityReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get evidenceRecordId => $composableBuilder(
    column: $table.evidenceRecordId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncentiveEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncentiveEventsTable,
          IncentiveEvent,
          $$IncentiveEventsTableFilterComposer,
          $$IncentiveEventsTableOrderingComposer,
          $$IncentiveEventsTableAnnotationComposer,
          $$IncentiveEventsTableCreateCompanionBuilder,
          $$IncentiveEventsTableUpdateCompanionBuilder,
          (IncentiveEvent, $$IncentiveEventsTableReferences),
          IncentiveEvent,
          PrefetchHooks Function({bool memberId})
        > {
  $$IncentiveEventsTableTableManager(
    _$AppDatabase db,
    $IncentiveEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncentiveEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncentiveEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncentiveEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<String?> encounterId = const Value.absent(),
                Value<String> activityCode = const Value.absent(),
                Value<String> catalogueVersionId = const Value.absent(),
                Value<int> eventDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> ineligibilityReason = const Value.absent(),
                Value<String?> evidenceRecordId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncentiveEventsCompanion(
                id: id,
                memberId: memberId,
                encounterId: encounterId,
                activityCode: activityCode,
                catalogueVersionId: catalogueVersionId,
                eventDate: eventDate,
                status: status,
                ineligibilityReason: ineligibilityReason,
                evidenceRecordId: evidenceRecordId,
                createdAt: createdAt,
                idempotencyKey: idempotencyKey,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String memberId,
                Value<String?> encounterId = const Value.absent(),
                required String activityCode,
                required String catalogueVersionId,
                required int eventDate,
                Value<String> status = const Value.absent(),
                Value<String?> ineligibilityReason = const Value.absent(),
                Value<String?> evidenceRecordId = const Value.absent(),
                required int createdAt,
                required String idempotencyKey,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncentiveEventsCompanion.insert(
                id: id,
                memberId: memberId,
                encounterId: encounterId,
                activityCode: activityCode,
                catalogueVersionId: catalogueVersionId,
                eventDate: eventDate,
                status: status,
                ineligibilityReason: ineligibilityReason,
                evidenceRecordId: evidenceRecordId,
                createdAt: createdAt,
                idempotencyKey: idempotencyKey,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IncentiveEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (memberId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.memberId,
                                referencedTable:
                                    $$IncentiveEventsTableReferences
                                        ._memberIdTable(db),
                                referencedColumn:
                                    $$IncentiveEventsTableReferences
                                        ._memberIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IncentiveEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncentiveEventsTable,
      IncentiveEvent,
      $$IncentiveEventsTableFilterComposer,
      $$IncentiveEventsTableOrderingComposer,
      $$IncentiveEventsTableAnnotationComposer,
      $$IncentiveEventsTableCreateCompanionBuilder,
      $$IncentiveEventsTableUpdateCompanionBuilder,
      (IncentiveEvent, $$IncentiveEventsTableReferences),
      IncentiveEvent,
      PrefetchHooks Function({bool memberId})
    >;
typedef $$IncentiveClaimsTableCreateCompanionBuilder =
    IncentiveClaimsCompanion Function({
      required String id,
      required String workerId,
      required String claimPeriod,
      Value<String> status,
      Value<String> lineItemsJson,
      Value<double> totalAmount,
      Value<String?> pdfPath,
      Value<String?> paymentReference,
      Value<int?> submittedAt,
      Value<int?> verifiedAt,
      Value<int?> paidAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$IncentiveClaimsTableUpdateCompanionBuilder =
    IncentiveClaimsCompanion Function({
      Value<String> id,
      Value<String> workerId,
      Value<String> claimPeriod,
      Value<String> status,
      Value<String> lineItemsJson,
      Value<double> totalAmount,
      Value<String?> pdfPath,
      Value<String?> paymentReference,
      Value<int?> submittedAt,
      Value<int?> verifiedAt,
      Value<int?> paidAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$IncentiveClaimsTableReferences
    extends
        BaseReferences<_$AppDatabase, $IncentiveClaimsTable, IncentiveClaim> {
  $$IncentiveClaimsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UsersTable _workerIdTable(_$AppDatabase db) => db.users.createAlias(
    $_aliasNameGenerator(db.incentiveClaims.workerId, db.users.id),
  );

  $$UsersTableProcessedTableManager get workerId {
    final $_column = $_itemColumn<String>('worker_id')!;

    final manager = $$UsersTableTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IncentiveClaimsTableFilterComposer
    extends Composer<_$AppDatabase, $IncentiveClaimsTable> {
  $$IncentiveClaimsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get claimPeriod => $composableBuilder(
    column: $table.claimPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineItemsJson => $composableBuilder(
    column: $table.lineItemsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentReference => $composableBuilder(
    column: $table.paymentReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$UsersTableFilterComposer get workerId {
    final $$UsersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workerId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncentiveClaimsTableOrderingComposer
    extends Composer<_$AppDatabase, $IncentiveClaimsTable> {
  $$IncentiveClaimsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get claimPeriod => $composableBuilder(
    column: $table.claimPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineItemsJson => $composableBuilder(
    column: $table.lineItemsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfPath => $composableBuilder(
    column: $table.pdfPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentReference => $composableBuilder(
    column: $table.paymentReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$UsersTableOrderingComposer get workerId {
    final $$UsersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workerId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncentiveClaimsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncentiveClaimsTable> {
  $$IncentiveClaimsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get claimPeriod => $composableBuilder(
    column: $table.claimPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get lineItemsJson => $composableBuilder(
    column: $table.lineItemsJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pdfPath =>
      $composableBuilder(column: $table.pdfPath, builder: (column) => column);

  GeneratedColumn<String> get paymentReference => $composableBuilder(
    column: $table.paymentReference,
    builder: (column) => column,
  );

  GeneratedColumn<int> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$UsersTableAnnotationComposer get workerId {
    final $$UsersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workerId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UsersTableAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncentiveClaimsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncentiveClaimsTable,
          IncentiveClaim,
          $$IncentiveClaimsTableFilterComposer,
          $$IncentiveClaimsTableOrderingComposer,
          $$IncentiveClaimsTableAnnotationComposer,
          $$IncentiveClaimsTableCreateCompanionBuilder,
          $$IncentiveClaimsTableUpdateCompanionBuilder,
          (IncentiveClaim, $$IncentiveClaimsTableReferences),
          IncentiveClaim,
          PrefetchHooks Function({bool workerId})
        > {
  $$IncentiveClaimsTableTableManager(
    _$AppDatabase db,
    $IncentiveClaimsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncentiveClaimsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncentiveClaimsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncentiveClaimsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workerId = const Value.absent(),
                Value<String> claimPeriod = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> lineItemsJson = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<String?> paymentReference = const Value.absent(),
                Value<int?> submittedAt = const Value.absent(),
                Value<int?> verifiedAt = const Value.absent(),
                Value<int?> paidAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncentiveClaimsCompanion(
                id: id,
                workerId: workerId,
                claimPeriod: claimPeriod,
                status: status,
                lineItemsJson: lineItemsJson,
                totalAmount: totalAmount,
                pdfPath: pdfPath,
                paymentReference: paymentReference,
                submittedAt: submittedAt,
                verifiedAt: verifiedAt,
                paidAt: paidAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workerId,
                required String claimPeriod,
                Value<String> status = const Value.absent(),
                Value<String> lineItemsJson = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String?> pdfPath = const Value.absent(),
                Value<String?> paymentReference = const Value.absent(),
                Value<int?> submittedAt = const Value.absent(),
                Value<int?> verifiedAt = const Value.absent(),
                Value<int?> paidAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncentiveClaimsCompanion.insert(
                id: id,
                workerId: workerId,
                claimPeriod: claimPeriod,
                status: status,
                lineItemsJson: lineItemsJson,
                totalAmount: totalAmount,
                pdfPath: pdfPath,
                paymentReference: paymentReference,
                submittedAt: submittedAt,
                verifiedAt: verifiedAt,
                paidAt: paidAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$IncentiveClaimsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workerId,
                                referencedTable:
                                    $$IncentiveClaimsTableReferences
                                        ._workerIdTable(db),
                                referencedColumn:
                                    $$IncentiveClaimsTableReferences
                                        ._workerIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IncentiveClaimsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncentiveClaimsTable,
      IncentiveClaim,
      $$IncentiveClaimsTableFilterComposer,
      $$IncentiveClaimsTableOrderingComposer,
      $$IncentiveClaimsTableAnnotationComposer,
      $$IncentiveClaimsTableCreateCompanionBuilder,
      $$IncentiveClaimsTableUpdateCompanionBuilder,
      (IncentiveClaim, $$IncentiveClaimsTableReferences),
      IncentiveClaim,
      PrefetchHooks Function({bool workerId})
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      required String id,
      required String targetTable,
      required String recordId,
      Value<int> priority,
      required String operation,
      required String payloadJson,
      Value<String> eventLogJson,
      Value<String> syncStatus,
      required int createdAt,
      Value<int?> lastAttemptAt,
      Value<int> attemptCount,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<String> id,
      Value<String> targetTable,
      Value<String> recordId,
      Value<int> priority,
      Value<String> operation,
      Value<String> payloadJson,
      Value<String> eventLogJson,
      Value<String> syncStatus,
      Value<int> createdAt,
      Value<int?> lastAttemptAt,
      Value<int> attemptCount,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventLogJson => $composableBuilder(
    column: $table.eventLogJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventLogJson => $composableBuilder(
    column: $table.eventLogJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetTable => $composableBuilder(
    column: $table.targetTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eventLogJson => $composableBuilder(
    column: $table.eventLogJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueData,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueData,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
          ),
          SyncQueueData,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> targetTable = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> eventLogJson = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> lastAttemptAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                targetTable: targetTable,
                recordId: recordId,
                priority: priority,
                operation: operation,
                payloadJson: payloadJson,
                eventLogJson: eventLogJson,
                syncStatus: syncStatus,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                attemptCount: attemptCount,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String targetTable,
                required String recordId,
                Value<int> priority = const Value.absent(),
                required String operation,
                required String payloadJson,
                Value<String> eventLogJson = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                required int createdAt,
                Value<int?> lastAttemptAt = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncQueueCompanion.insert(
                id: id,
                targetTable: targetTable,
                recordId: recordId,
                priority: priority,
                operation: operation,
                payloadJson: payloadJson,
                eventLogJson: eventLogJson,
                syncStatus: syncStatus,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                attemptCount: attemptCount,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueData,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueData,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>,
      ),
      SyncQueueData,
      PrefetchHooks Function()
    >;
typedef $$RuleVersionsTableCreateCompanionBuilder =
    RuleVersionsCompanion Function({
      required String id,
      required String versionString,
      required int publishedAt,
      required String bundleHash,
      Value<String?> bundlePath,
      Value<bool> isActive,
      Value<String?> clinicalLeadId,
      Value<String?> approvalSignature,
      Value<int> rowid,
    });
typedef $$RuleVersionsTableUpdateCompanionBuilder =
    RuleVersionsCompanion Function({
      Value<String> id,
      Value<String> versionString,
      Value<int> publishedAt,
      Value<String> bundleHash,
      Value<String?> bundlePath,
      Value<bool> isActive,
      Value<String?> clinicalLeadId,
      Value<String?> approvalSignature,
      Value<int> rowid,
    });

class $$RuleVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $RuleVersionsTable> {
  $$RuleVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versionString => $composableBuilder(
    column: $table.versionString,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bundleHash => $composableBuilder(
    column: $table.bundleHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bundlePath => $composableBuilder(
    column: $table.bundlePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clinicalLeadId => $composableBuilder(
    column: $table.clinicalLeadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get approvalSignature => $composableBuilder(
    column: $table.approvalSignature,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RuleVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $RuleVersionsTable> {
  $$RuleVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versionString => $composableBuilder(
    column: $table.versionString,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bundleHash => $composableBuilder(
    column: $table.bundleHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bundlePath => $composableBuilder(
    column: $table.bundlePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clinicalLeadId => $composableBuilder(
    column: $table.clinicalLeadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get approvalSignature => $composableBuilder(
    column: $table.approvalSignature,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RuleVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RuleVersionsTable> {
  $$RuleVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get versionString => $composableBuilder(
    column: $table.versionString,
    builder: (column) => column,
  );

  GeneratedColumn<int> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bundleHash => $composableBuilder(
    column: $table.bundleHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bundlePath => $composableBuilder(
    column: $table.bundlePath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get clinicalLeadId => $composableBuilder(
    column: $table.clinicalLeadId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get approvalSignature => $composableBuilder(
    column: $table.approvalSignature,
    builder: (column) => column,
  );
}

class $$RuleVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RuleVersionsTable,
          RuleVersion,
          $$RuleVersionsTableFilterComposer,
          $$RuleVersionsTableOrderingComposer,
          $$RuleVersionsTableAnnotationComposer,
          $$RuleVersionsTableCreateCompanionBuilder,
          $$RuleVersionsTableUpdateCompanionBuilder,
          (
            RuleVersion,
            BaseReferences<_$AppDatabase, $RuleVersionsTable, RuleVersion>,
          ),
          RuleVersion,
          PrefetchHooks Function()
        > {
  $$RuleVersionsTableTableManager(_$AppDatabase db, $RuleVersionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RuleVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RuleVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RuleVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> versionString = const Value.absent(),
                Value<int> publishedAt = const Value.absent(),
                Value<String> bundleHash = const Value.absent(),
                Value<String?> bundlePath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> clinicalLeadId = const Value.absent(),
                Value<String?> approvalSignature = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuleVersionsCompanion(
                id: id,
                versionString: versionString,
                publishedAt: publishedAt,
                bundleHash: bundleHash,
                bundlePath: bundlePath,
                isActive: isActive,
                clinicalLeadId: clinicalLeadId,
                approvalSignature: approvalSignature,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String versionString,
                required int publishedAt,
                required String bundleHash,
                Value<String?> bundlePath = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> clinicalLeadId = const Value.absent(),
                Value<String?> approvalSignature = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuleVersionsCompanion.insert(
                id: id,
                versionString: versionString,
                publishedAt: publishedAt,
                bundleHash: bundleHash,
                bundlePath: bundlePath,
                isActive: isActive,
                clinicalLeadId: clinicalLeadId,
                approvalSignature: approvalSignature,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RuleVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RuleVersionsTable,
      RuleVersion,
      $$RuleVersionsTableFilterComposer,
      $$RuleVersionsTableOrderingComposer,
      $$RuleVersionsTableAnnotationComposer,
      $$RuleVersionsTableCreateCompanionBuilder,
      $$RuleVersionsTableUpdateCompanionBuilder,
      (
        RuleVersion,
        BaseReferences<_$AppDatabase, $RuleVersionsTable, RuleVersion>,
      ),
      RuleVersion,
      PrefetchHooks Function()
    >;
typedef $$AuditLogTableCreateCompanionBuilder =
    AuditLogCompanion Function({
      required String id,
      required String entityTable,
      required String recordId,
      Value<String?> fieldName,
      Value<String?> oldValue,
      Value<String?> newValue,
      required String changedBy,
      required String deviceId,
      required String appVersion,
      Value<String?> ruleVersionId,
      required int deviceTimestamp,
      Value<int?> serverTimestamp,
      required String chainHash,
      Value<int> rowid,
    });
typedef $$AuditLogTableUpdateCompanionBuilder =
    AuditLogCompanion Function({
      Value<String> id,
      Value<String> entityTable,
      Value<String> recordId,
      Value<String?> fieldName,
      Value<String?> oldValue,
      Value<String?> newValue,
      Value<String> changedBy,
      Value<String> deviceId,
      Value<String> appVersion,
      Value<String?> ruleVersionId,
      Value<int> deviceTimestamp,
      Value<int?> serverTimestamp,
      Value<String> chainHash,
      Value<int> rowid,
    });

class $$AuditLogTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changedBy => $composableBuilder(
    column: $table.changedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleVersionId => $composableBuilder(
    column: $table.ruleVersionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deviceTimestamp => $composableBuilder(
    column: $table.deviceTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverTimestamp => $composableBuilder(
    column: $table.serverTimestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get chainHash => $composableBuilder(
    column: $table.chainHash,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get oldValue => $composableBuilder(
    column: $table.oldValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get newValue => $composableBuilder(
    column: $table.newValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changedBy => $composableBuilder(
    column: $table.changedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleVersionId => $composableBuilder(
    column: $table.ruleVersionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deviceTimestamp => $composableBuilder(
    column: $table.deviceTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverTimestamp => $composableBuilder(
    column: $table.serverTimestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get chainHash => $composableBuilder(
    column: $table.chainHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<String> get oldValue =>
      $composableBuilder(column: $table.oldValue, builder: (column) => column);

  GeneratedColumn<String> get newValue =>
      $composableBuilder(column: $table.newValue, builder: (column) => column);

  GeneratedColumn<String> get changedBy =>
      $composableBuilder(column: $table.changedBy, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ruleVersionId => $composableBuilder(
    column: $table.ruleVersionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deviceTimestamp => $composableBuilder(
    column: $table.deviceTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serverTimestamp => $composableBuilder(
    column: $table.serverTimestamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get chainHash =>
      $composableBuilder(column: $table.chainHash, builder: (column) => column);
}

class $$AuditLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogTable,
          AuditLogData,
          $$AuditLogTableFilterComposer,
          $$AuditLogTableOrderingComposer,
          $$AuditLogTableAnnotationComposer,
          $$AuditLogTableCreateCompanionBuilder,
          $$AuditLogTableUpdateCompanionBuilder,
          (
            AuditLogData,
            BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogData>,
          ),
          AuditLogData,
          PrefetchHooks Function()
        > {
  $$AuditLogTableTableManager(_$AppDatabase db, $AuditLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityTable = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String?> fieldName = const Value.absent(),
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                Value<String> changedBy = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> appVersion = const Value.absent(),
                Value<String?> ruleVersionId = const Value.absent(),
                Value<int> deviceTimestamp = const Value.absent(),
                Value<int?> serverTimestamp = const Value.absent(),
                Value<String> chainHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuditLogCompanion(
                id: id,
                entityTable: entityTable,
                recordId: recordId,
                fieldName: fieldName,
                oldValue: oldValue,
                newValue: newValue,
                changedBy: changedBy,
                deviceId: deviceId,
                appVersion: appVersion,
                ruleVersionId: ruleVersionId,
                deviceTimestamp: deviceTimestamp,
                serverTimestamp: serverTimestamp,
                chainHash: chainHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityTable,
                required String recordId,
                Value<String?> fieldName = const Value.absent(),
                Value<String?> oldValue = const Value.absent(),
                Value<String?> newValue = const Value.absent(),
                required String changedBy,
                required String deviceId,
                required String appVersion,
                Value<String?> ruleVersionId = const Value.absent(),
                required int deviceTimestamp,
                Value<int?> serverTimestamp = const Value.absent(),
                required String chainHash,
                Value<int> rowid = const Value.absent(),
              }) => AuditLogCompanion.insert(
                id: id,
                entityTable: entityTable,
                recordId: recordId,
                fieldName: fieldName,
                oldValue: oldValue,
                newValue: newValue,
                changedBy: changedBy,
                deviceId: deviceId,
                appVersion: appVersion,
                ruleVersionId: ruleVersionId,
                deviceTimestamp: deviceTimestamp,
                serverTimestamp: serverTimestamp,
                chainHash: chainHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogTable,
      AuditLogData,
      $$AuditLogTableFilterComposer,
      $$AuditLogTableOrderingComposer,
      $$AuditLogTableAnnotationComposer,
      $$AuditLogTableCreateCompanionBuilder,
      $$AuditLogTableUpdateCompanionBuilder,
      (
        AuditLogData,
        BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogData>,
      ),
      AuditLogData,
      PrefetchHooks Function()
    >;
typedef $$DraftsTableCreateCompanionBuilder =
    DraftsCompanion Function({
      required String id,
      required String formType,
      Value<String?> memberId,
      required String partialDataJson,
      required int lastModifiedAt,
      Value<int> recoveryCount,
      Value<int> rowid,
    });
typedef $$DraftsTableUpdateCompanionBuilder =
    DraftsCompanion Function({
      Value<String> id,
      Value<String> formType,
      Value<String?> memberId,
      Value<String> partialDataJson,
      Value<int> lastModifiedAt,
      Value<int> recoveryCount,
      Value<int> rowid,
    });

class $$DraftsTableFilterComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get formType => $composableBuilder(
    column: $table.formType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get partialDataJson => $composableBuilder(
    column: $table.partialDataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recoveryCount => $composableBuilder(
    column: $table.recoveryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DraftsTableOrderingComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get formType => $composableBuilder(
    column: $table.formType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberId => $composableBuilder(
    column: $table.memberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get partialDataJson => $composableBuilder(
    column: $table.partialDataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recoveryCount => $composableBuilder(
    column: $table.recoveryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DraftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DraftsTable> {
  $$DraftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get formType =>
      $composableBuilder(column: $table.formType, builder: (column) => column);

  GeneratedColumn<String> get memberId =>
      $composableBuilder(column: $table.memberId, builder: (column) => column);

  GeneratedColumn<String> get partialDataJson => $composableBuilder(
    column: $table.partialDataJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recoveryCount => $composableBuilder(
    column: $table.recoveryCount,
    builder: (column) => column,
  );
}

class $$DraftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DraftsTable,
          Draft,
          $$DraftsTableFilterComposer,
          $$DraftsTableOrderingComposer,
          $$DraftsTableAnnotationComposer,
          $$DraftsTableCreateCompanionBuilder,
          $$DraftsTableUpdateCompanionBuilder,
          (Draft, BaseReferences<_$AppDatabase, $DraftsTable, Draft>),
          Draft,
          PrefetchHooks Function()
        > {
  $$DraftsTableTableManager(_$AppDatabase db, $DraftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DraftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DraftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DraftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> formType = const Value.absent(),
                Value<String?> memberId = const Value.absent(),
                Value<String> partialDataJson = const Value.absent(),
                Value<int> lastModifiedAt = const Value.absent(),
                Value<int> recoveryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftsCompanion(
                id: id,
                formType: formType,
                memberId: memberId,
                partialDataJson: partialDataJson,
                lastModifiedAt: lastModifiedAt,
                recoveryCount: recoveryCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String formType,
                Value<String?> memberId = const Value.absent(),
                required String partialDataJson,
                required int lastModifiedAt,
                Value<int> recoveryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DraftsCompanion.insert(
                id: id,
                formType: formType,
                memberId: memberId,
                partialDataJson: partialDataJson,
                lastModifiedAt: lastModifiedAt,
                recoveryCount: recoveryCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DraftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DraftsTable,
      Draft,
      $$DraftsTableFilterComposer,
      $$DraftsTableOrderingComposer,
      $$DraftsTableAnnotationComposer,
      $$DraftsTableCreateCompanionBuilder,
      $$DraftsTableUpdateCompanionBuilder,
      (Draft, BaseReferences<_$AppDatabase, $DraftsTable, Draft>),
      Draft,
      PrefetchHooks Function()
    >;
typedef $$StockItemsTableCreateCompanionBuilder =
    StockItemsCompanion Function({
      required String id,
      required String workerId,
      required String itemCode,
      required String itemName,
      Value<double> quantity,
      Value<double> minThreshold,
      required String unit,
      required int lastUpdatedAt,
      Value<int> rowid,
    });
typedef $$StockItemsTableUpdateCompanionBuilder =
    StockItemsCompanion Function({
      Value<String> id,
      Value<String> workerId,
      Value<String> itemCode,
      Value<String> itemName,
      Value<double> quantity,
      Value<double> minThreshold,
      Value<String> unit,
      Value<int> lastUpdatedAt,
      Value<int> rowid,
    });

final class $$StockItemsTableReferences
    extends BaseReferences<_$AppDatabase, $StockItemsTable, StockItem> {
  $$StockItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StockTransactionsTable, List<StockTransaction>>
  _stockTransactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.stockTransactions,
        aliasName: $_aliasNameGenerator(
          db.stockItems.id,
          db.stockTransactions.itemId,
        ),
      );

  $$StockTransactionsTableProcessedTableManager get stockTransactionsRefs {
    final manager = $$StockTransactionsTableTableManager(
      $_db,
      $_db.stockTransactions,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _stockTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StockItemsTableFilterComposer
    extends Composer<_$AppDatabase, $StockItemsTable> {
  $$StockItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemCode => $composableBuilder(
    column: $table.itemCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minThreshold => $composableBuilder(
    column: $table.minThreshold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> stockTransactionsRefs(
    Expression<bool> Function($$StockTransactionsTableFilterComposer f) f,
  ) {
    final $$StockTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockTransactions,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.stockTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StockItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockItemsTable> {
  $$StockItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemCode => $composableBuilder(
    column: $table.itemCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemName => $composableBuilder(
    column: $table.itemName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minThreshold => $composableBuilder(
    column: $table.minThreshold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StockItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockItemsTable> {
  $$StockItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workerId =>
      $composableBuilder(column: $table.workerId, builder: (column) => column);

  GeneratedColumn<String> get itemCode =>
      $composableBuilder(column: $table.itemCode, builder: (column) => column);

  GeneratedColumn<String> get itemName =>
      $composableBuilder(column: $table.itemName, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get minThreshold => $composableBuilder(
    column: $table.minThreshold,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );

  Expression<T> stockTransactionsRefs<T extends Object>(
    Expression<T> Function($$StockTransactionsTableAnnotationComposer a) f,
  ) {
    final $$StockTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.stockTransactions,
          getReferencedColumn: (t) => t.itemId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$StockTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.stockTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$StockItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockItemsTable,
          StockItem,
          $$StockItemsTableFilterComposer,
          $$StockItemsTableOrderingComposer,
          $$StockItemsTableAnnotationComposer,
          $$StockItemsTableCreateCompanionBuilder,
          $$StockItemsTableUpdateCompanionBuilder,
          (StockItem, $$StockItemsTableReferences),
          StockItem,
          PrefetchHooks Function({bool stockTransactionsRefs})
        > {
  $$StockItemsTableTableManager(_$AppDatabase db, $StockItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workerId = const Value.absent(),
                Value<String> itemCode = const Value.absent(),
                Value<String> itemName = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> minThreshold = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> lastUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockItemsCompanion(
                id: id,
                workerId: workerId,
                itemCode: itemCode,
                itemName: itemName,
                quantity: quantity,
                minThreshold: minThreshold,
                unit: unit,
                lastUpdatedAt: lastUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workerId,
                required String itemCode,
                required String itemName,
                Value<double> quantity = const Value.absent(),
                Value<double> minThreshold = const Value.absent(),
                required String unit,
                required int lastUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => StockItemsCompanion.insert(
                id: id,
                workerId: workerId,
                itemCode: itemCode,
                itemName: itemName,
                quantity: quantity,
                minThreshold: minThreshold,
                unit: unit,
                lastUpdatedAt: lastUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StockItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({stockTransactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (stockTransactionsRefs) db.stockTransactions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (stockTransactionsRefs)
                    await $_getPrefetchedData<
                      StockItem,
                      $StockItemsTable,
                      StockTransaction
                    >(
                      currentTable: table,
                      referencedTable: $$StockItemsTableReferences
                          ._stockTransactionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$StockItemsTableReferences(
                            db,
                            table,
                            p0,
                          ).stockTransactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.itemId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StockItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockItemsTable,
      StockItem,
      $$StockItemsTableFilterComposer,
      $$StockItemsTableOrderingComposer,
      $$StockItemsTableAnnotationComposer,
      $$StockItemsTableCreateCompanionBuilder,
      $$StockItemsTableUpdateCompanionBuilder,
      (StockItem, $$StockItemsTableReferences),
      StockItem,
      PrefetchHooks Function({bool stockTransactionsRefs})
    >;
typedef $$StockTransactionsTableCreateCompanionBuilder =
    StockTransactionsCompanion Function({
      required String id,
      required String itemId,
      required String transactionType,
      required double quantityDelta,
      Value<String?> relatedEncounterId,
      Value<String?> relatedMemberId,
      required int recordedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });
typedef $$StockTransactionsTableUpdateCompanionBuilder =
    StockTransactionsCompanion Function({
      Value<String> id,
      Value<String> itemId,
      Value<String> transactionType,
      Value<double> quantityDelta,
      Value<String?> relatedEncounterId,
      Value<String?> relatedMemberId,
      Value<int> recordedAt,
      Value<String> syncStatus,
      Value<int> rowid,
    });

final class $$StockTransactionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $StockTransactionsTable,
          StockTransaction
        > {
  $$StockTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StockItemsTable _itemIdTable(_$AppDatabase db) =>
      db.stockItems.createAlias(
        $_aliasNameGenerator(db.stockTransactions.itemId, db.stockItems.id),
      );

  $$StockItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<String>('item_id')!;

    final manager = $$StockItemsTableTableManager(
      $_db,
      $_db.stockItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StockTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $StockTransactionsTable> {
  $$StockTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedEncounterId => $composableBuilder(
    column: $table.relatedEncounterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relatedMemberId => $composableBuilder(
    column: $table.relatedMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  $$StockItemsTableFilterComposer get itemId {
    final $$StockItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.stockItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockItemsTableFilterComposer(
            $db: $db,
            $table: $db.stockItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockTransactionsTable> {
  $$StockTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedEncounterId => $composableBuilder(
    column: $table.relatedEncounterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relatedMemberId => $composableBuilder(
    column: $table.relatedMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $$StockItemsTableOrderingComposer get itemId {
    final $$StockItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.stockItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockItemsTableOrderingComposer(
            $db: $db,
            $table: $db.stockItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockTransactionsTable> {
  $$StockTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get quantityDelta => $composableBuilder(
    column: $table.quantityDelta,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedEncounterId => $composableBuilder(
    column: $table.relatedEncounterId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relatedMemberId => $composableBuilder(
    column: $table.relatedMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  $$StockItemsTableAnnotationComposer get itemId {
    final $$StockItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.stockItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.stockItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockTransactionsTable,
          StockTransaction,
          $$StockTransactionsTableFilterComposer,
          $$StockTransactionsTableOrderingComposer,
          $$StockTransactionsTableAnnotationComposer,
          $$StockTransactionsTableCreateCompanionBuilder,
          $$StockTransactionsTableUpdateCompanionBuilder,
          (StockTransaction, $$StockTransactionsTableReferences),
          StockTransaction,
          PrefetchHooks Function({bool itemId})
        > {
  $$StockTransactionsTableTableManager(
    _$AppDatabase db,
    $StockTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<double> quantityDelta = const Value.absent(),
                Value<String?> relatedEncounterId = const Value.absent(),
                Value<String?> relatedMemberId = const Value.absent(),
                Value<int> recordedAt = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockTransactionsCompanion(
                id: id,
                itemId: itemId,
                transactionType: transactionType,
                quantityDelta: quantityDelta,
                relatedEncounterId: relatedEncounterId,
                relatedMemberId: relatedMemberId,
                recordedAt: recordedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String itemId,
                required String transactionType,
                required double quantityDelta,
                Value<String?> relatedEncounterId = const Value.absent(),
                Value<String?> relatedMemberId = const Value.absent(),
                required int recordedAt,
                Value<String> syncStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockTransactionsCompanion.insert(
                id: id,
                itemId: itemId,
                transactionType: transactionType,
                quantityDelta: quantityDelta,
                relatedEncounterId: relatedEncounterId,
                relatedMemberId: relatedMemberId,
                recordedAt: recordedAt,
                syncStatus: syncStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StockTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (itemId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.itemId,
                                referencedTable:
                                    $$StockTransactionsTableReferences
                                        ._itemIdTable(db),
                                referencedColumn:
                                    $$StockTransactionsTableReferences
                                        ._itemIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StockTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockTransactionsTable,
      StockTransaction,
      $$StockTransactionsTableFilterComposer,
      $$StockTransactionsTableOrderingComposer,
      $$StockTransactionsTableAnnotationComposer,
      $$StockTransactionsTableCreateCompanionBuilder,
      $$StockTransactionsTableUpdateCompanionBuilder,
      (StockTransaction, $$StockTransactionsTableReferences),
      StockTransaction,
      PrefetchHooks Function({bool itemId})
    >;
typedef $$FacilityDirectoryTableCreateCompanionBuilder =
    FacilityDirectoryCompanion Function({
      required String id,
      required String name,
      required String facilityLevel,
      Value<String?> district,
      Value<String?> block,
      Value<String?> village,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> contactPhone,
      Value<String> servicesJson,
      Value<bool> isActive,
      required int lastUpdatedAt,
      Value<int> rowid,
    });
typedef $$FacilityDirectoryTableUpdateCompanionBuilder =
    FacilityDirectoryCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> facilityLevel,
      Value<String?> district,
      Value<String?> block,
      Value<String?> village,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> contactPhone,
      Value<String> servicesJson,
      Value<bool> isActive,
      Value<int> lastUpdatedAt,
      Value<int> rowid,
    });

class $$FacilityDirectoryTableFilterComposer
    extends Composer<_$AppDatabase, $FacilityDirectoryTable> {
  $$FacilityDirectoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get facilityLevel => $composableBuilder(
    column: $table.facilityLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get block => $composableBuilder(
    column: $table.block,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get village => $composableBuilder(
    column: $table.village,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contactPhone => $composableBuilder(
    column: $table.contactPhone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servicesJson => $composableBuilder(
    column: $table.servicesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FacilityDirectoryTableOrderingComposer
    extends Composer<_$AppDatabase, $FacilityDirectoryTable> {
  $$FacilityDirectoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get facilityLevel => $composableBuilder(
    column: $table.facilityLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get district => $composableBuilder(
    column: $table.district,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get block => $composableBuilder(
    column: $table.block,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get village => $composableBuilder(
    column: $table.village,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contactPhone => $composableBuilder(
    column: $table.contactPhone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servicesJson => $composableBuilder(
    column: $table.servicesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FacilityDirectoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $FacilityDirectoryTable> {
  $$FacilityDirectoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get facilityLevel => $composableBuilder(
    column: $table.facilityLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get district =>
      $composableBuilder(column: $table.district, builder: (column) => column);

  GeneratedColumn<String> get block =>
      $composableBuilder(column: $table.block, builder: (column) => column);

  GeneratedColumn<String> get village =>
      $composableBuilder(column: $table.village, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get contactPhone => $composableBuilder(
    column: $table.contactPhone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get servicesJson => $composableBuilder(
    column: $table.servicesJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get lastUpdatedAt => $composableBuilder(
    column: $table.lastUpdatedAt,
    builder: (column) => column,
  );
}

class $$FacilityDirectoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FacilityDirectoryTable,
          FacilityDirectoryData,
          $$FacilityDirectoryTableFilterComposer,
          $$FacilityDirectoryTableOrderingComposer,
          $$FacilityDirectoryTableAnnotationComposer,
          $$FacilityDirectoryTableCreateCompanionBuilder,
          $$FacilityDirectoryTableUpdateCompanionBuilder,
          (
            FacilityDirectoryData,
            BaseReferences<
              _$AppDatabase,
              $FacilityDirectoryTable,
              FacilityDirectoryData
            >,
          ),
          FacilityDirectoryData,
          PrefetchHooks Function()
        > {
  $$FacilityDirectoryTableTableManager(
    _$AppDatabase db,
    $FacilityDirectoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FacilityDirectoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FacilityDirectoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FacilityDirectoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> facilityLevel = const Value.absent(),
                Value<String?> district = const Value.absent(),
                Value<String?> block = const Value.absent(),
                Value<String?> village = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> contactPhone = const Value.absent(),
                Value<String> servicesJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> lastUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FacilityDirectoryCompanion(
                id: id,
                name: name,
                facilityLevel: facilityLevel,
                district: district,
                block: block,
                village: village,
                latitude: latitude,
                longitude: longitude,
                contactPhone: contactPhone,
                servicesJson: servicesJson,
                isActive: isActive,
                lastUpdatedAt: lastUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String facilityLevel,
                Value<String?> district = const Value.absent(),
                Value<String?> block = const Value.absent(),
                Value<String?> village = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> contactPhone = const Value.absent(),
                Value<String> servicesJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int lastUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => FacilityDirectoryCompanion.insert(
                id: id,
                name: name,
                facilityLevel: facilityLevel,
                district: district,
                block: block,
                village: village,
                latitude: latitude,
                longitude: longitude,
                contactPhone: contactPhone,
                servicesJson: servicesJson,
                isActive: isActive,
                lastUpdatedAt: lastUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FacilityDirectoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FacilityDirectoryTable,
      FacilityDirectoryData,
      $$FacilityDirectoryTableFilterComposer,
      $$FacilityDirectoryTableOrderingComposer,
      $$FacilityDirectoryTableAnnotationComposer,
      $$FacilityDirectoryTableCreateCompanionBuilder,
      $$FacilityDirectoryTableUpdateCompanionBuilder,
      (
        FacilityDirectoryData,
        BaseReferences<
          _$AppDatabase,
          $FacilityDirectoryTable,
          FacilityDirectoryData
        >,
      ),
      FacilityDirectoryData,
      PrefetchHooks Function()
    >;
typedef $$LearningProgressTableCreateCompanionBuilder =
    LearningProgressCompanion Function({
      required String id,
      required String workerId,
      required String moduleId,
      required String lessonId,
      Value<String> status,
      Value<int?> score,
      Value<int?> startedAt,
      Value<int?> completedAt,
      Value<int> quizAttempts,
      Value<int> rowid,
    });
typedef $$LearningProgressTableUpdateCompanionBuilder =
    LearningProgressCompanion Function({
      Value<String> id,
      Value<String> workerId,
      Value<String> moduleId,
      Value<String> lessonId,
      Value<String> status,
      Value<int?> score,
      Value<int?> startedAt,
      Value<int?> completedAt,
      Value<int> quizAttempts,
      Value<int> rowid,
    });

class $$LearningProgressTableFilterComposer
    extends Composer<_$AppDatabase, $LearningProgressTable> {
  $$LearningProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get moduleId => $composableBuilder(
    column: $table.moduleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quizAttempts => $composableBuilder(
    column: $table.quizAttempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearningProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $LearningProgressTable> {
  $$LearningProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get workerId => $composableBuilder(
    column: $table.workerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get moduleId => $composableBuilder(
    column: $table.moduleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lessonId => $composableBuilder(
    column: $table.lessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quizAttempts => $composableBuilder(
    column: $table.quizAttempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearningProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $LearningProgressTable> {
  $$LearningProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get workerId =>
      $composableBuilder(column: $table.workerId, builder: (column) => column);

  GeneratedColumn<String> get moduleId =>
      $composableBuilder(column: $table.moduleId, builder: (column) => column);

  GeneratedColumn<String> get lessonId =>
      $composableBuilder(column: $table.lessonId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quizAttempts => $composableBuilder(
    column: $table.quizAttempts,
    builder: (column) => column,
  );
}

class $$LearningProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LearningProgressTable,
          LearningProgressData,
          $$LearningProgressTableFilterComposer,
          $$LearningProgressTableOrderingComposer,
          $$LearningProgressTableAnnotationComposer,
          $$LearningProgressTableCreateCompanionBuilder,
          $$LearningProgressTableUpdateCompanionBuilder,
          (
            LearningProgressData,
            BaseReferences<
              _$AppDatabase,
              $LearningProgressTable,
              LearningProgressData
            >,
          ),
          LearningProgressData,
          PrefetchHooks Function()
        > {
  $$LearningProgressTableTableManager(
    _$AppDatabase db,
    $LearningProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearningProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearningProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearningProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workerId = const Value.absent(),
                Value<String> moduleId = const Value.absent(),
                Value<String> lessonId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<int?> startedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> quizAttempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningProgressCompanion(
                id: id,
                workerId: workerId,
                moduleId: moduleId,
                lessonId: lessonId,
                status: status,
                score: score,
                startedAt: startedAt,
                completedAt: completedAt,
                quizAttempts: quizAttempts,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workerId,
                required String moduleId,
                required String lessonId,
                Value<String> status = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<int?> startedAt = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<int> quizAttempts = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearningProgressCompanion.insert(
                id: id,
                workerId: workerId,
                moduleId: moduleId,
                lessonId: lessonId,
                status: status,
                score: score,
                startedAt: startedAt,
                completedAt: completedAt,
                quizAttempts: quizAttempts,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearningProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LearningProgressTable,
      LearningProgressData,
      $$LearningProgressTableFilterComposer,
      $$LearningProgressTableOrderingComposer,
      $$LearningProgressTableAnnotationComposer,
      $$LearningProgressTableCreateCompanionBuilder,
      $$LearningProgressTableUpdateCompanionBuilder,
      (
        LearningProgressData,
        BaseReferences<
          _$AppDatabase,
          $LearningProgressTable,
          LearningProgressData
        >,
      ),
      LearningProgressData,
      PrefetchHooks Function()
    >;
typedef $$DeviceProfilesTableCreateCompanionBuilder =
    DeviceProfilesCompanion Function({
      required String id,
      required String deviceName,
      Value<String?> bleServiceUuid,
      Value<String?> bleCharacteristicUuid,
      required String measurementType,
      required String unit,
      required double minPlausible,
      required double maxPlausible,
      Value<String?> unitConversionJson,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$DeviceProfilesTableUpdateCompanionBuilder =
    DeviceProfilesCompanion Function({
      Value<String> id,
      Value<String> deviceName,
      Value<String?> bleServiceUuid,
      Value<String?> bleCharacteristicUuid,
      Value<String> measurementType,
      Value<String> unit,
      Value<double> minPlausible,
      Value<double> maxPlausible,
      Value<String?> unitConversionJson,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$DeviceProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceProfilesTable> {
  $$DeviceProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bleServiceUuid => $composableBuilder(
    column: $table.bleServiceUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bleCharacteristicUuid => $composableBuilder(
    column: $table.bleCharacteristicUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get measurementType => $composableBuilder(
    column: $table.measurementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minPlausible => $composableBuilder(
    column: $table.minPlausible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxPlausible => $composableBuilder(
    column: $table.maxPlausible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitConversionJson => $composableBuilder(
    column: $table.unitConversionJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceProfilesTable> {
  $$DeviceProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bleServiceUuid => $composableBuilder(
    column: $table.bleServiceUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bleCharacteristicUuid => $composableBuilder(
    column: $table.bleCharacteristicUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get measurementType => $composableBuilder(
    column: $table.measurementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minPlausible => $composableBuilder(
    column: $table.minPlausible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxPlausible => $composableBuilder(
    column: $table.maxPlausible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitConversionJson => $composableBuilder(
    column: $table.unitConversionJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceProfilesTable> {
  $$DeviceProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get deviceName => $composableBuilder(
    column: $table.deviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bleServiceUuid => $composableBuilder(
    column: $table.bleServiceUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bleCharacteristicUuid => $composableBuilder(
    column: $table.bleCharacteristicUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get measurementType => $composableBuilder(
    column: $table.measurementType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get minPlausible => $composableBuilder(
    column: $table.minPlausible,
    builder: (column) => column,
  );

  GeneratedColumn<double> get maxPlausible => $composableBuilder(
    column: $table.maxPlausible,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitConversionJson => $composableBuilder(
    column: $table.unitConversionJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$DeviceProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceProfilesTable,
          DeviceProfile,
          $$DeviceProfilesTableFilterComposer,
          $$DeviceProfilesTableOrderingComposer,
          $$DeviceProfilesTableAnnotationComposer,
          $$DeviceProfilesTableCreateCompanionBuilder,
          $$DeviceProfilesTableUpdateCompanionBuilder,
          (
            DeviceProfile,
            BaseReferences<_$AppDatabase, $DeviceProfilesTable, DeviceProfile>,
          ),
          DeviceProfile,
          PrefetchHooks Function()
        > {
  $$DeviceProfilesTableTableManager(
    _$AppDatabase db,
    $DeviceProfilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeviceProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> deviceName = const Value.absent(),
                Value<String?> bleServiceUuid = const Value.absent(),
                Value<String?> bleCharacteristicUuid = const Value.absent(),
                Value<String> measurementType = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double> minPlausible = const Value.absent(),
                Value<double> maxPlausible = const Value.absent(),
                Value<String?> unitConversionJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceProfilesCompanion(
                id: id,
                deviceName: deviceName,
                bleServiceUuid: bleServiceUuid,
                bleCharacteristicUuid: bleCharacteristicUuid,
                measurementType: measurementType,
                unit: unit,
                minPlausible: minPlausible,
                maxPlausible: maxPlausible,
                unitConversionJson: unitConversionJson,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String deviceName,
                Value<String?> bleServiceUuid = const Value.absent(),
                Value<String?> bleCharacteristicUuid = const Value.absent(),
                required String measurementType,
                required String unit,
                required double minPlausible,
                required double maxPlausible,
                Value<String?> unitConversionJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeviceProfilesCompanion.insert(
                id: id,
                deviceName: deviceName,
                bleServiceUuid: bleServiceUuid,
                bleCharacteristicUuid: bleCharacteristicUuid,
                measurementType: measurementType,
                unit: unit,
                minPlausible: minPlausible,
                maxPlausible: maxPlausible,
                unitConversionJson: unitConversionJson,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceProfilesTable,
      DeviceProfile,
      $$DeviceProfilesTableFilterComposer,
      $$DeviceProfilesTableOrderingComposer,
      $$DeviceProfilesTableAnnotationComposer,
      $$DeviceProfilesTableCreateCompanionBuilder,
      $$DeviceProfilesTableUpdateCompanionBuilder,
      (
        DeviceProfile,
        BaseReferences<_$AppDatabase, $DeviceProfilesTable, DeviceProfile>,
      ),
      DeviceProfile,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$HouseholdsTableTableManager get households =>
      $$HouseholdsTableTableManager(_db, _db.households);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$ConsentRecordsTableTableManager get consentRecords =>
      $$ConsentRecordsTableTableManager(_db, _db.consentRecords);
  $$ClinicalEncountersTableTableManager get clinicalEncounters =>
      $$ClinicalEncountersTableTableManager(_db, _db.clinicalEncounters);
  $$ClinicalObservationsTableTableManager get clinicalObservations =>
      $$ClinicalObservationsTableTableManager(_db, _db.clinicalObservations);
  $$TriageResultsTableTableManager get triageResults =>
      $$TriageResultsTableTableManager(_db, _db.triageResults);
  $$ReferralRecordsTableTableManager get referralRecords =>
      $$ReferralRecordsTableTableManager(_db, _db.referralRecords);
  $$VisitSchedulesTableTableManager get visitSchedules =>
      $$VisitSchedulesTableTableManager(_db, _db.visitSchedules);
  $$IncentiveEventsTableTableManager get incentiveEvents =>
      $$IncentiveEventsTableTableManager(_db, _db.incentiveEvents);
  $$IncentiveClaimsTableTableManager get incentiveClaims =>
      $$IncentiveClaimsTableTableManager(_db, _db.incentiveClaims);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$RuleVersionsTableTableManager get ruleVersions =>
      $$RuleVersionsTableTableManager(_db, _db.ruleVersions);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
  $$DraftsTableTableManager get drafts =>
      $$DraftsTableTableManager(_db, _db.drafts);
  $$StockItemsTableTableManager get stockItems =>
      $$StockItemsTableTableManager(_db, _db.stockItems);
  $$StockTransactionsTableTableManager get stockTransactions =>
      $$StockTransactionsTableTableManager(_db, _db.stockTransactions);
  $$FacilityDirectoryTableTableManager get facilityDirectory =>
      $$FacilityDirectoryTableTableManager(_db, _db.facilityDirectory);
  $$LearningProgressTableTableManager get learningProgress =>
      $$LearningProgressTableTableManager(_db, _db.learningProgress);
  $$DeviceProfilesTableTableManager get deviceProfiles =>
      $$DeviceProfilesTableTableManager(_db, _db.deviceProfiles);
}
