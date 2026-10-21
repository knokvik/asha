import 'dart:convert';

import 'ward_index.dart';

class DiseaseCount {
  const DiseaseCount({
    required this.weekIndex,
    required this.wardId,
    required this.condition,
    required this.cases,
  });

  final int weekIndex;
  final String wardId;
  final String condition;
  final int cases;
}

class OutbreakModule {
  const OutbreakModule({
    required this.id,
    required this.condition,
    required this.minCasesPerWeek,
    required this.lookbackWeeks,
    required this.seasonalMonths,
  });

  final String id;
  final String condition;
  final int minCasesPerWeek;
  final int lookbackWeeks;
  final List<int> seasonalMonths;
}

class DistrictPrior {
  const DistrictPrior({
    required this.districtId,
    required this.anaemiaPct,
    required this.stuntingPct,
    required this.immunizationPct,
  });

  final String districtId;
  final double anaemiaPct;
  final double stuntingPct;
  final double immunizationPct;
}

class ChoiceOption {
  const ChoiceOption({required this.value, required this.label});

  final String value;
  final String label;
}

class NumericBounds {
  const NumericBounds({
    required this.unit,
    required this.min,
    required this.max,
    this.decimals = 0,
  });

  final String unit;
  final num min;
  final num max;
  final int decimals;
}

class BankQuestion {
  const BankQuestion({
    required this.id,
    required this.module,
    required this.text,
    required this.type,
    required this.weight,
    required this.isRedFlag,
    required this.inputField,
    this.invertYes = false,
    this.options = const [],
    this.numeric,
  });

  final String id;
  final String module;
  final Map<String, String> text;
  final String type;
  final int weight;
  final bool isRedFlag;
  final String inputField;
  final bool invertYes;
  final List<ChoiceOption> options;
  final NumericBounds? numeric;

  String prompt(String language) => text[language] ?? text['en'] ?? id;
}

class PackFacility {
  const PackFacility({
    required this.id,
    required this.name,
    required this.wardId,
  });

  final String id;
  final String name;
  final String wardId;
}

/// One downloaded context pack. The demo ships version 1. The phone caches it.
class ContextPack {
  const ContextPack({
    required this.districtId,
    required this.version,
    required this.generatedAt,
    required this.languages,
    required this.asOfMonth,
    required this.wards,
    required this.counts,
    required this.modules,
    required this.priors,
    required this.questions,
    required this.facilities,
    required this.sampleFix,
  });

  final String districtId;
  final int version;
  final String generatedAt;
  final List<String> languages;
  final int asOfMonth;
  final List<WardPolygon> wards;
  final List<DiseaseCount> counts;
  final List<OutbreakModule> modules;
  final List<DistrictPrior> priors;
  final List<BankQuestion> questions;
  final List<PackFacility> facilities;
  final LatLon? sampleFix;

  /// IMCI core is not in this list. These are outbreak modules only.
  List<String> activeModuleIds(String wardId, {int? month}) {
    final when = month ?? asOfMonth;
    final latest = counts.fold<int>(
      0,
      (best, row) => row.weekIndex > best ? row.weekIndex : best,
    );
    final active = <String>[];
    for (final module in modules) {
      if (!module.seasonalMonths.contains(when)) continue;
      final start = latest - module.lookbackWeeks + 1;
      var peak = 0;
      var seen = false;
      for (final row in counts) {
        if (row.wardId != wardId ||
            row.condition != module.condition ||
            row.weekIndex < start)
          continue;
        seen = true;
        if (row.cases > peak) peak = row.cases;
      }
      if (seen && peak >= module.minCasesPerWeek) active.add(module.id);
    }
    return active;
  }

  int casesOverWeeks(String wardId, String condition, int weeks) {
    final latest = counts.fold<int>(
      0,
      (best, row) => row.weekIndex > best ? row.weekIndex : best,
    );
    final start = latest - weeks + 1;
    var total = 0;
    for (final row in counts) {
      if (row.wardId == wardId &&
          row.condition == condition &&
          row.weekIndex >= start) {
        total += row.cases;
      }
    }
    return total;
  }

  /// Sentence the referral can show. Empty when this ward has no active outbreak module.
  String clusterSummary(String wardId, {int? month}) {
    final active = activeModuleIds(wardId, month: month);
    final parts = <String>[];
    for (final id in active) {
      final module = modules.firstWhere((item) => item.id == id);
      final total = casesOverWeeks(wardId, module.condition, 2);
      final label = module.condition.replaceAll('_', '-');
      parts.add('$total $label cases in $wardId in the last 2 weeks');
    }
    return parts.join('; ');
  }

  DistrictPrior? priorFor(String? districtId) {
    for (final prior in priors) {
      if (prior.districtId == districtId) return prior;
    }
    return priors.isEmpty ? null : priors.first;
  }

