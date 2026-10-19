import '../domain/models/learning_models.dart';

class LearningContentRepository {
  static const List<MicroLesson> defaultLessons = [
    MicroLesson(
      id: 'lesson-neonatal-breathing',
      moduleId: 'mod-hbnc',
      title: 'Neonatal Fast Breathing & Chest Indrawing (PSBI)',
      description: 'Master the 60-second tap counter and identify early danger signs of severe bacterial illness.',
      durationMinutes: 3,
      category: LessonCategory.neonatal,
      format: LessonFormat.illustrated,
      dangerSignTriggerCode: 'FAST_BREATHING_NEONATE',
      isMandatory: true,
      contentMarkdown: '''
### Respiratory Rate Assessment in Infants (0–2 Months)

1. **Quiet Baby**: Never count when the baby is crying, feeding, or agitated.
2. **60-Second Timer**: Tap the screen once for each breath over a full 60 seconds. Do not multiply 15 seconds by 4.
3. **Threshold**:
   - **≥ 60 breaths/min** in an infant under 2 months indicates **FAST BREATHING** (RED flag).
   - Look for **severe chest indrawing** (lower chest wall moves inward during inhalation).
4. **Action**: Immediate referral to PHC/FRU. Escort mother and ensure thermal care (KMC).
''',
      quizQuestions: [
        QuizQuestion(
          id: 'q-neo-1',
          questionText: 'What is the fast-breathing threshold for an infant aged 15 days?',
          options: ['40 breaths/minute', '50 breaths/minute', '60 or more breaths/minute', '70 breaths/minute'],
          correctOptionIndex: 2,
          explanation: 'In infants under 2 months, 60 or more breaths per minute is classified as fast breathing.',
        ),
        QuizQuestion(
          id: 'q-neo-2',
          questionText: 'When should the ASHA measure the respiratory rate?',
          options: [
            'Immediately after vigorous crying',
            'When the baby is calm and quiet or sleeping',
            'While the baby is feeding at breast',
            'After waking the baby abruptly'
          ],
          correctOptionIndex: 1,
          explanation: 'Count only when the infant is calm and quiet to avoid false-positive tachypnea.',
        ),
        QuizQuestion(
          id: 'q-neo-3',
          questionText: 'Severe chest indrawing in a newborn indicates which severity triage?',
          options: ['GREEN (Normal)', 'YELLOW (Moderate)', 'RED (Emergency Urgent Referral)', 'Home monitoring only'],
          correctOptionIndex: 2,
          explanation: 'Chest indrawing is a primary sign of severe bacterial illness requiring RED triage.',
        ),
      ],
    ),
    MicroLesson(
      id: 'lesson-maternal-preeclampsia',
      moduleId: 'mod-anc',
      title: 'Pre-eclampsia & Severe Hypertension Danger Signs',
      description: 'Identify high BP danger signs during ANC visits to prevent eclampsia and maternal mortality.',
      durationMinutes: 3,
      category: LessonCategory.maternal,
      format: LessonFormat.audio,
      dangerSignTriggerCode: 'SEVERE_HYPERTENSION',
      isMandatory: true,
      contentMarkdown: '''
### Pre-eclampsia Clinical Protocol

1. **Measurement**: Measure BP in seated position with arm supported at heart level.
2. **Thresholds**:
   - **≥ 140/90 mmHg**: Mild-to-moderate pre-eclampsia (YELLOW triage).
   - **≥ 160/110 mmHg**: Severe pre-eclampsia (RED triage).
3. **Cardinal Danger Signs**:
   - Severe, persistent frontal headache unresponsive to paracetamol.
   - Blurred or double vision, seeing flashes of light.
   - Severe epigastric or right upper quadrant pain.
   - Rapid facial and pedal swelling.
4. **Action**: Immediate RED referral to facility with emergency obstetric and MgSO4 capability.
''',
      quizQuestions: [
        QuizQuestion(
          id: 'q-mat-1',
          questionText: 'Which systolic/diastolic blood pressure reading triggers a severe RED flag in pregnancy?',
          options: ['120/80 mmHg', '130/85 mmHg', '140/90 mmHg', '160/110 mmHg or higher'],
          correctOptionIndex: 3,
          explanation: 'A BP of ≥ 160/110 mmHg represents severe pre-eclampsia requiring emergency referral.',
        ),
        QuizQuestion(
          id: 'q-mat-2',
          questionText: 'Which symptom alongside high BP indicates impending eclampsia convulsions?',
          options: ['Visual flashes or blurring', 'Mild ankle edema', 'Normal fetal movements', 'Clear urine output'],
          correctOptionIndex: 0,
          explanation: 'Visual disturbances and severe headache indicate cerebral edema and impending seizure.',
        ),
      ],
    ),
    MicroLesson(
      id: 'lesson-tb-symptom-screening',
      moduleId: 'mod-tb',
      title: 'Active TB Case Finding & Sputum Linkage',
      description: 'Screening criteria for presumptive pulmonary TB and Nikshay adherence tracking.',
      durationMinutes: 4,
      category: LessonCategory.tb,
      format: LessonFormat.illustrated,
      dangerSignTriggerCode: 'TB_SYMPTOMS',
      isMandatory: false,
      contentMarkdown: '''
### Presumptive TB Identification

1. **Screening Criteria**:
   - Cough of 2 weeks or more.
   - Blood in sputum (haemoptysis).
   - Unexplained fever for more than 2 weeks, especially in the evening.
   - Significant unexplained weight loss or night sweats.
2. **Action**: Collect sputum referral slip, link Nikshay ID, coordinate with ANM for CBNAAT/Truenat testing.
''',
      quizQuestions: [
        QuizQuestion(
          id: 'q-tb-1',
          questionText: 'What cough duration triggers presumptive TB investigation under National TB Elimination Program?',
          options: ['3 days', '1 week', '2 weeks or longer', '1 month'],
          correctOptionIndex: 2,
          explanation: 'Any persistent cough lasting 2 weeks or more warrants diagnostic sputum evaluation.',
        ),
      ],
    ),
    MicroLesson(
      id: 'lesson-softskills-counselling',
      moduleId: 'mod-softskills',
      title: 'Supportive Health Counselling & Vaccine Hesitancy',
      description: 'Techniques for empathetic listening and addressing caregiver fears without judgment.',
      durationMinutes: 3,
      category: LessonCategory.softSkills,
      format: LessonFormat.audio,
      isMandatory: false,
      contentMarkdown: '''
### Empathetic Communication Principles

1. **Acknowledge Concerns First**: Never dismiss a mother's fear of vaccine fever as "foolish". Validate her maternal care.
2. **Simple Explanations**: Explain that mild fever shows the baby's body is building strong natural shields against deadly diseases.
3. **Offer Solutions**: Advise on paracetamol drops and clean cool compresses. Assure your availability if fever persists.
''',
      quizQuestions: [
        QuizQuestion(
          id: 'q-soft-1',
          questionText: 'When a family expresses fear of vaccine side effects, what is the most effective approach?',
          options: [
            'Threaten to cancel government rations',
            'Listen respectfully, acknowledge their fear, and clearly explain benefits',
            'Argue and leave immediately',
            'Tell them side effects never happen'
          ],
          correctOptionIndex: 1,
          explanation: 'Empathetic listening and honest guidance build lasting community trust and compliance.',
        ),
      ],
    ),
  ];

