# Requirements Document

## Introduction

This document specifies an offline-first digital platform for ASHA (Accredited Social Health Activist) workers in India and the health-system staff who support them. It starts from the hackathon core (voice entry in local languages, on-device red/yellow/green triage, referral notes, sync to a PHC dashboard) and extends it across the ASHA's whole working life: household and beneficiary records, maternal, newborn, child and NCD care, TB and communicable disease, visit scheduling, device integration, training, supervision, interoperability with government systems, and incentive tracking.

Design principles drawn from the research:

- **Offline first.** Every field workflow works with zero connectivity. Sync is background and never blocks the user.
- **Decision support, not diagnosis.** ASHAs screen, triage and refer. The system suggests, the ASHA decides.
- **Remove the double burden.** Enter data once, then generate paper-compatible outputs and government-portal exports from it.
- **Low-end, shared phones.** Small footprint, low RAM, low battery use, and shared-device-safe privacy.
- **Voice and icon first.** Designed for modest literacy and regional languages.
- **Worker trust.** No punitive surveillance. Transparent earnings and data use.
- **Configurable by state.** Incentive rates, forms, languages and protocols are configuration, not code.

Items marked **[VALIDATE]** depend on facts that must be confirmed against official NHM/MoHFW/NHSRC documents or field interviews before implementation (exact scoring, schedules, rates, regulatory class).

## Glossary

- **ASHA**: Accredited Social Health Activist, a village-level female community health worker.
- **ASHA Facilitator (AF)**: Supervisor of roughly 10 to 20 ASHAs.
- **ANM**: Auxiliary Nurse Midwife at the sub-centre or HWC.
- **CHO**: Community Health Officer at the Health and Wellness Centre.
- **AWW**: Anganwadi Worker.
- **PHC / CHC**: Primary Health Centre / Community Health Centre.
- **MO**: Medical Officer.
- **BPMU**: Block Program Management Unit.
- **HBNC / HBYC**: Home Based Newborn Care / Home Based Care for Young Child.
- **IMNCI**: Integrated Management of Neonatal and Childhood Illness.
- **CBAC**: Community Based Assessment Checklist for NCD risk.
- **ANC / PNC**: Antenatal / Postnatal Care.
- **VHSND**: Village Health, Sanitation and Nutrition Day.
- **VHSNC**: Village Health, Sanitation and Nutrition Committee.
- **MCP card**: Mother and Child Protection card.
- **ABDM / ABHA**: Ayushman Bharat Digital Mission / Ayushman Bharat Health Account ID.
- **CDSS**: Clinical Decision Support System.
- **SaMD**: Software as a Medical Device.
- **EARS**: Easy Approach to Requirements Syntax (the WHEN/THEN/SHALL format used below).
- **The System**: The ASHA mobile app, the sync backend, and the web dashboards, unless a requirement names a specific component.

---

## Requirements

### Part 1: Platform Foundation

### Requirement 1: Offline-First Local Data Store

**User Story:** As an ASHA working in a hamlet with no network, I want every feature to work without internet, so that I never lose work or wait on a loading spinner.

#### Acceptance Criteria

1. WHEN the device has no connectivity THEN the System SHALL allow all field workflows (registration, visits, triage, referral, scheduling, learning content already downloaded) to complete normally.
2. WHEN the ASHA saves any record THEN the System SHALL persist it to encrypted local storage before showing confirmation.
3. WHEN the app is force-closed, crashes or the device loses power mid-entry THEN the System SHALL restore the in-progress form as a draft on next launch.
4. WHEN a screen would need server data that is not cached THEN the System SHALL show a clear offline state and an alternative action, and SHALL NOT block the UI with an indefinite spinner.
5. WHEN storage is nearly full THEN the System SHALL warn the user, offer to clear safely synced and non-essential cached data, and SHALL NOT delete unsynced records.

### Requirement 2: Authentication, Roles and Shared-Device Safety

**User Story:** As an ASHA who shares her phone with family, I want my patient data protected behind a simple login, so that others cannot see or change beneficiary records.

#### Acceptance Criteria

1. WHEN the ASHA opens the app THEN the System SHALL require a PIN, pattern or device biometric that works offline.
2. WHEN a user is idle beyond a configurable timeout THEN the System SHALL lock the app and hide patient data from the recent-apps view.
3. WHEN a user is provisioned THEN the System SHALL assign exactly one role (ASHA, ASHA Facilitator, ANM/CHO, PHC MO, Block/District Officer, State Admin, Auditor) with role-scoped data access.
4. IF an incorrect PIN is entered a configurable number of times THEN the System SHALL apply an escalating lockout and require re-verification, which may need connectivity.
5. WHEN a device is lost or reassigned THEN the System SHALL let an administrator revoke the session, trigger remote wipe on next connection, and let the ASHA restore her data on a new device after re-verification.
6. WHEN the first login occurs on a device THEN the System SHALL verify identity by an official ASHA ID plus one-time password, and SHALL work in the same way for later offline logins using locally stored credentials.

### Requirement 3: Multilingual, Low-Literacy-Friendly Interface

**User Story:** As an ASHA with limited English and moderate education, I want the app in my own language with icons and audio, so that I can use it confidently without reading long text.

#### Acceptance Criteria

1. WHEN the app is first set up THEN the System SHALL let the user choose a language, at minimum Hindi, Marathi, Bengali, Telugu, Malayalam, Tamil, Kannada, Odia, Gujarati, Punjabi, Assamese and English, and SHALL allow switching at any time without data loss.
2. WHEN a screen presents a clinical term THEN the System SHALL show the local-language term used in official ASHA training material, with an icon or illustration where possible.
3. WHEN a screen is displayed THEN the System SHALL offer a tap-to-hear audio prompt for its instructions.
4. WHEN a form is shown THEN the System SHALL present one question per screen by default, with large touch targets, high contrast, and no hierarchical menu deeper than two levels.
5. WHEN a user is learning the app THEN the System SHALL provide an offline guided walkthrough and contextual help in her language.
6. WHEN a state or district adds or edits terminology THEN the System SHALL deliver the updated strings through a content update without a new app release.

### Requirement 4: Household and Beneficiary Registry

**User Story:** As an ASHA, I want to register and see every household and member in my area, so that I always have a complete longitudinal record of the person in front of me.

#### Acceptance Criteria

1. WHEN the ASHA registers a household THEN the System SHALL capture location (village, hamlet/pada), head of household, members, age/DOB, sex, relationships, social category, BPL status and contact details, with optional fields skippable.
2. WHEN the ASHA registers a member THEN the System SHALL generate a globally unique identifier on the device and SHALL NOT rely on a server-issued ID.
3. WHEN a new member resembles an existing record (name, age, household, phone similarity) THEN the System SHALL warn of a possible duplicate and offer to merge, link or continue.
4. WHEN the ASHA opens a beneficiary THEN the System SHALL show a single timeline of all visits, screenings, flags, referrals, immunizations and follow-ups.
5. WHEN a member is born, dies, migrates, marries out or moves THEN the System SHALL record the event, update household membership and stop generating tasks for that person where appropriate.
6. WHEN the beneficiary agrees THEN the System SHALL create or link an ABHA ID (see Requirement 36) and store it against the record.
7. WHEN the ASHA searches THEN the System SHALL support offline search by name (including phonetic and transliteration-tolerant matching), household, ABHA, RCH ID, phone and hamlet.
8. WHEN a household or member is shared between two workers' areas THEN the System SHALL support hand-over with an audit trail.

### Requirement 5: Informed Consent Management

**User Story:** As a beneficiary, I want to understand and control how my health data is collected and shared, so that my privacy is respected.

#### Acceptance Criteria

1. WHEN personal health data is first collected from a beneficiary THEN the System SHALL present a plain-language consent statement in her language, readable aloud in audio, covering purpose, who sees the data, and her right to withdraw.
2. WHEN consent is given THEN the System SHALL record it offline with timestamp, version of the consent text, a witness/ASHA identifier and a tamper-evident signature (tap, thumbprint photo or voice acknowledgment), and SHALL sync the consent artifact later.
3. IF consent is declined THEN the System SHALL allow the ASHA to provide emergency triage and referral guidance while restricting storage and sharing to what is legally permitted.
4. WHEN a beneficiary withdraws consent THEN the System SHALL flag the record, stop optional sharing and propagate the withdrawal on next sync.
5. WHEN a minor or an incapacitated person is the beneficiary THEN the System SHALL capture consent from the guardian and record that relationship.
6. WHEN the consent text or policy changes THEN the System SHALL request re-consent at the next relevant interaction.

