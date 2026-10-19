import 'package:core_triage/core_triage.dart';
import 'package:test/test.dart';

RuleSet _operatorRuleSet() => RuleSet.fromJson({
  'ruleset_id': 'operator-test',
  'ruleset_version': 'test-1',
  'clinical_signoff': {'status': 'PENDING'},
  'rules': [
    {'id': 'EQ', 'category': 'TEST', 'severity': 'RED', 'requires': ['a'], 'when': {'field': 'a', 'op': 'eq', 'value': 'YES'}, 'reason_text': {'en': 'eq'}, 'reason_key': 'eq'},
    {'id': 'NEQ', 'category': 'TEST', 'severity': 'YELLOW', 'requires': ['b'], 'when': {'field': 'b', 'op': 'neq', 'value': 'YES'}, 'reason_text': {'en': 'neq'}, 'reason_key': 'neq'},
    {'id': 'GTE', 'category': 'TEST', 'severity': 'YELLOW', 'requires': ['n'], 'when': {'field': 'n', 'op': 'gte', 'value': 5}, 'reason_text': {'en': 'gte'}, 'reason_key': 'gte'},
    {'id': 'GT', 'category': 'TEST', 'severity': 'YELLOW', 'requires': ['n'], 'when': {'field': 'n', 'op': 'gt', 'value': 4}, 'reason_text': {'en': 'gt'}, 'reason_key': 'gt'},
    {'id': 'LTE', 'category': 'TEST', 'severity': 'YELLOW', 'requires': ['n'], 'when': {'field': 'n', 'op': 'lte', 'value': 5}, 'reason_text': {'en': 'lte'}, 'reason_key': 'lte'},
    {'id': 'LT', 'category': 'TEST', 'severity': 'YELLOW', 'requires': ['n'], 'when': {'field': 'n', 'op': 'lt', 'value': 6}, 'reason_text': {'en': 'lt'}, 'reason_key': 'lt'},
    {'id': 'IN', 'category': 'TEST', 'severity': 'YELLOW', 'requires': ['s'], 'when': {'field': 's', 'op': 'in', 'value': ['A', 'B']}, 'reason_text': {'en': 'in'}, 'reason_key': 'in'},
    {'id': 'KNOWN', 'category': 'TEST', 'severity': 'YELLOW', 'requires': [], 'when': {'field': 'a', 'op': 'known'}, 'reason_text': {'en': 'known'}, 'reason_key': 'known'},
    {'id': 'UNKNOWN', 'category': 'TEST', 'severity': 'YELLOW', 'requires': [], 'when': {'field': 'missing', 'op': 'unknown'}, 'reason_text': {'en': 'unknown'}, 'reason_key': 'unknown'},
    {'id': 'COUNT', 'category': 'TEST', 'severity': 'YELLOW', 'requires': ['x', 'y'], 'when': {'field': '__count__', 'op': 'count_true_at_least', 'value': 2, 'fields': ['x', 'y']}, 'reason_text': {'en': 'count'}, 'reason_key': 'count'},
    {'id': 'COMBINATORS', 'category': 'TEST', 'severity': 'YELLOW', 'requires': ['a', 's', 'n'], 'when': {'all': [{'any': [{'field': 'a', 'op': 'eq', 'value': 'YES'}, {'field': 's', 'op': 'eq', 'value': 'B'}]}, {'not': {'field': 'n', 'op': 'lt', 'value': 1}}]}, 'reason_text': {'en': 'combinators'}, 'reason_key': 'combinators'},
    {'id': 'TABLE', 'category': 'TEST', 'severity': 'YELLOW', 'requires': ['age', 'table_n'], 'when': {'field': 'table_n', 'op': 'gte', 'threshold_table': {'key_field': 'age', 'bands': [{'min': 2, 'max': 11, 'value': 50}, {'min': 12, 'max': 59, 'value': 40}]}}, 'reason_text': {'en': 'table'}, 'reason_key': 'table'},
  ],
});

void main() {
  test('supports the complete Phase 1 operator and combinator set', () {
    final result = TriageEngine.evaluate(
      assessment: ClinicalAssessment(ageMonths: 24, fields: {
        'a': const SourcedValue(value: 'YES', source: ClinicalSource.guidedAnswer),
        'b': const SourcedValue(value: 'NO', source: ClinicalSource.guidedAnswer),
        'n': const SourcedValue(value: 5, source: ClinicalSource.measured),
        'table_n': const SourcedValue(value: 40, source: ClinicalSource.measured),
        's': const SourcedValue(value: 'B', source: ClinicalSource.confirmedByWorker),
        'x': const SourcedValue(value: 'YES', source: ClinicalSource.guidedAnswer),
        'y': const SourcedValue(value: 'YES', source: ClinicalSource.guidedAnswer),
        'age': const SourcedValue(value: 24, source: ClinicalSource.measured),
      }),
      ruleset: _operatorRuleSet(),
    );
    final ids = result.firedRules.map((rule) => rule.ruleId).toSet();
    expect(ids, containsAll(['EQ', 'NEQ', 'GTE', 'GT', 'LTE', 'LT', 'IN', 'KNOWN', 'UNKNOWN', 'COUNT', 'COMBINATORS', 'TABLE']));
  });

  test('invalid ruleset shape fails closed at parse time', () {
    expect(() => RuleSet.fromJson({'ruleset_id': 'bad'}), throwsA(isA<RuleSetParseException>()));
  });

  test('explanation invariant fails closed when a fired reason is empty', () {
    final ruleset = RuleSet.fromJson({
      'ruleset_id': 'bad-reason',
      'ruleset_version': 'test-2',
      'rules': [
        {'id': 'BAD', 'category': 'TEST', 'severity': 'RED', 'requires': ['a'], 'when': {'field': 'a', 'op': 'eq', 'value': 'YES'}, 'reason_text': {'en': ''}, 'reason_key': 'bad'},
      ],
    });
    expect(() => TriageEngine.evaluate(assessment: ClinicalAssessment(ageMonths: 24, fields: {'a': const SourcedValue(value: 'YES', source: ClinicalSource.guidedAnswer)}), ruleset: ruleset), throwsA(isA<EngineInvariantViolation>()));
  });
}
