/// Adaptive offline triage: ward pack, question flow, IMCI flag, hybrid policy.
///
/// The rules themselves live in `imci_engine`. This library does not import
/// `dart:io` or any network client. The app reads the cached pack and passes
/// the strings to [ContextPack.parse].
library;

export 'package:imci_engine/imci_engine.dart';

export 'context/context_pack.dart';
export 'context/ward_index.dart';
export 'engine/adaptive_triage.dart';
export 'engine/hybrid.dart';
export 'engine/outbox.dart';
export 'flows/question_flow.dart';
export 'ml_integration/risk_model.dart';
