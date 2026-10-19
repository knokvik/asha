import 'package:flutter/material.dart';

/// The kind of answer required by a clinical question.
enum AnswerType {
  /// Yes / No / Unknown choice.
  yesNo,

  /// Selection from a discrete set of options.
  multipleChoice,

  /// Numeric measurement entry (e.g. respiratory rate, temperature).
  numeric,
}

/// Discrete option for multiple choice questions.
class ChoiceOption {
  const ChoiceOption({
    required this.value,
    required this.label,
    this.icon,
    this.description,
  });

  final String value;
  final String label;
  final IconData? icon;
  final String? description;
}

/// Numeric bounds and unit specifications for measurements.
class NumericPlausibility {
  const NumericPlausibility({
    required this.unit,
    required this.min,
    required this.max,
    this.decimals = 0,
    this.dangerThresholdLow,
    this.dangerThresholdHigh,
  });

  final String unit;
  final num min;
  final num max;
  final int decimals;
  final num? dangerThresholdLow;
  final num? dangerThresholdHigh;

  bool isPlausible(num val) => val >= min && val <= max;
}

/// A clinical assessment question.
class TriageQuestion {
  const TriageQuestion({
    required this.id,
    required this.fieldKey,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.type,
    this.options = const [],
    this.numeric,
    this.allowUnobtainable = false,
    this.icon = Icons.help_outline_rounded,
    this.isDangerSign = false,
  });

  final String id;
  final String fieldKey;
  final String title;
  final String subtitle;
  final String category;
  final AnswerType type;
  final List<ChoiceOption> options;
  final NumericPlausibility? numeric;
  final bool allowUnobtainable;
  final IconData icon;
  final bool isDangerSign;
}