### Part 2: Input and Output Modalities

### Requirement 6: Offline Voice Input

**User Story:** As an ASHA who finds typing slow and error-prone, I want to speak symptoms and measurements in my own language, so that data entry is fast and accurate.

#### Acceptance Criteria

1. WHEN the ASHA taps the microphone on a field THEN the System SHALL capture and transcribe speech entirely on the device with no network call.
2. WHEN a field is a number, yes/no, date or a choice from a closed list THEN the System SHALL use constrained recognition (restricted vocabulary and grammar) and map spoken variants, dialect words and number words in the local language to the correct value.
3. WHEN the recognizer has low confidence THEN the System SHALL read the interpreted value back (text and audio) and ask for confirmation instead of silently accepting it.
4. WHEN a free-text field (such as a note) is dictated THEN the System SHALL transcribe it in the native script and let the ASHA review and edit it.
5. WHEN ambient noise is too high THEN the System SHALL tell the user and offer tap-based entry.
6. WHEN the ASHA says a symptom in colloquial terms THEN the System SHALL map it to the standard symptom concept via a maintained local-term lexicon.
7. WHEN the device has less than the supported RAM or storage THEN the System SHALL fall back to a smaller model or tap-only entry and SHALL remain usable.
8. WHERE voice recordings are retained for quality improvement THEN the System SHALL do so only with explicit opt-in and SHALL otherwise discard audio after transcription.
9. WHEN a language/dialect model is released THEN the System SHALL deliver it as an optional download that can be installed and removed independently.

### Requirement 7: Audio Output and Voice Guidance

**User Story:** As an ASHA who is more comfortable listening than reading, I want the app to speak instructions and results, so that I understand triage outcomes and next steps immediately.

#### Acceptance Criteria

1. WHEN a triage result is shown THEN the System SHALL speak the colour, the reason and the recommended action in the selected language.
2. WHEN the ASHA starts a procedure (counting breaths, measuring MUAC, giving ORS) THEN the System SHALL offer step-by-step audio guidance.
3. WHEN audio is played THEN the System SHALL support pre-recorded human voice where available and on-device text-to-speech otherwise.
4. WHEN the ASHA needs to explain a result to a family THEN the System SHALL offer a family-facing audio and pictorial explanation.

### Part 3: Clinical Decision Support

### Requirement 8: On-Device Triage Engine (Red / Yellow / Green)

**User Story:** As an ASHA, I want instant triage from symptoms and vitals without any network, so that I know whether to refer urgently, monitor, or reassure.

#### Acceptance Criteria

1. WHEN the ASHA completes a clinical assessment THEN the System SHALL compute a red, yellow or green flag on the device in under one second and without any cloud call.
2. WHEN a flag is produced THEN the System SHALL show the exact rule(s) that triggered it in plain language (for example "Breathing 62/min in a baby under 2 months, refer now") along with the data values used.
3. WHEN multiple rules fire THEN the System SHALL show the highest severity and list all contributing findings.
4. WHEN required inputs are missing THEN the System SHALL either ask for them, or return a conservative result with the missing items stated, and SHALL NOT assume normal values.
5. WHEN the outcome is red THEN the System SHALL prompt the referral workflow (Requirement 10) and present the nearest facility, transport options and emergency contacts.
6. WHEN the ASHA disagrees with a suggestion THEN the System SHALL let her override to a more or less severe level with a required reason, and SHALL record both the suggestion and the override.
7. WHEN presenting any result THEN the System SHALL label it as decision support requiring ASHA judgment and SHALL NOT use the words "diagnosis" or "prescription".
8. WHEN rules are evaluated THEN the System SHALL be deterministic: the same inputs and rule version SHALL always return the same output.
9. IF an ML component is used in addition to rules THEN the System SHALL ensure it can only raise severity relative to the rules, never lower it, and SHALL expose its contribution as a separate, explainable item.

### Requirement 9: Clinical Rule Authoring, Versioning and Governance

**User Story:** As a clinical lead, I want triage rules stored as reviewable, versioned decision tables, so that doctors can verify them and updates are safe.

#### Acceptance Criteria

1. WHEN rules are defined THEN the System SHALL store them as structured, human-readable decision tables or JSON with source references (IMNCI, HBNC, HBYC, MoHFW guideline and page).
2. WHEN a rule set is changed THEN the System SHALL require clinician review and approval, version it, and keep the full change history.
3. WHEN a new approved rule version is published THEN the System SHALL deliver it to devices over the air, apply it only after full download and integrity verification, and keep the previous version for rollback.
4. WHEN an encounter is stored THEN the System SHALL record the rule-set version used, so past decisions can be reproduced.
5. WHEN a rule set is prepared THEN the System SHALL include automated test cases (input to expected flag) that must pass before release.
6. WHEN a state has protocol variations THEN the System SHALL support state-specific rule overlays on a national base.
7. WHEN a rule change would lower the severity of any existing test case THEN the System SHALL flag it for explicit additional clinical sign-off.

### Requirement 10: Referral Notes and Referral Lifecycle

**User Story:** As an ASHA, I want to generate a clear referral note and know what happened to the patient afterwards, so that the PHC doctor can act without calling me and I can close the loop.

#### Acceptance Criteria

1. WHEN a referral is created THEN the System SHALL generate a concise note with patient identifiers, age/sex, key symptoms and vitals, triage flag with reasons, actions already taken, timing, and the ASHA's contact details, in a form a doctor can read in under 30 seconds.
2. WHEN a referral note is created offline THEN the System SHALL make it available to share as PDF, image, SMS text, QR code or a WhatsApp message, and print-ready for a thermal or normal printer.
3. WHEN the ASHA selects a destination THEN the System SHALL propose the correct facility level (Sub-Centre/HWC, PHC, CHC, District Hospital, higher centre) based on severity, with distance and services from a locally cached facility directory.
4. WHEN the referral syncs THEN the System SHALL notify the receiving facility's dashboard and the ANM/AF, with red referrals flagged for immediate attention.
5. WHEN the receiving facility records an outcome (arrived, treated, admitted, discharged, not reached) THEN the System SHALL show it to the ASHA and add it to the beneficiary timeline.
6. WHEN a referred patient has not reached care within a configured window THEN the System SHALL create a follow-up task for the ASHA and an alert for her supervisor.
7. WHEN a note is generated THEN the System SHALL render it in the local language and, optionally, in English for the receiving doctor.
8. WHEN emergency transport is needed THEN the System SHALL show offline one-tap dial for 108/102 and locally configured ambulance and transport contacts.

### Requirement 11: General Sick Child and Adult Danger-Sign Assessment

**User Story:** As an ASHA, I want a guided danger-sign check for any sick child or adult I meet, so that I do not miss urgent conditions even when the visit was not planned.

#### Acceptance Criteria

1. WHEN the ASHA starts an unscheduled assessment THEN the System SHALL ask for age first and load the matching protocol (young infant, child 2 months to 5 years, adolescent, adult, pregnant woman).
2. WHEN the protocol covers cough/breathing, diarrhoea, fever, feeding problems or malnutrition signs THEN the System SHALL walk through IMNCI/HBYC-aligned questions and observations within ASHA scope.
3. WHEN respiratory rate is required THEN the System SHALL provide a built-in breath counter (Requirement 29) and apply the age-appropriate threshold.
4. WHEN a general danger sign (convulsions, unable to drink, vomiting everything, lethargy or unconsciousness) is recorded THEN the System SHALL produce a red flag immediately.
5. WHEN first-aid or home-care actions within ASHA scope apply (ORS, zinc, keeping warm, continued breastfeeding) THEN the System SHALL show them and SHALL NOT suggest actions outside ASHA scope.
6. WHEN a symptom set suggests an outbreak pattern (cluster of similar cases) THEN the System SHALL raise a surveillance prompt (Requirement 21).

### Part 4: Health Programs and Care Pathways

### Requirement 12: Home Based Newborn Care (HBNC)

**User Story:** As an ASHA, I want a guided newborn visit flow with the correct visit schedule, so that every newborn is assessed on time and danger signs are caught early.

#### Acceptance Criteria

