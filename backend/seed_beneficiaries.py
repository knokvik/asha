"""Seed script to populate 25 real, clinical beneficiary members grouped into realistic households
assigned across ASHA workers (Sunita Devi, Rekha Devi, Anita Sharma).
Includes:
- Baby Aarav (Newborn HBNC Day 7) & Mother Kavita Singh
- High-risk ANC mother Pooja Devi (Severe Gestational HTN)
- NCD Hypertension & Type-2 DM senior citizen Ramprasad Verma
- Toddler Priya Yadav (Immunization & Samarth nutrition tracking)
- Presumptive TB patient Shanti Devi (Nikshay tracking)
- Plus 20 more realistic beneficiaries with interlinked Clinical Encounters,
  Triage Tickets, Triage Results, Referral Records, Visit Schedules, and Consent Records.
"""
import asyncio
import datetime
import json
import time
import uuid
from sqlalchemy import text
from db.session import AsyncSessionLocal

# ASHA Worker IDs from users table
ASHA_SUNITA = "9df7a6d5-16b9-4aac-a74f-35988534fc30"  # ASHA-001 Sunita Devi (Phone: 8767374879)
ASHA_REKHA = "dd1f3d35-5137-479e-a753-c0d9ffa865cc"   # ASHA-002 Rekha Devi (Phone: 7744811540)
ASHA_ANITA = "9dedd850-701a-4801-90d7-e65abfba1ca6"   # ASHA-003 Anita Sharma (Phone: 8149374187)

# Facilities
PHC_SHAHPUR = "phc-shahpur"
SC_SHAHPUR = "sc-shahpur"
CHC_SHIVPUR = "chc-shivpur"
HOSP_DISTRICT = "hosp-district"

NOW_MS = int(time.time() * 1000)
DAY_MS = 24 * 3600 * 1000
NOW_DT = datetime.datetime.utcnow()

