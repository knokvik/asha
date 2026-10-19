import 'dart:convert';
import 'dart:io';

import 'package:imci_engine/imci_engine.dart';
import 'package:test/test.dart';

void main() {
  late ImciEngine engine;

  setUpAll(() {
    final tables = <String, Map<String, Object?>>{};
    final dir = Directory('lib/data/imci_tables');
    for (final entity in dir.listSync()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      final name = entity.uri.pathSegments.last;
      tables[name] = (jsonDecode(entity.readAsStringSync()) as Map).cast<String, Object?>();
    }
    engine = ImciEngine(ImciCatalog.fromModuleMaps(tables));
  });

  EngineResult run(
    int age, {
    Symptoms symptoms = const Symptoms(),
    Vitals vitals = const Vitals(),
    List<String> modules = const [],
  }) {
    return engine.evaluate(AssessmentInput(
      patientId: 'p',
      ageMonths: age,
      sex: 'F',
      vitals: vitals,
      symptoms: symptoms,
      context: AssessmentContext(districtId: 'PCMC', wardId: 'W3', activeModules: modules),
    ));
  }

  void expectRule(EngineResult result, TriageFlag flag, String ruleId) {
    expect(result.flag, flag);
    expect(result.ruleIds, contains(ruleId));
  }

  group('RED chart cases', () {
    test('unable to drink at 8 months', () {
      expectRule(run(8, symptoms: const Symptoms(unableToDrink: true)), TriageFlag.red, 'DS-DRINK');
    });

    test('vomits everything at 24 months', () {
      expectRule(run(24, symptoms: const Symptoms(vomitsEverything: true)), TriageFlag.red, 'DS-VOMIT');
    });

    test('convulsions during this illness at 6 months', () {
      expectRule(run(6, symptoms: const Symptoms(convulsions: true)), TriageFlag.red, 'DS-CONV');
    });

    test('convulsing now at 18 months', () {
      expectRule(run(18, symptoms: const Symptoms(convulsingNow: true)), TriageFlag.red, 'DS-CONV-NOW');
    });

    test('lethargic at 36 months', () {
      expectRule(run(36, symptoms: const Symptoms(lethargicOrUnconscious: true)), TriageFlag.red, 'DS-LETH');
    });

    test('chest indrawing at 10 months', () {
      final result = run(10, symptoms: const Symptoms(cough: true, chestIndrawing: true));
      expectRule(result, TriageFlag.red, 'CB-INDRAW');
      expect(result.followUpDays, isNull);
    });

    test('stridor in a calm child at 20 months', () {
      expectRule(run(20, symptoms: const Symptoms(cough: true, stridorInCalmChild: true)), TriageFlag.red, 'CB-STRIDOR');
    });

    test('severe dehydration at 14 months', () {
      final result = run(14, symptoms: const Symptoms(diarrhoea: true, sunkenEyes: true, drinkingPoorly: true));
      expectRule(result, TriageFlag.red, 'DH-SEVERE');
      expect(result.ruleIds, isNot(contains('DH-SOME')));
    });

    test('dysentery plus a danger sign at 16 months', () {
      final result = run(16, symptoms: const Symptoms(bloodInStool: true, unableToDrink: true));
      expect(result.flag, TriageFlag.red);
      expect(result.ruleIds, containsAll(['DH-DYS-DS', 'DS-DRINK']));
      expect(result.ruleIds, isNot(contains('DH-DYS')));
    });

    test('fever with stiff neck at 30 months', () {
      final result = run(30, symptoms: const Symptoms(fever: true, stiffNeck: true));
      expectRule(result, TriageFlag.red, 'FV-STIFF');
      expect(result.ruleIds, isNot(contains('FV-SIMPLE')));
    });

    test('severe malaria at 40 months', () {
      expectRule(run(40, symptoms: const Symptoms(fever: true, severeMalaria: true)), TriageFlag.red, 'FV-SEV-MAL');
    });

    test('mastoiditis at 22 months', () {
      expectRule(run(22, symptoms: const Symptoms(tenderSwellingBehindEar: true)), TriageFlag.red, 'EAR-MAST');
    });

    test('visible severe wasting at 18 months', () {
      expectRule(run(18, symptoms: const Symptoms(visibleSevereWasting: true)), TriageFlag.red, 'MN-WASTE');
    });

    test('oedema of both feet at 12 months', () {
      expectRule(run(12, symptoms: const Symptoms(oedemaBothFeet: true)), TriageFlag.red, 'MN-OEDEMA');
    });

    test('weight-for-age Z below -3 at 24 months', () {
      expectRule(run(24, vitals: const Vitals(weightForAgeZscore: -3.5)), TriageFlag.red, 'MN-WAZ-SEV');
    });

    test('young infant respiratory rate 60 at 1 month', () {
      expectRule(run(1, vitals: const Vitals(respiratoryRate: 60)), TriageFlag.red, 'CB-YI-FAST');
    });

    test('young infant temperature 37.5 at 0 months', () {
      expectRule(run(0, vitals: const Vitals(tempC: 37.5)), TriageFlag.red, 'FV-YI-TEMP');
    });

    test('young infant temperature below 35.5', () {
      expectRule(run(1, vitals: const Vitals(tempC: 35.4)), TriageFlag.red, 'FV-YI-TEMP');
    });
  });

  group('YELLOW chart cases', () {
    test('age 2 months, respiratory rate exactly 50, with cough', () {
      final result = run(2, symptoms: const Symptoms(cough: true), vitals: const Vitals(respiratoryRate: 50));
      expectRule(result, TriageFlag.yellow, 'CB-FAST-U12');
      expect(result.followUpDays, 2);
      expect(result.ruleIds, isNot(contains('CB-YI-FAST')));
    });

    test('age 11 months, respiratory rate 50, with cough', () {
      expectRule(
        run(11, symptoms: const Symptoms(cough: true), vitals: const Vitals(respiratoryRate: 50)),
        TriageFlag.yellow,
        'CB-FAST-U12',
      );
    });

    test('age 12 months, respiratory rate exactly 40, with cough', () {
      final result = run(12, symptoms: const Symptoms(cough: true), vitals: const Vitals(respiratoryRate: 40));
      expectRule(result, TriageFlag.yellow, 'CB-FAST-12');
      expect(result.ruleIds, isNot(contains('CB-FAST-U12')));
    });

    test('age 59 months, respiratory rate 40, with cough', () {
      expectRule(
        run(59, symptoms: const Symptoms(cough: true), vitals: const Vitals(respiratoryRate: 40)),
        TriageFlag.yellow,
        'CB-FAST-12',
      );
    });

    test('some dehydration at 8 months', () {
      final result = run(8, symptoms: const Symptoms(diarrhoea: true, sunkenEyes: true, drinksEagerly: true));
      expectRule(result, TriageFlag.yellow, 'DH-SOME');
      expect(result.followUpDays, 5);
    });

    test('dysentery without a danger sign at 20 months', () {
      expectRule(run(20, symptoms: const Symptoms(bloodInStool: true, diarrhoea: true)), TriageFlag.yellow, 'DH-DYS');
    });

    test('diarrhoea for 14 days and no dehydration at 10 months', () {
      final result = run(10, symptoms: const Symptoms(diarrhoea: true, diarrhoeaDurationDays: 14));
      expectRule(result, TriageFlag.yellow, 'DH-PERSIST');
      expect(result.ruleIds, isNot(contains('DH-NONE')));
    });

    test('malaria test positive at 36 months', () {
      final result = run(36, symptoms: const Symptoms(fever: true, malariaTestPositive: true));
      expectRule(result, TriageFlag.yellow, 'FV-MAL');
      expect(result.followUpDays, 2);
      expect(result.ruleIds, isNot(contains('FV-SIMPLE')));
    });

    test('ear discharge for 3 days at 15 months', () {
      expectRule(
        run(15, symptoms: const Symptoms(earDischarge: true, earDischargeDays: 3)),
        TriageFlag.yellow,
        'EAR-ACUTE',
      );
    });

    test('ear discharge for exactly 14 days is chronic', () {
      final result = run(15, symptoms: const Symptoms(earDischarge: true, earDischargeDays: 14));
      expectRule(result, TriageFlag.yellow, 'EAR-CHRONIC');
      expect(result.ruleIds, isNot(contains('EAR-ACUTE')));
    });

    test('ear pain only at 9 months', () {
      expectRule(run(9, symptoms: const Symptoms(earPain: true)), TriageFlag.yellow, 'EAR-PAIN');
    });

    test('weight-for-age Z -2.5 at 24 months', () {
      final result = run(24, vitals: const Vitals(weightForAgeZscore: -2.5));
      expectRule(result, TriageFlag.yellow, 'MN-WAZ-MOD');
      expect(result.followUpDays, 14);
    });

    test('weight-for-age Z exactly -3 is moderate', () {
      final result = run(24, vitals: const Vitals(weightForAgeZscore: -3));
      expectRule(result, TriageFlag.yellow, 'MN-WAZ-MOD');
      expect(result.ruleIds, isNot(contains('MN-WAZ-SEV')));
    });

    test('weight-for-age Z exactly -2 is moderate', () {
      expectRule(run(24, vitals: const Vitals(weightForAgeZscore: -2)), TriageFlag.yellow, 'MN-WAZ-MOD');
    });

    test('palmar pallor at 30 months', () {
      expectRule(run(30, symptoms: const Symptoms(palmarPallor: true)), TriageFlag.yellow, 'MN-PALLOR');
    });
  });

  group('GREEN and boundaries', () {
    test('cough for 3 days, respiratory rate 30, at 8 months', () {
      final result = run(
        8,
        symptoms: const Symptoms(cough: true, coughDurationDays: 3),
        vitals: const Vitals(respiratoryRate: 30),
      );
      expectRule(result, TriageFlag.green, 'CB-COLD');
      expect(result.ruleIds, isNot(contains('CB-FAST-U12')));
    });

    test('cough for 15 days without other cough signs', () {
      final result = run(
        8,
        symptoms: const Symptoms(cough: true, coughDurationDays: 15),
        vitals: const Vitals(respiratoryRate: 30),
      );
      expectRule(result, TriageFlag.green, 'CB-LONG');
      expect(result.ruleIds, isNot(contains('CB-COLD')));
      expect(result.followUpDays, 14);
    });

    test('cough for exactly 14 days is a cold, not the long-cough follow-up', () {
      final result = run(
        8,
        symptoms: const Symptoms(cough: true, coughDurationDays: 14),
        vitals: const Vitals(respiratoryRate: 30),
      );
      expectRule(result, TriageFlag.green, 'CB-COLD');
      expect(result.ruleIds, isNot(contains('CB-LONG')));
    });

    test('diarrhoea for 2 days with no dehydration signs', () {
      expectRule(run(8, symptoms: const Symptoms(diarrhoea: true, diarrhoeaDurationDays: 2)), TriageFlag.green, 'DH-NONE');
    });

    test('fever only at 18 months', () {
      expectRule(run(18, symptoms: const Symptoms(fever: true)), TriageFlag.green, 'FV-SIMPLE');
    });

    test('ear assessed with no pain', () {
      expectRule(run(10, symptoms: const Symptoms(earAssessed: true)), TriageFlag.green, 'EAR-OK');
    });

    test('nothing recorded at 24 months stays green with no rules', () {
      final result = run(24);
      expect(result.flag, TriageFlag.green);
      expect(result.firedRules, isEmpty);
      expect(result.followUpDays, isNull);
    });

    test('age 2 months, respiratory rate 49, is not fast', () {
      final result = run(2, symptoms: const Symptoms(cough: true), vitals: const Vitals(respiratoryRate: 49));
      expect(result.flag, TriageFlag.green);
      expect(result.ruleIds, isNot(contains('CB-FAST-U12')));
    });

    test('age 12 months, respiratory rate 39, is not fast', () {
      final result = run(12, symptoms: const Symptoms(cough: true), vitals: const Vitals(respiratoryRate: 39));
      expect(result.ruleIds, isNot(contains('CB-FAST-12')));
    });

    test('age 11 months, respiratory rate 40, is not fast', () {
      final result = run(11, symptoms: const Symptoms(cough: true), vitals: const Vitals(respiratoryRate: 40));
      expect(result.ruleIds, isNot(contains('CB-FAST-U12')));
      expect(result.ruleIds, isNot(contains('CB-FAST-12')));
    });

    test('age 59 months, respiratory rate 39, is not fast', () {
      final result = run(59, symptoms: const Symptoms(cough: true), vitals: const Vitals(respiratoryRate: 39));
      expect(result.ruleIds, isNot(contains('CB-FAST-12')));
    });

    test('age 60 months is outside the child fast-breathing chart', () {
      final result = run(60, symptoms: const Symptoms(cough: true), vitals: const Vitals(respiratoryRate: 40));
      expect(result.ruleIds, isNot(contains('CB-FAST-12')));
      expect(result.flag, TriageFlag.green);
    });

    test('young infant temperature 37.4 is not the young-infant fever rule', () {
      final result = run(1, vitals: const Vitals(tempC: 37.4));
      expect(result.ruleIds, isNot(contains('FV-YI-TEMP')));
    });
  });

  group('order, modules, referral', () {
    test('a danger sign and chest indrawing both appear, and the flag stays red', () {
      final result = run(8, symptoms: const Symptoms(lethargicOrUnconscious: true, chestIndrawing: true, cough: true));
      expect(result.flag, TriageFlag.red);
      expect(result.ruleIds, ['DS-LETH', 'CB-INDRAW']);
    });

    test('danger signs still run when the caller asks only for the ear module', () {
      final result = run(
        8,
        symptoms: const Symptoms(lethargicOrUnconscious: true, earPain: true),
        modules: const ['ear'],
      );
      expect(result.flag, TriageFlag.red);
      expect(result.ruleIds, containsAll(['DS-LETH', 'EAR-PAIN']));
      expect(result.ruleIds, isNot(contains('CB-COLD')));
    });

    test('fast breathing is not classified when only the ear module is active', () {
      final result = run(
        8,
        symptoms: const Symptoms(cough: true),
        vitals: const Vitals(respiratoryRate: 60),
        modules: const ['ear'],
      );
      expect(result.ruleIds, isNot(contains('CB-FAST-U12')));
    });

    test('referral sms, markdown, and the FHIR bundle', () {
      final result = run(
        8,
        symptoms: const Symptoms(cough: true, chestIndrawing: true, lethargicOrUnconscious: true),
        vitals: const Vitals(respiratoryRate: 68, tempC: 38.2, weightKg: 7.5),
      );
      final note = ReferralNote.fromResult(
        result,
        const PatientProfile(
          id: 'case-1',
          abhaId: '91-0000-0000-0008',
          name: 'Demo child',
          ageMonths: 8,
          sex: 'F',
          village: 'Pimpri',
        ),
        const FacilityProfile(id: 'HFR-PCMC-1', name: 'PCMC UPHC'),
        wardId: 'W3',
        referralId: 'REF8',
        vitals: const Vitals(respiratoryRate: 68, tempC: 38.2, weightKg: 7.5),
        symptoms: const Symptoms(cough: true, chestIndrawing: true, lethargicOrUnconscious: true),
        outbreakContext: '9 dengue-like cases in W3 in the last 2 weeks',
      );
      expect(note.urgency, 'refer URGENTLY');
      expect(note.toSms().length, lessThanOrEqualTo(160));
      expect(note.toSms(), startsWith('REF|REF8|RED|8m|F|RR68|T38.2|'));
      expect(note.toSms(), endsWith('|W3'));
      expect(note.toSms(), isNot(contains('Demo')));
      final markdown = note.toMarkdown();
      expect(markdown, contains('refer URGENTLY'));
      expect(markdown, contains('Lethargic or unconscious.'));
      expect(markdown, contains('Give the first dose of an appropriate antibiotic.'));
      expect(markdown, contains('9 dengue-like cases'));
      final bundle = note.toFhirBundle();
      expect(bundle['resourceType'], 'Bundle');
      final resources = [
        for (final entry in bundle['entry'] as List) (entry as Map)['resource'] as Map,
      ];
      expect(resources.map((item) => item['resourceType']), containsAll(['Patient', 'Encounter', 'Observation', 'Condition']));
      final patient = resources.firstWhere((item) => item['resourceType'] == 'Patient');
      final identifier = (patient['identifier'] as List).first as Map;
      expect(identifier['system'], 'https://healthid.ndhm.gov.in');
      expect(patient['gender'], 'female');
    });

    test('a long rule list still fits in one SMS', () {
      final result = run(
        24,
        symptoms: const Symptoms(
          unableToDrink: true,
          vomitsEverything: true,
          convulsions: true,
          convulsingNow: true,
          lethargicOrUnconscious: true,
          cough: true,
          chestIndrawing: true,
          stridorInCalmChild: true,
          diarrhoea: true,
          bloodInStool: true,
          fever: true,
          stiffNeck: true,
          severeMalaria: true,
          tenderSwellingBehindEar: true,
          visibleSevereWasting: true,
          oedemaBothFeet: true,
          palmarPallor: true,
        ),
        vitals: const Vitals(respiratoryRate: 70, tempC: 40, weightForAgeZscore: -4),
      );
      final note = ReferralNote.fromResult(
        result,
        const PatientProfile(id: 'long-case', abhaId: '91-0000-0000-0024', name: 'Demo child', ageMonths: 24, sex: 'female', village: 'Chinchwad'),
        const FacilityProfile(id: 'HFR', name: 'PCMC UPHC'),
        wardId: 'W3',
        vitals: const Vitals(respiratoryRate: 70, tempC: 40),
      );
      expect(note.toSms().length, lessThanOrEqualTo(160));
      expect(note.toSms(), isNot(contains('Demo')));
      expect(note.toSms(), isNot(contains('Chinchwad')));
    });

    test('the library does not import IO or the network', () {
      final root = Directory('lib');
      final files = root.listSync(recursive: true).whereType<File>().where((file) => file.path.endsWith('.dart'));
      expect(files, isNotEmpty);
      for (final file in files) {
        final text = file.readAsStringSync();
        expect(text, isNot(contains("import 'dart:io'")), reason: file.path);
        expect(text, isNot(contains('package:http')), reason: file.path);
        expect(text, isNot(contains('dart:ffi')), reason: file.path);
      }
    });

    test('two hundred evaluations stay under a millisecond each', () {
      final input = AssessmentInput(
        patientId: 'speed',
        ageMonths: 8,
        sex: 'F',
        vitals: const Vitals(respiratoryRate: 55, tempC: 37),
        symptoms: const Symptoms(cough: true, diarrhoea: true),
      );
      final watch = Stopwatch()..start();
      for (var i = 0; i < 200; i++) {
        engine.evaluate(input);
      }
      watch.stop();
      final meanMicros = watch.elapsedMicroseconds / 200;
      expect(meanMicros, lessThan(1000));
    });
  });
}
