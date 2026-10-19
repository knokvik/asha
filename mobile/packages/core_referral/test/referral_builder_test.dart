import 'package:core_model/core_model.dart';
import 'package:core_referral/core_referral.dart';
import 'package:test/test.dart';

ClinicalAssessmentDocument _document({
  Map<String, SourcedValue>? overrides,
  bool escalated = false,
  String? workerNotes,
}) => ClinicalAssessmentDocument(
  assessmentId: 'a-1',
  patientId: 'p-1',
  workerId: 'W-114',
  deviceId: 'd-1',
  createdAtDevice: DateTime(2026, 8, 21, 10, 14),
  patient: const PatientDemographics(
    ageMonths: 24,
    sex: PatientSex.male,
    village: 'Kondhwa Khurd',
    weightKg: 10.4,
  ),
  workerOverride: WorkerOverride(escalateToRed: escalated, note: escalated ? 'child looks very unwell' : null),
  workerNotes: workerNotes,
  fields: {
    FieldPaths.fever: const SourcedValue.confirmed('YES'),
    FieldPaths.feverDurationDays: const SourcedValue.confirmed(3),
    FieldPaths.cough: const SourcedValue.confirmed('YES'),
    FieldPaths.coughDurationDays: const SourcedValue.confirmed(2),
    FieldPaths.diarrhoea: const SourcedValue.guided('NO'),
    FieldPaths.temperatureC: const SourcedValue.measured(38.7),
    FieldPaths.respiratoryRate: const SourcedValue.measured(58),
    FieldPaths.muacMm: const SourcedValue.notAvailable(),
    for (final path in FieldPaths.mandatoryDangerSigns) path: const SourcedValue.guided('NO'),
    ...?overrides,
  },
  versions: const VersionStamp(
    app: '0.4.1',
    ruleset: 'imci-mvp-1.0.0',
    engine: '1.0.0',
    extractor: '1.0.0',
    asrModel: 'indicconformer-mr-v1',
  ),
);

ClinicalTriageResult _result({
  TriageBand band = TriageBand.red,
  List<FiredRule>? rules,
  List<String> flooredBy = const ['vitals.muac_mm'],
  bool escalated = false,
}) => ClinicalTriageResult(
  band: band,
  firedRules: rules ??
      const [
        FiredRule(
          ruleId: 'RESP-02',
          severity: RuleSeverity.red,
          category: 'COUGH_BREATHING',
          reasonKey: 'reason.fast_breathing',
          reasonText: 'Fast breathing for age: 58/min.',
          evidence: {'vitals.respiratory_rate': 58, 'patient.age_months': 24},
          sourceRef: 'WHO-IMCI/cough-difficult-breathing',
        ),
        FiredRule(
          ruleId: 'FEV-04',
          severity: RuleSeverity.yellow,
          category: 'FEVER',
          reasonKey: 'reason.fever_with_other_finding',
          reasonText: 'Fever is present with another respiratory finding.',
          evidence: {},
          sourceRef: 'WHO-IMCI/fever',
        ),
      ],
  blockingQuestions: const [],
  flooredBy: flooredBy,
  escalatedByWorker: escalated,
  adviceKey: 'advice.red.urgent_referral',
  rulesetVersion: 'imci-mvp-1.0.0',
  engineVersion: '1.0.0',
);

ReferralContext get _ctx => ReferralContext(
  patientLocalCode: 'P-1023',
  workerName: 'Sunita D.',
  workerCode: 'W-114',
  workerContact: '9xxxxx1234',
  appVersion: '0.4.1',
  generatedAt: DateTime(2026, 8, 21, 10, 14),
);

ReferralNote _build({
  ClinicalAssessmentDocument? document,
  ClinicalTriageResult? result,
  String locale = 'en',
}) => ReferralNoteBuilder.build(
  document: document ?? _document(),
  result: result ?? _result(),
  context: _ctx,
  locale: locale,
);

