import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../shared/providers/core_providers.dart';
import 'due_list_models.dart';

/// Pure clinical task scheduler and visit management service (Requirements 24.1 – 24.7).
class TaskScheduler {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;
  final Uuid _uuid;

  TaskScheduler(this._db, [this._syncEngine, Uuid? uuid])
      : _uuid = uuid ?? const Uuid();

  /// 1. Fetches and prioritises all pending/overdue tasks (Requirements 24.1, 24.6).
  ///
  /// Ordering:
  /// 1. Urgency group (RED follow-ups → Overdue → Due today → Upcoming)
  /// 2. Urgency score descending = `clinical_risk_level × (1 / days_until_window_expiry)`
  /// 3. Hamlet alphabetically
  Future<List<DueTask>> fetchDueTasks({
    DateTime? referenceDate,
    String? hamletFilter,
    String? programFilter,
    int workloadThreshold = 8,
  }) async {
    final now = referenceDate ?? DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final dayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final dayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).millisecondsSinceEpoch;

    // Fetch unresolved RED referrals to identify urgent follow-ups
    final redReferralRows = await (_db.select(_db.referralRecords)
          ..where((t) => t.triageFlag.equals('red') & t.status.isNotValue('completed')))
        .get();
    final redMemberIds = redReferralRows.map((r) => r.memberId).toSet();

    // Query active visit schedules joined with Member and Household
    final query = _db.select(_db.visitSchedules).join([
      innerJoin(_db.members, _db.members.id.equalsExp(_db.visitSchedules.memberId)),
      innerJoin(_db.households, _db.households.id.equalsExp(_db.members.householdId)),
    ])
      ..where(_db.visitSchedules.status.isIn(['pending', 'overdue', 'rescheduled', 'due']))
      ..where(_db.members.lifecycleStatus.equals('active'));

    if (hamletFilter != null && hamletFilter.isNotEmpty && hamletFilter != 'All') {
      query.where(_db.households.hamlet.equals(hamletFilter));
    }
    if (programFilter != null && programFilter.isNotEmpty && programFilter != 'All') {
      query.where(_db.visitSchedules.programCode.equals(programFilter));
    }

    final rows = await query.get();
    final tasks = <DueTask>[];

    for (final row in rows) {
      final schedule = row.readTable(_db.visitSchedules);
      final member = row.readTable(_db.members);
      final household = row.readTable(_db.households);

      final hasRedAlert = redMemberIds.contains(member.id);

      // Determine days until window expiry (or due date)
      final expiryMs = schedule.dueWindowEnd ?? schedule.dueDate;
      final daysUntilWindowExpiry = (expiryMs - nowMs) / (24 * 60 * 60 * 1000);

      // Determine Urgency Group (Requirement 24.1)
      UrgencyGroup urgencyGroup;
      if (hasRedAlert) {
        urgencyGroup = UrgencyGroup.redFollowUp;
      } else if (schedule.dueDate < dayStart || (schedule.dueWindowEnd != null && schedule.dueWindowEnd! < dayStart)) {
        urgencyGroup = UrgencyGroup.overdue;
      } else if (schedule.dueDate <= dayEnd) {
        urgencyGroup = UrgencyGroup.dueToday;
      } else {
        urgencyGroup = UrgencyGroup.upcoming;
      }

      // Determine clinical risk level (1.0 routine, 2.0-2.5 moderate, 3.0 severe)
      double clinicalRiskLevel = 1.0;
      final lowerVisit = schedule.visitType.toLowerCase();
      if (hasRedAlert) {
        clinicalRiskLevel = 3.0;
      } else if (lowerVisit.contains('high-risk') ||
          lowerVisit.contains('kmc') ||
          lowerVisit.contains('pmsma') ||
          lowerVisit.contains('sam')) {
        clinicalRiskLevel = 3.0;
      } else if (lowerVisit.contains('mam') ||
          lowerVisit.contains('growth faltering') ||
          schedule.programCode == 'ncd') {
        clinicalRiskLevel = 2.0;
      }

      final urgencyScore = DueTask.calculateUrgencyScore(
        clinicalRiskLevel: clinicalRiskLevel,
        daysUntilWindowExpiry: daysUntilWindowExpiry,
        hasRedAlert: hasRedAlert,
      );

      final prioritisationReason = DueTask.generatePrioritisationReason(
        group: urgencyGroup,
        clinicalRiskLevel: clinicalRiskLevel,
        daysUntilWindowExpiry: daysUntilWindowExpiry,
        hasRedAlert: hasRedAlert,
      );

      // Format approx age text
      String? ageText;
      if (member.dobApprox != null) {
        final dob = DateTime.fromMillisecondsSinceEpoch(member.dobApprox!);
        final ageDays = now.difference(dob).inDays;
        if (ageDays < 60) {
          ageText = '$ageDays days';
        } else if (ageDays < 730) {
          ageText = '${(ageDays / 30.4).floor()} mos';
        } else {
          ageText = '${(ageDays / 365.25).floor()} yrs';
        }
      }

      tasks.add(
        DueTask(
          id: schedule.id,
          memberId: member.id,
          memberName: member.name,
          memberAgeText: ageText,
          sex: member.sex,
          householdId: household.id,
          village: household.village,
          hamlet: household.hamlet ?? household.village,
          programCode: schedule.programCode,
          visitType: schedule.visitType,
          dueDate: DateTime.fromMillisecondsSinceEpoch(schedule.dueDate),
          dueWindowStart: schedule.dueWindowStart != null
              ? DateTime.fromMillisecondsSinceEpoch(schedule.dueWindowStart!)
              : null,
          dueWindowEnd: schedule.dueWindowEnd != null
              ? DateTime.fromMillisecondsSinceEpoch(schedule.dueWindowEnd!)
              : null,
          status: schedule.status,
          urgencyGroup: urgencyGroup,
          clinicalRiskLevel: clinicalRiskLevel,
          daysUntilWindowExpiry: daysUntilWindowExpiry,
          urgencyScore: urgencyScore,
          prioritisationReason: prioritisationReason,
          hasRedAlert: hasRedAlert,
          rescheduledCount: schedule.rescheduledCount,
          skipReason: schedule.skipReason,
        ),
      );
    }