1. WHEN a delivery is recorded THEN the System SHALL generate the HBNC visit schedule based on place of delivery and birth weight (including the extra visits for low birth weight or sick newborns) **[VALIDATE against current NHSRC HBNC guidelines]**.
2. WHEN a visit is started THEN the System SHALL guide the ASHA through the HBNC checklist: feeding and breastfeeding, weight, temperature, breathing rate, cord care, skin, eyes, activity, jaundice, hygiene, thermal care, and maternal postpartum checks.
3. WHEN any newborn danger sign is entered THEN the System SHALL produce a red flag and start the referral flow.
4. WHEN the baby is low birth weight or preterm THEN the System SHALL enrol the baby in a high-risk follow-up pathway with additional visits and Kangaroo Mother Care guidance.
5. WHEN a scheduled HBNC visit is missed THEN the System SHALL mark it overdue, reschedule within allowed windows, and notify the AF if it passes the window.
6. WHEN a newborn or mother death occurs THEN the System SHALL record details required for maternal/child death review and notify the supervisory chain.
7. WHEN all HBNC visits are completed THEN the System SHALL record completion and mark the event as incentive-eligible (Requirement 57).

### Requirement 13: Home Based Care for Young Child (HBYC) and Child Development

**User Story:** As an ASHA, I want to follow children through the first 15 months with developmental checks and counselling, so that growth and feeding problems are spotted early.

#### Acceptance Criteria

1. WHEN an infant reaches the HBYC age points (3, 6, 9, 12, 15 months) THEN the System SHALL schedule the visits **[VALIDATE]**.
2. WHEN a visit occurs THEN the System SHALL record feeding practices, complementary feeding, immunization status, growth, development milestones, illness, and responsive-caregiving counselling.
3. WHEN development milestones are delayed THEN the System SHALL suggest referral to the appropriate service (Anganwadi, RBSK/DEIC, PHC).
4. WHEN a child shows signs of severe malnutrition THEN the System SHALL trigger the nutrition pathway (Requirement 17).
5. WHEN counselling is needed THEN the System SHALL provide short pictorial and audio messages for the caregiver.

### Requirement 14: Pregnancy Registration, ANC and High-Risk Pregnancy

**User Story:** As an ASHA, I want to register every pregnant woman early and track her antenatal care, so that complications are identified and she delivers safely.

#### Acceptance Criteria

1. WHEN a pregnancy is registered THEN the System SHALL capture LMP, calculated EDD, obstetric history (gravida, para, previous complications, previous caesarean, stillbirths), and link the woman to the MCP card and RCH/ABHA IDs.
2. WHEN a woman is registered THEN the System SHALL generate the ANC schedule (checkups, TT/Td, IFA and calcium supplementation, ultrasound, lab tests) and add them to the due list.
3. WHEN a woman's BP, haemoglobin, weight, age, parity, bleeding, swelling, headache, reduced fetal movement or history meets high-risk criteria THEN the System SHALL flag her high-risk via the decision engine, show the reasons, and recommend facility referral.
4. WHEN a pregnancy is high-risk THEN the System SHALL increase visit frequency, alert the ANM and AF, and track institutional delivery planning.
5. WHEN the EDD is approaching THEN the System SHALL prompt for a birth plan: facility, transport, escort, blood donor, savings, and emergency contacts.
6. WHEN a woman is not seen by the due date of a scheduled ANC contact THEN the System SHALL mark it overdue and notify the ASHA.
7. WHEN pregnancy ends (delivery, abortion, miscarriage, stillbirth, maternal death) THEN the System SHALL record the outcome and trigger the relevant downstream pathway (PNC, HBNC, death review).

### Requirement 15: Delivery, Postnatal Care and Maternal Follow-up

**User Story:** As an ASHA, I want to support the mother through delivery and the postpartum period, so that maternal complications and newborn issues are addressed quickly.

#### Acceptance Criteria

1. WHEN a woman goes into labour or is near term THEN the System SHALL show one-tap contacts for the facility, ambulance and escort plans.
2. WHEN a delivery is recorded THEN the System SHALL capture place, type, attendant, date/time, outcome, newborn sex and birth weight, and create the newborn record.
3. WHEN a PNC visit is due THEN the System SHALL guide the postpartum checklist (bleeding, fever, BP, breast problems, wound, mood, nutrition, contraception counselling).
4. WHEN any maternal danger sign (heavy bleeding, fever, convulsions, severe headache, foul discharge) is entered THEN the System SHALL flag red and start referral.
5. WHEN signs of postpartum depression are indicated THEN the System SHALL prompt a supportive counselling pathway and referral per MoHFW mental health guidance.
6. WHEN institutional delivery is confirmed THEN the System SHALL mark the escort event for incentive tracking (Requirement 57).

### Requirement 16: Immunization

**User Story:** As an ASHA, I want to see which children and women are due or overdue for vaccines, so that coverage is complete and no child is missed.

#### Acceptance Criteria

1. WHEN a child is registered THEN the System SHALL generate the national immunization schedule from date of birth and show each dose due window.
2. WHEN a dose is given at the session THEN the System SHALL record vaccine, date, site and batch (if the ANM provides it), and reflect it in the child's immunization card view.
3. WHEN a child is overdue or a defaulter THEN the System SHALL list them in the due list with reasons for missing (if known) and show the catch-up schedule.
4. WHEN a VHSND or immunization session is planned THEN the System SHALL generate the beneficiary list for that session and a mobilization checklist (Requirement 27).
5. WHEN the ANM records vaccinations in U-WIN THEN the System SHALL accept the status through import or manual sync, to avoid duplicate entry (Requirement 35).
6. WHEN an adverse event following immunization (AEFI) is reported THEN the System SHALL capture symptoms, flag urgent cases red and notify the ANM and MO.
7. WHEN a pregnant woman is registered THEN the System SHALL include her TT/Td schedule in her ANC due list.

### Requirement 17: Child Growth, Nutrition and Malnutrition

**User Story:** As an ASHA, I want to track growth and spot malnourished children early, so that they get treatment before complications arise.

#### Acceptance Criteria

1. WHEN weight, height/length or MUAC is entered THEN the System SHALL plot it against WHO growth standards on the device and classify nutritional status (normal, moderate, severe acute malnutrition, stunting, underweight).
2. WHEN MUAC or weight-for-height indicates severe acute malnutrition, or oedema or appetite failure is present THEN the System SHALL flag red and recommend facility/NRC referral.
3. WHEN moderate acute malnutrition is identified THEN the System SHALL flag yellow, advise counselling and Anganwadi supplementary nutrition linkage, and schedule closer follow-ups.
4. WHEN IFA, vitamin A or deworming are due THEN the System SHALL add them to the due list and record administration.
5. WHEN anaemia is suspected or measured in women, adolescents or children THEN the System SHALL classify severity using the entered haemoglobin value and the applicable protocol, and refer if required.
6. WHEN a child is in a malnutrition programme THEN the System SHALL track weekly/monthly follow-ups and exit criteria.
7. WHEN the AWW updates POSHAN Tracker data THEN the System SHALL allow sharing of growth data in either direction through supported exports (Requirement 35).

### Requirement 18: Family Planning and Reproductive Health

**User Story:** As an ASHA, I want to counsel and track family planning for eligible couples, so that they can make informed choices and get supplies on time.

#### Acceptance Criteria

1. WHEN eligible couples are identified during household survey THEN the System SHALL list them with current method and unmet-need flags.
2. WHEN the ASHA counsels on contraception THEN the System SHALL provide a method-comparison flow with pictorial and audio explanations of options, eligibility and side effects, within ASHA scope.
3. WHEN contraceptives (condoms, OCPs, ECPs) are distributed THEN the System SHALL record quantity and next refill date, and deduct from the ASHA's stock (Requirement 30).
4. WHEN a user reports side effects or a method failure THEN the System SHALL guide the next steps and refer to the ANM/facility as appropriate.
5. WHEN a woman is postpartum or post-abortion THEN the System SHALL prompt contraception counselling at the correct time.
6. WHEN sterilisation or IUCD/injectable services are accessed at a facility THEN the System SHALL record the event and follow-up for incentive tracking.
7. WHEN personal data about contraception is recorded THEN the System SHALL restrict visibility to a minimum necessary set of roles and hide it from household-shared views.

### Requirement 19: NCD Screening with CBAC

**User Story:** As an ASHA, I want to screen adults for hypertension, diabetes and common cancers using CBAC, so that high-risk people are referred and treatment is followed up.

#### Acceptance Criteria

1. WHEN the ASHA screens a person aged 30 or above THEN the System SHALL present the CBAC questionnaire, compute the risk score offline using the official scoring rules **[VALIDATE exact scoring and age bands]**, and indicate when the score requires confirmation at the facility.
2. WHEN a BP or blood glucose reading is entered or received from a device THEN the System SHALL classify it per national NCD guidelines and flag yellow or red as applicable.
3. WHEN symptoms suggestive of oral, breast or cervical cancer are recorded THEN the System SHALL flag for referral to confirmatory screening and track completion.
4. WHEN a person is confirmed to have hypertension or diabetes THEN the System SHALL add them to a follow-up register with medication adherence checks, repeat measurement reminders and refill tracking.
5. WHEN a person is overdue for follow-up or missed a facility visit THEN the System SHALL list them for tracing.
6. WHEN CBAC data is saved THEN the System SHALL offer export to the national NCD application (Requirement 35) without re-entry.
7. WHEN lifestyle counselling is appropriate THEN the System SHALL provide short audio and pictorial messages on tobacco, alcohol, diet, salt and physical activity.

