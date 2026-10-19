import 'package:core_model/core_model.dart';
import 'ruleset.dart';

class EngineInvariantViolation implements Exception {
  const EngineInvariantViolation(this.message);
  final String message;
  @override
  String toString() => 'EngineInvariantViolation: $message';
}

class TriageEngine {
  // Static-only façade: the private constructor exists to prevent
  // instantiation and is never executed.
  const TriageEngine._(); // coverage:ignore-line

  static const version = '1.0.0';

  /// Pure clinical evaluation. No I/O, clock, randomness, Flutter, or network.
  static ClinicalTriageResult evaluate({
    required ClinicalAssessment assessment,
    required RuleSet ruleset,
    String locale = 'en',
  }) {
    if (assessment.ageMonths < 2 || assessment.ageMonths >= 60) {
      return ClinicalTriageResult(
        band: TriageBand.outOfScope,
        firedRules: [
          _syntheticRule(
            id: 'SCOPE-001',
            severity: RuleSeverity.red,
            category: 'SCOPE',
            reasonKey: 'reason.out_of_scope',
            reasonText: _scopeReason(locale),
            adviceKey: 'advice.out_of_scope',
          ),
        ],
        blockingQuestions: const [],
        flooredBy: const [],
        escalatedByWorker: false,
        adviceKey: 'advice.out_of_scope',
        rulesetVersion: ruleset.version,
        engineVersion: version,
      );
    }

    final evaluations = <_RuleEvaluation>[];
    for (final rule in ruleset.rules) {
      if (rule.composite != null) continue;
      evaluations.add(_evaluateRule(rule, assessment));
    }

    final fired = evaluations
        .where((evaluation) => evaluation.status == _RuleStatus.fired)
        .map((evaluation) => _toFiredRule(evaluation.rule, assessment, locale))
        .toList();
    final redIndeterminate = evaluations
        .where(
          (evaluation) =>
              evaluation.rule.severity == RuleSeverity.red &&
              evaluation.status == _RuleStatus.indeterminate,
        )
        .toList();
    // SI-4: a worker escalation is always honoured, even when other data is
    // incomplete. Escalation is the only override direction permitted.
    if (assessment.workerOverride.escalateToRed) {
      fired.add(
        _syntheticRule(
          id: 'CMP-02',
          severity: RuleSeverity.red,
          category: 'COMPOSITE',
          reasonKey: 'reason.worker_escalation',
          reasonText: _workerEscalationReason(locale),
          adviceKey: 'advice.red.urgent_referral',
        ),
      );
      fired.sort(_firedRuleCompare);
      return ClinicalTriageResult(
        band: TriageBand.red,
        firedRules: List.unmodifiable(fired),
        blockingQuestions: const [],
        flooredBy: const [],
        escalatedByWorker: true,
        adviceKey: 'advice.red.urgent_referral',
        rulesetVersion: ruleset.version,
        engineVersion: version,
      );
    }
    final redUnknownBlockers = redIndeterminate
        .where(
          (evaluation) =>
              evaluation.unknownFields.isNotEmpty &&
              evaluation.unobtainableFields.isEmpty,
        )
        .toList();
    if (redUnknownBlockers.isNotEmpty) {
      final blockingQuestions = <String>{
        for (final evaluation in redUnknownBlockers)
          ...evaluation.unknownFields,
      }.toList()..sort();
      final blockingRules = redUnknownBlockers.map(
        (evaluation) => _syntheticRule(
          id: 'BLOCKING-${evaluation.rule.id}',
          severity: RuleSeverity.yellow,
          category: 'MISSING_DATA',
          reasonKey: 'reason.missing_data',
          reasonText: _missingDataReason(locale, blockingQuestions),
          adviceKey: 'advice.needs_more_info',
        ),
      );
      return ClinicalTriageResult(
        band: TriageBand.needsMoreInfo,
        firedRules: [...blockingRules, ...fired],
        blockingQuestions: blockingQuestions,
        flooredBy: const [],
        escalatedByWorker: false,
        adviceKey: 'advice.needs_more_info',
        rulesetVersion: ruleset.version,
        engineVersion: version,
      );
    }

    final unobtainableFloors = <String>{
      for (final evaluation in redIndeterminate)
        ...evaluation.unobtainableFields,
    }.toList()..sort();
    final compositeFired = <FiredRule>[];
    final yellowCount = fired
        .where((rule) => rule.severity == RuleSeverity.yellow)
        .length;
    for (final rule in ruleset.rules.where((rule) => rule.composite != null)) {
      final trigger = rule.composite!;
      final shouldFire = switch (trigger.type) {
        'yellow_count_at_least' => yellowCount >= trigger.threshold,
        'followup_red_not_improved' =>
          assessment.previousBand == 'RED' &&
              assessment.symptomsImproved == false,
        _ => false,
      };
      if (shouldFire)
        compositeFired.add(_toFiredRule(rule, assessment, locale));
    }
    fired.addAll(compositeFired);

    var band = _maxBand(fired.map((rule) => rule.severity));
    if (unobtainableFloors.isNotEmpty && band.rank < TriageBand.yellow.rank)
      band = TriageBand.yellow;
    const escalatedByWorker = false;
    if (fired.isEmpty) {
      fired.add(
        _syntheticRule(
          id: 'GREEN-001',
          severity: RuleSeverity.green,
          category: 'BASELINE',
          reasonKey: 'reason.no_flagged_findings',
          reasonText: _greenReason(locale),
          adviceKey: 'advice.green.routine_followup',
        ),
      );
    }
    fired.sort(_firedRuleCompare);
    if (fired.isEmpty || fired.any((rule) => rule.reasonText.trim().isEmpty)) {
      throw const EngineInvariantViolation(
        'Triage result has no complete human-readable explanation',
      );
    }

    final adviceKey = band == TriageBand.red
        ? 'advice.red.urgent_referral'
        : band == TriageBand.yellow
        ? 'advice.yellow.prompt_phc'
        : 'advice.green.routine_followup';
    return ClinicalTriageResult(
      band: band,
      firedRules: List.unmodifiable(fired),
      blockingQuestions: const [],
      flooredBy: List.unmodifiable(unobtainableFloors),
      escalatedByWorker: escalatedByWorker,
      adviceKey: adviceKey,
      rulesetVersion: ruleset.version,
      engineVersion: version,
    );
  }

