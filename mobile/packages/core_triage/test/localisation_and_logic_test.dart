import 'package:core_triage/core_triage.dart';
import 'package:test/test.dart';

RuleSet _ruleSet(List<JsonMap> rules) => RuleSet.fromJson({
  'ruleset_id': 'locale-test',
  'ruleset_version': 'test-locale',
  'rules': rules,
});

JsonMap _redRule({required String id, required String field}) => {
  'id': id,
  'category': 'TEST',
  'severity': 'RED',
  'requires': [field],
  'when': {'field': field, 'op': 'eq', 'value': 'YES'},
  'reason_text': {'en': 'red reason', 'hi': 'लाल कारण', 'mr': 'लाल कारण'},
  'reason_key': 'red',
};

void main() {
  group('three-valued logic', () {
    test('NOT over an unknown value stays unknown — negating ignorance is not knowledge', () {
      // `requires` is empty, so the rule is not gated by the indeterminacy
      // check: the UNKNOWN has to propagate through `not` on its own.
      final ruleset = _ruleSet([
        {
          'id': 'NOT-UNKNOWN',
          'category': 'TEST',
          'severity': 'YELLOW',
          'requires': <String>[],
          'when': {
            'not': {'field': 'observations.never_asked', 'op': 'eq', 'value': 'YES'},
          },
          'reason_text': {'en': 'not-unknown'},
          'reason_key': 'not',
        },
      ]);

      final result = TriageEngine.evaluate(
        assessment: ClinicalAssessment(ageMonths: 24),
        ruleset: ruleset,
      );

      // If NOT had inverted UNKNOWN to TRUE, this rule would have fired and the
      // band would be YELLOW on the strength of a question nobody answered.
      expect(result.firedRules.map((rule) => rule.ruleId), isNot(contains('NOT-UNKNOWN')));
      expect(result.band, TriageBand.green);
    });

    test('NOT still inverts known values', () {
      final ruleset = _ruleSet([
        {
          'id': 'NOT-KNOWN',
          'category': 'TEST',
          'severity': 'YELLOW',
          'requires': ['observations.stiff_neck'],
          'when': {
            'not': {'field': 'observations.stiff_neck', 'op': 'eq', 'value': 'YES'},
          },
          'reason_text': {'en': 'no stiff neck'},
          'reason_key': 'not',
        },
      ]);

      final result = TriageEngine.evaluate(
        assessment: ClinicalAssessment(
          ageMonths: 24,
          fields: {'observations.stiff_neck': const SourcedValue.guided('NO')},
        ),
        ruleset: ruleset,
      );

      expect(result.firedRules.map((rule) => rule.ruleId), contains('NOT-KNOWN'));
    });
  });

  group('localised explanations (SI-2 — in the worker\'s language)', () {
    final ruleset = _ruleSet([_redRule(id: 'RED-1', field: 'danger_signs.convulsing_now')]);

    test('out-of-scope reason is localised in every shipped language', () {
      final reasons = <String, String>{};
      for (final locale in const ['en', 'hi', 'mr']) {
        final result = TriageEngine.evaluate(
          assessment: ClinicalAssessment(ageMonths: 1),
          ruleset: ruleset,
          locale: locale,
        );
        expect(result.band, TriageBand.outOfScope);
        reasons[locale] = result.firedRules.single.reasonText;
        expect(reasons[locale], isNotEmpty);
      }
      expect(reasons.values.toSet(), hasLength(3), reason: 'each locale must have its own wording');
    });

    test('missing-data reason is localised and names the blocking questions (SI-3)', () {
      final reasons = <String, String>{};
      for (final locale in const ['en', 'hi', 'mr']) {
        final result = TriageEngine.evaluate(
          assessment: ClinicalAssessment(ageMonths: 24),
          ruleset: ruleset,
          locale: locale,
        );
        expect(result.band, TriageBand.needsMoreInfo);
        expect(result.blockingQuestions, ['danger_signs.convulsing_now']);
        final text = result.firedRules.first.reasonText;
        reasons[locale] = text;
        expect(text, contains('danger_signs.convulsing_now'),
            reason: 'the worker must be told exactly what to go ask');
      }
      expect(reasons.values.toSet(), hasLength(3));
    });

    test('worker-escalation reason is localised (SI-4)', () {
      final reasons = <String, String>{};
      for (final locale in const ['en', 'hi', 'mr']) {
        final result = TriageEngine.evaluate(
          assessment: ClinicalAssessment(
            ageMonths: 24,
            workerOverride: const WorkerOverride(escalateToRed: true, note: 'she looks very unwell'),
          ),
          ruleset: ruleset,
          locale: locale,
        );
        expect(result.band, TriageBand.red);
        expect(result.escalatedByWorker, isTrue);
        reasons[locale] = result.firedRules.firstWhere((rule) => rule.ruleId == 'CMP-02').reasonText;
      }
      expect(reasons.values.toSet(), hasLength(3));
    });

    test('green baseline reason is localised', () {
      final ruleset = _ruleSet([
        {
          'id': 'SILENT',
          'category': 'TEST',
          'severity': 'YELLOW',
          'requires': ['symptoms.fever'],
          'when': {'field': 'symptoms.fever', 'op': 'eq', 'value': 'YES'},
          'reason_text': {'en': 'fever'},
          'reason_key': 'fever',
        },
      ]);
      final reasons = <String, String>{};
      for (final locale in const ['en', 'hi', 'mr']) {
        final result = TriageEngine.evaluate(
          assessment: ClinicalAssessment(
            ageMonths: 24,
            fields: {'symptoms.fever': const SourcedValue.guided('NO')},
          ),
          ruleset: ruleset,
          locale: locale,
        );
        expect(result.band, TriageBand.green);
        reasons[locale] = result.firedRules.single.reasonText;
      }
      expect(reasons.values.toSet(), hasLength(3));
    });

    test('an unshipped locale falls back to English rather than showing a key', () {
      final result = TriageEngine.evaluate(
        assessment: ClinicalAssessment(
          ageMonths: 24,
          fields: {'danger_signs.convulsing_now': const SourcedValue.guided('YES')},
        ),
        ruleset: ruleset,
        locale: 'ta',
      );
      expect(result.firedRules.first.reasonText, 'red reason');
    });
  });
}
