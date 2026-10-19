import 'package:flutter/foundation.dart';

/// Clinical triage severity levels.
enum TriageSeverity {
  green(1, 'Routine / Normal'),
  yellow(2, 'Prompt Care / Facility Referral'),
  red(3, 'Emergency / Immediate Transfer');

  final int rank;
  final String label;
  const TriageSeverity(this.rank, this.label);
}

@immutable
class CdssSuggestionWrapper {
  final String ruleId;
  final TriageSeverity suggestedSeverity;
  final String rationale;
  final List<String> contributingObservations;
  final bool isDecisionSupport;
  final String safetyDisclaimer;

  const CdssSuggestionWrapper({
    required this.ruleId,
    required this.suggestedSeverity,
    required this.rationale,
    required this.contributingObservations,
    this.isDecisionSupport = true,
    this.safetyDisclaimer =
        'Decision Support Only: ASHA clinician confirmation required before finalizing record (Requirement 46.1).',
  });
}

@immutable
class OverrideRecord {
  final String id;
  final String ruleId;
  final TriageSeverity systemSuggestedSeverity;
  final TriageSeverity ashaConfirmedSeverity;
  final String overrideReasonCategory; // 'clinical_instinct', 'maternal_reported_worsening', 'visible_pallor_unmeasured', 'family_insisted', 'other'
  final String userFeedbackNotes;
  final String languageCode;
  final String ashaWorkerId;
  final DateTime recordedAt;

  const OverrideRecord({
    required this.id,
    required this.ruleId,
    required this.systemSuggestedSeverity,
    required this.ashaConfirmedSeverity,
    required this.overrideReasonCategory,
    required this.userFeedbackNotes,
    required this.languageCode,
    required this.ashaWorkerId,
    required this.recordedAt,
  });

  bool get isEscalation => ashaConfirmedSeverity.rank > systemSuggestedSeverity.rank;
  bool get isDeescalation => ashaConfirmedSeverity.rank < systemSuggestedSeverity.rank;
}

@immutable
class SafetyIncidentReport {
  final String incidentId;
  final String reporterId;
  final String reporterRole;
  final String description;
  final List<String> contributingFactors;
  final String immediateOutcome;
  final String proposedCorrectiveAction;
  final DateTime followUpReviewDate;
  final String severity; // 'LOW', 'MODERATE', 'CRITICAL_NEAR_MISS'
  final DateTime reportedAt;

  const SafetyIncidentReport({
    required this.incidentId,
    required this.reporterId,
    required this.reporterRole,
    required this.description,
    required this.contributingFactors,
    required this.immediateOutcome,
    required this.proposedCorrectiveAction,
    required this.followUpReviewDate,
    required this.severity,
    required this.reportedAt,
  });
}

class AiSafetyService {
  final Map<String, bool> _componentFeatureToggles = {};

  AiSafetyService() {
    // Default components active
    _componentFeatureToggles['voice_asr_hi'] = true;
    _componentFeatureToggles['voice_asr_mr'] = true;
    _componentFeatureToggles['voice_asr_ta'] = true;
    _componentFeatureToggles['cdss_pediatric_triage'] = true;
    _componentFeatureToggles['cdss_maternal_triage'] = true;
  }

  /// Wraps any raw CDSS output with mandatory safety metadata and transparency fields (Requirements 46.1, 46.8).
  CdssSuggestionWrapper wrapCdssSuggestion({
    required String ruleId,
    required TriageSeverity suggestedSeverity,
    required String rationale,
    required List<String> userEnteredObservations,
  }) {
    return CdssSuggestionWrapper(
      ruleId: ruleId,
      suggestedSeverity: suggestedSeverity,
      rationale: rationale,
      contributingObservations: List.unmodifiable(userEnteredObservations),
      isDecisionSupport: true,
      safetyDisclaimer:
          'Decision Support Only: ASHA clinician confirmation required before finalizing record (Requirement 46.1).',
    );
  }

  /// Evaluates whether an ASHA override or severity choice requires a reconsideration prompt (Requirement 46.2).
  ///
  /// If the system suggests a LOWER severity than the ASHA's suspicion, triggers reconsideration.
  /// ASHA always retains full authority to escalate severity without restriction.
  String? checkReconsiderationPrompt({
    required TriageSeverity systemSuggested,
    required TriageSeverity ashaSuspicion,
    String patientCategory = 'child',
  }) {
    if (systemSuggested.rank < ashaSuspicion.rank) {
      if (patientCategory == 'child') {
        return 'Reconsideration Check: Does the child look lethargic, abnormally sleepy, or unable to drink? The system calculated a lower severity (${systemSuggested.label}), but you may escalate to ${ashaSuspicion.label} with full clinical discretion.';
      } else {
        return 'Reconsideration Check: Does the mother exhibit severe breathlessness, altered sensorium, or severe pallor? You may confirm escalation to ${ashaSuspicion.label}.';
      }
    }
    return null; // No reconsideration prompt needed when accepting or escalating
  }

  /// Records structured ASHA override feedback for clinical team review (Requirement 46.7).
  OverrideRecord recordOverride({
    required String ruleId,
    required TriageSeverity systemSuggestedSeverity,
    required TriageSeverity ashaConfirmedSeverity,
    required String overrideReasonCategory,
    required String userFeedbackNotes,
    required String languageCode,
    required String ashaWorkerId,
  }) {
    final now = DateTime.now();
    return OverrideRecord(
      id: 'ovr_${now.millisecondsSinceEpoch}',
      ruleId: ruleId,
      systemSuggestedSeverity: systemSuggestedSeverity,
      ashaConfirmedSeverity: ashaConfirmedSeverity,
      overrideReasonCategory: overrideReasonCategory,
      userFeedbackNotes: userFeedbackNotes,
      languageCode: languageCode,
      ashaWorkerId: ashaWorkerId,
      recordedAt: now,
    );
  }

  /// Reports a clinical safety incident or near-miss with structured fields (Requirement 46.4).
  SafetyIncidentReport createIncidentReport({
    required String reporterId,
    required String reporterRole,
    required String description,
    required List<String> contributingFactors,
    required String immediateOutcome,
    required String proposedCorrectiveAction,
    required DateTime followUpReviewDate,
    required String severity,
  }) {
    return SafetyIncidentReport(
      incidentId: 'inc_rep_${DateTime.now().millisecondsSinceEpoch}',
      reporterId: reporterId,
      reporterRole: reporterRole,
      description: description,
      contributingFactors: contributingFactors,
      immediateOutcome: immediateOutcome,
      proposedCorrectiveAction: proposedCorrectiveAction,
      followUpReviewDate: followUpReviewDate,
      severity: severity,
      reportedAt: DateTime.now(),
    );
  }

  /// Inspects whether an ML or clinical module is safe and enabled (Requirement 46.5).
  bool isComponentEnabled(String componentKey) {
    return _componentFeatureToggles[componentKey] ?? true;
  }

  /// Safely disables or restricts a poor-performing component until recalibrated (Requirement 46.5).
  void disableComponent(String componentKey, {required String reason}) {
    _componentFeatureToggles[componentKey] = false;
  }
}