  static _RuleEvaluation _evaluateRule(
    RuleDefinition rule,
    ClinicalAssessment assessment,
  ) {
    final unknown = <String>[];
    final unobtainable = <String>[];
    for (final field in rule.requires) {
      final sourced = assessment.valueAt(field);
      if (sourced.isUnobtainable) {
        unobtainable.add(field);
      } else if (sourced.isUnknown) {
        unknown.add(field);
      }
    }
    final outcome = _evaluateCondition(rule.when, assessment);

    // A rule whose condition is *provably* false cannot fire under any value
    // of its missing inputs, so it is NOT_FIRED rather than INDETERMINATE.
    //
    // This matters in practice: DIA-01 requires four dehydration observations,
    // but when `symptoms.diarrhoea` is NO the conjunction is already false.
    // Without this check the engine would block on NEEDS_MORE_INFO and demand
    // four irrelevant answers for every child who does not have diarrhoea.
    //
    // Safety is preserved because three-valued logic only reports FALSE when
    // some conjunct is definitively false; anything that could still turn out
    // true evaluates to UNKNOWN and falls through to INDETERMINATE below (SI-3).
    if (outcome == _ConditionTruth.falseValue) {
      return _RuleEvaluation(rule, _RuleStatus.notFired, const [], const []);
    }

    if (unknown.isNotEmpty || unobtainable.isNotEmpty) {
      return _RuleEvaluation(
        rule,
        _RuleStatus.indeterminate,
        unknown,
        unobtainable,
      );
    }

    return _RuleEvaluation(
      rule,
      outcome == _ConditionTruth.trueValue
          ? _RuleStatus.fired
          : _RuleStatus.notFired,
      const [],
      const [],
    );
  }

