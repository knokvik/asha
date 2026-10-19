import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import 'other_programs_models.dart';

class OtherProgramsService {
  final AppDatabase? _db;

  OtherProgramsService([this._db]);

  static const Map<String, String> mentalHealthHelplines = {
    'Tele-MANAS (MoHFW National Helpline)': '14416',
    'KIRAN (Mental Health Rehabilitation)': '1800-599-0019',
    'iCall Psychosocial Helpline': '9152987821',
    'Vandrevala Foundation Helpline': '9999666555',
    'NIMHANS Toll-Free Helpline': '080-46110007',
    'Emergency Ambulance': '108',
  };

  /// Evaluates validated PHQ-4 mental health screening aid (Requirement 22.3).
  MentalHealthScreeningResult evaluateMentalHealthScreening({
    required String memberId,
    required int feelingNervousAnxious, // 0 to 3
    required int notBeingAbleToStopWorrying, // 0 to 3
    required int littleInterestOrPleasure, // 0 to 3
    required int feelingDownDepressedHopeless, // 0 to 3
    bool hasSelfHarmThoughts = false,
  }) {
    final now = DateTime.now();
    final anxietyScore = feelingNervousAnxious + notBeingAbleToStopWorrying;
    final depressionScore = littleInterestOrPleasure + feelingDownDepressedHopeless;
    final totalScore = anxietyScore + depressionScore;

    String flag;
    String recommendation;

    if (hasSelfHarmThoughts || totalScore >= 9) {
      flag = 'RED';
      recommendation =
          'High risk / Crisis detected. Do NOT leave individual alone. Provide crisis helpline (Tele-MANAS 14416 / iCall) and facilitate urgent escorted referral to Medical Officer.';
    } else if (totalScore >= 6) {
      flag = 'YELLOW';
      recommendation =
          'Moderate psychological distress. Provide supportive listening, discuss stress management, and schedule review at next HWC clinic with CHO / MO.';
    } else if (totalScore >= 3) {
      flag = 'YELLOW';
      recommendation =
          'Mild symptoms. Share community coping techniques and re-screen during next routine home visit.';
    } else {
      flag = 'GREEN';
      recommendation =
          'Screening negative / within normal range. Offer standard mental well-being encouragement.';
    }

    return MentalHealthScreeningResult(
      id: 'mh_scr_${now.millisecondsSinceEpoch}',
      memberId: memberId,
      screenedAt: now,
      phq4Score: totalScore,
      anxietySubscore: anxietyScore,
      depressionSubscore: depressionScore,
      hasSelfHarmIdeation: hasSelfHarmThoughts,
      triageFlag: flag,
      recommendation: recommendation,
      helplineNumbers: mentalHealthHelplines,
    );
  }

  /// Records Adolescent health contact, WIFS distribution, and stock decrement (Requirement 22.1).
  Future<AdolescentRecord> recordAdolescentCare({
    required String memberId,
    required int ageYears,
    required String gender,
    required bool isInSchool,
    required bool receivedMenstrualHygieneCounselling,
    required int wifsTabletsDispensed,
    required int sanitaryNapkinPacksDispensed,
    required bool referredToAfhc,
    String? stockItemId,
  }) async {
    final now = DateTime.now();
    final recordId = 'adol_${memberId}_${now.millisecondsSinceEpoch}';

    final db = _db;
    if (db != null && stockItemId != null && wifsTabletsDispensed > 0) {
      // Decrement stock in stock_transactions
      await db.into(db.stockTransactions).insert(
            StockTransactionsCompanion.insert(
              id: 'st_wifs_${now.millisecondsSinceEpoch}',
              itemId: stockItemId,
              transactionType: 'dispense',
              quantityDelta: -wifsTabletsDispensed.toDouble(),
              recordedAt: now.millisecondsSinceEpoch,
              relatedMemberId: Value(memberId),
            ),
          );

      // Schedule next monthly WIFS check
      final nextMonth = now.add(const Duration(days: 28));
      await db.into(db.visitSchedules).insert(
            VisitSchedulesCompanion.insert(
              id: 'vs_wifs_${now.millisecondsSinceEpoch}',
              memberId: memberId,
              programCode: 'WIFS',
              visitType: 'adolescent_wifs_refill',
              dueDate: nextMonth.millisecondsSinceEpoch,
              createdAt: now.millisecondsSinceEpoch,
            ),
          );
    }

    return AdolescentRecord(
      id: recordId,
      memberId: memberId,
      ageYears: ageYears,
      gender: gender,
      isInSchool: isInSchool,
      receivedMenstrualHygieneCounselling: receivedMenstrualHygieneCounselling,
      wifsTabletsDispensed: wifsTabletsDispensed,
      sanitaryNapkinPacksDispensed: sanitaryNapkinPacksDispensed,
      referredToAfhc: referredToAfhc,
      recordedAt: now,
    );
  }