  PackFacility? facilityForWard(String wardId) {
    for (final facility in facilities) {
      if (facility.wardId == wardId) return facility;
    }
    return null;
  }

  /// Centroid used only for aggregate hotspot display, never as a patient
  /// location.
  LatLon? centerForWard(String wardId) {
    for (final ward in wards) {
      if (ward.wardId != wardId || ward.ring.isEmpty) continue;
      final latitude = ward.ring.fold<double>(
            0,
            (sum, point) => sum + point.latitude,
          ) /
          ward.ring.length;
      final longitude = ward.ring.fold<double>(
            0,
            (sum, point) => sum + point.longitude,
          ) /
          ward.ring.length;
      return LatLon(latitude, longitude);
    }
    return null;
  }

  ContextPack withCounts(
    List<DiseaseCount> counts, {
    required int version,
    String? generatedAt,
  }) {
    return ContextPack(
      districtId: districtId,
      version: version,
      generatedAt: generatedAt ?? this.generatedAt,
      languages: languages,
      asOfMonth: asOfMonth,
      wards: wards,
      counts: counts,
      modules: modules,
      priors: priors,
      questions: questions,
      facilities: facilities,
      sampleFix: sampleFix,
    );
  }

  /// Overlays privacy-preserving cross-worker hotspot counts downloaded from
  /// the server. The base pack remains usable when the overlay is stale or
  /// unavailable, so triage never depends on connectivity.
  ContextPack withHotspotContext(Map<String, dynamic> context) {
    final rawCounts = context['counts'];
    final rawModules = context['modules'];
    if (rawCounts is! List || rawModules is! List) return this;

    final overlayCounts = <DiseaseCount>[];
    for (final raw in rawCounts) {
      if (raw is! Map) continue;
      final week = (raw['week_index'] as num?)?.toInt();
      final cases = (raw['cases'] as num?)?.toInt();
      final ward = raw['ward_id']?.toString();
      final condition = raw['condition']?.toString();
      if (week == null || cases == null || ward == null || condition == null)
        continue;
      overlayCounts.add(
        DiseaseCount(
          weekIndex: week,
          wardId: ward,
          condition: condition,
          cases: cases,
        ),
      );
    }

    final overlayModules = <OutbreakModule>[];
    for (final raw in rawModules) {
      if (raw is! Map) continue;
      final id = raw['id']?.toString();
      final condition = raw['condition']?.toString();
      if (id == null || condition == null) continue;
      overlayModules.add(
        OutbreakModule(
          id: id,
          condition: condition,
          minCasesPerWeek: (raw['min_cases_per_week'] as num?)?.toInt() ?? 1,
          lookbackWeeks: (raw['lookback_weeks'] as num?)?.toInt() ?? 4,
          seasonalMonths: [
            for (final month in (raw['seasonal_months'] as List? ?? const []))
              if (month is num) month.toInt(),
          ],
        ),
      );
    }

    final mergedModules = [
      ...modules.where(
        (base) => overlayModules.every((overlay) => overlay.id != base.id),
      ),
      ...overlayModules,
    ];
    final asOfMonth =
        (context['as_of_month'] as num?)?.toInt() ?? this.asOfMonth;
    return ContextPack(
      districtId: districtId,
      version: version,
      generatedAt: (context['generated_at']?.toString()) ?? generatedAt,
      languages: languages,
      asOfMonth: asOfMonth,
      wards: wards,
      counts: [...counts, ...overlayCounts],
      modules: mergedModules,
      priors: priors,
      questions: questions,
      facilities: facilities,
      sampleFix: sampleFix,
    );
  }

  static ContextPack parse({
    required String manifestJson,
    required String wardsGeoJson,
    required String diseaseCsv,
    required String modulesJson,
    required String priorsJson,
    required String questionBankJson,
  }) {
    final manifest = (jsonDecode(manifestJson) as Map).cast<String, Object?>();
    final version = manifest['pack_version'];
    if (version is! num) {
      throw FormatException('manifest.pack_version is missing');
    }
    final district = manifest['district_id'];
    if (district is! String || district.isEmpty) {
      throw FormatException('manifest.district_id is missing');
    }
    return ContextPack(
      districtId: district,
      version: version.toInt(),
      generatedAt: (manifest['generated_at'] as String?) ?? '',
      languages: _strings(manifest['languages']),
      asOfMonth: (manifest['as_of_month'] as num?)?.toInt() ?? 1,
      wards: _wards(wardsGeoJson),
      counts: _csv(diseaseCsv),
      modules: _modules(modulesJson),
      priors: _priors(priorsJson),
      questions: _questions(questionBankJson),
      facilities: _facilities(manifest['facilities']),
      sampleFix: _fix(manifest['sample_fix']),
    );
  }
}

List<String> _strings(Object? raw) {
  if (raw is! List) return const [];
  return [for (final item in raw) item.toString()];
}

