import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import 'models/models.dart';

/// Metadata for a published rule set version bundle from the backend.
class RuleVersionMetadata {
  final String id;
  final String versionString;
  final int publishedAt;
  final String bundleHash;
  final String downloadUrl;
  final String? clinicalLeadId;
  final String? approvalSignature;
  final bool isActive;

  const RuleVersionMetadata({
    required this.id,
    required this.versionString,
    required this.publishedAt,
    required this.bundleHash,
    required this.downloadUrl,
    this.clinicalLeadId,
    this.approvalSignature,
    this.isActive = true,
  });

  factory RuleVersionMetadata.fromJson(Map<String, dynamic> json) =>
      RuleVersionMetadata(
        id: json['id'] as String? ?? '',
        versionString: json['version_string'] as String? ??
            json['versionString'] as String? ??
            '',
        publishedAt: (json['published_at'] as num? ??
                json['publishedAt'] as num? ??
                0)
            .toInt(),
        bundleHash: json['bundle_hash'] as String? ??
            json['bundleHash'] as String? ??
            '',
        downloadUrl: json['download_url'] as String? ??
            json['downloadUrl'] as String? ??
            '',
        clinicalLeadId: json['clinical_lead_id'] as String? ??
            json['clinicalLeadId'] as String?,
        approvalSignature: json['approval_signature'] as String? ??
            json['approvalSignature'] as String?,
        isActive: json['is_active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'version_string': versionString,
        'published_at': publishedAt,
        'bundle_hash': bundleHash,
        'download_url': downloadUrl,
        if (clinicalLeadId != null) 'clinical_lead_id': clinicalLeadId,
        if (approvalSignature != null)
          'approval_signature': approvalSignature,
        'is_active': isActive,
      };
}

/// Service managing triage rule bundle OTA delivery, integrity verification,
/// rollback support, and in-memory sub-10ms caching.
///
/// Implements Requirements 9.2, 9.3, 9.4:
/// - Download signed rule bundle from `/api/v1/rules/latest`
/// - Verify SHA-256 hash before activation
/// - Write to `rule_versions` table and retain previous version for rollback
/// - Fast sub-10ms in-memory access
class RuleLoader {
  final AppDatabase _db;
  final http.Client _httpClient;
  final Directory? _overrideStorageDirectory;

  RuleSet? _cachedRuleSet;

  RuleLoader(
    this._db, {
    http.Client? httpClient,
    Directory? storageDirectory,
  })  : _httpClient = httpClient ?? http.Client(),
        _overrideStorageDirectory = storageDirectory;

  /// Fast in-memory cached instance of the active [RuleSet] (< 10 ms access).
  RuleSet? get cachedRuleSet => _cachedRuleSet;

