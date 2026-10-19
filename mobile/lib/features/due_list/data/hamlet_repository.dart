import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_engine.dart';
import '../domain/due_list_models.dart';
import '../domain/route_models.dart';

/// Repository managing hamlet physical accessibility flags, visit rescheduling adjustments,
/// and supervisor coverage analysis with ASHA consent checks (Requirements 25.4, 25.5).
class HamletRepository {
  final AppDatabase _db;
  final SyncEngine? _syncEngine;
  static const _uuid = Uuid();

  HamletRepository(this._db, [this._syncEngine]);

  // ── 1. Table Schema ──────────────────────────────────────────────────────────

  /// Ensures the SQLite table for tracking hamlet accessibility and physical barriers exists.
  Future<void> ensureHamletAccessibilityTableExists() async {
    await _db.customStatement('''
      CREATE TABLE IF NOT EXISTS hamlet_accessibility (
        id TEXT PRIMARY KEY,
        village TEXT NOT NULL,
        hamlet TEXT NOT NULL,
        is_blocked INTEGER NOT NULL,
        reason TEXT NOT NULL,
        notes TEXT,
        reported_at INTEGER NOT NULL,
        blocked_until INTEGER
      );
    ''');

    await _db.customStatement('''
      CREATE INDEX IF NOT EXISTS idx_hamlet_access_village
      ON hamlet_accessibility(village, hamlet);
    ''');
  }

  // ── 2. Flag Hamlet Accessibility & Adjust Schedule (Requirement 25.4) ────────

  /// Flags a hamlet as remote, seasonal, or physically unreachable, and adjusts open schedules.
  Future<HamletAccessibility> flagHamletBlocked({
    required String village,
    required String hamlet,
    required BarrierReason reason,
    String? notes,
    DateTime? blockedUntil,
  }) async {
    await ensureHamletAccessibilityTableExists();

    final now = DateTime.now();
    final id = _uuid.v4();
    final untilMs = blockedUntil?.millisecondsSinceEpoch;

    await _db.customStatement('''
      INSERT INTO hamlet_accessibility (id, village, hamlet, is_blocked, reason, notes, reported_at, blocked_until)
      VALUES (?, ?, ?, 1, ?, ?, ?, ?);
    ''', [id, village, hamlet, reason.code, notes, now.millisecondsSinceEpoch, untilMs]);

    final model = HamletAccessibility(
      id: id,
      village: village,
      hamlet: hamlet,
      isBlocked: true,
      reason: reason,
      notes: notes,
      reportedAt: now,
      blockedUntil: blockedUntil,
    );

    // Enqueue to sync queue for supervisor visibility
    if (_syncEngine != null) {
      await _syncEngine.enqueue(
        table: 'hamlet_accessibility',
        recordId: id,
        operation: 'insert',
        priority: SyncPriority.metadata,
        payload: model.toJson(),
      );
    }

    // Automatically adjust scheduling for affected households (Requirement 25.4)
    await _adjustSchedulesForBlockedHamlet(
      village: village,
      hamlet: hamlet,
      reason: reason,
      blockedUntil: blockedUntil,
    );

    return model;
  }

  /// Removes the blocked flag for a hamlet once access is restored.
  Future<void> clearHamletBlockage({
    required String village,
    required String hamlet,
  }) async {
    await ensureHamletAccessibilityTableExists();

    final now = DateTime.now();
    final id = _uuid.v4();

    await _db.customStatement('''
      INSERT INTO hamlet_accessibility (id, village, hamlet, is_blocked, reason, notes, reported_at, blocked_until)
      VALUES (?, ?, ?, 0, 'other', 'Access restored', ?, NULL);
    ''', [id, village, hamlet, now.millisecondsSinceEpoch]);
  }

  /// Adjusts open visit schedules in the blocked hamlet by deferring dueDate or setting skip reason.
  Future<int> _adjustSchedulesForBlockedHamlet({
    required String village,
    required String hamlet,
    required BarrierReason reason,
    DateTime? blockedUntil,
  }) async {
    // 1. Find all households in this hamlet
    final households = await (_db.select(_db.households)
          ..where((h) => h.village.equals(village) & h.hamlet.equals(hamlet)))
        .get();

    if (households.isEmpty) return 0;
    final householdIds = households.map((h) => h.id).toList();

    // 2. Find all members in these households
    final members = await (_db.select(_db.members)
          ..where((m) => m.householdId.isIn(householdIds)))
        .get();

    if (members.isEmpty) return 0;
    final memberIds = members.map((m) => m.id).toList();

    // 3. Find open visit schedules for these members
    final openSchedules = await (_db.select(_db.visitSchedules)
          ..where((s) => s.memberId.isIn(memberIds) & s.completedAt.isNull() & s.skipReason.isNull()))
        .get();

    final deferralDateMs = blockedUntil != null
        ? blockedUntil.add(const Duration(days: 1)).millisecondsSinceEpoch
        : DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch;

    final skipCode = reason == BarrierReason.flood || reason == BarrierReason.extremeWeather
        ? SkipReason.weatherRoadIssue.code
        : SkipReason.accessProblem.code;

    int adjustedCount = 0;
    for (final schedule in openSchedules) {
      await (_db.update(_db.visitSchedules)..where((s) => s.id.equals(schedule.id))).write(
        VisitSchedulesCompanion(
          dueDate: Value(deferralDateMs),
          rescheduledCount: Value(schedule.rescheduledCount + 1),
          skipReason: Value(skipCode),
          status: const Value('rescheduled'),
        ),
      );
      adjustedCount++;
    }

    return adjustedCount;
  }