  static const List<SimulatedClinicalScenario> defaultScenarios = [
    SimulatedClinicalScenario(
      id: 'sim-01',
      title: 'Simulated Case: 18-day-old Neonate with Fever & Poor Feeding',
      patientProfile: 'Infant Aarav, 18 days old, male. Delivered at home.',
      presentingSymptoms: 'Mother reports baby stopped feeding vigorously 6 hours ago and feels hot to touch.',
      availableObservations: [
        'Temperature: 101.2 °F (Axillary)',
        'Respiratory Rate: 64 breaths/minute (tap counted)',
        'Chest: Mild lower chest indrawing observed',
        'Activity: Lethargic, weak cry when stimulated',
      ],
      correctSeverity: 'RED',
      correctNextAction: 'Immediate referral to nearest FRU/SNCU for presumptive neonatal sepsis (PSBI). Keep baby warm.',
      teachingPoints: 'Any temperature > 99.5 °F or < 95.9 °F combined with fast breathing and lethargy in a neonate is a life-threatening emergency.',
    ),
    SimulatedClinicalScenario(
      id: 'sim-02',
      title: 'Simulated Case: Primigravida with Severe Pallor at 24 Weeks',
      patientProfile: 'Pooja, 20 years old, 1st pregnancy, 24 weeks gestation.',
      presentingSymptoms: 'Complains of dizziness when standing and breathlessness on mild exertion.',
      availableObservations: [
        'Palms and conjunctiva: Marked severe pallor',
        'Hemoglobin (Point of Care): 6.4 g/dL',
        'Blood Pressure: 102/64 mmHg',
        'Pulse: 96 bpm',
      ],
      correctSeverity: 'RED',
      correctNextAction: 'Urgent referral for parenteral Iron Sucrose infusion at PHC/CHC. Prescribe dietary counselling.',
      teachingPoints: 'Severe anaemia (< 7 g/dL) in second/third trimester cannot be managed by oral iron alone due to delayed response; requires facility-level parenteral management.',
    ),
  ];

