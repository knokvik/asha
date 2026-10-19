import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import 'incentive_models.dart';

/// Exception thrown when an incentive event refers to a non-existent clinical record (Property 12).
class OrphanedIncentiveException implements Exception {
  final String message;
  OrphanedIncentiveException(this.message);

  @override
  String toString() => 'OrphanedIncentiveException: $message';
}

/// Domain service for loading versioned incentive catalogues, evaluating task eligibility,
/// auto-logging incentive events with strict idempotency and clinical provenance,
/// tracking deferred eligibility, and providing multilingual explanations with audio cues.
///
/// Requirements: 53.1, 53.2, 53.3, 53.4, 54.1, 54.2, 54.3, 54.4, 54.5, 54.6
class IncentiveService {
  final AppDatabase db;
  final SyncEngine? syncEngine;
  static const _uuid = Uuid();

  // State code -> List of versioned catalogues (sorted by effectiveFrom)
  final Map<String, List<IncentiveCatalogue>> _catalogues = {};

  AppDatabase get _db => db;
  SyncEngine? get _syncEngine => syncEngine;

  IncentiveService({
    required this.db,
    this.syncEngine,
  });

  // ── Catalogue Management ──────────────────────────────────────────────────

  /// Registers or updates a catalogue version in memory.
  void registerCatalogue(IncentiveCatalogue catalogue) {
    final list = _catalogues.putIfAbsent(catalogue.stateCode, () => []);
    list.removeWhere((c) => c.versionId == catalogue.versionId);
    list.add(catalogue);
    list.sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));
  }

  /// Loads a catalogue from a JSON string without hardcoding rates (Req 53.1).
  IncentiveCatalogue loadCatalogueFromJson(String jsonString) {
    final catalogue = IncentiveCatalogue.fromJsonString(jsonString);
    registerCatalogue(catalogue);
    return catalogue;
  }

  /// Loads the default catalogue from flutter asset bundle if available.
  Future<IncentiveCatalogue?> loadDefaultCatalogueFromAssets({
    String assetPath = 'assets/incentives/catalogue_default.json',
  }) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      return loadCatalogueFromJson(jsonString);
    } catch (_) {
      return null;
    }
  }

  /// Returns the catalogue active on [date] for [stateCode] (Req 53.2, Property 11).
  ///
  /// Invariant: Any historical claim computes rates using the catalogue version
  /// active on the date the event was completed.
  IncentiveCatalogue? getCatalogueForDate(
    DateTime date, {
    String stateCode = 'DEFAULT',
  }) {
    List<IncentiveCatalogue>? list = _catalogues[stateCode];
    if (list == null || list.isEmpty) {
      list = _catalogues['DEFAULT'];
    }
    if (list == null || list.isEmpty) return null;

    // Find the version where effectiveFrom <= date <= effectiveTo
    for (final cat in list.reversed) {
      if (cat.isEffective(date)) {
        return cat;
      }
    }

    // Fallback: nearest active or most recent version
    return list.last;
  }

  /// Lists all registered catalogue versions for a state.
  List<IncentiveCatalogue> getCataloguesForState(String stateCode) {
    return List.unmodifiable(_catalogues[stateCode] ?? _catalogues['DEFAULT'] ?? []);
  }

  // ── Deterministic Idempotency Key ──────────────────────────────────────────

  /// Generates a deterministic idempotency key from activityCode, memberId, and eventDate.
  ///
  /// Property 10: hash(activityCode + memberId + eventDate)
  static String generateIdempotencyKey(
    String activityCode,
    String memberId,
    DateTime eventDate,
  ) {
    final dateStr =
        '${eventDate.year.toString().padLeft(4, '0')}-${eventDate.month.toString().padLeft(2, '0')}-${eventDate.day.toString().padLeft(2, '0')}';
    final raw = '${activityCode}_${memberId}_$dateStr';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  // ── Eligibility Evaluation ────────────────────────────────────────────────

  /// Evaluates eligibility for an activity based on catalogue conditions (Req 54.1, 54.2, 54.3, 54.4).
  EligibilityCheckResult evaluateEligibility({
    required String activityCode,
    required String memberId,
    required DateTime eventDate,
    required Map<String, dynamic> eventData,
    String language = 'en',
    String stateCode = 'DEFAULT',
    String? evidenceRecordId,
  }) {
    final catalogue = getCatalogueForDate(eventDate, stateCode: stateCode);
    if (catalogue == null) {
      return EligibilityCheckResult(
        activityCode: activityCode,
        isEligible: false,
        ineligibilityReasonCode: 'NO_CATALOGUE_FOUND',
        ineligibilityReasonText: 'No active incentive catalogue found for this date.',
      );
    }

    final item = catalogue.getItem(activityCode);
    if (item == null) {
      return EligibilityCheckResult(
        activityCode: activityCode,
        isEligible: false,
        ineligibilityReasonCode: 'UNKNOWN_ACTIVITY',
        ineligibilityReasonText: 'Activity not found in current catalogue.',
      );
    }

    final conditions = item.eligibilityConditions;

    switch (activityCode) {
      case 'ANC_REG_EARLY':
        final gestWeeks = eventData['gestational_weeks'] as num? ??
            eventData['gestationalWeeks'] as num?;
        final maxWeeks = (conditions['max_gestational_weeks'] as num?)?.toInt() ?? 12;

        if (gestWeeks != null && gestWeeks > maxWeeks) {
          final reason = 'LATE_REGISTRATION';
          return EligibilityCheckResult(
            activityCode: activityCode,
            isEligible: false,
            completionProgress: 1.0,
            ineligibilityReasonCode: reason,
            ineligibilityReasonText: item.getIneligibilityMessage(reason, language),
            audioClipPath: item.getIneligibilityAudio(reason, language),
            rates: item.rates,
            evidenceRecordId: evidenceRecordId,
          );
        }
        return EligibilityCheckResult(
          activityCode: activityCode,
          isEligible: true,
          completionProgress: 1.0,
          rates: item.rates,
          evidenceRecordId: evidenceRecordId,
        );

      case 'ANC_CHECKUP_FULL':
        final visits = (eventData['anc_visits_completed'] as num? ?? 0).toInt();
        final minVisits = (conditions['min_anc_visits'] as num?)?.toInt() ?? 4;
        final hasTt = eventData['tt_received'] as bool? ?? false;
        final hasIfa = eventData['ifa_provided'] as bool? ?? false;

        final meetsVisits = visits >= minVisits;
        final meetsTt = !conditions.containsKey('requires_tt') || hasTt;
        final meetsIfa = !conditions.containsKey('requires_ifa') || hasIfa;

        if (meetsVisits && meetsTt && meetsIfa) {
          return EligibilityCheckResult(
            activityCode: activityCode,
            isEligible: true,
            completionProgress: 1.0,
            completedCount: visits,
            requiredCount: minVisits,
            rates: item.rates,
            evidenceRecordId: evidenceRecordId,
          );
        } else {
          final progress = (visits / minVisits.toDouble()).clamp(0.0, 1.0);
          return EligibilityCheckResult(
            activityCode: activityCode,
            isEligible: false,
            isDeferred: true,
            completionProgress: progress,
            completedCount: visits,
            requiredCount: minVisits,
            ineligibilityReasonCode: 'INSUFFICIENT_VISITS',
            ineligibilityReasonText: item.getIneligibilityMessage('INSUFFICIENT_VISITS', language),
            rates: item.rates,
            evidenceRecordId: evidenceRecordId,
          );
        }

      case 'INST_DELIVERY_ESCORT':
        final location = (eventData['delivery_location'] as String?)?.toUpperCase();
        if (location != null && (location == 'HOME' || location == 'TRANSIT')) {
          const reason = 'HOME_DELIVERY';
          return EligibilityCheckResult(
            activityCode: activityCode,
            isEligible: false,
            completionProgress: 1.0,
            ineligibilityReasonCode: reason,
            ineligibilityReasonText: item.getIneligibilityMessage(reason, language),
            audioClipPath: item.getIneligibilityAudio(reason, language),
            rates: item.rates,
            evidenceRecordId: evidenceRecordId,
          );
        }
        return EligibilityCheckResult(
          activityCode: activityCode,
          isEligible: true,
          completionProgress: 1.0,
          rates: item.rates,
          evidenceRecordId: evidenceRecordId,
        );

      case 'HBNC_COMPLETE':
        final visitsCompleted = (eventData['hbnc_visits_completed'] as num? ?? 0).toInt();
        final isHomeDelivery = eventData['is_home_delivery'] as bool? ?? false;
        final requiredCount = isHomeDelivery
            ? (conditions['home_visits_required'] as num?)?.toInt() ?? 7
            : (conditions['institutional_visits_required'] as num?)?.toInt() ?? 6;

        if (visitsCompleted >= requiredCount) {
          return EligibilityCheckResult(
            activityCode: activityCode,
            isEligible: true,
            completionProgress: 1.0,
            completedCount: visitsCompleted,
            requiredCount: requiredCount,
            rates: item.rates,
            evidenceRecordId: evidenceRecordId,
          );
        } else {
          final progress = (visitsCompleted / requiredCount.toDouble()).clamp(0.0, 1.0);
          return EligibilityCheckResult(
            activityCode: activityCode,
            isEligible: false,
            isDeferred: true,
            completionProgress: progress,
            completedCount: visitsCompleted,
            requiredCount: requiredCount,
            ineligibilityReasonCode: 'INCOMPLETE_VISITS',
            ineligibilityReasonText: item.getIneligibilityMessage('INCOMPLETE_VISITS', language),
            rates: item.rates,
            evidenceRecordId: evidenceRecordId,
          );
        }

      case 'IMMUNIZATION_FULL_1YR':
        final completedAntigens = List<String>.from(eventData['completed_antigens'] as List? ?? []);
        final requiredAntigens = List<String>.from(conditions['required_antigens'] as List? ?? ['BCG', 'OPV_3', 'PENTA_3', 'MR_1']);

        final satisfied = requiredAntigens.every((antigen) => completedAntigens.contains(antigen));
        if (satisfied) {
          return EligibilityCheckResult(
            activityCode: activityCode,
            isEligible: true,
            completionProgress: 1.0,
            completedCount: completedAntigens.length,
            requiredCount: requiredAntigens.length,
            rates: item.rates,
            evidenceRecordId: evidenceRecordId,
          );
        } else {
          final matchedCount = completedAntigens.where((a) => requiredAntigens.contains(a)).length;
          final progress = (matchedCount / requiredAntigens.length.toDouble()).clamp(0.0, 1.0);
          return EligibilityCheckResult(
            activityCode: activityCode,
            isEligible: false,
            isDeferred: true,
            completionProgress: progress,
            completedCount: matchedCount,
            requiredCount: requiredAntigens.length,
            ineligibilityReasonCode: 'PENDING_VACCINES',
            ineligibilityReasonText: item.getIneligibilityMessage('PENDING_VACCINES', language),
            rates: item.rates,
            evidenceRecordId: evidenceRecordId,
          );
        }

      case 'CBAC_SCREENING':
        final age = (eventData['age_years'] as num? ?? eventData['age'] as num?)?.toInt();
        final minAge = (conditions['min_age_years'] as num?)?.toInt() ?? 30;

        if (age != null && age < minAge) {
          const reason = 'AGE_UNDER_30';
          return EligibilityCheckResult(
            activityCode: activityCode,
            isEligible: false,
            completionProgress: 1.0,
            ineligibilityReasonCode: reason,
            ineligibilityReasonText: item.getIneligibilityMessage(reason, language),
            audioClipPath: item.getIneligibilityAudio(reason, language),
            rates: item.rates,
            evidenceRecordId: evidenceRecordId,
          );
        }
        return EligibilityCheckResult(
          activityCode: activityCode,
          isEligible: true,
          completionProgress: 1.0,
          rates: item.rates,
          evidenceRecordId: evidenceRecordId,
        );

      case 'TB_DOTS_SUPPORT':
        final status = (eventData['treatment_status'] as String?)?.toUpperCase();
        if (status == 'CURED_OR_COMPLETED' || status == 'CURED' || status == 'COMPLETED') {
          return EligibilityCheckResult(
            activityCode: activityCode,
            isEligible: true,
            completionProgress: 1.0,
            rates: item.rates,
            evidenceRecordId: evidenceRecordId,
          );
        } else {
          return EligibilityCheckResult(
            activityCode: activityCode,
            isEligible: false,
            isDeferred: true,
            completionProgress: 0.5,
            ineligibilityReasonCode: 'TREATMENT_IN_PROGRESS',
            ineligibilityReasonText: 'TB treatment is ongoing. Incentive claims after cure/completion.',
            rates: item.rates,
            evidenceRecordId: evidenceRecordId,
          );
        }

      default:
        // Generic rule validation
        return EligibilityCheckResult(
          activityCode: activityCode,
          isEligible: true,
          completionProgress: 1.0,
          rates: item.rates,
          evidenceRecordId: evidenceRecordId,
        );
    }
  }

  // ── Auto-Event Logging & Idempotent Persistence ────────────────────────────

  /// Automatically records an incentive event upon task completion (Req 54.1).
  ///
  /// Enforces:
  /// 1. Non-orphaned clinical record: verifies [memberId] and/or [encounterId] exist (Property 12).
  /// 2. Idempotent insertion: recording N times produces exactly one record (Property 10).
  /// 3. Effective catalogue version active at [eventDate] (Req 53.2, Property 11).
  /// 4. Sync queue enqueuing for offline-first sync.
  Future<IncentiveEvent> recordEvent({
    required String memberId,
    required String activityCode,
    required DateTime eventDate,
    String? encounterId,
    String? evidenceRecordId,
    Map<String, dynamic> eventData = const {},
    String stateCode = 'DEFAULT',
    String language = 'en',
  }) async {
    // 1. Invariant: Linked clinical record must exist (Property 12)
    final member = await (_db.select(_db.members)..where((t) => t.id.equals(memberId))).getSingleOrNull();
    if (member == null) {
      throw OrphanedIncentiveException(
        'Member with ID $memberId not found in local store. Orphaned incentive records are not permitted.',
      );
    }

    if (encounterId != null) {
      final encounter = await (_db.select(_db.clinicalEncounters)
            ..where((t) => t.id.equals(encounterId)))
          .getSingleOrNull();
      if (encounter == null) {
        throw OrphanedIncentiveException(
          'Clinical encounter with ID $encounterId not found. Orphaned incentive records are not permitted.',
        );
      }
    }

    // 2. Identify active catalogue version for eventDate (Property 11)
    final catalogue = getCatalogueForDate(eventDate, stateCode: stateCode);
    final versionId = catalogue?.versionId ?? 'CATALOGUE_DEFAULT';

    // 3. Evaluate eligibility
    final evalResult = evaluateEligibility(
      activityCode: activityCode,
      memberId: memberId,
      eventDate: eventDate,
      eventData: eventData,
      language: language,
      stateCode: stateCode,
      evidenceRecordId: evidenceRecordId ?? encounterId,
    );

    // Determine initial status
    final String initialStatus;
    if (evalResult.isEligible) {
      initialStatus = IncentiveStatus.eligible;
    } else if (evalResult.isDeferred) {
      initialStatus = IncentiveStatus.deferred;
    } else {
      initialStatus = IncentiveStatus.ineligible;
    }

    // 4. Deterministic idempotency key (Property 10)
    final idempotencyKey = generateIdempotencyKey(activityCode, memberId, eventDate);

    // Check if an event with this idempotency key already exists
    final existing = await (_db.select(_db.incentiveEvents)
          ..where((t) => t.idempotencyKey.equals(idempotencyKey)))
        .getSingleOrNull();

    if (existing != null) {
      // Idempotent: return existing record without creating duplicates
      return existing;
    }

    // 5. Insert new record
    final newId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    final companion = IncentiveEventsCompanion.insert(
      id: newId,
      memberId: memberId,
      encounterId: encounterId != null ? Value(encounterId) : const Value.absent(),
      activityCode: activityCode,
      catalogueVersionId: versionId,
      eventDate: eventDate.millisecondsSinceEpoch,
      status: Value(initialStatus),
      ineligibilityReason: evalResult.ineligibilityReasonText != null
          ? Value(evalResult.ineligibilityReasonText!)
          : const Value.absent(),
      evidenceRecordId: evalResult.evidenceRecordId != null
          ? Value(evalResult.evidenceRecordId!)
          : const Value.absent(),
      createdAt: now,
      idempotencyKey: idempotencyKey,
      syncStatus: const Value('pending'),
    );

    await _db.into(_db.incentiveEvents).insert(
          companion,
          mode: InsertMode.insertOrIgnore,
        );

    final inserted = await (_db.select(_db.incentiveEvents)
          ..where((t) => t.idempotencyKey.equals(idempotencyKey)))
        .getSingle();

    // 6. Enqueue sync payload
    if (_syncEngine != null) {
      await _syncEngine!.enqueue(
        table: 'incentive_events',
        recordId: inserted.id,
        operation: 'insert',
        priority: SyncPriority.clinical,
        payload: {
          'id': inserted.id,
          'member_id': inserted.memberId,
          'encounter_id': inserted.encounterId,
          'activity_code': inserted.activityCode,
          'catalogue_version_id': inserted.catalogueVersionId,
          'event_date': inserted.eventDate,
          'status': inserted.status,
          'ineligibility_reason': inserted.ineligibilityReason,
          'evidence_record_id': inserted.evidenceRecordId,
          'created_at': inserted.createdAt,
          'idempotency_key': inserted.idempotencyKey,
        },
      );
    }

    return inserted;
  }

  // ── Deferred Eligibility Resolution ────────────────────────────────────────

  /// Checks and transitions deferred incentive events to 'eligible' once conditions are met (Req 54.3).
  Future<List<IncentiveEvent>> checkAndResolveDeferredConditions({
    required String memberId,
    required String activityCode,
    required Map<String, dynamic> updatedContext,
    String stateCode = 'DEFAULT',
  }) async {
    // Find all deferred events for this member & activity
    final deferredEvents = await (_db.select(_db.incentiveEvents)
          ..where((t) =>
              t.memberId.equals(memberId) &
              t.activityCode.equals(activityCode) &
              t.status.equals(IncentiveStatus.deferred)))
        .get();

    final resolved = <IncentiveEvent>[];

    for (final event in deferredEvents) {
      final eval = evaluateEligibility(
        activityCode: activityCode,
        memberId: memberId,
        eventDate: DateTime.fromMillisecondsSinceEpoch(event.eventDate),
        eventData: updatedContext,
        stateCode: stateCode,
      );

      if (eval.isEligible) {
        // Transition to eligible
        final updatedCompanion = IncentiveEventsCompanion(
          status: const Value(IncentiveStatus.eligible),
          ineligibilityReason: const Value(null),
          syncStatus: const Value('pending'),
        );

        await (_db.update(_db.incentiveEvents)..where((t) => t.id.equals(event.id)))
            .write(updatedCompanion);

        final updatedEvent = await (_db.select(_db.incentiveEvents)
              ..where((t) => t.id.equals(event.id)))
            .getSingle();

        if (_syncEngine != null) {
          await _syncEngine!.enqueue(
            table: 'incentive_events',
            recordId: event.id,
            operation: 'update',
            priority: SyncPriority.clinical,
            payload: {
              'id': event.id,
              'status': IncentiveStatus.eligible,
              'ineligibility_reason': null,
            },
          );
        }

        resolved.add(updatedEvent);
      }
    }

    return resolved;
  }

  // ── External Confirmatory Event Hook ───────────────────────────────────────

  /// Attaches external facility or portal verification as evidence (Req 54.5).
  Future<IncentiveEvent> recordExternalConfirmation({
    required String memberId,
    required String activityCode,
    required String externalReferenceId,
    required DateTime confirmationDate,
    String stateCode = 'DEFAULT',
  }) async {
    final idempotencyKey =
        generateIdempotencyKey(activityCode, memberId, confirmationDate);

    final existing = await (_db.select(_db.incentiveEvents)
          ..where((t) => t.idempotencyKey.equals(idempotencyKey)))
        .getSingleOrNull();

    if (existing != null) {
      // Update with external confirmation evidence
      final companion = IncentiveEventsCompanion(
        status: const Value(IncentiveStatus.eligible),
        evidenceRecordId: Value(externalReferenceId),
        syncStatus: const Value('pending'),
      );
      await (_db.update(_db.incentiveEvents)..where((t) => t.id.equals(existing.id)))
          .write(companion);

      return (_db.select(_db.incentiveEvents)..where((t) => t.id.equals(existing.id)))
          .getSingle();
    } else {
      // Record new event verified by external facility
      return recordEvent(
        memberId: memberId,
        activityCode: activityCode,
        eventDate: confirmationDate,
        evidenceRecordId: externalReferenceId,
        stateCode: stateCode,
      );
    }
  }

  // ── Multilingual & Audio Information Provider ──────────────────────────────

  /// Provides localized descriptions, audio paths, and ineligibility explanations (Req 53.4, 54.4).
  Map<String, dynamic> getActivityInfo(
    String activityCode, {
    String language = 'en',
    DateTime? date,
    String stateCode = 'DEFAULT',
  }) {
    final effectiveDate = date ?? DateTime.now();
    final catalogue = getCatalogueForDate(effectiveDate, stateCode: stateCode);
    final item = catalogue?.getItem(activityCode);

    if (item == null) {
      return {
        'activity_code': activityCode,
        'title': activityCode,
        'description': '',
        'audio_clip': null,
        'rates': null,
        'total_amount': 0.0,
      };
    }

    return {
      'activity_code': item.activityCode,
      'title': item.activityName,
      'description': item.getDescription(language),
      'audio_clip': item.getAudioClip(language),
      'rates': item.rates.toJson(),
      'total_amount': item.rates.totalRate,
      'required_evidence_type': item.requiredEvidenceType,
      'submission_window_days': item.submissionWindowDays,
    };
  }
}
