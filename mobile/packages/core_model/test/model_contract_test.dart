import 'package:core_model/core_model.dart';
import 'package:test/test.dart';

void main() {
  group('§7.2 source semantics (SI-5)', () {
    test('only confirmed, guided, measured and not-available reach the engine', () {
      const visible = {
        ClinicalSource.confirmedByWorker,
        ClinicalSource.guidedAnswer,
        ClinicalSource.measured,
        ClinicalSource.notAvailable,
      };
      for (final source in ClinicalSource.values) {
        expect(source.visibleToEngine, visible.contains(source), reason: source.wireName);
      }
    });

    test('an extracted-unconfirmed value projects as UNKNOWN, never as its value', () {
      const value = SourcedValue.extracted('YES');
      expect(value.isUnknown, isTrue);
      expect(value.isKnown, isFalse);
      expect(value.projectedValue, isA<UnknownValue>());
      // The raw value is still retained for the confirmation screen (§9.6).
      expect(value.value, 'YES');
    });

    test('not-available projects as UNOBTAINABLE, which is distinct from UNKNOWN', () {
      const value = SourcedValue.notAvailable();
      expect(value.isUnobtainable, isTrue);
      expect(value.projectedValue, isA<UnobtainableValue>());
      expect(value.projectedValue, isNot(isA<UnknownValue>()));
    });

    test('a confirmed value with a null payload is still unknown', () {
      const value = SourcedValue(value: null, source: ClinicalSource.confirmedByWorker);
      expect(value.isKnown, isFalse);
      expect(value.isUnknown, isTrue);
    });

    test('unrecognised wire values fail closed to UNSET', () {
      expect(ClinicalSourceX.fromWire('SOMETHING_NEW'), ClinicalSource.unset);
      expect(ClinicalSourceX.fromWire(null), ClinicalSource.unset);
      expect(ClinicalSourceX.fromWire(42), ClinicalSource.unset);
    });

    test('round-trips through JSON without changing provenance', () {
      for (final source in ClinicalSource.values) {
        final original = SourcedValue(value: 'X', source: source);
        final restored = SourcedValue.fromJson(original.toJson());
        expect(restored.source, source);
        expect(restored.value, 'X');
      }
    });
  });

  group('ClinicalAssessment', () {
    test('synthesises patient paths that are not in the field map', () {
      final assessment = ClinicalAssessment(ageMonths: 18, sex: PatientSex.female);
      expect(assessment.valueAt(FieldPaths.ageMonths).value, 18);
      expect(assessment.valueAt(FieldPaths.sex).value, 'F');
    });

    test('an unrecorded field reads as UNSET rather than throwing', () {
      final assessment = ClinicalAssessment(ageMonths: 18);
      final value = assessment.valueAt('observations.never_recorded');
      expect(value.source, ClinicalSource.unset);
      expect(value.isUnknown, isTrue);
    });

    test('withField returns a new assessment and leaves the original untouched', () {
      final original = ClinicalAssessment(ageMonths: 18);
      final updated = original.withField(FieldPaths.fever, const SourcedValue.guided('YES'));
      expect(original.valueAt(FieldPaths.fever).isUnknown, isTrue);
      expect(updated.valueAt(FieldPaths.fever).value, 'YES');
    });

    test('the field map is unmodifiable — clinical input cannot be mutated in place', () {
      final assessment = ClinicalAssessment(
        ageMonths: 18,
        fields: {FieldPaths.fever: const SourcedValue.guided('YES')},
      );
      expect(
        () => assessment.fields[FieldPaths.cough] = const SourcedValue.guided('YES'),
        throwsUnsupportedError,
      );
    });

    test('round-trips through JSON', () {
      final original = ClinicalAssessment(
        ageMonths: 30,
        sex: PatientSex.male,
        fields: {
          FieldPaths.cough: const SourcedValue.confirmed('YES'),
          FieldPaths.respiratoryRate: const SourcedValue.measured(52),
          FieldPaths.muacMm: const SourcedValue.notAvailable(),
        },
        workerOverride: const WorkerOverride(escalateToRed: true, note: 'worried'),
      );
      final restored = ClinicalAssessment.fromJson(original.toJson());

      expect(restored.ageMonths, 30);
      expect(restored.sex, PatientSex.male);
      expect(restored.valueAt(FieldPaths.respiratoryRate).value, 52);
      expect(restored.valueAt(FieldPaths.muacMm).isUnobtainable, isTrue);
      expect(restored.workerOverride.escalateToRed, isTrue);
      expect(restored.workerOverride.note, 'worried');
    });
  });

  group('§10.5 mandatory question set', () {
    test('covers every general danger sign plus the two observed RED signs', () {
      expect(FieldPaths.mandatoryDangerSigns, containsAll([
        FieldPaths.unableToDrinkOrBreastfeed,
        FieldPaths.vomitsEverything,
        FieldPaths.convulsionsThisIllness,
        FieldPaths.convulsingNow,
        FieldPaths.lethargicOrUnconscious,
        FieldPaths.chestIndrawing,
        FieldPaths.stridorWhenCalm,
      ]));
    });

    test('conditional questions follow cough and diarrhoea', () {
      expect(FieldPaths.conditionalQuestions[FieldPaths.cough], contains(FieldPaths.respiratoryRate));
      expect(FieldPaths.conditionalQuestions[FieldPaths.diarrhoea], containsAll([
        FieldPaths.sunkenEyes,
        FieldPaths.skinPinch,
        FieldPaths.drinkingPattern,
      ]));
    });
  });

  group('§7.1 assessment document', () {
    ClinicalAssessmentDocument buildDocument() => ClinicalAssessmentDocument(
      assessmentId: 'a-1',
      patientId: 'p-1',
      workerId: 'w-1',
      deviceId: 'd-1',
      createdAtDevice: DateTime.utc(2026, 8, 21, 10, 14, 3),
      patient: const PatientDemographics(ageMonths: 24, sex: PatientSex.male, village: 'Kolewadi', weightKg: 10.4),
      fields: {
        FieldPaths.fever: const SourcedValue.confirmed('YES'),
        FieldPaths.feverDurationDays: const SourcedValue.confirmed(3),
        FieldPaths.chestIndrawing: const SourcedValue.guided('NO'),
        FieldPaths.temperatureC: const SourcedValue.measured(38.7),
        FieldPaths.muacMm: const SourcedValue.notAvailable(),
      },
      capture: const CaptureMetadata(
        inputMode: InputMode.voice,
        language: 'mr-IN',
        transcriptRaw: 'तीन दिवसांपासून ताप आहे',
        transcriptConfidence: 0.82,
      ),
      versions: const VersionStamp(
        app: '0.4.1',
        ruleset: 'imci-mvp-1.0.0',
        engine: '1.0.0',
        extractor: '1.0.0',
        asrModel: 'indicconformer-mr-v1',
      ),
    );

    test('serialises to the nested §7.1 shape, not the flat engine shape', () {
      final json = buildDocument().toJson();
      expect(json['schema_version'], '1.0.0');
      expect((json['symptoms'] as Map)['fever'], {'value': 'YES', 'source': 'CONFIRMED_BY_WORKER'});
      expect((json['danger_signs'] as Map).containsKey('chest_indrawing'), isFalse,
          reason: 'chest_indrawing belongs to observations, not danger_signs');
      expect((json['vitals'] as Map)['muac_mm'], {'value': null, 'source': 'NOT_AVAILABLE'});
      expect((json['patient'] as Map)['village'], 'Kolewadi');
    });

    test('carries all five SI-9 version stamps', () {
      final versions = buildDocument().toJson()['versions'] as Map;
      for (final key in const ['app', 'schema', 'ruleset', 'engine', 'extractor', 'asr_model']) {
        expect(versions[key], isNotNull, reason: 'SI-9 requires $key');
      }
    });

    test('round-trips without losing a field or its provenance', () {
      final original = buildDocument();
      final restored = ClinicalAssessmentDocument.fromJson(original.toJson());

      expect(restored.assessmentId, original.assessmentId);
      expect(restored.createdAtDevice, original.createdAtDevice);
      expect(restored.fields.keys.toSet(), original.fields.keys.toSet());
      expect(restored.fields[FieldPaths.muacMm]!.source, ClinicalSource.notAvailable);
      expect(restored.capture.transcriptConfidence, 0.82);
      expect(restored.versions.asrModel, 'indicconformer-mr-v1');
    });

    test('projects to the engine assessment without transport metadata', () {
      final assessment = buildDocument().toEngineAssessment();
      expect(assessment.ageMonths, 24);
      expect(assessment.valueAt(FieldPaths.temperatureC).value, 38.7);
      expect(assessment.valueAt(FieldPaths.muacMm).isUnobtainable, isTrue);
    });
  });

  group('TriageResult', () {
    test('needs-more-info and out-of-scope are routing states, not decisions', () {
      expect(TriageBand.red.isDecision, isTrue);
      expect(TriageBand.yellow.isDecision, isTrue);
      expect(TriageBand.green.isDecision, isTrue);
      expect(TriageBand.needsMoreInfo.isDecision, isFalse);
      expect(TriageBand.outOfScope.isDecision, isFalse);
    });

    test('a result with a blank reason does not count as explained (SI-2)', () {
      const result = ClinicalTriageResult(
        band: TriageBand.red,
        firedRules: [
          FiredRule(ruleId: 'X', severity: RuleSeverity.red, category: 'T', reasonKey: 'k', reasonText: '   ', evidence: {}),
        ],
        blockingQuestions: [],
        flooredBy: [],
        escalatedByWorker: false,
        adviceKey: 'advice.red.urgent_referral',
        rulesetVersion: 'imci-mvp-1.0.0',
        engineVersion: '1.0.0',
      );
      expect(result.hasExplanation, isFalse);
    });

    test('round-trips through JSON', () {
      const original = ClinicalTriageResult(
        band: TriageBand.yellow,
        firedRules: [
          FiredRule(
            ruleId: 'RESP-05',
            severity: RuleSeverity.yellow,
            category: 'COUGH_BREATHING',
            reasonKey: 'reason.long_cough',
            reasonText: 'Cough has lasted 14 days or more.',
            evidence: {'symptoms.cough_duration_days': 15},
            sourceRef: 'WHO-IMCI/cough-difficult-breathing',
          ),
        ],
        blockingQuestions: [],
        flooredBy: ['vitals.temperature_c'],
        escalatedByWorker: false,
        adviceKey: 'advice.yellow.prompt_phc',
        rulesetVersion: 'imci-mvp-1.0.0',
        engineVersion: '1.0.0',
      );

      final restored = ClinicalTriageResult.fromJson(original.toJson());
      expect(restored.band, TriageBand.yellow);
      expect(restored.flooredBy, ['vitals.temperature_c']);
      expect(restored.firedRules.single.sourceRef, 'WHO-IMCI/cough-difficult-breathing');
      expect(restored.firedRules.single.evidence['symptoms.cough_duration_days'], 15);
      expect(restored.hasExplanation, isTrue);
    });

    test('an unknown band from a newer server fails closed to NEEDS_MORE_INFO', () {
      expect(TriageBandX.fromWire('SOME_FUTURE_BAND'), TriageBand.needsMoreInfo);
    });
  });
}