# 25 Realistic Beneficiaries in 10 Households
SEED_DATA = [
    # ── HOUSEHOLD 1: Vikram Singh Family (Baby Aarav & Postpartum Mother) ──
    {
        "household": {
            "id": "hh_singh_01",
            "village": "Rampur",
            "hamlet": "Ward 1 (Main Basti)",
            "head_name": "Vikram Singh",
            "contact_phone": "9811223340",
            "social_category": "OBC",
            "is_bpl": False,
            "worker_id": ASHA_SUNITA,
            "landmark_notes": "Near Primary School & Well",
            "block_code": "BLK_01",
        },
        "members": [
            {
                "id": "mem_vikram_01",
                "name": "Vikram Singh",
                "sex": "M",
                "dob_approx": NOW_MS - (26 * 365 * DAY_MS),
                "relationship_to_head": "Head",
                "phone": "9811223340",
                "abha_id": "14-5544-3322-1001",
                "worker_id": ASHA_SUNITA,
                "lifecycle_status": "active",
            },
            {
                "id": "mem_kavita_02",  # Kavita Singh (Postpartum Mother)
                "name": "Kavita Singh",
                "sex": "F",
                "dob_approx": NOW_MS - (22 * 365 * DAY_MS),
                "relationship_to_head": "Wife",
                "phone": "9811223344",
                "abha_id": "14-5544-3322-1100",
                "worker_id": ASHA_SUNITA,
                "lifecycle_status": "active",
                "is_pregnant": False,
                "encounters": [
                    {
                        "id": "enc_kavita_pnc_01",
                        "encounter_type": "pnc_visit",
                        "program_code": "pnc",
                        "encounter_date": NOW_MS - (7 * DAY_MS),
                        "asha_id": "ASHA-001",
                        "status": "completed",
                        "visit_notes": "PNC Day 7: Episiotomy wound clean, lactation established well, mild anemia (Hb 10.4). Given IFA tablets.",
                        "worker_id": ASHA_SUNITA,
                    }
                ],
                "schedules": [
                    {
                        "id": "vs_kavita_pnc_14",
                        "program_code": "pnc",
                        "visit_type": "PNC Day 14 Follow-up Visit",
                        "due_date": NOW_MS + (7 * DAY_MS),
                        "due_window_start": NOW_MS + (5 * DAY_MS),
                        "due_window_end": NOW_MS + (9 * DAY_MS),
                        "status": "scheduled",
                    }
                ]
            },
            {
                "id": "mem_aarav_02",  # Baby Aarav (Newborn HBNC Day 7)
                "name": "Baby Aarav",
                "sex": "M",
                "dob_approx": NOW_MS - (7 * DAY_MS),
                "relationship_to_head": "Son",
                "abha_id": "14-5544-3322-1101",
                "worker_id": ASHA_SUNITA,
                "lifecycle_status": "active",
                "is_infant": True,
                "encounters": [
                    {
                        "id": "enc_aarav_hbnc_07",
                        "encounter_type": "hbnc_visit",
                        "program_code": "hbnc",
                        "encounter_date": NOW_MS,
                        "asha_id": "ASHA-001",
                        "status": "completed",
                        "visit_notes": "HBNC Day 7: Weight 2.85 kg (+250g). Cord dry and clean, breastfeeding vigorously, no jaundice. Breathing rate 42/min normal.",
                        "worker_id": ASHA_SUNITA,
                        "triage": {
                            "id": "tr_aarav_07",
                            "flag": "GREEN",
                            "rule_version_id": "v1.0-mohfw",
                            "findings_json": json.dumps([
                                {"finding": "Normal newborn temperature 36.8°C", "severity": "normal"},
                                {"finding": "Adequate suckling and urine output >6 times/day", "severity": "normal"},
                                {"finding": "Weight gain on track", "severity": "normal"}
                            ])
                        }
                    }
                ],
                "schedules": [
                    {
                        "id": "vs_aarav_hbnc_14",
                        "program_code": "hbnc",
                        "visit_type": "HBNC Day 14 Newborn Check",
                        "due_date": NOW_MS + (7 * DAY_MS),
                        "due_window_start": NOW_MS + (5 * DAY_MS),
                        "due_window_end": NOW_MS + (9 * DAY_MS),
                        "status": "due",
                    },
                    {
                        "id": "vs_aarav_opv_6w",
                        "program_code": "immunization",
                        "visit_type": "OPV-1 + Pentavalent-1 + Rota-1 (6 Weeks)",
                        "due_date": NOW_MS + (35 * DAY_MS),
                        "due_window_start": NOW_MS + (30 * DAY_MS),
                        "due_window_end": NOW_MS + (42 * DAY_MS),
                        "status": "scheduled",
                    }
                ]
            }
        ]
    },

    # ── HOUSEHOLD 2: Ramesh Kumar Family (Pooja Devi High-Risk ANC) ──
    {
        "household": {
            "id": "hh_kumar_02",
            "village": "Rampur",
            "hamlet": "Ward 2 (Purwa Tola)",
            "head_name": "Ramesh Kumar",
            "contact_phone": "9876501120",
            "social_category": "OBC",
            "is_bpl": True,
            "worker_id": ASHA_SUNITA,
            "landmark_notes": "Near Temple Road",
            "block_code": "BLK_01",
        },
        "members": [
            {
                "id": "mem_ramesh_02",
                "name": "Ramesh Kumar",
                "sex": "M",
                "dob_approx": NOW_MS - (28 * 365 * DAY_MS),
                "relationship_to_head": "Head",
                "phone": "9876501120",
                "abha_id": "14-8899-7711-2001",
                "worker_id": ASHA_SUNITA,
                "lifecycle_status": "active",
            },
            {
                "id": "mem_pooja_01",  # Pooja Devi (High-Risk ANC Pre-Eclampsia)
                "name": "Pooja Devi",
                "sex": "F",
                "dob_approx": NOW_MS - (24 * 365 * DAY_MS),
                "relationship_to_head": "Wife",
                "phone": "9876501122",
                "abha_id": "14-8899-7711-2233",
                "rch_id": "RCH-2026-90123",
                "worker_id": ASHA_SUNITA,
                "lifecycle_status": "active",
                "is_pregnant": True,
                "encounters": [
                    {
                        "id": "enc_pooja_anc_01",
                        "encounter_type": "anc_visit",
                        "program_code": "anc",
                        "encounter_date": NOW_MS - (1 * DAY_MS),
                        "asha_id": "ASHA-001",
                        "status": "completed",
                        "visit_notes": "Gestational Age: 32 weeks. Severe frontal headache, pedal edema +++, BP 152/98 mmHg. Suspected Pre-Eclampsia. Triage RED urgent referral.",
                        "worker_id": ASHA_SUNITA,
                        "triage": {
                            "id": "tr_pooja_anc_01",
                            "flag": "RED",
                            "rule_version_id": "v1.0-mohfw",
                            "findings_json": json.dumps([
                                {"finding": "High BP: 152/98 mmHg (Pre-eclampsia trigger)", "severity": "danger"},
                                {"finding": "Persistent frontal headache & visual blurriness", "severity": "danger"},
                                {"finding": "Bilateral pitting pedal edema +++", "severity": "danger"}
                            ])
                        },
                        "referral": {
                            "id": "ref_pooja_01",
                            "triage_flag": "RED",
                            "destination_facility_id": PHC_SHAHPUR,
                            "destination_level": "PHC",
                            "transport_arranged": "108 Ambulance",
                            "status": "en_route",
                            "referral_note_text": "High-risk 32W primigravida presenting with acute pre-eclampsia signs (BP 152/98, severe headache). Emergency stabilization & lab workup needed."
                        }
                    }
                ],
                "schedules": [
                    {
                        "id": "vs_pooja_anc_phc",
                        "program_code": "anc",
                        "visit_type": "RED Emergency Referral Doctor Follow-up (PHC)",
                        "due_date": NOW_MS,
                        "due_window_start": NOW_MS - (1 * DAY_MS),
                        "due_window_end": NOW_MS + (1 * DAY_MS),
                        "status": "due",
                    }
                ]
            },
            {
                "id": "mem_sita_devi_02",  # Elderly Mother in law
                "name": "Sita Devi",
                "sex": "F",
                "dob_approx": NOW_MS - (55 * 365 * DAY_MS),
                "relationship_to_head": "Mother",
                "abha_id": "14-8899-7711-2002",
                "worker_id": ASHA_SUNITA,
                "lifecycle_status": "active",
            }
        ]
    },

    # ── HOUSEHOLD 3: Ramprasad Verma Family (Senior Citizen NCD Hypertension/Diabetes) ──
    {
        "household": {
            "id": "hh_verma_03",
            "village": "Rampur",
            "hamlet": "Ward 3 (Basti)",
            "head_name": "Ramprasad Verma",
            "contact_phone": "9822334455",
            "social_category": "General",
            "is_bpl": False,
            "worker_id": ASHA_SUNITA,
            "landmark_notes": "Behind Community Hall",
            "block_code": "BLK_01",
        },
        "members": [
            {
                "id": "mem_ramprasad_03",
                "name": "Ramprasad Verma",
                "sex": "M",
                "dob_approx": NOW_MS - (62 * 365 * DAY_MS),
                "relationship_to_head": "Head",
                "phone": "9822334455",
                "abha_id": "14-3322-1144-5566",
                "worker_id": ASHA_SUNITA,
                "lifecycle_status": "active",
                "encounters": [
                    {
                        "id": "enc_ramprasad_ncd_01",
                        "encounter_type": "cbac_screening",
                        "program_code": "ncd",
                        "encounter_date": NOW_MS - (3 * DAY_MS),
                        "asha_id": "ASHA-001",
                        "status": "completed",
                        "visit_notes": "CBAC Score: 6. Random Blood Sugar 214 mg/dL, BP 160/94 mmHg. Recommended regular medications and diet change.",
                        "worker_id": ASHA_SUNITA,
                        "triage": {
                            "id": "tr_ramprasad_ncd_01",
                            "flag": "YELLOW",
                            "rule_version_id": "v1.0-mohfw",
                            "findings_json": json.dumps([
                                {"finding": "Uncontrolled Hypertension: BP 160/94", "severity": "warning"},
                                {"finding": "Hyperglycemia: RBS 214 mg/dL", "severity": "warning"},
                                {"finding": "CBAC Score 6/10 (High Risk Profile)", "severity": "warning"}
                            ])
                        },
                        "referral": {
                            "id": "ref_ramprasad_01",
                            "triage_flag": "YELLOW",
                            "destination_facility_id": SC_SHAHPUR,
                            "destination_level": "subcentre",
                            "transport_arranged": "Self / Family",
                            "status": "pending",
                            "referral_note_text": "Known hypertensive with uncontrolled blood pressure and elevated capillary blood glucose. Doctor titration of antihypertensives needed."
                        }
                    }
                ],
                "schedules": [
                    {
                        "id": "vs_ramprasad_ncd_mo",
                        "program_code": "ncd",
                        "visit_type": "NCD Monthly Medication Refill & BP Check",
                        "due_date": NOW_MS - (1 * DAY_MS),
                        "due_window_start": NOW_MS - (3 * DAY_MS),
                        "due_window_end": NOW_MS + (2 * DAY_MS),
                        "status": "overdue",
                    }
                ]
            },
            {
                "id": "mem_kamlesh_03",
                "name": "Kamlesh Verma",
                "sex": "F",
                "dob_approx": NOW_MS - (58 * 365 * DAY_MS),
                "relationship_to_head": "Wife",
                "phone": "9822334456",
                "abha_id": "14-3322-1144-5567",
                "worker_id": ASHA_SUNITA,
                "lifecycle_status": "active",
            }
        ]
    },

    # ── HOUSEHOLD 4: Sunil Yadav Family (Toddler Nutrition & Immunization) ──
    {
        "household": {
            "id": "hh_yadav_04",
            "village": "Rampur",
            "hamlet": "Ward 2 (Purwa Tola)",
            "head_name": "Sunil Yadav",
            "contact_phone": "9876543210",
            "social_category": "OBC",
            "is_bpl": True,
            "worker_id": ASHA_SUNITA,
            "landmark_notes": "Opposite Tube-well No. 4",
            "block_code": "BLK_01",
        },
        "members": [
            {
                "id": "mem_sunil_04",
                "name": "Sunil Yadav",
                "sex": "M",
                "dob_approx": NOW_MS - (30 * 365 * DAY_MS),
                "relationship_to_head": "Head",
                "phone": "9876543210",
                "abha_id": "14-7711-2244-9980",
                "worker_id": ASHA_SUNITA,
                "lifecycle_status": "active",
            },
            {
                "id": "mem_meera_04",
                "name": "Meera Yadav",
                "sex": "F",
                "dob_approx": NOW_MS - (26 * 365 * DAY_MS),
                "relationship_to_head": "Wife",
                "phone": "9876543211",
                "abha_id": "14-7711-2244-9981",
                "worker_id": ASHA_SUNITA,
                "lifecycle_status": "active",
            },
            {
                "id": "mem_priya_04",  # Toddler Priya (16 months - Nutrition & Measles-Rubella 1)
                "name": "Priya Yadav",
                "sex": "F",
                "dob_approx": NOW_MS - (16 * 30 * DAY_MS),
                "relationship_to_head": "Daughter",
                "abha_id": "14-7711-2244-9988",
                "rch_id": "RCH-2025-44551",
                "worker_id": ASHA_SUNITA,
                "lifecycle_status": "active",
                "encounters": [
                    {
                        "id": "enc_priya_immu_01",
                        "encounter_type": "immunization_session",
                        "program_code": "immunization",
                        "encounter_date": NOW_MS - (10 * DAY_MS),
                        "asha_id": "ASHA-001",
                        "status": "completed",
                        "visit_notes": "Growth monitoring: MUAC 12.8 cm (Yellow - Moderate Acute Malnutrition risk). Vitamin A dose 2 given.",
                        "worker_id": ASHA_SUNITA,
                        "triage": {
                            "id": "tr_priya_sam_01",
                            "flag": "YELLOW",
                            "rule_version_id": "v1.0-mohfw",
                            "findings_json": json.dumps([
                                {"finding": "MUAC 12.8 cm (MAM Borderline Risk)", "severity": "warning"},
                                {"finding": "Underweight for age (-2SD line)", "severity": "warning"}
                            ])
                        }
                    }
                ],
                "schedules": [
                    {
                        "id": "vs_priya_dpt_booster",
                        "program_code": "immunization",
                        "visit_type": "DPT Booster 1 & MR-2 Due Visit (16-24 Months)",
                        "due_date": NOW_MS + (2 * DAY_MS),
                        "due_window_start": NOW_MS - (3 * DAY_MS),
                        "due_window_end": NOW_MS + (10 * DAY_MS),
                        "status": "due",
                    }
                ]
            }
        ]
    },

    # ── HOUSEHOLD 5: Shanti Devi Family (Presumptive TB Screening - Nikshay) ──
    {
        "household": {
            "id": "hh_shanti_05",
            "village": "Rampur",
            "hamlet": "Ward 3 (Basti)",
            "head_name": "Shanti Devi",
            "contact_phone": "9833445566",
            "social_category": "SC",
            "is_bpl": True,
            "worker_id": ASHA_SUNITA,
            "landmark_notes": "Corner House near Banyan Tree",
            "block_code": "BLK_01",
        },
        "members": [
            {
                "id": "mem_shanti_05",
                "name": "Shanti Devi",
                "sex": "F",
                "dob_approx": NOW_MS - (58 * 365 * DAY_MS),
                "relationship_to_head": "Head",
                "phone": "9833445566",
                "abha_id": "14-6655-4433-2211",
                "worker_id": ASHA_SUNITA,
                "lifecycle_status": "active",
                "encounters": [
                    {
                        "id": "enc_shanti_tb_01",
                        "encounter_type": "tb_screening",
                        "program_code": "tb",
                        "encounter_date": NOW_MS - (2 * DAY_MS),
                        "asha_id": "ASHA-001",
                        "status": "completed",
                        "visit_notes": "Cough for 18 days, evening low-grade fever, weight loss. Sputum sample collected for CBNAAT test at PHC Shahpur.",
                        "worker_id": ASHA_SUNITA,
                        "triage": {
                            "id": "tr_shanti_tb_01",
                            "flag": "YELLOW",
                            "rule_version_id": "v1.0-mohfw",
                            "findings_json": json.dumps([
                                {"finding": "Productive cough > 2 weeks", "severity": "warning"},
                                {"finding": "Low-grade fever with night sweats", "severity": "warning"},
                                {"finding": "Sputum CBNAAT test dispatched", "severity": "info"}
                            ])
                        },
                        "referral": {
                            "id": "ref_shanti_01",
                            "triage_flag": "YELLOW",
                            "destination_facility_id": PHC_SHAHPUR,
                            "destination_level": "PHC",
                            "transport_arranged": "Local Transit",
                            "status": "arrived",
                            "referral_note_text": "Presumptive TB suspect with chronic cough >14 days and unexplained weight loss. Sputum sent for CBNAAT (GeneXpert) testing."
                        }
                    }
                ],
                "schedules": [
                    {
                        "id": "vs_shanti_tb_followup",
                        "program_code": "tb",
                        "visit_type": "Nikshay CBNAAT Sputum Result Follow-up",
                        "due_date": NOW_MS + (3 * DAY_MS),
                        "due_window_start": NOW_MS + (1 * DAY_MS),
                        "due_window_end": NOW_MS + (5 * DAY_MS),
                        "status": "scheduled",
                    }
                ]
            },
            {
                "id": "mem_vinod_05",
                "name": "Vinod Kumar",
                "sex": "M",
                "dob_approx": NOW_MS - (32 * 365 * DAY_MS),
                "relationship_to_head": "Son",
                "phone": "9833445567",
                "abha_id": "14-6655-4433-2212",
                "worker_id": ASHA_SUNITA,
                "lifecycle_status": "active",
            }
        ]
    },

    # ── HOUSEHOLD 6: Manoj Mishra Family (Pregnant Mother ANC 2nd Trimester - ASHA Rekha) ──
    {
        "household": {
            "id": "hh_mishra_06",
            "village": "Shahpur",
            "hamlet": "Shahpur South - Hamlet 3",
            "head_name": "Manoj Mishra",
            "contact_phone": "9844556677",
            "social_category": "General",
            "is_bpl": False,
            "worker_id": ASHA_REKHA,
            "landmark_notes": "Near Shiva Temple",
            "block_code": "BLK_01",
        },
        "members": [
            {
                "id": "mem_manoj_06",
                "name": "Manoj Mishra",
                "sex": "M",
                "dob_approx": NOW_MS - (31 * 365 * DAY_MS),
                "relationship_to_head": "Head",
                "phone": "9844556677",
                "abha_id": "14-1122-3344-5501",
                "worker_id": ASHA_REKHA,
                "lifecycle_status": "active",
            },
            {
                "id": "mem_anjali_06",  # Anjali Mishra (ANC 24 Weeks - Moderate Anemia)
                "name": "Anjali Mishra",
                "sex": "F",
                "dob_approx": NOW_MS - (25 * 365 * DAY_MS),
                "relationship_to_head": "Wife",
                "phone": "9844556678",
                "abha_id": "14-1122-3344-5502",
                "rch_id": "RCH-2026-88192",
                "worker_id": ASHA_REKHA,
                "lifecycle_status": "active",
                "is_pregnant": True,
                "encounters": [
                    {
                        "id": "enc_anjali_anc_02",
                        "encounter_type": "anc_visit",
                        "program_code": "anc",
                        "encounter_date": NOW_MS - (4 * DAY_MS),
                        "asha_id": "ASHA-002",
                        "status": "completed",
                        "visit_notes": "ANC Contact 2: Gestational age 24 weeks. Hb 9.1 g/dL (Moderate Anemia). BP 118/76 normal. FHR 144 bpm. 100 IFA tablets issued.",
                        "worker_id": ASHA_REKHA,
                        "triage": {
                            "id": "tr_anjali_anc_02",
                            "flag": "YELLOW",
                            "rule_version_id": "v1.0-mohfw",
                            "findings_json": json.dumps([
                                {"finding": "Moderate Gestational Anemia: Hb 9.1 g/dL", "severity": "warning"},
                                {"finding": "Fetal Heart Rate 144 bpm (Healthy)", "severity": "normal"}
                            ])
                        }
                    }
                ],
                "schedules": [
                    {
                        "id": "vs_anjali_anc_03",
                        "program_code": "anc",
                        "visit_type": "ANC Contact 3 (28 Weeks Routine Check)",
                        "due_date": NOW_MS + (24 * DAY_MS),
                        "due_window_start": NOW_MS + (20 * DAY_MS),
                        "due_window_end": NOW_MS + (28 * DAY_MS),
                        "status": "scheduled",
                    }
                ]
            },
            {
                "id": "mem_arjun_06",  # Firstborn Child (4 Years)
                "name": "Arjun Mishra",
                "sex": "M",
                "dob_approx": NOW_MS - (4 * 365 * DAY_MS),
                "relationship_to_head": "Son",
                "abha_id": "14-1122-3344-5503",
                "worker_id": ASHA_REKHA,
                "lifecycle_status": "active",
            }
        ]
    },

    # ── HOUSEHOLD 7: Suresh Chauhan Family (Childhood Acute Diarrhea & ORS - ASHA Rekha) ──
    {
        "household": {
            "id": "hh_chauhan_07",
            "village": "Shahpur",
            "hamlet": "Shahpur North",
            "head_name": "Suresh Chauhan",
            "contact_phone": "9855667788",
            "social_category": "SC",
            "is_bpl": True,
            "worker_id": ASHA_REKHA,
            "landmark_notes": "Near Panchayat Bhawan",
            "block_code": "BLK_01",
        },
        "members": [
            {
                "id": "mem_suresh_07",
                "name": "Suresh Chauhan",
                "sex": "M",
                "dob_approx": NOW_MS - (35 * 365 * DAY_MS),
                "relationship_to_head": "Head",
                "phone": "9855667788",
                "abha_id": "14-2233-4455-6601",
                "worker_id": ASHA_REKHA,
                "lifecycle_status": "active",
            },
            {
                "id": "mem_rekha_ch_07",
                "name": "Suman Chauhan",
                "sex": "F",
                "dob_approx": NOW_MS - (30 * 365 * DAY_MS),
                "relationship_to_head": "Wife",
                "phone": "9855667789",
                "abha_id": "14-2233-4455-6602",
                "worker_id": ASHA_REKHA,
                "lifecycle_status": "active",
            },
            {
                "id": "mem_rohit_07",  # Child Rohit (2 years old - Acute Diarrhea with moderate dehydration)
                "name": "Rohit Chauhan",
                "sex": "M",
                "dob_approx": NOW_MS - (24 * 30 * DAY_MS),
                "relationship_to_head": "Son",
                "abha_id": "14-2233-4455-6603",
                "worker_id": ASHA_REKHA,
                "lifecycle_status": "active",
                "encounters": [
                    {
                        "id": "enc_rohit_diarrhea_01",
                        "encounter_type": "childhood_illness",
                        "program_code": "child_health",
                        "encounter_date": NOW_MS - (1 * DAY_MS),
                        "asha_id": "ASHA-002",
                        "status": "completed",
                        "visit_notes": "5 episodes watery diarrhea today, thirsty, skin pinch goes back slowly. Supplied 2 ORS packets + Zinc 20mg daily for 14 days.",
                        "worker_id": ASHA_REKHA,
                        "triage": {
                            "id": "tr_rohit_ors_01",
                            "flag": "YELLOW",
                            "rule_version_id": "v1.0-mohfw",
                            "findings_json": json.dumps([
                                {"finding": "Acute watery diarrhea with Some Dehydration", "severity": "warning"},
                                {"finding": "Started ORS + 14-day Zinc dispersible tablets", "severity": "normal"}
                            ])
                        }
                    }
                ],
                "schedules": [
                    {
                        "id": "vs_rohit_diarrhea_d2",
                        "program_code": "child_health",
                        "visit_type": "Day 2 Diarrhea Reassessment (Hydration check)",
                        "due_date": NOW_MS + (1 * DAY_MS),
                        "due_window_start": NOW_MS,
                        "due_window_end": NOW_MS + (2 * DAY_MS),
                        "status": "due",
                    }
                ]
            }
        ]
    },

    # ── HOUSEHOLD 8: Harish Chandra Family (Dengue Suspect with High Fever - ASHA Rekha) ──
    {
        "household": {
            "id": "hh_chandra_08",
            "village": "Shahpur",
            "hamlet": "Ward 4 (Basti)",
            "head_name": "Harish Chandra",
            "contact_phone": "9866778899",
            "social_category": "OBC",
            "is_bpl": False,
            "worker_id": ASHA_REKHA,
            "landmark_notes": "Near Canal Bridge",
            "block_code": "BLK_01",
        },
        "members": [
            {
                "id": "mem_harish_08",  # Harish (40 yrs - Dengue Warning Signs)
                "name": "Harish Chandra",
                "sex": "M",
                "dob_approx": NOW_MS - (40 * 365 * DAY_MS),
                "relationship_to_head": "Head",
                "phone": "9866778899",
                "abha_id": "14-3344-5566-7701",
                "worker_id": ASHA_REKHA,
                "lifecycle_status": "active",
                "encounters": [
                    {
                        "id": "enc_harish_fever_01",
                        "encounter_type": "fever_survey",
                        "program_code": "vector_borne",
                        "encounter_date": NOW_MS,
                        "asha_id": "ASHA-002",
                        "status": "completed",
                        "visit_notes": "High fever 103.2°F x 4 days, severe retro-orbital headache, abdominal pain, petechial rash on arms. Dengue NS1 positive.",
                        "worker_id": ASHA_REKHA,
                        "triage": {
                            "id": "tr_harish_dengue_01",
                            "flag": "RED",
                            "rule_version_id": "v1.0-mohfw",
                            "findings_json": json.dumps([
                                {"finding": "High continuous fever 103.2°F with severe myalgia", "severity": "danger"},
                                {"finding": "Dengue Warning Sign: Severe persistent abdominal pain", "severity": "danger"},
                                {"finding": "Petechial skin lesions on bilateral arms", "severity": "danger"}
                            ])
                        },
                        "referral": {
                            "id": "ref_harish_01",
                            "triage_flag": "RED",
                            "destination_facility_id": CHC_SHIVPUR,
                            "destination_level": "chc",
                            "transport_arranged": "108 Ambulance",
                            "status": "en_route",
                            "referral_note_text": "Dengue fever with warning signs (persistent abdominal pain, petechiae). Urgent platelet count, hematocrit monitoring, and IV fluids required."
                        }
                    }
                ],
                "schedules": [
                    {
                        "id": "vs_harish_hospital_fup",
                        "program_code": "vector_borne",
                        "visit_type": "Dengue Inpatient Hospital Discharge Follow-up",
                        "due_date": NOW_MS + (5 * DAY_MS),
                        "due_window_start": NOW_MS + (4 * DAY_MS),
                        "due_window_end": NOW_MS + (7 * DAY_MS),
                        "status": "scheduled",
                    }
                ]
            },
            {
                "id": "mem_sunita_chandra_08",
                "name": "Saroj Chandra",
                "sex": "F",
                "dob_approx": NOW_MS - (37 * 365 * DAY_MS),
                "relationship_to_head": "Wife",
                "phone": "9866778890",
                "abha_id": "14-3344-5566-7702",
                "worker_id": ASHA_REKHA,
                "lifecycle_status": "active",
            }
        ]
    },

    # ── HOUSEHOLD 9: Deepak Pandey Family (Adolescent Anemia & IFA - ASHA Anita) ──
    {
        "household": {
            "id": "hh_pandey_09",
            "village": "Rampur",
            "hamlet": "Ward 4 (Basti)",
            "head_name": "Deepak Pandey",
            "contact_phone": "9877889900",
            "social_category": "General",
            "is_bpl": False,
            "worker_id": ASHA_ANITA,
            "landmark_notes": "Opposite Post Office",
            "block_code": "BLK_01",
        },
        "members": [
            {
                "id": "mem_deepak_09",
                "name": "Deepak Pandey",
                "sex": "M",
                "dob_approx": NOW_MS - (45 * 365 * DAY_MS),
                "relationship_to_head": "Head",
                "phone": "9877889900",
                "abha_id": "14-4455-6677-8801",
                "worker_id": ASHA_ANITA,
                "lifecycle_status": "active",
            },
            {
                "id": "mem_geeta_09",
                "name": "Geeta Pandey",
                "sex": "F",
                "dob_approx": NOW_MS - (42 * 365 * DAY_MS),
                "relationship_to_head": "Wife",
                "phone": "9877889901",
                "abha_id": "14-4455-6677-8802",
                "worker_id": ASHA_ANITA,
                "lifecycle_status": "active",
            },
            {
                "id": "mem_sakshi_09",  # Adolescent Girl (15 yrs - WIFS Anemia Screening)
                "name": "Sakshi Pandey",
                "sex": "F",
                "dob_approx": NOW_MS - (15 * 365 * DAY_MS),
                "relationship_to_head": "Daughter",
                "abha_id": "14-4455-6677-8803",
                "worker_id": ASHA_ANITA,
                "lifecycle_status": "active",
                "encounters": [
                    {
                        "id": "enc_sakshi_wifs_01",
                        "encounter_type": "adolescent_health",
                        "program_code": "wifs",
                        "encounter_date": NOW_MS - (6 * DAY_MS),
                        "asha_id": "ASHA-003",
                        "status": "completed",
                        "visit_notes": "WIFS session: Hemoglobin check 10.6 g/dL (Mild Anemia). Distributed blue IFA tablets and dietary counseling on green leafy vegetables.",
                        "worker_id": ASHA_ANITA,
                        "triage": {
                            "id": "tr_sakshi_wifs_01",
                            "flag": "GREEN",
                            "rule_version_id": "v1.0-mohfw",
                            "findings_json": json.dumps([
                                {"finding": "Mild Adolescent Anemia (Hb 10.6 g/dL)", "severity": "info"},
                                {"finding": "Issued 4 weekly blue IFA tablets", "severity": "normal"}
                            ])
                        }
                    }
                ],
                "schedules": [
                    {
                        "id": "vs_sakshi_wifs_m2",
                        "program_code": "wifs",
                        "visit_type": "Monthly Adolescent IFA Compliance Check",
                        "due_date": NOW_MS + (22 * DAY_MS),
                        "due_window_start": NOW_MS + (18 * DAY_MS),
                        "due_window_end": NOW_MS + (25 * DAY_MS),
                        "status": "scheduled",
                    }
                ]
            }
        ]
    },

    # ── HOUSEHOLD 10: Jagdish Prasad Family (Senior Citizen Eye Cataract Screening - ASHA Anita) ──
    {
        "household": {
            "id": "hh_prasad_10",
            "village": "Rampur",
            "hamlet": "Ward 1 (Main Basti)",
            "head_name": "Jagdish Prasad",
            "contact_phone": "9888990011",
            "social_category": "OBC",
            "is_bpl": True,
            "worker_id": ASHA_ANITA,
            "landmark_notes": "Near Old Peepal Tree",
            "block_code": "BLK_01",
        },
        "members": [
            {
                "id": "mem_jagdish_10",  # Elderly Male (68 yrs - Senile Cataract bilateral)
                "name": "Jagdish Prasad",
                "sex": "M",
                "dob_approx": NOW_MS - (68 * 365 * DAY_MS),
                "relationship_to_head": "Head",
                "phone": "9888990011",
                "abha_id": "14-5566-7788-9901",
                "worker_id": ASHA_ANITA,
                "lifecycle_status": "active",
                "encounters": [
                    {
                        "id": "enc_jagdish_eye_01",
                        "encounter_type": "elderly_care",
                        "program_code": "ncd",
                        "encounter_date": NOW_MS - (5 * DAY_MS),
                        "asha_id": "ASHA-003",
                        "status": "completed",
                        "visit_notes": "Progressive painless vision loss in bilateral eyes for 6 months. Cloudy opacity in both lenses. Visual acuity finger counting at 3 meters.",
                        "worker_id": ASHA_ANITA,
                        "triage": {
                            "id": "tr_jagdish_eye_01",
                            "flag": "YELLOW",
                            "rule_version_id": "v1.0-mohfw",
                            "findings_json": json.dumps([
                                {"finding": "Bilateral dense lens opacity (Cataract)", "severity": "warning"},
                                {"finding": "Severely impaired functional vision", "severity": "warning"}
                            ])
                        },
                        "referral": {
                            "id": "ref_jagdish_01",
                            "triage_flag": "YELLOW",
                            "destination_facility_id": HOSP_DISTRICT,
                            "destination_level": "hospital",
                            "transport_arranged": "District Mobile Eye Camp Transit",
                            "status": "pending",
                            "referral_note_text": "Bilateral mature senile cataract with marked reduction in vision. Referred to District Hospital Ophthalmology department for IOL surgery."
                        }
                    }
                ],
                "schedules": [
                    {
                        "id": "vs_jagdish_eye_camp",
                        "program_code": "ncd",
                        "visit_type": "District Eye Camp Free Cataract Surgery Camp",
                        "due_date": NOW_MS + (6 * DAY_MS),
                        "due_window_start": NOW_MS + (4 * DAY_MS),
                        "due_window_end": NOW_MS + (8 * DAY_MS),
                        "status": "due",
                    }
                ]
            },
            {
                "id": "mem_manju_10",
                "name": "Manju Prasad",
                "sex": "F",
                "dob_approx": NOW_MS - (64 * 365 * DAY_MS),
                "relationship_to_head": "Wife",
                "phone": "9888990012",
                "abha_id": "14-5566-7788-9902",
                "worker_id": ASHA_ANITA,
                "lifecycle_status": "active",
            }
        ]
    }
]

