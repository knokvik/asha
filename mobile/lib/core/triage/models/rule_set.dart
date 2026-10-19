import 'age_band.dart';
import 'condition.dart';
import 'triage_flag.dart';
import 'triage_rule.dart';

/// Embedded verification test case for rule set governance.
class TestCase {
  final String testId;
  final Map<String, dynamic> inputs;
  final TriageFlag expectedFlag;
  final String description;

  const TestCase({
    required this.testId,
    required this.inputs,
    required this.expectedFlag,
    required this.description,
  });

  factory TestCase.fromJson(Map<String, dynamic> json) => TestCase(
        testId: json['test_id'] as String? ?? json['testId'] as String? ?? '',
        inputs: Map<String, dynamic>.from(json['inputs'] as Map? ?? {}),
        expectedFlag: TriageFlag.fromString(
          json['expected_flag'] as String? ?? json['expectedFlag'] as String?,
        ),
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'test_id': testId,
        'inputs': inputs,
        'expected_flag': expectedFlag.label,
        'description': description,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestCase &&
          runtimeType == other.runtimeType &&
          testId == other.testId &&
          expectedFlag == other.expectedFlag &&
          description == other.description &&
          _mapEquals(inputs, other.inputs);

  @override
  int get hashCode => Object.hash(
        testId,
        expectedFlag,
        description,
        Object.hashAll(inputs.entries.map((e) => Object.hash(e.key, e.value))),
      );

  static bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}

/// Versioned triage rule set package.
class RuleSet {
  final String id;
  final String versionString;
  final int publishedAt;
  final String clinicalLeadId;
  final String approvalSignature;
  final String bundleHash;
  final List<AgeBand> ageBands;
  final List<TriageRule> rules;
  final List<TestCase> testSuite;

  const RuleSet({
    required this.id,
    required this.versionString,
    required this.publishedAt,
    required this.clinicalLeadId,
    required this.approvalSignature,
    required this.bundleHash,
    required this.ageBands,
    required this.rules,
    this.testSuite = const [],
  });

  /// Returns empty fallback rule set.
  factory RuleSet.empty() => RuleSet(
        id: 'ruleset-empty',
        versionString: '0.0.0',
        publishedAt: 0,
        clinicalLeadId: 'system',
        approvalSignature: 'unsigned',
        bundleHash: '',
        ageBands: [
          for (final code in AgeBandCode.values) AgeBand.defaultFor(code),
        ],
        rules: const [],
        testSuite: const [],
      );

  /// Filters rules matching the target [ageBand].
  List<TriageRule> rulesForAgeBand(AgeBandCode ageBand) {
    return rules.where((r) => r.ageBand == ageBand).toList();
  }

  /// Looks up metadata for the target [code].
  AgeBand? ageBandConfig(AgeBandCode code) {
    for (final ab in ageBands) {
      if (ab.code == code) return ab;
    }
    return AgeBand.defaultFor(code);
  }