### Requirement 20: Tuberculosis Support

**User Story:** As an ASHA, I want to identify TB suspects and support patients through treatment, so that cases are found early and treatment is completed.

#### Acceptance Criteria

1. WHEN a person has cough of two weeks or more, fever, weight loss, night sweats or other TB symptoms THEN the System SHALL flag a presumptive TB case and guide referral for testing.
2. WHEN a sputum sample is collected THEN the System SHALL record sample details and track transport and result status.
3. WHEN a patient starts treatment THEN the System SHALL register them in the TB follow-up pathway, record the treatment supporter role, and schedule dose-adherence checks.
4. WHEN a dose is observed or missed THEN the System SHALL record it and alert the ASHA and TB staff after configured consecutive misses.
5. WHEN household contacts of a TB case exist THEN the System SHALL list them for screening and preventive therapy as applicable.
6. WHEN diagnosis and treatment status exist in Ni-kshay THEN the System SHALL allow sync or import of status, to avoid double entry (Requirement 35).
7. WHEN a TB patient has nutrition or social-support needs THEN the System SHALL prompt linkage to the relevant scheme and record it.
8. WHEN TB data is displayed THEN the System SHALL apply additional privacy protections against stigma, including hidden labels on shared views.

### Requirement 21: Communicable Disease, Malaria and Outbreak Surveillance

**User Story:** As an ASHA, I want to report fever clusters and test for malaria where applicable, so that outbreaks are noticed early.

#### Acceptance Criteria

1. WHEN a fever case in a malaria-endemic area is assessed THEN the System SHALL guide rapid diagnostic test use and record the result and treatment referral per protocol.
2. WHEN the ASHA enters cases that match an alert pattern (for example more than a threshold of similar cases in the same hamlet within a short period) THEN the System SHALL raise a local outbreak alert to the ANM, AF and MO on sync.
3. WHEN the ASHA records a vector-borne, waterborne or other notifiable disease THEN the System SHALL capture the minimum surveillance data and route it to the appropriate programme.
4. WHEN an outbreak response is initiated THEN the System SHALL let supervisors push targeted instructions and checklists to affected ASHAs.
5. WHEN seasonal risks apply (monsoon, dengue, heat wave) THEN the System SHALL show relevant awareness and action prompts.
6. WHEN the ASHA reports an animal bite, snake bite, poisoning or injury THEN the System SHALL provide the first-aid steps and immediate referral guidance.

### Requirement 22: Other Health Programs and Life-Stage Coverage

**User Story:** As an ASHA, I want support for all the other tasks I am asked to do, so that I do not need a separate system for any part of my work.

#### Acceptance Criteria

1. WHEN adolescent health tasks apply THEN the System SHALL support adolescent registers, menstrual hygiene, IFA/WIFS distribution and counselling, and referral to adolescent-friendly services.
2. WHEN elderly, palliative or bedridden patients are identified THEN the System SHALL support a home-care follow-up list with visit logs.
3. WHEN common mental health concerns are noticed (depression, anxiety, substance use, suicide risk) THEN the System SHALL provide a screening aid within ASHA scope and a referral and helpline pathway.
4. WHEN a disability is noticed THEN the System SHALL support registration and linkage to disability services.
5. WHEN a new national or state programme is introduced THEN the System SHALL allow it to be added as a configurable form, schedule and rules module, without a new app release.
6. WHEN the ASHA conducts routine village activities (surveys, awareness sessions, sanitation drives) THEN the System SHALL log them with participants and notes.

### Requirement 23: Vital Events Registration (Births and Deaths)

**User Story:** As an ASHA, I want to report births and deaths properly, so that records are complete and certificates and schemes follow.

#### Acceptance Criteria

1. WHEN a birth or death occurs in her area THEN the System SHALL capture the data required for civil registration and the health system and prepare a shareable report.
2. WHEN a maternal, infant or child death is entered THEN the System SHALL capture the information needed for death review and notify the supervisory chain.
3. WHEN a stillbirth or abortion is recorded THEN the System SHALL handle it with sensitivity, minimal mandatory fields and restricted visibility.
4. WHEN the vital event is reported THEN the System SHALL update the household registry and cancel pending tasks for the person.

### Part 5: Work Planning

### Requirement 24: Due List and Visit Scheduler

**User Story:** As an ASHA, I want a prioritised list of who I need to see today and this week, so that I open the app every morning and never miss a time-critical visit.

#### Acceptance Criteria

1. WHEN the app is opened THEN the System SHALL show today's tasks, grouped by urgency (red follow-ups, overdue, due today, upcoming) and by hamlet.
2. WHEN a pregnancy, delivery, birth, vaccination, test or follow-up date exists THEN the System SHALL auto-generate due and overdue tasks from date rules, with no manual scheduling required.
3. WHEN the ASHA completes a task THEN the System SHALL remove it from the list and generate the next dependent task.
4. WHEN the ASHA cannot complete a visit THEN the System SHALL let her record a reason (not at home, refused, migrated, unwell, access problem) and reschedule within permitted windows.
5. WHEN the ASHA wants an overview THEN the System SHALL show week and month views and a coverage summary of her area by programme.
6. WHEN tasks exceed a day's capacity THEN the System SHALL prioritise by clinical risk and time-window expiry and show why.
7. WHEN the ASHA adds an ad hoc visit or task THEN the System SHALL allow it and merge it with the plan.

### Requirement 25: Route and Hamlet Planning for Dispersed Areas

**User Story:** As an ASHA in a hilly or tribal area, I want my visits ordered to reduce walking, so that I spend more time with patients and less on the road.

#### Acceptance Criteria

1. WHEN the ASHA has multiple visits THEN the System SHALL suggest an efficient hamlet-level order using household location data, available offline.
2. WHEN a location is recorded THEN the System SHALL store it only with the ASHA's opt-in and at the level of detail needed (hamlet, or household pin) and SHALL NOT track her continuously.
3. WHEN the ASHA needs directions to a household or facility THEN the System SHALL show an offline map or sketch map with landmarks, where regional map data has been downloaded.
4. WHEN a hamlet is remote, seasonal or unreachable (floods, landslides) THEN the System SHALL allow it to be flagged and adjust the scheduling.
5. WHEN a coverage analysis is requested THEN the System SHALL show to supervisors, with the ASHA's consent, which hamlets are visited less often and why (distance, access), to support workload planning.

### Requirement 26: Reminders and Beneficiary Communication

**User Story:** As an ASHA, I want reminders to reach me and my beneficiaries reliably, so that appointments and doses are not missed.

#### Acceptance Criteria

1. WHEN a task is due THEN the System SHALL show a local notification on the device without network.
2. WHEN a beneficiary has a phone and has opted in THEN the System SHALL send reminders via SMS or IVR in her language when connectivity is available, with all messages avoiding sensitive health details.
3. WHEN the ASHA wants to message a family THEN the System SHALL provide templates in the local language and a one-tap call/SMS action.
4. WHEN a beneficiary replies or acknowledges THEN the System SHALL record it if the channel supports it.
5. WHEN notification volume is high THEN the System SHALL batch and limit notifications and SHALL respect quiet hours.
6. WHEN the ASHA needs to reach her ANM, AF or MO THEN the System SHALL provide one-tap call and message actions from the beneficiary or referral screen.

### Requirement 27: VHSND, Community Mobilisation and Health Education

**User Story:** As an ASHA, I want help planning and recording village health days and community activities, so that sessions are well attended and documented.

#### Acceptance Criteria

1. WHEN a VHSND is scheduled THEN the System SHALL generate the list of due beneficiaries per service, a mobilisation checklist and a session summary form.
2. WHEN the session occurs THEN the System SHALL record attendance, services given and gaps, and update individual records.
3. WHEN VHSNC meetings or community events are held THEN the System SHALL log date, participants, decisions and follow-ups.
4. WHEN health education is needed THEN the System SHALL provide an offline library of short audio, picture and video messages in local languages, searchable by topic.
5. WHEN a campaign (pulse polio, MDA, IFA week, TB case-finding) is active THEN the System SHALL provide its checklist, target list and reporting form.
6. WHEN community feedback or health concerns are collected THEN the System SHALL record them and route them to the supervisor and the VHSNC.

