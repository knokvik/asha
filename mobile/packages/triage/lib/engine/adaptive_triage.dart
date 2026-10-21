import 'package:imci_engine/imci_engine.dart';

import '../context/context_pack.dart';
import '../flows/question_flow.dart';
import 'hybrid.dart';
import 'outbox.dart';

/// The phone-side loop. A new pack drops the open flow and the next
/// assessment uses the new ward modules.
class AdaptiveTriage {
  AdaptiveTriage({
    required ContextPack pack,
    required this.engine,
    this.redThreshold = 0.65,
    OutboxSink? outbox,
  }) : _pack = pack,
       outbox = outbox ?? OutboxSink();

  ContextPack _pack;
  final ImciEngine engine;
  final double redThreshold;
  final OutboxSink outbox;
  FlowState? _openFlow;

  ContextPack get pack => _pack;
  FlowState? get openFlow => _openFlow;

  void updateContextPack(ContextPack next) {
    if (next.version < _pack.version) {
      throw FormatException(
        'pack version ${next.version} is older than ${_pack.version}',
      );
    }
    if (next.districtId != _pack.districtId) {
      throw FormatException(
        'pack district ${next.districtId} does not match ${_pack.districtId}',
      );
    }
    _pack = next;
    _openFlow = null;
  }

  FlowState openAssessment({
    required String wardId,
    int? month,
    Set<String> extraModules = const {},
  }) {
    _openFlow = FlowBuilder(_pack)
        .build(wardId: wardId, month: month, extraModules: extraModules);
    return _openFlow!;
  }

  HybridDecision decide(AssessmentInput input, {ModelScore? score}) {
    final result = engine.evaluate(input);
    final ward = input.context.wardId ?? '';
    final context = _pack.clusterSummary(ward);
    return HybridTriage(redThreshold: redThreshold)
        .combine(result, score, outbreakContext: context);
  }

  /// Writes one assessment into the offline outbox. The server module drains it.
  void enqueue(
    AssessmentInput input,
    HybridDecision decision,
    ReferralNote note,
  ) {
    outbox.add(
      OutboxItem(
        packVersion: _pack.version,
        districtId: _pack.districtId,
        wardId: input.context.wardId ?? '',
        flag: decision.flag.wireName,
        referralSms: note.toSms(),
      ),
    );
  }
}
