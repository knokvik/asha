import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import 'family_planning_models.dart';

class FamilyPlanningService {
  final AppDatabase _db;

  FamilyPlanningService(this._db);

  /// Evaluates unmet family planning need for an eligible couple (Requirement 18.1).
  UnmetNeedType classifyUnmetNeed({
    required int parity,
    required int youngestChildAgeMonths,
    required bool wantsMoreChildren,
    required ContraceptiveMethod currentMethod,
  }) {
    // If using a reliable modern method, no unmet need
    if (currentMethod != ContraceptiveMethod.none &&
        currentMethod != ContraceptiveMethod.traditional) {
      return UnmetNeedType.none;
    }

    if (!wantsMoreChildren) {
      return UnmetNeedType.limiting;
    } else if (youngestChildAgeMonths < 24) {
      return UnmetNeedType.spacing;
    }

    return UnmetNeedType.spacing;
  }

  /// Returns education and method-comparison cards with pictorial and audio metadata (Requirement 18.2).
  List<ContraceptiveEducationCard> getMethodEducationCards() {
    return const [
      ContraceptiveEducationCard(
        method: ContraceptiveMethod.condoms,
        title: 'Condoms (Nirodh)',
        effectivenessPercentage: 98.0,
        eligibilityCriteria: 'Any couple. Dual protection against unintended pregnancy and STIs/HIV.',
        commonSideEffects: 'No hormonal side effects. Rare latex allergy.',
        audioPrompt: 'audio_counsel_condom_hi',
        pictorialKey: 'asset_fp_condom',
        isAshaDistributable: true,
      ),
      ContraceptiveEducationCard(
        method: ContraceptiveMethod.chhaya,
        title: 'Centchroman (Chhaya)',
        effectivenessPercentage: 99.0,
        eligibilityCriteria: 'Non-hormonal pill. Twice a week for first 3 months, then once a week.',
        commonSideEffects: 'Cycles may be delayed; safe for breastfeeding mothers after 6 months.',
        audioPrompt: 'audio_counsel_chhaya_hi',
        pictorialKey: 'asset_fp_chhaya',
        isAshaDistributable: true,
      ),
      ContraceptiveEducationCard(
        method: ContraceptiveMethod.malaN,
        title: 'Oral Contraceptive Pills (Mala-N)',
        effectivenessPercentage: 99.0,
        eligibilityCriteria: 'One pill daily without break. Not for lactating mothers < 6 months postpartum.',
        commonSideEffects: 'Mild nausea, spotting in first few months.',
        audioPrompt: 'audio_counsel_malan_hi',
        pictorialKey: 'asset_fp_malan',
        isAshaDistributable: true,
      ),
      ContraceptiveEducationCard(
        method: ContraceptiveMethod.antara,
        title: 'Injectable DMPA (Antara)',
        effectivenessPercentage: 99.7,
        eligibilityCriteria: 'Intramuscular / subcutaneous injection every 3 months. Safe during lactation after 6 weeks.',
        commonSideEffects: 'Amenorrhea or irregular spotting; reversible upon stopping.',
        audioPrompt: 'audio_counsel_antara_hi',
        pictorialKey: 'asset_fp_antara',
        isAshaDistributable: false,
      ),
      ContraceptiveEducationCard(
        method: ContraceptiveMethod.iucd380A,
        title: 'Copper-T (IUCD 380A)',
        effectivenessPercentage: 99.2,
        eligibilityCriteria: 'Long-acting reversible protection for up to 10 years. Insertion by trained ANM/MO.',
        commonSideEffects: 'Mild abdominal cramps and heavier initial menstrual flow.',
        audioPrompt: 'audio_counsel_iucd_hi',
        pictorialKey: 'asset_fp_iucd',
        isAshaDistributable: false,
      ),
    ];
  }

  /// Evaluates reported side effects or method complications (Requirement 18.4).
  FamilyPlanningSideEffectEvaluation evaluateSideEffects({
    required ContraceptiveMethod method,
    required List<String> symptoms,
  }) {
    final lowerSymptoms = symptoms.map((s) => s.toLowerCase()).toList();

    // Red flag symptoms requiring emergency or urgent referral
    final redTriggers = [
      'severe abdominal pain',
      'severe pelvic pain',
      'high fever',
      'foul discharge',
      'heavy continuous bleeding',
      'missing threads with cramps',
      'severe chest pain',
      'acute leg swelling',
    ];

    final hasRedFlag = lowerSymptoms.any((sym) =>
        redTriggers.any((trigger) => sym.contains(trigger)));

    if (hasRedFlag) {
      return FamilyPlanningSideEffectEvaluation(
        method: method,
        reportedSymptoms: symptoms,
        requiresImmediateReferral: true,
        triageFlag: 'RED',
        counsellingGuidance:
            'Critical danger sign detected. Immediately refer to PHC / CHC. Do NOT attempt removal in field.',
        recommendedFacility: 'Primary Health Centre (PHC) / Community Health Centre (CHC)',
      );
    }

    // Moderate/expected side effects
    final isYellow = lowerSymptoms.any((s) =>
        s.contains('spotting') ||
        s.contains('nausea') ||
        s.contains('irregular period') ||
        s.contains('headache'));

    if (isYellow) {
      return FamilyPlanningSideEffectEvaluation(
        method: method,
        reportedSymptoms: symptoms,
        requiresImmediateReferral: false,
        triageFlag: 'YELLOW',
        counsellingGuidance:
            'Reassure client that spotting and mild nausea are common during the first 2-3 cycles. Consult ANM at next VHSND if discomfort continues.',
        recommendedFacility: 'Health & Wellness Centre / Sub-Centre (ANM)',
      );
    }

    return FamilyPlanningSideEffectEvaluation(
      method: method,
      reportedSymptoms: symptoms,
      requiresImmediateReferral: false,
      triageFlag: 'GREEN',
      counsellingGuidance: 'Routine adaptation. Encourage continuous adherence per guidelines.',
      recommendedFacility: 'Sub-Centre / ASHA Follow-up',
    );
  }