  /// Registers and schedules home-care visit for elderly / palliative patient (Requirement 22.2).
  Future<ElderlyPalliativeRecord> registerElderlyPalliativeFollowUp({
    required String memberId,
    required int ageYears,
    required String mobilityStatus,
    required List<String> chronicConditions,
    required int visitIntervalDays,
    required bool hasPressureUlcers,
    required String caregiverName,
  }) async {
    final now = DateTime.now();
    final nextDue = now.add(Duration(days: visitIntervalDays));
    final recordId = 'eld_${memberId}_${now.millisecondsSinceEpoch}';

    final db = _db;
    if (db != null) {
      await db.into(db.visitSchedules).insert(
            VisitSchedulesCompanion.insert(
              id: 'vs_eld_${now.millisecondsSinceEpoch}',
              memberId: memberId,
              programCode: 'PALLIATIVE',
              visitType: 'elderly_palliative_visit',
              dueDate: nextDue.millisecondsSinceEpoch,
              createdAt: now.millisecondsSinceEpoch,
            ),
          );
    }

    return ElderlyPalliativeRecord(
      id: recordId,
      memberId: memberId,
      ageYears: ageYears,
      mobilityStatus: mobilityStatus,
      chronicConditions: chronicConditions,
      visitIntervalDays: visitIntervalDays,
      lastVisitDate: now,
      nextDueDate: nextDue,
      hasPressureUlcers: hasPressureUlcers,
      caregiverName: caregiverName,
    );
  }

  /// Registers disability and identifies eligible government welfare schemes (Requirement 22.4).
  DisabilityRecord registerDisability({
    required String memberId,
    required String disabilityType,
    required int percentageSeverity,
    String? udidNumber,
  }) {
    final eligibleSchemes = <String>[];
    if (percentageSeverity >= 40) {
      eligibleSchemes.add('Unique Disability ID (UDID) Card & Certificate');
      eligibleSchemes.add('National Divyangjan Monthly Pension Scheme');
      eligibleSchemes.add('ADIP Scheme: Free Assistive Aids & Appliances');
      eligibleSchemes.add('Free State Road Transport Concession Pass');
      if (disabilityType.contains('intellectual') || disabilityType.contains('multiple')) {
        eligibleSchemes.add('Niramaya Comprehensive Health Insurance Scheme (Up to ₹1 Lakh)');
      }
    } else {
      eligibleSchemes.add('Early Intervention & Rehabilitation Services');
    }

    return DisabilityRecord(
      id: 'dis_${memberId}_${DateTime.now().millisecondsSinceEpoch}',
      memberId: memberId,
      disabilityType: disabilityType,
      percentageSeverity: percentageSeverity,
      udidNumber: udidNumber,
      linkedGovernmentSchemes: eligibleSchemes,
      registeredAt: DateTime.now(),
    );
  }

  /// Records community activity logs that roll up to the AF supervision dashboard (Requirement 22.6).
  CommunityActivityLog logCommunityActivity({
    required String activityType,
    required String hamletName,
    required int participantCount,
    required String topicCovered,
    required String notes,
  }) {
    return CommunityActivityLog(
      id: 'comm_act_${DateTime.now().millisecondsSinceEpoch}',
      activityType: activityType,
      activityDate: DateTime.now(),
      hamletName: hamletName,
      participantCount: participantCount,
      topicCovered: topicCovered,
      actionPointsOrNotes: notes,
      rolledUpToAfDashboard: true,
    );
  }

  /// Dynamically parses an OTA-pushed program module schema without requiring an APK release (Requirement 22.5).
  OtaProgramModule loadOtaProgramModule(Map<String, dynamic> moduleConfig) {
    return OtaProgramModule(
      moduleKey: moduleConfig['module_key'] as String? ?? 'custom_program',
      version: moduleConfig['version'] as String? ?? '1.0.0',
      programTitle: moduleConfig['program_title'] as String? ?? 'Untitled Health Program',
      formSchema: (moduleConfig['form_schema'] as Map<String, dynamic>?) ?? {},
      scheduleRules: (moduleConfig['schedule_rules'] as Map<String, dynamic>?) ?? {},
      isActive: moduleConfig['is_active'] as bool? ?? true,
    );
  }
}