    // Sort order:
    // 1. UrgencyGroup sortOrder (RED -> Overdue -> Due Today -> Upcoming)
    // 2. UrgencyScore descending
    // 3. Hamlet alphabetically
    tasks.sort((a, b) {
      final groupCompare = a.urgencyGroup.sortOrder.compareTo(b.urgencyGroup.sortOrder);
      if (groupCompare != 0) return groupCompare;

      final scoreCompare = b.urgencyScore.compareTo(a.urgencyScore);
      if (scoreCompare != 0) return scoreCompare;

      return a.hamlet.compareTo(b.hamlet);
    });

    return tasks;
  }

  /// 2. Groups tasks by UrgencyGroup, then by Hamlet (Requirement 24.1).
  Future<Map<UrgencyGroup, Map<String, List<DueTask>>>> fetchGroupedDueList({
    DateTime? referenceDate,
    String? hamletFilter,
    String? programFilter,
    int workloadThreshold = 8,
  }) async {
    final allTasks = await fetchDueTasks(
      referenceDate: referenceDate,
      hamletFilter: hamletFilter,
      programFilter: programFilter,
      workloadThreshold: workloadThreshold,
    );

    final grouped = <UrgencyGroup, Map<String, List<DueTask>>>{
      UrgencyGroup.redFollowUp: {},
      UrgencyGroup.overdue: {},
      UrgencyGroup.dueToday: {},
      UrgencyGroup.upcoming: {},
    };

    for (final task in allTasks) {
      final groupMap = grouped[task.urgencyGroup]!;
      groupMap.putIfAbsent(task.hamlet, () => []).add(task);
    }

    return grouped;
  }

  /// 3. Workload threshold analysis (Requirement 24.6).
  Future<WorkloadSummary> fetchWorkloadSummary({
    DateTime? referenceDate,
    int workloadThreshold = 8,
  }) async {
    final tasks = await fetchDueTasks(referenceDate: referenceDate);
    final todayTasks = tasks.where((t) =>
        t.urgencyGroup == UrgencyGroup.redFollowUp ||
        t.urgencyGroup == UrgencyGroup.overdue ||
        t.urgencyGroup == UrgencyGroup.dueToday).toList();

    int red = 0;
    int overdue = 0;
    int dueToday = 0;
    int upcoming = 0;
    final hamletMap = <String, int>{};

    for (final t in tasks) {
      hamletMap[t.hamlet] = (hamletMap[t.hamlet] ?? 0) + 1;
      switch (t.urgencyGroup) {
        case UrgencyGroup.redFollowUp:
          red++;
          break;
        case UrgencyGroup.overdue:
          overdue++;
          break;
        case UrgencyGroup.dueToday:
          dueToday++;
          break;
        case UrgencyGroup.upcoming:
          upcoming++;
          break;
      }
    }

    return WorkloadSummary(
      totalTasksToday: todayTasks.length,
      reasonableThreshold: workloadThreshold,
      redCount: red,
      overdueCount: overdue,
      dueTodayCount: dueToday,
      upcomingCount: upcoming,
      tasksByHamlet: hamletMap,
    );
  }

  /// 4. Captures visit skip reason and reschedules within permitted window (Requirement 24.4).
  Future<bool> recordSkipAndReschedule({
    required String visitScheduleId,
    required SkipReason reason,
    String? notes,
    DateTime? customRescheduleDate,
  }) async {
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final schedule = await (_db.select(_db.visitSchedules)
          ..where((t) => t.id.equals(visitScheduleId)))
        .getSingleOrNull();

    if (schedule == null) return false;

    if (!reason.canReschedule) {
      // Reason permanently precludes visit (e.g. permanently migrated)
      await (_db.update(_db.visitSchedules)..where((t) => t.id.equals(visitScheduleId))).write(
        VisitSchedulesCompanion(
          status: const Value('skipped'),
          skipReason: Value('${reason.label}${notes != null ? ' - $notes' : ''}'),
        ),
      );

      if (_syncEngine != null) {
        await _syncEngine.enqueue(
          table: 'visit_schedules',
          recordId: visitScheduleId,
          operation: 'update',
          priority: SyncPriority.clinical,
          payload: {'id': visitScheduleId, 'status': 'skipped', 'skip_reason': reason.label},
        );
      }
      return true;
    }

    // Reschedule within protocol window:
    // If custom date provided, use it. Otherwise, add 2 days (48 hours), clamping to dueWindowEnd if valid.
    int newDueDateMs;
    int? newWindowEndMs = schedule.dueWindowEnd;

    if (customRescheduleDate != null) {
      newDueDateMs = customRescheduleDate.millisecondsSinceEpoch;
      if (newWindowEndMs != null && newDueDateMs > newWindowEndMs) {
        newWindowEndMs = newDueDateMs + (24 * 60 * 60 * 1000 * 3);
      }
    } else {
      const twoDaysMs = 2 * 24 * 60 * 60 * 1000;
      final proposed = nowMs + twoDaysMs;
      if (newWindowEndMs != null && proposed <= newWindowEndMs) {
        newDueDateMs = proposed;
      } else {
        // Window already lapsed or expiring immediately; extend window by 3 days for grace
        newDueDateMs = proposed;
        newWindowEndMs = proposed + (24 * 60 * 60 * 1000);
      }
    }

    await (_db.update(_db.visitSchedules)..where((t) => t.id.equals(visitScheduleId))).write(
      VisitSchedulesCompanion(
        dueDate: Value(newDueDateMs),
        dueWindowEnd: Value(newWindowEndMs),
        status: const Value('pending'),
        skipReason: Value('Rescheduled: ${reason.label}${notes != null ? ' ($notes)' : ''}'),
        rescheduledCount: Value(schedule.rescheduledCount + 1),
      ),
    );

    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'visit_schedules',
        recordId: visitScheduleId,
        operation: 'update',
        priority: SyncPriority.clinical,
        payload: {
          'id': visitScheduleId,
          'due_date': newDueDateMs,
          'due_window_end': newWindowEndMs,
          'status': 'pending',
          'rescheduled_count': schedule.rescheduledCount + 1,
          'skip_reason': reason.label,
        },
      );
    }

    return true;
  }

  /// 5. Creates ad hoc visit or unplanned task, merged at appropriate urgency (Requirement 24.7).
  Future<String> createAdHocTask({
    required String memberId,
    required String title,
    String programCode = 'ad_hoc',
    required DateTime dueDate,
    double clinicalRiskLevel = 1.0,
    String? notes,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final taskId = 'adhoc_${_uuid.v4()}';
    final dueMs = dueDate.millisecondsSinceEpoch;
    final windowStartMs = dueMs - (24 * 60 * 60 * 1000);
    final windowEndMs = dueMs + (24 * 60 * 60 * 1000 * 2);

    await _db.into(_db.visitSchedules).insert(
      VisitSchedulesCompanion.insert(
        id: taskId,
        memberId: memberId,
        programCode: programCode,
        visitType: title,
        dueDate: dueMs,
        dueWindowStart: Value(windowStartMs),
        dueWindowEnd: Value(windowEndMs),
        status: const Value('pending'),
        createdAt: nowMs,
      ),
    );

    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'visit_schedules',
        recordId: taskId,
        operation: 'insert',
        priority: SyncPriority.clinical,
        payload: {
          'id': taskId,
          'member_id': memberId,
          'program_code': programCode,
          'visit_type': title,
          'due_date': dueMs,
          'status': 'pending',
          'notes': notes,
        },
      );
    }

    return taskId;
  }

  /// 6. Completes task and removes it from active due list (Requirement 24.3).
  Future<void> completeTask({
    required String visitScheduleId,
    String? encounterId,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.visitSchedules)..where((t) => t.id.equals(visitScheduleId))).write(
      VisitSchedulesCompanion(
        status: const Value('completed'),
        completedAt: Value(nowMs),
        completedEncounterId: Value(encounterId),
      ),
    );

    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'visit_schedules',
        recordId: visitScheduleId,
        operation: 'update',
        priority: SyncPriority.clinical,
        payload: {
          'id': visitScheduleId,
          'status': 'completed',
          'completed_at': nowMs,
          'encounter_id': encounterId,
        },
      );
    }
  }

  /// 7. Month calendar view data (Requirement 24.5).
  /// Maps day-of-month (1..31) -> count of scheduled visits.
  Future<Map<int, int>> fetchMonthDailyCounts({
    required int year,
    required int month,
  }) async {
    final startMs = DateTime(year, month, 1).millisecondsSinceEpoch;
    final endMs = DateTime(year, month + 1, 0, 23, 59, 59, 999).millisecondsSinceEpoch;

    final schedules = await (_db.select(_db.visitSchedules)
          ..where((t) => t.dueDate.isBiggerOrEqualValue(startMs) & t.dueDate.isSmallerOrEqualValue(endMs)))
        .get();

    final counts = <int, int>{};
    for (final s in schedules) {
      final date = DateTime.fromMillisecondsSinceEpoch(s.dueDate);
      counts[date.day] = (counts[date.day] ?? 0) + 1;
    }
    return counts;
  }

  /// 8. Programme-level coverage summary (Requirement 24.5).
  Future<List<ProgramCoverage>> fetchProgramCoverageSummary() async {
    final allSchedules = await _db.select(_db.visitSchedules).get();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final programNames = {
      'anc': 'Antenatal Care (ANC)',
      'pnc': 'Postnatal Care (PNC)',
      'hbnc': 'Home Based Newborn Care (HBNC)',
      'hbyc': 'Home Based Care for Young Child (HBYC)',
      'immunization': 'Routine Immunization',
      'ncd': 'NCD & CBAC Screening',
      'nutrition': 'Child Nutrition & SAM/MAM',
      'tb': 'TB & Nikshay Follow-up',
      'vhsnd': 'VHSND Village Health Day',
      'ad_hoc': 'Ad-hoc Home Visits',
    };

    final stats = <String, Map<String, int>>{};

    for (final s in allSchedules) {
      final p = s.programCode;
      stats.putIfAbsent(p, () => {'total': 0, 'completed': 0, 'overdue': 0});
      stats[p]!['total'] = stats[p]!['total']! + 1;

      if (s.status == 'completed') {
        stats[p]!['completed'] = stats[p]!['completed']! + 1;
      } else if (s.dueDate < nowMs) {
        stats[p]!['overdue'] = stats[p]!['overdue']! + 1;
      }
    }

    final coverages = <ProgramCoverage>[];
    for (final entry in stats.entries) {
      final code = entry.key;
      final m = entry.value;
      coverages.add(
        ProgramCoverage(
          programCode: code,
          programName: programNames[code] ?? code.toUpperCase(),
          totalScheduled: m['total']!,
          completed: m['completed']!,
          overdue: m['overdue']!,
        ),
      );
    }

    // Sort with primary core programs first
    final order = [
      'anc',
      'pnc',
      'hbnc',
      'hbyc',
      'immunization',
      'ncd',
      'nutrition',
      'tb',
      'vhsnd',
      'ad_hoc'
    ];
    coverages.sort((a, b) {
      final idxA = order.indexOf(a.programCode);
      final idxB = order.indexOf(b.programCode);
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      if (idxA != -1) return -1;
      if (idxB != -1) return 1;
      return a.programName.compareTo(b.programName);
    });

    return coverages;
  }
}

/// Riverpod provider for TaskScheduler.
final taskSchedulerProvider = Provider<TaskScheduler>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final sync = ref.watch(syncEngineProvider);
  return TaskScheduler(db, sync);
});
