import 'dart:math' as math;

/// Defined skip reasons for scheduled visits (Requirement 24.4).
enum SkipReason {
  notAtHome('not_at_home', 'Beneficiary not at home / temporarily away'),
  refused('refused', 'Beneficiary or family refused visit'),
  migrated('migrated', 'Temporarily migrated / out of village'),
  permanentlyMigrated('permanently_migrated', 'Permanently migrated / married out'),
  ashaUnwell('asha_unwell', 'ASHA worker unwell / personal emergency'),
  accessProblem('access_problem', 'Physical access barrier / blocked path'),
  weatherRoadIssue('weather_road', 'Severe weather, flood or road impassable'),
  other('other', 'Other operational constraint');

  final String code;
  final String label;
  const SkipReason(this.code, this.label);

  /// Whether the protocol permits rescheduling for this reason.
  bool get canReschedule =>
      this != SkipReason.permanentlyMigrated && this != SkipReason.refused;

  static SkipReason fromCode(String? code) {
    if (code == null) return SkipReason.other;
    return SkipReason.values.firstWhere(
      (e) => e.code == code,
      orElse: () => SkipReason.other,
    );
  }
}

/// Urgency grouping order (Requirement 24.1):
/// RED follow-ups → Overdue items → Due today → Upcoming.
enum UrgencyGroup {
  redFollowUp(0, 'RED Alert & Emergency Follow-ups', 0xFFD32F2F),
  overdue(1, 'Overdue Visits', 0xFFE65100),
  dueToday(2, 'Due Today', 0xFF00695C),
  upcoming(3, 'Upcoming Visits (Next 7 Days)', 0xFF1565C0);

  final int sortOrder;
  final String label;
  final int colorValue;
  const UrgencyGroup(this.sortOrder, this.label, this.colorValue);
}

/// Unified task item representing a scheduled or ad-hoc beneficiary visit.
class DueTask {
  final String id;
  final String memberId;
  final String memberName;
  final String? memberAgeText;
  final String sex;
  final String householdId;
  final String village;
  final String hamlet;
  final String programCode; // hbnc, hbyc, anc, pnc, immunization, ad_hoc
  final String visitType;
  final DateTime dueDate;
  final DateTime? dueWindowStart;
  final DateTime? dueWindowEnd;
  final String status; // pending, completed, overdue, skipped, rescheduled
  final UrgencyGroup urgencyGroup;
  final double clinicalRiskLevel; // 1.0 (Green), 2.0 (Yellow), 3.0 (Red / High-Risk)
  final double daysUntilWindowExpiry;
  final double urgencyScore;
  final String prioritisationReason;
  final bool hasRedAlert;
  final int rescheduledCount;
  final String? skipReason;
  final String? adHocNotes;

  const DueTask({
    required this.id,
    required this.memberId,
    required this.memberName,
    this.memberAgeText,
    required this.sex,
    required this.householdId,
    required this.village,
    required this.hamlet,
    required this.programCode,
    required this.visitType,
    required this.dueDate,
    this.dueWindowStart,
    this.dueWindowEnd,
    required this.status,
    required this.urgencyGroup,
    required this.clinicalRiskLevel,
    required this.daysUntilWindowExpiry,
    required this.urgencyScore,
    required this.prioritisationReason,
    this.hasRedAlert = false,
    this.rescheduledCount = 0,
    this.skipReason,
    this.adHocNotes,
  });

  /// Evaluates the urgency score according to Requirement 24.6:
  /// urgency score = clinical_risk_level × (1 / days_until_window_expiry).
  static double calculateUrgencyScore({
    required double clinicalRiskLevel,
    required double daysUntilWindowExpiry,
    required bool hasRedAlert,
  }) {
    if (hasRedAlert) {
      // Highest priority multiplier for active RED triage
      return 100.0 * clinicalRiskLevel + (daysUntilWindowExpiry <= 0 ? 50.0 : (1.0 / (daysUntilWindowExpiry + 0.1)));
    }
    if (daysUntilWindowExpiry <= 0) {
      // Overdue: urgency scales with clinical risk and days overdue
      final daysLapsed = daysUntilWindowExpiry.abs();
      return clinicalRiskLevel * (10.0 + daysLapsed);
    }
    final effectiveDays = math.max(0.1, daysUntilWindowExpiry);
    return clinicalRiskLevel * (1.0 / effectiveDays);
  }

  /// Generates human-readable prioritisation rationale for display (Requirement 24.6).
  static String generatePrioritisationReason({
    required UrgencyGroup group,
    required double clinicalRiskLevel,
    required double daysUntilWindowExpiry,
    required bool hasRedAlert,
  }) {
    if (hasRedAlert) {
      return 'RED ALERT: Patient has critical danger sign needing immediate follow-up';
    }
    if (group == UrgencyGroup.overdue) {
      final days = daysUntilWindowExpiry.abs().toInt();
      return 'OVERDUE: Visit window lapsed by $days day${days == 1 ? '' : 's'} (Risk Level: ${clinicalRiskLevel >= 3.0 ? 'High' : 'Standard'})';
    }
    if (daysUntilWindowExpiry <= 1.0) {
      return 'EXPIRING SOON: Care window closes within 24 hours (Risk Level: ${clinicalRiskLevel >= 3.0 ? 'High' : 'Standard'})';
    }
    if (clinicalRiskLevel >= 3.0) {
      return 'HIGH CLINICAL RISK: Priority follow-up (LBW / High-risk pregnancy / Severe illness)';
    }
    if (clinicalRiskLevel >= 2.0) {
      return 'MODERATE RISK: Scheduled monitoring (MAM / Borderline vitals)';
    }
    return 'ROUTINE: Scheduled standard program visit';
  }
}

/// Workload tracking summary for configurable threshold alerts (Requirement 24.6).
class WorkloadSummary {
  final int totalTasksToday;
  final int reasonableThreshold; // Default: 8 visits/day
  final int redCount;
  final int overdueCount;
  final int dueTodayCount;
  final int upcomingCount;
  final Map<String, int> tasksByHamlet;

  const WorkloadSummary({
    required this.totalTasksToday,
    this.reasonableThreshold = 8,
    required this.redCount,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.upcomingCount,
    required this.tasksByHamlet,
  });

  bool get isOverloaded => totalTasksToday > reasonableThreshold;
  int get excessTaskCount => math.max(0, totalTasksToday - reasonableThreshold);
}

/// Program-level coverage summary for supervisor and ASHA review (Requirement 24.5).
class ProgramCoverage {
  final String programCode;
  final String programName;
  final int totalScheduled;
  final int completed;
  final int overdue;

  const ProgramCoverage({
    required this.programCode,
    required this.programName,
    required this.totalScheduled,
    required this.completed,
    required this.overdue,
  });

  double get coveragePercentage =>
      totalScheduled == 0 ? 100.0 : ((completed / totalScheduled) * 100.0).clamp(0.0, 100.0);
}
