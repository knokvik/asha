/// Pure deterministic pediatric triage rule engine (architecture.md §10).
///
/// Re-exports `core_model` so consumers get the canonical clinical data model
/// and the engine from a single import.
library;

export 'package:core_model/core_model.dart';

export 'src/engine.dart';
export 'src/ruleset.dart';
