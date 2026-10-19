import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../shared/providers/core_providers.dart';

/// Supported timeline event categories.
enum TimelineEventType {
  encounter,
  triage,
  referral,
  immunization,
  incentive,
  visitSchedule,
}

/// A single clinical or administrative event in a beneficiary's longitudinal history.
class TimelineEventItem {
  final String id;
  final TimelineEventType type;
  final String title;
  final String subtitle;
  final int timestamp;
  final String? badgeText;
  final Color? badgeColor;
  final IconData icon;
  final Map<String, dynamic> metadata;

  const TimelineEventItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.badgeText,
    this.badgeColor,
    required this.icon,
    this.metadata = const {},
  });
}

/// Repository assembling a live, reverse-chronological stream of events for a beneficiary.
///
/// Combines:
/// - Clinical encounters (anc, pnc, hbnc, hbyc, ncd, tb)
/// - Facility referrals with triage flags
/// - Claimable incentive events
/// - Completed and due visit schedules
///
/// Requirements: 4.4
class TimelineRepository {
  final AppDatabase db;

  TimelineRepository(this.db);

  /// Emits a live, reverse-chronological list of all events for [memberId].
  Stream<List<TimelineEventItem>> watchTimeline(String memberId) async* {
    yield await getTimeline(memberId);

    final updates = db.tableUpdates(
      TableUpdateQuery.onAllTables([
        db.clinicalEncounters,
        db.referralRecords,
        db.incentiveEvents,
        db.visitSchedules,
      ]),
    );

    await for (final _ in updates) {
      yield await getTimeline(memberId);
    }
  }

  /// One-shot fetch of beneficiary timeline events.
  Future<List<TimelineEventItem>> getTimeline(String memberId) async {
    final encounters = await (db.select(db.clinicalEncounters)
          ..where((t) => t.memberId.equals(memberId)))
        .get();
    final referrals = await (db.select(db.referralRecords)
          ..where((t) => t.memberId.equals(memberId)))
        .get();
    final incentives = await (db.select(db.incentiveEvents)
          ..where((t) => t.memberId.equals(memberId)))
        .get();
    final schedules = await (db.select(db.visitSchedules)
          ..where((t) => t.memberId.equals(memberId)))
        .get();

    final events = <TimelineEventItem>[
      ...encounters.map(_mapEncounter),
      ...referrals.map(_mapReferral),
      ...incentives.map(_mapIncentive),
      ...schedules.map(_mapSchedule),
    ];

    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  TimelineEventItem _mapEncounter(ClinicalEncounter e) {
    final isImmunization = e.programCode.toLowerCase() == 'immunization' ||
        e.encounterType.toLowerCase().contains('vaccin');

    return TimelineEventItem(
      id: e.id,
      type: isImmunization
          ? TimelineEventType.immunization
          : TimelineEventType.encounter,
      title: '${e.programCode.toUpperCase()} Encounter: ${e.encounterType}',
      subtitle: e.visitNotes?.isNotEmpty == true
          ? e.visitNotes!
          : 'Clinical observations recorded by ASHA',
      timestamp: e.encounterDate,
      badgeText: e.status.toUpperCase(),
      badgeColor: e.status == 'completed' ? Colors.green : Colors.blue,
      icon: isImmunization ? Icons.vaccines : Icons.medical_services,
      metadata: {
        'program': e.programCode,
        'status': e.status,
      },
    );
  }

  TimelineEventItem _mapReferral(ReferralRecord r) {
    final flagUpper = r.triageFlag.toUpperCase();
    final isRed = flagUpper == 'RED';

    String title = 'Facility Referral ($flagUpper FLAG)';
    String badge = '$flagUpper REFERRAL';
    if (r.outcome != null) {
      badge = 'OUTCOME: ${r.outcome!.toUpperCase()}';
      title = 'Facility Referral ($flagUpper) — Outcome: ${r.outcome!.toUpperCase()}';
    }

    return TimelineEventItem(
      id: r.id,
      type: TimelineEventType.referral,
      title: title,
      subtitle: r.referralNoteText?.isNotEmpty == true
          ? r.referralNoteText!
          : 'Referred to ${r.destinationLevel ?? "Health Facility"}',
      timestamp: r.outcomeRecordedAt ?? r.createdAt,
      badgeText: badge,
      badgeColor: isRed ? Colors.red : Colors.orange,
      icon: Icons.emergency,
      metadata: {
        'triageFlag': r.triageFlag,
        'status': r.status,
        'outcome': r.outcome,
        'destinationLevel': r.destinationLevel,
      },
    );
  }

  TimelineEventItem _mapIncentive(IncentiveEvent i) {
    return TimelineEventItem(
      id: i.id,
      type: TimelineEventType.incentive,
      title: 'Incentive Event: ${i.activityCode}',
      subtitle: 'Catalogue version ${i.catalogueVersionId}',
      timestamp: i.eventDate,
      badgeText: i.status == 'eligible' ? '₹ CLAIMABLE' : i.status.toUpperCase(),
      badgeColor: Colors.amber.shade800,
      icon: Icons.monetization_on,
      metadata: {
        'activityCode': i.activityCode,
        'status': i.status,
      },
    );
  }

  TimelineEventItem _mapSchedule(VisitSchedule s) {
    final isCompleted = s.status == 'completed';

    return TimelineEventItem(
      id: s.id,
      type: TimelineEventType.visitSchedule,
      title: 'Scheduled Visit: ${s.visitType}',
      subtitle: 'Program: ${s.programCode.toUpperCase()}',
      timestamp: s.completedAt ?? s.dueDate,
      badgeText: s.status.toUpperCase(),
      badgeColor: isCompleted ? Colors.teal : Colors.blueGrey,
      icon: Icons.event_available,
      metadata: {
        'programCode': s.programCode,
        'status': s.status,
      },
    );
  }
}

// ── Riverpod Providers ────────────────────────────────────────────────────────

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TimelineRepository(db);
});

final beneficiaryTimelineStreamProvider = StreamProvider.autoDispose
    .family<List<TimelineEventItem>, String>((ref, memberId) {
  final repo = ref.watch(timelineRepositoryProvider);
  return repo.watchTimeline(memberId);
});
