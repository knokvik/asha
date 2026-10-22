import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { apiClient } from '@/shared/api/client';

export interface TriageEvidence {
  index: number;
  type: 'image' | 'audio' | 'file';
  mimeType: string;
  originalBytes?: number;
  url: string;
}

export interface FrontlineSyncActivity {
  id: string;
  workerName: string;
  workerPhone: string;
  village: string;
  category: 'Maternal (ANC)' | 'Child (IMNCI)' | 'Postnatal (PNC)' | 'NCD Screening' | 'Immunization';
  details: string;
  clinicalPayload: string;
  vitalsSummary?: string;
  syncTime: string;
  timestamp: number;
  channel: 'ABDM Online Gateway' | 'SMS Emergency Gateway' | 'Subcentre Mesh';
  status: 'Verified & Synced' | 'Triage Priority' | 'Processed';
  severity?: 'RED' | 'YELLOW' | 'GREEN';
  patientName?: string;
  patientAge?: string | number;
  patientGender?: string;
  abhaId?: string;
  ticketId?: string;
  attachments?: TriageEvidence[];
  dangerSigns?: string[];
  preReferralTreatment?: string[];
  facilityName?: string;
  vitals?: {
    bp?: string;
    pulse?: number;
    spo2?: number;
    temp?: number;
    respRate?: number;
    hemoglobin?: number;
    bloodSugar?: number;
  };
}