  /// Records contraceptive dispensing, updates stock transaction, and schedules refill task (Requirements 18.3, 30).
  Future<ContraceptiveDistributionRecord> recordDistribution({
    required String memberId,
    required String coupleId,
    required ContraceptiveMethod method,
    required int quantity,
    required String ashaWorkerId,
    required String stockItemId,
    required String batchNumber,
  }) async {
    final now = DateTime.now();
    final recordId = 'fp_dist_${now.millisecondsSinceEpoch}';

    // Calculate next refill date (e.g. 1 packet OCP = 28 days; Condoms 30 pcs = 30 days)
    final refillDays = (method == ContraceptiveMethod.malaN)
        ? quantity * 28
        : (method == ContraceptiveMethod.chhaya)
            ? quantity * 30
            : 30;
    final nextRefill = now.add(Duration(days: refillDays));

    // 1. Record stock decrement in stock_transactions
    await _db.into(_db.stockTransactions).insert(
          StockTransactionsCompanion.insert(
            id: 'st_fp_${now.millisecondsSinceEpoch}',
            itemId: stockItemId,
            transactionType: 'dispense',
            quantityDelta: -quantity.toDouble(),
            recordedAt: now.millisecondsSinceEpoch,
            relatedMemberId: Value(memberId),
          ),
        );

    // 2. Schedule next-refill due task in visit_schedules
    await _db.into(_db.visitSchedules).insert(
          VisitSchedulesCompanion.insert(
            id: 'vs_fp_${now.millisecondsSinceEpoch}',
            memberId: memberId,
            programCode: 'FP',
            visitType: 'family_planning_refill',
            dueDate: nextRefill.millisecondsSinceEpoch,
            createdAt: now.millisecondsSinceEpoch,
          ),
        );

    return ContraceptiveDistributionRecord(
      id: recordId,
      memberId: memberId,
      coupleId: coupleId,
      method: method,
      quantity: quantity,
      distributionDate: now,
      nextRefillDate: nextRefill,
      stockItemId: stockItemId,
      batchNumber: batchNumber,
    );
  }

  /// Generates an incentive-eligible event record for clinical family planning procedures (Requirements 18.6, 54).
  Future<String> recordFpIncentiveEvent({
    required String memberId,
    required ContraceptiveMethod method,
    required String ashaWorkerId,
    required String facilityName,
  }) async {
    final now = DateTime.now();
    String activityCode;
    switch (method) {
      case ContraceptiveMethod.ppiucd:
        activityCode = 'FP_PPIUCD';
        break;
      case ContraceptiveMethod.iucd380A:
      case ContraceptiveMethod.iucd375:
        activityCode = 'FP_IUCD_INTERVAL';
        break;
      case ContraceptiveMethod.antara:
        activityCode = 'FP_ANTARA_INJECTION';
        break;
      case ContraceptiveMethod.femaleSterilization:
        activityCode = 'FP_FEMALE_STERILIZATION';
        break;
      case ContraceptiveMethod.maleSterilization:
        activityCode = 'FP_MALE_STERILIZATION';
        break;
      default:
        activityCode = 'FP_COUNSELLING_GENERAL';
    }

    final eventId = 'inc_fp_${memberId}_${now.millisecondsSinceEpoch}';
    final idempotencyKey = 'fp_${memberId}_${activityCode}_${now.year}_${now.month}';

    await _db.into(_db.incentiveEvents).insert(
          IncentiveEventsCompanion.insert(
            id: eventId,
            memberId: memberId,
            activityCode: activityCode,
            catalogueVersionId: 'v1.0-mohfw',
            eventDate: now.millisecondsSinceEpoch,
            status: const Value('eligible'),
            createdAt: now.millisecondsSinceEpoch,
            idempotencyKey: idempotencyKey,
            evidenceRecordId: Value('facility_confirmation:$facilityName'),
          ),
        );

    return eventId;
  }

  /// Enforces DPDP and Reproductive Health privacy: hides specific contraceptive choices in shared household views (Requirement 18.7).
  Map<String, dynamic> applyPrivacyFilter(Map<String, dynamic> record, String viewerRole) {
    final filtered = Map<String, dynamic>.from(record);
    final allowedRoles = ['asha', 'anm', 'mo', 'cho'];
    if (!allowedRoles.contains(viewerRole.toLowerCase())) {
      filtered['contraceptive_method'] = 'Confidential / Protected Record';
      filtered['fp_notes'] = 'Hidden per DPDP Act Section 6';
      filtered.remove('last_refill_date');
      filtered.remove('contraceptive_stock_issued');
    }
    return filtered;
  }
}
