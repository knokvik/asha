import 'catalog.dart';
import 'conditions.dart';
import 'models.dart';

/// What [ImciEngine.evaluate] returns. The hybrid layer wraps this later.
typedef EngineResult = TriageResult;

/// Deterministic IMCI / IMNCI classifier. No I/O and no clock.
class ImciEngine {
  const ImciEngine(this.catalog);

  final ImciCatalog catalog;

  EngineResult evaluate(AssessmentInput input) {
    final fields = input.toFields();
    final known = <String>{for (final rule in catalog.rules) rule.module};
    final requested = input.context.activeModules.where(known.contains).toSet();
    final fired = <FiredRule>[];

    for (final rule in catalog.rules) {
      // Outbreak ids are not chart modules. They must not switch the chart off.
      // An explicit chart module list still limits which chart modules run.
      if (requested.isNotEmpty && rule.module != 'danger_signs' && !requested.contains(rule.module)) {
        continue;
      }
      if (!matchesCondition(rule.conditions, fields)) continue;
      fired.add(FiredRule(
        ruleId: rule.ruleId,
        module: rule.module,
        severity: rule.severity,
        reasonText: rule.reasonText,
        guidelineRef: rule.guidelineRef,
        suspectedDisease: rule.suspectedDisease,
        actions: rule.actions,
        followUpDays: rule.followUpDays,
      ));
    }

    var flag = TriageFlag.green;
    FiredRule? winner;
    for (final rule in fired) {
      if (winner == null || rule.severity.rank > winner.severity.rank) {
        winner = rule;
        flag = rule.severity;
      }
    }

    return TriageResult(
      flag: flag,
      firedRules: List.unmodifiable(fired),
      followUpDays: winner?.followUpDays,
    );
  }
}
