"""Comprehensive Seeder for PCMC Disease Cases, Surveillance Counts & Context Pack.

Populates Supabase PostgreSQL with clinically realistic disease cases across
all 8 PCMC wards (W1–W8) including:
1. Dengue & Dengue Hemorrhagic Fever outbreaks (W3 Akurdi, W5 Bhosari)
2. Acute Gastroenteritis & Bacillary Dysentery (W1 Pimpri, W7 Sangvi)
3. Pediatric Severe Bronchopneumonia & ARI (W4 Nigdi, W6 Moshi)
4. Plasmodium Vivax & Complicated Falciparum Malaria (W2 Chinchwad, W5 Bhosari)
5. Enteric / Typhoid Fever (W8 Rahatani)
6. Pediatric Measles Outbreak Alert (W2 Chinchwad)
7. Acute Encephalitis Syndrome (AES) / Viral Meningoencephalitis (W6 Moshi)
8. Presumptive Pulmonary Tuberculosis (W1 Pimpri Camp)
9. Severe Pre-eclampsia in High-Risk Pregnancy (W7 Pimple Gurav)
10. Neonatal Sepsis / PSBI (W3 Walhekarwadi)
11. Acute Viral Hepatitis A (W8 Rahatani)
12. Scrub Typhus / Rickettsial Fever with Eschar (W4 Nigdi)

Target Tables:
- disease_counts (Wards W1..W8, Weeks 1..12, multiple syndromic conditions)
- desk_tickets (Queue for PHC Medical Officers with priority RED/YELLOW)
- desk_outcomes (Clinical diagnoses, actions, and FHIR bundles for closed tickets)
- triage_tickets (Mobile offline triage packets with IMCI assessments)
- referral_records (Facility queues for PCMC UPHCs & YCM Hospital)
- context_packs (Official merged context pack with active dengue ward)
"""
from __future__ import annotations

import asyncio
import json
import os
import sys
import uuid
from datetime import datetime, timedelta, timezone

# Ensure backend root is on sys.path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import delete, select

from db.session import AsyncSessionLocal
from models.db.desk import (
    ContextPackBlob,
    DeskIdempotency,
    DeskOutcome,
    DeskTicket,
    DiseaseCountRow,
)
from models.db.models import ReferralRecord, TriageTicket, User
from services.triage_desk import TriageDesk

# PCMC Wards and Localities
PCMC_WARDS = ["W1", "W2", "W3", "W4", "W5", "W6", "W7", "W8"]

