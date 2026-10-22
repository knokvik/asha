import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/duplicate_detector.dart';
import 'household_dao.dart';
import 'member_dao.dart';

/// Provenance metadata tracking synchronization and dirty state.
class SyncMetadataEntry {
  final String targetTable;
  final String recordId;
  final int dirtyFlag;
  final int syncVersion;
  final int updatedAt;

  const SyncMetadataEntry({
    required this.targetTable,
    required this.recordId,
    required this.dirtyFlag,
    required this.syncVersion,
    required this.updatedAt,
  });
}

/// Composite model pairing a [Household] with its associated [Member] records.
class HouseholdWithMembers {
  final Household household;
  final List<Member> members;

  const HouseholdWithMembers({required this.household, required this.members});
}

/// Repository coordinating offline-first household and member lifecycle.
///
/// Features:
/// - Client-generated UUID v4 without server round-trip (Requirements 4.1, 4.2).
/// - Instant persistence to SQLite + SQLCipher local store (Requirement 1.2).
/// - Provenance sync tracking with `dirty_flag = 1` and `sync_version = 1`.
/// - Automatic BitChat queueing via [SyncEngine] (Requirement 31.1).
class HouseholdRepository {
  final HouseholdDao householdDao;
  final MemberDao memberDao;
  final SyncEngine? syncEngine;
  final Map<String, SyncMetadataEntry> _syncMetadataCache = {};
  static const _uuid = Uuid();

  HouseholdRepository({
    required this.householdDao,
    required this.memberDao,
    this.syncEngine,
  });

  // ── Household Management ───────────────────────────────────────────────────

