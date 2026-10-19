import 'package:core_triage/core_triage.dart';
import 'package:flutter/material.dart';

/// How one Setu question is answered. Same three kinds as Setu's catalogue.
enum SetuAnswerKind { yesNo, choice, numeric }

class SetuQuestionOption {
  const SetuQuestionOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

class SetuNumericSpec {
  const SetuNumericSpec({
    required this.unit,
    required this.min,
    required this.max,
    this.decimals = 0,
  });

  final String unit;
  final num min;
  final num max;
  final int decimals;

  bool isPlausible(num value) => value >= min && value <= max;
}

/// One screen, one observable question. Prompts are Setu's English wording.
class SetuQuestion {
  const SetuQuestion({
    required this.path,
    required this.icon,
    required this.prompt,
    this.kind = SetuAnswerKind.yesNo,
    this.options = const [],
    this.numeric,
    this.allowUnobtainable = false,
  });

  final String path;
  final IconData icon;
  final String prompt;
  final SetuAnswerKind kind;
  final List<SetuQuestionOption> options;
  final SetuNumericSpec? numeric;
  final bool allowUnobtainable;
}

/// The question order Setu walks: danger signs, then what you can see, then
/// what you ask, then the measurements.
abstract final class SetuQuestionCatalogue {
  static List<SetuQuestion> forPaths(Iterable<String> paths) {
    final wanted = paths.toSet();
    return _all.where((question) => wanted.contains(question.path)).toList(growable: false);
  }

  static final List<SetuQuestion> _all = [
    SetuQuestion(
      path: FieldPaths.unableToDrinkOrBreastfeed,
      icon: Icons.local_drink_rounded,
      prompt: 'Can the child drink or breastfeed?',
    ),
    SetuQuestion(
      path: FieldPaths.vomitsEverything,
      icon: Icons.sick_rounded,
      prompt: 'Does the child vomit everything?',
    ),
    SetuQuestion(
      path: FieldPaths.convulsionsThisIllness,
      icon: Icons.bolt_rounded,
      prompt: 'Has the child had convulsions?',
    ),
    SetuQuestion(
      path: FieldPaths.convulsingNow,
      icon: Icons.flash_on_rounded,
      prompt: 'Is the child convulsing now?',
    ),
    SetuQuestion(
      path: FieldPaths.lethargicOrUnconscious,
      icon: Icons.bedtime_rounded,
      prompt: 'Is the child very sleepy or difficult to wake?',
    ),
    SetuQuestion(
      path: FieldPaths.chestIndrawing,
      icon: Icons.air_rounded,
      prompt: 'Does the chest pull in while breathing?',
    ),
    SetuQuestion(
      path: FieldPaths.stridorWhenCalm,
      icon: Icons.volume_up_rounded,
      prompt: 'Is there a harsh sound when the child is calm?',
    ),
    SetuQuestion(
      path: FieldPaths.grunting,
      icon: Icons.graphic_eq_rounded,
      prompt: 'When the child breathes OUT, do you hear a short grunting sound?',
    ),
    SetuQuestion(
      path: FieldPaths.nasalFlaring,
      icon: Icons.face_rounded,
      prompt: 'When the child breathes IN, do the sides of the nose widen?',
    ),
    SetuQuestion(
      path: FieldPaths.severeRespiratoryDistress,
      icon: Icons.warning_amber_rounded,
      prompt: 'Is the child struggling so hard to breathe that they cannot feed or speak?',
    ),
    SetuQuestion(
      path: FieldPaths.cough,
      icon: Icons.masks_rounded,
      prompt: 'Does the child have a cough or difficulty breathing?',
    ),
    SetuQuestion(
      path: FieldPaths.observedLethargic,
      icon: Icons.night_shelter_rounded,
      prompt: 'Is the child unusually sleepy, or hard to wake even when you call?',
    ),
    SetuQuestion(
      path: FieldPaths.fever,
      icon: Icons.thermostat_rounded,
      prompt: 'Does the child have fever, or has the body felt hot?',
    ),
    SetuQuestion(
      path: FieldPaths.stiffNeck,
      icon: Icons.accessibility_new_rounded,
      prompt: 'When you gently bend the neck forward, is it stiff or does the child resist?',
    ),
    SetuQuestion(
      path: FieldPaths.diarrhoea,
      icon: Icons.water_drop_rounded,
      prompt: 'Does the child have diarrhoea?',
    ),
    SetuQuestion(
      path: FieldPaths.sunkenEyes,
      icon: Icons.remove_red_eye_rounded,
      prompt: 'Do the child’s eyes look sunken compared with usual?',
    ),
    SetuQuestion(
      path: FieldPaths.skinPinch,
      icon: Icons.back_hand_rounded,
      prompt: 'Pinch the skin of the abdomen and release. How fast does it go back?',
      kind: SetuAnswerKind.choice,
      options: const [
        SetuQuestionOption(value: 'NORMAL', label: 'Goes back immediately', icon: Icons.check_circle_outline_rounded),
        SetuQuestionOption(value: 'SLOW', label: 'Goes back slowly (under 2 seconds)', icon: Icons.hourglass_bottom_rounded),
        SetuQuestionOption(value: 'VERY_SLOW', label: 'Goes back very slowly (over 2 seconds)', icon: Icons.error_outline_rounded),
      ],
    ),
    SetuQuestion(
      path: FieldPaths.drinkingPattern,
      icon: Icons.water_rounded,
      prompt: 'Offer the child water. How does the child drink?',
      kind: SetuAnswerKind.choice,
      options: const [
        SetuQuestionOption(value: 'NORMAL', label: 'Drinks normally', icon: Icons.check_circle_outline_rounded),
        SetuQuestionOption(value: 'EAGER_THIRSTY', label: 'Drinks eagerly, seems very thirsty', icon: Icons.local_drink_rounded),
        SetuQuestionOption(value: 'POOR_OR_UNABLE', label: 'Drinks poorly or is unable to drink', icon: Icons.error_outline_rounded),
      ],
    ),
    SetuQuestion(
      path: FieldPaths.oedemaBothFeet,
      icon: Icons.pan_tool_rounded,
      prompt: 'Press the top of BOTH feet for 3 seconds. Does a dent stay in the skin?',
    ),
    SetuQuestion(
      path: FieldPaths.visibleSevereWasting,
      icon: Icons.monitor_weight_rounded,
      prompt: 'Are the ribs and shoulder bones clearly visible, with very little muscle?',
    ),
    SetuQuestion(
      path: FieldPaths.respiratoryRate,
      icon: Icons.timer_rounded,
      prompt: 'Count the breaths for a full 60 seconds',
      kind: SetuAnswerKind.numeric,
      numeric: const SetuNumericSpec(unit: '/min', min: 10, max: 120),
      allowUnobtainable: true,
    ),
    SetuQuestion(
      path: FieldPaths.temperatureC,
      icon: Icons.thermostat_rounded,
      prompt: 'Measure the temperature (°C, axillary)',
      kind: SetuAnswerKind.numeric,
      numeric: const SetuNumericSpec(unit: '°C', min: 30, max: 43, decimals: 1),
      allowUnobtainable: true,
    ),
    SetuQuestion(
      path: FieldPaths.muacMm,
      icon: Icons.straighten_rounded,
      prompt: 'Measure mid-upper arm circumference (mm)',
      kind: SetuAnswerKind.numeric,
      numeric: const SetuNumericSpec(unit: 'mm', min: 70, max: 250),
      allowUnobtainable: true,
    ),
  ];
}
