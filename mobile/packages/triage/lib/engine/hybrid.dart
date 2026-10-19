import 'package:imci_engine/imci_engine.dart';

class ModelScore {
  const ModelScore({
    required this.pRed,
    required this.pYellow,
    required this.pGreen,
    required this.latencyMs,
  });

  final double pRed;
  final double pYellow;
  final double pGreen;
  final double latencyMs;

  String get likelyFlag {
    if (pRed >= pYellow && pRed >= pGreen) return 'RED';
    if (pYellow >= pGreen) return 'YELLOW';
    return 'GREEN';
  }
}

class ModelContribution {
  const ModelContribution({
    required this.score,
    required this.escalated,
    required this.note,
  });

  final ModelScore? score;
  final bool escalated;
  final String note;
}

/// The flag the phone shows. The engine flag is never lowered.
class HybridDecision {
  const HybridDecision({
    required this.flag,
    required this.firedRules,
    required this.followUpDays,
    required this.modelContribution,
    required this.outbreakContext,
  });

  final TriageFlag flag;
  final List<FiredRule> firedRules;
  final int? followUpDays;
  final ModelContribution modelContribution;
  final String outbreakContext;

  TriageResult get engineView => TriageResult(
        flag: flag,
        firedRules: firedRules,
        followUpDays: followUpDays,
      );
}

class HybridTriage {
  const HybridTriage({this.redThreshold = 0.65});

  /// Yellow escalates only when the model's red probability is above this.
  final double redThreshold;

  HybridDecision combine(
    EngineResult engine,
    ModelScore? score, {
    String outbreakContext = '',
  }) {
    if (score == null) {
      return HybridDecision(
        flag: engine.flag,
        firedRules: engine.firedRules,
        followUpDays: engine.followUpDays,
        outbreakContext: outbreakContext,
        modelContribution: const ModelContribution(
          score: null,
          escalated: false,
          note: 'Model not loaded. Engine flag kept.',
        ),
      );
    }

    final would = 'Model would have said ${score.likelyFlag} '
        '(p_red ${score.pRed.toStringAsFixed(2)}, '
        'p_yellow ${score.pYellow.toStringAsFixed(2)}, '
        'p_green ${score.pGreen.toStringAsFixed(2)}).';

    if (engine.flag == TriageFlag.red) {
      return HybridDecision(
        flag: TriageFlag.red,
        firedRules: engine.firedRules,
        followUpDays: engine.followUpDays,
        outbreakContext: outbreakContext,
        modelContribution: ModelContribution(
          score: score,
          escalated: false,
          note: 'Engine RED kept. $would',
        ),
      );
    }

    if (engine.flag == TriageFlag.green) {
      return HybridDecision(
        flag: TriageFlag.green,
        firedRules: engine.firedRules,
        followUpDays: engine.followUpDays,
        outbreakContext: outbreakContext,
        modelContribution: ModelContribution(
          score: score,
          escalated: false,
          note: 'Engine GREEN kept. $would',
        ),
      );
    }

    if (score.pRed > redThreshold) {
      final cluster = outbreakContext.isEmpty ? 'no outbreak module active' : outbreakContext;
      return HybridDecision(
        flag: TriageFlag.red,
        firedRules: engine.firedRules,
        followUpDays: null,
        outbreakContext: outbreakContext,
        modelContribution: ModelContribution(
          score: score,
          escalated: true,
          note: 'escalated: high risk + $cluster',
        ),
      );
    }

    return HybridDecision(
      flag: TriageFlag.yellow,
      firedRules: engine.firedRules,
      followUpDays: engine.followUpDays,
      outbreakContext: outbreakContext,
      modelContribution: ModelContribution(
        score: score,
        escalated: false,
        note: 'Engine YELLOW kept. $would',
      ),
    );
  }
}