### Part 6: Devices and Tools

### Requirement 28: Bluetooth Device Integration with Manual Fallback

**User Story:** As an ASHA, I want my BP monitor, pulse oximeter, thermometer and similar devices to send readings straight into the app, so that I avoid transcription mistakes.

#### Acceptance Criteria

1. WHEN a supported Bluetooth Low Energy device is paired THEN the System SHALL receive readings directly into the active form field and show the device identity and time of the measurement.
2. WHEN a device is unsupported, out of battery, or fails to connect THEN the System SHALL offer immediate manual entry with no loss of workflow.
3. WHEN a reading is out of plausible physiological range THEN the System SHALL prompt the ASHA to remeasure before saving.
4. WHEN a reading is entered THEN the System SHALL record its source (device or manual) for quality and audit.
5. WHEN a device type is added THEN the System SHALL support it through a device-profile configuration (service/characteristic mapping, units, validation) and SHALL support at least pulse oximeters, BP monitors, digital thermometers, glucometers, haemoglobinometers, weighing scales and smart stethoscopes where standard profiles exist.
6. WHEN readings are received THEN the System SHALL require no background service that drains battery, and SHALL connect only while a measurement screen is active.
7. WHEN a device is shared among ASHAs THEN the System SHALL tie each reading to the active patient and user, not to the device.

### Requirement 29: Zero-Hardware Measurement Aids

**User Story:** As an ASHA without working equipment, I want tools built into the app for common measurements, so that I can still assess patients properly.

#### Acceptance Criteria

1. WHEN the ASHA needs to count breaths THEN the System SHALL provide a timer with tap-to-count and audible cues, and compute the rate and the age-appropriate classification.
2. WHEN the ASHA needs to measure MUAC, height or growth THEN the System SHALL provide a colour-coded reading guide and an on-screen reference for tape colours.
3. WHEN a timed procedure applies (such as a 60-second respiratory count or 14-day sputum timing) THEN the System SHALL provide timers and reminders.
4. WHEN a camera-based measurement or AI estimation is offered (for example, infant weight, jaundice or anaemia colour) THEN the System SHALL label it experimental, SHALL require clinical validation and regulatory approval before triage use, and SHALL NOT use it as the sole basis for a red-to-green downgrade.
5. WHEN a calculation is needed (EDD, gestational age, drug doses within ASHA scope, BMI, percentiles) THEN the System SHALL provide built-in calculators.

### Requirement 30: Equipment, Supply and Drug Stock Management

**User Story:** As an ASHA, I want to track my kit and consumables, so that I know when to request restocking and my tools are working.

#### Acceptance Criteria

1. WHEN an ASHA's kit is issued THEN the System SHALL record items, serial numbers and issue dates against her.
2. WHEN she dispenses IFA, ORS, zinc, contraceptives or other items THEN the System SHALL decrement stock and show remaining quantity and estimated run-out date.
3. WHEN stock falls below a threshold THEN the System SHALL notify the ASHA and the AF and allow a restock request that works offline.
4. WHEN a device reading pattern suggests a fault or drift (repeated implausible readings, low battery) THEN the System SHALL alert the ASHA and offer a fault report with photo.
5. WHEN a device is due for calibration or replacement THEN the System SHALL list it for the ANM and record the action taken.
6. WHEN a stock-out occurs THEN the System SHALL record it and roll it up to the PHC and district dashboards for supply-chain action.

### Part 7: Data, Sync and Interoperability

### Requirement 31: Background Synchronisation

**User Story:** As an ASHA who is rarely online, I want my data to sync automatically when a network appears, so that my supervisors see my work without me doing anything.

#### Acceptance Criteria

1. WHEN connectivity becomes available THEN the System SHALL sync in the background in small prioritised batches (referrals and red flags first, then visits, then low-priority data).
2. WHEN the network is slow or unstable (2G/EDGE) THEN the System SHALL use compact payloads, resume interrupted transfers, and retry with backoff without duplicating records.
3. WHEN a sync completes or fails THEN the System SHALL show a simple status per record (saved on phone, synced, needs attention) and SHALL NOT interrupt the user.
4. WHEN a user wants data-cost control THEN the System SHALL offer a Wi-Fi-only mode for large downloads (rule updates, maps, learning content) and SHALL always allow small safety-critical syncs.
5. WHEN a SMS-only path is needed for a red referral and no data is available THEN the System SHALL be able to send a compact referral summary by SMS.
6. WHEN the device is idle with no pending data THEN the System SHALL not run background activity that wastes battery.
7. WHEN the server is unreachable THEN the System SHALL keep all data intact on-device for as long as needed.

### Requirement 32: Conflict Resolution and Identity Merging

**User Story:** As a system operator, I want concurrent offline edits by different workers to merge safely, so that no data is silently lost or duplicated.

#### Acceptance Criteria

1. WHEN records are created offline THEN the System SHALL use client-generated unique IDs and an append-only event log of changes.
2. WHEN two users edit the same record offline THEN the System SHALL merge non-overlapping fields automatically and SHALL flag true conflicts on the same field for review, recording both values.
3. WHEN clinical data conflicts (for example, two different weights on the same day) THEN the System SHALL keep both with provenance and show the most recent by default, never overwriting silently.
4. WHEN the server detects duplicate beneficiaries across workers THEN the System SHALL propose a merge to a designated reviewer and preserve full history of both records.
5. WHEN a merge is approved THEN the System SHALL propagate the canonical record to all devices and redirect references from the retired ID.
6. WHEN device clocks are wrong THEN the System SHALL not rely on device time alone and SHALL record both device time and server-received time.

### Requirement 33: Data Integrity and Auditability

**User Story:** As an auditor, I want tamper-evident records of who recorded what and when, so that data and decisions can be trusted.

#### Acceptance Criteria

1. WHEN a clinical or incentive-relevant record is created THEN the System SHALL store its author, time, device, app version and rule version.
2. WHEN records are synced THEN the System SHALL include a tamper-evident integrity mechanism (such as hashes over event chains) so alterations are detectable.
3. WHEN a record is corrected THEN the System SHALL keep the original, add the correction with reason and author, and SHALL NOT allow silent edits or deletion of clinical history.
4. WHEN an auditor requests an audit trail for a beneficiary or a worker THEN the System SHALL produce it with role-appropriate redaction.
5. WHEN data validation rules fail (impossible dates, ages, vitals) THEN the System SHALL block or warn at entry and log patterns of repeated bypass.

### Requirement 34: Paper-Compatible Outputs (Ending the Double Burden)

**User Story:** As an ASHA who must still submit paper registers, I want the app to produce those outputs from my single entry, so that I never write the same data twice.

#### Acceptance Criteria

1. WHEN the ASHA needs a register page THEN the System SHALL generate print-ready and shareable PDF views matching the layout of the official registers and forms (village survey, RCH, HBNC, HBYC, PNC, high-risk, CBAC, TB, immunization and others).
2. WHEN the supervisor or ANM asks for monthly reports THEN the System SHALL generate the standard monthly reporting formats from synced or on-device data.
3. WHEN an official format is updated THEN the System SHALL allow templates to be updated through configuration.
4. WHEN a printer is unavailable THEN the System SHALL provide a clear on-screen view that can be shown to or photographed by the supervisor, and a share action by messaging apps.
5. WHEN the ASHA wants to hand a record to the family THEN the System SHALL generate a family-friendly summary or card (MCP card update, vaccination card, referral slip).

### Requirement 35: Integration with Government Digital Systems

**User Story:** As an ANM and an ASHA, I want data to flow to RCH/ANMOL, U-WIN, Ni-kshay, NCD, HMIS and POSHAN systems without retyping, so that digital tools reduce work instead of adding to it.

#### Acceptance Criteria

1. WHEN an official API or integration channel exists for a system THEN the System SHALL integrate via that channel with the required authorisations and security.
2. WHEN no public API exists THEN the System SHALL provide exports in the system's accepted bulk-upload or data-entry format and a guided entry assistant for the operator (ANM/DEO), minimising keystrokes.
3. WHEN data originates in another system (for example, vaccination from U-WIN, TB treatment from Ni-kshay) THEN the System SHALL import or reconcile it and show the source.
4. WHEN field mappings differ across states THEN the System SHALL provide state-level mapping configurations.
5. WHEN an integration fails or a record is rejected THEN the System SHALL show the reason and a correction path to the right user.
6. WHEN HMIS monthly indicators are needed THEN the System SHALL auto-compute them from event data and let the ANM review before submission.
7. WHEN integrations are added THEN the System SHALL log all outbound sharing for DPDP accountability.

