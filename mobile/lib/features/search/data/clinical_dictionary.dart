import 'package:flutter/material.dart';

/// Medicine dosage item for a disease counter-measure protocol.
class MedicineProtocol {
  final String name;
  final String indication;
  final String dosage;
  final String form;
  final String howToAdminister;
  final String cautionWarning;

  const MedicineProtocol({
    required this.name,
    required this.indication,
    required this.dosage,
    required this.form,
    required this.howToAdminister,
    this.cautionWarning = '',
  });
}

/// Clinical Disease or Condition in the ASHA field knowledge dictionary.
class ClinicalDisease {
  final String id;
  final String nameEn;
  final String nameLocal;
  final String shortDescription;
  final String severityBadge;
  final Color badgeColor;
  final List<String> keywords;
  final String introduction;
  final List<String> counterMeasures;
  final List<MedicineProtocol> medicines;
  final List<String> dangerSigns;
  final List<String> referralProtocol;
  final List<String> preventionTips;
  final String sourceGuidelines;

  const ClinicalDisease({
    required this.id,
    required this.nameEn,
    required this.nameLocal,
    required this.shortDescription,
    required this.severityBadge,
    required this.badgeColor,
    required this.keywords,
    required this.introduction,
    required this.counterMeasures,
    required this.medicines,
    required this.dangerSigns,
    required this.referralProtocol,
    required this.preventionTips,
    required this.sourceGuidelines,
  });

  String get searchableText => [
        nameEn,
        nameLocal,
        shortDescription,
        introduction,
        ...keywords,
        ...counterMeasures,
        ...medicines.map((m) => '${m.name} ${m.indication} ${m.dosage} ${m.cautionWarning}'),
        ...dangerSigns,
        ...referralProtocol,
        ...preventionTips,
        sourceGuidelines,
      ].join(' ').toLowerCase();
}

/// Comprehensive ASHA Clinical Dictionary covering national health mission programs:
/// IMCI, HBNC, HBYC, NVBDCP, Anemia Mukt Bharat, NTEP, and NPCDCS.
class ClinicalDictionary {
  ClinicalDictionary._();

