/// On-device IMCI / IMNCI decision support.
///
/// [ImciEngine.evaluate] is a pure function of [AssessmentInput] and the
/// loaded tables. It does not read the clock, the disk, or the network.
library;

export 'src/catalog.dart';
export 'src/conditions.dart';
export 'src/engine.dart';
export 'src/models.dart';
export 'src/referral_note.dart';
