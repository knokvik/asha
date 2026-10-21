import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _assetPath = 'assets/search/asha_master_search.csv';

/// One offline knowledge-card row from the ASHA master search catalog.
class SearchKnowledgeEntry {
  const SearchKnowledgeEntry({
    required this.id,
    required this.category,
    required this.keywordEn,
    required this.keywordHi,
    required this.keywordMr,
    required this.name,
    required this.purpose,
    required this.doseOrProtocol,
    required this.howToUse,
    required this.whenToRefer,
    required this.dangerSigns,
    required this.sourceRef,
    required this.approxPrice,
  });

  final String id;
  final String category;
  final String keywordEn;
  final String keywordHi;
  final String keywordMr;
  final String name;
  final String purpose;
  final String doseOrProtocol;
  final String howToUse;
  final String whenToRefer;
  final String dangerSigns;
  final String sourceRef;
  final String approxPrice;

  String get categoryLabel => switch (category) {
    'medicine' => 'Medicine',
    'measure' => 'Measurement',
    'guide' => 'Guide',
    'danger_sign' => 'Danger sign',
    'program' => 'Programme',
    'warning' => 'Safety warning',
    _ => category,
  };

  String get searchableText => [
    keywordEn,
    keywordHi,
    keywordMr,
    name,
    purpose,
    doseOrProtocol,
    howToUse,
    whenToRefer,
    dangerSigns,
    sourceRef,
  ].join(' ');
}

class OfflineSearchIndex {
  OfflineSearchIndex(this.entries);

  /// Testable parser entry point for a downloaded or bundled catalog.
  factory OfflineSearchIndex.fromCsv(String csv) {
    return OfflineSearchIndex(_parseCsv(csv));
  }

  final List<SearchKnowledgeEntry> entries;

  static Future<OfflineSearchIndex> load() async {
    final csv = await rootBundle.loadString(_assetPath);
    return OfflineSearchIndex.fromCsv(csv);
  }

  List<SearchKnowledgeEntry> search(
    String query, {
    String? category,
    int limit = 30,
  }) {
    final normalizedQuery = _normalise(query);
    if (normalizedQuery.isEmpty) return const [];
    final tokens = normalizedQuery.split(RegExp(r'\s+'));
    final ranked = <({SearchKnowledgeEntry entry, int score})>[];

    for (final entry in entries) {
      if (category != null && entry.category != category) continue;
      final name = _normalise(entry.name);
      final keywords = _normalise(
        '${entry.keywordEn} ${entry.keywordHi} ${entry.keywordMr}',
      );
      final searchable = _normalise(entry.searchableText);
      var score = 0;
      if (name.contains(normalizedQuery)) score += 90;
      if (keywords.contains(normalizedQuery)) score += 70;
      if (searchable.contains(normalizedQuery)) score += 30;
      for (final token in tokens) {
        if (token.length < 2) continue;
        if (name.contains(token)) score += 18;
        if (keywords.contains(token)) score += 12;
        if (searchable.contains(token)) score += 4;
      }
      if (score > 0) ranked.add((entry: entry, score: score));
    }

    ranked.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      return byScore == 0 ? a.entry.name.compareTo(b.entry.name) : byScore;
    });
    return [for (final result in ranked.take(limit)) result.entry];
  }
}

final offlineSearchIndexProvider = FutureProvider<OfflineSearchIndex>((ref) {
  return OfflineSearchIndex.load();
});

List<SearchKnowledgeEntry> _parseCsv(String input) {
  final rows = <List<String>>[];
  final currentRow = <String>[];
  final current = StringBuffer();
  var quoted = false;

  void finishField() {
    currentRow.add(current.toString());
    current.clear();
  }

  void finishRow() {
    if (currentRow.isNotEmpty || current.isNotEmpty) finishField();
    if (currentRow.isNotEmpty) rows.add(List<String>.from(currentRow));
    currentRow.clear();
  }

  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (char == '"') {
      if (quoted && i + 1 < input.length && input[i + 1] == '"') {
        current.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (char == ',' && !quoted) {
      finishField();
    } else if ((char == '\n' || char == '\r') && !quoted) {
      if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
        i++;
      }
      finishRow();
    } else {
      current.write(char);
    }
  }
  finishRow();

  if (rows.isEmpty) return const [];
  final header = [for (final value in rows.first) _normalise(value)];
  final index = <String, int>{
    for (var i = 0; i < header.length; i++) header[i]: i,
  };
  String value(List<String> row, String key) {
    final position = index[_normalise(key)];
    if (position == null || position >= row.length) return '';
    return row[position].trim();
  }

  return [
    for (final row in rows.skip(1))
      if (row.length >= header.length)
        SearchKnowledgeEntry(
          id: value(row, 'id'),
          category: value(row, 'category'),
          keywordEn: value(row, 'keyword_en'),
          keywordHi: value(row, 'keyword_hi'),
          keywordMr: value(row, 'keyword_mr'),
          name: value(row, 'name'),
          purpose: value(row, 'purpose'),
          doseOrProtocol: value(row, 'dose_or_protocol'),
          howToUse: value(row, 'how_to_use'),
          whenToRefer: value(row, 'when_to_refer'),
          dangerSigns: value(row, 'danger_signs'),
          sourceRef: value(row, 'source_ref'),
          approxPrice: value(row, 'approx_price_inr'),
        ),
  ];
}

String _normalise(String value) =>
    value.replaceFirst('\ufeff', '').toLowerCase().trim();