export const DEFAULT_SYNC_ACTIVITIES: FrontlineSyncActivity[] = [
  {
    id: 'sync-001',
    workerName: 'Meena Sharma',
    workerPhone: '+91 98765 43210',
    village: 'Rampur & Bishanpur',
    category: 'Maternal (ANC)',
    details: 'Severe Pre-eclampsia (BP 165/105 mmHg with visual disturbances)',
    clinicalPayload: 'Gravida 2, 34 wks. Severe frontal headache, blurred vision, bilateral pedal edema (+++). Immediate triage referral.',
    vitalsSummary: 'BP 165/105 · SpO2 97% · Pulse 98',
    syncTime: '12 mins ago',
    timestamp: Date.now() - 1000 * 60 * 12,
    channel: 'ABDM Online Gateway',
    status: 'Triage Priority',
    severity: 'RED',
    patientName: 'Sunita Devi',
    patientAge: '24y',
    patientGender: 'Female',
    abhaId: '91-8765-4321-0987',
    ticketId: 'TKT-2026-0842',
    dangerSigns: ['Severe Headache / Visual Disturbances', 'Bilateral Pedal Edema (+++)', 'Systolic BP >= 160 mmHg'],
    preReferralTreatment: ['Left lateral tilt positioning', 'Dark quiet environment', '108 Ambulance dispatched'],
    facilityName: 'PHC Shahpur - 24x7 Emergency Room',
    vitals: { bp: '165/105', pulse: 98, spo2: 97, temp: 98.6, respRate: 22 },
  },
  {
    id: 'sync-002',
    workerName: 'Poonam Devi',
    workerPhone: '+91 98765 11223',
    village: 'Kalyanpur',
    category: 'Child (IMNCI)',
    details: 'Neonatal Fast Breathing & Severe Chest Indrawing (PSBI)',
    clinicalPayload: 'Day 3 home visit. RR 68 breaths/min confirmed with 60s tap timer. Chest indrawing present, unable to feed.',
    vitalsSummary: 'RR 68/min · SpO2 91% · Temp 99.8°F',
    syncTime: '28 mins ago',
    timestamp: Date.now() - 1000 * 60 * 28,
    channel: 'ABDM Online Gateway',
    status: 'Triage Priority',
    severity: 'RED',
    patientName: 'Baby of Kavita',
    patientAge: '3 days',
    patientGender: 'Male',
    abhaId: '91-1122-3344-5566',
    ticketId: 'TKT-2026-0845',
    dangerSigns: ['Fast breathing >= 60/min', 'Severe chest indrawing', 'Unable to latch / feed'],
    preReferralTreatment: ['First dose oral Amoxicillin 1.25ml administered', 'Skin-to-skin Kangaroo Mother Care wrapping', 'Urgent referral to SNCU'],
    facilityName: 'PHC Shahpur - Newborn Stabilization Unit',
    vitals: { respRate: 68, spo2: 91, pulse: 155, temp: 99.8 },
  },
  {
    id: 'sync-003',
    workerName: 'Rekha Verma',
    workerPhone: '+91 98765 99887',
    village: 'Shahpur Hamlet 2',
    category: 'NCD Screening',
    details: 'Presumptive TB Sputum Referral — Productive cough > 3 weeks',
    clinicalPayload: '45y male with chronic cough, hemoptysis streaks, evening subfebrile fever and unexplained weight loss.',
    vitalsSummary: 'Temp 100.2°F · SpO2 96% · Wt 48kg',
    syncTime: '45 mins ago',
    timestamp: Date.now() - 1000 * 60 * 45,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: 'YELLOW',
    patientName: 'Mohan Lal',
    patientAge: '45y',
    patientGender: 'Male',
    abhaId: '91-5566-7788-9900',
    ticketId: 'TKT-2026-0850',
    dangerSigns: ['Cough > 2 weeks', 'Hemoptysis streaks', 'Unexplained weight loss'],
    preReferralTreatment: ['Sputum collection container issued for CBNAAT / Truenat', 'Triple-layer medical mask provided'],
    facilityName: 'PHC Shahpur - Designated Microscopy Centre',
    vitals: { temp: 100.2, spo2: 96, pulse: 82, respRate: 18 },
  },
  {
    id: 'sync-004',
    workerName: 'Sunita Sharma',
    workerPhone: '+91 98765 77665',
    village: 'Bishanpur South',
    category: 'Maternal (ANC)',
    details: 'Severe Anemia in 3rd Trimester (Hb 6.8 g/dL with severe fatigue)',
    clinicalPayload: 'Gravida 3, 32 wks. Pale conjunctiva, palmar pallor, resting tachycardia (HR 108). Urgent parenteral iron indicated.',
    vitalsSummary: 'Hb 6.8 g/dL · BP 100/64 · HR 108 bpm',
    syncTime: '1 hr ago',
    timestamp: Date.now() - 1000 * 60 * 65,
    channel: 'ABDM Online Gateway',
    status: 'Triage Priority',
    severity: 'RED',
    patientName: 'Radhika Devi',
    patientAge: '23y',
    patientGender: 'Female',
    abhaId: '91-9988-1122-3344',
    ticketId: 'TKT-2026-0858',
    dangerSigns: ['Severe Pallor', 'Hb < 7 g/dL in late trimester', 'Tachycardia at rest'],
    preReferralTreatment: ['Expedited transfer for IV Iron Sucrose infusion', 'Dietary folate rich counseling'],
    facilityName: 'PHC Shahpur - Maternity Ward',
    vitals: { bp: '100/64', pulse: 108, spo2: 95, hemoglobin: 6.8 },
  },
  {
    id: 'sync-005',
    workerName: 'Geeta Rawat',
    workerPhone: '+91 98765 33445',
    village: 'Majra Khas',
    category: 'Child (IMNCI)',
    details: 'Acute High Grade Fever with Rigors (Temp 102.8°F)',
    clinicalPayload: '3-year-old child presenting with acute febrile illness, refusal of fluids, no neck stiffness, malaria RDT negative.',
    vitalsSummary: 'Temp 102.8°F · SpO2 98% · Pulse 120',
    syncTime: '1 hr ago',
    timestamp: Date.now() - 1000 * 60 * 75,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: 'YELLOW',
    patientName: 'Rahul Kumar',
    patientAge: '3y',
    patientGender: 'Male',
    abhaId: '91-4433-2211-0099',
    ticketId: 'TKT-2026-0861',
    dangerSigns: ['High fever > 102.5°F', 'Refusal of solid feeds'],
    preReferralTreatment: ['Tepid sponging instructed and performed', 'Paracetamol syrup (250mg/5ml) 5ml administered', 'Hydration monitor'],
    facilityName: 'PHC Shahpur - Pediatric OPD',
    vitals: { temp: 102.8, pulse: 120, spo2: 98, respRate: 28 },
  },
  {
    id: 'sync-006',
    workerName: 'Meena Sharma',
    workerPhone: '+91 98765 43210',
    village: 'Rampur & Bishanpur',
    category: 'Postnatal (PNC)',
    details: 'Day 3 Postnatal Home Visit — Mother & Healthy Newborn',
    clinicalPayload: 'Routine home visit under HBNC guidelines. Exclusive breastfeeding established, umbilical stump dry, baby temperature 98.4°F.',
    vitalsSummary: 'BP 116/74 · Newborn Temp 98.4°F',
    syncTime: '2 hrs ago',
    timestamp: Date.now() - 1000 * 60 * 120,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: 'GREEN',
    patientName: 'Pooja Devi & Infant',
    patientAge: '22y',
    patientGender: 'Female',
    abhaId: '91-6655-4433-2211',
    dangerSigns: ['None identified — normal postnatal progression'],
    preReferralTreatment: ['Exclusive breastfeeding counseling', 'Thermal wrap guidance', 'Hand hygiene demonstrated'],
    facilityName: 'Rampur Subcentre',
    vitals: { bp: '116/74', temp: 98.4, pulse: 76 },
  },
  {
    id: 'sync-007',
    workerName: 'Poonam Devi',
    workerPhone: '+91 98765 11223',
    village: 'Kalyanpur',
    category: 'Maternal (ANC)',
    details: '1st Trimester ANC Registration & ABHA Card Linking',
    clinicalPayload: 'Primigravida, 9 weeks. Verified urine pregnancy test, created ABHA address, screened for sickle cell trait.',
    vitalsSummary: 'BP 112/72 · Hb 11.4 g/dL · Wt 51kg',
    syncTime: '2 hrs ago',
    timestamp: Date.now() - 1000 * 60 * 135,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: 'GREEN',
    patientName: 'Ritu Patel',
    patientAge: '21y',
    patientGender: 'Female',
    abhaId: '91-7788-9900-1122',
    dangerSigns: ['None identified'],
    preReferralTreatment: ['Folic acid 5mg daily for 90 days dispensed', 'Scheduled first USG Dating Scan at PHC'],
    facilityName: 'Kalyanpur Subcentre',
    vitals: { bp: '112/72', hemoglobin: 11.4, pulse: 74 },
  },
  {
    id: 'sync-008',
    workerName: 'Rekha Verma',
    workerPhone: '+91 98765 99887',
    village: 'Shahpur Hamlet 2',
    category: 'Maternal (ANC)',
    details: 'Gestational Diabetes Follow-up — RBS 168 mg/dL',
    clinicalPayload: 'Gravida 2, 28 wks. Elevated casual glucose. Screened with glucometer. No polyuria or visual blurring.',
    vitalsSummary: 'RBS 168 mg/dL · BP 128/84',
    syncTime: '3 hrs ago',
    timestamp: Date.now() - 1000 * 60 * 180,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: 'YELLOW',
    patientName: 'Anjali Gupta',
    patientAge: '28y',
    patientGender: 'Female',
    abhaId: '91-2233-4455-6677',
    ticketId: 'TKT-2026-0869',
    dangerSigns: ['Elevated blood glucose in pregnancy (> 140 mg/dL)'],
    preReferralTreatment: ['Dietary carbohydrate counseling', 'Referred to PHC MO for 75g OGTT confirmation'],
    facilityName: 'PHC Shahpur - Ante-Natal Clinic',
    vitals: { bloodSugar: 168, bp: '128/84', pulse: 80 },
  },
  {
    id: 'sync-009',
    workerName: 'Geeta Rawat',
    workerPhone: '+91 98765 33445',
    village: 'Majra Khas',
    category: 'Immunization',
    details: 'Measles-Rubella (MR-1) & Vitamin A Due Date Mobilization',
    clinicalPayload: 'Child turned 9 months. Counseled reluctant family regarding measles safety. Mobilized for upcoming Wednesday VHND.',
    vitalsSummary: 'Child Active · Due: MR-1, JE-1, PCV-Booster',
    syncTime: '3 hrs ago',
    timestamp: Date.now() - 1000 * 60 * 195,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: 'GREEN',
    patientName: 'Baby Aradhya',
    patientAge: '9 mo',
    patientGender: 'Female',
    abhaId: '91-3322-1100-9988',
    dangerSigns: ['None identified'],
    preReferralTreatment: ['Caregiver counseled', 'Due list updated in frontline register'],
    facilityName: 'Majra Khas Anganwadi Centre',
    vitals: { temp: 98.2 },
  },
  {
    id: 'sync-010',
    workerName: 'Meena Sharma',
    workerPhone: '+91 98765 43210',
    village: 'Rampur & Bishanpur',
    category: 'Child (IMNCI)',
    details: 'Acute Diarrhea with Mild Dehydration — ORS & Zinc Started',
    clinicalPayload: '14-month-old passing loose watery stools 4x in 12h. Alert, drinking eagerly, skin pinch retracts immediately.',
    vitalsSummary: 'Temp 99.1°F · Pulse 110 bpm · No sunken eyes',
    syncTime: '4 hrs ago',
    timestamp: Date.now() - 1000 * 60 * 240,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: 'YELLOW',
    patientName: 'Aryan Singh',
    patientAge: '14 mo',
    patientGender: 'Male',
    abhaId: '91-8899-7766-5544',
    ticketId: 'TKT-2026-0872',
    dangerSigns: ['Frequent loose watery stools'],
    preReferralTreatment: ['1 liter ORS solution prepared with mother', 'Zinc Sulphate 20mg tab #1 given, 13 tablets dispensed for 14-day course'],
    facilityName: 'Rampur Subcentre',
    vitals: { temp: 99.1, pulse: 110, respRate: 26 },
  },
  {
    id: 'sync-011',
    workerName: 'Poonam Devi',
    workerPhone: '+91 98765 11223',
    village: 'Kalyanpur',
    category: 'NCD Screening',
    details: 'Population CBAC & Hypertension Community Screening',
    clinicalPayload: 'Target age 48y female. Blood pressure 124/80 mmHg, waist circumference 82 cm, CBAC risk score 2 (low risk).',
    vitalsSummary: 'BP 124/80 · FBS 102 mg/dL · CBAC 2/10',
    syncTime: '4 hrs ago',
    timestamp: Date.now() - 1000 * 60 * 260,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: 'GREEN',
    patientName: 'Sushila Devi',
    patientAge: '48y',
    patientGender: 'Female',
    abhaId: '91-5544-3322-1100',
    dangerSigns: ['None identified'],
    preReferralTreatment: ['Dietary salt reduction guidance', 'Scheduled for annual follow-up screening'],
    facilityName: 'Kalyanpur Subcentre',
    vitals: { bp: '124/80', bloodSugar: 102, pulse: 72 },
  },
  {
    id: 'sync-012',
    workerName: 'Kamla Thakur',
    workerPhone: '+91 94180 55443',
    village: 'Kotla Forest (No Network)',
    category: 'NCD Screening',
    details: 'Hypertensive Emergency Relayed via 140-char Encrypted SMS',
    clinicalPayload: 'No 3G/4G coverage. Encrypted 140-char SMS relay received at PHC gateway modem: BP 190/125, severe occipital throbbing, diaphoresis.',
    vitalsSummary: 'BP 190/125 · Pulse 92 · Relayed via SMS Gateway',
    syncTime: '5 hrs ago',
    timestamp: Date.now() - 1000 * 60 * 300,
    channel: 'SMS Emergency Gateway',
    status: 'Triage Priority',
    severity: 'RED',
    patientName: 'Ramesh Chand',
    patientAge: '58y',
    patientGender: 'Male',
    abhaId: '91-3344-5566-7788',
    ticketId: 'ref-sms-091',
    dangerSigns: ['Severe Hypertensive Urgency (BP >= 180/120)', 'Occipital headache', 'Diaphoresis'],
    preReferralTreatment: ['Patient kept seated resting', 'Sublingual Sorbitrate advised via PHC voice link', '108 Ambulance dispatched to Kotla Forest Checkpost'],
    facilityName: 'PHC Shahpur - Emergency Resuscitation Bay',
    vitals: { bp: '190/125', pulse: 92, spo2: 96 },
  },
  {
    id: 'sync-013',
    workerName: 'Sunita Sharma',
    workerPhone: '+91 98765 77665',
    village: 'Bishanpur South',
    category: 'Child (IMNCI)',
    details: 'Severe Acute Malnutrition (SAM) Screening with MUAC Red Flag',
    clinicalPayload: '18-month-old child with MUAC 11.1 cm (Red zone). Visible severe wasting, bilateral pitting edema absent. Passed appetite test.',
    vitalsSummary: 'MUAC 11.1 cm · Wt 7.1 kg · Wasting Present',
    syncTime: '5 hrs ago',
    timestamp: Date.now() - 1000 * 60 * 320,
    channel: 'ABDM Online Gateway',
    status: 'Triage Priority',
    severity: 'RED',
    patientName: 'Baby Chotu',
    patientAge: '18 mo',
    patientGender: 'Male',
    abhaId: '91-1199-2288-3377',
    ticketId: 'TKT-2026-0875',
    dangerSigns: ['MUAC < 11.5 cm (Severe Acute Malnutrition)', 'Weight-for-height < -3 SD'],
    preReferralTreatment: ['Appetite test conducted with RUTF packet (passed)', 'Immediate referral to District Nutrition Rehabilitation Centre (NRC)'],
    facilityName: 'District Hospital NRC / PHC Shahpur',
    vitals: { temp: 98.4, pulse: 114, respRate: 24 },
  },
  {
    id: 'sync-014',
    workerName: 'Rekha Verma',
    workerPhone: '+91 98765 99887',
    village: 'Shahpur Hamlet 2',
    category: 'Postnatal (PNC)',
    details: 'Day 14 Postnatal Home Visit — Weight Check & Thermal Care',
    clinicalPayload: 'Infant gained 380 grams since birth. No neonatal jaundice. Mother practicing warm wrap and exclusive breastfeeding.',
    vitalsSummary: 'Infant Wt 3.2 kg · Temp 98.6°F · Feeding Active',
    syncTime: '6 hrs ago',
    timestamp: Date.now() - 1000 * 60 * 360,
    channel: 'Subcentre Mesh',
    status: 'Verified & Synced',
    severity: 'GREEN',
    patientName: 'Babita Devi & Baby',
    patientAge: '25y',
    patientGender: 'Female',
    abhaId: '91-4455-6677-8899',
    dangerSigns: ['None identified'],
    preReferralTreatment: ['Breastfeeding positioning reinforced', 'Immunization scheduled for 6 weeks OPV-1/Penta-1'],
    facilityName: 'Shahpur Subcentre',
    vitals: { temp: 98.6, pulse: 78, bp: '118/76' },
  },
  {
    id: 'sync-015',
    workerName: 'Meena Sharma',
    workerPhone: '+91 98765 43210',
    village: 'Rampur & Bishanpur',
    category: 'NCD Screening',
    details: 'Elderly Hypertension Screening — Stage 1 HTN Identified',
    clinicalPayload: '62y male farmer. BP 146/92 mmHg confirmed on repeat reading after 15 mins rest. No chest pain or dizziness.',
    vitalsSummary: 'BP 146/92 · Pulse 74 · FBS 110 mg/dL',
    syncTime: '6 hrs ago',
    timestamp: Date.now() - 1000 * 60 * 390,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: 'YELLOW',
    patientName: 'Ram Prasad',
    patientAge: '62y',
    patientGender: 'Male',
    abhaId: '91-7766-5544-3322',
    ticketId: 'TKT-2026-0881',
    dangerSigns: ['Stage 1 Hypertension (BP 140-159 / 90-99 mmHg)'],
    preReferralTreatment: ['Dietary low sodium counseling', 'Referred to PHC Medical Officer for anti-hypertensive initiation'],
    facilityName: 'PHC Shahpur - NCD Clinic',
    vitals: { bp: '146/92', pulse: 74, bloodSugar: 110 },
  },
  {
    id: 'sync-016',
    workerName: 'Geeta Rawat',
    workerPhone: '+91 98765 33445',
    village: 'Majra Khas',
    category: 'NCD Screening',
    details: 'Diabetes Screening — Casual RBS 218 mg/dL with Polydipsia',
    clinicalPayload: '55y female with complaints of frequent thirst and nocturia. Casual fingerstick blood glucose 218 mg/dL.',
    vitalsSummary: 'RBS 218 mg/dL · BP 132/86 · SpO2 97%',
    syncTime: '7 hrs ago',
    timestamp: Date.now() - 1000 * 60 * 430,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: 'YELLOW',
    patientName: 'Kanti Devi',
    patientAge: '55y',
    patientGender: 'Female',
    abhaId: '91-6677-8899-0011',
    ticketId: 'TKT-2026-0884',
    dangerSigns: ['Elevated casual blood glucose > 200 mg/dL', 'Polydipsia'],
    preReferralTreatment: ['Hydration encouraged', 'Scheduled for fasting blood glucose and HbA1c test at PHC laboratory'],
    facilityName: 'PHC Shahpur - Laboratory & NCD Clinic',
    vitals: { bloodSugar: 218, bp: '132/86', pulse: 84 },
  },
];