# 20 Clinically realistic disease cases in PCMC
PCMC_CASES = [
    {
        "id": "PCMC-CASE-001",
        "referral_id": "REF-PCMC-W3-0101",
        "name": "Kavita Shinde",
        "age_months": 288,  # 24 years
        "age_display": "24Y",
        "sex": "F",
        "ward_id": "W3",
        "location": "Ward W3, Akurdi Gaon, Near Vitthal Temple, PCMC",
        "condition": "dengue_like",
        "diagnosis_display": "Severe Dengue with Hemoconcentration (DHF Grade II)",
        "priority": "RED",
        "status": "IN_CARE",
        "vitals": {
            "temp_c": 39.7,
            "temp_f": 103.5,
            "pulse_bpm": 124,
            "bp_systolic": 88,
            "bp_diastolic": 58,
            "spo2": 96,
            "platelet_count": 32000,
            "hematocrit_pct": 48.2,
        },
        "symptoms": [
            "High grade continuous fever x 5 days",
            "Severe retro-orbital pain and headache",
            "Persistent vomiting (4 episodes in past 6h)",
            "Petechial purpura over bilateral lower limbs",
            "Positive tourniquet test",
            "Dengue NS1 Antigen Reactive",
        ],
        "danger_signs": [
            "Narrow pulse pressure (30 mmHg)",
            "Platelets < 50,000/μL with active hemoconcentration",
            "Persistent vomiting and cold extremities",
        ],
        "asha_id": "ASHA-001",
        "asha_name": "Sunita Devi",
        "pre_referral_action": "IV Cannula 18G secured, rapid Normal Saline 10ml/kg bolus started, urgent transfer via 108 ambulance.",
        "facility_id": "HFR-PCMC-W3",
        "facility_name": "PCMC UPHC Ward 3 (Escalated to YCM Hospital ICU)",
        "notes": "Community mosquito larval breeding observed in unsealed rooftop cement tanks nearby.",
    },
    {
        "id": "PCMC-CASE-002",
        "referral_id": "REF-PCMC-W3-0102",
        "name": "Aarush More",
        "age_months": 84,  # 7 years
        "age_display": "7Y",
        "sex": "M",
        "ward_id": "W3",
        "location": "Ward W3, Walhekarwadi, Sector 32, PCMC",
        "condition": "dengue_like",
        "diagnosis_display": "Pediatric Dengue with Warning Signs",
        "priority": "RED",
        "status": "ACKNOWLEDGED",
        "vitals": {
            "temp_c": 39.2,
            "temp_f": 102.6,
            "pulse_bpm": 118,
            "bp_systolic": 94,
            "bp_diastolic": 62,
            "spo2": 97,
            "platelet_count": 68000,
        },
        "symptoms": [
            "High fever for 4 days",
            "Severe abdominal tenderness (RUQ)",
            "Lethargy and refusal to eat",
            "Bleeding from gums while brushing",
            "Dengue NS1 Rapid Test Positive",
        ],
        "danger_signs": [
            "Persistent abdominal pain and tenderness",
            "Mucosal bleeding",
            "Lethargy in young child",
        ],
        "asha_id": "ASHA-001",
        "asha_name": "Sunita Devi",
        "pre_referral_action": "Oral rehydration solution given, paracetamol syrup 250mg, urgent pediatric referral.",
        "facility_id": "HFR-PCMC-W3",
        "facility_name": "PCMC UPHC Ward 3",
        "notes": "Child attended municipal school in Walhekarwadi where 3 other children report high fever.",
    },
    {
        "id": "PCMC-CASE-003",
        "referral_id": "REF-PCMC-W3-0103",
        "name": "Suresh Waghmare",
        "age_months": 504,  # 42 years
        "age_display": "42Y",
        "sex": "M",
        "ward_id": "W3",
        "location": "Ward W3, Akurdi Station Road, PCMC",
        "condition": "dengue_like",
        "diagnosis_display": "Dengue Fever without Warning Signs",
        "priority": "YELLOW",
        "status": "CLOSED",
        "vitals": {
            "temp_c": 38.6,
            "temp_f": 101.5,
            "pulse_bpm": 86,
            "bp_systolic": 118,
            "bp_diastolic": 78,
            "spo2": 98,
            "platelet_count": 110000,
        },
        "symptoms": [
            "Fever for 3 days with severe backache",
            "Severe retro-orbital headache",
            "No spontaneous bleeding, no abdominal tenderness",
            "Dengue NS1 Ag positive",
        ],
        "danger_signs": [],
        "asha_id": "ASHA-001",
        "asha_name": "Sunita Devi",
        "pre_referral_action": "Advised plenty of oral fluids (>2.5L/day), Tab Paracetamol 650mg TDS, daily CBC follow-up.",
        "facility_id": "HFR-PCMC-W3",
        "facility_name": "PCMC UPHC Ward 3",
        "outcome": {
            "diagnosis": "Uncomplicated Dengue Fever (Recovered)",
            "action": "treated",
            "note_for_asha": "Platelets stable at 145,000/μL on Day 6. Afebrile for 48h. Discharge with mosquito repellant advice.",
        },
        "notes": "Full recovery noted after outpatient symptomatic management.",
    },
    {
        "id": "PCMC-CASE-004",
        "referral_id": "REF-PCMC-W5-0104",
        "name": "Rohit Jadhav",
        "age_months": 228,  # 19 years
        "age_display": "19Y",
        "sex": "M",
        "ward_id": "W5",
        "location": "Ward W5, Landewadi, Bhosari, PCMC",
        "condition": "dengue_like",
        "diagnosis_display": "Dengue Hemorrhagic Fever with Epistaxis & Melena",
        "priority": "RED",
        "status": "IN_CARE",
        "vitals": {
            "temp_c": 39.4,
            "temp_f": 103.0,
            "pulse_bpm": 130,
            "bp_systolic": 86,
            "bp_diastolic": 54,
            "spo2": 95,
            "platelet_count": 24000,
            "hematocrit_pct": 51.0,
        },
        "symptoms": [
            "Acute high fever 6 days",
            "Active profuse epistaxis (anterior nasal pack placed)",
            "Dark tarry stools (melena)",
            "Cold and clammy skin over hands and feet",
        ],
        "danger_signs": [
            "Severe thrombocytopenia < 30,000/μL",
            "Overt spontaneous gastrointestinal & nasal hemorrhage",
            "Hypotension and tachycardia (Compensated Shock)",
        ],
        "asha_id": "ASHA-002",
        "asha_name": "Rekha Devi",
        "pre_referral_action": "Direct emergent 108 ambulance transfer to YCM Hospital ICU. Ringer Lactate fluid resuscitation underway.",
        "facility_id": "HFR-PCMC-W5",
        "facility_name": "PCMC UPHC Ward 5 (Shifted to YCM Hospital)",
        "notes": "Bhosari industrial scrap yard area adjacent; fogging request submitted to PCMC Health Department.",
    },
    {
        "id": "PCMC-CASE-005",
        "referral_id": "REF-PCMC-W5-0105",
        "name": "Pooja Patil",
        "age_months": 336,  # 28 years
        "age_display": "28Y",
        "sex": "F",
        "ward_id": "W5",
        "location": "Ward W5, Indrayani Nagar, Bhosari, PCMC",
        "condition": "dengue_like",
        "diagnosis_display": "Probable Dengue / Acute Arboviral Infection",
        "priority": "YELLOW",
        "status": "NEW",
        "vitals": {
            "temp_c": 38.8,
            "temp_f": 101.8,
            "pulse_bpm": 92,
            "bp_systolic": 110,
            "bp_diastolic": 72,
            "spo2": 98,
            "platelet_count": 84000,
        },
        "symptoms": [
            "Sudden fever 4 days with chills",
            "Severe myalgia and retro-orbital headache",
            "Maculopapular rash on trunk and arms",
            "Loss of appetite and mild nausea",
        ],
        "danger_signs": [],
        "asha_id": "ASHA-002",
        "asha_name": "Rekha Devi",
        "pre_referral_action": "Paracetamol 650mg SOS, ORS packet provided, referred to Ward 5 UPHC for Dengue Duo test.",
        "facility_id": "HFR-PCMC-W5",
        "facility_name": "PCMC UPHC Ward 5",
        "notes": "Patient works in Bhosari MIDC electronics assembly unit.",
    },
    {
        "id": "PCMC-CASE-006",
        "referral_id": "REF-PCMC-W1-0106",
        "name": "Ananya Kamble",
        "age_months": 11,
        "age_display": "11M",
        "sex": "F",
        "ward_id": "W1",
        "location": "Ward W1, Kharalwadi Slums, Pimpri, PCMC",
        "condition": "acute_diarrhoea",
        "diagnosis_display": "Acute Watery Diarrhoea with Severe Dehydration (Cholera Suspect)",
        "priority": "RED",
        "status": "NEW",
        "vitals": {
            "temp_c": 37.8,
            "temp_f": 100.0,
            "pulse_bpm": 152,
            "respiratory_rate": 44,
            "weight_kg": 7.1,
            "spo2": 96,
        },
        "symptoms": [
            "11 profuse watery rice-water stools in 12 hours",
            "Frequent vomiting (5 episodes)",
            "Sunken eyes, severely depressed anterior fontanelle",
            "Skin pinch of abdomen goes back very slowly (> 2 seconds)",
            "Child abnormally sleepy, floppy, and unable to suck breastmilk",
        ],
        "danger_signs": [
            "IMCI Severe Dehydration (Sunken eyes + skin pinch >2s + lethargic)",
            "Unable to drink / breastfeed",
            "Signs of impending hypovolemic shock",
        ],
        "asha_id": "ASHA-001",
        "asha_name": "Sunita Devi",
        "pre_referral_action": "First dose ORS attempted by cup-spoon, referred immediately for IV Ringer Lactate at YCM Hospital Pediatric ER.",
        "facility_id": "pcmc_ycm_hospital",
        "facility_name": "YCM Hospital Pimpri (Pediatric Emergency)",
        "notes": "Broken municipal water pipe mixed with drainage canal in Kharalwadi lane 4.",
    },
    {
        "id": "PCMC-CASE-007",
        "referral_id": "REF-PCMC-W1-0107",
        "name": "Nilesh Gaikwad",
        "age_months": 408,  # 34 years
        "age_display": "34Y",
        "sex": "M",
        "ward_id": "W1",
        "location": "Ward W1, Morwadi, Pimpri Gaon, PCMC",
        "condition": "acute_diarrhoea",
        "diagnosis_display": "Acute Gastroenteritis with Some Dehydration",
        "priority": "YELLOW",
        "status": "ACKNOWLEDGED",
        "vitals": {
            "temp_c": 38.1,
            "temp_f": 100.6,
            "pulse_bpm": 102,
            "bp_systolic": 102,
            "bp_diastolic": 68,
            "spo2": 98,
        },
        "symptoms": [
            "Watery diarrhoea 7 times since morning",
            "Cramping abdominal pain around umbilicus",
            "Thirst, dry buccal mucosa",
            "No blood in stool",
        ],
        "danger_signs": [],
        "asha_id": "ASHA-001",
        "asha_name": "Sunita Devi",
        "pre_referral_action": "Started on WHO-ORS Plan B (75 ml/kg over 4 hours), Zinc tablets 20mg, Tab Ondansetron 4mg.",
        "facility_id": "HFR-PCMC-W1",
        "facility_name": "PCMC UPHC Pimpri",
        "notes": "Multiple neighbors report loose motions after monsoon canal water seepage.",
    },
    {
        "id": "PCMC-CASE-008",
        "referral_id": "REF-PCMC-W7-0108",
        "name": "Rani Rathod",
        "age_months": 48,  # 4 years
        "age_display": "4Y",
        "sex": "F",
        "ward_id": "W7",
        "location": "Ward W7, Old Sangvi near Pavana River, PCMC",
        "condition": "acute_diarrhoea",
        "diagnosis_display": "Acute Bacillary Dysentery (Suspected Shigellosis)",
        "priority": "RED",
        "status": "IN_CARE",
        "vitals": {
            "temp_c": 39.1,
            "temp_f": 102.4,
            "pulse_bpm": 126,
            "respiratory_rate": 28,
            "spo2": 97,
        },
        "symptoms": [
            "Fever with chills for 2 days",
            "Small frequent stools containing macroscopic blood and mucopurulent exudate (9 episodes)",
            "Severe tenesmus with intense crying during defecation",
            "Moderate dehydration with sunken eyes",
        ],
        "danger_signs": [
            "Bloody diarrhoea in under-5 child",
            "High grade fever with toxicity",
            "Risk of Hemolytic Uremic Syndrome (HUS)",
        ],
        "asha_id": "ASHA-002",
        "asha_name": "Rekha Devi",
        "pre_referral_action": "Oral Ciprofloxacin suspension first dose administered under MO telephone guidance, ORS started, urgent referral.",
        "facility_id": "pcmc_ycm_hospital",
        "facility_name": "YCM Hospital Pediatric Ward",
        "notes": "Pavana riverbank slum pocket experiencing severe sanitation issues due to flooding.",
    },
    {
        "id": "PCMC-CASE-009",
        "referral_id": "REF-PCMC-W4-0109",
        "name": "Vivaan Kadam",
        "age_months": 18,
        "age_display": "18M",
        "sex": "M",
        "ward_id": "W4",
        "location": "Ward W4, Yamuna Nagar, Nigdi, PCMC",
        "condition": "pneumonia",
        "diagnosis_display": "Severe Childhood Bronchopneumonia with Hypoxemia",
        "priority": "RED",
        "status": "NEW",
        "vitals": {
            "temp_c": 39.3,
            "temp_f": 102.8,
            "respiratory_rate": 64,  # Severe tachypnea (>50 for 12-59m)
            "pulse_bpm": 146,
            "spo2": 88,  # Hypoxemic
        },
        "symptoms": [
            "Rapid breathing and severe cough for 48 hours",
            "Deep subcostal and intercostal chest indrawing",
            "Nasal flaring and audible expiratory grunting",
            "Unable to feed or retain fluids",
            "Cyanosis around lips noted on crying",
        ],
        "danger_signs": [
            "IMCI Very Severe Pneumonia / Disease",
            "Severe chest indrawing with SpO2 < 90%",
            "Inability to feed and central grunting",
        ],
        "asha_id": "ASHA-001",
        "asha_name": "Sunita Devi",
        "pre_referral_action": "First dose dispersible Amoxicillin given, emergency supplemental oxygen via face mask in transit, 108 ambulance called.",
        "facility_id": "pcmc_talera_hospital",
        "facility_name": "Talera Hospital Chinchwad (Pediatric HDU)",
        "notes": "History of indoor smoke exposure from coal chulha in small unventilated room.",
    },
    {
        "id": "PCMC-CASE-010",
        "referral_id": "REF-PCMC-W6-0110",
        "name": "Tanuja Salve",
        "age_months": 36,  # 3 years
        "age_display": "3Y",
        "sex": "F",
        "ward_id": "W6",
        "location": "Ward W6, Borhadewadi, Moshi, PCMC",
        "condition": "pneumonia",
        "diagnosis_display": "Non-Severe Community-Acquired Pneumonia",
        "priority": "YELLOW",
        "status": "CLOSED",
        "vitals": {
            "temp_c": 38.5,
            "temp_f": 101.3,
            "respiratory_rate": 46,  # Fast breathing (>40 for under-5)
            "pulse_bpm": 114,
            "spo2": 95,
        },
        "symptoms": [
            "Cough for 4 days",
            "Fever, runny nose",
            "Fast breathing without chest indrawing",
            "Child alert, drinking water and eating normally",
        ],
        "danger_signs": [],
        "asha_id": "ASHA-002",
        "asha_name": "Rekha Devi",
        "pre_referral_action": "Prescribed oral Amoxicillin 40mg/kg/day for 5 days, Paracetamol syrup, advised mother on fast breathing danger signs.",
        "facility_id": "HFR-PCMC-W6",
        "facility_name": "PCMC UPHC Moshi",
        "outcome": {
            "diagnosis": "Pneumonia - Resolved on Day 5 Follow-up",
            "action": "treated",
            "note_for_asha": "Respiratory rate normalized to 28/min. Cough subsided. Afebrile. Completed full 5-day antibiotic course.",
        },
        "notes": "Follow-up visit completed on Day 3 and Day 5; child completely healthy.",
    },
    {
        "id": "PCMC-CASE-011",
        "referral_id": "REF-PCMC-W2-0111",
        "name": "Ganesh Bhosale",
        "age_months": 372,  # 31 years
        "age_display": "31Y",
        "sex": "M",
        "ward_id": "W2",
        "location": "Ward W2, Anandnagar Slums, Chinchwad, PCMC",
        "condition": "malaria",
        "diagnosis_display": "Plasmodium Vivax Malaria (Tertian Fever)",
        "priority": "YELLOW",
        "status": "ACKNOWLEDGED",
        "vitals": {
            "temp_c": 40.0,
            "temp_f": 104.0,
            "pulse_bpm": 110,
            "bp_systolic": 114,
            "bp_diastolic": 74,
            "spo2": 98,
        },
        "symptoms": [
            "Periodic alternate day fever with severe shaking chills (rigor stage)",
            "Drenching night sweats and severe headache",
            "Mild splenomegaly (2 cm palpable below left costal margin)",
            "Rapid Diagnostic Test (RDT) positive for P. vivax LDH",
        ],
        "danger_signs": [],
        "asha_id": "ASHA-001",
        "asha_name": "Sunita Devi",
        "pre_referral_action": "Blood smear prepared for microscopy. Initiated Tab Chloroquine (600mg Day 1, 600mg Day 2, 300mg Day 3) + Primaquine 14 days per NVBDCP.",
        "facility_id": "pcmc_talera_hospital",
        "facility_name": "Talera Hospital Chinchwad",
        "notes": "G6PD deficiency screened negative prior to radical primaquine therapy.",
    },
    {
        "id": "PCMC-CASE-012",
        "referral_id": "REF-PCMC-W5-0112",
        "name": "Shabana Shaikh",
        "age_months": 312,  # 26 years
        "age_display": "26Y",
        "sex": "F",
        "ward_id": "W5",
        "location": "Ward W5, MIDC Shantinagar Brick Kiln, Bhosari, PCMC",
        "condition": "malaria",
        "diagnosis_display": "Complicated Falciparum Malaria (Cerebral / Hepatic)",
        "priority": "RED",
        "status": "NEW",
        "vitals": {
            "temp_c": 40.2,
            "temp_f": 104.4,
            "pulse_bpm": 128,
            "bp_systolic": 90,
            "bp_diastolic": 60,
            "spo2": 93,
            "total_bilirubin": 4.8,
        },
        "symptoms": [
            "Continuous remittent fever 5 days with confusion and delirium",
            "Marked scleral icterus (deep yellow eyes)",
            "Passage of dark burgundy / black urine (Blackwater fever suspect)",
            "RDT Bivalent strongly positive for P. falciparum (Pf HRP2 band)",
        ],
        "danger_signs": [
            "Altered sensorium and delirium in severe malaria",
            "Jaundice with hemoglobinuria (hemolysis)",
            "High risk of acute renal shutdown and cerebral malaria",
        ],
        "asha_id": "ASHA-002",
        "asha_name": "Rekha Devi",
        "pre_referral_action": "First dose IV Artesunate 2.4 mg/kg administered stat at UPHC Ward 5, urgently dispatched to YCM Hospital ICU via 108 ambulance.",
        "facility_id": "pcmc_ycm_hospital",
        "facility_name": "YCM Hospital Pimpri (Medical ICU)",
        "notes": "Seasonal migrant family working at construction brick kiln without bednets.",
    },
    {
        "id": "PCMC-CASE-013",
        "referral_id": "REF-PCMC-W8-0113",
        "name": "Aditya Chavan",
        "age_months": 168,  # 14 years
        "age_display": "14Y",
        "sex": "M",
        "ward_id": "W8",
        "location": "Ward W8, Kalewadi Phata, Rahatani, PCMC",
        "condition": "typhoid",
        "diagnosis_display": "Enteric Fever (Typhoid / Salmonella enterica)",
        "priority": "YELLOW",
        "status": "IN_CARE",
        "vitals": {
            "temp_c": 39.5,
            "temp_f": 103.1,
            "pulse_bpm": 76,  # Relative bradycardia (Faget's sign)
            "bp_systolic": 106,
            "bp_diastolic": 70,
            "spo2": 98,
        },
        "symptoms": [
            "Step-ladder rising fever for 9 consecutive days",
            "Thick white coated tongue with red margins",
            "Relative bradycardia (pulse 76 despite 103°F temp)",
            "Diffuse abdominal bloating, constipation followed by pea-soup stools",
            "Faint pink blanching rose spots on abdomen",
            "Widal Test: S. typhi 'O' titer 1:320, 'H' titer 1:320",
        ],
        "danger_signs": [],
        "asha_id": "ASHA-002",
        "asha_name": "Rekha Devi",
        "pre_referral_action": "Started on Tab Cefixime 20mg/kg/day in two divided doses for 14 days, antipyretics, high-calorie liquid diet.",
        "facility_id": "HFR-PCMC-W8",
        "facility_name": "PCMC UPHC Rahatani",
        "notes": "Patient consumed roadside sugarcane juice prepared with unhygienic ice.",
    },
    {
        "id": "PCMC-CASE-014",
        "referral_id": "REF-PCMC-W2-0114",
        "name": "Samarth Pawar",
        "age_months": 14,
        "age_display": "14M",
        "sex": "M",
        "ward_id": "W2",
        "location": "Ward W2, Chinchwad Gaon, Chaphekar Chowk, PCMC",
        "condition": "measles_like",
        "diagnosis_display": "Measles with Early Bronchial Complication (Unvaccinated Infant)",
        "priority": "RED",
        "status": "NEW",
        "vitals": {
            "temp_c": 39.4,
            "temp_f": 103.0,
            "respiratory_rate": 48,
            "pulse_bpm": 138,
            "spo2": 94,
        },
        "symptoms": [
            "High fever for 4 days with harsh barking cough and coryza",
            "Intense bilateral conjunctivitis with photophobia and tearing",
            "Characteristic Koplik's spots (tiny white lesions with red halo) on buccal mucosa opposite lower molars",
            "Maculopapular erythematous rash spreading from behind ears to hairline, face, and neck",
            "Zero doses of Measles-Rubella (MR) vaccine on RCH register",
        ],
        "danger_signs": [
            "Measles in unvaccinated infant with fast breathing",
            "Risk of post-measles pneumonia and corneal ulceration",
            "Highly contagious outbreak risk for PCMC Ward 2",
        ],
        "asha_id": "ASHA-001",
        "asha_name": "Sunita Devi",
        "pre_referral_action": "Administered Vitamin A 100,000 IU orally stat, immediate home respiratory isolation, notified PCMC Epidemiologist.",
        "facility_id": "HFR-PCMC-W2",
        "facility_name": "PCMC UPHC Chinchwad (Outbreak Surveillance)",
        "notes": "Index case of suspected measles cluster in Anandnagar slum lane 3. Active fever-rash survey launched.",
    },
    {
        "id": "PCMC-CASE-015",
        "referral_id": "REF-PCMC-W6-0115",
        "name": "Pranav Jagtap",
        "age_months": 72,  # 6 years
        "age_display": "6Y",
        "sex": "M",
        "ward_id": "W6",
        "location": "Ward W6, Moshi Alandi Road, PCMC",
        "condition": "aes",
        "diagnosis_display": "Acute Encephalitis Syndrome (AES) / Suspected Viral Meningoencephalitis",
        "priority": "RED",
        "status": "NEW",
        "vitals": {
            "temp_c": 39.9,
            "temp_f": 103.8,
            "pulse_bpm": 138,
            "bp_systolic": 112,
            "bp_diastolic": 76,
            "gcs_score": 10,  # E2 V3 M5 (altered sensorium)
            "spo2": 95,
        },
        "symptoms": [
            "Acute fever for 36 hours",
            "Two episodes of generalized tonic-clonic convulsions (lasting 3-4 mins each)",
            "Disorientation, drowsiness, and altered behavior",
            "Marked nuchal rigidity (neck stiffness positive)",
            "Positive Kernig and Brudzinski signs",
        ],
        "danger_signs": [
            "IMCI Danger Sign: Convulsions with altered consciousness",
            "Meningeal irritation signs present",
            "High risk of cerebral edema and respiratory arrest",
        ],
        "asha_id": "ASHA-002",
        "asha_name": "Rekha Devi",
        "pre_referral_action": "Airway secured in recovery position, rectal Midazolam administered to break status epilepticus, code-red 108 ambulance referral to PICU.",
        "facility_id": "pcmc_ycm_hospital",
        "facility_name": "YCM Hospital Pediatric ICU",
        "notes": "Emergency lumbar puncture and Japanese Encephalitis IgM / Enterovirus CSF panel requested.",
    },
    {
        "id": "PCMC-CASE-016",
        "referral_id": "REF-PCMC-W1-0116",
        "name": "Babanrao Mhaske",
        "age_months": 624,  # 52 years
        "age_display": "52Y",
        "sex": "M",
        "ward_id": "W1",
        "location": "Ward W1, Pimpri Camp, Near Railway Bridge, PCMC",
        "condition": "fever",
        "diagnosis_display": "Presumptive Pulmonary Tuberculosis (NTEP Screening)",
        "priority": "YELLOW",
        "status": "ACKNOWLEDGED",
        "vitals": {
            "temp_c": 37.9,
            "temp_f": 100.2,
            "pulse_bpm": 82,
            "bp_systolic": 124,
            "bp_diastolic": 80,
            "weight_kg": 46.5,
            "bmi": 16.4,
            "spo2": 96,
        },
        "symptoms": [
            "Chronic productive cough with yellow-green phlegm x 3 weeks",
            "Low-grade evening fever spikes accompanied by drenching night sweats",
            "Significant unintentional weight loss of 6.5 kg over 2 months",
            "Trace hemoptysis (streaks of fresh blood in sputum yesterday)",
        ],
        "danger_signs": [],
        "asha_id": "ASHA-001",
        "asha_name": "Sunita Devi",
        "pre_referral_action": "Sputum collection cup given for early morning sample, registered on Nikshay portal, referred for CBNAAT (TrueNat) at UPHC Pimpri.",
        "facility_id": "HFR-PCMC-W1",
        "facility_name": "PCMC UPHC Pimpri (NTEP DOTS Centre)",
        "notes": "Household contacts (wife and 2 teenage children) scheduled for symptom screening and Mantoux testing.",
    },
    {
        "id": "PCMC-CASE-017",
        "referral_id": "REF-PCMC-W7-0117",
        "name": "Meena Sonawane",
        "age_months": 288,  # 24 years
        "age_display": "24Y",
        "sex": "F",
        "ward_id": "W7",
        "location": "Ward W7, Pimple Gurav, Shinde Vasti, PCMC",
        "condition": "fever",
        "diagnosis_display": "High-Risk Pregnancy: Severe Pre-eclampsia at 34 Weeks Gestation",
        "priority": "RED",
        "status": "NEW",
        "vitals": {
            "bp_systolic": 168,
            "bp_diastolic": 112,
            "pulse_bpm": 96,
            "temp_c": 37.1,
            "temp_f": 98.8,
            "fetal_heart_rate": 144,
            "urine_albumin": "3+",
        },
        "symptoms": [
            "Severe persistent throbbing frontal headache not responsive to paracetamol",
            "Visual disturbances (scintillating scotomas and blurred vision)",
            "Epigastric and right upper quadrant abdominal pain",
            "Grade 3 bilateral pitting pedal and facial edema",
            "Urine dipstick shows 3+ proteinuria",
        ],
        "danger_signs": [
            "Blood pressure ≥ 160/110 mmHg with severe end-organ symptoms",
            "Impending eclampsia with cerebral symptoms",
            "Risk of maternal seizure, placental abruption, and fetal compromise",
        ],
        "asha_id": "ASHA-002",
        "asha_name": "Rekha Devi",
        "pre_referral_action": "Emergency loading dose Magnesium Sulfate (Pritchard regimen: 4g IV + 10g IM) initiated by ANM, rapid transport to YCM Labor Complex.",
        "facility_id": "pcmc_ycm_hospital",
        "facility_name": "YCM Hospital Pimpri (Obstetric Emergency)",
        "notes": "Primigravida, 33 weeks 6 days by LMP. Ultrasound shows viable singleton fetus with normal liquor volume.",
    },
    {
        "id": "PCMC-CASE-018",
        "referral_id": "REF-PCMC-W3-0118",
        "name": "Neonate of Sunita Waghmare",
        "age_months": 0,  # 18 days
        "age_display": "18 Days",
        "sex": "M",
        "ward_id": "W3",
        "location": "Ward W3, Walhekarwadi, Lane 2, PCMC",
        "condition": "pneumonia",
        "diagnosis_display": "Possible Serious Bacterial Infection (PSBI) / Early Neonatal Sepsis",
        "priority": "RED",
        "status": "IN_CARE",
        "vitals": {
            "temp_c": 35.4,  # Hypothermia (<36.5°C)
            "temp_f": 95.7,
            "respiratory_rate": 68,  # Neonatal tachypnea (>60/min)
            "pulse_bpm": 164,
            "weight_kg": 2.3,
            "spo2": 91,
        },
        "symptoms": [
            "Severe hypothermia (cold to touch, core temp 35.4°C)",
            "Refusal to feed / unable to latch for past 8 hours",
            "Lethargic with weak whiny cry",
            "Umbilical cord stump inflamed, erythematous, with purulent foul-smelling discharge",
            "Mild subcostal chest indrawing with tachypnea",
        ],
        "danger_signs": [
            "IMCI PSBI Classification: Hypothermia + feeding intolerance + omphalitis",
            "High risk of rapid septic shock and neonatal mortality",
        ],
        "asha_id": "ASHA-001",
        "asha_name": "Sunita Devi",
        "pre_referral_action": "Immediate Kangaroo Mother Care (KMC) rewarming initiated, first dose IM Gentamicin + Ampicillin per IMNCI protocol, emergency SNCU transfer.",
        "facility_id": "pcmc_ycm_hospital",
        "facility_name": "YCM Hospital Pimpri (SNCU - Special Newborn Care Unit)",
        "notes": "Delivered at home without skilled birth attendant; unhygienic cord application suspected.",
    },
    {
        "id": "PCMC-CASE-019",
        "referral_id": "REF-PCMC-W8-0119",
        "name": "Vaibhav Shinde",
        "age_months": 192,  # 16 years
        "age_display": "16Y",
        "sex": "M",
        "ward_id": "W8",
        "location": "Ward W8, Rahatani Shinde Vasti, PCMC",
        "condition": "fever",
        "diagnosis_display": "Acute Viral Hepatitis A (Acute Icteric Phase)",
        "priority": "YELLOW",
        "status": "CLOSED",
        "vitals": {
            "temp_c": 38.2,
            "temp_f": 100.8,
            "pulse_bpm": 80,
            "bp_systolic": 110,
            "bp_diastolic": 72,
            "total_bilirubin": 6.4,
            "sgpt_alt": 840,
        },
        "symptoms": [
            "Deep yellow discoloration of sclera and skin for 6 days",
            "Dark tea-colored urine and pale clay-colored stools",
            "Severe anorexia, nausea, and vomiting triggered by food smells",
            "Tender hepatomegaly palpable 3 cm below right costal margin",
            "Serum Anti-HAV IgM strongly positive",
        ],
        "danger_signs": [],
        "asha_id": "ASHA-002",
        "asha_name": "Rekha Devi",
        "pre_referral_action": "Advised complete physical rest, easily digestible high-carbohydrate low-fat diet, safe boiled drinking water, strictly avoided hepatotoxic medications.",
        "facility_id": "HFR-PCMC-W8",
        "facility_name": "PCMC UPHC Rahatani",
        "outcome": {
            "diagnosis": "Acute Hepatitis A - Convalescent Phase",
            "action": "treated",
            "note_for_asha": "Bilirubin decreased to 2.1 mg/dL. Appetite restored. Urine color normal. Household water chlorination advised.",
        },
        "notes": "Water supply contamination investigated in Shinde Vasti; chlorination tablets distributed to 45 homes.",
    },
    {
        "id": "PCMC-CASE-020",
        "referral_id": "REF-PCMC-W4-0120",
        "name": "Deepak Salunke",
        "age_months": 456,  # 38 years
        "age_display": "38Y",
        "sex": "M",
        "ward_id": "W4",
        "location": "Ward W4, Sector 22, Nigdi Pradhikaran, PCMC",
        "condition": "fever",
        "diagnosis_display": "Scrub Typhus (Orientia tsutsugamushi) with Pathognomonic Eschar",
        "priority": "YELLOW",
        "status": "ACKNOWLEDGED",
        "vitals": {
            "temp_c": 39.6,
            "temp_f": 103.2,
            "pulse_bpm": 106,
            "bp_systolic": 104,
            "bp_diastolic": 68,
            "spo2": 95,
        },
        "symptoms": [
            "Severe remittent high fever for 8 days with chills",
            "Intense pounding frontal headache and generalized lymphadenopathy",
            "Pathognomonic black necrotic crusted eschar with erythematous halo (cigarette burn appearance) in right groin",
            "Mild transaminitis and thrombocytopenia (platelets 98,000/μL)",
        ],
        "danger_signs": [],
        "asha_id": "ASHA-001",
        "asha_name": "Sunita Devi",
        "pre_referral_action": "Eschar photographed and documented. Started on oral Doxycycline 100 mg BD x 7 days per IDSP zoonosis protocol.",
        "facility_id": "pcmc_talera_hospital",
        "facility_name": "Talera Hospital Chinchwad",
        "notes": "Patient works as a landscape gardener clearing thick brush and shrubbery in PCMC municipal parks.",
    },
]

