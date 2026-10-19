import 'package:core_triage/core_triage.dart';
import 'package:test/test.dart';

RuleSet _ruleSet(List<JsonMap> rules) => RuleSet.fromJson({
  'ruleset_id': 'invariant-test',
  'ruleset_version': 'test-invariants',
  'rules': rules,
});

ClinicalAssessment _assessment(Map<String, SourcedValue> fields, {int ageMonths = 24}) =>
    ClinicalAssessment(ageMonths: ageMonths, fields: fields);

void main() {
  group('operator contract', () {
    test('an operator outside the frozen §10.2 set is an engine error, not a silent false', () {
      final ruleset = _ruleSet([
        {
          'id': 'BAD-OP',
          'category': 'TEST',
          'severity': 'RED',
          'requires': ['a'],
          'when': {'field': 'a', 'op': 'matches_regex', 'value': '.*'},
          'reason_text': {'en': 'bad operator'},
          'reason_key': 'bad',
        },
      ]);

      expect(
        () => TriageEngine.evaluate(
          assessment: _assessment({'a': const SourcedValue.guided('YES')}),
          ruleset: ruleset,
        ),
        throwsA(isA<EngineInvariantViolation>()),
      );
    });

    test('numeric comparison coerces string-encoded measurements', () {
      final ruleset = _ruleSet([
        {
          'id': 'NUM',
          'category': 'TEST',
          'severity': 'YELLOW',
          'requires': ['vitals.temperature_c'],
          'when': {'field': 'vitals.temperature_c', 'op': 'gte', 'value': 38.5},
          'reason_text': {'en': 'high temperature'},
          'reason_key': 'temp',
        },
      ]);

      // A value that arrived as text (e.g. from a form field) must compare
      // identically to the same value as a double.
      final asText = TriageEngine.evaluate(
        assessment: _assessment({'vitals.temperature_c': const SourcedValue.measured('38.7')}),
        ruleset: ruleset,
      );
      final asNumber = TriageEngine.evaluate(
        assessment: _assessment({'vitals.temperature_c': const SourcedValue.measured(38.7)}),
        ruleset: ruleset,
      );

      expect(asText.band, TriageBand.yellow);
      expect(asNumber.band, TriageBand.yellow);
      expect(asText.firedRules.map((r) => r.ruleId), asNumber.firedRules.map((r) => r.ruleId));
    });

    test('a non-numeric value never satisfies a numeric comparison', () {
      final ruleset = _ruleSet([
        {
          'id': 'NUM',
          'category': 'TEST',
          'severity': 'RED',
          'requires': ['vitals.respiratory_rate'],
          'when': {'field': 'vitals.respiratory_rate', 'op': 'gte', 'value': 40},
          'reason_text': {'en': 'fast breathing'},
          'reason_key': 'rr',
        },
      ]);

      final result = TriageEngine.evaluate(
        assessment: _assessment({'vitals.respiratory_rate': const SourcedValue.measured('not-a-number')}),
        ruleset: ruleset,
      );

      expect(result.firedRules.map((r) => r.ruleId), isNot(contains('NUM')));
    });
  });

  group('ruleset parse contract', () {
    test('a RED rule with neither requires nor a composite is rejected', () {
      expect(
        () => _ruleSet([
          {
            'id': 'UNGROUNDED-RED',
            'category': 'TEST',
            'severity': 'RED',
            'requires': <String>[],
            'when': {'field': 'a', 'op': 'eq', 'value': 'YES'},
            'reason_text': {'en': 'ungrounded'},
            'reason_key': 'ungrounded',
          },
        ]),
        throwsA(isA<RuleSetParseException>()),
      );
    });

    test('duplicate rule ids are rejected', () {
      JsonMap rule(String id) => {
        'id': id,
        'category': 'TEST',
        'severity': 'YELLOW',
        'requires': ['a'],
        'when': {'field': 'a', 'op': 'eq', 'value': 'YES'},
        'reason_text': {'en': 'dupe'},
        'reason_key': 'dupe',
      };
      expect(() => _ruleSet([rule('SAME'), rule('SAME')]), throwsA(isA<RuleSetParseException>()));
    });

    test('an unparseable condition node is rejected', () {
      expect(
        () => _ruleSet([
          {
            'id': 'BAD-NODE',
            'category': 'TEST',
            'severity': 'YELLOW',
            'requires': ['a'],
            'when': {'nonsense': true},
            'reason_text': {'en': 'bad'},
            'reason_key': 'bad',
          },
        ]),
        throwsA(isA<RuleSetParseException>()),
      );
    });

    test('a rule missing required keys is rejected', () {
      expect(
        () => _ruleSet([
          {'id': 'NO-WHEN', 'category': 'TEST', 'severity': 'YELLOW'},
        ]),
        throwsA(isA<RuleSetParseException>()),
      );
    });

    test('ruleById resolves known ids and returns null for unknown ones', () {
      final ruleset = _ruleSet([
        {
          'id': 'FINDABLE',
          'category': 'TEST',
          'severity': 'YELLOW',
          'requires': ['a'],
          'when': {'field': 'a', 'op': 'eq', 'value': 'YES'},
          'reason_text': {'en': 'findable'},
          'reason_key': 'findable',
        },
      ]);

      expect(ruleset.ruleById('FINDABLE')?.id, 'FINDABLE');
      expect(ruleset.ruleById('MISSING'), isNull);
    });

    test('exceptions carry a readable message for the crash log', () {
      expect(
        const RuleSetParseException('bad shape').toString(),
        contains('bad shape'),
      );
      expect(
        const EngineInvariantViolation('no explanation').toString(),
        contains('no explanation'),
      );
    });
  });

  group('§10.3 step order', () {
    test('scope check short-circuits before any rule is evaluated (SI-6)', () {
      final ruleset = _ruleSet([
        {
          'id': 'WOULD-FIRE',
          'category': 'TEST',
          'severity': 'RED',
          'requires': ['a'],
          'when': {'field': 'a', 'op': 'eq', 'value': 'YES'},
          'reason_text': {'en': 'would fire'},
          'reason_key': 'would',
        },
      ]);
      final fields = {'a': const SourcedValue.guided('YES')};

      for (final age in [1, 0, 60, 72]) {
        final result = TriageEngine.evaluate(assessment: _assessment(fields, ageMonths: age), ruleset: ruleset);
        expect(result.band, TriageBand.outOfScope, reason: 'age $age months');
        expect(result.firedRules.single.ruleId, 'SCOPE-001', reason: 'age $age months');
      }

      // Boundaries are in scope: 2 months and 59 months.
      for (final age in [2, 59]) {
        final result = TriageEngine.evaluate(assessment: _assessment(fields, ageMonths: age), ruleset: ruleset);
        expect(result.band, TriageBand.red, reason: 'age $age months');
      }
    });

    test('the engine is a pure function — repeated evaluation is byte-identical (SI-1)', () {
      final ruleset = _ruleSet([
        {
          'id': 'STABLE',
          'category': 'TEST',
          'severity': 'YELLOW',
          'requires': ['a'],
          'when': {'field': 'a', 'op': 'eq', 'value': 'YES'},
          'reason_text': {'en': 'stable'},
          'reason_key': 'stable',
        },
      ]);
      final assessment = _assessment({'a': const SourcedValue.guided('YES')});

      final first = TriageEngine.evaluate(assessment: assessment, ruleset: ruleset).toJson().toString();
      final second = TriageEngine.evaluate(assessment: assessment, ruleset: ruleset).toJson().toString();
      expect(second, first);
    });
  });
}