export interface ActiveHotspotData {
  id: string;
  name: string;
  locationName: string;
  lat: number;
  lng: number;
  radiusMeters: number;
  condition: string;
  severity: 'CRITICAL' | 'WARNING';
  casesCount: number;
  affectedWards: string[];
  nearbyAshas: Array<{
    id: string;
    name: string;
    beat: string;
    lat: number;
    lng: number;
    phone: string;
    status: string;
  }>;
  activatedAt: number;
}

export const INDIRA_AIRPORT_HOTSPOT: ActiveHotspotData = {
  id: 'hotspot-delhi-igi-01',
  name: 'Indira Airport Outbreak Cluster',
  locationName: 'Indira Gandhi International Airport & Aerocity Catchment, New Delhi',
  lat: 28.5562,
  lng: 77.1000,
  radiusMeters: 1800,
  condition: 'Dengue & Acute Febrile Illness (AFI)',
  severity: 'CRITICAL',
  casesCount: 14,
  affectedWards: ['Ward 14 (Mahipalpur Extn)', 'Ward 15 (Rangpuri Basti)', 'Aerocity Catchment'],
  nearbyAshas: [
    {
      id: 'asha-01',
      name: 'Meena Sharma',
      beat: 'Mahipalpur Extn Beat 1',
      lat: 28.5480,
      lng: 77.1250,
      phone: '+91 98765 43210',
      status: 'Active • 8 Fever Checks Logged',
    },
    {
      id: 'asha-02',
      name: 'Poonam Devi',
      beat: 'Rangpuri Basti Beat 2',
      lat: 28.5350,
      lng: 77.1120,
      phone: '+91 98765 11223',
      status: 'Deploying ORS & Mosquito Repellents',
    },
    {
      id: 'asha-05',
      name: 'Priya Singh',
      beat: 'Aerocity Transit Camp Beat 3',
      lat: 28.5520,
      lng: 77.1050,
      phone: '+91 98765 66778',
      status: 'Rapid NS1 RDT Testing On-Site',
    },
    {
      id: 'asha-06',
      name: 'Sunita Kumari',
      beat: 'Shahbad Mohammadpur Beat 4',
      lat: 28.5620,
      lng: 77.0750,
      phone: '+91 98765 88990',
      status: 'Larval Source Reduction Active',
    },
  ],
  activatedAt: Date.now(),
};