  /// Built-in national base rule set aligned with IMNCI, HBNC, and HBYC guidelines.
  factory RuleSet.defaultNational() {
    return RuleSet(
      id: 'ruleset-national-v1',
      versionString: '1.0.0',
      publishedAt: 1710000000000,
      clinicalLeadId: 'lead_clinician_mohfw_01',
      approvalSignature: 'SIG_ED25519_VALIDATED_NATIONAL_BASE_RULESET',
      bundleHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      ageBands: [
        for (final code in AgeBandCode.values) AgeBand.defaultFor(code),
      ],
      rules: [
        // 1. INFANT_0_2M Fast Breathing: >= 60 breaths/min
        const TriageRule(
          ruleId: 'INFANT_FAST_BREATHING',
          ageBand: AgeBandCode.infant02m,
          severity: TriageFlag.red,
          sourceCitation: 'IMNCI Chart Booklet 2014, MoHFW, p.12',
          condition: Condition(
            op: ConditionOp.and,
            children: [
              Condition(op: ConditionOp.gte, field: 'respiratory_rate', value: 60),
              Condition(op: ConditionOp.lte, field: 'age_days', value: 60),
            ],
          ),
          findingTemplate:
              'Breathing rate {respiratory_rate}/min in infant {age_days} days — refer now',
          action: 'REFER_IMMEDIATELY',
        ),
        // 2. INFANT_0_2M Severe Hypothermia: < 35.5 C
        const TriageRule(
          ruleId: 'INFANT_HYPOTHERMIA_SEVERE',
          ageBand: AgeBandCode.infant02m,
          severity: TriageFlag.red,
          sourceCitation: 'HBNC Operational Guidelines, MoHFW, p.24',
          condition: Condition(
            op: ConditionOp.lt,
            field: 'temperature',
            value: 35.5,
          ),
          findingTemplate:
              'Axillary temperature {temperature}°C in young infant — severe hypothermia, warm and refer urgently',
          action: 'REFER_IMMEDIATELY',
        ),
        // 3. INFANT_0_2M Fever: >= 37.5 C
        const TriageRule(
          ruleId: 'INFANT_FEVER',
          ageBand: AgeBandCode.infant02m,
          severity: TriageFlag.red,
          sourceCitation: 'IMNCI Chart Booklet 2014, MoHFW, p.14',
          condition: Condition(
            op: ConditionOp.gte,
            field: 'temperature',
            value: 37.5,
          ),
          findingTemplate:
              'High temperature {temperature}°C in young infant under 2 months — possible serious bacterial infection',
          action: 'REFER_IMMEDIATELY',
        ),
        // 4. CHILD_2M_5Y Fast breathing:
        // 2-11 months: >= 50
        const TriageRule(
          ruleId: 'CHILD_FAST_BREATHING_INFANT',
          ageBand: AgeBandCode.child2m5y,
          severity: TriageFlag.yellow,
          sourceCitation: 'IMNCI Chart Booklet 2014, MoHFW, p.16',
          condition: Condition(
            op: ConditionOp.and,
            children: [
              Condition(op: ConditionOp.lte, field: 'age_days', value: 365),
              Condition(op: ConditionOp.gte, field: 'respiratory_rate', value: 50),
            ],
          ),
          findingTemplate:
              'Fast breathing {respiratory_rate}/min in child {age_days} days — pneumonia',
          action: 'INITIATE_HOME_CARE_AND_REFER_IF_WORSENS',
        ),
        // 5. CHILD_2M_5Y Chest Indrawing: RED
        const TriageRule(
          ruleId: 'CHILD_CHEST_INDRAWING',
          ageBand: AgeBandCode.child2m5y,
          severity: TriageFlag.red,
          sourceCitation: 'IMNCI Chart Booklet 2014, MoHFW, p.16',
          condition: Condition(
            op: ConditionOp.eq,
            field: 'chest_indrawing',
            value: true,
          ),
          findingTemplate: 'Severe chest indrawing observed in child — urgent referral',
          action: 'REFER_IMMEDIATELY',
        ),
        // 6. PREGNANT Severe Hypertension: SBP >= 160 or DBP >= 110
        const TriageRule(
          ruleId: 'PREGNANT_SEVERE_HYPERTENSION',
          ageBand: AgeBandCode.pregnant,
          severity: TriageFlag.red,
          sourceCitation: 'Pradhan Mantri Surakshit Matritva Abhiyan (PMSMA), MoHFW, p.18',
          condition: Condition(
            op: ConditionOp.or,
            children: [
              Condition(op: ConditionOp.gte, field: 'systolic_bp', value: 160),
              Condition(op: ConditionOp.gte, field: 'diastolic_bp', value: 110),
            ],
          ),
          findingTemplate:
              'Severe hypertension (BP {systolic_bp}/{diastolic_bp} mmHg) in pregnancy — pre-eclampsia risk',
          action: 'REFER_IMMEDIATELY',
        ),
        // 7. ADULT Severe Hypertension: SBP >= 180 or DBP >= 120
        const TriageRule(
          ruleId: 'ADULT_HYPERTENSIVE_CRISIS',
          ageBand: AgeBandCode.adult,
          severity: TriageFlag.red,
          sourceCitation: 'NP-NCD Operational Guidelines, MoHFW, p.32',
          condition: Condition(
            op: ConditionOp.or,
            children: [
              Condition(op: ConditionOp.gte, field: 'systolic_bp', value: 180),
              Condition(op: ConditionOp.gte, field: 'diastolic_bp', value: 120),
            ],
          ),
          findingTemplate:
              'Hypertensive urgency/crisis (BP {systolic_bp}/{diastolic_bp} mmHg)',
          action: 'REFER_IMMEDIATELY',
        ),
        // 8. ADULT Moderate Hypertension: SBP >= 140 or DBP >= 90
        const TriageRule(
          ruleId: 'ADULT_HYPERTENSION_STAGE1',
          ageBand: AgeBandCode.adult,
          severity: TriageFlag.yellow,
          sourceCitation: 'NP-NCD Operational Guidelines, MoHFW, p.32',
          condition: Condition(
            op: ConditionOp.or,
            children: [
              Condition(op: ConditionOp.gte, field: 'systolic_bp', value: 140),
              Condition(op: ConditionOp.gte, field: 'diastolic_bp', value: 90),
            ],
          ),
          findingTemplate:
              'Elevated blood pressure (BP {systolic_bp}/{diastolic_bp} mmHg) — advise lifestyle and schedule PHC visit',
          action: 'SCHEDULE_PHC_VISIT',
        ),
      ],
      testSuite: const [
        TestCase(
          testId: 'TC_INFANT_FAST_BREATHING_RED',
          inputs: {
            'age_days': 45,
            'respiratory_rate': 62,
            'temperature': 36.8,
          },
          expectedFlag: TriageFlag.red,
          description: 'Fast breathing in 45-day infant evaluates to RED',
        ),
      ],
    );
  }