  /// Loads the active [RuleSet].
  ///
  /// - Returns cached instance immediately if available and [forceReload] is false.
  /// - Otherwise loads active record from `rule_versions` table.
  /// - On fresh installation, seeds and activates the national base ruleset.
  Future<RuleSet> loadActiveRuleSet({bool forceReload = false}) async {
    if (_cachedRuleSet != null && !forceReload) {
      return _cachedRuleSet!;
    }

    final activeRows = await (_db.select(_db.ruleVersions)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.publishedAt)])
          ..limit(1))
        .get();

    if (activeRows.isNotEmpty) {
      final active = activeRows.first;
      if (active.bundlePath != null && active.bundlePath!.isNotEmpty) {
        final file = File(active.bundlePath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final computedHash = sha256.convert(bytes).toString();

          if (computedHash.toLowerCase() == active.bundleHash.toLowerCase()) {
            final jsonStr = utf8.decode(bytes);
            final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
            _cachedRuleSet = RuleSet.fromJson(decoded);
            return _cachedRuleSet!;
          }
        }
      }
    }

    // Default seed fallback: National Base RuleSet
    final defaultSet = RuleSet.defaultNational();
    await _seedInitialNationalRuleSet(defaultSet);
    _cachedRuleSet = defaultSet;
    return defaultSet;
  }

  /// Checks the backend for the latest published rule version.
  Future<RuleVersionMetadata?> checkForUpdates({
    required String baseUrl,
    String? state,
  }) async {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final uri = Uri.parse(
      '$cleanBase/api/v1/rules/latest${state != null ? '?state=$state' : ''}',
    );

    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to fetch latest rule version metadata (${response.statusCode}): ${response.body}',
        uri: uri,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return RuleVersionMetadata.fromJson(data);
  }

  /// Downloads signed rule bundle from server, verifies SHA-256 hash, saves to
  /// local disk, records in `rule_versions` table, and activates only upon full success.
  ///
  /// Retains previous active version as inactive for rollback.
  Future<RuleSet> downloadAndActivate({
    required String baseUrl,
    required RuleVersionMetadata metadata,
  }) async {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final downloadUrl = metadata.downloadUrl.startsWith('http')
        ? metadata.downloadUrl
        : '$cleanBase${metadata.downloadUrl.startsWith('/') ? '' : '/'}${metadata.downloadUrl}';

    final uri = Uri.parse(downloadUrl);
    final response = await _httpClient.get(uri);

    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to download rule bundle from $downloadUrl (${response.statusCode})',
        uri: uri,
      );
    }

    // 1. Decompress gzip
    List<int> decompressedBytes;
    try {
      decompressedBytes = gzip.decode(response.bodyBytes);
    } catch (_) {
      // In case server sent raw JSON
      decompressedBytes = response.bodyBytes;
    }

    // 2. Verify SHA-256 integrity hash
    final computedHash = sha256.convert(decompressedBytes).toString();
    if (computedHash.toLowerCase() != metadata.bundleHash.toLowerCase()) {
      throw StateError(
        'Rule bundle integrity verification failed: expected ${metadata.bundleHash}, got $computedHash',
      );
    }

    // 3. Parse canonical JSON into RuleSet
    final jsonStr = utf8.decode(decompressedBytes);
    final decodedJson = jsonDecode(jsonStr) as Map<String, dynamic>;
    final ruleSet = RuleSet.fromJson(decodedJson);

    // 4. Save to persistent storage
    final storageDir = _overrideStorageDirectory ??
        await getApplicationDocumentsDirectory();
    final rulesDir = Directory(p.join(storageDir.path, 'rules'));
    if (!await rulesDir.exists()) {
      await rulesDir.create(recursive: true);
    }

    final filePath = p.join(
      rulesDir.path,
      'ruleset_${metadata.versionString}.json',
    );
    await File(filePath).writeAsBytes(decompressedBytes, flush: true);

    // 5. Transactional DB update: mark previous active as inactive; insert new active
    await _db.transaction(() async {
      await (_db.update(_db.ruleVersions)
            ..where((t) => t.isActive.equals(true)))
          .write(const RuleVersionsCompanion(isActive: Value(false)));

      await _db.into(_db.ruleVersions).insert(
            RuleVersionsCompanion.insert(
              id: ruleSet.id,
              versionString: metadata.versionString,
              publishedAt: metadata.publishedAt,
              bundleHash: metadata.bundleHash,
              bundlePath: Value(filePath),
              isActive: const Value(true),
              clinicalLeadId: Value(metadata.clinicalLeadId),
              approvalSignature: Value(metadata.approvalSignature),
            ),
            mode: InsertMode.insertOrReplace,
          );
    });

    // 6. Update in-memory active cache
    _cachedRuleSet = ruleSet;
    return ruleSet;
  }

  /// Rolls back to the most recent previous rule version.
  Future<RuleSet?> rollbackToPreviousVersion() async {
    final inactiveVersions = await (_db.select(_db.ruleVersions)
          ..where((t) => t.isActive.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.publishedAt)])
          ..limit(1))
        .get();

    if (inactiveVersions.isEmpty) {
      return null;
    }

    final previous = inactiveVersions.first;

    // Load bundle from file and verify hash
    RuleSet? restoredRuleSet;
    if (previous.bundlePath != null && previous.bundlePath!.isNotEmpty) {
      final file = File(previous.bundlePath!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final computedHash = sha256.convert(bytes).toString();
        if (computedHash.toLowerCase() == previous.bundleHash.toLowerCase()) {
          final jsonStr = utf8.decode(bytes);
          restoredRuleSet = RuleSet.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          );
        }
      }
    }

    if (restoredRuleSet == null) {
      return null;
    }

    // Switch active version in DB
    await _db.transaction(() async {
      await (_db.update(_db.ruleVersions)
            ..where((t) => t.isActive.equals(true)))
          .write(const RuleVersionsCompanion(isActive: Value(false)));

      await (_db.update(_db.ruleVersions)
            ..where((t) => t.id.equals(previous.id)))
          .write(const RuleVersionsCompanion(isActive: Value(true)));
    });

    _cachedRuleSet = restoredRuleSet;
    return restoredRuleSet;
  }

  Future<void> _seedInitialNationalRuleSet(RuleSet ruleSet) async {
    try {
      final storageDir = _overrideStorageDirectory ??
          await getApplicationDocumentsDirectory();
      final rulesDir = Directory(p.join(storageDir.path, 'rules'));
      if (!await rulesDir.exists()) {
        await rulesDir.create(recursive: true);
      }

      final canonicalJson = jsonEncode(ruleSet.toJson());
      final bytes = utf8.encode(canonicalJson);
      final hash = sha256.convert(bytes).toString();
      final filePath = p.join(
        rulesDir.path,
        'ruleset_${ruleSet.versionString}.json',
      );
      await File(filePath).writeAsBytes(bytes, flush: true);

      await _db.into(_db.ruleVersions).insert(
            RuleVersionsCompanion.insert(
              id: ruleSet.id,
              versionString: ruleSet.versionString,
              publishedAt: ruleSet.publishedAt,
              bundleHash: hash,
              bundlePath: Value(filePath),
              isActive: const Value(true),
              clinicalLeadId: Value(ruleSet.clinicalLeadId),
              approvalSignature: Value(ruleSet.approvalSignature),
            ),
            mode: InsertMode.insertOrReplace,
          );
    } catch (_) {
      // Seeding disk storage error handled gracefully in memory
    }
  }
}
