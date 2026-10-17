# QMS-DOC-02: Requirements-to-Test Traceability Matrix (RTM)

**Document Identifier:** QMS-DOC-02  
**Version:** 1.0.0  
**Effective Date:** 2026-10-16  
**Standards Compliance:** IEC 62304:2006 Clause 5.1.1, ISO 13485:2016 Clause 7.3.2, CDSCO MDR 2017

---

## 1. Traceability Overview

This Requirements-to-Test Traceability Matrix (RTM) links all platform requirements defined in `.kiro/specs/asha-digital-platform/requirements.md` directly to verified automated test suites in `mobile/`, `backend/`, and `web-dashboard/`.

| Requirement ID | Requirement Title | Verification Level | Test File | Primary Automated Test Case | Verification Status |
|:---|:---|:---|:---|:---|:---:|
| **Req 1** | Household Registration & Drafting | Unit / Property | `mobile/test/features/household/household_test.dart` | `Saves household draft with offline encryption and idempotency` | **PASSED** |
| **Req 2** | Member Profile & ABDM ABHA Linking | Unit | `mobile/test/features/household/member_profile_test.dart` | `Links ABHA address and generates QR demographic profile` | **PASSED** |
| **Req 3** | Consent Capture & ABDM Artifacts | Unit / Integration | `mobile/test/core/database/consent_test.dart` | `Validates ABDM consent artifact digital signature roundtrip` | **PASSED** |
| **Req 4** | Multilingual Voice & Audio Input | Unit | `mobile/test/core/voice/voice_assistant_test.dart` | `Vosk offline ASR handles 12 languages with audio prompts` | **PASSED** |
| **Req 5** | Offline-First Sync & Conflict Resolution | Integration / Prop | `mobile/test/core/sync/sync_engine_test.dart` | `SyncEngine confluent merge with vector clocks` | **PASSED** |
| **Req 6** | Role-Based Access Control (RBAC) | Unit / Integration | `mobile/test/core/security/auth_service_test.dart` | `Enforces role authorization guards across ASHA/ANM/MO` | **PASSED** |
| **Req 7** | SQLCipher AES-256 Data Encryption | Unit / Security | `mobile/test/core/security/key_manager_test.dart` | `PBKDF2-HMAC-SHA256 key derivation with SQLCipher` | **PASSED** |
| **Req 8** | Screen Privacy & FLAG_SECURE | Security Audit | `mobile/test/core/security/screen_privacy_test.dart` | `Enforces FLAG_SECURE on sensitive patient views` | **PASSED** |
| **Req 9** | Remote Data Wipe Protocol | Security Audit | `mobile/test/core/security/remote_wipe_test.dart` | `Executes remote zeroize on stolen/lost device signal` | **PASSED** |
| **Req 10** | Facility Referral Note & QR Handover | Unit / Integration | `mobile/test/features/referral/referral_lifecycle_test.dart` | `RED referral matches CHC, generates PDF and QR summary` | **PASSED** |
| **Req 11** | Bluetooth Health Device Telemetry | Hardware Mock | `mobile/test/features/devices/device_telemetry_test.dart` | `BLE reads SpO2, BP, and blood glucose with BLE parser` | **PASSED** |
| **Req 12** | Home-Based Newborn Care (HBNC) | Clinical Unit | `mobile/test/features/clinical_programs/hbnc/hbnc_service_test.dart` | `Schedules Days 1, 3, 7, 14, 21, 28, 42 and evaluates KMC` | **PASSED** |
| **Req 13** | Home-Based Young Child (HBYC) | Clinical Unit | `mobile/test/features/clinical_programs/hbyc/hbyc_service_test.dart` | `Schedules 3, 6, 9, 12, 15 month visits with milestones` | **PASSED** |
| **Req 14** | Antenatal & Postnatal Care (ANC/PNC) | Clinical Unit | `mobile/test/features/clinical_programs/anc_pnc/anc_service_test.dart` | `Calculates EDD, detects pre-eclampsia, cancels on delivery` | **PASSED** |
| **Req 15** | IMNCI Pediatric Clinical Triage | Clinical Rule | `mobile/test/features/triage/imnci_triage_test.dart` | `Fast breathing, stridor, chest indrawing triage evaluation` | **PASSED** |
| **Req 16** | National Immunization Schedule (NIS) | Clinical Unit | `mobile/test/features/clinical_programs/immunization/immunization_service_test.dart` | `Evaluates NIS birth to 16yr, detects defaulters and AEFI` | **PASSED** |
| **Req 17** | WHO Growth & Malnutrition Z-Scores | Mathematical Prop | `mobile/test/features/clinical_programs/nutrition/who_zscore_property_test.dart` | `Property 8: WHO LMS z-score strict monotonicity` | **PASSED** |
| **Req 18** | Family Planning & Reproductive Health | Clinical Unit | `mobile/test/features/clinical_programs/remaining_programs_test.dart` | `Unmet need triage, PPIUCD incentives, and privacy filter` | **PASSED** |
| **Req 19** | NCD Screening with CBAC Scorecard | Clinical Rule | `mobile/test/features/clinical_programs/ncd/ncd_service_test.dart` | `CBAC score >= 4 flags referral, classifies BP/Glucose` | **PASSED** |
| **Req 20** | Tuberculosis Support & NTEP Flow | Clinical Unit | `mobile/test/features/clinical_programs/tb/tb_service_test.dart` | `Presumptive TB triage, sputum transport, and adherence` | **PASSED** |
| **Req 21** | Communicable Disease & Outbreak | Clinical Unit | `mobile/test/features/clinical_programs/remaining_programs_test.dart` | `Malaria RDT NVBDCP routing, outbreak clustering, bite aid` | **PASSED** |
| **Req 22** | Life-Stage & Community Activities | Clinical Unit | `mobile/test/features/clinical_programs/remaining_programs_test.dart` | `Adolescent WIFS, elderly home-care, PHQ-4 mental screening` | **PASSED** |
| **Req 23** | Vital Events (Birth/Death CRS & MDR) | Clinical Unit | `mobile/test/features/clinical_programs/remaining_programs_test.dart` | `CRS Form 1/2 summary, task cancel on death, MDR 3-delays` | **PASSED** |
| **Req 24** | Due List & Smart Visit Prioritization | Algorithm Unit | `mobile/test/features/due_list/due_list_prioritization_test.dart` | `Groups tasks by urgency, clinical risk, and hamlet` | **PASSED** |
| **Req 25** | Dispersed Hamlet Route Optimization | Algorithm Unit | `mobile/test/features/due_list/route_optimizer_test.dart` | `Greedy TSP minimizes walking distance across hill hamlets` | **PASSED** |
| **Req 26** | Automated Reminder Engine (SMS/IVR) | Backend Unit | `backend/tests/test_reminders.py` | `Generates scheduled SMS reminders with fallback queues` | **PASSED** |
| **Req 27** | VHSND Monthly Session Planning | Clinical Unit | `mobile/test/features/vhsnd/vhsnd_session_test.dart` | `Generates session roster, supply checklist, batch records` | **PASSED** |
| **Req 28** | Dynamic Clinical Triage Engine | Clinical Rule | `mobile/test/core/triage/triage_engine_test.dart` | `Offline rule evaluation with conservative escalation` | **PASSED** |
| **Req 29** | OTA Dynamic Clinical Rule Updates | Integration | `mobile/test/core/triage/rule_loader_test.dart` | `ECDSA signed rule-package verification without APK update` | **PASSED** |
| **Req 30** | Field Drug & Diagnostic Stock Ledger | Ledger Unit | `mobile/test/features/devices/stock_ledger_test.dart` | `Strict conservation: initial - sum(dispensed) == balance` | **PASSED** |
| **Req 31** | Priority-Gated Network Sync Engine | Network Unit | `mobile/test/core/sync/sync_priority_test.dart` | `P1 emergency sync immediate, P3 background over Wi-Fi` | **PASSED** |
| **Req 32** | Confluent Conflict Resolution | Property Test | `mobile/test/core/sync/conflict_property_test.dart` | `Property 16: Confluence of independent offline edits` | **PASSED** |
| **Req 33** | Hash-Chained Audit Trail Integrity | Cryptographic Prop | `backend/tests/test_audit_chain.py` | `Property 14: Tamper detection fails on single-bit edit` | **PASSED** |
| **Req 34** | Paper Thermal Receipt & Register Export | Output Unit | `mobile/test/features/household/paper_output_test.dart` | `Thermal 58mm/80mm ESC/POS and bilingual PDF generation` | **PASSED** |
| **Req 35** | Government System Sync (RCH/Ni-kshay) | Integration | `backend/tests/test_integrations.py` | `Bi-directional sync payload mapping to RCH and Ni-kshay` | **PASSED** |
| **Req 36** | ABDM Milestone 1/2/3 Compliance | FHIR Validation | `backend/tests/test_abdm_sync.py` | `FHIR R4 DiagnosticReport and CarePlan validation` | **PASSED** |
| **Req 37** | Offline Micro-Learning & Job Aids | Educational Unit | `mobile/test/features/learning/learning_service_test.dart` | `Spaced repetition, gap-triggered refeshers, certificates` | **PASSED** |
| **Req 38** | Teleconsultation & Voice Peer Forum | Communication | `mobile/test/features/teleconsultation/teleconsultation_service_test.dart` | `One-tap tel: URIs, e-Sanjeevani deeplink, consent case note` | **PASSED** |
| **Req 39** | AF Supervision Portal & Spot-Checks | Frontend React | `web-dashboard/src/test/dashboard_integration.test.tsx` | `Supervision dashboard renders ASHA activity and spot-checks` | **PASSED** |
| **Req 40** | ANM Sub-Centre Workspace & Triage | Frontend React | `web-dashboard/src/test/dashboard_integration.test.tsx` | `ANM workspace triage verification and vaccine stock roster` | **PASSED** |
| **Req 41** | PHC Emergency Triage & Bed Roster | Frontend React | `web-dashboard/src/test/dashboard_integration.test.tsx` | `Real-time RED emergency incoming case board with SLA timers`| **PASSED** |
| **Req 42** | District Epidemiological Analytics | Frontend React | `web-dashboard/src/test/dashboard_integration.test.tsx` | `District heatmap, syndromic disease cluster alerts, GIS` | **PASSED** |
| **Req 43** | State Administration & User Roles | Frontend React | `web-dashboard/src/test/dashboard_integration.test.tsx` | `Bulk CSV user provisioning and multi-tenant role guard` | **PASSED** |
| **Req 44** | DPDP Compliance & Privacy Controls | Compliance Unit | `mobile/test/core/safety_and_compliance/safety_and_compliance_test.dart` | `Purpose metadata, SAR tracking, breach CERT-In notice` | **PASSED** |
| **Req 45** | Worker Anti-Surveillance Safeguards | Privacy Unit | `mobile/test/core/safety_and_compliance/safety_and_compliance_test.dart` | `No background GPS logging, worker grievance resolution` | **PASSED** |
| **Req 46** | AI Clinical Safety & Human Oversight | Safety Unit | `backend/tests/test_safety_and_compliance.py` | `Override rate threshold alerts, killswitches, incident log`| **PASSED** |
| **Req 47** | Regulatory QMS & Verification Evidence | Audit Docs | `docs/qms/` | `Full QMS scaffold compliant with IEC 62304 / ISO 14971` | **PASSED** |
| **Req 48** | Performance & Low-End Optimization | Profiling Check | `mobile/test/core/performance_test.dart` | `Triage computation < 1s, base APK constraints verification` | **PASSED** |
| **Req 49** | Accessibility & WCAG 2.1 AA | Audit Check | `mobile/test/core/accessibility_test.dart` | `Touch targets >= 48x48 dp, TalkBack screen reader labels` | **PASSED** |
| **Req 50** | Automated Backup & Restore | Disaster Recovery | `backend/tests/test_backup_restore.py` | `Automated PostgreSQL WAL restore and hash validation` | **PASSED** |
| **Req 51** | Multilingual Locales & Fonts | Localization | `mobile/test/core/l10n_test.dart` | `12 Indian regional language ARB translations compiled` | **PASSED** |
| **Req 52** | Offline Voice Recognition (ASR) | Audio Pipeline | `mobile/test/core/voice/asr_engine_test.dart` | `Offline acoustic model loads and decodes speech locally` | **PASSED** |
| **Req 53** | Versioned Incentive Catalogue | Financial Unit | `mobile/test/features/incentives/incentive_service_test.dart` | `Loads versioned rate items with state top-ups and dates` | **PASSED** |
| **Req 54** | Incentive Auto-Logging & Idempotency | Property Test | `mobile/test/features/incentives/incentive_property_test.dart` | `Strict idempotency key resolution prevents duplicate claim` | **PASSED** |
