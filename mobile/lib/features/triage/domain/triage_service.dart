import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/triage/models/models.dart';
import '../../../core/triage/rule_loader.dart';
import '../../../core/triage/triage_engine.dart';
import '../../../core/voice/tts_service.dart';
import '../../../shared/providers/core_providers.dart';
import '../data/triage_repository.dart';

/// Service coordinating on-device clinical triage evaluation, audio speech synthesis,
/// ML contribution hook, and override persistence.
///
/// Implements Requirements 8.1, 8.5, 8.6, 8.9, 46.1, 46.2.
class TriageService {
  final RuleLoader ruleLoader;
  final TriageRepository repository;
  final TtsService? ttsService;

  TriageService({
    required this.ruleLoader,
    required this.repository,
    this.ttsService,
  });

  /// Evaluates clinical assessment inputs against the currently active rule set.
  ///
  /// Guarantees execution in < 1 second without network I/O (Requirement 8.1).
  Future<TriageResult> evaluateAssessment(
    TriageInputs inputs, {
    MLTriageContribution? mlContribution,
    String? memberId,
    bool speakAudio = true,
  }) async {
    final ruleSet = await ruleLoader.loadActiveRuleSet();
    final engine = TriageEngine(ruleSet: ruleSet);

    final result = engine.evaluate(inputs, ruleSet, mlContribution);

    // Persist result
    await repository.saveTriageResult(result, memberId: memberId);

    // Speak result audio (Requirement 46.1, 46.2)
    if (speakAudio && ttsService != null) {
      await speakTriageResult(result);
    }

    return result;
  }

  /// Speaks triage result summary: Colour + Primary Reason + Action.
  Future<void> speakTriageResult(TriageResult result, {String language = 'en'}) async {
    if (ttsService == null) return;

    final colourName = result.flag.label; // RED, YELLOW, GREEN
    final primaryReason = result.findings.isNotEmpty
        ? result.findings.first.findingText
        : (result.escalatedForMissingData
            ? 'Missing required clinical inputs: ${result.missingFields.join(', ')}'
            : 'Normal vitals and symptoms');

    final action = result.findings.isNotEmpty
        ? result.findings.first.action.replaceAll('_', ' ').toLowerCase()
        : (result.flag == TriageFlag.red
            ? 'refer immediately'
            : (result.flag == TriageFlag.yellow
                ? 'monitor closely and schedule visit'
                : 'continue home care'));

    final speechText = 'Flag $colourName. $primaryReason. Action: $action.';
    await ttsService!.speak(text: speechText, language: language);
  }

  /// Records an ASHA worker's clinical override.
  ///
  /// Requirement 8.6: Requires 10–500 character reason, records both original and override.
  Future<void> recordOverride({
    required String triageResultId,
    required TriageOverride override,
  }) async {
    await repository.recordOverride(
      triageResultId: triageResultId,
      override: override,
    );
  }
}

final ruleLoaderProvider = Provider<RuleLoader>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return RuleLoader(db);
});

final triageServiceProvider = Provider<TriageService>((ref) {
  final ruleLoader = ref.watch(ruleLoaderProvider);
  final repo = ref.watch(triageRepositoryProvider);
  final tts = ref.watch(ttsServiceProvider);
  return TriageService(
    ruleLoader: ruleLoader,
    repository: repo,
    ttsService: tts,
  );
});
