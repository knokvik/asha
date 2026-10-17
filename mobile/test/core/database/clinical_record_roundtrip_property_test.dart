import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:asha_platform/core/database/app_database.dart';

/// Property-Based Test: Clinical Record Serialisation Round-Trip (Property 1)
///
/// **Property 1: Clinical Record Serialisation Round-Trip**
/// For any valid clinical record (Member, ClinicalEncounter, ConsentRecord, IncentiveClaim)
/// stored in the Local_Store, deserialising the serialised form must produce a value equal
/// to the original across all field types — date, enum, numeric, nullable text, and blob.
///
/// **Validates: Requirements 1.2, 5.2, 9.1, 52.6**
void main() {
  final random = Random(1337); // Deterministic seed for reproducible property runs
  const iterations = 500; // 500 examples for release validation

  String randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_ -';
    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  group('Property 1: Clinical Record Serialisation Round-Trip (500 Iterations)', () {
    test('Member serialization round-trip across all field types (dates, enums, nullables)', () {
      final sexes = ['M', 'F', 'O'];
      final socialCats = ['GEN', 'SC', 'ST', 'OBC', null];
      final relationships = ['Self', 'Spouse', 'Child', 'Parent', null];
      final statuses = ['active', 'migrated', 'deceased'];
      final consentStatuses = ['given', 'refused', 'pending'];

      for (var i = 0; i < iterations; i++) {
        final member = Member(
          id: 'mem_${random.nextInt(1000000)}_${randomString(6)}',
          householdId: 'hh_${random.nextInt(50000)}',
          name: 'Person ${randomString(10)}',
          namePhonetic: random.nextBool() ? 'PRSN_${randomString(6)}' : null,
          dobApprox: random.nextBool() ? random.nextInt(1800000000) : null,
          isDobApprox: random.nextBool(),
          sex: sexes[random.nextInt(sexes.length)],
          relationshipToHead: relationships[random.nextInt(relationships.length)],
          abhaId: random.nextBool() ? '14-${random.nextInt(9000) + 1000}-${random.nextInt(9000) + 1000}-${random.nextInt(9000) + 1000}' : null,
          rchId: random.nextBool() ? 'RCH_${random.nextInt(99999999)}' : null,
          phone: random.nextBool() ? '98${random.nextInt(90000000) + 10000000}' : null,
          socialCategory: socialCats[random.nextInt(socialCats.length)],
          isBpl: random.nextBool() ? random.nextBool() : null,
          lifecycleStatus: statuses[random.nextInt(statuses.length)],
          consentStatus: consentStatuses[random.nextInt(consentStatuses.length)],
          consentUpdatedAt: random.nextBool() ? random.nextInt(1800000000) : null,
          createdAt: random.nextInt(1800000000),
          updatedAt: random.nextInt(1800000000),
          createdBy: 'asha_${random.nextInt(1000)}',
          syncStatus: random.nextBool() ? 'synced' : 'pending',
          serverVersion: random.nextBool() ? random.nextInt(1000) : null,
        );

        // Serialize to JSON Map and String
        final serializedMap = member.toJson();
        final jsonString = jsonEncode(serializedMap);

        // Deserialise back
        final deserializedMap = jsonDecode(jsonString) as Map<String, dynamic>;
        final reconstructed = Member.fromJson(deserializedMap);

        // Invariant check: deserialise(serialise(record)) == record
        expect(reconstructed, equals(member),
            reason: 'Member iteration $i failed deserialization round-trip');
        expect(reconstructed.id, equals(member.id));
        expect(reconstructed.name, equals(member.name));
        expect(reconstructed.isDobApprox, equals(member.isDobApprox));
        expect(reconstructed.isBpl, equals(member.isBpl));
      }
    });

    test('ClinicalEncounter serialization round-trip across all field types', () {
      final encTypes = ['anc_visit', 'pnc_visit', 'hbnc_visit', 'ncd_screening', 'immunization', 'tb_followup'];
      final programs = ['ANC', 'PNC', 'HBNC', 'NCD', 'IMM', 'TB', 'FP', 'CRS'];
      final statuses = ['completed', 'partial', 'cancelled'];

      for (var i = 0; i < iterations; i++) {
        final encounter = ClinicalEncounter(
          id: 'enc_${random.nextInt(1000000)}_${randomString(5)}',
          memberId: 'mem_${random.nextInt(50000)}',
          encounterType: encTypes[random.nextInt(encTypes.length)],
          programCode: programs[random.nextInt(programs.length)],
          encounterDate: random.nextInt(1800000000),
          ashaId: 'asha_${random.nextInt(500)}',
          ruleVersionId: random.nextBool() ? 'rules_v${random.nextInt(10)}' : null,
          status: statuses[random.nextInt(statuses.length)],
          visitNotes: random.nextBool() ? 'Notes: ${randomString(30)}' : null,
          createdAt: random.nextInt(1800000000),
          updatedAt: random.nextInt(1800000000),
          syncStatus: random.nextBool() ? 'pending' : 'synced',
          serverVersion: random.nextBool() ? random.nextInt(500) : null,
        );

        final jsonString = jsonEncode(encounter.toJson());
        final reconstructed = ClinicalEncounter.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

        expect(reconstructed, equals(encounter),
            reason: 'Encounter iteration $i failed round-trip');
        expect(reconstructed.id, equals(encounter.id));
        expect(reconstructed.encounterDate, equals(encounter.encounterDate));
        expect(reconstructed.ruleVersionId, equals(encounter.ruleVersionId));
        expect(reconstructed.visitNotes, equals(encounter.visitNotes));
      }
    });

    test('ConsentRecord serialization round-trip across digital signatures and hashes', () {
      final witnessTypes = ['self', 'guardian', 'verbal_witnessed'];

      for (var i = 0; i < iterations; i++) {
        final consent = ConsentRecord(
          id: 'consent_${random.nextInt(1000000)}_${randomString(4)}',
          memberId: 'mem_${random.nextInt(50000)}',
          consentVersion: 'v${random.nextInt(5) + 1}.0',
          consentedAt: random.nextInt(1800000000),
          ashaId: 'asha_${random.nextInt(500)}',
          witnessType: witnessTypes[random.nextInt(witnessTypes.length)],
          signatureHash: randomString(64),
          voiceAckAudioHash: random.nextBool() ? randomString(64) : null,
          isGuardianConsent: random.nextBool(),
          guardianRelationship: random.nextBool() ? 'Father' : null,
          withdrawnAt: random.nextBool() ? random.nextInt(1800000000) : null,
          withdrawalReason: random.nextBool() ? 'Requested withdrawal' : null,
          syncStatus: random.nextBool() ? 'synced' : 'pending',
        );

        final jsonString = jsonEncode(consent.toJson());
        final reconstructed = ConsentRecord.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

        expect(reconstructed, equals(consent),
            reason: 'Consent iteration $i failed round-trip');
        expect(reconstructed.id, equals(consent.id));
        expect(reconstructed.signatureHash, equals(consent.signatureHash));
        expect(reconstructed.voiceAckAudioHash, equals(consent.voiceAckAudioHash));
        expect(reconstructed.isGuardianConsent, equals(consent.isGuardianConsent));
      }
    });

    test('IncentiveClaim serialization round-trip with floating-point amounts and JSON line items', () {
      final statuses = ['draft', 'submitted', 'verified', 'approved', 'paid', 'disputed'];

      for (var i = 0; i < iterations; i++) {
        final nItems = random.nextInt(5) + 1;
        final items = List.generate(nItems, (idx) => {
          'activity_code': 'ACT_${100 + idx}',
          'rate': (random.nextDouble() * 500).roundToDouble(),
          'member_id': 'mem_${random.nextInt(1000)}',
          'date': '2026-10-${random.nextInt(28) + 1}',
        });

        final claim = IncentiveClaim(
          id: 'claim_${random.nextInt(1000000)}_${randomString(4)}',
          workerId: 'asha_${random.nextInt(500)}',
          claimPeriod: '2026-${(random.nextInt(12) + 1).toString().padLeft(2, '0')}',
          status: statuses[random.nextInt(statuses.length)],
          lineItemsJson: jsonEncode(items),
          totalAmount: double.parse((random.nextDouble() * 5000).toStringAsFixed(2)),
          pdfPath: random.nextBool() ? '/storage/claims/voucher_${random.nextInt(1000)}.pdf' : null,
          paymentReference: random.nextBool() ? 'PFMS_REF_${randomString(12)}' : null,
          submittedAt: random.nextBool() ? random.nextInt(1800000000) : null,
          verifiedAt: random.nextBool() ? random.nextInt(1800000000) : null,
          paidAt: random.nextBool() ? random.nextInt(1800000000) : null,
          syncStatus: random.nextBool() ? 'synced' : 'pending',
        );

        final jsonString = jsonEncode(claim.toJson());
        final reconstructed = IncentiveClaim.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

        expect(reconstructed, equals(claim),
            reason: 'IncentiveClaim iteration $i failed round-trip');
        expect(reconstructed.id, equals(claim.id));
        expect(reconstructed.totalAmount, equals(claim.totalAmount));
        expect(reconstructed.lineItemsJson, equals(claim.lineItemsJson));
      }
    });
  });
}
