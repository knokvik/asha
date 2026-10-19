/// Canonical clinical data model (architecture.md §7).
///
/// This package is deliberately dependency-free: it is imported by the pure
/// rule engine, by the Flutter app, and by the backend verifier, so it MUST NOT
/// reference Flutter, dart:io, drift, or any transport library.
library;

export 'src/sourced_value.dart';
export 'src/clinical_assessment.dart';
export 'src/triage_result.dart';
export 'src/assessment_document.dart';