export interface SyncToastItem {
  id: string;
  title: string;
  workerName: string;
  village: string;
  category: string;
  details: string;
  syncTime: string;
  type: 'sync_received' | 'urgent_triage' | 'outcome_pushed';
  link?: string;
}

interface SyncContextType {
  lastSyncTime: string;
  isSyncing: boolean;
  toasts: SyncToastItem[];
  syncActivities: FrontlineSyncActivity[];
  triggerManualSync: (customPayload?: Partial<FrontlineSyncActivity>) => void;
  dismissToast: (id: string) => void;
  recordDoctorOutcomeSync: (patientName: string, ashaName: string, actionText: string) => void;
  activeHotspot: ActiveHotspotData | null;
  triggerHotspot: (custom?: Partial<ActiveHotspotData>) => ActiveHotspotData;
  clearHotspot: () => void;
}

const SyncContext = createContext<SyncContextType | undefined>(undefined);

function relativeTime(timestamp: number): string {
  const minutes = Math.max(0, Math.round((Date.now() - timestamp) / 60000));
  if (minutes < 1) return 'Just now';
  if (minutes < 60) return `${minutes} min${minutes === 1 ? '' : 's'} ago`;
  const hours = Math.floor(minutes / 60);
  return `${hours} hr${hours === 1 ? '' : 's'} ago`;
}

