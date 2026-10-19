typedef JsonMap = Map<String, dynamic>;

/// Provenance of a single clinical field (architecture.md §7.2).
///
/// This enum is the mechanism that enforces SI-5: values the NLP layer guessed
/// but a human has not confirmed are invisible to the rule engine.
enum ClinicalSource {
  unset,
  extractedUnconfirmed,
  confirmedByWorker,
  guidedAnswer,
  measured,
  notAvailable,
}

extension ClinicalSourceX on ClinicalSource {
  String get wireName => switch (this) {
    ClinicalSource.unset => 'UNSET',
    ClinicalSource.extractedUnconfirmed => 'EXTRACTED_UNCONFIRMED',
    ClinicalSource.confirmedByWorker => 'CONFIRMED_BY_WORKER',
    ClinicalSource.guidedAnswer => 'GUIDED_ANSWER',
    ClinicalSource.measured => 'MEASURED',
    ClinicalSource.notAvailable => 'NOT_AVAILABLE',
  };

  /// SI-5. Only these sources may influence a band.
  bool get visibleToEngine => switch (this) {
    ClinicalSource.confirmedByWorker || ClinicalSource.guidedAnswer || ClinicalSource.measured || ClinicalSource.notAvailable => true,
    ClinicalSource.unset || ClinicalSource.extractedUnconfirmed => false,
  };

  static ClinicalSource fromWire(Object? value) => ClinicalSource.values.firstWhere(
    (source) => source.wireName == value,
    orElse: () => ClinicalSource.unset,
  );
}

class SourcedValue {
  const SourcedValue({required this.value, required this.source});

  const SourcedValue.unset() : value = null, source = ClinicalSource.unset;
  const SourcedValue.notAvailable() : value = null, source = ClinicalSource.notAvailable;
  const SourcedValue.guided(this.value) : source = ClinicalSource.guidedAnswer;
  const SourcedValue.measured(this.value) : source = ClinicalSource.measured;
  const SourcedValue.confirmed(this.value) : source = ClinicalSource.confirmedByWorker;
  const SourcedValue.extracted(this.value) : source = ClinicalSource.extractedUnconfirmed;

  final Object? value;
  final ClinicalSource source;

  bool get isUnknown => !source.visibleToEngine || value == null;
  bool get isUnobtainable => source == ClinicalSource.notAvailable;
  bool get isKnown => source.visibleToEngine && !isUnobtainable && value != null;

  Object? get projectedValue {
    if (isUnobtainable) return const UnobtainableValue();
    if (isUnknown) return const UnknownValue();
    return value;
  }

  SourcedValue copyWith({Object? value, ClinicalSource? source}) =>
      SourcedValue(value: value ?? this.value, source: source ?? this.source);

  JsonMap toJson() => {'value': value, 'source': source.wireName};

  factory SourcedValue.fromJson(Object? raw) {
    if (raw is Map<String, dynamic>) {
      return SourcedValue(value: raw['value'], source: ClinicalSourceX.fromWire(raw['source']));
    }
    if (raw is Map) {
      final map = raw.cast<String, dynamic>();
      return SourcedValue(value: map['value'], source: ClinicalSourceX.fromWire(map['source']));
    }
    return SourcedValue(value: raw, source: ClinicalSource.unset);
  }

  @override
  String toString() => 'SourcedValue($value, ${source.wireName})';
}

/// Private sentinels let the interpreter distinguish unknown from unobtainable
/// without putting magic strings into the clinical payload.
class UnknownValue {
  const UnknownValue();
  @override
  String toString() => 'UNKNOWN';
}

class UnobtainableValue {
  const UnobtainableValue();
  @override
  String toString() => 'UNOBTAINABLE';
}
