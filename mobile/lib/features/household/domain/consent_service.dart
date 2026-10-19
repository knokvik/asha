import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/member_dao.dart';

/// Method used to record beneficiary or guardian acknowledgment.
/// Requirements: 5.2
enum WitnessType {
  tapAck,
  thumbprintPhoto,
  voiceHash,
}

/// Plain-language consent statement provider for multilingual audio and text.
/// Requirements: 5.1
class ConsentTextProvider {
  static const String currentVersion = 'v1.0';

  static String getPlainLanguageStatement({String languageCode = 'en'}) {
    switch (languageCode) {
      case 'hi':
        return 'हम आपके और आपके परिवार के स्वास्थ्य की देखभाल, टीकाकरण और सरकारी योजनाओं के लाभ के लिए यह जानकारी दर्ज कर रहे हैं। यह जानकारी केवल आशा, एएनएम और डॉक्टर देख सकते हैं। आप किसी भी समय अपनी सहमति वापस ले सकते हैं, और आपातकालीन उपचार कभी नहीं रोका जाएगा।';
      case 'mr':
        return 'आम्ही तुमची आणि तुमच्या कुटुंबाची आरोग्य सेवा, लसीकरण आणि शासकीय योजनांच्या लाभासाठी ही माहिती नोंदवत आहोत. ही माहिती फक्त आशा, एएनएम आणि वैद्यकीय अधिकारी पाहू शकतात. तुम्ही कधीही तुमची संमती मागे घेऊ शकता, आणि आपत्कालीन उपचार कधीही थांबवले जाणार नाहीत.';
      case 'pa':
        return 'ਅਸੀਂ ਤੁਹਾਡੀ ਅਤੇ ਤੁਹਾਡੇ ਪਰਿਵਾਰ ਦੀ ਸਿਹਤ ਸੰਭਾਲ, ਟੀਕਾਕਰਨ ਅਤੇ ਸਰਕਾਰੀ ਸਕੀਮਾਂ ਦੇ ਲਾਭ ਲਈ ਇਹ ਜਾਣਕਾਰੀ ਦਰਜ ਕਰ ਰਹੇ ਹਾਂ। ਇਹ ਜਾਣਕਾਰੀ ਸਿਰਫ਼ ਆਸ਼ਾ, ਏਐਨਐਮ ਅਤੇ ਡਾਕਟਰ ਦੇਖ ਸਕਦੇ ਹਨ। ਤੁਸੀਂ ਕਿਸੇ ਵੀ ਸਮੇਂ ਆਪਣੀ ਸਹਿਮਤੀ ਵਾਪਸ ਲੈ ਸਕਦੇ ਹੋ, ਅਤੇ ਐਮਰਜੈਂਸੀ ਇਲਾਜ ਕਦੇ ਨਹੀਂ ਰੋਕਿਆ ਜਾਵੇਗਾ।';
      default:
        return 'We are collecting your health details to track care, scheduled checkups, immunizations, and welfare benefits. This data is only accessible to your assigned ASHA, ANM, and Primary Health Centre Medical Officer. You have the right to withdraw your consent at any time without losing any emergency care or public health assistance.';
    }
  }
}

/// Service managing informed consent collection, tamper-evident cryptographic signatures,
/// guardian branches for minors, emergency-only restrictions, and withdrawal sync.
///
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6
class ConsentService {
  final AppDatabase db;
  final MemberDao memberDao;
  final SyncEngine? syncEngine;
  static const _uuid = Uuid();

  ConsentService({
    required this.db,
    required this.memberDao,
    this.syncEngine,
  });