function mapPacket(packet: any): FrontlineSyncActivity {
  const timestamp = Number(packet.received_at || packet.device_timestamp || Date.now());
  const table = String(packet.table || 'sync packet');
  const category = table.includes('encounter') || table.includes('triage')
    ? 'NCD Screening'
    : table.includes('member') || table.includes('household')
      ? 'Child (IMNCI)'
      : 'Immunization';
  const ticket = packet.ticket;
  const attachments: TriageEvidence[] = Array.isArray(ticket?.attachments)
    ? ticket.attachments.map((attachment: any) => ({
        index: Number(attachment.index),
        type: attachment.type === 'image' || attachment.type === 'audio' ? attachment.type : 'file',
        mimeType: String(attachment.mime_type || 'application/octet-stream'),
        originalBytes: typeof attachment.original_bytes === 'number' ? attachment.original_bytes : undefined,
        url: String(attachment.url),
      }))
    : [];
  return {
    id: String(packet.id),
    workerName: String(packet.worker_id || 'Field worker'),
    workerPhone: '',
    village: String(ticket?.location || packet.device_id || 'Field device'),
    category,
    details: ticket
      ? `TRIAGE ${String(ticket.flag || 'SUBMITTED')} · ${String(ticket.id || packet.record_id)}`
      : `${String(packet.operation || 'update').toUpperCase()} ${table} · ${packet.record_id}`,
    clinicalPayload: ticket?.details
      ? String(ticket.details)
      : ticket
        ? `Ward ${String(ticket.ward_id || 'not recorded')} · ticket received from the field.`
        : 'Packet metadata available in the source record.',
    syncTime: relativeTime(timestamp),
    timestamp,
    channel: 'ABDM Online Gateway',
    status: 'Verified & Synced',
    severity: ticket?.flag === 'RED' || ticket?.flag === 'YELLOW' || ticket?.flag === 'GREEN'
      ? ticket.flag
      : undefined,
    patientName: ticket?.patient_name ? String(ticket.patient_name) : undefined,
    ticketId: ticket?.id ? String(ticket.id) : undefined,
    attachments,
  };
}