  /// Retrieves the latest accessibility status map for all hamlets in a village.
  Future<Map<String, HamletAccessibility>> getAccessibilityMap(String village) async {
    await ensureHamletAccessibilityTableExists();

    final rows = await _db.customSelect(
      '''
      SELECT h1.* FROM hamlet_accessibility h1
      JOIN (
        SELECT hamlet, MAX(reported_at) as max_reported
        FROM hamlet_accessibility
        WHERE village = ?
        GROUP BY hamlet
      ) h2 ON h1.hamlet = h2.hamlet AND h1.reported_at = h2.max_reported
      WHERE h1.village = ?;
      ''',
      variables: [Variable.withString(village), Variable.withString(village)],
    ).get();

    final result = <String, HamletAccessibility>{};
    for (final r in rows) {
      final isBlockedInt = r.read<int>('is_blocked');
      final blockedUntilMs = r.readNullable<int>('blocked_until');
      final model = HamletAccessibility(
        id: r.read<String>('id'),
        village: r.read<String>('village'),
        hamlet: r.read<String>('hamlet'),
        isBlocked: isBlockedInt == 1,
        reason: BarrierReason.fromCode(r.read<String>('reason')),
        notes: r.readNullable<String>('notes'),
        reportedAt: DateTime.fromMillisecondsSinceEpoch(r.read<int>('reported_at')),
        blockedUntil: blockedUntilMs != null ? DateTime.fromMillisecondsSinceEpoch(blockedUntilMs) : null,
      );
      result[model.hamlet] = model;
    }

    return result;
  }

  // ── 3. Supervisor Coverage Analysis with ASHA Consent (Requirement 25.5) ──────

  /// Generates aggregate, area-level hamlet visit frequency and access barrier analysis.
  ///
  /// Privacy & Autonomy Guard (Req 25.5):
  /// - Only produces worker-specific workload analysis IF [ashaConsentGiven] is true.
  Future<CoverageAnalysisReport> generateCoverageAnalysis({
    required String village,
    required bool ashaConsentGiven,
  }) async {
    if (!ashaConsentGiven) {
      // Consent not granted: produce sanitized summary with no granular worker patterns
      return CoverageAnalysisReport(
        village: village,
        totalHamlets: 0,
        accessibleHamlets: 0,
        seasonallyBlockedHamlets: 0,
        ashaConsentGiven: false,
        hamletVisitFrequencies: const {},
        hamletCompletionRates: const {},
        accessBarriersHistory: const ['Consent not granted by ASHA for workload tracking.'],
        workloadRebalanceSuggestions: const [
          'Workload rebalancing requires explicit ASHA consent under Requirement 25.5.',
        ],
      );
    }

    await ensureHamletAccessibilityTableExists();

    // 1. Collect all hamlets in the village
    final households = await (_db.select(_db.households)..where((h) => h.village.equals(village))).get();
    final hamlets = households.map((h) => h.hamlet ?? 'Main Village').toSet().toList();

    // 2. Fetch accessibility map
    final accessMap = await getAccessibilityMap(village);
    int blockedCount = 0;
    final barriersHistory = <String>[];

    for (final entry in accessMap.entries) {
      if (entry.value.isBlocked) {
        blockedCount++;
        barriersHistory.add('${entry.key}: Blocked due to ${entry.value.reason.label}');
      }
    }

    // 3. Compute visit frequency and completion rate per hamlet
    final visitFrequencies = <String, int>{};
    final completionRates = <String, double>{};
    final rebalanceSuggestions = <String>[];

    for (final hamlet in hamlets) {
      final hIds = households.where((h) => (h.hamlet ?? 'Main Village') == hamlet).map((h) => h.id).toList();
      final mList = await (_db.select(_db.members)..where((m) => m.householdId.isIn(hIds))).get();
      final mIds = mList.map((m) => m.id).toList();

      final totalSchedules = await (_db.select(_db.visitSchedules)..where((s) => s.memberId.isIn(mIds))).get();
      final completedSchedules = totalSchedules.where((s) => s.completedAt != null).length;

      visitFrequencies[hamlet] = totalSchedules.length;
      final rate = totalSchedules.isNotEmpty
          ? (completedSchedules / totalSchedules.length) * 100.0
          : 100.0;
      completionRates[hamlet] = double.parse(rate.toStringAsFixed(1));

      // Workload rebalancing heuristics
      if (accessMap[hamlet]?.isBlocked ?? false) {
        rebalanceSuggestions.add(
          '$hamlet is seasonally blocked (${accessMap[hamlet]!.reason.label}). Recommend temporary mobile health camp or subcentre co-mobilisation.',
        );
      } else if (rate < 60.0 && totalSchedules.length > 5) {
        rebalanceSuggestions.add(
          '$hamlet has low visit completion ($rate%). Consider pairing with secondary ASHA or adjusting travel allowance.',
        );
      }
    }

    return CoverageAnalysisReport(
      village: village,
      totalHamlets: hamlets.length,
      accessibleHamlets: hamlets.length - blockedCount,
      seasonallyBlockedHamlets: blockedCount,
      ashaConsentGiven: true,
      hamletVisitFrequencies: visitFrequencies,
      hamletCompletionRates: completionRates,
      accessBarriersHistory: barriersHistory,
      workloadRebalanceSuggestions: rebalanceSuggestions,
    );
  }
}
