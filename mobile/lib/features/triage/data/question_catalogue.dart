import 'package:flutter/material.dart';
import '../domain/question_model.dart';

/// Clinical question catalogue matching WHO IMCI & National Guidelines.
///
/// Categorized into:
/// 1. General Danger Signs (Multiple Choice: Yes/No/Unknown)
/// 2. Vital Signs (Enter Value: Numeric with boundaries)
/// 3. Nutrition & MUAC (Enter Value / Multiple Choice)
/// 4. Common Symptoms & Physical Examination (Multiple Choice)
class QuestionCatalogue {
  const QuestionCatalogue._();

  static List<TriageQuestion> get allQuestions => [
        // ── 1. General Danger Signs (Multiple Choice) ──
        const TriageQuestion(
          id: 'q_unable_drink',
          fieldKey: 'unable_to_drink',
          category: 'General Danger Signs',
          title: 'Is the child unable to drink or breastfeed?',
          subtitle: 'Child is unable to suckle or swallow anything offered.',
          type: AnswerType.yesNo,
          isDangerSign: true,
          icon: Icons.local_drink_rounded,
        ),
        const TriageQuestion(
          id: 'q_vomits_everything',
          fieldKey: 'vomits_everything',
          category: 'General Danger Signs',
          title: 'Does the child vomit everything?',
          subtitle: 'Cannot retain any food, milk, or fluids at all.',
          type: AnswerType.yesNo,
          isDangerSign: true,
          icon: Icons.sick_rounded,
        ),
        const TriageQuestion(
          id: 'q_convulsions',
          fieldKey: 'convulsions',
          category: 'General Danger Signs',
          title: 'Has the child had convulsions during this illness?',
          subtitle: 'Focal or generalized fits, seizures, or rolling of eyes.',
          type: AnswerType.yesNo,
          isDangerSign: true,
          icon: Icons.flash_on_rounded,
        ),
        const TriageQuestion(
          id: 'q_lethargy',
          fieldKey: 'lethargic_or_unconscious',
          category: 'General Danger Signs',
          title: 'Is the child lethargic or unconscious?',
          subtitle: 'Difficult to awaken, limp, or not responding to voice/touch.',
          type: AnswerType.yesNo,
          isDangerSign: true,
          icon: Icons.hotel_rounded,
        ),
        const TriageQuestion(
          id: 'q_stridor',
          fieldKey: 'stridor',
          category: 'General Danger Signs',
          title: 'Is there stridor in a calm child?',
          subtitle: 'Harsh, high-pitched noise while breathing in when child is resting.',
          type: AnswerType.yesNo,
          isDangerSign: true,
          icon: Icons.volume_up_rounded,
        ),
        const TriageQuestion(
          id: 'q_chest_indrawing',
          fieldKey: 'chest_indrawing',
          category: 'General Danger Signs',
          title: 'Is there chest indrawing?',
          subtitle: 'Lower chest wall moves inward when the child breathes in.',
          type: AnswerType.yesNo,
          isDangerSign: true,
          icon: Icons.airline_seat_flat_rounded,
        ),

        // ── 2. Vital Signs (Enter Value / Numeric) ──
        const TriageQuestion(
          id: 'q_age_days',
          fieldKey: 'age_in_days',
          category: 'Patient Vitals',
          title: 'Age of the child',
          subtitle: 'Child age in days (or approx months x 30)',
          type: AnswerType.numeric,
          icon: Icons.cake_rounded,
          numeric: NumericPlausibility(
            unit: 'days',
            min: 1,
            max: 1825, // 5 years
          ),
        ),
        const TriageQuestion(
          id: 'q_resp_rate',
          fieldKey: 'respiratory_rate',
          category: 'Patient Vitals',
          title: 'Respiratory Rate',
          subtitle: 'Count breaths for a full 60 seconds while the child is calm.',
          type: AnswerType.numeric,
          allowUnobtainable: true,
          icon: Icons.air_rounded,
          numeric: NumericPlausibility(
            unit: 'breaths/min',
            min: 10,
            max: 140,
            dangerThresholdHigh: 50,
          ),
        ),
        const TriageQuestion(
          id: 'q_temperature',
          fieldKey: 'temperature',
          category: 'Patient Vitals',
          title: 'Body Temperature',
          subtitle: 'Axillary temperature measured with thermometer.',
          type: AnswerType.numeric,
          allowUnobtainable: true,
          icon: Icons.thermostat_rounded,
          numeric: NumericPlausibility(
            unit: '°C',
            min: 32.0,
            max: 43.0,
            decimals: 1,
            dangerThresholdLow: 35.5,
            dangerThresholdHigh: 38.5,
          ),
        ),

        // ── 3. Nutrition & MUAC (Enter Value & Multiple Choice) ──
        const TriageQuestion(
          id: 'q_muac',
          fieldKey: 'muac_mm',
          category: 'Nutrition & Growth',
          title: 'Mid-Upper Arm Circumference (MUAC)',
          subtitle: 'Measured with Shakir tape on relaxed left upper arm.',
          type: AnswerType.numeric,
          allowUnobtainable: true,
          icon: Icons.straighten_rounded,
          numeric: NumericPlausibility(
            unit: 'mm',
            min: 70,
            max: 250,
            dangerThresholdLow: 115,
          ),
        ),
        const TriageQuestion(
          id: 'q_edema',
          fieldKey: 'edema_both_feet',
          category: 'Nutrition & Growth',
          title: 'Bilateral Pitting Edema of Feet?',
          subtitle: 'Thumb depression leaves indentation on both feet for 3 seconds.',
          type: AnswerType.yesNo,
          isDangerSign: true,
          icon: Icons.do_not_step_rounded,
        ),

        // ── 4. Dehydration & Symptoms (Multiple Choice) ──
        const TriageQuestion(
          id: 'q_skin_pinch',
          fieldKey: 'skin_pinch',
          category: 'Symptoms & Examination',
          title: 'Skin pinch test for dehydration',
          subtitle: 'Pinch the skin of the abdomen for 1 second and release.',
          type: AnswerType.multipleChoice,
          icon: Icons.touch_app_rounded,
          options: [
            ChoiceOption(
              value: 'normal',
              label: 'Goes back immediately (< 1s)',
              description: 'Normal hydration',
            ),
            ChoiceOption(
              value: 'slow',
              label: 'Goes back slowly (1 to 2s)',
              description: 'Some dehydration',
            ),
            ChoiceOption(
              value: 'very_slow',
              label: 'Goes back very slowly (> 2s)',
              description: 'Severe dehydration danger sign',
            ),
          ],
        ),
        const TriageQuestion(
          id: 'q_sunken_eyes',
          fieldKey: 'sunken_eyes',
          category: 'Symptoms & Examination',
          title: 'Are the child\'s eyes sunken?',
          subtitle: 'Ask caregiver if eyes look deeper into the skull than usual.',
          type: AnswerType.yesNo,
          icon: Icons.remove_red_eye_rounded,
        ),
        const TriageQuestion(
          id: 'q_diarrhoea',
          fieldKey: 'diarrhoea',
          category: 'Symptoms & Examination',
          title: 'Does the child have loose or watery stools?',
          subtitle: 'Three or more loose stools in 24 hours.',
          type: AnswerType.yesNo,
          icon: Icons.water_drop_rounded,
        ),
      ];

  static List<String> get categories => [
        'General Danger Signs',
        'Patient Vitals',
        'Nutrition & Growth',
        'Symptoms & Examination',
      ];

  static List<TriageQuestion> byCategory(String category) =>
      allQuestions.where((q) => q.category == category).toList();
}