export function SyncProvider({ children }: { children: React.ReactNode }) {
  const [lastSyncTime, setLastSyncTime] = useState('12 mins ago');
  const [isSyncing, setIsSyncing] = useState(false);
  const [toasts, setToasts] = useState<SyncToastItem[]>([]);
  const [syncActivities, setSyncActivities] = useState<FrontlineSyncActivity[]>(DEFAULT_SYNC_ACTIVITIES);
  const [activeHotspot, setActiveHotspot] = useState<ActiveHotspotData | null>(() => {
    try {
      const saved = localStorage.getItem('asha_active_hotspot');
      return saved ? JSON.parse(saved) : null;
    } catch {
      return null;
    }
  });

  const dismissToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((toast) => toast.id !== id));
  }, []);

  const triggerHotspot = useCallback((custom?: Partial<ActiveHotspotData>) => {
    const hotspot: ActiveHotspotData = {
      ...INDIRA_AIRPORT_HOTSPOT,
      ...custom,
      activatedAt: Date.now(),
    };
    setActiveHotspot(hotspot);
    try {
      localStorage.setItem('asha_active_hotspot', JSON.stringify(hotspot));
    } catch {}

    const hotspotPackets: FrontlineSyncActivity[] = [
      {
        id: `sync-hotspot-001-${Date.now()}`,
        workerName: 'Meena Sharma',
        workerPhone: '+91 98765 43210',
        village: 'Mahipalpur Extn (Indira Airport Catchment)',
        category: 'Child (IMNCI)',
        details: 'CRITICAL TRIAGE: Dengue Hemorrhagic Suspect — High Fever (103.4°F), Thrombocytopenia & Petechiae',
        clinicalPayload: 'Patient resides 0.8 km from active Indira Airport Hotspot. Platelets 42,000/uL, severe retro-orbital headache, persistent vomiting, positive tourniquet test. Immediate IV normal saline initiated; 108 Ambulance summoned.',
        vitalsSummary: 'Temp 103.4°F · BP 90/60 · Pulse 118 · SpO2 96%',
        syncTime: 'Just now',
        timestamp: Date.now(),
        channel: 'ABDM Online Gateway',
        status: 'Triage Priority',
        severity: 'RED',
        patientName: 'Sunita Devi',
        patientAge: '24y',
        patientGender: 'Female',
        abhaId: '91-8765-4321-0987',
        ticketId: 'TKT-HOTSPOT-DEL-01',
        dangerSigns: [
          'High persistent fever > 103°F',
          'Petechial skin rash / Bleeding tendency',
          'Platelet count < 50,000/uL',
          'Persistent vomiting with dehydration',
          'Proximity to active Indira Airport Dengue cluster (< 1 km)',
        ],
        preReferralTreatment: [
          '500ml IV Normal Saline initiated at Mahipalpur Subcentre',
          'Tepid sponging administered',
          '108 Emergency Ambulance dispatched from PHC Aerocity',
          'Safdarjung Hospital Dengue Resuscitation Bay alerted',
        ],
        facilityName: 'PHC Aerocity / Safdarjung Hospital Emergency Resuscitation',
        vitals: { bp: '90/60', pulse: 118, spo2: 96, temp: 103.4, respRate: 26 },
      },
      {
        id: `sync-hotspot-002-${Date.now()}`,
        workerName: 'Priya Singh',
        workerPhone: '+91 98765 66778',
        village: 'Aerocity Transit Camp',
        category: 'NCD Screening',
        details: 'Hotspot Rapid Screening: NS1 Antigen Positive — High Fever Day 3',
        clinicalPayload: 'On-site rapid diagnostic testing in Aerocity worker barracks. Positive NS1 Ag. Tepid sponging & oral fluids counseled.',
        vitalsSummary: 'Temp 102.1°F · BP 118/78 · NS1 Positive',
        syncTime: 'Just now',
        timestamp: Date.now(),
        channel: 'ABDM Online Gateway',
        status: 'Triage Priority',
        severity: 'YELLOW',
        patientName: 'Mohan Lal',
        patientAge: '45y',
        patientGender: 'Male',
        abhaId: '91-5566-7788-9900',
        ticketId: 'TKT-HOTSPOT-DEL-02',
        dangerSigns: ['High fever > 3 days', 'NS1 Antigen positive', 'Generalized myalgia'],
        preReferralTreatment: ['Oral rehydration fluid therapy started', 'Paracetamol 650mg given, NSAIDs strictly restricted'],
        facilityName: 'PHC Aerocity Fever OPD',
        vitals: { bp: '118/78', pulse: 90, spo2: 98, temp: 102.1 },
      },
      {
        id: `sync-hotspot-003-${Date.now()}`,
        workerName: 'Poonam Devi',
        workerPhone: '+91 98765 11223',
        village: 'Rangpuri Basti',
        category: 'Maternal (ANC)',
        details: 'Outbreak Vector Alert Broadcast Acknowledged — 34 HHs Surveyed',
        clinicalPayload: 'Door-to-door fever surveillance active in Rangpuri sector. Identified 2 pregnant women in 2nd trimester; provided vector nets and repellents.',
        vitalsSummary: 'Fever Screen 34 HHs · 2 High-Risk ANC Identified',
        syncTime: 'Just now',
        timestamp: Date.now(),
        channel: 'ABDM Online Gateway',
        status: 'Verified & Synced',
        severity: 'GREEN',
        patientName: 'Rangpuri Community Cohort',
        dangerSigns: ['None identified in surveyed cohort'],
        preReferralTreatment: ['Long-lasting insecticidal nets (LLIN) distributed', 'Fever reporting helpline 104 disseminated'],
        facilityName: 'Rangpuri Subcentre',
      },
    ];

    setSyncActivities((prev) => [...hotspotPackets, ...prev]);

    // Push broadcast toast
    const toastItem: SyncToastItem = {
      id: `toast-${Date.now()}`,
      title: '🚨 OUTBREAK HOTSPOT BROADCAST TO ASHAS',
      workerName: 'ABDM Central Gateway',
      village: 'Indira Airport Catchment (Delhi)',
      category: 'Dengue Outbreak Cluster',
      details: 'Hotspot mapped near Indira Airport. 4 nearby ASHA workers mobilized with fever triage protocols.',
      syncTime: 'Just now',
      type: 'urgent_triage',
      link: '/map',
    };
    setToasts((prev) => [toastItem, ...prev]);

    window.dispatchEvent(
      new CustomEvent('asha:hotspot_triggered', {
        detail: hotspot,
      })
    );

    return hotspot;
  }, []);

  const clearHotspot = useCallback(() => {
    setActiveHotspot(null);
    try {
      localStorage.removeItem('asha_active_hotspot');
    } catch {}
    window.dispatchEvent(new CustomEvent('asha:hotspot_cleared'));
  }, []);

  const loadActivity = useCallback(async () => {
    setIsSyncing(true);
    try {
      if (localStorage.getItem('asha_auth_token')) {
        const response = await apiClient.get('/sync/activity?limit=100');
        const packets = Array.isArray(response.data?.packets) ? response.data.packets : [];
        if (packets.length > 0) {
          const next = packets.map(mapPacket);
          setSyncActivities(next);
          setLastSyncTime(relativeTime(next[0].timestamp));
          return;
        }
      }
      setSyncActivities(DEFAULT_SYNC_ACTIVITIES);
      setLastSyncTime('12 mins ago');
    } catch {
      setSyncActivities(DEFAULT_SYNC_ACTIVITIES);
      setLastSyncTime('12 mins ago');
    } finally {
      setIsSyncing(false);
    }
  }, []);

  useEffect(() => {
    void loadActivity();
    const timer = window.setInterval(() => void loadActivity(), 10000);
    return () => window.clearInterval(timer);
  }, [loadActivity]);

  const triggerManualSync = useCallback(() => {
    void loadActivity();
  }, [loadActivity]);

  const recordDoctorOutcomeSync = useCallback(() => {
    void loadActivity();
  }, [loadActivity]);

  return (
    <SyncContext.Provider value={{ lastSyncTime, isSyncing, toasts, syncActivities, triggerManualSync, dismissToast, recordDoctorOutcomeSync, activeHotspot, triggerHotspot, clearHotspot }}>
      {children}
    </SyncContext.Provider>
  );
}

export function useSync() {
  const context = useContext(SyncContext);
  return context ?? {
    lastSyncTime: '12 mins ago',
    isSyncing: false,
    toasts: [],
    syncActivities: DEFAULT_SYNC_ACTIVITIES,
    triggerManualSync: () => undefined,
    dismissToast: () => undefined,
    recordDoctorOutcomeSync: () => undefined,
    activeHotspot: null,
    triggerHotspot: () => INDIRA_AIRPORT_HOTSPOT,
    clearHotspot: () => undefined,
  };
}