LatLon? _fix(Object? raw) {
  if (raw is! Map) return null;
  final lat = raw['latitude'];
  final lon = raw['longitude'];
  if (lat is! num || lon is! num) return null;
  return LatLon(lat.toDouble(), lon.toDouble());
}

List<PackFacility> _facilities(Object? raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item is Map)
        PackFacility(
          id: item['id'].toString(),
          name: item['name'].toString(),
          wardId: item['ward_id'].toString(),
        ),
  ];
}

List<WardPolygon> _wards(String geoJson) {
  final root = (jsonDecode(geoJson) as Map).cast<String, Object?>();
  final features = root['features'];
  if (features is! List) throw FormatException('wards.geojson has no features');
  final wards = <WardPolygon>[];
  for (final feature in features) {
    if (feature is! Map) continue;
    final properties =
        (feature['properties'] as Map?)?.cast<String, Object?>() ?? const {};
    final geometry =
        (feature['geometry'] as Map?)?.cast<String, Object?>() ?? const {};
    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.isEmpty) continue;
    final ring = coordinates.first;
    if (ring is! List) continue;
    wards.add(
      WardPolygon(
        wardId: properties['ward_id'].toString(),
        ring: [
          for (final point in ring)
            if (point is List && point.length >= 2)
              LatLon(
                (point[1] as num).toDouble(),
                (point[0] as num).toDouble(),
              ),
        ],
      ),
    );
  }
  return wards;
}

List<DiseaseCount> parseDiseaseCsv(String csv) => _csv(csv);

List<DiseaseCount> _csv(String csv) {
  final lines = csv
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.length < 2) return const [];
  final rows = <DiseaseCount>[];
  for (final line in lines.skip(1)) {
    final cells = line.split(',');
    if (cells.length < 4) continue;
    rows.add(
      DiseaseCount(
        weekIndex: int.parse(cells[0]),
        wardId: cells[1],
        condition: cells[2],
        cases: int.parse(cells[3]),
      ),
    );
  }
  return rows;
}

List<OutbreakModule> _modules(String raw) {
  final root = (jsonDecode(raw) as Map).cast<String, Object?>();
  final list = root['modules'];
  if (list is! List) throw FormatException('modules array missing');
  return [
    for (final item in list)
      if (item is Map)
        OutbreakModule(
          id: item['id'].toString(),
          condition: item['condition'].toString(),
          minCasesPerWeek:
              ((item['activation'] as Map)['min_cases_per_week'] as num)
                  .toInt(),
          lookbackWeeks: ((item['activation'] as Map)['lookback_weeks'] as num)
              .toInt(),
          seasonalMonths: [
            for (final month
                in (item['activation'] as Map)['seasonal_months'] as List)
              (month as num).toInt(),
          ],
        ),
  ];
}

List<DistrictPrior> _priors(String raw) {
  final root = (jsonDecode(raw) as Map).cast<String, Object?>();
  final list = root['districts'];
  if (list is! List) return const [];
  return [
    for (final item in list)
      if (item is Map)
        DistrictPrior(
          districtId: item['district_id'].toString(),
          anaemiaPct: (item['anaemia_children_6_59_months_pct'] as num)
              .toDouble(),
          stuntingPct: (item['stunting_under_5_pct'] as num).toDouble(),
          immunizationPct: (item['full_immunization_12_23_months_pct'] as num)
              .toDouble(),
        ),
  ];
}

List<BankQuestion> _questions(String raw) {
  final root = (jsonDecode(raw) as Map).cast<String, Object?>();
  final list = root['questions'];
  if (list is! List) throw FormatException('questions array missing');
  return [
    for (final item in list)
      if (item is Map) _question((item).cast<String, Object?>()),
  ];
}

BankQuestion _question(Map<String, Object?> json) {
  final textRaw = json['text'];
  final text = <String, String>{};
  if (textRaw is Map) {
    for (final entry in textRaw.entries) {
      text[entry.key.toString()] = entry.value.toString();
    }
  }
  final numericRaw = json['numeric'];
  NumericBounds? numeric;
  if (numericRaw is Map) {
    numeric = NumericBounds(
      unit: numericRaw['unit'].toString(),
      min: numericRaw['min'] as num,
      max: numericRaw['max'] as num,
      decimals: (numericRaw['decimals'] as num?)?.toInt() ?? 0,
    );
  }
  final optionsRaw = json['options'];
  return BankQuestion(
    id: json['id']! as String,
    module: json['module']! as String,
    text: text,
    type: json['type']! as String,
    weight: (json['weight'] as num).toInt(),
    isRedFlag: json['is_red_flag'] == true,
    inputField: json['input_field']! as String,
    invertYes: json['invert_yes'] == true,
    numeric: numeric,
    options: [
      if (optionsRaw is List)
        for (final option in optionsRaw)
          if (option is Map)
            ChoiceOption(
              value: option['value'].toString(),
              label: option['label'].toString(),
            ),
    ],
  );
}