async def seed_data():
    async with AsyncSessionLocal() as session:
        print("--- Starting database seeding for 25 real beneficiaries ---")

        # Get current maximum server_seq across tables
        seq_res = await session.execute(text("SELECT COALESCE(MAX(server_seq), 0) FROM clinical_encounters"))
        curr_enc_seq = seq_res.scalar() or 200

        seq_res = await session.execute(text("SELECT COALESCE(MAX(server_seq), 0) FROM visit_schedules"))
        curr_vs_seq = seq_res.scalar() or 300

        curr_hh_seq = 100
        curr_mem_seq = 100
        curr_ref_seq = 100

        total_members_seeded = 0
        total_encounters_seeded = 0
        total_referrals_seeded = 0
        total_schedules_seeded = 0

        for item in SEED_DATA:
            hh = item["household"]
            curr_hh_seq += 1

            # Check if household exists
            hh_check = await session.execute(text("SELECT id FROM households WHERE id = :id"), {"id": hh["id"]})
            if not hh_check.scalar():
                await session.execute(text("""
                    INSERT INTO households (
                        id, village, hamlet, head_name, contact_phone, social_category, 
                        is_bpl, worker_id, landmark_notes, block_code, member_count, 
                        sync_status, created_at, updated_at, server_received_at, server_seq
                    ) VALUES (
                        :id, :village, :hamlet, :head_name, :contact_phone, :social_category,
                        :is_bpl, :worker_id, :landmark_notes, :block_code, :member_count,
                        'synced', :created_at, :updated_at, :server_received_at, :server_seq
                    )
                """), {
                    "id": hh["id"],
                    "village": hh["village"],
                    "hamlet": hh["hamlet"],
                    "head_name": hh["head_name"],
                    "contact_phone": hh["contact_phone"],
                    "social_category": hh["social_category"],
                    "is_bpl": hh["is_bpl"],
                    "worker_id": hh["worker_id"],
                    "landmark_notes": hh["landmark_notes"],
                    "block_code": hh["block_code"],
                    "member_count": len(item["members"]),
                    "created_at": NOW_MS - (30 * DAY_MS),
                    "updated_at": NOW_MS,
                    "server_received_at": NOW_DT,
                    "server_seq": curr_hh_seq,
                })
            else:
                # Update member count
                await session.execute(text("""
                    UPDATE households 
                    SET member_count = :cnt, updated_at = :up 
                    WHERE id = :id
                """), {"cnt": len(item["members"]), "up": NOW_MS, "id": hh["id"]})

            # Process Members
            for mem in item["members"]:
                curr_mem_seq += 1
                total_members_seeded += 1

                # Check if member exists
                m_check = await session.execute(text("SELECT id FROM members WHERE id = :id"), {"id": mem["id"]})
                if not m_check.scalar():
                    await session.execute(text("""
                        INSERT INTO members (
                            id, household_id, name, sex, dob_approx, relationship_to_head,
                            phone, abha_id, rch_id, worker_id, lifecycle_status, consent_status,
                            sync_status, created_at, updated_at, server_received_at, server_seq, block_code
                        ) VALUES (
                            :id, :household_id, :name, :sex, :dob_approx, :relationship_to_head,
                            :phone, :abha_id, :rch_id, :worker_id, :lifecycle_status, 'given',
                            'synced', :created_at, :updated_at, :server_received_at, :server_seq, 'BLK_01'
                        )
                    """), {
                        "id": mem["id"],
                        "household_id": hh["id"],
                        "name": mem["name"],
                        "sex": mem["sex"],
                        "dob_approx": mem["dob_approx"],
                        "relationship_to_head": mem["relationship_to_head"],
                        "phone": mem.get("phone"),
                        "abha_id": mem.get("abha_id"),
                        "rch_id": mem.get("rch_id"),
                        "worker_id": mem["worker_id"],
                        "lifecycle_status": mem.get("lifecycle_status", "active"),
                        "created_at": NOW_MS - (20 * DAY_MS),
                        "updated_at": NOW_MS,
                        "server_received_at": NOW_DT,
                        "server_seq": curr_mem_seq,
                    })

                # Consent Record
                c_check = await session.execute(text("SELECT id FROM consent_records WHERE member_id = :mid"), {"mid": mem["id"]})
                if not c_check.scalar():
                    c_id = f"consent_{mem['id']}"
                    await session.execute(text("""
                        INSERT INTO consent_records (
                            id, member_id, consent_version, consented_at, asha_id, witness_type,
                            sync_status, server_received_at, block_code
                        ) VALUES (
                            :id, :member_id, 'v1.0', :consented_at, :asha_id, 'TAPACK',
                            'synced', :server_received_at, 'BLK_01'
                        )
                    """), {
                        "id": c_id,
                        "member_id": mem["id"],
                        "consented_at": NOW_MS - (20 * DAY_MS),
                        "asha_id": "ASHA-001" if mem["worker_id"] == ASHA_SUNITA else ("ASHA-002" if mem["worker_id"] == ASHA_REKHA else "ASHA-003"),
                        "server_received_at": NOW_DT,
                    })

                # Clinical Encounters
                for enc in mem.get("encounters", []):
                    curr_enc_seq += 1
                    total_encounters_seeded += 1
                    enc_check = await session.execute(text("SELECT id FROM clinical_encounters WHERE id = :id"), {"id": enc["id"]})
                    if not enc_check.scalar():
                        await session.execute(text("""
                            INSERT INTO clinical_encounters (
                                id, member_id, encounter_type, program_code, encounter_date,
                                asha_id, status, visit_notes, worker_id, sync_status,
                                created_at, updated_at, server_received_at, server_seq, block_code
                            ) VALUES (
                                :id, :member_id, :encounter_type, :program_code, :encounter_date,
                                :asha_id, :status, :visit_notes, :worker_id, 'synced',
                                :created_at, :updated_at, :server_received_at, :server_seq, 'BLK_01'
                            )
                        """), {
                            "id": enc["id"],
                            "member_id": mem["id"],
                            "encounter_type": enc["encounter_type"],
                            "program_code": enc["program_code"],
                            "encounter_date": enc["encounter_date"],
                            "asha_id": enc["asha_id"],
                            "status": enc["status"],
                            "visit_notes": enc["visit_notes"],
                            "worker_id": enc["worker_id"],
                            "created_at": enc["encounter_date"],
                            "updated_at": enc["encounter_date"],
                            "server_received_at": NOW_DT,
                            "server_seq": curr_enc_seq,
                        })

                    # Triage Result
                    if "triage" in enc:
                        tr = enc["triage"]
                        tr_check = await session.execute(text("SELECT id FROM triage_results WHERE id = :id"), {"id": tr["id"]})
                        if not tr_check.scalar():
                            await session.execute(text("""
                                INSERT INTO triage_results (
                                    id, encounter_id, flag, rule_version_id, findings_json,
                                    evaluated_at, server_received_at
                                ) VALUES (
                                    :id, :encounter_id, :flag, :rule_version_id, :findings_json,
                                    :evaluated_at, :server_received_at
                                )
                            """), {
                                "id": tr["id"],
                                "encounter_id": enc["id"],
                                "flag": tr["flag"],
                                "rule_version_id": tr["rule_version_id"],
                                "findings_json": tr["findings_json"],
                                "evaluated_at": enc["encounter_date"],
                                "server_received_at": NOW_DT,
                            })

                    # Referral Record
                    if "referral" in enc:
                        ref = enc["referral"]
                        curr_ref_seq += 1
                        total_referrals_seeded += 1
                        ref_check = await session.execute(text("SELECT id FROM referral_records WHERE id = :id"), {"id": ref["id"]})
                        if not ref_check.scalar():
                            await session.execute(text("""
                                INSERT INTO referral_records (
                                    id, encounter_id, member_id, triage_flag, destination_facility_id,
                                    destination_level, transport_arranged, status, referral_note_text,
                                    sync_status, created_at, server_received_at, server_seq, block_code
                                ) VALUES (
                                    :id, :encounter_id, :member_id, :triage_flag, :destination_facility_id,
                                    :destination_level, :transport_arranged, :status, :referral_note_text,
                                    'synced', :created_at, :server_received_at, :server_seq, 'BLK_01'
                                )
                            """), {
                                "id": ref["id"],
                                "encounter_id": enc["id"],
                                "member_id": mem["id"],
                                "triage_flag": ref["triage_flag"],
                                "destination_facility_id": ref["destination_facility_id"],
                                "destination_level": ref["destination_level"],
                                "transport_arranged": ref["transport_arranged"],
                                "status": ref["status"],
                                "referral_note_text": ref["referral_note_text"],
                                "created_at": enc["encounter_date"],
                                "server_received_at": NOW_DT,
                                "server_seq": curr_ref_seq,
                            })

                # Visit Schedules
                for vs in mem.get("schedules", []):
                    curr_vs_seq += 1
                    total_schedules_seeded += 1
                    vs_check = await session.execute(text("SELECT id FROM visit_schedules WHERE id = :id"), {"id": vs["id"]})
                    if not vs_check.scalar():
                        await session.execute(text("""
                            INSERT INTO visit_schedules (
                                id, member_id, program_code, visit_type, due_date,
                                due_window_start, due_window_end, status, rescheduled_count,
                                created_at, server_received_at, server_seq, block_code
                            ) VALUES (
                                :id, :member_id, :program_code, :visit_type, :due_date,
                                :due_window_start, :due_window_end, :status, 0,
                                :created_at, :server_received_at, :server_seq, 'BLK_01'
                            )
                        """), {
                            "id": vs["id"],
                            "member_id": mem["id"],
                            "program_code": vs["program_code"],
                            "visit_type": vs["visit_type"],
                            "due_date": vs["due_date"],
                            "due_window_start": vs["due_window_start"],
                            "due_window_end": vs["due_window_end"],
                            "status": vs["status"],
                            "created_at": NOW_MS - (5 * DAY_MS),
                            "server_received_at": NOW_DT,
                            "server_seq": curr_vs_seq,
                        })

        await session.commit()
        print(f"SUCCESS: Seeded {total_members_seeded} beneficiary members across 10 households!")
        print(f"Associated items seeded: {total_encounters_seeded} encounters, {total_referrals_seeded} referrals, {total_schedules_seeded} visit schedules.")

        # Verification check
        mem_cnt = (await session.execute(text("SELECT count(*) FROM members"))).scalar()
        hh_cnt = (await session.execute(text("SELECT count(*) FROM households"))).scalar()
        enc_cnt = (await session.execute(text("SELECT count(*) FROM clinical_encounters"))).scalar()
        ref_cnt = (await session.execute(text("SELECT count(*) FROM referral_records"))).scalar()
        vs_cnt = (await session.execute(text("SELECT count(*) FROM visit_schedules"))).scalar()
        print(f"CURRENT DB TOTALS -> Members: {mem_cnt}, Households: {hh_cnt}, Encounters: {enc_cnt}, Referrals: {ref_cnt}, Schedules: {vs_cnt}")

if __name__ == "__main__":
    asyncio.run(seed_data())