  static const List<JobAidReferenceCard> defaultJobAids = [
    JobAidReferenceCard(
      id: 'job-hbnc-visit-schedule',
      title: 'HBNC Home Visit Schedule (Institutional vs Home Delivery)',
      programCategory: 'HBNC',
      keywords: ['hbnc', 'schedule', 'home visits', 'infant', 'postnatal'],
      summarySteps: '''
• Institutional Delivery (6 visits): Days 3, 7, 14, 21, 28, 42.
• Home Delivery (7 visits): Days 1 (within 24 hrs), 3, 7, 14, 21, 28, 42.
• Every visit check: Temperature, weight, umbilical stump, eye discharge, breastfeeding latch, respiratory rate.
''',
      dosageOrThresholdTable: 'Fast breathing: ≥ 60 bpm (< 2 mo). Fever: > 99.5 °F. Hypothermia: < 95.9 °F.',
      redFlags: 'Chest indrawing, convulsions, lethargy/unconsciousness, yellow palms/soles (jaundice).',
    ),
    JobAidReferenceCard(
      id: 'job-drug-doses-paracetamol-ors',
      title: 'Drug Dosing Guide: Paracetamol & ORS/Zinc for ASHAs',
      programCategory: 'Child Health',
      keywords: ['dosage', 'paracetamol', 'ors', 'zinc', 'diarrhoea', 'fever'],
      summarySteps: '''
• ORS: 1 packet in 1 litre clean boiled water. Offer after every loose stool (50–100 ml for < 2 yrs; 100–200 ml for older).
• Zinc: 10 mg/day for infants 2–6 months; 20 mg/day for > 6 months for 14 continuous days.
• Paracetamol syrup (125mg/5ml): 10–15 mg/kg per dose. Max 4 doses in 24 hours.
''',
      dosageOrThresholdTable: 'Zinc 14-day completion is essential even after diarrhoea stops to prevent relapse.',
      redFlags: 'Blood in stool, sunken eyes, skin pinch goes back very slowly (severe dehydration → RED).',
    ),
    JobAidReferenceCard(
      id: 'job-cbac-ncd-scoring',
      title: 'Community-Based Assessment Checklist (CBAC) for NCDs (30+)',
      programCategory: 'NCD',
      keywords: ['cbac', 'ncd', 'hypertension', 'diabetes', 'cancer', 'screening'],
      summarySteps: '''
• Screen all individuals aged 30 and older annually.
• Section A (Part 1): Age, tobacco use, alcohol, waist circumference, physical activity, family history.
• Score > 4 requires prioritized facility-level screening by ANM/MO for HTN and diabetes.
''',
      dosageOrThresholdTable: 'Waist: > 90 cm (men), > 80 cm (women) gives +2 points on CBAC scorecard.',
      redFlags: 'Non-healing oral ulcer > 2 weeks, lump in breast, irregular post-menopausal bleeding.',
    ),
  ];
}
