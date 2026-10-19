import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:triage/triage.dart';

/// Loads the cached pack and the chart tables. Nothing here touches the network.
class AdaptiveSession {
  AdaptiveSession({required this.loop, required this.model, required this.prior});

  final AdaptiveTriage loop;
  final RiskModel? model;
  final DistrictPrior? prior;

  static const _pack = 'packages/triage/lib/data/pack';
  static const _tables = 'packages/imci_engine/lib/data/imci_tables';
  static const _tableNames = [
    'danger_signs',
    'cough_breathing',
    'diarrhoea',
    'fever',
    'ear',
    'malnutrition_anaemia',
  ];

  static Future<AdaptiveSession> load() async {
    Future<String> read(String path) => rootBundle.loadString(path);
    final pack = ContextPack.parse(
      manifestJson: await read('$_pack/manifest.json'),
      wardsGeoJson: await read('$_pack/wards.geojson'),
      diseaseCsv: await read('$_pack/disease_counts.csv'),
      modulesJson: await read('$_pack/modules.json'),
      priorsJson: await read('$_pack/priors.json'),
      questionBankJson: await read('$_pack/question_bank.json'),
    );
    final tables = <String, Map<String, Object?>>{};
    for (final name in _tableNames) {
      final decoded = jsonDecode(await read('$_tables/$name.json'));
      tables['$name.json'] = (decoded as Map).cast<String, Object?>();
    }
    RiskModel? model;
    try {
      model = RiskModel.fromJson(await read('packages/triage/lib/data/model/model.json'));
    } catch (_) {
      model = null;
    }
    return AdaptiveSession(
      loop: AdaptiveTriage(
        pack: pack,
        engine: ImciEngine(ImciCatalog.fromModuleMaps(tables)),
        redThreshold: model?.redThreshold ?? 0.65,
      ),
      model: model != null && model.isReady ? model : null,
      prior: pack.priorFor(pack.districtId),
    );
  }

  /// The demo starts from the cached sample fix, which sits inside ward W3.
  WardResolution resolve(LatLon? fix) => WardIndex(loop.pack.wards).resolve(fix ?? loop.pack.sampleFix);
}
