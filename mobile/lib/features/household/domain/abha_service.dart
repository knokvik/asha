import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/member_dao.dart';
import 'consent_service.dart';

/// Result of capturing an ABHA identifier offline.
class AbhaCaptureResult {
  final String memberId;
  final String abhaId;
  final bool isLinked;
  final String consentArtifactId;
  final int capturedAt;

  const AbhaCaptureResult({
    required this.memberId,
    required this.abhaId,
    required this.isLinked,
    required this.consentArtifactId,
    required this.capturedAt,
  });
}

/// Service managing offline capture of Ayushman Bharat Health Account (ABHA) IDs,
/// format validation, consent verification, and queued online ABDM sandbox verification.
///
/// Requirements: 4.6, 36.1
class AbhaService {
  final AppDatabase db;
  final MemberDao memberDao;
  final ConsentService consentService;
  final SyncEngine? syncEngine;

  AbhaService({
    required this.db,
    required this.memberDao,
    required this.consentService,
    this.syncEngine,
  });

  /// Validates if an ABHA string matches either:
  /// 1. 14-digit number: continuous `12345678901234` or hyphenated `12-3456-7890-1234`
  /// 2. ABHA address: `username@abdm`
  ///
  /// Requirements: 4.6, 36.1
  static bool validateAbhaFormat(String rawAbha) {
    final cleaned = rawAbha.trim();
    if (cleaned.isEmpty) return false;

    // Pattern 1: Hyphenated 14 digits (XX-XXXX-XXXX-XXXX)
    final hyphenatedRegex = RegExp(r'^\d{2}-\d{4}-\d{4}-\d{4}$');
    if (hyphenatedRegex.hasMatch(cleaned)) return true;

    // Pattern 2: 14 continuous digits
    final continuousRegex = RegExp(r'^\d{14}$');
    if (continuousRegex.hasMatch(cleaned)) return true;

    // Pattern 3: ABHA Address / Health ID (e.g. name@abdm or name@sbx)
    final abhaAddressRegex = RegExp(r'^[a-zA-Z0-9._]{3,32}@[a-zA-Z0-9]{3,}$');
    if (abhaAddressRegex.hasMatch(cleaned)) return true;

    return false;
  }

  /// Normalizes continuous 14 digits into canonical `XX-XXXX-XXXX-XXXX` format.
  static String normalizeAbhaNumber(String rawAbha) {
    final cleaned = rawAbha.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 14) {
      return '${cleaned.substring(0, 2)}-${cleaned.substring(2, 6)}-${cleaned.substring(6, 10)}-${cleaned.substring(10, 14)}';
    }
    return rawAbha.trim();
  }

  /// Captures and links an ABHA identifier offline for [memberId].
  ///
  /// Enforces:
  /// 1. Beneficiary MUST have granted informed consent (Requirement 4.6, 5.1).
  /// 2. Valid ABHA format.
  /// 3. Offline storage with initial unverified status (`abha_linked: false`).
  /// 4. Enqueues payload to BitChat SyncEngine to trigger online ABDM sandbox
  ///    verification upon next connection.
  Future<AbhaCaptureResult> captureAbhaOffline({
    required String memberId,
    required String rawAbhaId,
    int? timestamp,
  }) async {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;

    // 1. Verify Member Exists
    final member = await memberDao.getById(memberId);
    if (member == null) {
      throw ArgumentError('Member not found with ID: $memberId');
    }

    // 2. Enforce Informed Consent (Requirement 4.6)
    final hasConsent = await consentService.hasValidConsent(memberId);
    if (!hasConsent) {
      throw StateError(
        'Cannot link ABHA: Beneficiary has not granted informed consent or consent was withdrawn.',
      );
    }

    final consentRecord = await consentService.getLatestConsent(memberId);
    final consentArtifactId = consentRecord?.id ?? '';

    // 3. Format Validation
    if (!validateAbhaFormat(rawAbhaId)) {
      throw ArgumentError(
        'Invalid ABHA format. Must be a 14-digit ABHA number or valid ABHA address (e.g., name@abdm).',
      );
    }

    final formattedAbha = normalizeAbhaNumber(rawAbhaId);

    // 4. Offline Persistence: Store in Local_Store on Member record
    await (db.update(db.members)..where((t) => t.id.equals(memberId))).write(
      MembersCompanion(
        abhaId: Value(formattedAbha),
        updatedAt: Value(ts),
        syncStatus: const Value('pending'),
      ),
    );

    // 5. Enqueue to BitChat SyncEngine for Backend ABDM Sandbox Verification
    if (syncEngine != null) {
      await syncEngine!.enqueue(
        table: 'members',
        recordId: memberId,
        operation: 'link_abha',
        priority: SyncPriority.metadata,
        payload: {
          'id': memberId,
          'abha_id': formattedAbha,
          'abha_linked': false, // Verification pending on backend
          'consent_artifact_id': consentArtifactId,
          'captured_at': ts,
          'dirty_flag': 1,
          'sync_version': 1,
        },
      );
    }

    return AbhaCaptureResult(
      memberId: memberId,
      abhaId: formattedAbha,
      isLinked: false, // will be confirmed by backend ABDM verification
      consentArtifactId: consentArtifactId,
      capturedAt: ts,
    );
  }

  /// Called upon backend ABDM sync reconciliation to mark ABHA as verified and linked.
  Future<void> confirmAbhaLinked({
    required String memberId,
    required String verifiedAbhaId,
    int? timestamp,
  }) async {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    await (db.update(db.members)..where((t) => t.id.equals(memberId))).write(
      MembersCompanion(
        abhaId: Value(verifiedAbhaId),
        updatedAt: Value(ts),
        syncStatus: const Value('synced'),
      ),
    );
  }
}

// ── Riverpod Provider ─────────────────────────────────────────────────────────

final abhaServiceProvider = Provider<AbhaService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final memberDao = MemberDao(db);
  final consentService = ref.watch(consentServiceProvider);
  final syncEngine = ref.watch(syncEngineProvider);

  return AbhaService(
    db: db,
    memberDao: memberDao,
    consentService: consentService,
    syncEngine: syncEngine,
  );
});
