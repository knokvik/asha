import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/core_providers.dart';
import '../domain/duplicate_detector.dart';

/// Composite model representing a beneficiary match with household context.
class BeneficiarySearchResult {
  final Member member;
  final String village;
  final String? hamlet;
  final String headName;

  const BeneficiarySearchResult({
    required this.member,
    required this.village,
    this.hamlet,
    required this.headName,
  });
}

/// Offline full-text search repository using SQLite FTS5 with phonetic Soundex support.
///
/// Features:
/// - Fast sub-200ms SQLite FTS5 `MATCH` queries over `members_fts` (Requirement 4.7, 49.3).
/// - Partial token prefix matching (`token*`).
/// - Phonetic Soundex query expansion (`DuplicateDetector.soundex(token)`).
/// - Multi-attribute matching (Name, Phonetic code, ABHA ID, RCH ID, Phone, Village, Hamlet).
/// - Area-scoped filtering (restricts to ASHA's assigned village).
/// - Resilient fallback to substring matching if FTS5 table is empty or unavailable.
///
/// Requirements: 4.7
class MemberSearchRepository {
  final AppDatabase db;

  MemberSearchRepository(this.db);

  /// Searches beneficiaries matching [query], optionally restricted to [village].
  Future<List<BeneficiarySearchResult>> search(
    String query, {
    String? village,
    int limit = 50,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final ftsExpression = _buildFtsExpression(trimmed);

    // 1. Try FTS5 MATCH query first
    if (ftsExpression != null) {
      try {
        final results = await _queryFts5(ftsExpression, village: village, limit: limit);
        if (results.isNotEmpty) {
          return results;
        }
      } catch (_) {
        // Fall back gracefully if FTS throws or is unavailable
      }
    }

    // 2. Fallback: Like substring query across members & households
    return _queryLikeFallback(trimmed, village: village, limit: limit);
  }

  /// Builds a sanitized FTS5 expression with token prefixes and phonetic expansion.
  String? _buildFtsExpression(String query) {
    // Strip special characters that break FTS5 grammar
    final cleaned = query.replaceAll(RegExp(r'["\*\+\(\)\:\^\{\}\-\[\]]'), ' ').trim();
    if (cleaned.isEmpty) return null;

    final tokens = cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return null;

    final clauses = <String>[];
    for (final token in tokens) {
      final tokenClauses = <String>['$token*'];

      // Add phonetic soundex code for alphabetical words
      if (RegExp(r'^[a-zA-Z]+$').hasMatch(token)) {
        final sndx = DuplicateDetector.soundex(token);
        if (sndx != '0000') {
          tokenClauses.add('$sndx*');
        }
      }

      if (tokenClauses.length == 1) {
        clauses.add(tokenClauses.first);
      } else {
        clauses.add('(${tokenClauses.join(' OR ')})');
      }
    }

    return clauses.join(' ');
  }

  Future<List<BeneficiarySearchResult>> _queryFts5(
    String ftsExpression, {
    String? village,
    required int limit,
  }) async {
    final ftsSql = '''
      SELECT DISTINCT
        m.id AS m_id,
        m.household_id AS m_household_id,
        m.name AS m_name,
        m.name_phonetic AS m_name_phonetic,
        m.dob_approx AS m_dob_approx,
        m.is_dob_approx AS m_is_dob_approx,
        m.sex AS m_sex,
        m.relationship_to_head AS m_relationship_to_head,
        m.abha_id AS m_abha_id,
        m.rch_id AS m_rch_id,
        m.phone AS m_phone,
        m.social_category AS m_social_category,
        m.is_bpl AS m_is_bpl,
        m.lifecycle_status AS m_lifecycle_status,
        m.consent_status AS m_consent_status,
        m.consent_updated_at AS m_consent_updated_at,
        m.created_at AS m_created_at,
        m.updated_at AS m_updated_at,
        m.created_by AS m_created_by,
        m.sync_status AS m_sync_status,
        m.server_version AS m_server_version,
        h.village AS h_village,
        h.hamlet AS h_hamlet,
        h.head_name AS h_head_name
      FROM members_fts fts
      JOIN members m ON m.id = fts.member_id
      JOIN households h ON m.household_id = h.id
      WHERE members_fts MATCH ?
      ${village != null && village.isNotEmpty ? 'AND h.village = ?' : ''}
      ORDER BY rank
      LIMIT ?
    ''';

    final variables = <Variable>[
      Variable.withString(ftsExpression),
      if (village != null && village.isNotEmpty) Variable.withString(village),
      Variable.withInt(limit),
    ];

    final rows = await db.customSelect(ftsSql, variables: variables).get();
    return rows.map(_mapRow).toList();
  }

  Future<List<BeneficiarySearchResult>> _queryLikeFallback(
    String query, {
    String? village,
    required int limit,
  }) async {
    final likePattern = '%$query%';
    final soundexCode = DuplicateDetector.soundex(query);

    final sql = '''
      SELECT DISTINCT
        m.id AS m_id,
        m.household_id AS m_household_id,
        m.name AS m_name,
        m.name_phonetic AS m_name_phonetic,
        m.dob_approx AS m_dob_approx,
        m.is_dob_approx AS m_is_dob_approx,
        m.sex AS m_sex,
        m.relationship_to_head AS m_relationship_to_head,
        m.abha_id AS m_abha_id,
        m.rch_id AS m_rch_id,
        m.phone AS m_phone,
        m.social_category AS m_social_category,
        m.is_bpl AS m_is_bpl,
        m.lifecycle_status AS m_lifecycle_status,
        m.consent_status AS m_consent_status,
        m.consent_updated_at AS m_consent_updated_at,
        m.created_at AS m_created_at,
        m.updated_at AS m_updated_at,
        m.created_by AS m_created_by,
        m.sync_status AS m_sync_status,
        m.server_version AS m_server_version,
        h.village AS h_village,
        h.hamlet AS h_hamlet,
        h.head_name AS h_head_name
      FROM members m
      JOIN households h ON m.household_id = h.id
      WHERE (
        m.name LIKE ?
        OR (m.name_phonetic IS NOT NULL AND m.name_phonetic LIKE ?)
        OR m.phone LIKE ?
        OR m.abha_id LIKE ?
        OR m.rch_id LIKE ?
        OR h.hamlet LIKE ?
        OR h.head_name LIKE ?
      )
      ${village != null && village.isNotEmpty ? 'AND h.village = ?' : ''}
      ORDER BY m.name ASC
      LIMIT ?
    ''';

    final variables = <Variable>[
      Variable.withString(likePattern),
      Variable.withString('%$soundexCode%'),
      Variable.withString(likePattern),
      Variable.withString(likePattern),
      Variable.withString(likePattern),
      Variable.withString(likePattern),
      Variable.withString(likePattern),
      if (village != null && village.isNotEmpty) Variable.withString(village),
      Variable.withInt(limit),
    ];

    final rows = await db.customSelect(sql, variables: variables).get();
    return rows.map(_mapRow).toList();
  }

  BeneficiarySearchResult _mapRow(QueryRow row) {
    return BeneficiarySearchResult(
      member: Member(
        id: row.read<String>('m_id'),
        householdId: row.read<String>('m_household_id'),
        name: row.read<String>('m_name'),
        namePhonetic: row.readNullable<String>('m_name_phonetic'),
        dobApprox: row.readNullable<int>('m_dob_approx'),
        isDobApprox: row.read<bool>('m_is_dob_approx'),
        sex: row.read<String>('m_sex'),
        relationshipToHead: row.readNullable<String>('m_relationship_to_head'),
        abhaId: row.readNullable<String>('m_abha_id'),
        rchId: row.readNullable<String>('m_rch_id'),
        phone: row.readNullable<String>('m_phone'),
        socialCategory: row.readNullable<String>('m_social_category'),
        isBpl: row.readNullable<bool>('m_is_bpl'),
        lifecycleStatus: row.read<String>('m_lifecycle_status'),
        consentStatus: row.read<String>('m_consent_status'),
        consentUpdatedAt: row.readNullable<int>('m_consent_updated_at'),
        createdAt: row.read<int>('m_created_at'),
        updatedAt: row.read<int>('m_updated_at'),
        createdBy: row.read<String>('m_created_by'),
        syncStatus: row.read<String>('m_sync_status'),
        serverVersion: row.readNullable<int>('m_server_version'),
      ),
      village: row.read<String>('h_village'),
      hamlet: row.readNullable<String>('h_hamlet'),
      headName: row.read<String>('h_head_name'),
    );
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────────────

final memberSearchRepositoryProvider = Provider<MemberSearchRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MemberSearchRepository(db);
});

final beneficiarySearchResultsProvider = FutureProvider.autoDispose
    .family<List<BeneficiarySearchResult>, String>((ref, query) async {
  if (query.trim().isEmpty) return const [];
  final repo = ref.watch(memberSearchRepositoryProvider);
  return repo.search(query);
});