  /// Computes a tamper-evident SHA-256 signature hash of:
  /// (memberId + consentVersion + timestamp + ashaId)
  ///
  /// Requirements: 5.2
  static String computeSignatureHash({
    required String memberId,
    required String consentVersion,
    required int timestamp,
    required String ashaId,
  }) {
    final payload = '$memberId$consentVersion$timestamp$ashaId';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// Verifies whether the stored [record]'s signatureHash matches the cryptographic SHA-256
  /// of its canonical attributes, proving tamper-evidence.
  ///
  /// Requirements: 5.2
  static bool verifyTamperEvidence(ConsentRecord record) {
    final expectedHash = computeSignatureHash(
      memberId: record.memberId,
      consentVersion: record.consentVersion,
      timestamp: record.consentedAt,
      ashaId: record.ashaId,
    );
    return record.signatureHash == expectedHash;
  }

  /// Determines whether [member] is a minor (under 18 years of age).
  /// Requirements: 5.5
  static bool isMemberMinor(Member member, {DateTime? referenceDate}) {
    if (member.dobApprox == null) return false;
    final birthDate = DateTime.fromMillisecondsSinceEpoch(member.dobApprox!);
    final now = referenceDate ?? DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age < 18;
  }

  /// Grants consent, creating a tamper-evident [ConsentRecord] in Local_Store and updating
  /// the beneficiary's consent status to 'given'.
  ///
  /// If the beneficiary is a minor (<18 yrs) or incapacitated, guardian consent is enforced.
  /// Requirements: 5.1, 5.2, 5.5
  Future<ConsentRecord> grantConsent({
    required String memberId,
    required String ashaId,
    String consentVersion = ConsentTextProvider.currentVersion,
    WitnessType witnessType = WitnessType.tapAck,
    String? voiceAckAudioHash,
    bool isGuardianConsent = false,
    String? guardianRelationship,
    int? timestamp,
  }) async {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final member = await memberDao.getById(memberId);
    if (member == null) {
      throw ArgumentError('Member not found with ID: $memberId');
    }

    // Guardian verification for minors and incapacitated persons
    final isMinor = isMemberMinor(member);
    final effectiveGuardian = isGuardianConsent || isMinor;

    if (effectiveGuardian) {
      if (guardianRelationship == null || guardianRelationship.trim().isEmpty) {
        throw ArgumentError(
          'Guardian relationship is mandatory when recording consent for a minor or incapacitated person',
        );
      }
    }

    // Cryptographic signature hash: SHA256(memberId + consentVersion + timestamp + ashaId)
    final sigHash = computeSignatureHash(
      memberId: memberId,
      consentVersion: consentVersion,
      timestamp: ts,
      ashaId: ashaId,
    );

    final recordId = _uuid.v4();
    final companion = ConsentRecordsCompanion.insert(
      id: recordId,
      memberId: memberId,
      consentVersion: consentVersion,
      consentedAt: ts,
      ashaId: ashaId,
      witnessType: witnessType.name.toUpperCase(),
      signatureHash: sigHash,
      voiceAckAudioHash: Value(voiceAckAudioHash),
      isGuardianConsent: Value(effectiveGuardian),
      guardianRelationship: Value(guardianRelationship),
      syncStatus: const Value('pending'),
    );

    // Save consent record
    await db.into(db.consentRecords).insert(companion);

    // Update member record: consent_status = 'given'
    await (db.update(db.members)..where((t) => t.id.equals(memberId))).write(
      MembersCompanion(
        consentStatus: const Value('given'),
        consentUpdatedAt: Value(ts),
        updatedAt: Value(ts),
        syncStatus: const Value('pending'),
      ),
    );

    // Enqueue to BitChat SyncEngine
    if (syncEngine != null) {
      await syncEngine!.enqueue(
        table: 'consent_records',
        recordId: recordId,
        operation: 'insert',
        priority: SyncPriority.metadata,
        payload: {
          'id': recordId,
          'member_id': memberId,
          'consent_version': consentVersion,
          'consented_at': ts,
          'asha_id': ashaId,
          'witness_type': witnessType.name.toUpperCase(),
          'signature_hash': sigHash,
          'voice_ack_audio_hash': voiceAckAudioHash,
          'is_guardian_consent': effectiveGuardian,
          'guardian_relationship': guardianRelationship,
          'dirty_flag': 1,
          'sync_version': 1,
        },
      );
    }

    return (await (db.select(db.consentRecords)..where((t) => t.id.equals(recordId)))
        .getSingle());
  }

  /// Declines consent, placing the record into Emergency-Only Mode.
  /// Allows emergency triage and referrals while suppressing longitudinal profiling and
  /// non-emergency data sharing.
  ///
  /// Requirements: 5.3
  Future<void> declineConsent({
    required String memberId,
    required String ashaId,
    int? timestamp,
    String? reason,
  }) async {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final member = await memberDao.getById(memberId);
    if (member == null) {
      throw ArgumentError('Member not found with ID: $memberId');
    }

    // Update member record: consent_status = 'declined'
    await (db.update(db.members)..where((t) => t.id.equals(memberId))).write(
      MembersCompanion(
        consentStatus: const Value('declined'),
        consentUpdatedAt: Value(ts),
        updatedAt: Value(ts),
        syncStatus: const Value('pending'),
      ),
    );

    // Enqueue emergency mode status to BitChat SyncEngine
    if (syncEngine != null) {
      await syncEngine!.enqueue(
        table: 'members',
        recordId: memberId,
        operation: 'update',
        priority: SyncPriority.metadata,
        payload: {
          'id': memberId,
          'consent_status': 'declined',
          'consent_updated_at': ts,
          'emergency_only_mode': true,
          'decline_reason': reason,
          'recorded_by': ashaId,
          'dirty_flag': 1,
          'sync_version': 1,
        },
      );
    }
  }

  /// Withdraws previously granted consent, flagging the record, restricting optional data
  /// sharing, and immediately propagating the withdrawal to the sync queue.
  ///
  /// Requirements: 5.4
  Future<void> withdrawConsent({
    required String memberId,
    required String reason,
    required String ashaId,
    int? timestamp,
  }) async {
    final ts = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final member = await memberDao.getById(memberId);
    if (member == null) {
      throw ArgumentError('Member not found with ID: $memberId');
    }

    // 1. Mark existing active consent records as withdrawn
    await (db.update(db.consentRecords)
          ..where((t) => t.memberId.equals(memberId) & t.withdrawnAt.isNull()))
        .write(
      ConsentRecordsCompanion(
        withdrawnAt: Value(ts),
        withdrawalReason: Value(reason),
        syncStatus: const Value('pending'),
      ),
    );

    // 2. Update member consent_status to 'withdrawn'
    await (db.update(db.members)..where((t) => t.id.equals(memberId))).write(
      MembersCompanion(
        consentStatus: const Value('withdrawn'),
        consentUpdatedAt: Value(ts),
        updatedAt: Value(ts),
        syncStatus: const Value('pending'),
      ),
    );

    // 3. Immediately propagate withdrawal to sync queue with high priority (P1)
    if (syncEngine != null) {
      await syncEngine!.enqueue(
        table: 'consent_records',
        recordId: memberId,
        operation: 'withdraw',
        priority: SyncPriority.critical, // Immediate P1 sync per specification
        payload: {
          'member_id': memberId,
          'withdrawn_at': ts,
          'withdrawal_reason': reason,
          'asha_id': ashaId,
          'dirty_flag': 1,
          'sync_version': 1,
        },
      );
    }
  }

  /// Retrieves the most recent [ConsentRecord] for [memberId].
  Future<ConsentRecord?> getLatestConsent(String memberId) {
    return (db.select(db.consentRecords)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.consentedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Returns true if the member has valid, unwithdrawn consent.
  Future<bool> hasValidConsent(String memberId) async {
    final member = await memberDao.getById(memberId);
    if (member == null || member.consentStatus != 'given') {
      return false;
    }
    final latest = await getLatestConsent(memberId);
    return latest != null && latest.withdrawnAt == null;
  }

  /// Returns true if the beneficiary is restricted to Emergency-Only Mode.
  /// Requirements: 5.3
  Future<bool> isEmergencyOnlyMode(String memberId) async {
    final member = await memberDao.getById(memberId);
    return member?.consentStatus == 'declined';
  }

  /// Checks if re-consent is required due to policy/text version change or absence of consent.
  /// Requirements: 5.6
  Future<bool> checkNeedsReconsent({
    required String memberId,
    String currentVersion = ConsentTextProvider.currentVersion,
  }) async {
    final member = await memberDao.getById(memberId);
    if (member == null || member.consentStatus != 'given') {
      return true;
    }

    final latest = await getLatestConsent(memberId);
    if (latest == null || latest.withdrawnAt != null) {
      return true;
    }

    return latest.consentVersion != currentVersion;
  }
}

// ── Riverpod Provider ─────────────────────────────────────────────────────────

final consentServiceProvider = Provider<ConsentService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final memberDao = MemberDao(db);
  final syncEngine = ref.watch(syncEngineProvider);

  return ConsentService(
    db: db,
    memberDao: memberDao,
    syncEngine: syncEngine,
  );
});
