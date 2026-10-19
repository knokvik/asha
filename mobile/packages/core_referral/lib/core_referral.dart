/// Referral note generator (architecture.md §11).
///
/// Deterministic template rendering. This package MUST NOT call a language
/// model: a referral a clinician acts on has to be reproducible from the record.
library;

export 'src/referral_note.dart';
export 'src/referral_labels.dart';
export 'src/referral_builder.dart';