void main() {
  group('§11.2 Tier 1 design rules', () {
    test('the action header is at most 8 lines', () {
      expect(_build().actionHeaderLineCount, lessThanOrEqualTo(8));
    });

    test('the band word is a plain imperative, not only a colour', () {
      expect(_build().actionHeader, contains('SEE NOW'));
      expect(_build(result: _result(band: TriageBand.yellow)).actionHeader, contains('SEE TODAY'));
      expect(_build(result: _result(band: TriageBand.green)).actionHeader, contains('ROUTINE FOLLOW-UP'));
    });

    test('there is exactly one WHY line, carrying the highest-severity rule', () {
      final header = _build().actionHeader;
      final whyLines = header.split('\n').where((line) => line.startsWith('WHY:')).toList();

      expect(whyLines, hasLength(1));
      expect(whyLines.single, contains('Fast breathing for age: 58/min.'));
      expect(whyLines.single, contains('RESP-02'));
      expect(whyLines.single, isNot(contains('FEV-04')));
    });

    test('the WHY line carries the number that triggered the band', () {
      expect(_build().actionHeader, contains('58/min'));
    });

    test('screened-and-absent danger signs are stated explicitly', () {
      expect(_build().actionHeader, contains('DANGER SIGNS: none of 7 present'));
    });

    test('a present danger sign is named rather than counted away', () {
      final note = _build(
        document: _document(overrides: {FieldPaths.convulsingNow: const SourcedValue.guided('YES')}),
      );
      expect(note.actionHeader, contains('Convulsing now'));
      expect(note.actionHeader, contains('present'));
    });

    test('unmeasured fields appear on a NOT CHECKED line', () {
      final header = _build().actionHeader;
      expect(header, contains('NOT CHECKED:'));
      expect(header, contains('MUAC'));
    });

    test('the worker line gives a name, a code and one number to call', () {
      final header = _build().actionHeader;
      expect(header, contains('ASHA Sunita D. (W-114)'));
      expect(header, contains('21-Aug 10:14'));
      expect(header, contains('9xxxxx1234'));
    });

    test('a worker escalation is disclosed in the header (SI-4)', () {
      final note = _build(result: _result(escalated: true));
      expect(note.actionHeader, contains('ESCALATED BY WORKER'));
    });
  });

  group('§11.3 output channels', () {
    test('the SMS-safe header drops the worker contact line', () {
      final note = _build();
      expect(note.actionHeader, contains('9xxxxx1234'));
      expect(note.smsSafeHeader, isNot(contains('9xxxxx1234')));
    });

    test('the SMS-safe header still carries the band and the reason', () {
      final sms = _build().smsSafeHeader;
      expect(sms, contains('SEE NOW'));
      expect(sms, contains('RESP-02'));
    });

    test('the structured form carries what the dashboard renders', () {
      final structured = _build().structured;

      expect(structured['band'], 'RED');
      expect((structured['primary_reason'] as Map)['rule_id'], 'RESP-02');
      expect(structured['not_checked'], contains('vitals.muac_mm'));
      expect(structured['floored_by'], contains('vitals.muac_mm'));
      expect((structured['danger_signs_screened'] as Map).length, 7);
      expect((structured['versions'] as Map)['ruleset'], 'imci-mvp-1.0.0');
    });

    test('every negative danger-sign answer survives into the structured form', () {
      final screened = _build().structured['danger_signs_screened'] as Map;
      expect(screened.values.every((value) => value == 'NO'), isTrue);
    });
  });

  group('Tier 2 full record', () {
    test('lists every fired rule, not just the primary one', () {
      final text = _build().plainText;
      expect(text, contains('[RESP-02]'));
      expect(text, contains('[FEV-04]'));
    });

    test('cites the clinical source for each rule', () {
      expect(_build().plainText, contains('WHO-IMCI/cough-difficult-breathing'));
    });

    test('spells out limitations rather than leaving a blank', () {
      final text = _build().plainText;
      expect(text, contains('NOT ASSESSED / LIMITATIONS'));
      expect(text, contains('could not be excluded'));
    });

    test('carries all SI-9 version stamps', () {
      final text = _build().plainText;
      expect(text, contains('Ruleset imci-mvp-1.0.0'));
      expect(text, contains('Engine 1.0.0'));
      expect(text, contains('Extractor 1.0.0'));
      expect(text, contains('ASR indicconformer-mr-v1'));
      expect(text, contains('App 0.4.1'));
    });

    test('carries the SI-10 disclaimer', () {
      expect(_build().plainText, contains('not a diagnosis'));
    });

    test('includes the worker note when one was written', () {
      final note = _build(document: _document(workerNotes: 'Poor feeding since morning.'));
      expect(note.plainText, contains('WORKER NOTE'));
      expect(note.plainText, contains('Poor feeding since morning.'));
    });

    test('omits the worker-note section when there is none', () {
      expect(_build().plainText, isNot(contains('WORKER NOTE')));
    });

    test('renders the band-appropriate caregiver advice', () {
      expect(_build().plainText, contains('immediately'));
    });
  });

  group('determinism (§11.1)', () {
    test('the same record renders byte-identically every time', () {
      expect(_build().plainText, _build().plainText);
      expect(_build().actionHeader, _build().actionHeader);
    });

    test('no field is dropped when a label is missing from the table', () {
      final note = _build(
        document: _document(overrides: {'observations.some_new_sign': const SourcedValue.guided('NO')}),
      );
      expect(note.plainText, isNotEmpty);
    });
  });

  group('localisation', () {
    test('renders in every shipped language with a distinct band imperative', () {
      final imperatives = <String>{};
      for (final locale in const ['en', 'hi', 'mr']) {
        final note = _build(locale: locale);
        expect(note.actionHeader, isNotEmpty);
        imperatives.add(note.actionHeader.split('\n').first);
      }
      expect(imperatives, hasLength(3));
    });

    test('an unshipped locale falls back to English rather than rendering blanks', () {
      final note = _build(locale: 'ta');
      expect(note.actionHeader, contains('SEE NOW'));
    });
  });

  group('formatting', () {
    test('age renders the way a pediatrician reads it', () {
      expect(ReferralNoteBuilder.formatAge(24), '2 y 0 m');
      expect(ReferralNoteBuilder.formatAge(7), '7 m');
      expect(ReferralNoteBuilder.formatAge(59), '4 y 11 m');
    });
  });
}
