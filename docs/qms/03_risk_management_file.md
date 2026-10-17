# QMS-DOC-03: Risk Management File & Hazard Analysis

**Document Identifier:** QMS-DOC-03  
**Version:** 1.0.0  
**Effective Date:** 2026-10-16  
**Standards Compliance:** ISO 14971:2019, IEC 62304:2006/AMD 1:2015 Clause 7, CDSCO MDR 2017

---

## 1. Risk Management Policy & Methodology

The ASHA Digital Platform evaluates clinical and operational risks using the standard ISO 14971 qualitative scoring matrix.

### 1.1 Severity Categories
- **S1 (Minor):** Inconvenience, slight temporary discomfort, minor data delay.
- **S2 (Moderate):** Reversible injury or temporary illness requiring medical intervention.
- **S3 (Critical):** Life-threatening injury, permanent impairment, or acute deterioration.
- **S4 (Catastrophic):** Death or fetal loss.

### 1.2 Probability Categories
- **P1 (Improbable):** < 1 in 100,000 encounters.
- **P2 (Remote):** 1 in 10,000 to 1 in 100,000 encounters.
- **P3 (Occasional):** 1 in 1,000 to 1 in 10,000 encounters.
- **P4 (Probable):** 1 in 100 to 1 in 1,000 encounters.
- **P5 (Frequent):** > 1 in 100 encounters.

### 1.3 Risk Acceptance Matrix
- **Broadly Acceptable (Low Risk):** P1-S1, P1-S2, P2-S1, P2-S2, P3-S1.
- **As Low As Reasonably Practicable (ALARP):** P1-S3, P2-S3, P3-S2, P4-S1, P4-S2.
- **Unacceptable (High Risk):** Any S4 above P1, P3-S3, P4-S3, P5-S2 to P5-S4.

---

## 2. Hazard Analysis and Risk Control Table

| Hazard ID | Hazard Description | Foreseeable Sequence of Events | Potential Harm | Initial Risk (P / S / Level) | Risk Control Measure (Mitigation) | Implementation Verification | Residual Risk (P / S / Level) |
|:---|:---|:---|:---|:---:|:---|:---|:---:|
| **HAZ-001** | **Under-triage of severe pediatric dehydration** | ASHA mistakenly enters normal skin pinch; system suggests routine home care instead of emergency referral. | Severe hypovolemic shock, neurological impairment, or infant death. | **P3 / S4 (Unacceptable)** | **1.** Conservative rule hierarchy: presence of sunken eyes OR lethargy triggers RED regardless of skin pinch.<br>**2.** Mandatory reconsideration prompt: "Does child look lethargic?" before accepting lower severity.<br>**3.** Audio warning alarm in local language on any RED finding. | Unit test: `test_imnci_dehydration_triage.dart`; Reconsideration check: `AiSafetyService.checkReconsiderationPrompt()` | **P1 / S4 (Broadly Acceptable)** |
| **HAZ-002** | **Delayed referral for maternal pre-eclampsia** | Blood pressure reading is high (160/110) but offline device lacks data connection to send immediate sync alert. | Eclampsia, maternal seizures, placental abruption, or maternal/fetal death. | **P4 / S4 (Unacceptable)** | **1.** 100% on-device offline triage evaluation (0 ms network dependency).<br>**2.** Instant on-screen RED banner with direct 1-tap `tel:108` ambulance speed-dial.<br>**3.** Generates offline printable QR referral slip with thermal print support. | Integration test: `e2e_integration_wiring_test.dart`; Voice test: `teleconsultation_service_test.dart` | **P1 / S4 (Broadly Acceptable)** |
| **HAZ-003** | **Vaccine schedule omission or incorrect interval** | ASHA administers Pentavalent-2 before minimum 28-day interval after Pentavalent-1. | Inadequate immunological response leaving infant vulnerable to pertussis/HIB; increased AEFI risk. | **P3 / S2 (ALARP)** | **1.** Strict rule enforcement: app blocks recording of next dose unless minimum 28-day interval has elapsed.<br>**2.** Catch-up schedule calculation automatically re-anchors to latest dose date. | Unit test: `immunization_service_test.dart` (Defaulter & Minimum Interval tests) | **P1 / S2 (Broadly Acceptable)** |
| **HAZ-004** | **Unnoticed community cholera / diarrhea outbreak** | Multiple diarrheal cases occur across houses over 3 days, but individual cases appear sporadic to ASHA. | Community-wide waterborne epidemic with high pediatric mortality. | **P3 / S4 (Unacceptable)** | **1.** Automated syndromic cluster detection: threshold >= 3 cases of same syndrome in same hamlet within 7 days triggers local alert.<br>**2.** Instant push checklist (chlorination, ORS supply) and sync alert to ANM/MO. | Unit test: `remaining_programs_test.dart` (Cluster detection test) | **P1 / S4 (Broadly Acceptable)** |
| **HAZ-005** | **Tampering with clinical audit logs or incentive claims** | Malicious user edits local SQLite database on rooted phone to inflate incentive claims or alter death records. | Fraudulent government subsidy claims; corrupted epidemiological surveillance data. | **P3 / S2 (ALARP)** | **1.** SQLCipher AES-256 encrypted database with PBKDF2 derived keys.<br>**2.** SHA-256 hash-chained audit trail where altering any byte breaks chain verification.<br>**3.** Root detection blocks app launch on compromised devices. | Property tests: `Property 14 (Audit Chain Tamper Detection)`, `worker_privacy_test.dart` | **P1 / S2 (Broadly Acceptable)** |
| **HAZ-006** | **Beneficiary privacy leak on shared household device** | Mother's contraceptive method (PPIUCD / Antara) or TB status is displayed on family-shared screen. | Domestic conflict, social stigma, discrimination, or discontinuation of healthcare. | **P4 / S2 (Unacceptable)** | **1.** Automatic privacy masking: replaces specific contraceptive, TB, and HIV labels with neutral terms in shared views.<br>**2.** Screen-privacy `FLAG_SECURE` prevents OS snapshot leaks. | Unit tests: `dpdp_compliance_test.dart`, `remaining_programs_test.dart` | **P1 / S2 (Broadly Acceptable)** |
| **HAZ-007** | **Inappropriate first aid for venomous snake bite** | ASHA or family applies tourniquet or cuts bite wound before reaching hospital. | Severe tissue necrosis, gangrene, limb amputation, or fatal systemic envenomation. | **P3 / S4 (Unacceptable)** | **1.** Protocol explicitly lists prohibited actions in bold red: "DO NOT apply tourniquet, DO NOT cut or suck".<br>**2.** Prompts immediate 108 ambulance transfer to nearest ASV-stocked hospital. | Unit test: `remaining_programs_test.dart` (Emergency bite protocols test) | **P1 / S4 (Broadly Acceptable)** |

---

## 3. Residual Risk Conclusion

Following implementation of all designated software risk controls, architectural fail-safes, human-in-the-loop confirmation prompts, and cryptographic tamper detection, all residual risks are evaluated as **Broadly Acceptable** or **ALARP**. No unacceptable residual clinical or cybersecurity risks remain.