  factory RuleSet.fromJson(Map<String, dynamic> json) => RuleSet(
        id: json['id'] as String? ?? '',
        versionString: json['versionString'] as String? ??
            json['version_string'] as String? ??
            json['version'] as String? ??
            '1.0.0',
        publishedAt: (json['publishedAt'] as num? ??
                json['published_at'] as num? ??
                0)
            .toInt(),
        clinicalLeadId: json['clinicalLeadId'] as String? ??
            json['clinical_lead_id'] as String? ??
            '',
        approvalSignature: json['approvalSignature'] as String? ??
            json['approval_signature'] as String? ??
            '',
        bundleHash: json['bundleHash'] as String? ??
            json['bundle_hash'] as String? ??
            '',
        ageBands: (json['ageBands'] as List<dynamic>? ??
                json['age_bands'] as List<dynamic>? ??
                [])
            .map((e) => AgeBand.fromJson(e as Map<String, dynamic>))
            .toList(),
        rules: (json['rules'] as List<dynamic>? ?? [])
            .map((e) => TriageRule.fromJson(e as Map<String, dynamic>))
            .toList(),
        testSuite: (json['testSuite'] as List<dynamic>? ??
                json['test_suite'] as List<dynamic>? ??
                [])
            .map((e) => TestCase.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'versionString': versionString,
        'publishedAt': publishedAt,
        'clinicalLeadId': clinicalLeadId,
        'approvalSignature': approvalSignature,
        'bundleHash': bundleHash,
        'ageBands': ageBands.map((a) => a.toJson()).toList(),
        'rules': rules.map((r) => r.toJson()).toList(),
        'testSuite': testSuite.map((t) => t.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RuleSet &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          versionString == other.versionString &&
          publishedAt == other.publishedAt &&
          clinicalLeadId == other.clinicalLeadId &&
          approvalSignature == other.approvalSignature &&
          bundleHash == other.bundleHash &&
          _listEquals(ageBands, other.ageBands) &&
          _listEquals(rules, other.rules) &&
          _listEquals(testSuite, other.testSuite);

  @override
  int get hashCode => Object.hash(
        id,
        versionString,
        publishedAt,
        clinicalLeadId,
        approvalSignature,
        bundleHash,
        Object.hashAll(ageBands),
        Object.hashAll(rules),
        Object.hashAll(testSuite),
      );

  static bool _listEquals(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
