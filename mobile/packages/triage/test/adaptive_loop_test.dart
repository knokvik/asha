import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:triage/triage.dart';

void main() {
  late ContextPack pack;
  late String v2Csv;
  late ImciEngine engine;

  setUpAll(() {
    final dir = Directory('lib/data/pack');
    String read(String name) => File('${dir.path}/$name').readAsStringSync();
    pack = ContextPack.parse(
      manifestJson: read('manifest.json'),
      wardsGeoJson: read('wards.geojson'),
      diseaseCsv: read('disease_counts.csv'),
      modulesJson: read('modules.json'),
      priorsJson: read('priors.json'),
      questionBankJson: read('question_bank.json'),
    );
    v2Csv = read('disease_counts_v2.csv');
    final tables = <String, Map<String, Object?>>{};
    final rules = Directory('../imci_engine/lib/data/imci_tables');
    for (final entity in rules.listSync()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      tables[entity.uri.pathSegments.last] = (jsonDecode(
        entity.readAsStringSync(),
      ) as Map).cast<String, Object?>();
    }
    engine = ImciEngine(ImciCatalog.fromModuleMaps(tables));
  });

  ContextPack v2() => pack.withCounts(
    parseDiseaseCsv(v2Csv),
    version: 2,
    generatedAt: '2026-10-26T00:00:00Z',
  );

  Set<String> ids(FlowState flow) =>
      flow.questions.map((question) => question.id).toSet();

  group('ward lookup works offline', () {
    test('the cached sample fix sits inside W3', () {
      final index = WardIndex(pack.wards);
      final resolution = index.resolve(pack.sampleFix);
      expect(resolution.kind, WardFixKind.inside);
      expect(resolution.wardId, 'W3');
      expect(resolution.choices, isEmpty);
    });

    test('no fix asks the worker to pick a ward', () {
      final resolution = WardIndex(pack.wards).resolve(null);
      expect(resolution.kind, WardFixKind.noFix);
      expect(resolution.choices, hasLength(8));
    });

    test('a point outside every ward asks for a pick', () {
      final resolution = WardIndex(pack.wards)
          .resolve(const LatLon(18.50, 73.50));
      expect(resolution.kind, WardFixKind.outside);
      expect(resolution.wardId, isNull);
    });

    test('a fix within 50 metres of the W2/W3 edge asks for confirmation', () {
      const latitude = 18.64;
      final metresPerLon = 111320 * math.cos(latitude * math.pi / 180);
      final longitude = 73.82 + 25 / metresPerLon;
      final resolution = WardIndex(pack.wards)
          .resolve(LatLon(latitude, longitude));
      expect(resolution.kind, WardFixKind.confirmBoundary);
      expect(resolution.wardId, 'W3');
      expect(resolution.choices, containsAll(['W3', 'W2']));
    });
  });

  group('the planted cluster adapts the modules', () {
    test('dengue is active in W3 in October and quiet wards stay inactive', () {
      expect(pack.activeModuleIds('W3'), contains('dengue'));
      for (final ward in ['W2', 'W4', 'W5', 'W6', 'W7', 'W8']) {
        expect(pack.activeModuleIds(ward), isEmpty, reason: ward);
      }
    });

    test('dengue stays off outside its season', () {
      expect(pack.activeModuleIds('W3', month: 1), isEmpty);
    });

    test('the referral context names the W3 dengue-like cases', () {
      expect(
        pack.clusterSummary('W3'),
        '8 dengue-like cases in W3 in the last 2 weeks',
      );
      expect(pack.clusterSummary('W2'), isEmpty);
    });

    test('version 2 moves the cluster from W3 to W5', () {
      final next = v2();
      expect(next.activeModuleIds('W3'), isEmpty);
      expect(next.activeModuleIds('W5'), ['dengue']);
      expect(next.clusterSummary('W5'), contains('dengue-like cases in W5'));
    });
  });

  group('question flow safety', () {
    test('adult context adds the unified adult vitals questions', () {
      final flow = FlowBuilder(
        pack,
      ).build(wardId: 'W3', calendarMonth: 8, ageMonths: 840, extraModules: const {'adult_vitals'});
      expect(
        flow.questions.map((question) => question.id),
        containsAll(['adult.systolic_bp', 'adult.diastolic_bp', 'adult.pulse']),
      );
      flow.seedInput('vitals.systolic_bp', 182);
      expect(flow.answers['vitals.systolic_bp'], 182);
      expect(flow.answeredIds, contains('adult.systolic_bp'));
    });

    test('danger signs come first, in chart order', () {
      final flow = FlowBuilder(pack).build(wardId: 'W3');
      expect(flow.questions.take(5).map((question) => question.id).toList(), [
        'core.drink',
        'core.vomit',
        'core.convulsions',
        'core.convulsing_now',
        'core.lethargic',
      ]);
      expect(
        flow.questions.first.prompt('en'),
        'Can the child drink or breastfeed?',
      );
    });

    test('every core question is in a flow with no outbreak and in a flow with dengue', () {
      final core = pack.questions
          .where((question) => question.module == 'core')
          .map((question) => question.id)
          .toSet();
      expect(ids(FlowBuilder(pack).build(wardId: 'W1')), containsAll(core));
      expect(ids(FlowBuilder(pack).build(wardId: 'W3')), containsAll(core));
    });

    test('dengue warning signs are asked before the remaining core questions, and only in W3', () {
      final w3 = FlowBuilder(pack).build(wardId: 'W3');
      final quietWard = FlowBuilder(pack).build(wardId: 'W2');
      expect(ids(quietWard), isNot(contains('dengue.abdominal')));
      final dengueFlagAt = w3.questions.indexWhere(
        (question) => question.id == 'dengue.abdominal',
      );
      final coreRestAt = w3.questions.indexWhere(
        (question) => question.id == 'core.stiff_neck',
      );
      final breedingAt = w3.questions.indexWhere(
        (question) => question.id == 'dengue.breeding',
      );
      expect(dengueFlagAt, greaterThan(4));
      expect(dengueFlagAt, lessThan(coreRestAt));
      expect(breedingAt, greaterThan(coreRestAt));
    });

    test('remaining core questions are in descending weight', () {
      final flow = FlowBuilder(pack).build(wardId: 'W2');
      final rest = flow.questions
          .where(
            (question) =>
                question.module == 'core' &&
                !dangerFields.contains(question.inputField),
          )
          .toList();
      for (var i = 1; i < rest.length; i++) {
        expect(rest[i - 1].weight, greaterThanOrEqualTo(rest[i].weight));
      }
    });

    test('a confirmed danger sign stops the rest of the questions', () {
      final flow = FlowBuilder(pack).build(wardId: 'W3');
      flow.answer('core.drink', false);
      expect(flow.earlyStopped, isTrue);
      expect(flow.pending, isEmpty);
      expect(flow.answers['symptoms.unable_to_drink'], isTrue);
      expect(ids(flow), contains('core.cough'));
    });

    test(
      'yes to drinking is not a danger sign, and unknown stores nothing',
      () {
        final flow = FlowBuilder(pack).build(wardId: 'W3');
        flow.answer('core.drink', true);
        expect(flow.earlyStopped, isFalse);
        expect(flow.answers['symptoms.unable_to_drink'], isFalse);
        flow.answer('core.vomit', null);
        expect(flow.answers.containsKey('symptoms.vomits_everything'), isFalse);
        expect(flow.dangerComplete, isFalse);
      },
    );

    test('typed measurements and choices are retained for the live answer controls', () {
      final flow = FlowBuilder(pack).build(wardId: 'W2');
      flow.answer('core.rr', 44);
      flow.answer('core.skin_pinch', 'slow');

      expect(flow.answers['vitals.respiratory_rate'], 44);
      expect(flow.answers['symptoms.skin_pinch'], 'slow');
      final input = flow.toAssessmentInput(
        patientId: 'case',
        ageMonths: 18,
        sex: 'F',
      );
      expect(input.vitals.respiratoryRate, 44);
      expect(input.symptoms.skinPinchSlow, isTrue);
    });

    test('the flow becomes an assessment the rules engine can classify', () {
      final flow = FlowBuilder(pack).build(wardId: 'W3');
      flow.answer('core.diarrhoea', true);
      flow.answer('core.sunken', true);
      flow.answer('core.skin_pinch', 'very_slow');
      final input = flow.toAssessmentInput(
        patientId: 'case',
        ageMonths: 14,
        sex: 'F',
      );
      expect(input.context.wardId, 'W3');
      expect(input.context.activeModules, ['dengue']);
      expect(input.symptoms.skinPinchVerySlow, isTrue);
      expect(input.symptoms.skinPinchSlow, isFalse);
      final result = engine.evaluate(input);
      expect(result.flag, TriageFlag.red);
      expect(result.ruleIds, contains('DH-SEVERE'));
    });
  });

  group('hybrid policy', () {
    HybridDecision decide(
      EngineResult result,
      ModelScore score, {
      String context = '',
    }) {
      return const HybridTriage().combine(
        result,
        score,
        outbreakContext: context,
      );
    }

    EngineResult flagged(TriageFlag flag, {int? followUpDays}) {
      return TriageResult(
        flag: flag,
        firedRules: const [],
        followUpDays: followUpDays,
      );
    }

    test('an engine red is never downgraded', () {
      final decision = decide(
        flagged(TriageFlag.red),
        const ModelScore(
          pRed: 0.01,
          pYellow: 0.04,
          pGreen: 0.95,
          latencyMs: 0.2,
        ),
      );
      expect(decision.flag, TriageFlag.red);
      expect(decision.modelContribution.escalated, isFalse);
      expect(decision.modelContribution.note, contains('Engine RED kept'));
    });

    test('a yellow flag escalates when red probability is above 0.65', () {
      final decision = decide(
        flagged(TriageFlag.yellow, followUpDays: 2),
        const ModelScore(
          pRed: 0.80,
          pYellow: 0.15,
          pGreen: 0.05,
          latencyMs: 0.2,
        ),
        context: '8 dengue-like cases in W3 in the last 2 weeks',
      );
      expect(decision.flag, TriageFlag.red);
      expect(decision.followUpDays, isNull);
      expect(decision.modelContribution.escalated, isTrue);
      expect(
        decision.modelContribution.note,
        contains('escalated: high risk +'),
      );
      expect(decision.modelContribution.note, contains('W3'));
    });

    test('red probability equal to the threshold does not escalate', () {
      final decision = decide(
        flagged(TriageFlag.yellow, followUpDays: 2),
        const ModelScore(
          pRed: 0.65,
          pYellow: 0.30,
          pGreen: 0.05,
          latencyMs: 0.1,
        ),
      );
      expect(decision.flag, TriageFlag.yellow);
      expect(decision.followUpDays, 2);
    });

    test('a green flag stays green even when the model is sure it is red', () {
      final decision = decide(
        flagged(TriageFlag.green),
        const ModelScore(
          pRed: 0.99,
          pYellow: 0.01,
          pGreen: 0.00,
          latencyMs: 0.1,
        ),
      );
      expect(decision.flag, TriageFlag.green);
      expect(decision.modelContribution.note, contains('Engine GREEN kept'));
    });
  });

  group('the pack loop', () {
    test(
      'a newer pack drops the open flow and moves dengue questions to W5',
      () {
        final loop = AdaptiveTriage(pack: pack, engine: engine);
        final first = loop.openAssessment(wardId: 'W3');
        expect(
          first.questions.map((question) => question.id),
          contains('dengue.abdominal'),
        );
        loop.updateContextPack(v2());
        expect(loop.openFlow, isNull);
        final moved = loop.openAssessment(wardId: 'W5');
        expect(
          moved.questions.map((question) => question.id),
          contains('dengue.abdominal'),
        );
        final quiet = loop.openAssessment(wardId: 'W3');
        expect(
          quiet.questions.map((question) => question.id),
          isNot(contains('dengue.abdominal')),
        );
        expect(ids(quiet), contains('core.drink'));
      },
    );

    test('an older pack is rejected', () {
      final loop = AdaptiveTriage(pack: v2(), engine: engine);
      expect(() => loop.updateContextPack(pack), throwsFormatException);
    });

    test(
      'a finished assessment is queued for the server without a network call',
      () {
        final loop = AdaptiveTriage(pack: pack, engine: engine);
        final input = AssessmentInput(
          patientId: 'case-w3',
          ageMonths: 8,
          sex: 'F',
          symptoms: const Symptoms(unableToDrink: true),
          context: const AssessmentContext(
            districtId: 'PCMC',
            wardId: 'W3',
            activeModules: ['dengue'],
          ),
        );
        final decision = loop.decide(input);
        expect(decision.flag, TriageFlag.red);
        expect(decision.outbreakContext, contains('W3'));
        final note = ReferralNote.fromResult(
          decision.engineView,
          const PatientProfile(
            id: 'case-w3',
            abhaId: '91-0000-0000-0001',
            name: 'Demo child',
            ageMonths: 8,
            sex: 'F',
            village: 'Pimpri',
          ),
          const FacilityProfile(id: 'HFR-PCMC-W3', name: 'PCMC UPHC Ward 3'),
          wardId: 'W3',
          referralId: 'REFW3',
          outbreakContext: decision.outbreakContext,
          suggestedFacilityId: pack.facilityForWard('W3')?.id,
        );
        loop.enqueue(input, decision, note);
        expect(loop.outbox.pending, hasLength(1));
        expect(loop.outbox.pending.single.flag, 'RED');
        expect(loop.outbox.pending.single.referralSms, isNot(contains('Demo')));
        expect(note.suggestedFacilityId, 'HFR-PCMC-W3');
      },
    );
  });

  test('a tiny int8 model returns probabilities that sum to one', () {
    final raw = jsonEncode({
      'kind': 'linear',
      'feature_names': ['age_months', 'symptoms.unable_to_drink'],
      'red_threshold': 0.65,
      'weight_scale': 0.1,
      'coefficients_int8': [
        [-10, -20],
        [0, 0],
        [10, 40],
      ],
      'intercepts': [0.0, 0.0, 0.0],
    });
    final model = RiskModel.fromJson(raw)!;
    final score = model.score(
      const AssessmentInput(
        patientId: 'p',
        ageMonths: 8,
        sex: 'F',
        symptoms: Symptoms(unableToDrink: true),
      ),
      pack.priorFor('PCMC'),
    );
    expect(score.pRed + score.pYellow + score.pGreen, closeTo(1, 1e-6));
    expect(score.pRed, greaterThan(score.pGreen));
    expect(score.latencyMs, lessThan(50));
    expect(score.modelVersion, RiskModel.fallbackModelVersion);
  });

  test(
    'a malformed model falls back to rules-only triage without blocking',
    () {
      expect(RiskModel.fromJson('{not-json'), isNull);
      const input = AssessmentInput(
        patientId: 'rules-only',
        ageMonths: 12,
        sex: 'F',
        symptoms: Symptoms(unableToDrink: true),
      );
      final decision = AdaptiveTriage(pack: pack, engine: engine).decide(input);
      expect(decision.flag, TriageFlag.red);
      expect(decision.modelContribution.score, isNull);
      expect(decision.modelContribution.modelVersion, 'rules-only');
    },
  );

  test(
    'the fitted model file stays under 1 MB and leans red on a danger sign',
    () {
      final file = File('lib/data/model/model.json');
      expect(file.lengthSync(), lessThan(1000000));
      final model = RiskModel.fromJson(file.readAsStringSync());
      expect(model, isNotNull);
      expect(model!.kind, 'lightgbm');
      final input = AssessmentInput(
        patientId: 'p',
        ageMonths: 8,
        sex: 'F',
        symptoms: const Symptoms(unableToDrink: true),
      );
      final prior = pack.priorFor('PCMC');
      final first = model.score(input, prior);
      expect(first.pRed, greaterThan(0.5));
      expect(first.pRed + first.pYellow + first.pGreen, closeTo(1, 1e-6));
      final times = <double>[
        for (var i = 0; i < 40; i++) model.score(input, prior).latencyMs,
      ]..sort();
      expect(times[(times.length * 0.95).floor()], lessThan(50));
      final kept = const HybridTriage().combine(
        engine.evaluate(input),
        ModelScore(
          pRed: 0.01,
          pYellow: 0.01,
          pGreen: 0.98,
          latencyMs: first.latencyMs,
        ),
      );
      expect(kept.flag, TriageFlag.red);
    },
  );

  test('the triage library does not import IO or the network', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    expect(files, isNotEmpty);
    for (final file in files) {
      final text = file.readAsStringSync();
      expect(text, isNot(contains("import 'dart:io'")), reason: file.path);
      expect(text, isNot(contains('package:http')), reason: file.path);
    }
  });
}