  static _ConditionTruth _evaluateCondition(
    ConditionNode node,
    ClinicalAssessment assessment,
  ) {
    if (node is AllCondition) {
      var sawUnknown = false;
      for (final child in node.children) {
        final result = _evaluateCondition(child, assessment);
        if (result == _ConditionTruth.falseValue)
          return _ConditionTruth.falseValue;
        if (result == _ConditionTruth.unknownValue) sawUnknown = true;
      }
      return sawUnknown
          ? _ConditionTruth.unknownValue
          : _ConditionTruth.trueValue;
    }
    if (node is AnyCondition) {
      var sawUnknown = false;
      for (final child in node.children) {
        final result = _evaluateCondition(child, assessment);
        if (result == _ConditionTruth.trueValue)
          return _ConditionTruth.trueValue;
        if (result == _ConditionTruth.unknownValue) sawUnknown = true;
      }
      return sawUnknown
          ? _ConditionTruth.unknownValue
          : _ConditionTruth.falseValue;
    }
    if (node is NotCondition) {
      final result = _evaluateCondition(node.child, assessment);
      return switch (result) {
        _ConditionTruth.trueValue => _ConditionTruth.falseValue,
        _ConditionTruth.falseValue => _ConditionTruth.trueValue,
        _ConditionTruth.unknownValue => _ConditionTruth.unknownValue,
      };
    }
    final predicate = node as PredicateCondition;
    final sourced = assessment.valueAt(predicate.field);
    final projected = sourced.projectedValue;
    if (predicate.operator == 'unknown')
      return sourced.isUnknown
          ? _ConditionTruth.trueValue
          : _ConditionTruth.falseValue;
    if (predicate.operator == 'known')
      return sourced.isKnown
          ? _ConditionTruth.trueValue
          : _ConditionTruth.falseValue;
    if (predicate.operator == 'count_true_at_least') {
      final fields = predicate.countFields ?? const <String>[];
      final fieldCount = fields
          .where((field) => _isTrue(assessment.valueAt(field).projectedValue))
          .length;
      final conditionCount =
          (predicate.countConditions ?? const <ConditionNode>[])
              .where(
                (condition) =>
                    _evaluateCondition(condition, assessment) ==
                    _ConditionTruth.trueValue,
              )
              .length;
      final count = fieldCount + conditionCount;
      return count >= ((predicate.value as num?)?.toInt() ?? 0)
          ? _ConditionTruth.trueValue
          : _ConditionTruth.falseValue;
    }
    if (projected is UnknownValue || projected is UnobtainableValue)
      return _ConditionTruth.unknownValue;
    Object? expected = predicate.value;
    if (predicate.thresholdTable != null) {
      final key = assessment
          .valueAt(predicate.thresholdTable!.keyField)
          .projectedValue;
      if (key is! num) return _ConditionTruth.unknownValue;
      final match = predicate.thresholdTable!.bands
          .where((band) => key >= band.min && key <= band.max)
          .firstOrNull;
      if (match == null) return _ConditionTruth.unknownValue;
      expected = match.value;
    }
    final result = switch (predicate.operator) {
      'eq' => _equals(projected, expected),
      'neq' => !_equals(projected, expected),
      'gte' => _numericCompare(
        projected,
        expected,
        (left, right) => left >= right,
      ),
      'gt' => _numericCompare(
        projected,
        expected,
        (left, right) => left > right,
      ),
      'lte' => _numericCompare(
        projected,
        expected,
        (left, right) => left <= right,
      ),
      'lt' => _numericCompare(
        projected,
        expected,
        (left, right) => left < right,
      ),
      'in' =>
        (predicate.values ??
                (predicate.value is List
                    ? (predicate.value as List).cast<Object?>()
                    : const <Object?>[]))
            .any((value) => _equals(projected, value)),
      _ => throw EngineInvariantViolation(
        'Unsupported operator: ${predicate.operator}',
      ),
    };
    return result ? _ConditionTruth.trueValue : _ConditionTruth.falseValue;
  }

  static bool _isTrue(Object? value) =>
      value == true || value == 'YES' || value == 'TRUE';
  static bool _equals(Object? left, Object? right) =>
      left.toString().toUpperCase() == right.toString().toUpperCase();
  static bool _numericCompare(
    Object? left,
    Object? right,
    bool Function(num left, num right) compare,
  ) {
    final leftNumber = _numberOrNull(left);
    final rightNumber = _numberOrNull(right);
    return leftNumber != null &&
        rightNumber != null &&
        compare(leftNumber, rightNumber);
  }