### Requirement 36: ABDM, ABHA and FHIR Interoperability

**User Story:** As a beneficiary, I want my health records linked to my ABHA, so that care is continuous across facilities.

#### Acceptance Criteria

1. WHEN the beneficiary consents THEN the System SHALL support creating, verifying and linking an ABHA ID, working offline for capture and completing verification when connectivity is available.
2. WHEN records are exchanged with ABDM THEN the System SHALL generate FHIR R4 resources conforming to ABDM profiles on the server side and use compact payloads in transit from devices.
3. WHEN a beneficiary or a facility requests records through ABDM consent flows THEN the System SHALL honour consent artifacts and scope.
4. WHEN a health facility or professional registry lookup is required THEN the System SHALL use ABDM registries, with local caching for offline use.
5. WHEN ABDM specifications change THEN the System SHALL absorb them through backend mapping updates without requiring app releases wherever possible.
6. WHEN the System is deployed THEN it SHALL complete the ABDM sandbox and certification steps required for the relevant roles.

### Part 8: Learning, Support and Supervision

### Requirement 37: Training and Micro-Learning

**User Story:** As an ASHA, I want short, practical lessons on my phone, so that I keep my skills sharp and learn new programmes without leaving my village.

#### Acceptance Criteria

1. WHEN an ASHA is onboarded THEN the System SHALL provide an induction pathway aligned with the official ASHA modules (including HBNC, HBYC, NCD, TB, immunization) in audio, video and illustrated formats, available offline.
2. WHEN a lesson is available THEN the System SHALL keep it short (about two to five minutes) with a few quiz questions, and SHALL store progress and scores locally.
3. WHEN the System sees a performance or knowledge gap (for example, repeated skipped danger-sign questions, frequent overrides, missed IFA distribution, or rejected data) THEN it SHALL suggest a relevant micro-lesson, without punitive framing.
4. WHEN a red flag is raised THEN the System SHALL offer a link to a short refresher about that danger sign.
5. WHEN a mandatory course exists THEN the System SHALL pace content (for example, limiting completion per day) and use spaced-repetition quizzes to improve retention, rather than allowing a single-sitting click-through.
6. WHEN the ASHA completes modules THEN the System SHALL record completion toward official certification, with a verifiable certificate or record, and share with the AF and the training system.
7. WHEN trainers or the state add content THEN the System SHALL allow content publishing and assignment by role, with versioning and language variants.
8. WHEN soft skills are covered THEN the System SHALL include modules on communication, counselling, negotiation, financial literacy, stress management and self-efficacy.
9. WHEN scenario practice is available THEN the System SHALL offer offline simulated cases (for example, a sick newborn) that exercise the triage workflow in practice mode with no real records created.
10. WHEN the ASHA asks a question about a protocol THEN the System SHALL provide searchable offline reference cards and job aids from official material.

### Requirement 38: Teleconsultation, Helpline and Peer Support

**User Story:** As an ASHA facing a difficult case, I want to reach a doctor or colleague quickly, so that I am not alone with the decision.

#### Acceptance Criteria

1. WHEN the ASHA wants advice THEN the System SHALL provide one-tap calls to the ANM, CHO, MO, and helplines (including 104, 108, 102 and state-specific lines), and SHALL work with basic voice calls when data is unavailable.
2. WHEN connectivity is sufficient THEN the System SHALL support asynchronous case sharing (message with the referral note) and, where available, linkage to e-Sanjeevani or similar teleconsult services.
3. WHEN an ASHA wants peer help THEN the System SHALL provide an opt-in group or forum with moderated Q and A, voice notes and local-language support.
4. WHEN sensitive patient details are shared THEN the System SHALL share only the minimum necessary details and with consent.

### Requirement 39: ASHA Facilitator Supportive Supervision

**User Story:** As an ASHA Facilitator, I want to see how my ASHAs are doing and where they need help, so that I can mentor them rather than only check compliance.

#### Acceptance Criteria

1. WHEN an AF opens the dashboard THEN the System SHALL show, for each ASHA under her, coverage, overdue visits, pending referrals, recent red flags, data quality indicators and learning progress.
2. WHEN an AF plans a supervisory visit THEN the System SHALL offer digital supervision checklists (observing a visit, checking registers, reviewing equipment) and capture findings, photos and agreed actions offline.
3. WHEN patterns indicate a need for mentoring (frequent errors, repeated missed tasks, unusual overrides) THEN the System SHALL surface them in a supportive framing and suggest micro-learning or a visit.
4. WHEN an ASHA's workload is excessive or access is hard THEN the System SHALL highlight it to support workload balancing.
5. WHEN the AF reviews data THEN the System SHALL provide a quick way to give feedback or recognition to an ASHA through messages, voice notes or badges.
6. WHEN an AF resolves or escalates an issue THEN the System SHALL record the action and follow up.

### Requirement 40: ANM and CHO Workspace

**User Story:** As an ANM, I want the data collected by ASHAs to arrive ready to use, so that I can focus on clinical care and sessions rather than re-entering records.

#### Acceptance Criteria

1. WHEN ASHAs sync THEN the System SHALL show the ANM the new registrations, ANC/PNC, immunization and referral data for her sub-centre area, with validation errors highlighted.
2. WHEN the ANM conducts a VHSND or clinic THEN the System SHALL provide a session list and let her record services, which update the beneficiary timelines.
3. WHEN the ANM verifies ASHA work THEN the System SHALL provide an efficient review queue with evidence from the logged events (Requirement 57).
4. WHEN red-flag referrals and high-risk cases arise THEN the System SHALL alert the ANM or CHO with the required details.
5. WHEN the ANM needs government portal entry THEN the System SHALL provide the assistant described in Requirement 35.
6. WHEN the ANM wants to use the system offline THEN the System SHALL provide an offline-capable tablet or phone app for her area's data.

### Requirement 41: PHC / Facility Dashboard

**User Story:** As a PHC doctor, I want incoming referrals and area health indicators in one place, so that I can prepare for patients and act on risks.

#### Acceptance Criteria

1. WHEN a referral syncs THEN the System SHALL show it in a live queue at the destination facility sorted by severity, with the referral note, patient history, and the ASHA's contact.
2. WHEN a facility staff member records an outcome THEN the System SHALL notify the originating ASHA and ANM.
3. WHEN the doctor reviews the area THEN the System SHALL show high-risk pregnancies, sick newborns, malnourished children, TB patients, NCD defaulters and overdue follow-ups with filters by sub-centre and ASHA.
4. WHEN the facility needs to plan THEN the System SHALL show expected deliveries, immunization demand, stock levels and outstanding referrals.
5. WHEN a doctor wants to give advice back THEN the System SHALL let her send a short text or voice instruction to the ASHA linked to the case.
6. WHEN the dashboard is used on a slow connection THEN the System SHALL load a lightweight view and cache recent data.

### Requirement 42: Block, District and State Analytics

**User Story:** As a district health officer, I want reliable and timely data across my area, so that I can detect outbreaks, direct resources and monitor programmes.

#### Acceptance Criteria

1. WHEN data syncs THEN the System SHALL update coverage and outcome indicators (ANC coverage, institutional delivery, immunization, HBNC/HBYC completion, NCD screening, TB notification) near real time.
2. WHEN a geographic view is requested THEN the System SHALL show maps and heatmaps by block, PHC, sub-centre and village, with privacy-preserving aggregation for small counts.
3. WHEN signals suggest an outbreak, a high-risk cluster or a service gap THEN the System SHALL alert officers with the supporting data.
4. WHEN supply forecasting is needed THEN the System SHALL estimate consumption and run-out of key commodities from logged use.
5. WHEN data quality is poor in an area THEN the System SHALL highlight missing, delayed or anomalous data without blaming individual workers by default.
6. WHEN analysis is needed for research or planning THEN the System SHALL provide de-identified exports and a query interface with access controls.
7. WHEN officers compare areas THEN the System SHALL provide benchmarks against targets and previous periods.

### Part 9: Administration, Security and Compliance

### Requirement 43: Administration and Configuration Console

**User Story:** As a state or district administrator, I want to configure the system for my state without developers, so that rules, forms, languages and rates reflect local policy.

#### Acceptance Criteria

