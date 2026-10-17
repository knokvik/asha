# QMS-DOC-01: Intended Use Statement & CDSCO SaMD Classification Analysis

**Document Identifier:** QMS-DOC-01  
**Version:** 1.0.0  
**Effective Date:** 2026-10-16  
**Standards Compliance:** CDSCO Medical Device Rules (MDR) 2017, IMDRF SaMD N12, IEC 62304:2006/AMD 1:2015, ISO 14971:2019

---

## 1. Intended Use Statement

The **ASHA Digital Platform (Asha-Setu)** is an offline-first mobile medical application and connected health system intended to support Accredited Social Health Activists (ASHAs), Auxiliary Nurse Midwives (ANMs), and primary care clinicians in delivering community health services in India.

### 1.1 Specific Clinical Indications
- **Maternal Health:** Antenatal care (ANC) scheduling, identification of high-risk pregnancy danger signs (pre-eclampsia, gestational diabetes, severe anaemia, antepartum haemorrhage), and delivery outcome tracking.
- **Newborn & Child Health:** Home-Based Newborn Care (HBNC) and Home-Based Young Child (HBYC) visit checklists, integrated management of neonatal and childhood illness (IMNCI) syndromic triage for pneumonia, diarrhoea with dehydration, sepsis, and hypothermia.
- **Immunization:** Automated National Immunization Schedule (NIS) tracking, defaulter identification, and adverse event following immunization (AEFI) syndromic reporting.
- **Nutrition:** WHO Child Growth Standard z-score evaluation (Weight-for-Age, Height-for-Age, Weight-for-Height) for active detection of Severe Acute Malnutrition (SAM) and Moderate Acute Malnutrition (MAM).
- **Non-Communicable Diseases (NCD):** Community-Based Assessment Checklist (CBAC) scoring for adults aged 30+, hypertension and diabetes screening, and suggestive cancer warning sign referral.
- **Tuberculosis & Communicable Diseases:** Presumptive TB screening per NTEP guidelines, sputum transport tracking, treatment adherence verification, Malaria rapid diagnostic test (RDT) species-specific routing, and syndromic outbreak cluster alerts.

### 1.2 Intended User Population
- Primary Users: Accredited Social Health Activists (ASHAs) with high school education and foundational community health training.
- Secondary Users: Auxiliary Nurse Midwives (ANMs), Community Health Officers (CHOs), Medical Officers (MOs), and ASHA Facilitators (AFs).

### 1.3 Operating Environment
- Handheld Android devices (Android 9.0+, minimum 2 GB RAM, offline environments with intermittent 2G/3G/4G connectivity).
- Ambient conditions: Rural Indian village field visits, high temperatures, humidity, low lighting, and sunlight visibility constraints.

### 1.4 Contraindications & Operating Limitations
- **Not for Autonomous Diagnosis:** The software is strictly a **Clinical Decision Support System (CDSS)** and does **not** provide autonomous diagnostic determinations or replace qualified clinical evaluation by a registered medical practitioner.
- **No Direct Patient Intervention:** The application does not directly control infusion pumps, surgical devices, or active medical hardware.
- **Human-in-the-Loop Mandate:** Every triage suggestion must be confirmed by the ASHA worker before being committed to the permanent medical record.

---

## 2. CDSCO SaMD Classification Analysis

Under the **Medical Devices Rules (MDR) 2017** administered by the Central Drugs Standard Control Organisation (CDSCO), software with a medical purpose is regulated as **Software as a Medical Device (SaMD)**.

### 2.1 IMDRF Categorization Framework
Per the International Medical Device Regulators Forum (IMDRF/SaMD WG/N10FINAL:2013) framework endorsed by CDSCO:

1. **State of the Healthcare Situation:**
   - *Critical:* Life-threatening or irreversible deterioration (e.g. severe postpartum hemorrhage, acute neonatal sepsis).
   - *Serious:* Potential for major deterioration without intervention (e.g. pre-eclampsia, falciparum malaria, SAM with complications).
   - *Non-serious:* Mild, reversible conditions (e.g. mild dehydration, routine immunization tracking).
   - *Assessment:* The software addresses situations ranging from Non-serious to Critical.

2. **Significance of Information Provided:**
   - *Treat or Diagnose:* The software does **not** make direct diagnostic calls or deliver automated therapy.
   - *Drive Clinical Management:* The software generates priority triage flags (RED, YELLOW, GREEN) and immediate emergency referral recommendations that directly inform where and how quickly care is sought.
   - *Inform Clinical Management:* Routine visit scheduling, educational job aids, and lifestyle counselling.
   - *Assessment:* The primary clinical functionality falls under **Drive Clinical Management**.

### 2.2 Classification Determination
- **CDSCO Risk Class:** **Class B (Low-Moderate Risk)**
  - *Rationale:* While some evaluated conditions are serious/critical (e.g. severe pre-eclampsia), the software operates exclusively in a **decision support** capacity with human confirmation required. The software does not control any active therapeutic hardware or perform autonomous medical diagnosis.
  - *Reference:* CDSCO Guidance Document on Classification of Medical Devices and In Vitro Diagnostic Medical Devices (Rule 4, Chapter II, MDR 2017).

### 2.3 IEC 62304 Software Safety Classification
- **IEC 62304 Safety Class:** **Class B**
  - *Definition:* Non-serious injury is possible before risk control measures are applied, but death or serious injury is mitigated through human clinical review and conservative triage design (fail-safe escalation to higher severity).
  - *Lifecycle Requirements:* Architectural design, unit testing, software integration testing, software verification, and formal change control.
