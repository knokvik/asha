import 'dart:convert';

import 'package:core_referral/core_referral.dart';
import 'package:core_triage/core_triage.dart';

/// Answers from the Setu question walk.
///
/// The voice page never writes these fields. Only a Yes, No, choice, or
/// measurement the worker taps is visible to [TriageEngine].
class SetuCase {
  SetuCase({
    required this.ageMonths,
    this.sex = PatientSex.unknown,
    Map<String, SourcedValue>? fields,
  }) : fields = Map<String, SourcedValue>.from(fields ?? const {});

  final int ageMonths;
  final PatientSex sex;
  final Map<String, SourcedValue> fields;

  /// The Setu engine decides only for a child from 2 months up to 5 years.
  bool get inScope => ageMonths >= 2 && ageMonths < 60;

  ClinicalAssessment get assessment => ClinicalAssessment(
        ageMonths: ageMonths,
        sex: sex,
        fields: fields,
      );

  ClinicalTriageResult evaluate(RuleSet ruleset) =>
      TriageEngine.evaluate(assessment: assessment, ruleset: ruleset);

  ReferralNote referral(
    ClinicalTriageResult result, {
    DateTime? at,
    String caseCode = 'CASE',
  }) {
    final when = at ?? DateTime.now().toUtc();
    final document = ClinicalAssessmentDocument(
      assessmentId: caseCode,
      patientId: caseCode,
      workerId: 'asha',
      deviceId: 'phone',
      createdAtDevice: when,
      patient: PatientDemographics(ageMonths: ageMonths, sex: sex),
      fields: fields,
      versions: VersionStamp(
        app: 'asha-setu-yashraj',
        ruleset: result.rulesetVersion,
        engine: TriageEngine.version,
        extractor: 'none',
        asrModel: 'none',
      ),
      workerOverride: assessment.workerOverride,
    );
    return ReferralNoteBuilder.build(
      document: document,
      result: result,
      context: ReferralContext(
        patientLocalCode: caseCode,
        workerName: 'worker',
        workerCode: 'ASHA',
        generatedAt: when,
        appVersion: 'asha-setu-yashraj',
      ),
    );
  }
}

/// Facility scan of the Setu referral. The child's name and any phone number
/// stay off the code. Setu's share channel has the same limit.
String referralQrText(ReferralNote note) {
  final worker = (note.structured['worker'] as Map?)?.cast<String, dynamic>();
  final reason = note.structured['primary_reason'];
  final reasonMap = reason is Map ? reason.cast<String, dynamic>() : null;
  return jsonEncode({
    'kind': 'setu-referral',
    'band': note.structured['band'],
    'case': note.structured['patient_local_code'],
    'rule': reasonMap?['rule_id'],
    'why': reasonMap?['text'],
    'header': note.smsSafeHeader,
    'worker_code': worker?['code'],
  });
}