1. WHEN an admin manages users THEN the System SHALL support bulk onboarding, role assignment, area mapping (village, hamlet, sub-centre, PHC, block, district), reassignment and deactivation.
2. WHEN an admin updates the organisational hierarchy THEN the System SHALL propagate changes to dashboards and routing without data loss.
3. WHEN forms, schedules, rule sets, languages, content, incentive categories, and facility directories change THEN the System SHALL allow admins with the proper role to edit and publish them with versioning and staged rollout.
4. WHEN a configuration change is published THEN the System SHALL allow targeting by state, district, block or user group, and rollback.
5. WHEN an admin needs to monitor deployment THEN the System SHALL show app versions in use, last sync times, sync failures, storage and device health per user.
6. WHEN the System is deployed to a new state THEN the System SHALL support it through configuration, with a checklist for localisation and validation.

### Requirement 44: Data Security and Privacy Compliance (DPDP and ABDM)

**User Story:** As a beneficiary, I want my health data kept private and used lawfully, so that I can trust the system with sensitive information.

#### Acceptance Criteria

1. WHEN data is stored on devices or servers THEN the System SHALL encrypt it at rest, and in transit with modern TLS and certificate pinning in the app.
2. WHEN personal data is collected THEN the System SHALL limit it to what is necessary for a stated purpose, record the purpose, and apply retention limits.
3. WHEN a beneficiary requests access, correction or erasure of her data THEN the System SHALL support the request workflow within the legal limits and record its fulfilment.
4. WHEN a data breach is suspected THEN the System SHALL provide detection, incident logging, and the notification workflow required by law.
5. WHEN data is processed by third parties or cloud providers THEN the System SHALL ensure data stays in compliant jurisdictions and processors are under agreements.
6. WHEN staff access beneficiary data THEN the System SHALL enforce least privilege, log every access and alert on unusual access patterns.
7. WHEN data is used for analytics, model training or research THEN the System SHALL use de-identified data and obtain ethics review and consent where required.
8. WHEN a phone is rooted, tampered with, or running a modified app THEN the System SHALL detect and restrict access where feasible.
9. WHEN data from stigmatised conditions (HIV, TB, mental health, family planning) is shown THEN the System SHALL apply stricter visibility controls and neutral labels.

### Requirement 45: Worker Privacy, Anti-Surveillance Safeguards and Transparency

**User Story:** As an ASHA, I want to know exactly what the app tracks about me and be sure it is not used to punish me unfairly, so that I trust and willingly use it.

#### Acceptance Criteria

1. WHEN the app is installed THEN the System SHALL show a plain-language, audio-supported notice of what data about the worker is collected and who can see it.
2. WHEN location is used THEN the System SHALL use it only for features the ASHA has enabled, only while she is using the feature, and SHALL NOT perform continuous tracking or punitive geofencing.
3. WHEN supervisors view performance data THEN the System SHALL present it for support and planning, and SHALL give the ASHA access to the same data about herself.
4. WHEN a worker disputes data about her work THEN the System SHALL provide a grievance channel with a recorded resolution.
5. WHEN workers' representatives or unions request aggregate information about the platform's use THEN the System SHALL support it through governance policy and aggregated reporting.
6. WHEN analytics about individuals are proposed for use in appraisal or disciplinary action THEN the System SHALL require policy sign-off and SHALL expose such uses to the workers affected.

### Requirement 46: AI Safety, Human Oversight and Monitoring

**User Story:** As a clinical safety officer, I want AI outputs to be safe, explainable and monitored, so that ASHAs stay in control and errors are caught early.

#### Acceptance Criteria

1. WHEN the System gives a suggestion THEN it SHALL present it as advice, require ASHA confirmation to proceed with the recorded action, and keep the ASHA's final decision as the one of record.
2. WHEN the System suggests a lower-severity outcome than the ASHA's own observation THEN the System SHALL prompt her to reconsider the observation (for example, a "child looks lethargic?" check) and SHALL always allow her to escalate.
3. WHEN triage outcomes, overrides and referral results are synced THEN the System SHALL monitor over-triage, under-triage, override rates and outcome mismatches by rule, language, area and ASHA cohort, and alert the clinical team when thresholds are exceeded.
4. WHEN a safety incident or near miss is reported THEN the System SHALL provide an incident workflow with review, root cause, rule or model correction and re-release.
5. WHEN voice recognition or any ML component performs poorly for a language, dialect or demographic THEN the System SHALL report accuracy by group and the team SHALL be able to disable or restrict that component.
6. WHEN a model or rule set is updated THEN the System SHALL require validation on a held-out test set and sign-off before release.
7. WHEN the ASHA gives feedback on a suggestion THEN the System SHALL capture it for clinical review.
8. WHEN the user interface presents AI output THEN the System SHALL avoid designs that encourage over-reliance, for example by showing the observations she entered next to the output.

### Requirement 47: Regulatory and Quality Management Compliance

**User Story:** As the product owner, I want the platform to meet medical-software regulation and quality standards, so that it can be deployed legally in public health programmes.

#### Acceptance Criteria

1. WHEN the triage function is classified THEN the System SHALL be developed under a documented Quality Management System, with an intended-use statement and classification analysis under the Medical Devices Rules and CDSCO software guidance **[VALIDATE current CDSCO position, including treatment of lay-user software]**.
2. WHEN a release is prepared THEN the System SHALL maintain requirements-to-test traceability, risk management files (hazard analysis), and verification and validation evidence.
3. WHEN clinical performance claims are made THEN the System SHALL support a clinical validation study design (sensitivity, specificity, agreement with clinician or IMNCI gold standard) in the target settings.
4. WHEN software changes affect clinical behaviour THEN the System SHALL follow change control, regression testing and release approval.
5. WHEN post-deployment issues arise THEN the System SHALL support complaint handling and vigilance reporting.
6. WHEN legal liability for triage error is considered THEN the System SHALL provide documentation of intended use, limitations, user training and the human-in-the-loop design.

### Part 10: Non-Functional and Operational

### Requirement 48: Performance and Low-End Device Constraints

**User Story:** As an ASHA with an older, low-memory phone, I want the app to run smoothly and not drain my battery or storage, so that it works on the phone I actually have.

#### Acceptance Criteria

1. WHEN the app is installed THEN the System SHALL keep the base install small (target under about 50 MB) and offer optional downloads for language models, maps and learning content.
2. WHEN the app runs on a device with 2 GB RAM and an older Android version THEN the System SHALL remain responsive (screens in under one second, triage in under one second) and not be killed by the OS during entry.
3. WHEN the app is in use THEN the System SHALL minimise battery consumption, avoid persistent background services and let the user see storage use.
4. WHEN the device is not powered for long periods THEN the System SHALL preserve data and resume correctly.
5. WHEN the app is updated THEN the System SHALL support delta updates, deferred updates on poor connections, and backward-compatible data schemas.
6. WHEN a minimum Android version or hardware is not met THEN the System SHALL show a clear message and offer a reduced-feature mode where possible.
7. WHEN the System is used on a low-cost power bank or solar charging setup THEN the System SHALL provide a low-power mode (dark UI, reduced animation, sync deferral).

### Requirement 49: Accessibility and Inclusion

**User Story:** As an ASHA with low vision, hearing difficulties or limited dexterity, I want the app to be usable for me, so that I am not excluded from the workforce tools.

#### Acceptance Criteria

1. WHEN the user adjusts display THEN the System SHALL support larger text, high contrast and a bright-sunlight mode.
2. WHEN a user has vision impairment THEN the System SHALL support screen readers and audio-first operation.
3. WHEN a user has hearing impairment THEN the System SHALL support visual and vibration cues for all alerts.
4. WHEN a user has dexterity limitations THEN the System SHALL provide large, well-spaced controls and voice alternatives.
5. WHEN a beneficiary has a disability or limited language ability THEN the System SHALL support assisted communication aids such as pictorial prompts.

### Requirement 50: Backup, Recovery and Device Migration

**User Story:** As an ASHA who may lose or replace her phone, I want my data to be recoverable, so that months of work are not lost.

#### Acceptance Criteria

1. WHEN data is synced THEN the System SHALL retain it server-side with redundancy and backups, and test restore procedures.
2. WHEN an ASHA gets a new device THEN the System SHALL restore her assigned area data after secure re-verification, within the data minimisation limits for the device.
3. WHEN a device is lost THEN the System SHALL limit loss to unsynced data and tell the user which items were unsynced if known.
4. WHEN the ASHA nears the end of a shift or day THEN the System SHALL provide a quick "sync status" check and nudge her to sync when a network is available.
5. WHEN a worker leaves or is replaced THEN the System SHALL support structured hand-over of her households and open tasks to a successor.

### Requirement 51: Observability, Quality Feedback and Support

**User Story:** As a product team, I want to know how the app performs in the field and hear from users, so that I can fix problems fast and improve usability.

