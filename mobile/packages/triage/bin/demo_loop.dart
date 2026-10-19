import 'dart:convert';
import 'dart:io';

import 'package:triage/triage.dart';

/// Proves the pack loop in one session. No network.
///
/// 1. Ward W3 with the seeded pack activates dengue.
/// 2. Version 2 moves that cluster to W5.
/// 3. The next assessment follows the new pack.
void main() {
  final packDir = Directory('lib/data/pack');
  String read(String name) => File('${packDir.path}/$name').readAsStringSync();
  final pack = ContextPack.parse(
    manifestJson: read('manifest.json'),
    wardsGeoJson: read('wards.geojson'),
    diseaseCsv: read('disease_counts.csv'),
    modulesJson: read('modules.json'),
    priorsJson: read('priors.json'),
    questionBankJson: read('question_bank.json'),
  );
  final tables = <String, Map<String, Object?>>{};
  for (final entity in Directory('../imci_engine/lib/data/imci_tables').listSync()) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    tables[entity.uri.pathSegments.last] = (jsonDecode(entity.readAsStringSync()) as Map).cast<String, Object?>();
  }
  final loop = AdaptiveTriage(pack: pack, engine: ImciEngine(ImciCatalog.fromModuleMaps(tables)));

  final first = loop.openAssessment(wardId: 'W3');
  stdout.writeln('1. W3 modules: ${first.activeModules}');
  stdout.writeln('   context: ${pack.clusterSummary('W3')}');
  stdout.writeln('   dengue question is number ${first.questions.indexWhere((question) => question.id == 'dengue.abdominal') + 1}');

  final next = pack.withCounts(
    parseDiseaseCsv(read('disease_counts_v2.csv')),
    version: 2,
    generatedAt: '2026-10-26T00:00:00Z',
  );
  loop.updateContextPack(next);
  stdout.writeln('2. Loaded pack v2. Open flow cleared: ${loop.openFlow == null}');

  final w5 = loop.openAssessment(wardId: 'W5');
  final w3 = loop.openAssessment(wardId: 'W3');
  stdout.writeln('3. W5 modules: ${w5.activeModules}');
  stdout.writeln('   W3 modules: ${w3.activeModules}');
  stdout.writeln('   W5 has dengue questions: ${w5.questions.any((question) => question.module == 'dengue')}');
  stdout.writeln('   W3 has dengue questions: ${w3.questions.any((question) => question.module == 'dengue')}');
}