# Weekly syndromic disease counts across W1..W8 for 12 weeks
# Simulating the real seasonal / outbreak curve in PCMC
WEEKLY_PATTERNS = {
    # Outbreak in W3 (Akurdi) & W5 (Bhosari) reaching high threshold in weeks 10..12
    "dengue_like": {
        "W1": [1, 0, 0, 1, 2, 1, 2, 2, 3, 3, 4, 4],
        "W2": [0, 0, 1, 1, 0, 1, 2, 2, 2, 3, 3, 3],
        "W3": [0, 1, 0, 1, 1, 2, 2, 3, 4, 6, 8, 11],  # Peak outbreak in W3
        "W4": [0, 0, 0, 1, 1, 0, 1, 1, 2, 2, 1, 2],
        "W5": [0, 0, 1, 0, 1, 2, 3, 3, 5, 5, 7, 9],   # Secondary outbreak in W5
        "W6": [0, 0, 0, 0, 1, 1, 1, 2, 1, 2, 2, 3],
        "W7": [1, 0, 1, 0, 1, 2, 1, 2, 3, 2, 3, 4],
        "W8": [0, 1, 0, 0, 1, 1, 1, 1, 2, 1, 2, 2],
    },
    # Canal contamination cluster in W1 (Pimpri) and riverbank W7 (Sangvi)
    "acute_diarrhoea": {
        "W1": [2, 3, 4, 3, 5, 6, 7, 9, 12, 14, 15, 18],  # Severe cluster
        "W2": [1, 1, 2, 2, 1, 3, 2, 3, 4, 4, 3, 4],
        "W3": [2, 1, 1, 2, 3, 2, 2, 3, 4, 3, 3, 4],
        "W4": [1, 0, 1, 2, 1, 2, 2, 1, 3, 2, 3, 2],
        "W5": [2, 2, 3, 2, 3, 4, 3, 5, 5, 6, 6, 7],
        "W6": [1, 1, 1, 2, 2, 3, 2, 3, 4, 4, 5, 5],
        "W7": [1, 2, 2, 3, 4, 4, 6, 8, 10, 11, 13, 14], # Riverbank cluster
        "W8": [1, 2, 1, 1, 2, 2, 3, 2, 3, 3, 4, 3],
    },
    # Measles cluster in unvaccinated pocket of W2 (Chinchwad)
    "measles_like": {
        "W1": [0, 0, 0, 0, 1, 0, 1, 1, 1, 2, 2, 2],
        "W2": [0, 0, 0, 1, 0, 1, 2, 3, 4, 5, 6, 7],     # Measles alert in W2
        "W3": [0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1],
        "W4": [0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 1],
        "W5": [0, 0, 1, 0, 0, 1, 1, 1, 2, 2, 3, 2],
        "W6": [0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 2, 2],
        "W7": [0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 1],
        "W8": [0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1],
    },
    # Winter / Seasonal pediatric ARI & Bronchopneumonia in W4 (Nigdi) & W6 (Moshi)
    "pneumonia": {
        "W1": [1, 1, 1, 2, 2, 2, 3, 3, 4, 4, 5, 4],
        "W2": [2, 1, 2, 1, 3, 2, 3, 4, 3, 4, 4, 5],
        "W3": [1, 2, 1, 2, 2, 3, 2, 3, 3, 4, 4, 4],
        "W4": [1, 2, 2, 3, 3, 4, 5, 6, 8, 7, 9, 10],   # High pediatric ARI
        "W5": [2, 2, 3, 3, 4, 4, 5, 5, 6, 7, 7, 8],
        "W6": [1, 1, 2, 2, 3, 4, 4, 5, 6, 6, 8, 8],
        "W7": [1, 1, 2, 1, 2, 2, 3, 2, 3, 3, 4, 4],
        "W8": [1, 0, 1, 2, 2, 2, 2, 3, 3, 4, 4, 3],
    },
    # Malaria in Bhosari industrial construction sites (W5) & Chinchwad (W2)
    "malaria": {
        "W1": [0, 1, 0, 1, 1, 2, 1, 2, 2, 3, 3, 3],
        "W2": [1, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5],
        "W3": [0, 0, 1, 0, 1, 1, 2, 1, 2, 2, 2, 3],
        "W4": [0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 2],
        "W5": [0, 1, 1, 2, 2, 3, 4, 4, 5, 6, 6, 7],     # Construction vector breeding
        "W6": [0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4],
        "W7": [1, 1, 0, 1, 1, 2, 2, 2, 3, 3, 3, 4],
        "W8": [0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 3],
    },
    # Enteric fever in Rahatani (W8)
    "typhoid": {
        "W1": [1, 1, 2, 1, 2, 2, 3, 3, 4, 4, 4, 5],
        "W2": [0, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4],
        "W3": [1, 0, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4],
        "W4": [0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3],
        "W5": [1, 1, 2, 2, 2, 3, 3, 4, 4, 5, 5, 5],
        "W6": [1, 0, 1, 1, 2, 2, 2, 3, 3, 4, 4, 4],
        "W7": [1, 1, 1, 2, 2, 3, 3, 3, 4, 4, 5, 5],
        "W8": [1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 7, 8],     # Typhoid signal
    },
    # Sporadic AES signal in Moshi (W6)
    "aes": {
        "W1": [0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0],
        "W2": [0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1],
        "W3": [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1],
        "W4": [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
        "W5": [0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 1],
        "W6": [0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 2, 2],     # AES alert in W6
        "W7": [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
        "W8": [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1],
    },
    # Acute Febrile Illness surveillance baseline
    "fever": {
        "W1": [6, 7, 8, 8, 10, 11, 13, 14, 16, 18, 19, 21],
        "W2": [5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 17, 18],
        "W3": [7, 8, 9, 10, 12, 14, 15, 17, 20, 22, 24, 28],
        "W4": [4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16],
        "W5": [6, 7, 8, 9, 11, 13, 15, 17, 19, 21, 23, 26],
        "W6": [5, 5, 6, 7, 8, 10, 11, 13, 14, 16, 17, 19],
        "W7": [6, 7, 8, 9, 10, 12, 13, 15, 17, 18, 20, 22],
        "W8": [5, 6, 7, 7, 9, 10, 12, 13, 15, 16, 18, 20],
    },
}


async def seed_pcmc_database() -> None:
    print("=" * 70)
    print("Starting PCMC Disease Surveillance & Clinical Cases Seeding...")
    print("=" * 70)

    now = datetime.now(timezone.utc)
    base_time = now - timedelta(days=84)  # 12 weeks back

    async with AsyncSessionLocal() as db:
        # 1. Ensure primary PCMC ASHA user exists
        user_asha = await db.scalar(select(User).where(User.asha_id == "ASHA-001"))
        if user_asha is None:
            user_asha = User(
                id=str(uuid.uuid4()),
                asha_id="ASHA-001",
                name="Sunita Devi",
                role="ASHA",
                area_village="Akurdi Gaon",
                area_subcentre="PCMC SC Akurdi",
                area_phc="PCMC UPHC Ward 3",
                area_block="PCMC",
                area_district="PCMC",
                area_state="Maharashtra",
                state_code="MH",
                district_code="PCMC",
                block_code="PCMC",
                is_active=True,
            )
            db.add(user_asha)
            await db.flush()

        worker_id = user_asha.id

        # 2. Seed Disease Counts (all 8 wards x 12 weeks x 8 conditions)
        print("\n[1/4] Populating disease_counts across PCMC W1..W8 (Weeks 1..12)...")
        count_rows_inserted = 0
        for condition, ward_dict in WEEKLY_PATTERNS.items():
            for ward_id, weeks in ward_dict.items():
                for week_idx, count_val in enumerate(weeks, start=1):
                    observed_date = base_time + timedelta(weeks=week_idx - 1, days=4)

                    # IDSP baseline entry
                    stmt = select(DiseaseCountRow).where(
                        DiseaseCountRow.district_id == "PCMC",
                        DiseaseCountRow.ward_id == ward_id,
                        DiseaseCountRow.week_index == week_idx,
                        DiseaseCountRow.condition == condition,
                        DiseaseCountRow.source == "idsp",
                    )
                    existing_idsp = (await db.execute(stmt)).scalar_one_or_none()
                    if existing_idsp:
                        existing_idsp.count = count_val
                        existing_idsp.observed_at = observed_date.replace(tzinfo=None)
                    else:
                        db.add(
                            DiseaseCountRow(
                                id=str(uuid.uuid4()),
                                district_id="PCMC",
                                ward_id=ward_id,
                                week_index=week_idx,
                                condition=condition,
                                count=count_val,
                                source="idsp",
                                observed_at=observed_date.replace(tzinfo=None),
                            )
                        )
                        count_rows_inserted += 1

                    # For recent weeks (weeks 8..12), add live "app" reports (authoritative syndromic reports from ASHAs)
                    if week_idx >= 8:
                        app_count = count_val  # or slightly higher to simulate real-time spike
                        app_observed = observed_date + timedelta(hours=6)
                        stmt_app = select(DiseaseCountRow).where(
                            DiseaseCountRow.district_id == "PCMC",
                            DiseaseCountRow.ward_id == ward_id,
                            DiseaseCountRow.week_index == week_idx,
                            DiseaseCountRow.condition == condition,
                            DiseaseCountRow.source == "app",
                        )
                        existing_app = (await db.execute(stmt_app)).scalar_one_or_none()
                        if existing_app:
                            existing_app.count = app_count
                            existing_app.observed_at = app_observed.replace(tzinfo=None)
                        else:
                            db.add(
                                DiseaseCountRow(
                                    id=str(uuid.uuid4()),
                                    district_id="PCMC",
                                    ward_id=ward_id,
                                    week_index=week_idx,
                                    condition=condition,
                                    count=app_count,
                                    source="app",
                                    observed_at=app_observed.replace(tzinfo=None),
                                )
                            )
                            count_rows_inserted += 1

        await db.flush()
        print(f"  ✓ Processed 768+ disease_counts syndromic surveillance entries.")

        # 3. Seed Desk Tickets, Triage Tickets, and Referral Records
        print("\n[2/4] Populating 20 rich clinical disease cases in PCMC...")
        seeded_tickets = 0
        for idx, case in enumerate(PCMC_CASES, start=1):
            created_dt = now - timedelta(hours=(20 - idx) * 3, minutes=15 * idx)
            created_ms = int(created_dt.timestamp() * 1000)

            # A. TriageTicket (for mobile app offline sync & triage activity)
            triage_rec = await db.get(TriageTicket, case["id"])
            modules_content = [
                {
                    "module": "chief_complaint",
                    "condition": case["condition"],
                    "diagnosis": case["diagnosis_display"],
                    "symptoms": case["symptoms"],
                    "vitals": case["vitals"],
                },
                {
                    "module": "clinical_triage",
                    "priority": case["priority"],
                    "danger_signs": case["danger_signs"],
                    "action": case["pre_referral_action"],
                    "facility": case["facility_name"],
                },
            ]
            if triage_rec:
                triage_rec.name = case["name"]
                triage_rec.age_months = case["age_months"]
                triage_rec.location = case["location"]
                triage_rec.ward_id = case["ward_id"]
                triage_rec.flag = case["priority"]
                triage_rec.additional_details = f"{case['diagnosis_display']} - {case['pre_referral_action']}"
                triage_rec.modules_json = json.dumps(modules_content)
                triage_rec.updated_at = created_ms
            else:
                db.add(
                    TriageTicket(
                        id=case["id"],
                        name=case["name"],
                        age_months=case["age_months"],
                        location=case["location"],
                        additional_details=f"{case['diagnosis_display']} - {case['pre_referral_action']}",
                        ward_id=case["ward_id"],
                        flag=case["priority"],
                        sms=f"PCMC ALERT|{case['ward_id']}|{case['priority']}|{case['name']}|{case['diagnosis_display']}",
                        modules_json=json.dumps(modules_content),
                        worker_modules_json=json.dumps({"asha_name": case["asha_name"], "ward": case["ward_id"]}),
                        attachments_json="[]",
                        engine_version="setu-engine-v2.4",
                        model_version="imci-pcmc-2026.1",
                        created_at=created_ms,
                        updated_at=created_ms,
                        sync_status="synced",
                        worker_id=worker_id,
                        block_code="PCMC",
                    )
                )

            # B. DeskTicket (for PHC MO command desk queue)
            ticket_stmt = select(DeskTicket).where(DeskTicket.referral_id == case["referral_id"])
            desk_ticket = (await db.execute(ticket_stmt)).scalar_one_or_none()

            payload = {
                "id": case["id"],
                "referral_id": case["referral_id"],
                "patient_name": case["name"],
                "patient_age": case["age_display"],
                "patient_gender": case["sex"],
                "ward_id": case["ward_id"],
                "locality": case["location"],
                "condition": case["condition"],
                "suspected_diagnosis": case["diagnosis_display"],
                "priority": case["priority"],
                "flag": case["priority"],
                "vitals": case["vitals"],
                "symptoms": case["symptoms"],
                "danger_signs": case["danger_signs"],
                "asha_id": case["asha_id"],
                "asha_name": case["asha_name"],
                "pre_referral_action": case["pre_referral_action"],
                "receiving_facility": case["facility_name"],
                "created_at": created_dt.isoformat(),
                "epidemiology_notes": case["notes"],
            }

            sla_due = created_dt + timedelta(hours=4) if case["priority"] == "RED" else None
            ack_time = created_dt + timedelta(minutes=25) if case["status"] in ("ACKNOWLEDGED", "IN_CARE", "CLOSED") else None

            if desk_ticket:
                desk_ticket.priority = case["priority"]
                desk_ticket.status = case["status"]
                desk_ticket.ward_id = case["ward_id"]
                desk_ticket.payload_json = json.dumps(payload)
                desk_ticket.acknowledged_at = ack_time.replace(tzinfo=None) if ack_time else None
            else:
                desk_ticket = DeskTicket(
                    id=str(uuid.uuid4()),
                    referral_id=case["referral_id"],
                    priority=case["priority"],
                    status=case["status"],
                    district_id="PCMC",
                    ward_id=case["ward_id"],
                    asha_id=case["asha_id"],
                    created_at=created_dt.replace(tzinfo=None),
                    sla_due_at=sla_due.replace(tzinfo=None) if sla_due else None,
                    escalated_level=0,
                    acknowledged_at=ack_time.replace(tzinfo=None) if ack_time else None,
                    payload_json=json.dumps(payload),
                    idempotency_key=f"idemp-{case['referral_id']}",
                )
                db.add(desk_ticket)
                await db.flush()

            # C. DeskOutcome (for CLOSED tickets)
            if case.get("outcome"):
                outcome_data = case["outcome"]
                existing_outcome = (await db.execute(select(DeskOutcome).where(DeskOutcome.ticket_id == desk_ticket.id))).scalar_one_or_none()
                fhir_bundle = {
                    "resourceType": "Bundle",
                    "type": "document",
                    "entry": [
                        {"resource": {"resourceType": "Condition", "code": {"text": outcome_data["diagnosis"]}}},
                        {"resource": {"resourceType": "Encounter", "status": "finished", "subject": {"display": case["name"]}}},
                    ],
                }
                if not existing_outcome:
                    db.add(
                        DeskOutcome(
                            id=str(uuid.uuid4()),
                            ticket_id=desk_ticket.id,
                            diagnosis=outcome_data["diagnosis"],
                            action=outcome_data["action"],
                            note_for_asha=outcome_data["note_for_asha"],
                            outcome_label_for_ml=outcome_data["action"],
                            fhir_json=json.dumps(fhir_bundle),
                            recorded_at=created_dt.replace(tzinfo=None) + timedelta(hours=8),
                        )
                    )

            # D. ReferralRecord (for facility referral queue API)
            ref_rec = await db.get(ReferralRecord, case["referral_id"])
            clinical_referral_note = (
                f"[{case['priority']} REFERRAL] {case['diagnosis_display']}\n"
                f"Patient: {case['name']} ({case['age_display']}, {case['sex']})\n"
                f"Ward: {case['ward_id']} - {case['location']}\n"
                f"Vitals: {json.dumps(case['vitals'])}\n"
                f"Key Symptoms: {', '.join(case['symptoms'])}\n"
                f"Danger Signs: {', '.join(case['danger_signs']) if case['danger_signs'] else 'None'}\n"
                f"ASHA First-Aid / Action: {case['pre_referral_action']}\n"
                f"Referred To: {case['facility_name']}"
            )
            if ref_rec:
                ref_rec.triage_flag = case["priority"]
                ref_rec.destination_facility_id = case["facility_id"]
                ref_rec.referral_note_text = clinical_referral_note
                ref_rec.status = "outcome_recorded" if case["status"] == "CLOSED" else "arrived" if case["status"] == "IN_CARE" else "pending"
            else:
                db.add(
                    ReferralRecord(
                        id=case["referral_id"],
                        triage_flag=case["priority"],
                        destination_facility_id=case["facility_id"],
                        destination_level="UPHC_OR_TERTIARY",
                        transport_arranged="108_Ambulance" if case["priority"] == "RED" else "Self/Auto",
                        status="outcome_recorded" if case["status"] == "CLOSED" else "arrived" if case["status"] == "IN_CARE" else "pending",
                        outcome="treated" if case["status"] == "CLOSED" else None,
                        referral_note_text=clinical_referral_note,
                        created_at=created_ms,
                        updated_at=created_ms,
                        sync_status="synced",
                        block_code="PCMC",
                    )
                )

            seeded_tickets += 1
            print(f"  ✓ [{case['ward_id']}] {case['priority']:<6} | {case['condition']:<16} | {case['name']:<18} ({case['age_display']}) -> {case['diagnosis_display']}")

        # 4. Compile and Publish official Context Pack for PCMC
        print("\n[3/4] Publishing official PCMC Context Pack with outbreak radar active ward...")
        desk = TriageDesk(db)
        pack = await desk.publish_next_pack("PCMC")
        pack_data = json.loads(pack.body_json)
        print(f"  ✓ Context Pack Version {pack.version} generated successfully (ETag: {pack.etag})")
        print(f"  ✓ Active Dengue Outbreak Ward identified: {pack_data.get('active_dengue_ward')}")
        print(f"  ✓ Total merged syndromic data points in pack: {len(pack_data.get('disease_counts', []))}")

        # 5. Commit all database transactions
        print("\n[4/4] Committing all transactions to Supabase PostgreSQL...")
        await db.commit()
        print("  ✓ All changes committed successfully!")

    print("\n" + "=" * 70)
    print("SUCCESS: PCMC Disease Cases & Surveillance Data Seeded Successfully!")
    print("=" * 70)


if __name__ == "__main__":
    asyncio.run(seed_pcmc_database())