  static const List<ClinicalDisease> allDiseases = [
    // 1. FEVER / PYREXIA
    ClinicalDisease(
      id: 'DIS_FEVER',
      nameEn: 'Fever (Pyrexia) / Acute Febrile Illness',
      nameLocal: 'बुखार / ताप / Febrile Illness',
      shortDescription:
          'Elevation of body temperature ≥37.5°C (99.5°F). Early antipyretic relief, danger sign screening, and malaria/dengue triage.',
      severityBadge: 'High Priority Triage',
      badgeColor: Color(0xFFE11D48),
      keywords: [
        'fever',
        'pyrexia',
        'temperature',
        'bukhar',
        'taap',
        'thand',
        'shivering',
        'paracetamol',
        'hot body',
        'infant fever',
        'high temperature',
      ],
      introduction:
          'Fever (Pyrexia) is a core physiological sign of infection where axillary temperature reaches ≥37.5°C (99.5°F) or oral/rectal reaches ≥38.0°C (100.4°F). In rural and semi-urban catchment communities, common etiologies include viral upper respiratory infections, Malaria (Plasmodium vivax/falciparum), Dengue, Typhoid (Enteric fever), Pneumonia, and Urinary Tract Infections. Immediate classification via IMCI / NVBDCP protocols prevents rapid deterioration into febrile seizures, cerebral malaria, or septic shock.',
      counterMeasures: [
        'Tepid Sponging: Gently sponge the forehead, neck, armpits, and groin with clean room-temperature water (30–32°C). NEVER use cold water, ice, or alcohol rubs, which trigger shivering and paradoxically spike core body temperature.',
        'Continuous Fluid Hydration: Offer frequent sips of clean boiled water, ORS solution, thin rice kanji, coconut water, or fresh lemon water to replenish sweat losses. For infants under 6 months, strictly maintain frequent exclusive breastfeeding.',
        'Comfortable Loose Clothing: Keep the patient in a single layer of loose, breathable cotton clothing. Maintain airflow and good room ventilation. Remove thick quilts and blankets even if the patient reports feeling chilly.',
        'Regular Temperature Monitoring: Re-measure axillary temperature with a digital thermometer every 2–4 hours and record values in the ASHA diary/app.',
        'Malaria Finger-Prick RDT: In NVBDCP malaria-endemic areas, perform a finger-prick Bivalent Malaria Rapid Diagnostic Test (RDT) before giving antimalarials.',
      ],
      medicines: [
        MedicineProtocol(
          name: 'Paracetamol (Tablet 500mg / Syrup 125mg/5ml)',
          indication: 'First-line antipyretic for fever relief and pain management',
          dosage:
              '10–15 mg/kg per dose orally every 6 hours (max 4 doses in 24 hours).\n• 2–12 months (4–9 kg): 2.5–5 ml syrup (60–120 mg)\n• 1–3 years (10–14 kg): 5–10 ml syrup (120–240 mg)\n• 4–5 years (15–19 kg): 10–15 ml syrup or 1/2 tab 500mg (240–360 mg)\n• Older children & Adults: 1 tablet 500mg every 6 hours after food (max 2000mg/day)',
          form: 'Oral tablet 500mg or paediatric syrup 125mg per 5ml',
          howToAdminister:
              'Give orally with water after food or breastfeed. Measure paediatric syrup strictly with dosing cup or syringe.',
          cautionWarning:
              'CRITICAL WARNING: NEVER give Aspirin (Disprin) to children under 16 years — risk of fatal Reye\'s Syndrome. NEVER give Ibuprofen if Dengue is suspected — exacerbates platelet bleeding.',
        ),
        MedicineProtocol(
          name: 'WHO-ORS (Oral Rehydration Salts)',
          indication: 'Prevents dehydration caused by fever sweating and reduced oral intake',
          dosage: '1 sachet dissolved in exactly 1 litre clean drinking water. Sip frequently throughout the day.',
          form: 'Oral powder sachet (20.5g WHO low-osmolarity formula)',
          howToAdminister: 'Dissolve entire sachet in 1 litre water. Store covered. Discard unused solution after 24 hours.',
          cautionWarning: 'Do not add sugar, milk, or juice into the ORS solution.',
        ),
      ],
      dangerSigns: [
        'Any fever in an infant under 2 months of age (potential neonatal sepsis).',
        'High fever ≥39.5°C (103°F) unyielding to paracetamol after 2 hours.',
        'Convulsions, fits, seizures, or rolling back of eyes (febrile seizure or cerebral malaria).',
        'Child is abnormally sleepy, lethargic, floppy, or difficult to wake.',
        'Stiff neck (child cannot touch chin to chest).',
        'Inability to drink or breastfeed; vomits everything consumed.',
        'Fast breathing or lower chest wall indrawing (pneumonia complication).',
        'Non-blanching red/purple petechial rash or mucosal bleeding (Dengue hemorrhagic warning).',
        'Fever persisting for more than 5 consecutive days without clear origin.',
      ],
      referralProtocol: [
        'Emergency 108 Transport: Dial 108 Emergency Ambulance immediately or arrange Janani Shishu 102 vehicle.',
        'Pre-Referral Dose: Administer one age-appropriate dose of Paracetamol orally if temperature ≥38.5°C prior to transport.',
        'Convulsion First Aid: Keep airway clear, place child on their side (recovery position), do NOT put objects or fingers in mouth.',
        'Documentation: Record vitals (Temperature, Pulse, SpO2) on MCP referral slip or dispatch electronic referral in ASHA Setu app to PHC Medical Officer.',
        'Accompany Patient: Accompany family to the Community Health Centre (CHC) or District Hospital if red triage criteria are met.',
      ],
      preventionTips: [
        'Sleep under Long-Lasting Insecticidal Nets (LLINs) every night to prevent mosquito bites.',
        'Weekly Dry Day: Empty and scrub water coolers, flower pots, overhead tanks, and discarded tyres every Sunday to halt Aedes mosquito breeding.',
        'Complete Immunization: Verify and ensure timely doses of Measles-Rubella, Pentavalent, PCV, and Japanese Encephalitis vaccines.',
        'Food & Water Safety: Drink boiled or chlorinated water and wash hands thoroughly with soap before meals.',
      ],
      sourceGuidelines: 'IMCI Chart Booklet 2014 (MoHFW) • NVBDCP National Guidelines • NLEM 2022',
    ),

    // 2. ACUTE DIARRHOEA & DEHYDRATION
    ClinicalDisease(
      id: 'DIS_DIARRHOEA',
      nameEn: 'Acute Diarrhoea & Dehydration',
      nameLocal: 'दस्त / अतिसार / जुलाब / Dehydration',
      shortDescription:
          'Passage of ≥3 loose/watery stools in 24 hours. Immediate ORS hydration, Zinc 14-day course, and continuous feeding.',
      severityBadge: 'Urgent Hydration',
      badgeColor: Color(0xFF2563EB),
      keywords: [
        'diarrhoea',
        'diarrhea',
        'dast',
        'julab',
        'loose motion',
        'ors',
        'zinc',
        'dehydration',
        'watery stool',
        'vomiting',
        'sunken eyes',
        'cholera',
        'dysentery',
      ],
      introduction:
          'Acute Diarrhoea is defined as the passage of 3 or more loose or liquid stools per day (or more frequent than normal for an infant). It is a leading cause of child mortality in India, primarily through acute dehydration, electrolyte imbalance, and nutritional faltering. The cornerstone of community management is immediate oral rehydration therapy (WHO-ORS) combined with a mandatory 14-day course of Zinc to repair intestinal villi.',
      counterMeasures: [
        'Immediate ORS Administration: Start oral rehydration at home at the very first sign of loose stools. Give after every stool: under 2 years give 50–100 ml; 2 years and above give 100–200 ml.',
        'Mandatory 14-Day Zinc Course: Initiate Zinc dispersible tablets immediately. Continue daily for the FULL 14 days even after diarrhoea stops, to build intestinal mucosal immunity and prevent recurrence.',
        'Continue Feeding: Never withhold food or breast milk. Continue frequent breastfeeding and offer easily digestible foods (khichdi, mashed banana, curd).',
        'Assess Dehydration Level: Check for sunken eyes, skin pinch elasticity on abdomen (normal <1 sec, slow 1–2 sec, very slow >2 sec), and thirst.',
      ],
      medicines: [
        MedicineProtocol(
          name: 'WHO-ORS (Oral Rehydration Salts)',
          indication: 'Replaces lost water and essential electrolytes to prevent dehydration',
          dosage: 'Under 2y: 50–100ml after each stool; 2y+: 100–200ml after each stool. Sip slowly.',
          form: 'Sachet for 1 litre water (low-osmolarity formulation)',
          howToAdminister: 'Mix full packet in 1 litre boiled and cooled water. Give in small frequent sips using spoon or cup.',
          cautionWarning: 'Discard solution 24 hours after mixing. Never boil prepared ORS.',
        ),
        MedicineProtocol(
          name: 'Zinc Sulphate Dispersible Tablets',
          indication: 'Reduces diarrhoea duration, stool volume, and prevents recurrence for 3 months',
          dosage: '• Age <6 months: 10mg once daily for 14 days\n• Age 6 months – 5 years: 20mg once daily for 14 days',
          form: 'Dispersible tablet 10mg / 20mg',
          howToAdminister: 'Disperse tablet in a teaspoon of breast milk or clean water. Administer once daily for full 14 days.',
          cautionWarning: 'Must complete full 14-day course even if diarrhoea stops on day 2.',
        ),
      ],
      dangerSigns: [
        'Severe Dehydration: Child is lethargic, floppy, unconscious, or cannot drink.',
        'Sunken eyes with skin pinch going back very slowly (>2 seconds).',
        'Blood in stool (Dysentery / Shigellosis) — requires urgent medical evaluation and antibiotics.',
        'Repeated persistent vomiting (unable to retain any fluids).',
        'High fever accompanying watery stools.',
        'Diarrhoea persisting for more than 7–14 days (persistent diarrhoea).',
      ],
      referralProtocol: [
        'Severe Dehydration: Immediate emergency transfer to PHC/CHC for intravenous (IV) Ringer\'s Lactate.',
        'Give ORS in small sips en route to the health facility if child can swallow.',
        'Blood in Stool: Refer to PHC Medical Officer for ciprofloxacin/antibiotic prescription.',
      ],
      preventionTips: [
        'Exclusive breastfeeding for the first 6 months of life.',
        'Rotavirus vaccination at 6, 10, and 14 weeks of age.',
        'Proper handwashing with soap before preparing food, feeding, and after defecation.',
        'Safe drinking water storage using narrow-necked vessels with clean taps.',
      ],
      sourceGuidelines: 'MoHFW National Diarrhoea Control Programme • WHO IMCI Diarrhoea Guidelines',
    ),

    // 3. PNEUMONIA & ACUTE RESPIRATORY INFECTIONS
    ClinicalDisease(
      id: 'DIS_PNEUMONIA',
      nameEn: 'Pneumonia & Acute Respiratory Infections',
      nameLocal: 'निमोनिया / तीव्र श्वसन संक्रमण / सांस फूलना',
      shortDescription:
          'Fast breathing and chest indrawing in children. Timely classification, SpO2 check, and first-line dispersible Amoxicillin.',
      severityBadge: 'Critical Respiratory Risk',
      badgeColor: Color(0xFFDC2626),
      keywords: [
        'pneumonia',
        'cough',
        'cold',
        'fast breathing',
        'chest indrawing',
        'amoxicillin',
        'respiratory rate',
        'breathlessness',
        'stridor',
        'nimoniya',
        'khansi',
        'saans',
      ],
      introduction:
          'Pneumonia is an acute infection of the lung parenchyma causing alveolar fluid accumulation, rapid breathing, and hypoxia. It is the single largest infectious killer of children under 5 in India. ASHA workers screen for pneumonia using a 60-second respiratory rate count (HBNC timer) and visual assessment for lower chest wall indrawing and SpO2 pulse oximetry.',
      counterMeasures: [
        'Count Breathing for FULL 60 Seconds: Child must be calm and quiet (not crying or feeding). Observe chest rise and fall for a complete 60 seconds using the HBNC timer or app timer.',
        'Fast Breathing Cut-Offs:\n• Age 0–2 months: ≥60 breaths/min (Refer immediately)\n• Age 2–12 months: ≥50 breaths/min (Fast breathing)\n• Age 12–59 months: ≥40 breaths/min (Fast breathing)',
        'Check for Chest Indrawing: Lower chest wall moves inwards when the child breathes IN (abnormal and a severe sign).',
        'Check SpO2 with Pulse Oximeter: SpO2 <94% indicates hypoxemia; SpO2 ≤90% requires immediate oxygen therapy at facility.',
        'Keep Child Warm & Clear Nose: Keep the baby comfortably warm and clear thick nasal secretions with a saline drop/clean cloth before feeds.',
      ],
      medicines: [
        MedicineProtocol(
          name: 'Amoxicillin Dispersible Tablets (250mg)',
          indication: 'First-line antibiotic for non-severe pneumonia in children 2m–5y (per updated WHO/MoHFW)',
          dosage:
              '40–50 mg/kg/day divided in 2 daily doses for 5 days.\n• 2–12 months: 1/2 tab (125mg) twice daily for 5 days\n• 1–5 years: 1 tab (250mg) twice daily for 5 days',
          form: 'Dispersible tablet 250mg (strawberry/vanilla flavoured)',
          howToAdminister: 'Disperse tablet in clean water or breast milk. Give twice daily after feeds. Complete full 5 days.',
          cautionWarning: 'Do NOT use cough syrups, sedatives, or steroids for young children.',
        ),
      ],
      dangerSigns: [
        'Lower chest wall indrawing (subcostal retraction).',
        'Stridor (harsh vibrating sound heard when breathing in while child is calm).',
        'SpO2 saturation ≤90% on pulse oximeter.',
        'Inability to drink, suckle, or breastfeed; vomits everything.',
        'Convulsions or abnormal drowsiness / lethargy.',
        'Central cyanosis (bluish discolouration of lips, tongue, or fingertips).',
      ],
      referralProtocol: [
        'Severe Pneumonia (Chest Indrawing / Stridor / SpO2 ≤90%): Give first dose of Amoxicillin and arrange URGENT 108 Ambulance to CHC/District Hospital with oxygen facility.',
        'Keep child in an upright/semi-seated position during transit.',
        'Advise mother to continue frequent sips of fluid or breastfeeding if child is conscious.',
      ],
      preventionTips: [
        'Ensure full immunization with Pneumococcal Conjugate Vaccine (PCV) and Pentavalent vaccine.',
        'Exclusive breastfeeding for the first 6 months builds innate pulmonary immunity.',
        'Avoid indoor air pollution: ventilate cooking areas and avoid chulha smoke around infants.',
      ],
      sourceGuidelines: 'MoHFW Updated Pneumonia Guidelines • IMCI 2014 • India PCV Protocol',
    ),

    // 4. MALARIA (FALCIPARUM & VIVAX)
    ClinicalDisease(
      id: 'DIS_MALARIA',
      nameEn: 'Malaria (Falciparum & Vivax)',
      nameLocal: 'मलेरिया / हिवताप / ठंड लगकर बुखार',
      shortDescription:
          'Vector-borne parasitic infection with chills, high fever, and sweating. Finger-prick RDT confirmation and ACT therapy.',
      severityBadge: 'Endemic Vector Risk',
      badgeColor: Color(0xFFD97706),
      keywords: [
        'malaria',
        'chills',
        'rigors',
        'rdt',
        'falciparum',
        'vivax',
        'act',
        'artemether',
        'lumefantrine',
        'anopheles',
        'mosquito',
        'hivtap',
      ],
      introduction:
          'Malaria is caused by Plasmodium parasites (primarily P. vivax and P. falciparum in India) transmitted through the bite of infective female Anopheles mosquitoes. Classic presentation features paroxysms of severe chills, rigors, high spiking fever, and profuse sweating. P. falciparum carries a grave risk of cerebral malaria, severe anaemia, and multi-organ failure if not treated promptly.',
      counterMeasures: [
        'Perform Rapid Diagnostic Test (RDT): Prick finger using sterile lancet, collect blood in pipette, add buffer, and read result at 15 minutes (C, Pf, Pv lines).',
        'Prepare Blood Smear: Make thin and thick blood slides for laboratory microscopic confirmation at PHC.',
        'Antipyretic Fever Control: Give Paracetamol and tepid sponging to reduce core temperature.',
        'Assess for Complications: Check for yellow eyes (jaundice), dark urine, and confusion.',
      ],
      medicines: [
        MedicineProtocol(
          name: 'Artemether + Lumefantrine (ACT Co-formulated)',
          indication: 'First-line therapy for confirmed Plasmodium falciparum malaria',
          dosage: 'Weight-based 6-dose regimen over 3 days (per NVBDCP blister pack color codes). Must be taken with fatty food/milk for absorption.',
          form: 'Co-formulated blister pack (Artemether 20mg + Lumefantrine 120mg)',
          howToAdminister: 'Follow exact blister pack schedule. Supervise first dose as DOTS-style observation.',
          cautionWarning: 'Do NOT use monotherapy. Complete entire 3-day course without missing doses.',
        ),
        MedicineProtocol(
          name: 'Chloroquine Tablet',
          indication: 'First-line therapy for confirmed Plasmodium vivax malaria (followed by Primaquine at PHC)',
          dosage: 'Total 25 mg base/kg body weight divided over 3 days (Day 1: 10mg/kg, Day 2: 10mg/kg, Day 3: 5mg/kg).',
          form: 'Tablet 150mg base',
          howToAdminister: 'Take orally after meals.',
          cautionWarning: 'Primaquine for vivax radical cure must be prescribed strictly by Medical Officer after G6PD screen.',
        ),
      ],
      dangerSigns: [
        'Altered sensorium, drowsiness, disorientation, or coma (Cerebral Malaria).',
        'Repeated convulsions or seizures.',
        'Severe palmar/conjunctival pallor (severe hemolytic anaemia).',
        'Jaundice (deep yellow eyes and skin).',
        'Dark cola-colored urine (Blackwater Fever / hemoglobinuria).',
        'Breathing distress or acidotic breathing.',
        'Pregnant woman or infant with confirmed falciparum malaria.',
      ],
      referralProtocol: [
        'Any severe malaria sign: Immediate 108 referral to District Hospital / FRU with ICU facilities.',
        'Administer first dose of ACT or referral Artesunate injection at facility.',
        'Keep patient cool and hydrated during transit.',
      ],
      preventionTips: [
        'Sleep under Long-Lasting Insecticidal Nets (LLINs) every night, year-round.',
        'Cooperate with indoor residual spraying (IRS) teams.',
        'Wear full-sleeved clothing during dawn and dusk.',
      ],
      sourceGuidelines: 'NVBDCP National Malaria Treatment Guidelines 2022 • MoHFW',
    ),

    // 5. DENGUE & CHIKUNGUNYA
    ClinicalDisease(
      id: 'DIS_DENGUE',
      nameEn: 'Dengue & Vector-Borne Fever',
      nameLocal: 'डेंगू / चिकनगुनिया / Dengue Warning',
      shortDescription:
          'Aedes mosquito arboviral fever with severe retro-orbital pain, body ache, and critical plasma leakage phase.',
      severityBadge: 'Critical Warning Signs',
      badgeColor: Color(0xFFDC2626),
      keywords: [
        'dengue',
        'chikungunya',
        'platelet',
        'aedes',
        'breakbone fever',
        'retro-orbital',
        'petechiae',
        'dengue warning',
        'bleeding',
        'rash',
      ],
      introduction:
          'Dengue is an arboviral infection transmitted by daytime-biting Aedes aegypti mosquitoes. Patients typically present with high abrupt fever, severe headache, retro-orbital eye pain, joint pain ("breakbone fever"), and macular rash. The CRITICAL PHASE occurs during defervescence (days 3–7 when fever drops), where plasma leakage, hemoconcentration, and severe thrombocytopenia can precipitate Dengue Shock Syndrome.',
      counterMeasures: [
        'Strict Oral Hydration: The single most vital intervention. Patient must consume plenty of ORS, tender coconut water, soup, and clean water to counter capillary plasma leakage.',
        'Bed Rest: Enforce complete physical bed rest under an insect net to prevent secondary mosquito transmission.',
        'Monitor Defervescence Period: Warn family that the danger phase begins precisely when fever comes DOWN.',
        'Daily Platelet & Hematocrit Testing: Coordinate with PHC lab for daily CBC/platelet surveillance.',
      ],
      medicines: [
        MedicineProtocol(
          name: 'Paracetamol Only (500mg / Paediatric Syrup)',
          indication: 'Fever and pain relief in suspected or confirmed dengue',
          dosage: '500mg every 6 hours as needed (max 2000mg/day). Children 10–15mg/kg/dose.',
          form: 'Tablet 500mg / syrup',
          howToAdminister: 'Take with water after food.',
          cautionWarning:
              'STRICT CONTRAINDICATION: NEVER give Aspirin, Ibuprofen, Diclofenac, or any NSAID. They cause irreversible platelet inhibition and trigger fatal internal hemorrhage.',
        ),
      ],
      dangerSigns: [
        'Severe, persistent abdominal pain or tenderness.',
        'Persistent vomiting (≥3 episodes within a few hours).',
        'Mucosal bleeding: bleeding from gums, nose (epistaxis), blood in vomit, or black tarry stools (melena).',
        'Lethargy, extreme restlessness, confusion, or agitation.',
        'Sudden drop in body temperature accompanied by cold, clammy extremities and weak pulse.',
        'Rapid decrease in platelet count paired with a rising hematocrit (>20% rise).',
      ],
      referralProtocol: [
        'Presence of ANY single danger sign warrants immediate 108 emergency transfer to a facility with blood bank and ICU facilities.',
        'Maintain continuous oral fluid intake during transport if patient is conscious.',
      ],
      preventionTips: [
        'Eliminate standing freshwater sources: empty desert coolers, discarded tyres, coconut shells, and ornamental plant pots weekly.',
        'Apply mosquito repellent on exposed skin during daytime hours.',
        'Wear light-colored, long-sleeved clothing.',
      ],
      sourceGuidelines: 'National Guidelines for Clinical Management of Dengue Fever (MoHFW & NVBDCP)',
    ),

    // 6. SEVERE ACUTE MALNUTRITION (SAM / MAM)
    ClinicalDisease(
      id: 'DIS_MALNUTRITION',
      nameEn: 'Severe Acute Malnutrition (SAM / MAM)',
      nameLocal: 'कुपोषण / गंभीर तीव्र कुपोषण / SAM / NRC',
      shortDescription:
          'Screening via MUAC tape (<115mm) and bilateral pitting oedema. NRC referral, supplementary nutrition, and POSHAN tracking.',
      severityBadge: 'Nutrition Emergency',
      badgeColor: Color(0xFFEA580C),
      keywords: [
        'malnutrition',
        'sam',
        'mam',
        'muac',
        'oedema',
        'kuposhan',
        'nrc',
        'wasting',
        'stunting',
        'poshan',
        'weight',
        'growth',
      ],
      introduction:
          'Severe Acute Malnutrition (SAM) is a life-threatening condition in children aged 6–59 months characterized by severe muscle wasting (MUAC <115 mm), very low weight-for-height (<-3 SD), or the presence of nutritional bilateral pitting oedema. Children with SAM face a 9-fold higher risk of death from common infections and require immediate triage.',
      counterMeasures: [
        'Measure MUAC (Mid-Upper Arm Circumference): Use color-coded Shakir tape on the relaxed left arm midpoint:\n• RED (<115 mm) = SAM (Severe Acute Malnutrition)\n• YELLOW (115–<125 mm) = MAM (Moderate Acute Malnutrition)\n• GREEN (≥125 mm) = Normal nutrition',
        'Check Bilateral Pitting Oedema: Press thumbs gently on the top of both feet for 3 seconds. If visible indentation pits remain on BOTH feet, child has nutritional oedema (classified as SAM regardless of MUAC).',
        'Conduct Appetite Test: In a quiet environment, offer Ready-to-Use Therapeutic Food (RUTF) or supplementary paste. Failure to consume indicates SAM with medical complications.',
        'Assess for Infections: Check temperature for hypothermia (<35°C) or fever, and examine chest for pneumonia.',
      ],
      medicines: [
        MedicineProtocol(
          name: 'Vitamin A Solution',
          indication: 'Replenishes hepatic vitamin A stores and prevents corneal necrosis',
          dosage: 'Age-specific single dose (100,000 IU for 6–11m; 200,000 IU for 12–59m).',
          form: 'Oral oily solution with calibrated spoon',
          howToAdminister: 'Administer orally into the cheek pouch.',
          cautionWarning: 'Do not give if already received within the last 1 month.',
        ),
        MedicineProtocol(
          name: 'Albendazole 400mg',
          indication: 'Deworming for children with malnutrition (National Deworming Day protocol)',
          dosage: '1–2 years: 200mg (1/2 tablet); 2+ years: 400mg (1 chewable tablet).',
          form: 'Chewable tablet 400mg',
          howToAdminister: 'Chew or crush with water.',
          cautionWarning: 'Do not give to infants under 1 year.',
        ),
      ],
      dangerSigns: [
        'Bilateral pitting oedema on both feet or legs.',
        'MUAC <115 mm with failure of appetite test.',
        'Severe hypothermia (axillary temp <35.5°C) or high fever.',
        'Severe vomiting, diarrhoea, or respiratory distress.',
        'Extensive dermatosis (peeling skin, ulcerations, or raw skin lesions).',
      ],
      referralProtocol: [
        'Direct referral to the nearest Nutrition Rehabilitation Centre (NRC) or Malnutrition Treatment Centre (MTC).',
        'Keep the child warm skin-to-skin with mother during transit to prevent fatal hypothermia.',
        'Give sugar water (10% glucose or 1 tsp sugar in 50ml water) before departure to prevent hypoglycemia.',
      ],
      preventionTips: [
        'Promote exclusive breastfeeding for 6 months followed by timely, nutrient-dense complementary feeding.',
        'Growth monitoring at monthly Anganwadi VHSND sessions.',
        'Enroll family in POSHAN Abhiyaan and PMMVY maternity benefits.',
      ],
      sourceGuidelines: 'MoHFW Operational Guidelines for Management of SAM in Children • WHO Child Growth Standards',
    ),

    // 7. HIGH-RISK PREGNANCY & PRE-ECLAMPSIA
    ClinicalDisease(
      id: 'DIS_MATERNAL_HRP',
      nameEn: 'High-Risk Pregnancy & Pre-Eclampsia',
      nameLocal: 'उच्च जोखिम गर्भावस्था / प्री-एक्लेम्पसिया / PMSMA',
      shortDescription:
          'BP ≥140/90, severe anaemia (Hb <7), antepartum bleeding, and pre-eclampsia warning signs. Institutional delivery mapping.',
      severityBadge: 'Maternal Red Alert',
      badgeColor: Color(0xFFE11D48),
      keywords: [
        'pregnancy',
        'maternal',
        'pre-eclampsia',
        'hypertension',
        'high risk',
        'hrp',
        'bleeding',
        'headache',
        'swelling',
        'ifa',
        'fetal',
        'pmsma',
        'garbh',
      ],
      introduction:
          'High-Risk Pregnancy (HRP) encompasses maternal complications that increase the risk of morbidity or mortality to the mother or fetus. Key risks identified by ASHA workers include gestational hypertension/pre-eclampsia (BP ≥140/90 with proteinuria or headache), severe maternal anaemia (Hb <7 g/dL), antepartum hemorrhage (vaginal bleeding), abnormal lie, and gestational diabetes. Detection during Pradhan Mantri Surakshit Matritva Abhiyan (PMSMA on 9th of each month) is mandatory.',
      counterMeasures: [
        'Measure Blood Pressure at Every Contact: Check BP with a calibrated digital monitor. A reading of systolic ≥140 mmHg or diastolic ≥90 mmHg requires immediate CHO/MO confirmation.',
        'Screen for Severe Anaemia: Check palmar pallor, conjunctiva, and tongue. Verify Hb levels from ANM records; Hb <7 g/dL is severe anaemia requiring IV iron sucrose or transfusion.',
        'Monitor Fetal Movements: Mother should count fetal kicks after meals (at least 10 kicks in 2 hours).',
        'Birth Preparedness: Identify FRU/hospital, blood donors, transport (102 ambulance), and keep MCP card ready.',
      ],
      medicines: [
        MedicineProtocol(
          name: 'Iron + Folic Acid (IFA) Tablets (Red Tablet)',
          indication: 'Prophylaxis and treatment of nutritional anaemia in pregnancy',
          dosage: '1 tablet daily (60mg elemental iron + 500mcg folic acid) starting from 2nd trimester for minimum 180 days.',
          form: 'Sugar-coated red oral tablet',
          howToAdminister: 'Take after meals with water or lemon water. Do NOT take with tea, coffee, or milk.',
          cautionWarning: 'Dark stools are harmless. Do not stop taking tablets.',
        ),
        MedicineProtocol(
          name: 'Calcium + Vitamin D3 Tablets',
          indication: 'Bone density preservation and reduction of pre-eclampsia risk',
          dosage: '2 tablets daily (500mg elemental calcium each) starting from 14 weeks of pregnancy until 6 months postpartum.',
          form: 'Oral tablet 500mg',
          howToAdminister: 'Take after breakfast and dinner. Take at least 2 hours apart from IFA tablets.',
          cautionWarning: 'Do NOT consume Calcium and Iron tablets together (they block mutual absorption).',
        ),
      ],
      dangerSigns: [
        'Vaginal bleeding at any stage of pregnancy (threatened abortion, placenta previa, or abruption).',
        'Severe persistent headache, blurred vision, or seeing spots before the eyes (impending eclampsia).',
        'Sudden swelling of face, hands, and eyelids.',
        'Severe epigastric or right upper abdominal pain.',
        'Reduced or completely absent fetal movements.',
        'Premature rupture of membranes (water leaking before labor pains).',
        'Convulsions or fits (Eclampsia emergency).',
      ],
      referralProtocol: [
        'Immediate 108 Emergency Ambulance transfer to a First Referral Unit (FRU) or District Hospital equipped with Obstetrician and Blood Bank.',
        'Notify the receiving facility MO/Labour Room staff in advance.',
        'Position the mother on her LEFT side during transport to maximize uterine blood flow.',
      ],
      preventionTips: [
        'Attend all 4 Antenatal Care (ANC) visits and PMSMA on the 9th of every month.',
        'Adequate rest in the left lateral position.',
        'Nutritious diet rich in green leafy vegetables, pulses, jaggery, and dairy.',
      ],
      sourceGuidelines: 'MoHFW Guidelines for Management of High Risk Pregnancies • PMSMA Guidelines',
    ),

    // 8. NEWBORN SEPSIS & HYPOTHERMIA (HBNC)
    ClinicalDisease(
      id: 'DIS_NEONATAL_SEPSIS',
      nameEn: 'Newborn Sepsis & Hypothermia / HBNC',
      nameLocal: 'नवजात शिशु सेप्सिस व हाइपोथर्मिया / HBNC',
      shortDescription:
          'Home-Based Newborn Care home visits (days 1, 3, 7, 14, 21, 28, 42). Temperature stability, cord care, and sepsis triage.',
      severityBadge: 'Neonatal Emergency',
      badgeColor: Color(0xFFDC2626),
      keywords: [
        'newborn',
        'neonate',
        'sepsis',
        'hypothermia',
        'hbnc',
        'kmc',
        'chlorhexidine',
        'cord care',
        'baby',
        'shishu',
        'navjaat',
      ],
      introduction:
          'The neonatal period (first 28 days of life) carries the highest risk of mortality in infancy. ASHA workers conduct structured Home-Based Newborn Care (HBNC) visits on Days 1, 3, 7, 14, 21, 28, and 42 (plus extra visits for low birth weight infants). Key threats are neonatal sepsis, hypothermia, birth asphyxia, and feeding difficulties. Prompt identification of danger signs allows emergency intervention at SNCU (Special Newborn Care Unit).',
      counterMeasures: [
        'Kangaroo Mother Care (KMC): For babies <2.5 kg, provide continuous skin-to-skin contact on mother\'s chest inside clothing to maintain normothermia (36.5–37.5°C) and stimulate breathing.',
        'Clean Cord Care: Apply 7.1% Chlorhexidine gel to the umbilical cord stump once daily for the first 7 days (in areas designated by MoHFW). Keep stump clean and dry; do NOT apply cow dung, ash, or oil.',
        'Support Exclusive Breastfeeding: Ensure initiation within 1 hour of birth. Help mother with latching and attachment. No prelacteal feeds (honey, ghutti, sugar water).',
        'Weigh the Baby: Weigh on digital/spring infant scale. Low birth weight (<2500g) or very low birth weight (<1500g) require enhanced monitoring.',
      ],
      medicines: [
        MedicineProtocol(
          name: 'Chlorhexidine 7.1% Gel',
          indication: 'Prevents umbilical cord stump infection (omphalitis) and neonatal sepsis',
          dosage: 'Apply a coin-sized quantity to the umbilical cord stump once daily for first 7 days.',
          form: 'Topical gel tube',
          howToAdminister: 'Wash hands thoroughly, apply gently to the cord stump, base, and surrounding skin. Leave open to air.',
          cautionWarning: 'Do NOT apply into eyes or mouth.',
        ),
      ],
      dangerSigns: [
        'Baby is cold to touch (hypothermia, axillary temp <36.5°C despite warming) or has fever (>37.5°C).',
        'Baby stopped feeding or is unable to suckle at the breast.',
        'Convulsions, abnormal tremors, or eye twitching.',
        'Fast breathing (RR ≥60/min) or severe chest indrawing.',
        'Yellow palms and soles within the first 24 hours of birth (severe pathological jaundice).',
        'Pus leaking from umbilical cord stump with surrounding red skin.',
        'Lethargic, unusually quiet, floppy, or unconscious.',
      ],
      referralProtocol: [
        'Emergency 102/108 Ambulance transfer to the nearest Special Newborn Care Unit (SNCU) at District Hospital.',
        'Keep baby warm in continuous KMC position with mother during transit.',
        'Do not feed orally if baby is lethargic or having convulsions.',
      ],
      preventionTips: [
        'Institutional delivery at accredited facility.',
        'Strict hand hygiene before handling the newborn.',
        'Delay bathing for at least 48–72 hours to prevent hypothermia.',
      ],
      sourceGuidelines: 'Home Based Newborn Care (HBNC) Operational Guidelines (MoHFW) • SNCU Protocols',
    ),

    // 9. TUBERCULOSIS (TB / NI-KSHAY)
    ClinicalDisease(
      id: 'DIS_TB',
      nameEn: 'Tuberculosis (Pulmonary & Extra-Pulmonary)',
      nameLocal: 'क्षय रोग / टीबी / निक्षय / Cough >2 Weeks',
      shortDescription:
          'Chronic cough >2 weeks, evening fever, night sweats, and weight loss. Sputum CBNAAT testing, Nikshay tracking, and DOTS.',
      severityBadge: 'Notifiable Chronic',
      badgeColor: Color(0xFF6B4F9B),
      keywords: [
        'tuberculosis',
        'tb',
        'nikshay',
        'cough',
        'dots',
        'sputum',
        'hemoptysis',
        'khansi',
        'tb test',
        'cbnaat',
        'truenat',
      ],
      introduction:
          'Tuberculosis (TB) is a chronic bacterial infection caused by Mycobacterium tuberculosis, primarily affecting the lungs (pulmonary TB). Under the National TB Elimination Programme (NTEP), ASHA workers are front-line case finders: screening households for cough persisting >2 weeks, facilitating sputum collection for molecular CBNAAT/TrueNat testing, and serving as Treatment Supporters for adherence.',
      counterMeasures: [
        'Screen for 4 Presumptive TB Symptoms:\n1. Cough for 2 weeks or more\n2. Fever for 2 weeks or more (often evening rise)\n3. Significant unintentional weight loss\n4. Night sweats or hemoptysis (blood in sputum)',
        'Sputum Collection & Transport: Provide two clean plastic sputum cups (spot and early morning). Ensure deep productive cough, not saliva. Transport securely to PHC DMC/CBNAAT lab.',
        'Household Contact Tracing: Screen all family members, especially children <5 years (who need TB preventive therapy - TPT).',
        'Counsel on Ni-kshay Poshan Yojana: Ensure patient receives ₹500/month direct benefit transfer (DBT) into bank account for nutritional support.',
      ],
      medicines: [
        MedicineProtocol(
          name: 'NTEP Daily Fixed-Dose Combinations (FDCs)',
          indication: 'Standard first-line anti-TB chemotherapy (Isoniazid, Rifampicin, Pyrazinamide, Ethambutol)',
          dosage: 'Weight-banded daily oral FDC tablets (Category 1: 2 months 4-FDC intensive phase, 4 months 3-FDC continuation phase).',
          form: 'Blister packs (HRZE / HRE)',
          howToAdminister: 'Take daily on empty stomach 1 hour before breakfast with water. Directly observed by ASHA/family.',
          cautionWarning:
              'Red/orange urine is a normal, harmless effect of Rifampicin. Patient must NEVER stop medication prematurely (causes drug-resistant MDR-TB).',
        ),
      ],
      dangerSigns: [
        'Hemoptysis: Coughing up significant fresh red blood.',
        'Acute severe breathlessness or chest pain.',
        'Drug Adverse Effects: Jaundice (yellow eyes), severe vomiting, or rash while taking anti-TB drugs (drug-induced hepatitis).',
        'Sudden decrease in vision or color blindness (Ethambutol toxicity).',
      ],
      referralProtocol: [
        'Presumptive TB: Refer to PHC Designated Microscopy Centre (DMC) for TrueNat / CBNAAT testing and chest X-ray.',
        'Hemoptysis / Jaundice: Urgent transfer to District Hospital TB Ward or Medical College.',
      ],
      preventionTips: [
        'BCG vaccination at birth for all newborns.',
        'Cough etiquette: Cover mouth and nose with cloth or elbow when coughing.',
        'TB Preventive Treatment (TPT) for eligible household contacts.',
      ],
      sourceGuidelines: 'NTEP Technical and Operational Guidelines for TB Control in India 2021 • MoHFW',
    ),

    // 10. HYPERTENSION & CARDIOVASCULAR HEALTH (NCD)
    ClinicalDisease(
      id: 'DIS_HYPERTENSION',
      nameEn: 'Hypertension & Cardiovascular Health',
      nameLocal: 'उच्च रक्तचाप / हाई बीपी / NCD Screening',
      shortDescription:
          'Sustained BP ≥140/90 mmHg. Community CBAC checklist screening (age 30+), DASH diet counseling, and medication adherence.',
      severityBadge: 'Chronic Lifestyle NCD',
      badgeColor: Color(0xFFD97706),
      keywords: [
        'hypertension',
        'high bp',
        'blood pressure',
        'cbac',
        'heart',
        'stroke',
        'amlodipine',
        'telmisartan',
        'bp machine',
        'rakhtchap',
      ],
      introduction:
          'Hypertension is defined as sustained systolic BP ≥140 mmHg and/or diastolic BP ≥90 mmHg. Often called the "silent killer", it is asymptomatic until presenting as stroke, myocardial infarction, or kidney failure. ASHA workers conduct population enumeration using the Community-Based Assessment Checklist (CBAC) for all individuals aged 30+ under Ayushman Bharat Comprehensive Primary Health Care.',
      counterMeasures: [
        'Conduct Annual CBAC Screening: Enumerate all individuals aged 30+; calculate risk score (age, smoking, alcohol, waist circumference, physical activity, family history). Score ≥4 requires priority screening at Ayushman Arogya Mandir (HWC).',
        'Standard BP Measurement Protocol: Patient sits relaxed for 5 minutes, arm supported at heart level, feet flat on floor, no tea/tobacco within 30 minutes. Measure with validated digital cuff.',
        'Dietary Salt Counseling: Counsel to reduce dietary salt to <5 grams per day (less than 1 level teaspoon). Avoid papad, pickles, and processed snacks.',
        'Medication Adherence Monitoring: Verify that diagnosed patients collect monthly refills of antihypertensives from PHC/HWC and take them daily without interruption.',
      ],
      medicines: [
        MedicineProtocol(
          name: 'Amlodipine (5mg) / Telmisartan (40mg)',
          indication: 'Standard first-line antihypertensive medication prescribed by PHC/HWC Medical Officer',
          dosage: '1 tablet once daily (usually in the morning or bedtime as prescribed).',
          form: 'Oral tablet',
          howToAdminister: 'Take daily at the same time with water. Do NOT skip doses when feeling well.',
          cautionWarning:
              'Hypertension medicine is LIFELONG. Never stop taking the medicine just because BP has normalized.',
        ),
      ],
      dangerSigns: [
        'Severe crushing central chest pain radiating to left arm, neck, or jaw (Heart Attack).',
        'Sudden weakness, numbness, or paralysis of face, arm, or leg, especially on one side (Stroke - FAST signs).',
        'Sudden slurring of speech or difficulty speaking.',
        'Hypertensive Emergency: BP ≥180/120 mmHg with severe headache, blurred vision, or breathlessness.',
      ],
      referralProtocol: [
        'Suspected Stroke or Heart Attack: Call 108 Emergency Ambulance immediately. Every minute counts (Golden Hour <4.5 hours for stroke thrombolysis).',
        'Newly detected BP ≥140/90 on two separate occasions: Refer to CHO / Medical Officer at PHC for confirmation.',
      ],
      preventionTips: [
        'Engage in 30 minutes of moderate aerobic exercise (brisk walking, cycling) at least 5 days a week.',
        'Zero tobacco consumption: Counsel on quitting bidi, cigarettes, gutkha, and khaini.',
        'Eat a diet rich in fresh vegetables, whole grains, and fruits; avoid reheated cooking oils.',
      ],
      sourceGuidelines: 'Operational Guidelines for Prevention, Screening and Control of Common NCDs (MoHFW)',
    ),

    // 11. DIABETES MELLITUS (NCD)
    ClinicalDisease(
      id: 'DIS_DIABETES',
      nameEn: 'Diabetes Mellitus',
      nameLocal: 'मधुमेह / शूगर / Random Blood Sugar',
      shortDescription:
          'Fasting or random blood sugar elevation. Finger-prick glucometer screening, diabetic foot inspection, and hypoglycemia triage.',
      severityBadge: 'Chronic Metabolic NCD',
      badgeColor: Color(0xFF6B4F9B),
      keywords: [
        'diabetes',
        'sugar',
        'rbs',
        'glucose',
        'glucometer',
        'madhumeh',
        'fbs',
        'hypoglycemia',
        'foot care',
        'insulin',
      ],
      introduction:
          'Diabetes Mellitus is a metabolic disorder characterized by chronic hyperglycemia resulting from defects in insulin secretion, action, or both. ASHA workers screen adults aged 30+ using random blood sugar (RBS) glucometers during NCD camps and provide vital community support for treatment compliance, foot care, and prompt recognition of hypoglycemia.',
      counterMeasures: [
        'Screen with Glucometer: Check finger-prick Random Blood Sugar (RBS):\n• Normal: <140 mg/dL\n• Suspect Pre-Diabetes: 140–199 mg/dL\n• Suspect Diabetes: ≥200 mg/dL (or Fasting ≥126 mg/dL) — requires PHC MO confirmation',
        'Daily Diabetic Foot Inspection: Inspect patient\'s feet for cuts, blisters, corns, cracks, or redness. Diabetics have reduced sensation (neuropathy) and may not feel injuries, which can progress to gangrene.',
        'Manage Hypoglycemia: Educate patient on early signs (sweating, trembling, intense hunger, palpitations, dizziness). Carry 3 sugar cubes or jaggery.',
        'Dietary Counseling: Replace polished white rice with brown rice, millets (bajra, ragi, jowar), and pulses. Avoid sweets, colas, and sugar in tea.',
      ],
      medicines: [
        MedicineProtocol(
          name: 'Metformin (500mg / 1000mg)',
          indication: 'First-line oral hypoglycemic drug prescribed by Medical Officer',
          dosage: 'As prescribed by doctor (usually 500mg once or twice daily with meals).',
          form: 'Oral tablet',
          howToAdminister: 'Take strictly with or immediately after meals to reduce stomach upset.',
          cautionWarning: 'Do not skip meals after taking diabetes medicine to avoid sudden low blood sugar.',
        ),
      ],
      dangerSigns: [
        'Severe Hypoglycemia: Patient is confused, disoriented, sweating profusely, slurring speech, or unconscious.',
        'Diabetic Ketoacidosis (DKA): Deep rapid breathing, fruity/acetone breath, severe nausea, vomiting, or altered sensorium.',
        'Diabetic Foot Ulcer: Non-healing wound, black discoloration, or foul-smelling discharge on toes or foot.',
      ],
      referralProtocol: [
        'Hypoglycemia First Response: If conscious, give 3 teaspoons of sugar dissolved in water or fruit juice immediately. If unconscious, do NOT pour liquid in mouth; call 108 ambulance immediately.',
        'RBS ≥300 mg/dL or suspected DKA: Emergency transfer to District Hospital.',
      ],
      preventionTips: [
        'Maintain healthy body weight through daily physical activity.',
        'Never walk barefoot, even indoors; wear comfortable, soft footwear.',
        'Have blood sugar tested at least once every 3 months at PHC.',
      ],
      sourceGuidelines: 'Ayushman Bharat Operational Guidelines for Comprehensive Primary Health Care • MoHFW',
    ),

    // 12. ANAEMIA & IRON DEFICIENCY
    ClinicalDisease(
      id: 'DIS_ANEMIA',
      nameEn: 'Anaemia & Nutritional Iron Deficiency',
      nameLocal: 'खून की कमी / रक्ताल्पता / Anemia Mukt Bharat',
      shortDescription:
          'Palmar pallor screening, Hemoglobin checking, IFA supplementation across life stages (IFA pink, blue, red), and deworming.',
      severityBadge: 'Life-Cycle Nutrition',
      badgeColor: Color(0xFFD97706),
      keywords: [
        'anaemia',
        'anemia',
        'blood',
        'iron',
        'folic acid',
        'ifa',
        'khoon ki kami',
        'pallor',
        'wifs',
        'albendazole',
        'hemoglobin',
      ],
      introduction:
          'Anaemia is a condition in which the number of red blood cells (and their oxygen-carrying capacity) is insufficient to meet the body\'s physiological needs. Under the Anemia Mukt Bharat (AMB) 6x6x6 strategy, ASHA workers target 6 beneficiary groups: children 6–59m, children 5–9y, adolescents 10–19y, pregnant women, lactating mothers, and women of reproductive age (15–49y).',
      counterMeasures: [
        'Palmar & Conjunctival Pallor Screen: Inspect the palms of the hands and compare with mother\'s palm. Palmar pallor indicates anaemia; paper-white palms indicate severe anaemia.',
        'Age-Specific IFA Distribution:\n• Children 6–59m: IFA syrup (1ml bi-weekly)\n• Children 5–9y: IFA pink tablet (weekly)\n• Adolescents 10–19y (WIFS): IFA blue tablet (weekly on designated day)\n• Pregnant Women: IFA red tablet (daily 180 days from 2nd trimester)',
        'Bi-Annual Deworming: Administer Albendazole chewable tablets on National Deworming Day (NDD) in February and August to eradicate intestinal parasites causing chronic blood loss.',
        'Dietary Iron Counseling: Promote consumption of green leafy vegetables (palak, methi), jaggery (gur), sprouted grains, roasted chana, and citrus fruits (amla, lemon) to boost non-heme iron absorption.',
      ],
      medicines: [
        MedicineProtocol(
          name: 'IFA Red Tablet (Pregnant & Lactating Mothers)',
          indication: 'Prevention and correction of maternal iron deficiency anaemia',
          dosage: '1 tablet daily (60mg elemental iron + 500mcg folic acid) for minimum 180 days.',
          form: 'Oral tablet',
          howToAdminister: 'Take after meals with lemon water. Never take with tea, coffee, or milk.',
          cautionWarning: 'May cause black stools or mild constipation (harmless side-effects).',
        ),
        MedicineProtocol(
          name: 'IFA Blue Tablet (WIFS Adolescent 10–19y)',
          indication: 'Weekly Iron and Folic Acid Supplementation for school & out-of-school adolescents',
          dosage: '1 tablet once weekly on a fixed day (e.g., every Wednesday).',
          form: 'Oral tablet (60mg iron + 500mcg folic acid)',
          howToAdminister: 'Take after lunch/food.',
          cautionWarning: 'Do not take on an empty stomach.',
        ),
      ],
      dangerSigns: [
        'Severe Anaemia: Hb <7 g/dL in pregnant women or children.',
        'Breathlessness at rest or with minimal exertion.',
        'Extreme fatigue, dizziness, fainting spells, or palpitations.',
        'Bilateral swelling of feet and ankles (cardiac strain from severe anaemia).',
      ],
      referralProtocol: [
        'Severe Anaemia (Hb <7 g/dL): Priority referral to PHC/CHC for IV Iron Sucrose infusion or blood transfusion.',
        'Pregnant woman in 3rd trimester with moderate anaemia: Refer to obstetrician.',
      ],
      preventionTips: [
        'Delay cord clamping at birth by 1–3 minutes to transfer ~80ml blood to newborn.',
        'Eat iron-rich local foods accompanied by vitamin C (amla, citrus).',
        'Avoid consuming tea or coffee within 1 hour before or after meals.',
      ],
      sourceGuidelines: 'Anemia Mukt Bharat Operational Guidelines • MoHFW & UNICEF 2022',
    ),
  ];

  /// Find matching diseases by searching titles, keywords, and medical text.
  static List<ClinicalDisease> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return allDiseases;

    final tokens = normalized.split(RegExp(r'\s+'));
    final results = <({ClinicalDisease disease, int score})>[];

    for (final disease in allDiseases) {
      final name = disease.nameEn.toLowerCase();
      final local = disease.nameLocal.toLowerCase();
      final keywords = disease.keywords.join(' ').toLowerCase();
      final fullText = disease.searchableText;

      var score = 0;
      if (name.contains(normalized)) score += 100;
      if (local.contains(normalized)) score += 80;
      if (keywords.contains(normalized)) score += 70;
      if (fullText.contains(normalized)) score += 30;

      for (final token in tokens) {
        if (token.length < 2) continue;
        if (name.contains(token)) score += 20;
        if (local.contains(token)) score += 15;
        if (keywords.contains(token)) score += 12;
        if (fullText.contains(token)) score += 5;
      }

      if (score > 0) {
        results.add((disease: disease, score: score));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.map((r) => r.disease).toList();
  }

  /// Get disease by ID
  static ClinicalDisease? getById(String id) {
    try {
      return allDiseases.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