  static num? _numberOrNull(Object? value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }

  static FiredRule _toFiredRule(
    RuleDefinition rule,
    ClinicalAssessment assessment,
    String locale,
  ) {
    final reason =
        rule.reasonText[locale] ?? rule.reasonText['en'] ?? rule.reasonKey;
    final evidence = <String, Object?>{};
    for (final field in rule.evidenceFields) {
      evidence[field] = assessment.valueAt(field).value;
    }
    return FiredRule(
      ruleId: rule.id,
      severity: rule.severity,
      category: rule.category,
      reasonKey: rule.reasonKey,
      reasonText: _interpolate(reason, evidence),
      evidence: evidence,
      sourceRef: rule.sourceRef,
    );
  }

  static String _interpolate(String text, Map<String, Object?> evidence) =>
      text.replaceAllMapped(
        RegExp(r'\{([^}]+)\}'),
        (match) => '${evidence[match.group(1)] ?? match.group(0)}',
      );
  static FiredRule _syntheticRule({
    required String id,
    required RuleSeverity severity,
    required String category,
    required String reasonKey,
    required String reasonText,
    required String adviceKey,
  }) => FiredRule(
    ruleId: id,
    severity: severity,
    category: category,
    reasonKey: reasonKey,
    reasonText: reasonText,
    evidence: const {},
    sourceRef: null,
  );
  static int _firedRuleCompare(FiredRule a, FiredRule b) =>
      b.severity.rank != a.severity.rank
      ? b.severity.rank.compareTo(a.severity.rank)
      : a.category != b.category
      ? a.category.compareTo(b.category)
      : a.ruleId.compareTo(b.ruleId);
  static TriageBand _maxBand(Iterable<RuleSeverity> severities) {
    final rank = severities.fold(
      0,
      (current, severity) => severity.rank > current ? severity.rank : current,
    );
    return switch (rank) {
      3 => TriageBand.red,
      2 => TriageBand.yellow,
      _ => TriageBand.green,
    };
  }

  static String _scopeReason(String locale) => locale == 'mr'
      ? 'वय २ ते ५९ महिन्यांच्या कक्षेबाहेर आहे; PHC शी संपर्क करा.'
      : locale == 'hi'
      ? 'आयु २ से ५९ महीने के दायरे से बाहर है; PHC से संपर्क करें।'
      : 'Age is outside the 2–59 month scope; contact the PHC.';
  static String _workerEscalationReason(String locale) => locale == 'mr'
      ? 'ASHA कार्यकर्त्याने काळजी व्यक्त करून तातडीची रेफरल निवडली.'
      : locale == 'hi'
      ? 'ASHA कार्यकर्ता ने चिंता व्यक्त की और तत्काल रेफरल चुना।'
      : 'The ASHA worker is worried and chose urgent referral.';
  static String _greenReason(String locale) => locale == 'mr'
      ? 'नोंदवलेल्या तपासणीत कोणतीही धोक्याची खूण आढळली नाही.'
      : locale == 'hi'
      ? 'दर्ज की गई जांच में कोई खतरे का संकेत नहीं मिला।'
      : 'No flagged danger finding was recorded in the completed assessment.';
  static String _missingDataReason(String locale, List<String> questions) =>
      locale == 'mr'
      ? 'सुरक्षित ट्रायेज निकाल दाखवण्यापूर्वी अधिक माहिती आवश्यक आहे: ${questions.join(', ')}.'
      : locale == 'hi'
      ? 'सुरक्षित ट्रायेज नतीजा दिखाने से पहले अधिक जानकारी चाहिए: ${questions.join(', ')}.'
      : 'More information is needed before a safe triage band can be shown: ${questions.join(', ')}.';
}

enum _RuleStatus { fired, notFired, indeterminate }

enum _ConditionTruth { trueValue, falseValue, unknownValue }

class _RuleEvaluation {
  const _RuleEvaluation(
    this.rule,
    this.status,
    this.unknownFields,
    this.unobtainableFields,
  );
  final RuleDefinition rule;
  final _RuleStatus status;
  final List<String> unknownFields;
  final List<String> unobtainableFields;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