  /// Registers a new household offline with a client-generated UUID v4.
  ///
  /// Requirements: 4.1, 4.2
  Future<Household> createHousehold({
    required String village,
    String? hamlet,
    required String headName,
    String? socialCategory,
    bool isBpl = false,
    String? contactPhone,
    String? latitude,
    String? longitude,
    int? locationCapturedAt,
    String? landmarkNotes,
    String createdBy = 'offline_user',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final companion = HouseholdsCompanion.insert(
      id: id,
      village: village,
      hamlet: Value(hamlet),
      headName: headName,
      socialCategory: Value(socialCategory),
      isBpl: Value(isBpl),
      contactPhone: Value(contactPhone),
      latitude: Value(latitude),
      longitude: Value(longitude),
      landmarkNotes: Value(landmarkNotes),
      memberCount: const Value(0),
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
      syncStatus: const Value('pending'),
      serverVersion: const Value(1),
    );

    await householdDao.insertHousehold(companion);

    // Track sync metadata: dirty_flag = 1, sync_version = 1
    final metadata = SyncMetadataEntry(
      targetTable: 'households',
      recordId: id,
      dirtyFlag: 1,
      syncVersion: 1,
      updatedAt: now,
    );
    _syncMetadataCache[id] = metadata;

    // Enqueue to BitChat SyncEngine
    if (syncEngine != null) {
      await syncEngine!.enqueue(
        table: 'households',
        recordId: id,
        operation: 'insert',
        priority: SyncPriority.metadata,
        payload: {
          'id': id,
          'village': village,
          'hamlet': hamlet,
          'head_name': headName,
          'social_category': socialCategory,
          'is_bpl': isBpl,
          'contact_phone': contactPhone,
          'latitude': latitude,
          'longitude': longitude,
          'location_captured_at': locationCapturedAt,
          'landmark_notes': landmarkNotes,
          'member_count': 0,
          'created_at': now,
          'updated_at': now,
          'created_by': createdBy,
          'dirty_flag': 1,
          'sync_version': 1,
        },
      );
    }

    final created = await householdDao.getById(id);
    return created!;
  }

  /// Adds a new member to an existing household with a client-generated UUID v4.
  ///
  /// Requirements: 4.1, 4.2
  Future<Member> addMember({
    required String householdId,
    required String name,
    String? namePhonetic,
    int? dobApprox,
    bool isDobApprox = false,
    required String sex,
    String? relationshipToHead,
    String? abhaId,
    String? rchId,
    String? phone,
    String? socialCategory,
    bool? isBpl,
    String createdBy = 'offline_user',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final phoneticCode = namePhonetic ?? DuplicateDetector.soundexWords(name);

    final companion = MembersCompanion.insert(
      id: id,
      householdId: householdId,
      name: name,
      namePhonetic: Value(phoneticCode),
      dobApprox: Value(dobApprox),
      isDobApprox: Value(isDobApprox),
      sex: sex,
      relationshipToHead: Value(relationshipToHead),
      abhaId: Value(abhaId),
      rchId: Value(rchId),
      phone: Value(phone),
      socialCategory: Value(socialCategory),
      isBpl: Value(isBpl),
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
      syncStatus: const Value('pending'),
      serverVersion: const Value(1),
    );

    await memberDao.insertMember(companion);

    // Update member count on household
    final currentMembers = await memberDao.getByHousehold(householdId);
    await householdDao.updateMemberCount(householdId, currentMembers.length);

    // Track sync metadata: dirty_flag = 1, sync_version = 1
    final metadata = SyncMetadataEntry(
      targetTable: 'members',
      recordId: id,
      dirtyFlag: 1,
      syncVersion: 1,
      updatedAt: now,
    );
    _syncMetadataCache[id] = metadata;

    // Enqueue to BitChat SyncEngine
    if (syncEngine != null) {
      await syncEngine!.enqueue(
        table: 'members',
        recordId: id,
        operation: 'insert',
        priority: SyncPriority.metadata,
        payload: {
          'id': id,
          'household_id': householdId,
          'name': name,
          'name_phonetic': phoneticCode,
          'dob_approx': dobApprox,
          'is_dob_approx': isDobApprox,
          'sex': sex,
          'relationship_to_head': relationshipToHead,
          'abha_id': abhaId,
          'rch_id': rchId,
          'phone': phone,
          'social_category': socialCategory,
          'is_bpl': isBpl,
          'created_at': now,
          'updated_at': now,
          'created_by': createdBy,
          'dirty_flag': 1,
          'sync_version': 1,
        },
      );
    }

    final created = await memberDao.getById(id);
    return created!;
  }

  /// Updates details of an existing household.
  Future<bool> updateHousehold(HouseholdsCompanion companion) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedCompanion = companion.copyWith(
      updatedAt: Value(now),
      syncStatus: const Value('pending'),
    );

    final success = await householdDao.updateHousehold(updatedCompanion);
    if (success && companion.id.present) {
      final id = companion.id.value;
      _syncMetadataCache[id] = SyncMetadataEntry(
        targetTable: 'households',
        recordId: id,
        dirtyFlag: 1,
        syncVersion: (companion.serverVersion.value ?? 1) + 1,
        updatedAt: now,
      );
    }
    return success;
  }

  /// Updates details of an existing member.
  Future<bool> updateMember(MembersCompanion companion) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedCompanion = companion.copyWith(
      updatedAt: Value(now),
      syncStatus: const Value('pending'),
    );

    final success = await memberDao.updateMember(updatedCompanion);
    if (success && companion.id.present) {
      final id = companion.id.value;
      _syncMetadataCache[id] = SyncMetadataEntry(
        targetTable: 'members',
        recordId: id,
        dirtyFlag: 1,
        syncVersion: (companion.serverVersion.value ?? 1) + 1,
        updatedAt: now,
      );
    }
    return success;
  }

  /// Retrieves a household by [id].
  Future<Household?> getHousehold(String id) => householdDao.getById(id);

  /// Retrieves a member by [id].
  Future<Member?> getMember(String id) => memberDao.getById(id);

  /// Lists all households, optionally filtered by [village].
  Future<List<Household>> listHouseholds({String? village}) =>
      householdDao.getAll(village: village);

  /// Lists all members for [householdId].
  Future<List<Member>> listMembers(String householdId) =>
      memberDao.getByHousehold(householdId);

  /// Retrieves a combined [HouseholdWithMembers] object.
  Future<HouseholdWithMembers?> getHouseholdWithMembers(
    String householdId,
  ) async {
    final household = await householdDao.getById(householdId);
    if (household == null) return null;

    final members = await memberDao.getByHousehold(householdId);
    return HouseholdWithMembers(household: household, members: members);
  }

  /// Retrieves sync metadata tracking dirty_flag and sync_version for [recordId].
  SyncMetadataEntry? getSyncMetadata(String recordId) {
    return _syncMetadataCache[recordId];
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────────────

final householdDaoProvider = Provider<HouseholdDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return HouseholdDao(db);
});

final memberDaoProvider = Provider<MemberDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MemberDao(db);
});

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  final householdDao = ref.watch(householdDaoProvider);
  final memberDao = ref.watch(memberDaoProvider);
  final syncEngine = ref.watch(syncEngineProvider);

  return HouseholdRepository(
    householdDao: householdDao,
    memberDao: memberDao,
    syncEngine: syncEngine,
  );
});
