import 'package:core_model/core_model.dart';
import 'package:core_referral/core_referral.dart';

void main() {
  final document = ClinicalAssessmentDocument(
    assessmentId: 'a-1', patientId: 'p-1', workerId: 'W-114', deviceId: 'd-1',
    createdAtDevice: DateTime(2026, 8, 21, 10, 14),
    patient: const PatientDemographics(ageMonths: 24, sex: PatientSex.male, village: 'Kondhwa Khurd', weightKg: 10.4),
    workerNotes: 'Child appears tired; mother reports poor feeding since morning.',
    fields: {
      FieldPaths.fever: const SourcedValue.confirmed('YES'),
      FieldPaths.feverDurationDays: const SourcedValue.confirmed(3),
      FieldPaths.cough: const SourcedValue.confirmed('YES'),
      FieldPaths.coughDurationDays: const SourcedValue.confirmed(2),
      FieldPaths.temperatureC: const SourcedValue.measured(38.7),
      FieldPaths.respiratoryRate: const SourcedValue.measured(58),
      FieldPaths.muacMm: const SourcedValue.notAvailable(),
      for (final p in FieldPaths.mandatoryDangerSigns) p: const SourcedValue.guided('NO'),
    },
    versions: const VersionStamp(app: '0.4.1', ruleset: 'imci-mvp-1.0.0', engine: '1.0.0', extractor: '1.0.0', asrModel: 'indicconformer-mr-v1'),
  );
  const result = ClinicalTriageResult(
    band: TriageBand.red,
    firedRules: [FiredRule(ruleId: 'RESP-02', severity: RuleSeverity.red, category: 'COUGH_BREATHING',
      reasonKey: 'reason.fast_breathing', reasonText: 'Fast breathing for age: 58/min (threshold 40/min).',
      evidence: {'vitals.respiratory_rate': 58}, sourceRef: 'WHO-IMCI/cough-difficult-breathing')],
    blockingQuestions: [], flooredBy: ['vitals.muac_mm'], escalatedByWorker: false,
    adviceKey: 'advice.red.urgent_referral', rulesetVersion: 'imci-mvp-1.0.0', engineVersion: '1.0.0',
  );
  final note = ReferralNoteBuilder.build(document: document, result: result,
    context: ReferralContext(patientLocalCode: 'P-1023', workerName: 'Sunita D.', workerCode: 'W-114',
      workerContact: '9xxxxx1234', appVersion: '0.4.1', generatedAt: DateTime(2026, 8, 21, 10, 14)));
  print(note.plainText);
}
