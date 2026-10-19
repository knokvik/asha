import 'dart:convert';
import 'dart:io';

import 'package:core_triage/core_triage.dart';
import 'package:test/test.dart';

Future<RuleSet> _loadRuleSet() async {
  final file = File('${Directory.current.path}/../../rules/imci-mvp-1.0.0.json');
  return RuleSet.fromJson((jsonDecode(await file.readAsString()) as Map).cast<String, dynamic>());
}

void main() {
  late RuleSet ruleset;
  late List<JsonMap> cases;
  late String casesRulesetVersion;

  setUpAll(() async {
    ruleset = await _loadRuleSet();
    final file = File('${Directory.current.path}/../../docs/clinical/golden-cases.json');
    final json = (jsonDecode(await file.readAsString()) as Map).cast<String, dynamic>();
    casesRulesetVersion = json['ruleset_version'] as String;
    cases = (json['cases'] as List).map((item) => (item as Map).cast<String, dynamic>()).toList(growable: false);
  });

  test('ruleset parses without duplicate IDs and has a pending signoff', () {
    expect(ruleset.version, 'imci-mvp-1.0.0');
    expect(casesRulesetVersion, ruleset.version);
    expect(ruleset.rules.map((rule) => rule.id).toSet(), hasLength(ruleset.rules.length));
    expect(ruleset.clinicalSignoffStatus, 'PENDING');
  });

  test('all golden clinical cases match expected bands and explanations', () {
    expect(cases, hasLength(60));
    for (final golden in cases) {
      final input = (golden['input'] as Map).cast<String, dynamic>();
      final expected = (golden['expect'] as Map).cast<String, dynamic>();
      final result = TriageEngine.evaluate(assessment: ClinicalAssessment.fromJson(input), ruleset: ruleset);
      final actualIds = result.firedRules.map((rule) => rule.ruleId).toSet();
      expect(result.band.wireName, expected['band'], reason: golden['case_id'] as String);
      expect(result.hasExplanation, isTrue, reason: golden['case_id'] as String);
      for (final ruleId in (expected['must_include_rules'] as List<dynamic>? ?? const [])) {
        expect(actualIds, contains(ruleId), reason: '${golden['case_id']}: missing $ruleId');
      }
      for (final ruleId in (expected['must_not_include_rules'] as List<dynamic>? ?? const [])) {
        expect(actualIds, isNot(contains(ruleId)), reason: '${golden['case_id']}: unexpected $ruleId');
      }
    }
  });

  test('every non-composite clinical rule fires in at least one golden case', () {
    final covered = <String>{};
    final absent = <String>{};
    for (final golden in cases) {
      final result = TriageEngine.evaluate(assessment: ClinicalAssessment.fromJson((golden['input'] as Map).cast<String, dynamic>()), ruleset: ruleset);
      final fired = result.firedRules.map((rule) => rule.ruleId).toSet();
      covered.addAll(fired);
      absent.addAll(ruleset.rules.where((rule) => !fired.contains(rule.id)).map((rule) => rule.id));
    }
    for (final rule in ruleset.rules.where((rule) => rule.composite == null)) {
      expect(covered, contains(rule.id), reason: 'No golden case fires ${rule.id}');
      expect(absent, contains(rule.id), reason: 'No golden near-miss/silent case covers ${rule.id}');
    }
  });

  test('extracted-unconfirmed values cannot influence the band', () {
    final fields = <String, SourcedValue>{
      'danger_signs.unable_to_drink_or_breastfeed': const SourcedValue(value: 'YES', source: ClinicalSource.extractedUnconfirmed),
    };
    final result = TriageEngine.evaluate(assessment: ClinicalAssessment(ageMonths: 24, fields: fields), ruleset: ruleset);
    expect(result.band, TriageBand.needsMoreInfo);
    expect(result.firedRules.map((rule) => rule.ruleId), isNot(contains('DS-01')));
  });

  test('worker escalation can only raise to RED', () {
    final result = TriageEngine.evaluate(assessment: ClinicalAssessment(ageMonths: 24, workerOverride: const WorkerOverride(escalateToRed: true)), ruleset: ruleset);
    expect(result.band, TriageBand.red);
    expect(result.escalatedByWorker, isTrue);
    expect(result.firedRules.map((rule) => rule.ruleId), contains('CMP-02'));
  });
}
