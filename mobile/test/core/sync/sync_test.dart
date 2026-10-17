import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/sync/sms_fallback.dart';
import 'package:asha_platform/core/sync/conflict_resolver.dart';
import 'package:asha_platform/core/sync/sync_worker.dart';

void main() {
  group('SmsFallback', () {
    test('generateReferralSms produces ≤160 char output', () {
      final sms = SmsFallback.generateReferralSms(
        memberId: 'MEMBER-001',
        ageYears: 28,
        sex: 'F',
        primaryFinding: 'Fast breathing',
        facilityName: 'PHC Rampur',
        ashaName: 'Sunita Devi',
        ashaPhone: '+919876543210',
        referralId: 'REF-2024-001',
        referralDate: DateTime(2024, 1, 15),
      );
      expect(sms.length, lessThanOrEqualTo(160));
    });

    test('generateReferralSms contains RED flag', () {
      final sms = SmsFallback.generateReferralSms(
        memberId: 'M1',
        ageYears: 5,
        sex: 'M',
        primaryFinding: 'Severe dehydration',
        facilityName: 'CHC',
        ashaName: 'Radha',
        ashaPhone: '9876543210',
        referralId: 'R001',
        referralDate: DateTime(2024, 3, 10),
      );
      expect(sms, contains('RED'));
      expect(sms, contains('ASHA REFERRAL'));
    });

    test('smsIntentUri produces valid sms: URI', () {
      final uri = SmsFallback.smsIntentUri('9876543210', 'Test message');
      expect(uri, startsWith('sms:9876543210'));
      expect(uri, contains('body='));
    });

    test('generateReferralSms trims very long inputs', () {
      final sms = SmsFallback.generateReferralSms(
        memberId: 'M' * 30,
        ageYears: 25,
        sex: 'F',
        primaryFinding: 'X' * 50,
        facilityName: 'Y' * 50,
        ashaName: 'Z' * 40,
        ashaPhone: '1234567890',
        referralId: 'R' * 30,
        referralDate: DateTime.now(),
      );
      expect(sms.length, lessThanOrEqualTo(160));
    });
  });

  group('ConflictResolver', () {
    test('applyConflicts marks auto_merged as resolved', () {
      final resolver = ConflictResolver();
      final conflicts = [
        ConflictItem(
          recordId: 'rec-1',
          table: 'members',
          conflictType: 'field_conflict',
          bothValues: [],
          resolution: 'auto_merged',
        ),
      ];
      final pending = resolver.applyConflicts(conflicts, DateTime.now().millisecondsSinceEpoch);
      expect(pending, isEmpty);
    });

    test('applyConflicts marks flagged_for_review as pending', () {
      final resolver = ConflictResolver();
      final conflicts = [
        ConflictItem(
          recordId: 'rec-2',
          table: 'members',
          conflictType: 'field_conflict',
          bothValues: [{'field': 'name', 'client': 'A', 'server': 'B'}],
          resolution: 'flagged_for_review',
        ),
      ];
      final pending = resolver.applyConflicts(conflicts, DateTime.now().millisecondsSinceEpoch);
      expect(pending, contains('rec-2'));
    });

    test('applyConflicts never auto-merges duplicate_identity', () {
      final resolver = ConflictResolver();
      final conflicts = [
        ConflictItem(
          recordId: 'rec-3',
          table: 'members',
          conflictType: 'duplicate_identity',
          bothValues: [],
          resolution: 'auto_merged', // even if server says auto_merged
        ),
      ];
      final pending = resolver.applyConflicts(conflicts, DateTime.now().millisecondsSinceEpoch);
      expect(pending, contains('rec-3'));
    });

    test('parseFromResponse returns empty list on malformed JSON', () {
      final items = ConflictResolver.parseFromResponse('not json');
      expect(items, isEmpty);
    });

    test('parseFromResponse parses valid response', () {
      const body = '''{"batch_id":"b1","server_received_at":0,"synced":[],"conflicts":[
        {"record_id":"r1","table":"households","conflict_type":"field_conflict",
         "both_values":[],"resolution":"auto_merged"}
      ],"server_watermarks":{}}''';
      final items = ConflictResolver.parseFromResponse(body);
      expect(items.length, 1);
      expect(items.first.recordId, 'r1');
    });
  });

  group('SyncWorker backoff', () {
    test('first attempt returns 30 seconds', () {
      expect(SyncWorker.backoffFor(0), const Duration(seconds: 30));
    });

    test('second attempt returns 60 seconds', () {
      expect(SyncWorker.backoffFor(1), const Duration(seconds: 60));
    });

    test('third attempt returns 120 seconds', () {
      expect(SyncWorker.backoffFor(2), const Duration(seconds: 120));
    });

    test('fourth and subsequent attempts cap at 300 seconds', () {
      expect(SyncWorker.backoffFor(3), const Duration(seconds: 300));
      expect(SyncWorker.backoffFor(10), const Duration(seconds: 300));
    });

    test('Property 7: backoff is monotonically non-decreasing', () {
      // Generate 20 attempts and verify ordering
      final durations = List.generate(20, SyncWorker.backoffFor);
      for (var i = 1; i < durations.length; i++) {
        expect(
          durations[i].inSeconds,
          greaterThanOrEqualTo(durations[i - 1].inSeconds),
          reason: 'Attempt $i backoff must be ≥ attempt ${i-1}',
        );
      }
    });
  });
}
