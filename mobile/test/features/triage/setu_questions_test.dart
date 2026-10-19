import 'dart:convert';
import 'dart:io';

import 'package:asha_platform/features/triage/domain/setu_case.dart';
import 'package:asha_platform/features/triage/presentation/setu_questions_screen.dart';
import 'package:asha_platform/features/triage/presentation/triage_assessment_screen.dart';
import 'package:core_triage/core_triage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late RuleSet ruleset;

  setUpAll(() async {
    final file = File('assets/triage/imci-mvp-1.0.0.json');
    ruleset = RuleSet.fromJson((jsonDecode(await file.readAsString()) as Map).cast<String, dynamic>());
  });

  test('a danger sign makes a red Setu referral the QR can carry', () {
    const yes = SourcedValue.guided('YES');
    const no = SourcedValue.guided('NO');
    final fields = <String, SourcedValue>{
      FieldPaths.unableToDrinkOrBreastfeed: no,
      FieldPaths.vomitsEverything: no,
      FieldPaths.convulsionsThisIllness: no,
      FieldPaths.convulsingNow: no,
      FieldPaths.lethargicOrUnconscious: yes,
      FieldPaths.chestIndrawing: no,
      FieldPaths.stridorWhenCalm: no,
      FieldPaths.grunting: no,
      FieldPaths.nasalFlaring: no,
      FieldPaths.severeRespiratoryDistress: no,
      FieldPaths.observedLethargic: no,
      FieldPaths.sunkenEyes: no,
      FieldPaths.drinkingPattern: const SourcedValue.confirmed('NORMAL'),
      FieldPaths.skinPinch: const SourcedValue.confirmed('NORMAL'),
      FieldPaths.stiffNeck: no,
      FieldPaths.oedemaBothFeet: no,
      FieldPaths.visibleSevereWasting: no,
      FieldPaths.cough: no,
      FieldPaths.diarrhoea: no,
      FieldPaths.fever: no,
      FieldPaths.temperatureC: const SourcedValue.measured(37),
      FieldPaths.respiratoryRate: const SourcedValue.measured(30),
      FieldPaths.muacMm: const SourcedValue.measured(130),
    };
    final caseFile = SetuCase(ageMonths: 8, fields: fields);
    final result = caseFile.evaluate(ruleset);
    expect(result.band, TriageBand.red);
    expect(result.firedRules.map((rule) => rule.ruleId), contains('DS-05'));

    final note = caseFile.referral(result, at: DateTime.utc(2026, 1, 1), caseCode: 'CASE-8');
    final qr = jsonDecode(referralQrText(note)) as Map<String, dynamic>;
    expect(qr['band'], 'RED');
    expect(qr['case'], 'CASE-8');
    expect(qr['rule'], 'DS-05');
    expect(qr.containsKey('contact'), isFalse);
    expect(qr.containsKey('phone'), isFalse);
    expect(qr.containsKey('patient_name'), isFalse);
    expect('${qr['header']}', isNot(contains('reachable')));
    expect(note.plainText, contains('DS-05'));
    expect(note.structured['worker'], {'name': 'worker', 'code': 'ASHA', 'contact': null});
  });

  test('an unanswered danger sign does not become a referral colour', () {
    final result = SetuCase(ageMonths: 8).evaluate(ruleset);
    expect(result.band, TriageBand.needsMoreInfo);
    expect(result.band.isDecision, isFalse);
  });

  testWidgets('triage opens the question walk and the voice page', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: TriageAssessmentScreen()),
      ),
    );
    expect(find.byKey(const Key('setu_questions_button')), findsOneWidget);
    expect(find.byKey(const Key('language_bridge_button')), findsOneWidget);
    expect(find.text('They speak / I ask'), findsOneWidget);
  });

  testWidgets('the first Setu question is the drink question', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const MaterialApp(home: SetuQuestionsScreen()));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('setu_age_months')), '8');
    await tester.tap(find.byKey(const Key('start_questions_button')));
    await tester.pump();

    expect(find.text('Can the child drink or breastfeed?'), findsOneWidget);
    expect(find.text('Ward W3'), findsOneWidget);
    expect(find.byKey(const Key('open_language_bridge')), findsOneWidget);
  });
}
