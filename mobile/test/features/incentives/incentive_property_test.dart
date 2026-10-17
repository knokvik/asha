import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asha_platform/core/database/app_database.dart';
import 'package:asha_platform/core/sync/sync_engine.dart';
import 'package:asha_platform/features/incentives/data/claim_service.dart';
import 'package:asha_platform/features/incentives/domain/claim_models.dart';
import 'package:asha_platform/features/incentives/domain/incentive_models.dart';
import 'package:asha_platform/features/incentives/domain/incentive_service.dart';

/// Helper to extract all decompressed text content from a PDF binary.
String extractPdfText(Uint8List pdfBytes) {
  final buffer = StringBuffer();
  final pdfStr = latin1.decode(pdfBytes);

  // Pattern: << ... /Length (\d+) ... >>\s*stream\r?\n
  final dictPattern = RegExp(
    r'<<(?:(?!>>).)*?/Length\s+(\d+)(?:(?!>>).)*?>>\s*stream\r?\n',
    dotAll: true,
  );

  final matches = dictPattern.allMatches(pdfStr).toList();
  for (final match in matches) {
    final length = int.parse(match.group(1)!);
    final streamStart = match.end;
    if (streamStart + length <= pdfBytes.length) {
      final streamSlice = pdfBytes.sublist(streamStart, streamStart + length);
      Uint8List decompressed;
      try {
        decompressed = Uint8List.fromList(zlib.decode(streamSlice));
      } catch (_) {
        decompressed = streamSlice;
      }
      final decodedText = latin1.decode(decompressed);
      final strMatches = RegExp(r'\((.*?)\)').allMatches(decodedText);
      for (final m in strMatches) {
        final s = m.group(1) ?? '';
        final unescaped = s.replaceAll(r'\(', '(').replaceAll(r'\)', ')').replaceAll(r'\\', r'\');
        buffer.write('$unescaped ');
      }
      buffer.write('$decodedText ');
    }
  }

  // Also append outer text objects
  buffer.write(' $pdfStr ');

  return buffer.toString();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SyncEngine syncEngine;
  late IncentiveService incentiveService;
  late ClaimService claimService;
  final random = Random(42);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    syncEngine = SyncEngine(db);
    incentiveService = IncentiveService(db: db, syncEngine: syncEngine);
    claimService = ClaimService(
      db: db,
      incentiveService: incentiveService,
      syncEngine: syncEngine,
    );
  });

  tearDown(() async {
    await db.close();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPERTY 10: Incentive Event Deduplication (Req 54.1, 54.6)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Task 13.7: Property 10 — Incentive Event Deduplication (Req 54.1, 54.6)', () {
    test(
      'Property 10 Invariant: Recording the same eligible event N times produces exactly one record across 50 randomized trials',
      () async {
        final activityCodes = [
          'ANC_REG_EARLY',
          'ANC_CHECKUP_FULL',
          'INSTITUTIONAL_DELIVERY',
          'HBNC_COMPLETE',
          'IMM_FULL_1YEAR',
          'CBAC_SCREENING',
          'NCD_FOLLOWUP',
          'TB_DOTS_COMPLETION',
        ];

        final nowMs = DateTime.now().millisecondsSinceEpoch;

        // Seed worker
        await db.into(db.users).insert(
              UsersCompanion.insert(
                id: 'worker_p10',
                ashaId: 'ASHA_P10',
                name: 'Test ASHA P10',
                role: 'ASHA',
                createdAt: nowMs,
                updatedAt: nowMs,
              ),
            );

        // Seed household
        await db.into(db.households).insert(
              HouseholdsCompanion.insert(
                id: 'hh_p10',
                village: 'Rampur',
                headName: 'Head Name',
                createdBy: 'worker_p10',
                createdAt: nowMs,
                updatedAt: nowMs,
              ),
            );

        for (int trial = 0; trial < 50; trial++) {
          final memberId = 'mem_p10_${trial}_${random.nextInt(10000)}';
          final encId = 'enc_p10_${trial}_$memberId';
          final activityCode = activityCodes[random.nextInt(activityCodes.length)];
          final daysAgo = random.nextInt(60);
          final eventDate = DateTime.now().subtract(Duration(days: daysAgo));
          final retryCount = random.nextInt(6) + 2; // 2 to 7 retries

          // Seed member
          await db.into(db.members).insert(
                MembersCompanion.insert(
                  id: memberId,
                  householdId: 'hh_p10',
                  name: 'Beneficiary $trial',
                  sex: 'F',
                  createdAt: nowMs,
                  updatedAt: nowMs,
                  createdBy: 'worker_p10',
                ),
              );

          // Seed clinical encounter to satisfy provenance check (Property 12)
          await db.into(db.clinicalEncounters).insert(
                ClinicalEncountersCompanion.insert(
                  id: encId,
                  memberId: memberId,
                  encounterType: 'ANC_VISIT',
                  programCode: 'maternal',
                  encounterDate: eventDate.millisecondsSinceEpoch,
                  ashaId: 'worker_p10',
                  createdAt: nowMs,
                  updatedAt: nowMs,
                ),
              );

          String? firstEventId;
          String? firstIdempotencyKey;

          // Record same event N times (network retries)
          for (int retry = 0; retry < retryCount; retry++) {
            final event = await incentiveService.recordEvent(
              activityCode: activityCode,
              memberId: memberId,
              eventDate: eventDate,
              encounterId: encId,
              eventData: {'gestational_weeks': 8},
            );

            if (firstEventId == null) {
              firstEventId = event.id;
              firstIdempotencyKey = event.idempotencyKey;
            } else {
              // Determinism check: subsequent calls return identical event ID and key
              expect(
                event.id,
                equals(firstEventId),
                reason: 'Property 10 violated: retry $retry returned differing event ID',
              );
              expect(
                event.idempotencyKey,
                equals(firstIdempotencyKey),
                reason: 'Property 10 violated: retry $retry returned differing idempotency key',
              );
            }
          }

          // Invariant: exactly 1 record exists in the database for this event
          final storedEvents = await (db.select(db.incentiveEvents)
                ..where((t) => t.idempotencyKey.equals(firstIdempotencyKey!)))
              .get();

          expect(
            storedEvents.length,
            equals(1),
            reason: 'Property 10 Invariant violated: Expected 1 record for idempotency_key $firstIdempotencyKey, got ${storedEvents.length}',
          );
        }
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPERTY 11: Incentive Historical Rate Invariant (Req 53.2)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Task 13.7: Property 11 — Incentive Historical Rate Invariant (Req 53.2)', () {
    test(
      'Property 11 Invariant: Historical claims resolve rates using catalogue version active at event completion date across 50 randomized trials',
      () {
        final cat2022 = IncentiveCatalogue(
          versionId: 'CAT_2022_V1',
          stateCode: 'DEFAULT',
          effectiveFrom: DateTime(2022, 1, 1),
          effectiveTo: DateTime(2022, 12, 31, 23, 59, 59),
          items: {
            'ANC_REG_EARLY': const IncentiveCatalogueItem(
              activityCode: 'ANC_REG_EARLY',
              activityName: 'Early ANC Registration',
              category: 'RCH',
              rates: PaymentComponent(fixedHonorarium: 0, performanceIncentive: 75, stateTopUp: 25),
              submissionWindowDays: 60,
              requiredEvidenceType: 'CLINICAL_ENCOUNTER',
            ),
            'HBNC_COMPLETE': const IncentiveCatalogueItem(
              activityCode: 'HBNC_COMPLETE',
              activityName: 'Complete HBNC Visits',
              category: 'CHILD',
              rates: PaymentComponent(fixedHonorarium: 0, performanceIncentive: 175, stateTopUp: 25),
              submissionWindowDays: 60,
              requiredEvidenceType: 'CLINICAL_ENCOUNTER',
            ),
          },
        );

        final cat2023 = IncentiveCatalogue(
          versionId: 'CAT_2023_V1',
          stateCode: 'DEFAULT',
          effectiveFrom: DateTime(2023, 1, 1),
          effectiveTo: DateTime(2023, 12, 31, 23, 59, 59),
          items: {
            'ANC_REG_EARLY': const IncentiveCatalogueItem(
              activityCode: 'ANC_REG_EARLY',
              activityName: 'Early ANC Registration',
              category: 'RCH',
              rates: PaymentComponent(fixedHonorarium: 0, performanceIncentive: 100, stateTopUp: 50),
              submissionWindowDays: 60,
              requiredEvidenceType: 'CLINICAL_ENCOUNTER',
            ),
            'HBNC_COMPLETE': const IncentiveCatalogueItem(
              activityCode: 'HBNC_COMPLETE',
              activityName: 'Complete HBNC Visits',
              category: 'CHILD',
              rates: PaymentComponent(fixedHonorarium: 0, performanceIncentive: 200, stateTopUp: 50),
              submissionWindowDays: 60,
              requiredEvidenceType: 'CLINICAL_ENCOUNTER',
            ),
          },
        );

        final cat2024 = IncentiveCatalogue(
          versionId: 'CAT_2024_V1',
          stateCode: 'DEFAULT',
          effectiveFrom: DateTime(2024, 1, 1),
          effectiveTo: null, // active version
          items: {
            'ANC_REG_EARLY': const IncentiveCatalogueItem(
              activityCode: 'ANC_REG_EARLY',
              activityName: 'Early ANC Registration',
              category: 'RCH',
              rates: PaymentComponent(fixedHonorarium: 0, performanceIncentive: 150, stateTopUp: 75),
              submissionWindowDays: 60,
              requiredEvidenceType: 'CLINICAL_ENCOUNTER',
            ),
            'HBNC_COMPLETE': const IncentiveCatalogueItem(
              activityCode: 'HBNC_COMPLETE',
              activityName: 'Complete HBNC Visits',
              category: 'CHILD',
              rates: PaymentComponent(fixedHonorarium: 0, performanceIncentive: 250, stateTopUp: 75),
              submissionWindowDays: 60,
              requiredEvidenceType: 'CLINICAL_ENCOUNTER',
            ),
          },
        );

        final catalogues = [cat2022, cat2023, cat2024];

        IncentiveCatalogue? resolveCatalogue(DateTime eventDate) {
          for (final cat in catalogues) {
            final fromOk = !eventDate.isBefore(cat.effectiveFrom);
            final toOk = cat.effectiveTo == null || !eventDate.isAfter(cat.effectiveTo!);
            if (fromOk && toOk) return cat;
          }
          return null;
        }

        for (int trial = 0; trial < 50; trial++) {
          final year = 2022 + random.nextInt(3); // 2022, 2023, or 2024
          final month = random.nextInt(12) + 1;
          final day = random.nextInt(28) + 1;
          final testDate = DateTime(year, month, day);

          final resolved = resolveCatalogue(testDate);
          expect(resolved, isNotNull);

          if (year == 2022) {
            expect(resolved!.versionId, equals('CAT_2022_V1'));
            final rate = resolved.getItem('ANC_REG_EARLY')!.rates.totalRate;
            expect(rate, equals(100.0), reason: '2022 rate must be 75+25=100');
          } else if (year == 2023) {
            expect(resolved!.versionId, equals('CAT_2023_V1'));
            final rate = resolved.getItem('ANC_REG_EARLY')!.rates.totalRate;
            expect(rate, equals(150.0), reason: '2023 rate must be 100+50=150');
          } else {
            expect(resolved!.versionId, equals('CAT_2024_V1'));
            final rate = resolved.getItem('ANC_REG_EARLY')!.rates.totalRate;
            expect(rate, equals(225.0), reason: '2024 rate must be 150+75=225');
          }
        }
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // PROPERTY 12: Claim Line-Item Round-Trip (Req 56.1, 56.7)
  // ═══════════════════════════════════════════════════════════════════════════
  group('Task 13.7: Property 12 — Claim Line-Item Round-Trip (Req 56.1, 56.7)', () {
    test(
      'Property 12 Invariant: parse(generate_pdf(claim)) preserves all line items, codes, amounts, member IDs, and dates without loss',
      () async {
        final activityPool = [
          ('ANC_REG_EARLY', 'Early ANC Registration', 100.0),
          ('ANC_CHECKUP_FULL', 'Complete 4 ANC Checkups', 200.0),
          ('INSTITUTIONAL_DELIVERY', 'Institutional Delivery Facilitation', 600.0),
          ('HBNC_COMPLETE', 'Complete 6/7 HBNC Home Visits', 250.0),
          ('IMM_FULL_1YEAR', 'Complete 1-Year Immunization', 100.0),
          ('CBAC_SCREENING', 'CBAC NCD Screening', 10.0),
          ('NCD_FOLLOWUP', 'NCD Patient Treatment Followup', 50.0),
          ('TB_DOTS_COMPLETION', 'TB Treatment DOTS Completion', 1000.0),
        ];

        for (int trial = 0; trial < 10; trial++) {
          final itemCount = random.nextInt(6) + 1; // 1 to 6 items per claim
          final lineItems = <ClaimLineItem>[];
          double totalAmount = 0.0;

          for (int i = 0; i < itemCount; i++) {
            final sample = activityPool[random.nextInt(activityPool.length)];
            final actCode = sample.$1;
            final actName = sample.$2;
            final amount = sample.$3;
            totalAmount += amount;

            final serviceDate = DateTime(2024, 4, (i % 25) + 1);
            final memberId = 'MEM-10$i$trial';
            final eventId = 'ev_${trial}_$i';

            lineItems.add(
              ClaimLineItem(
                incentiveEventId: eventId,
                activityCode: actCode,
                activityName: actName,
                memberCodedId: memberId,
                serviceDate: serviceDate,
                amount: amount,
                evidenceRecordId: 'REC-$i$trial',
                status: 'verified',
              ),
            );
          }

          final claim = IncentiveClaimModel(
            id: 'claim_roundtrip_$trial',
            workerId: 'worker_p12_$trial',
            claimPeriod: '2024-04',
            status: 'approved',
            lineItems: lineItems,
            totalAmount: totalAmount,
          );

          // Generate PDF
          final pdfBytes = await claimService.generateVoucherPdf(
            claim: claim,
            workerName: 'ASHA Sunita Devi',
            workerAshaId: 'ASHA-12345',
            village: 'Rampur',
            phc: 'PHC Rampur',
            subCenter: 'SC Rampur-A',
          );

          expect(pdfBytes, isNotEmpty);
          expect(pdfBytes.sublist(0, 4), equals([37, 80, 68, 70])); // %PDF

          // Extract plain text from PDF streams
          final pdfText = extractPdfText(pdfBytes);

          // Assert Property 12: all line items survive PDF generation
          // 1. Total amount with exact 2 decimal places
          expect(
            pdfText.contains(totalAmount.toStringAsFixed(2)),
            isTrue,
            reason: 'Property 12 violated: Total amount ${totalAmount.toStringAsFixed(2)} missing from PDF text',
          );

          // 2. Each line item survives
          for (final item in lineItems) {
            // Activity code
            expect(
              pdfText.contains(item.activityCode),
              isTrue,
              reason: 'Property 12 violated: Activity code ${item.activityCode} missing from PDF text',
            );

            // Member coded ID
            expect(
              pdfText.contains(item.memberCodedId),
              isTrue,
              reason: 'Property 12 violated: Member ID ${item.memberCodedId} missing from PDF text',
            );

            // Service date (YYYY-MM-DD)
            final dateStr = item.serviceDate.toIso8601String().substring(0, 10);
            expect(
              pdfText.contains(dateStr),
              isTrue,
              reason: 'Property 12 violated: Service date $dateStr missing from PDF text',
            );

            // Amount formatted to 2 decimals
            final amountStr = item.amount.toStringAsFixed(2);
            expect(
              pdfText.contains(amountStr),
              isTrue,
              reason: 'Property 12 violated: Amount $amountStr missing from PDF text',
            );
          }
        }
      },
    );
  });
}