#### Acceptance Criteria

1. WHEN the app crashes or errors occur THEN the System SHALL record diagnostics locally, without patient data, and send them when connectivity returns.
2. WHEN usage analytics are collected THEN the System SHALL collect only anonymised, minimal metrics (feature use, time on task, error rates, sync success) with transparency to workers.
3. WHEN an ASHA needs help THEN the System SHALL provide in-app help with voice, a toll-free helpline, and a "report a problem" action with optional voice note and screenshot (excluding patient data).
4. WHEN field teams review the field experience THEN the System SHALL provide an issue tracker view with metrics for time to resolution.
5. WHEN a new feature is released THEN the System SHALL support staged rollout, feature flags and A/B-safe pilots limited to non-clinical aspects.
6. WHEN the System is evaluated THEN it SHALL track adoption, retention, time saved versus paper, data completeness and timeliness, and referral completion rates against baselines.

### Requirement 52: Model Evaluation and Dataset Pipeline

**User Story:** As an ML engineer, I want a pipeline to evaluate and improve speech and triage components using appropriate datasets, so that quality is measurable and bias is controlled.

#### Acceptance Criteria

1. WHEN evaluating speech recognition THEN the System SHALL maintain a benchmark per language and dialect, using public datasets (such as IndicVoices) and field-collected, consented recordings of the clinical vocabulary, on target low-end devices.
2. WHEN evaluating triage THEN the System SHALL use clinician-labelled case sets, guideline-derived test cases and, where permitted, retrospective field data, and use national surveys (NFHS-5, HMIS) for prevalence checks and scenario realism.
3. WHEN training or fine-tuning is done THEN the System SHALL document data provenance, licences, consent and limitations of each dataset.
4. WHEN a model is quantised or compressed THEN the System SHALL re-run accuracy, latency, memory and battery tests on reference devices.
5. WHEN performance differs across languages, regions, gender or age groups THEN the System SHALL report it and set minimum thresholds before release in that group.
6. WHEN field data is collected for improvement THEN the System SHALL honour consent and de-identification requirements of Requirement 44.

---

### Part 11: Compensation and Incentives (Final Functional Module)

### Requirement 53: Incentive Task Catalogue and Rate Configuration

**User Story:** As a state administrator, I want to configure the incentive categories and rates for my state, so that the system reflects actual policy and changes in orders.

#### Acceptance Criteria

1. WHEN the System is deployed in a state THEN the System SHALL load a state-specific incentive catalogue (activities, rates, conditions, evidence required, claim windows) and SHALL NOT hardcode any rate **[VALIDATE against current NHM state orders]**.
2. WHEN an order changes rates or conditions THEN the System SHALL allow an authorised admin to publish a new effective-dated version and keep prior versions for historical claims.
3. WHEN a task type supports fixed and variable components (fixed honorarium, performance-based incentive, state top-up, connectivity allowance) THEN the System SHALL represent each separately.
4. WHEN a catalogue is viewed by an ASHA THEN the System SHALL show, in her language and with audio, what each task pays and what proof is needed.

### Requirement 54: Automatic Incentive Event Logging and Eligibility

**User Story:** As an ASHA, I want every task I complete to be counted towards my incentives automatically, so that I do not forget to claim or need to prove it twice.

#### Acceptance Criteria

1. WHEN a visit, service, escort, registration, follow-up or programme milestone that matches a catalogue item is completed and meets its conditions THEN the System SHALL log an incentive-eligible event linked to the underlying clinical record.
2. WHEN a task is only partially complete (for example, 3 of 5 HBNC visits done) THEN the System SHALL show progress and what remains to become eligible.
3. WHEN conditions depend on later events (for example, full immunization by age one, delivery outcome, treatment completion) THEN the System SHALL track the pending condition and mark eligibility only when satisfied.
4. WHEN a task is not eligible THEN the System SHALL tell her the reason in plain language.
5. WHEN a facility records an external event (institutional delivery confirmed, case confirmed in Ni-kshay) THEN the System SHALL use it as verification evidence where policy allows.
6. WHEN an event might be claimed twice THEN the System SHALL prevent duplicate eligibility for the same beneficiary and task.

### Requirement 55: Earnings Dashboard and Transparency

**User Story:** As an ASHA, I want to see what I have earned, what is pending and why, so that I can plan my household budget and trust the process.

#### Acceptance Criteria

1. WHEN the ASHA opens the earnings view THEN the System SHALL show this month's eligible, claimed, verified, approved, paid, and rejected amounts, with the breakdown per task.
2. WHEN a claim is delayed or rejected THEN the System SHALL show the stage it is stuck at, the reason and the person responsible for the next step.
3. WHEN payment is made THEN the System SHALL show the date and the reference, and reconcile it against claimed amounts.
4. WHEN she wants to estimate THEN the System SHALL show a projection of this month's earnings if pending tasks are completed.
5. WHEN history is requested THEN the System SHALL show previous months and years, and allow a printable statement (for example, for a bank or loan).
6. WHEN earnings data is shown THEN the System SHALL display it in her language with audio and simple visuals, and keep it private from other household members using the device lock.

### Requirement 56: Claim Voucher Generation, Verification and Submission

**User Story:** As an ASHA, I want my monthly claim voucher created for me and verified quickly, so that I am paid on time without paperwork.

#### Acceptance Criteria

1. WHEN the claim period closes or the ASHA requests it THEN the System SHALL generate the claim voucher automatically in the state's official format as a printable PDF and a digital submission, listing each task, beneficiary reference (privacy-protected), date, amount and evidence link.
2. WHEN the voucher is submitted THEN the System SHALL route it to the ANM or AF for verification, with the underlying records available to confirm each line.
3. WHEN a verifier reviews a claim THEN the System SHALL let them approve, reject or request correction per line item with a required reason, with sampling-based verification where policy permits.
4. WHEN a claim is rejected THEN the System SHALL tell the ASHA what to fix and let her resubmit, with the rejection categories captured for analysis.
5. WHEN verification completes THEN the System SHALL forward approved claims to the payment system (ASHA Soft, PFMS/DBT or the state equivalent) through an API where available, or as a state-format export file and a guided data-entry aid.
6. WHEN a verifier or the BPMU reviews the claim backlog THEN the System SHALL show ageing, bottlenecks and reasons by block and facility.
7. WHEN voucher data is shared THEN the System SHALL include only the minimum beneficiary information necessary.

### Requirement 57: Payment Tracking, Bank Details and Dispute Resolution

**User Story:** As an ASHA, I want my payment details validated and any dispute followed up, so that mismatches do not delay my money for months.

#### Acceptance Criteria

1. WHEN bank and identity details are captured THEN the System SHALL validate the format, flag likely mismatches (name, Aadhaar-seeding, IFSC, account status) before the payment cycle, and let the ASHA or ANM correct them in time.
2. WHEN a payment is rejected by the bank or PFMS THEN the System SHALL surface the failure reason to the ASHA and her facilitator, with the correction steps.
3. WHEN an ASHA believes an amount is wrong or missing THEN the System SHALL provide a dispute workflow with evidence from her event log, an assigned owner, status and a service-level due date, and escalation if not met.
4. WHEN payments are delayed beyond a configured threshold THEN the System SHALL alert the block and district officers and include the delay in their dashboards.
5. WHEN auditors review payments THEN the System SHALL provide a reconciliation report (events, claims, approvals, payments) with the audit trail described in Requirement 33.
6. WHEN the System cannot resolve a matter that is a policy problem rather than a technical one (rates, employment status, minimum wage) THEN the System SHALL record it as an aggregated issue for programme leadership instead of presenting it as a technical fault.

---

## Out of Scope: Problems Technology Cannot Solve

These issues surfaced in the research and are recorded so the product does not pretend to address them:

1. The employment classification of ASHAs (volunteer versus worker) and minimum-wage entitlement.
2. The baseline level of incentives and honorarium set by central and state governments.
3. Physical exhaustion from long travel between remote hamlets.
4. Supply-chain logistics for physical devices, batteries and consumables (the System can detect and report these but cannot deliver them).
5. Shortages of health-facility capacity and referral transport.

## Open Questions for Field Validation

1. What is the actual reason for most claim voucher rejections at the PHC sector meeting?
2. In which hours does an ASHA have uninterrupted access to her phone?
3. How long do state-supplied devices stay functional and calibrated?
4. Which government applications does she currently use, and which does she actually trust?
5. What do ANMs and doctors need in a referral note to act without calling back?
6. Which local words does the ASHA use for each symptom, per district and dialect?
7. Which exact incentive categories, rates and proof requirements apply in the pilot state today?
