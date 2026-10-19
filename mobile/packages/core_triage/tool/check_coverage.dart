// Phase 1 DoD: coverage floor on rule evaluation.
//
// The clinical core is the one place in this project where "the tests pass" is
// not enough — an unexercised branch in the evaluator is a clinical decision
// nobody has ever checked. This fails CI when the engine drops below the floor.
import 'dart:io';

/// Per-file minimum line coverage. `engine.dart` and `ruleset.dart` are the
/// evaluation path and are held at 100%.
const floors = <String, double>{
  'lib/src/engine.dart': 100.0,
  'lib/src/ruleset.dart': 100.0,
};

void main(List<String> args) {
  final path = args.isEmpty ? 'coverage/lcov.info' : args.first;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('coverage report not found at $path');
    exit(2);
  }

  final coverage = <String, ({int hit, int found})>{};
  String? current;
  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = line.substring(3);
    } else if (line.startsWith('LH:') && current != null) {
      coverage[current] = (hit: int.parse(line.substring(3)), found: coverage[current]?.found ?? 0);
    } else if (line.startsWith('LF:') && current != null) {
      coverage[current] = (hit: coverage[current]?.hit ?? 0, found: int.parse(line.substring(3)));
    }
  }

  var failed = false;
  floors.forEach((suffix, floor) {
    final entry = coverage.entries.where((e) => e.key.endsWith(suffix)).firstOrNull;
    if (entry == null) {
      stderr.writeln('FAIL  $suffix — no coverage recorded');
      failed = true;
      return;
    }
    final found = entry.value.found;
    final percent = found == 0 ? 100.0 : entry.value.hit * 100 / found;
    final verdict = percent + 1e-9 >= floor ? 'ok  ' : 'FAIL';
    stdout.writeln('$verdict  $suffix  ${percent.toStringAsFixed(1)}% '
        '(${entry.value.hit}/$found), floor ${floor.toStringAsFixed(1)}%');
    if (percent + 1e-9 < floor) failed = true;
  });

  if (failed) {
    stderr.writeln('\nCoverage floor not met on the rule-evaluation path.');
    exit(1);
  }
  stdout.writeln('\nCoverage floors met.');
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
