# Requirements Document

## Introduction

The ASHA Digital Platform is an offline-first, mobile-first health-information system designed to support ASHA (Accredited Social Health Activist) workers, their supervisors, and the facility staff who act on their data. It covers the full scope of an ASHA's working life: household and beneficiary records, maternal-newborn-child and NCD care, TB and communicable disease, visit scheduling, Bluetooth device integration, training and supervision, interoperability with government health systems, and incentive tracking and payment.

The platform is built for deployment in rural and peri-urban India where network connectivity is intermittent, devices are low-end and often shared, and the primary user may have modest literacy and prefer voice interaction in a regional language.

### Primary users

- **ASHA** — village-level female community health worker; primary mobile-app user in the field
- **ASHA Facilitator (AF)** — supervisor of 10–20 ASHAs; uses supervisory dashboard on mobile or tablet
- **ANM / CHO** — sub-centre or HWC clinician; uses a tablet or laptop workspace
- **PHC Medical Officer** — reviews referrals and area health data on the web dashboard
- **Block / District / State officers** — programme monitoring and analytics on the web dashboard
- **State Administrator** — configures the system (forms, rules, incentive catalogues, languages) without code changes
- **Auditor** — read-only access to audit trails and reconciliation reports

### Design principles

1. **Offline first.** Every field workflow completes with zero connectivity. Sync is background and non-blocking.
2. **Decision support, not diagnosis.** ASHAs screen, triage and refer. The system suggests; the ASHA decides.
3. **Remove the double burden.** Data is entered once; paper-compatible outputs and government-portal exports are generated from it.
4. **Low-end, shared phones.** Base APK under 50 MB; responsive on 2 GB RAM Android; no persistent background services; shared-device-safe privacy.
5. **Voice and icon first.** Designed for modest literacy and 12 regional languages with audio prompts on every screen.
6. **Worker trust.** No punitive surveillance. The ASHA sees the same performance data her supervisor sees. Earnings are transparent.
7. **Configurable by state.** Incentive rates, forms, languages and clinical protocols are configuration, not code.

### Technology decisions (already agreed)

| Concern | Choice |
|---|---|
| Mobile app | Flutter 3.x (Dart) |
| Local storage | SQLite via drift ORM + SQLCipher AES-256 encryption |
| Sync engine | Custom delta-sync over HTTPS REST — BitChat-style priority queue, gzip, resume-on-reconnect |
| Backend | FastAPI (Python 3.12) + PostgreSQL 16 |
| Web dashboards | React 18 + TypeScript + TailwindCSS |
| On-device ASR | Vosk (offline; 40 MB Hindi model + optional Indic language downloads) |
| Clinical term mapping | Custom lexicon layer over Vosk output |
| Text-to-speech | flutter_tts (on-device) |
| Authentication | JWT + bcrypt, offline-capable |
| BLE devices | flutter_reactive_ble |
| FHIR | fhir Dart package + fhir_r4 Python |
| PDF generation | pdf Dart package |

Items marked **[VALIDATE]** depend on facts that must be confirmed against official NHM / MoHFW / NHSRC documents or field interviews before implementation.

---

## Glossary

- **ASHA**: Accredited Social Health Activist — a village-level female community health worker selected and trained under the National Health Mission.
- **ASHA Facilitator (AF)**: Supervisor of roughly 10–20 ASHAs at the sector level.
- **ANM**: Auxiliary Nurse Midwife — posted at the sub-centre or Health and Wellness Centre.
- **CHO**: Community Health Officer at the Health and Wellness Centre.
- **AWW**: Anganwadi Worker — ICDS nutrition programme frontline worker.
- **PHC / CHC**: Primary Health Centre / Community Health Centre.
- **MO**: Medical Officer at the PHC or higher facility.
- **BPMU**: Block Program Management Unit.
- **HBNC**: Home Based Newborn Care — structured home-visit protocol for the first 42 days of life.
- **HBYC**: Home Based Care for Young Child — structured visit protocol from 42 days to 15 months.
- **IMNCI**: Integrated Management of Neonatal and Childhood Illness.
- **CBAC**: Community Based Assessment Checklist — NCD risk screening tool for persons aged 30 and above.
- **ANC**: Antenatal Care.
- **PNC**: Postnatal Care.
- **VHSND**: Village Health, Sanitation and Nutrition Day — monthly community outreach session.
- **VHSNC**: Village Health, Sanitation and Nutrition Committee.
- **MCP card**: Mother and Child Protection card — official record kept by the mother.
- **ABDM**: Ayushman Bharat Digital Mission — national digital health infrastructure.
- **ABHA**: Ayushman Bharat Health Account — a unique digital health ID for every citizen.
- **FHIR**: Fast Healthcare Interoperability Resources (HL7 FHIR R4) — the data exchange standard used for ABDM.
- **CDSS**: Clinical Decision Support System.
- **SaMD**: Software as a Medical Device — regulatory classification under CDSCO Medical Devices Rules.
- **DPDP**: Digital Personal Data Protection Act, 2023 — India's data-privacy law.
- **PFMS**: Public Financial Management System — central government payment platform.
- **DBT**: Direct Benefit Transfer.
- **NRC**: Nutrition Rehabilitation Centre.
- **RBSK / DEIC**: Rashtriya Bal Swasthya Karyakram / District Early Intervention Centre — child health screening programme.
- **RDT**: Rapid Diagnostic Test (context: malaria blood test).
- **WIFS**: Weekly Iron and Folic acid Supplementation — adolescent anaemia programme.
- **IFA**: Iron and Folic Acid supplement.
- **MUAC**: Mid-Upper Arm Circumference — anthropometric measure for malnutrition screening.
- **MAM**: Moderate Acute Malnutrition.
- **SAM**: Severe Acute Malnutrition.
- **KMC**: Kangaroo Mother Care — skin-to-skin warmth for low-birth-weight newborns.
- **LBW**: Low Birth Weight (< 2.5 kg).
- **LMP / EDD**: Last Menstrual Period / Expected Date of Delivery.
- **AEFI**: Adverse Event Following Immunization.
- **U-WIN**: Union-level Immunization Information System.
- **Ni-kshay**: National TB Information System.
- **HMIS**: Health Management Information System.
- **POSHAN Tracker**: National Nutrition Mission monitoring platform.
- **ASR**: Automatic Speech Recognition.
- **TTS**: Text-to-Speech.
- **BLE**: Bluetooth Low Energy.
- **GATT**: Generic Attribute Profile — BLE data protocol.
- **FTS**: Full-Text Search.
- **OTA**: Over-The-Air update.
- **The System**: The ASHA mobile app (Flutter), the sync backend (FastAPI), and the web dashboards (React), unless a requirement names a specific component.
- **The App**: The Flutter mobile application only.
- **The Backend**: The FastAPI + PostgreSQL service only.
- **The Dashboard**: The React web application only.
- **Local_Store**: The on-device SQLite database encrypted with SQLCipher.
- **Sync_Engine**: The BitChat-style delta-sync queue that transfers data between the App and the Backend.
- **Triage_Engine**: The on-device deterministic rule evaluator that produces Red/Yellow/Green flags.
- **Vosk_ASR**: The on-device Vosk speech-recognition engine.
- **Lexicon**: The configurable mapping from colloquial and dialect symptom terms to standard clinical concepts.

---

## Requirements

---

## Part 1 — Platform Foundation

---

### Requirement 1: Offline-First Local Data Store

**User Story:** As an ASHA working in a hamlet with no network, I want every feature to work without internet, so that I never lose work or wait on a loading spinner.

#### Acceptance Criteria

1. WHEN the device has no network connectivity, THE App SHALL allow all field workflows — registration, visits, triage, referral creation, scheduling, and previously downloaded learning content — to complete normally, meaning: no connectivity error is surfaced to the ASHA, no workflow step requires a network-dependent action, and no interactive element becomes blocked or unresponsive.
2. WHEN the ASHA saves any record, THE App SHALL persist it to the Local_Store (SQLite + SQLCipher AES-256) before displaying a confirmation to the user.
3. WHEN the App is force-closed, crashes, or the device loses power mid-entry, THE App SHALL restore the in-progress form as a draft in the Local_Store — provided at least one field value had been entered before the interruption — and SHALL offer to resume it on the next launch; restoring the same draft a second time SHALL produce the same draft state as restoring it once, with no duplicate draft created.
4. WHEN a screen requires server data that is not present in the Local_Store, THE App SHALL show a visible on-screen offline-state indicator and an alternative action within 3 seconds, and SHALL NOT block the UI with a spinner for more than 3 seconds.
5. WHEN the device storage falls below a configurable low-storage threshold (default 200 MB free), THE App SHALL warn the ASHA, offer to clear cached data that has received a server-acknowledged sync confirmation and non-essential media (maps, video content), and SHALL NOT delete any record that lacks a server-acknowledged sync confirmation.
6. THE Local_Store SHALL use drift ORM for schema management; after any App version upgrade, every record written by any prior version SHALL remain fully readable and intact, with no field values silently truncated, defaulted, or lost.

#### Property-Based Testing Notes

- **Round-trip invariant:** For any clinical record written to the Local_Store, `deserialise(serialise(record)) == record` for all field types (date, enum, numeric, text, nullable).
- **Idempotence:** Applying the same draft-recovery sequence twice to the Local_Store SHALL produce the same state as applying it once — no duplicate drafts.

---

### Requirement 2: Authentication, Roles and Shared-Device Safety

**User Story:** As an ASHA who shares her phone with family, I want my patient data protected behind a simple login, so that others cannot see or change beneficiary records.

#### Acceptance Criteria

1. WHEN the ASHA opens the App, THE App SHALL require authentication via a numeric PIN of 4 to 8 digits, a pattern, or a device biometric (fingerprint / face unlock) that operates entirely offline using locally stored, bcrypt-hashed credentials; IF biometric authentication fails 3 consecutive times, THEN THE App SHALL fall back to PIN or pattern entry.
2. WHEN a user has been idle beyond a configurable timeout period (default 2 minutes, configurable range 1–30 minutes), THE App SHALL lock the screen, hide all patient data, and remove the App's content from the Android recent-apps thumbnail.
3. WHEN a user account is provisioned, THE Backend SHALL assign exactly one of the following roles — ASHA, ASHA_Facilitator, ANM_CHO, PHC_MO, Block_District_Officer, State_Admin, or Auditor — and THE App SHALL enforce data access scoped to that role.
4. IF an incorrect PIN is entered a configurable number of consecutive times (default 5, configurable range 3–10), THEN THE App SHALL apply a lockout delay that starts at 30 seconds and doubles with each subsequent failed attempt up to a maximum of 10 minutes per delay; after the final allowed attempt THE App SHALL require re-verification via a one-time password valid for 10 minutes, which may require connectivity.
5. WHEN a device is reported lost or reassigned by an administrator, THE Backend SHALL invalidate the JWT refresh token, and THE App SHALL detect the revocation on its next sync and trigger a remote wipe of the Local_Store on that device.
6. WHEN an ASHA sets up the App on a new device, THE System SHALL restore her area data after she verifies her identity with her official ASHA ID and a one-time password valid for 10 minutes; subsequent offline logins SHALL use the locally stored hashed credential.
7. WHEN the session JWT expires while the user is offline, THE App SHALL maintain the session using a locally cached offline credential valid for up to 7 days from the last successful JWT refresh and SHALL refresh the JWT on the next server connection; IF the offline credential has exceeded 7 days without a successful JWT refresh, THEN THE App SHALL require the user to authenticate online before granting access.

---

### Requirement 3: Multilingual Low-Literacy Interface

**User Story:** As an ASHA with limited English and moderate education, I want the app in my own language with icons and audio, so that I can use it confidently without reading long text.

#### Acceptance Criteria

1. WHEN the App is first set up, THE App SHALL present a language picker offering at minimum: Hindi, Marathi, Bengali, Telugu, Malayalam, Tamil, Kannada, Odia, Gujarati, Punjabi, Assamese, and English; the selected language SHALL apply to all UI strings, audio prompts, and generated documents, and SHALL be changeable at any time without data loss.
2. WHEN a screen displays a clinical term (for example, "MUAC" or "jaundice"), THE App SHALL render the local-language term used in official ASHA training material alongside an icon or illustration where one exists.
3. WHEN a screen is displayed, THE App SHALL offer a tap-to-hear audio prompt that reads the screen's instructions aloud using flutter_tts or a bundled pre-recorded voice clip.
4. WHEN a data-entry form is shown, THE App SHALL present one question per screen by default, with touch targets of at least 48 × 48 dp, high-contrast colour ratios meeting WCAG AA, and no navigation hierarchy deeper than two levels.
5. WHEN a first-time user launches the App, THE App SHALL offer an offline guided walkthrough in the selected language covering the key workflows, and SHALL provide contextual inline help accessible from every screen.
6. WHEN a state or district administrator updates localisation strings or terminology, THE Backend SHALL deliver the updated content as an OTA string bundle; THE App SHALL apply it on next sync without requiring a new APK release.

---

### Requirement 4: Household and Beneficiary Registry

**User Story:** As an ASHA, I want to register and see every household and member in my area, so that I always have a complete longitudinal record of the person in front of me.

#### Acceptance Criteria

1. WHEN the ASHA registers a household, THE App SHALL capture: village, hamlet/pada, head-of-household name, member list, age or date of birth, sex, relationships, social category (SC/ST/OBC/General), BPL status, and at least one contact detail; all fields except name and village SHALL be individually skippable.
2. WHEN a new beneficiary record is created, THE App SHALL generate a UUID v4 on the device and store it as the primary identifier, with no server round-trip required before saving.
3. WHEN a new beneficiary record is saved, THE App SHALL check existing records for potential duplicates using a configurable fuzzy-match score on name (phonetic and transliteration-tolerant), age, household, and phone number, and SHALL present a merge / link / continue prompt when a match exceeds the threshold.
4. WHEN the ASHA opens a beneficiary record, THE App SHALL show a reverse-chronological timeline of all visits, screenings, flags, referrals, immunizations and follow-ups for that person.
5. WHEN a life event (birth, death, migration, marriage, household transfer) is recorded, THE App SHALL capture the event with a timestamp, update household membership, and suppress future task generation for that person where applicable.
6. WHEN a beneficiary gives consent (see Requirement 5), THE App SHALL create or link an ABHA ID for that person; the ABHA linking SHALL work as offline capture + online verification as described in Requirement 36.
7. WHEN the ASHA uses the search function, THE App SHALL query the Local_Store via SQLite FTS5 and support lookup by: name (phonetic Soundex / transliteration variants), household, ABHA ID, RCH ID, phone number, and hamlet — all without network.
8. WHEN a household or beneficiary is shared between two ASHA areas (migration or boundary overlap), THE System SHALL support a hand-over workflow with a full audit trail recording the transferring worker, receiving worker, timestamp, and reason.

#### Property-Based Testing Notes

- **Duplicate-detection invariant:** For any two records with identical name, DOB, and household, the deduplication routine SHALL always return a match score above the configured threshold regardless of field order or Unicode normalisation form.
- **UUID uniqueness:** For any arbitrarily large batch of offline device-generated UUIDs, the collision probability SHALL conform to the UUID v4 birthday-paradox bounds (< 1 in 10¹⁵ for up to 10⁷ records).

---

### Requirement 5: Informed Consent Management

**User Story:** As a beneficiary, I want to understand and control how my health data is collected and shared, so that my privacy is respected.

#### Acceptance Criteria

1. WHEN personal health data is first collected from a beneficiary, THE App SHALL present a plain-language consent statement in the selected language, readable aloud via audio, covering: the purpose of data collection, which roles can view the data, and the beneficiary's right to withdraw at any time.
2. WHEN consent is given, THE App SHALL record a consent artifact in the Local_Store containing: timestamp, version identifier of the consent text, the ASHA's identifier as witness, and a tamper-evident signature (tap acknowledgment, thumbprint photo, or voice acknowledgment audio hash); the artifact SHALL be synced to the Backend on next connection.
3. IF a beneficiary declines consent, THEN THE App SHALL allow the ASHA to complete emergency triage and provide referral guidance while restricting storage to only what is legally permitted for public-health safety purposes, and SHALL NOT create a full longitudinal record.
4. WHEN a beneficiary withdraws consent, THE App SHALL flag the record, cease optional data sharing for that record, and propagate the withdrawal status to the Backend on next sync.
5. WHEN the beneficiary is a minor or an incapacitated person, THE App SHALL capture consent from the guardian and record the guardian's relationship to the beneficiary.
6. WHEN the consent text or data-use policy changes, THE App SHALL request re-consent from the affected beneficiary at the next relevant interaction.

#### Property-Based Testing Notes

- **Round-trip invariant:** `deserialise(serialise(consentArtifact)) == consentArtifact` — the tamper-evident signature value SHALL be preserved without truncation or character encoding loss across SQLite write-read cycles.

---

## Part 2 — Input and Output Modalities

---

### Requirement 6: Offline Voice Input

**User Story:** As an ASHA who finds typing slow and error-prone, I want to speak symptoms and measurements in my own language, so that data entry is fast and accurate.

#### Acceptance Criteria

1. WHEN the ASHA taps the microphone icon on any form field, THE App SHALL capture and transcribe speech entirely on the device using Vosk_ASR with no network call.
2. WHEN a field accepts a closed set of values (number, yes/no, date, enumerated choice), THE App SHALL use a Vosk grammar constraint (restricted vocabulary and FST-based grammar) and SHALL map spoken dialect variants and number words to the canonical stored value via the Lexicon.
3. WHEN Vosk_ASR returns a recognition result with a confidence score below a configurable threshold, THE App SHALL read the interpreted value back to the user in audio and text and SHALL require explicit confirmation before accepting it.
4. WHEN a free-text field (such as a clinical note or reason) is dictated, THE App SHALL transcribe it into the native script of the selected language and SHALL present a review-and-edit screen before saving.
5. WHEN the ambient noise level exceeds a configurable threshold (measured via device microphone RMS), THE App SHALL notify the ASHA of excessive noise and SHALL offer tap-based entry as an alternative.
6. WHEN the ASHA speaks a symptom or health term in colloquial or dialect form, THE App SHALL map it to the standard clinical concept using the configurable Lexicon layer over Vosk_ASR output.
7. WHEN the device has less than the minimum supported RAM for the full Vosk model, THE App SHALL automatically fall back to a smaller compressed Vosk model or tap-only entry, and SHALL remain fully usable in either fallback mode.
8. WHERE voice recordings are retained for model quality improvement, THE App SHALL do so only after explicit ASHA opt-in; in all other cases THE App SHALL discard the raw audio after Vosk_ASR completes transcription.
9. WHEN a new language or dialect Vosk model is released, THE App SHALL deliver it as an optional, independently downloadable bundle; the ASHA SHALL be able to install and remove models without an APK update.

#### Property-Based Testing Notes

- **Round-trip invariant:** For any canonical clinical value (number, enumeration, date) in the Lexicon, `canonicalise(Lexicon.lookup(voiceVariant(value))) == value` — the voice → canonical mapping SHALL be a left-inverse of the display label.
- **Idempotence:** Applying the Lexicon normalisation function twice to the same string SHALL produce the same output as applying it once.

---

### Requirement 7: Audio Output and Voice Guidance

**User Story:** As an ASHA who is more comfortable listening than reading, I want the app to speak instructions and results, so that I understand triage outcomes and next steps immediately.

#### Acceptance Criteria

1. WHEN a triage result is displayed, THE App SHALL speak the colour (red / yellow / green), the primary triggering reason, and the recommended action in the selected language using flutter_tts or a pre-recorded human voice clip.
2. WHEN the ASHA initiates a clinical procedure (breath counting, MUAC measurement, ORS preparation), THE App SHALL offer a step-by-step audio guidance sequence that advances manually or on a timer.
3. WHEN audio is played, THE App SHALL use a bundled pre-recorded human voice clip where available for the selected language, and SHALL fall back to flutter_tts on-device synthesis otherwise.
4. WHEN the ASHA needs to explain a triage result or health message to a family member, THE App SHALL offer a family-facing audio and pictorial explanation in the selected language, distinct from the clinician-facing text.

---

## Part 3 — Clinical Decision Support

---

### Requirement 8: On-Device Triage Engine

**User Story:** As an ASHA, I want instant triage from symptoms and vitals without any network, so that I know whether to refer urgently, monitor, or reassure.

#### Acceptance Criteria

1. WHEN the ASHA explicitly submits a clinical assessment by tapping the designated confirm/submit control, THE Triage_Engine SHALL compute a Red, Yellow, or Green flag on the device within 1 second of that action and SHALL NOT make any network call to do so.
2. WHEN a flag is produced, THE App SHALL display each rule that triggered it as a self-contained sentence stating the finding, the measured value, and the action (example: "Breathing rate 62/min in an infant under 2 months — refer now"), alongside the data values used, in the selected language.
3. WHEN multiple rules fire simultaneously, THE Triage_Engine SHALL return the highest severity flag and list all contributing findings; no individual rule result SHALL be suppressed.
4. WHEN one or more required inputs are absent, THE Triage_Engine SHALL prompt the ASHA for each missing value before computing a result; IF the ASHA proceeds without supplying all required inputs, THEN THE Triage_Engine SHALL compute the flag using available data and escalate the result by one severity level, capping at Red, and SHALL explicitly list each missing item alongside the result.
5. WHEN the triage outcome is Red, THE App SHALL automatically open the referral workflow (see Requirement 10) and display the facility whose care level matches the clinical flag and whose road distance from the ASHA's registered area is shortest among qualifying facilities in the offline facility directory, together with available transport options and emergency contact numbers stored in that directory.
6. WHEN the ASHA disagrees with the Triage_Engine's suggestion, THE App SHALL allow her to override the severity level (upward or downward), SHALL require a reason of between 10 and 500 characters entered as free-text or recorded as a voice note, and SHALL record both the engine's original output and the override — including the reason — in the encounter record.
7. WHEN presenting any triage result, THE App SHALL label it with a prominent disclaimer that it is clinical decision support requiring ASHA judgment, and SHALL NOT use the words "diagnosis" or "prescription" in any language.
8. WHEN the same inputs and the same rule-set version are evaluated, THE Triage_Engine SHALL always produce the same output — the engine is deterministic with no random or time-dependent behaviour.
9. WHERE an ML inference component is incorporated alongside the rule engine, THE Triage_Engine SHALL ensure the ML component can only raise the severity relative to the rule-based output and never lower it, and SHALL display the ML contribution as a separately labelled item showing the specific input features and their relative weights that produced the ML severity score.

#### Property-Based Testing Notes

- **Determinism invariant:** For any (inputs, rule_version) pair, `evaluate(inputs, rule_version) == evaluate(inputs, rule_version)` when called any number of times.
- **Severity monotonicity (ML):** For any ML component output `ml_severity` and rule-based output `rule_severity`, `final_severity >= rule_severity` always holds.
- **Metamorphic — missing inputs:** Adding a normal value for a previously missing input SHALL never increase the severity flag; adding an abnormal value SHALL never decrease it.
- **Error conditions:** Malformed or out-of-physiological-range inputs SHALL produce a conservative flag with an explicit "input error" annotation rather than a crash or silent normal result.

---

### Requirement 9: Clinical Rule Authoring, Versioning and Governance

**User Story:** As a clinical lead, I want triage rules stored as reviewable, versioned decision tables, so that doctors can verify them and updates are safe.

#### Acceptance Criteria

1. WHEN rules are defined, THE Backend SHALL store them as structured, human-readable JSON decision tables with mandatory source citations (IMNCI, HBNC, HBYC, MoHFW guideline title and page number) and SHALL reject rule entries with missing source references.
2. WHEN a rule set is modified, THE Backend SHALL require that a clinician with the Clinical_Lead role reviews and digitally approves the change; THE System SHALL version the rule set (semantic version string) and retain the full change history immutably.
3. WHEN a new approved rule version is published, THE Backend SHALL package it as a signed OTA bundle; THE App SHALL apply the new rule set only after the full bundle has been downloaded and its integrity hash verified, and SHALL keep the previous version for rollback.
4. WHEN an encounter is recorded, THE App SHALL store the active rule-set version identifier with the encounter so the triage result can be reproduced from the archived rule version.
5. WHEN a rule set is prepared for release, THE System SHALL run the embedded automated test suite (input → expected flag mappings) and SHALL block release if any test case fails.
6. WHEN a state has protocol variations, THE Backend SHALL support state-specific overlay rules on a national base rule set; overlays SHALL be additive or restrictive, never destructive of the base.
7. WHEN a proposed rule change would lower the expected severity of any existing automated test case, THE System SHALL flag it for explicit additional clinical sign-off by a second clinician before release.

#### Property-Based Testing Notes

- **Round-trip invariant:** `deserialise(serialise(ruleSet)) == ruleSet` — JSON serialisation of a rule set SHALL preserve all fields, operators, and threshold values without numeric precision loss.
- **Test-suite completeness invariant:** For every leaf branch in the decision table, at least one automated test case SHALL exist (coverage enforced at publish time).

---

### Requirement 10: Referral Notes and Referral Lifecycle

**User Story:** As an ASHA, I want to generate a clear referral note and know what happened to the patient afterwards, so that the PHC doctor can act without calling me and I can close the loop.

#### Acceptance Criteria

1. WHEN a referral is created, THE App SHALL generate a structured referral note containing: patient identifiers, age and sex, key symptoms and vitals, triage flag with triggering reasons, actions already taken by the ASHA, date and time, and the ASHA's name and phone number — formatted so the receiving doctor can read and act on it in under 30 seconds.
2. WHEN a referral note is generated offline, THE App SHALL make it immediately available to share as: a PDF (pdf Dart package), an image, an SMS text summary, a QR code, and a WhatsApp message; the PDF SHALL also be print-ready on thermal and standard printers.
3. WHEN the ASHA selects a referral destination, THE App SHALL propose the appropriate facility level (Sub-Centre/HWC, PHC, CHC, District Hospital, higher centre) based on triage severity, and SHALL show distance and available services from a locally cached facility directory.
4. WHEN a referral record syncs to the Backend, THE Backend SHALL push a notification to the receiving facility's Dashboard and to the supervising ANM and AF, with Red referrals marked for immediate attention.
5. WHEN a facility staff member records a referral outcome (arrived / treated / admitted / discharged / did not reach) via the Dashboard, THE Backend SHALL sync the outcome to the originating ASHA's device and append it to the beneficiary timeline.
6. WHEN a referred patient has not reached the destination facility within a configurable window, THE App SHALL create an overdue follow-up task for the ASHA and THE Backend SHALL generate an alert for the AF.
7. WHEN a referral note is generated, THE App SHALL render it in the ASHA's selected language, and SHALL offer an optional English version for the receiving clinical staff.
8. WHEN emergency transport is needed, THE App SHALL present a one-tap dial action for 108 (ambulance) and 102 (obstetric transport), plus locally configured transport and emergency contacts, available offline.

---

## Part 4 — Health Programs and Care Pathways

---

### Requirement 11: General Sick Child and Adult Danger-Sign Assessment

**User Story:** As an ASHA, I want a guided danger-sign check for any sick child or adult I meet, so that I do not miss urgent conditions even when the visit was not planned.

#### Acceptance Criteria

1. WHEN the ASHA starts an unscheduled assessment, THE App SHALL ask for the patient's age first and SHALL load the matching ASHA-scope protocol: young infant (0–2 months), child (2 months–5 years), adolescent, adult, or pregnant woman.
2. WHEN the loaded protocol covers cough/breathing, diarrhoea, fever, feeding problems, or malnutrition signs, THE App SHALL present IMNCI/HBYC-aligned questions and observations and SHALL not surface clinical steps outside ASHA scope.
3. WHEN a respiratory rate measurement is required, THE App SHALL launch the built-in breath counter (Requirement 29) and apply the age-appropriate fast-breathing threshold to classify the result.
4. WHEN a general danger sign is recorded (convulsions, inability to drink/breastfeed, vomiting everything, lethargy, or unconsciousness), THE Triage_Engine SHALL produce a Red flag immediately without waiting for the full assessment to complete.
5. WHEN the assessment indicates first-aid or home-care actions within ASHA scope (ORS, zinc, keeping warm, continued breastfeeding), THE App SHALL display them and SHALL NOT suggest clinical interventions outside ASHA scope.
6. WHEN a symptom pattern (number and similarity of cases in the same hamlet within a configurable time window) meets a surveillance threshold, THE App SHALL raise an outbreak surveillance prompt and pre-populate the notifiable disease report (Requirement 21).

---

### Requirement 12: Home Based Newborn Care (HBNC)

**User Story:** As an ASHA, I want a guided newborn visit flow with the correct visit schedule, so that every newborn is assessed on time and danger signs are caught early.

#### Acceptance Criteria

1. WHEN a delivery is recorded, THE App SHALL generate the HBNC visit schedule based on place of delivery and birth weight, including the additional visits prescribed for low-birth-weight or sick newborns **[VALIDATE against current NHSRC HBNC guidelines]**.
2. WHEN an HBNC visit is started, THE App SHALL guide the ASHA through the complete checklist: breastfeeding and feeding, weight, temperature, breathing rate, cord care, skin condition, eye condition, activity level, jaundice, hygiene, thermal care, and maternal postpartum status.
3. WHEN any newborn danger sign is entered during an HBNC visit, THE Triage_Engine SHALL produce a Red flag and THE App SHALL open the referral workflow.
4. WHEN a baby is low birth weight (< 2.5 kg) or preterm, THE App SHALL enrol the newborn in a high-risk follow-up pathway with additional visits and SHALL present Kangaroo Mother Care guidance on each relevant visit screen.
5. WHEN a scheduled HBNC visit is not completed within its permitted window, THE App SHALL mark it as overdue, reschedule within the allowed rescheduling window, and notify the AF if the rescheduled window also lapses.
6. WHEN a newborn or maternal death occurs, THE App SHALL capture the data fields required for maternal/child death review and SHALL generate an alert to the AF, ANM, and MO via the Backend on next sync.
7. WHEN all required HBNC visits are completed, THE App SHALL mark the HBNC episode as complete and generate an incentive-eligible event record (Requirement 54).

---

### Requirement 13: Home Based Care for Young Child (HBYC) and Child Development

**User Story:** As an ASHA, I want to follow children through the first 15 months with developmental checks and counselling, so that growth and feeding problems are spotted early.

#### Acceptance Criteria

1. WHEN an infant reaches the HBYC visit age points (3, 6, 9, 12, and 15 months), THE App SHALL schedule the corresponding visit and add it to the due list **[VALIDATE exact visit ages and checklist items against current NHSRC HBYC guidelines]**.
2. WHEN an HBYC visit is conducted, THE App SHALL record: current feeding practices, complementary feeding introduction, immunization status, growth measurements, developmental milestone assessment, illness in the interval, and responsive-caregiving counselling given.
3. WHEN developmental milestone delays are recorded, THE App SHALL suggest referral to the appropriate service (Anganwadi/AWW, RBSK/DEIC, PHC) with the reason pre-populated in the referral note.
4. WHEN the child shows signs of severe acute malnutrition at an HBYC visit, THE App SHALL trigger the nutrition pathway (Requirement 17) automatically.
5. WHEN counselling messages are needed for the caregiver, THE App SHALL display short pictorial storyboard cards and play audio messages in the selected language.

---

### Requirement 14: Pregnancy Registration, ANC and High-Risk Pregnancy

**User Story:** As an ASHA, I want to register every pregnant woman early and track her antenatal care, so that complications are identified and she delivers safely.

#### Acceptance Criteria

1. WHEN a pregnancy is registered, THE App SHALL capture: LMP, calculated EDD, obstetric history (gravida, para, previous complications, previous caesarean, stillbirths), and SHALL link the woman to her MCP card and RCH/ABHA identifiers.
2. WHEN a pregnancy is registered, THE App SHALL generate the complete ANC schedule — contacts, TT/Td doses, IFA and calcium supplementation, ultrasound, and lab tests — and SHALL add each item to the due list.
3. WHEN any of the following are recorded — BP above threshold, haemoglobin below threshold, age below 18 or above 35, parity ≥ 4, history of previous complications or caesarean, vaginal bleeding, oedema, severe headache, or reduced fetal movement — THE Triage_Engine SHALL evaluate high-risk criteria against national guidelines and SHALL flag the pregnancy as high-risk with the specific reasons shown **[VALIDATE exact thresholds]**.
4. WHEN a pregnancy is flagged high-risk, THE App SHALL increase the scheduled visit frequency, and THE Backend SHALL generate alerts to the ANM and AF on next sync.
5. WHEN the calculated gestation reaches 34 weeks, THE App SHALL prompt the ASHA to complete a birth plan record: chosen delivery facility, transport arrangement, named escort, identified blood donor, savings status, and emergency contacts.
6. WHEN a scheduled ANC contact passes its due date without a recorded visit, THE App SHALL mark it overdue and add a priority follow-up task to the ASHA's due list.
7. WHEN a pregnancy ends (delivery, abortion, miscarriage, stillbirth, or maternal death), THE App SHALL record the outcome with the relevant details and SHALL trigger the appropriate downstream pathway: PNC (Requirement 15), HBNC (Requirement 12), or death review (Requirement 23).

---

### Requirement 15: Delivery, Postnatal Care and Maternal Follow-up

**User Story:** As an ASHA, I want to support the mother through delivery and the postpartum period, so that maternal complications and newborn issues are addressed quickly.

#### Acceptance Criteria

1. WHEN a woman is at or near term or goes into labour, THE App SHALL present a one-tap contact screen showing the delivery facility, ambulance (108/102), and the planned escort from the birth plan.
2. WHEN a delivery is recorded, THE App SHALL capture: place of delivery (home/facility/in-transit), delivery type (normal/instrumental/caesarean), attendant, date and time, outcome (live birth/stillbirth/maternal death), newborn sex and birth weight; and SHALL create the newborn record linked to the mother.
3. WHEN a PNC visit is due, THE App SHALL guide the ASHA through the postpartum checklist: bleeding amount, fever, blood pressure, breast problems, wound healing, mood indicators, nutrition, and contraception counselling offer.
4. WHEN any maternal danger sign is recorded (heavy bleeding, fever above threshold, convulsions, severe headache, foul-smelling discharge), THE Triage_Engine SHALL produce a Red flag and THE App SHALL open the referral workflow.
5. WHEN indicators of postpartum depression are recorded, THE App SHALL present a supportive counselling pathway and a referral option to mental health services per current MoHFW guidance.
6. WHEN an institutional delivery is confirmed, THE App SHALL create an incentive-eligible event record for the facilitated institutional delivery escort incentive (Requirement 54).

---

### Requirement 16: Immunization

**User Story:** As an ASHA, I want to see which children and women are due or overdue for vaccines, so that coverage is complete and no child is missed.

#### Acceptance Criteria

1. WHEN a child is registered, THE App SHALL generate the complete national immunization schedule from the date of birth and SHALL show each dose's due window in the due list.
2. WHEN a vaccine dose is administered at a session, THE App SHALL record: vaccine name, date administered, body site, and batch number (if provided by the ANM); and SHALL update the child's immunization-card view in the beneficiary record.
3. WHEN a child is overdue for a scheduled dose or is identified as a defaulter, THE App SHALL list them in the due list with the reason for missing (if recorded) and SHALL display the applicable catch-up schedule.
4. WHEN a VHSND or immunization session is planned, THE App SHALL generate the due-beneficiary list for that session and a mobilisation checklist (see Requirement 27).
5. WHEN the ANM records vaccinations in U-WIN, THE System SHALL accept vaccination status through an import or reconciliation mechanism to avoid duplicate ASHA entry (see Requirement 35).
6. WHEN an AEFI is reported, THE App SHALL capture the symptoms, timing, and severity; THE Triage_Engine SHALL flag urgent AEFI cases Red; and THE Backend SHALL notify the ANM and MO on next sync.
7. WHEN a pregnant woman is registered, THE App SHALL include her TT/Td schedule in her ANC due list.

---

### Requirement 17: Child Growth, Nutrition and Malnutrition

**User Story:** As an ASHA, I want to track growth and spot malnourished children early, so that they get treatment before complications arise.

#### Acceptance Criteria

1. WHEN weight, height/length, or MUAC is entered, THE App SHALL classify nutritional status offline against WHO child growth standards embedded in the App (normal, MAM, SAM, stunting, underweight) and SHALL plot the measurement on a growth chart.
2. WHEN the recorded MUAC or weight-for-height Z-score indicates SAM, or when bilateral oedema or appetite failure is present, THE Triage_Engine SHALL produce a Red flag and THE App SHALL recommend referral to the nearest NRC or facility.
3. WHEN MAM is identified, THE Triage_Engine SHALL produce a Yellow flag; THE App SHALL advise supplementary nutrition counselling and linkage to the Anganwadi centre, and SHALL schedule closer follow-up visits.
4. WHEN IFA, Vitamin A, or deworming are due per the national schedule, THE App SHALL add them to the due list and record administration with dose and date.
5. WHEN anaemia is suspected or a haemoglobin value is entered for a woman, adolescent, or child, THE App SHALL classify severity using the applicable WHO/national Hb threshold for that age/sex group and SHALL refer if the classification warrants it.
6. WHEN a child is enrolled in a malnutrition treatment programme, THE App SHALL track scheduled weekly or monthly follow-up visits and SHALL record exit-criteria outcomes (cured/defaulted/died/non-responder).
7. WHEN AWW or POSHAN Tracker data is available, THE System SHALL support bidirectional sharing of growth measurements in the format accepted by POSHAN Tracker (Requirement 35).

#### Property-Based Testing Notes

- **Invariant:** For any (weight, height, age, sex) input within plausible physiological bounds, the WHO Z-score formula SHALL produce the same classification regardless of the order in which the measurements are entered.
- **Metamorphic:** If weight increases and no other measurement changes, the weight-for-age Z-score SHALL not decrease.

---

### Requirement 18: Family Planning and Reproductive Health

**User Story:** As an ASHA, I want to counsel and track family planning for eligible couples, so that they can make informed choices and get supplies on time.

#### Acceptance Criteria

1. WHEN an eligible couple is identified during a household survey, THE App SHALL list them in the family-planning register with their current method (if any) and an unmet-need flag.
2. WHEN the ASHA counsels a couple on contraception, THE App SHALL present a method-comparison flow with pictorial and audio explanations of each option's effectiveness, eligibility criteria, and common side effects, limited to methods within ASHA distribution scope.
3. WHEN the ASHA distributes contraceptives (condoms, oral contraceptive pills, emergency contraceptive pills), THE App SHALL record the quantity, method, and recipient, deduct from the ASHA's stock (Requirement 30), and set a next-refill reminder.
4. WHEN a user reports a side effect or method failure, THE App SHALL guide the ASHA through the appropriate next steps and SHALL prompt referral to the ANM or facility if clinically indicated.
5. WHEN a woman is in the postpartum or post-abortion period, THE App SHALL prompt the ASHA to offer contraception counselling at the protocol-specified timing.
6. WHEN a sterilisation procedure or IUCD/injectable service is accessed at a facility and confirmed, THE App SHALL record the event and SHALL generate an incentive-eligible event record (Requirement 54).
7. WHEN contraception or reproductive health data is displayed, THE App SHALL enforce stricter role-based visibility and SHALL omit contraception details from any shared-household or supervisor-facing view unless the viewing role has explicit access.

---

### Requirement 19: NCD Screening with CBAC

**User Story:** As an ASHA, I want to screen adults for hypertension, diabetes and common cancers using CBAC, so that high-risk people are referred and treatment is followed up.

#### Acceptance Criteria

1. WHEN the ASHA screens a person aged 30 or above, THE App SHALL present the CBAC questionnaire, compute the risk score offline using the official CBAC scoring rules, and indicate when the score crosses the threshold requiring facility confirmation **[VALIDATE exact scoring algorithm and age-band cut-offs against current NHM CBAC tool]**.
2. WHEN a blood pressure or blood glucose reading is entered or received from a Bluetooth device, THE App SHALL classify it per current national NCD management guidelines and SHALL produce a Yellow or Red flag as appropriate.
3. WHEN symptoms suggestive of oral, breast, or cervical cancer are recorded, THE App SHALL flag the case for referral to confirmatory screening, create a follow-up task, and track completion of the referral outcome.
4. WHEN a person is confirmed to have hypertension or diabetes, THE App SHALL enrol them in a follow-up register, schedule adherence check visits, add medication-refill reminders to the due list, and record repeat measurement results over time.
5. WHEN a confirmed NCD patient is overdue for a follow-up visit or has missed a scheduled facility visit, THE App SHALL add a tracing task to the ASHA's due list.
6. WHEN CBAC data is saved for a beneficiary, THE App SHALL offer an export in the format accepted by the national NCD application to avoid re-entry (Requirement 35).
7. WHEN lifestyle counselling is appropriate, THE App SHALL provide short audio and pictorial messages on tobacco cessation, alcohol reduction, diet, salt intake, and physical activity.

---

### Requirement 20: Tuberculosis Support

**User Story:** As an ASHA, I want to identify TB suspects and support patients through treatment, so that cases are found early and treatment is completed.

#### Acceptance Criteria

1. WHEN a person presents with cough of two or more weeks' duration, unexplained fever, weight loss, night sweats, or other listed TB symptoms, THE Triage_Engine SHALL flag a presumptive TB case and THE App SHALL guide the ASHA to refer for testing.
2. WHEN a sputum sample is collected, THE App SHALL record the sample ID, collection date and site, and SHALL track transport status and result receipt.
3. WHEN a patient starts TB treatment, THE App SHALL register them in the TB follow-up pathway, record the treatment supporter's name and contact, and schedule dose-observation or adherence-check visits per the treatment regimen.
4. WHEN a dose observation visit occurs, THE App SHALL record whether the dose was observed as taken or missed; WHEN a configurable number of consecutive doses are missed, THE App SHALL alert the ASHA and THE Backend SHALL notify the designated TB programme staff.
5. WHEN household contacts of a confirmed TB case are identified, THE App SHALL list them for symptom screening and SHALL prompt preventive therapy assessment per current national guidelines.
6. WHEN a patient's diagnosis or treatment status is registered in Ni-kshay, THE System SHALL import or reconcile that status to avoid duplicate data entry (Requirement 35).
7. WHEN a TB patient has identified nutrition or social-support needs, THE App SHALL prompt linkage to the relevant government scheme and SHALL record the linkage outcome.
8. WHEN TB-related data is displayed on any screen, THE App SHALL apply stricter visibility controls — replacing TB labels with neutral terms in shared-device views — to protect the beneficiary from stigma.

---

### Requirement 21: Communicable Disease, Malaria and Outbreak Surveillance

**User Story:** As an ASHA, I want to report fever clusters and test for malaria where applicable, so that outbreaks are noticed early.

#### Acceptance Criteria

1. WHEN a fever case occurs in a malaria-endemic area, THE App SHALL guide the ASHA through RDT use, record the test result and species (P. falciparum / P. vivax / negative), and refer treatment per the state protocol **[VALIDATE endemic area mapping and treatment protocol]**.
2. WHEN the number of similar cases (fever, diarrhoea, rash, or other configured syndrome) in the same hamlet within a configurable time window exceeds a configurable threshold, THE App SHALL raise a local outbreak alert and THE Backend SHALL forward it to the ANM, AF, and MO on the next sync.
3. WHEN the ASHA records a vector-borne, waterborne, or other listed notifiable disease, THE App SHALL capture the minimum surveillance data fields required for IDSP reporting and route the record to the appropriate programme on sync.
4. WHEN an outbreak response is initiated by a supervisor, THE Backend SHALL push targeted response instructions and checklists to the affected ASHAs' devices and THE App SHALL present them at the top of the home screen.
5. WHEN seasonal risk periods apply (monsoon, dengue season, heat-wave alert), THE App SHALL display contextually timed awareness and action prompts on the home screen.
6. WHEN the ASHA records an animal bite, snake bite, poisoning, or injury, THE App SHALL display the protocol-appropriate first-aid steps within ASHA scope and SHALL prompt immediate referral with facility directions.

---

### Requirement 22: Other Health Programs and Life-Stage Coverage

**User Story:** As an ASHA, I want support for all the other tasks I am asked to do, so that I do not need a separate system for any part of my work.

#### Acceptance Criteria

1. WHEN adolescent health tasks apply, THE App SHALL support: an adolescent register, menstrual hygiene counselling, WIFS tablet distribution with stock decrement, and referral to adolescent-friendly services.
2. WHEN elderly, palliative, or bedridden patients are identified in the household survey, THE App SHALL create a home-care follow-up list with scheduled visit logs and a configurable visit interval.
3. WHEN the ASHA observes indicators of common mental health concerns (depression, anxiety, substance use, or suicide risk) within her screening scope, THE App SHALL provide a validated screening aid appropriate for ASHA use and SHALL present a referral pathway and helpline numbers (iCall, Vandrevala Foundation, 104, NIMHANS helpline).
4. WHEN a disability is identified in a household member, THE App SHALL support registration of the disability type and linkage to relevant government disability schemes and services.
5. WHEN a new national or state health programme is introduced, THE Backend SHALL allow a State_Admin to publish it as a configurable module (form, schedule, and rule definitions) and THE App SHALL load it on next sync without requiring an APK update.
6. WHEN the ASHA conducts a routine village activity (household survey, awareness session, sanitation drive, VHSNC meeting), THE App SHALL record the activity with date, participant count, and notes, and SHALL roll the data up to the AF dashboard.

---

### Requirement 23: Vital Events Registration

**User Story:** As an ASHA, I want to report births and deaths properly, so that records are complete and certificates and schemes follow.

#### Acceptance Criteria

1. WHEN a birth or death occurs in the ASHA's area, THE App SHALL capture the data fields required for civil registration (Civil Registration System format) and the health system, and SHALL generate a shareable summary for handover to the ANM or local authority.
2. WHEN a maternal, infant, or child death is entered, THE App SHALL capture the data fields required for the District Maternal Death Review or Child Death Review process and THE Backend SHALL generate an alert to the AF, ANM, and MO on next sync.
3. WHEN a stillbirth or abortion is recorded, THE App SHALL minimise mandatory fields, apply restricted visibility (limited to the ASHA, ANM, and MO), and use neutral language throughout the recording flow.
4. WHEN a vital event is saved, THE App SHALL update the household registry (adjusting membership counts and statuses) and SHALL cancel pending due-list tasks that are no longer applicable for the deceased or migrated person.

---

## Part 5 — Work Planning

---

### Requirement 24: Due List and Visit Scheduler

**User Story:** As an ASHA, I want a prioritised list of who I need to see today and this week, so that I open the app every morning and never miss a time-critical visit.

#### Acceptance Criteria

1. WHEN the App is opened, THE App SHALL display today's tasks grouped first by urgency (Red follow-ups, then overdue items, then due today, then upcoming) and within each urgency group by hamlet.
2. WHEN a pregnancy, delivery, birth, vaccination due date, lab test, or follow-up interval is recorded, THE App SHALL auto-generate the corresponding due and overdue tasks from configurable date rules — no manual scheduling by the ASHA is required.
3. WHEN the ASHA marks a task as completed, THE App SHALL remove it from the active due list and SHALL generate the next dependent task in the care pathway automatically.
4. WHEN the ASHA cannot complete a scheduled visit, THE App SHALL capture a skip reason from a defined list (not at home, refused, migrated, ASHA unwell, access problem, weather/road) and SHALL reschedule within the protocol's permitted rescheduling window.
5. WHEN the ASHA wants a broader view, THE App SHALL offer week and month calendar views and a programme-level coverage summary for her area.
6. WHEN the day's task count exceeds a configurable reasonable-workload threshold, THE App SHALL order remaining tasks by a combined score of clinical risk level and time-window expiry proximity, and SHALL display the prioritisation reason for each task.
7. WHEN the ASHA creates an ad hoc visit or unplanned task, THE App SHALL merge it into the due list at the appropriate urgency level.

---

### Requirement 25: Route and Hamlet Planning for Dispersed Areas

**User Story:** As an ASHA in a hilly or tribal area, I want my visits ordered to reduce walking, so that I spend more time with patients and less on the road.

#### Acceptance Criteria

1. WHEN the ASHA has multiple visits scheduled, THE App SHALL suggest an efficient hamlet-level visit order using household location data and a nearest-neighbour heuristic, computed offline on the device.
2. WHEN location data is used for route planning, THE App SHALL use it only if the ASHA has explicitly opted in to location features for that purpose, and SHALL NOT continuously track or log her GPS position.
3. WHEN the ASHA requests directions to a household or facility, THE App SHALL display an offline map or landmark-based sketch map using pre-downloaded regional tile data, and SHALL include locally entered landmarks.
4. WHEN a hamlet is remote, seasonal, or physically unreachable (floods, landslides, road conditions), THE App SHALL allow the ASHA to flag it with a reason, and SHALL adjust the scheduling to reflect the unavailability.
5. WHEN a supervisor requests a coverage analysis, THE App SHALL produce an aggregate, area-level view of hamlet visit frequency and access barriers — with the ASHA's consent — to support workload rebalancing.

---

### Requirement 26: Reminders and Beneficiary Communication

**User Story:** As an ASHA, I want reminders to reach me and my beneficiaries reliably, so that appointments and doses are not missed.

#### Acceptance Criteria

1. WHEN a task is due or overdue, THE App SHALL generate a local push notification on the device without any network connection, using the Android WorkManager scheduled notification framework.
2. WHEN a beneficiary has a phone number on record and has opted in to reminders, THE Backend SHALL send appointment and follow-up reminders via SMS or IVR in the beneficiary's language when connectivity is available; all messages SHALL avoid including sensitive health details.
3. WHEN the ASHA wants to contact a beneficiary's family, THE App SHALL provide template messages in the selected language and a one-tap action to initiate a call or send an SMS.
4. WHEN a beneficiary or family member acknowledges or replies to a reminder (on channels that support delivery receipts), THE App SHALL record the acknowledgement against the task.
5. WHEN notification volume is high, THE App SHALL batch notifications into a daily summary and SHALL respect a configurable quiet-hours window during which non-urgent alerts are suppressed.
6. WHEN the ASHA needs to contact her ANM, AF, or MO, THE App SHALL provide a one-tap call and one-tap message action from the beneficiary record, referral screen, or help screen.

---

### Requirement 27: VHSND, Community Mobilisation and Health Education

**User Story:** As an ASHA, I want help planning and recording village health days and community activities, so that sessions are well attended and documented.

#### Acceptance Criteria

1. WHEN a VHSND is scheduled, THE App SHALL generate: the list of due beneficiaries per service (immunization, ANC, CBAC, family planning), a mobilisation checklist, and a session-summary recording form.
2. WHEN a VHSND session occurs, THE App SHALL record attendance, services given per beneficiary, and service gaps, and SHALL update individual beneficiary records from the session data.
3. WHEN a VHSNC meeting or other community event is held, THE App SHALL log the date, participant count, decisions made, and agreed follow-up actions.
4. WHEN the ASHA needs health education material, THE App SHALL provide an offline library of short audio clips, illustrated messages, and video content, searchable by health topic.
5. WHEN a campaign is active (pulse polio, MDA, IFA week, TB active case-finding), THE App SHALL present the campaign's checklist, target beneficiary list, and reporting form.
6. WHEN community feedback or health concerns are collected at a session, THE App SHALL record them and route a summary to the AF and VHSNC on next sync.

---

## Part 6 — Devices and Tools

---

### Requirement 28: Bluetooth Device Integration with Manual Fallback

**User Story:** As an ASHA, I want my BP monitor, pulse oximeter, thermometer and similar devices to send readings straight into the app, so that I avoid transcription mistakes.

#### Acceptance Criteria

1. WHEN a supported BLE device is paired using flutter_reactive_ble, THE App SHALL receive readings from the device's GATT characteristic directly into the active form field and SHALL display the device identity and measurement timestamp.
2. WHEN a supported device is unavailable (unsupported model, out of battery, Bluetooth off, pairing failure), THE App SHALL offer immediate manual entry for the measurement with no loss of workflow progress.
3. WHEN a device reading is outside configurable plausible physiological bounds (per measurement type and patient age/sex), THE App SHALL prompt the ASHA to remeasure before saving and SHALL NOT auto-accept the out-of-range value.
4. WHEN a measurement is saved, THE App SHALL tag it with its source (BLE device ID or manual) for data quality and audit purposes.
5. WHEN a new device type is to be supported, THE System SHALL add it through a device-profile configuration file specifying the BLE service/characteristic UUIDs, unit conversions, and validation bounds; supported profiles SHALL include at minimum: pulse oximeters (SpO₂/HR), BP monitors, digital thermometers, glucometers, haemoglobinometers, weighing scales, and smart stethoscopes where standard BLE profiles exist.
6. WHEN a measurement screen is not active, THE App SHALL not maintain a BLE connection or run any background scanning service that drains the device battery.
7. WHEN a reading is received from a shared device, THE App SHALL associate the reading with the currently active patient and the authenticated ASHA user, not with the device identifier.

---

### Requirement 29: Zero-Hardware Measurement Aids

**User Story:** As an ASHA without working equipment, I want tools built into the app for common measurements, so that I can still assess patients properly.

#### Acceptance Criteria

1. WHEN the ASHA needs to count breaths, THE App SHALL provide a 60-second tap-to-count timer with audible cues, compute the respiratory rate from the tap count, and apply the age-appropriate fast-breathing threshold to classify the result.
2. WHEN the ASHA needs to assess MUAC, height, or growth, THE App SHALL provide a colour-coded reference guide and an on-screen tape-colour chart consistent with the WHO/UNICEF MUAC tape colour coding.
3. WHEN a timed procedure requires a specific duration (for example, 60-second respiratory count or 14-day sputum follow-up), THE App SHALL provide timers and SHALL notify the ASHA when the interval expires.
4. WHEN a camera-based measurement or AI estimation is presented (such as infant weight estimation or jaundice/anaemia assessment from photo), THE App SHALL label it prominently as experimental, SHALL require clinical validation and CDSCO regulatory approval before use in triage, and SHALL NOT use it as the sole basis for reducing a triage severity from Red or Yellow.
5. WHEN a clinical calculation is needed, THE App SHALL provide built-in calculators for: EDD from LMP, gestational age, ASHA-scope drug doses (ORS, zinc, iron, paracetamol), BMI, and WHO growth percentiles — all computed offline.

---

### Requirement 30: Equipment, Supply and Drug Stock Management

**User Story:** As an ASHA, I want to track my kit and consumables, so that I know when to request restocking and my tools are working.

#### Acceptance Criteria

1. WHEN an ASHA's equipment kit is issued, THE System SHALL record each item with its name, serial number, and issue date against her worker record.
2. WHEN the ASHA dispenses IFA tablets, ORS sachets, zinc tablets, contraceptives, or other listed items, THE App SHALL decrement the item count from her stock and SHALL display the remaining quantity and estimated run-out date.
3. WHEN any stock item falls below its configurable minimum threshold, THE App SHALL notify the ASHA and generate a restock request that can be submitted offline and synced to the AF and Backend later.
4. WHEN a pattern of implausible repeated readings or low-battery warnings from a Bluetooth device suggests a fault, THE App SHALL alert the ASHA and provide a fault-report form with an optional photo attachment.
5. WHEN a device is due for calibration or replacement based on a configurable schedule, THE App SHALL list it on the ANM's workspace and record the action taken after the ANM confirms it.
6. WHEN a stock-out occurs for any item, THE App SHALL record the date and item, and THE Backend SHALL surface the stock-out in the PHC and district supply-chain dashboards on next sync.

---

## Part 7 — Data, Sync and Interoperability

---

### Requirement 31: Background Synchronisation

**User Story:** As an ASHA who is rarely online, I want my data to sync automatically when a network appears, so that my supervisors see my work without me doing anything.

#### Acceptance Criteria

1. WHEN network connectivity becomes available, THE Sync_Engine SHALL begin a background sync automatically, sending records in priority order: Red referrals and urgent flags first, then visit records, then low-priority metadata and analytics.
2. WHEN the network is slow, unstable, or intermittent (2G/EDGE), THE Sync_Engine SHALL use gzip-compressed, incremental delta payloads, resume interrupted transfers from the last confirmed checkpoint, and retry failed batches with exponential backoff — without creating duplicate records on the Backend.
3. WHEN a sync batch completes or fails for a record, THE App SHALL update a per-record sync status visible to the ASHA: one of "saved on phone", "synced", or "needs attention" — without interrupting active use.
4. WHEN the ASHA enables data-cost control mode, THE App SHALL restrict large downloads (rule updates, offline maps, learning-content bundles) to Wi-Fi connections, while always allowing safety-critical syncs (Red referrals, consent withdrawals, critical flags) on any connection.
5. WHEN no data network is available and a Red referral must be shared urgently, THE App SHALL be able to produce a compact referral SMS text that can be sent via a basic SMS channel.
6. WHEN the device is idle with no pending sync data, THE Sync_Engine SHALL not run background activity that consumes battery.
7. WHEN the Backend is unreachable, THE App SHALL retain all unsynced records in the Local_Store indefinitely until sync succeeds, and SHALL NOT show a data loss warning unless the device storage is genuinely full.

#### Property-Based Testing Notes

- **Idempotence:** Applying the same sync batch to the Backend twice (due to a retry) SHALL produce the same final database state as applying it once — idempotent upsert semantics required on the Backend.
- **Priority invariant:** For any set of pending sync records, the Sync_Engine SHALL never send a lower-priority record before all higher-priority records in the queue have been sent or acknowledged.

---

### Requirement 32: Conflict Resolution and Identity Merging

**User Story:** As a system operator, I want concurrent offline edits by different workers to merge safely, so that no data is silently lost or duplicated.

#### Acceptance Criteria

1. WHEN records are created offline, THE App SHALL use client-generated UUID v4 identifiers and SHALL record all changes as entries in an append-only event log stored in the Local_Store.
2. WHEN two users edit different fields of the same record while offline, THE Backend SHALL merge the non-overlapping field changes automatically on sync using last-write-wins per field, preserving the event-log provenance for each field value.
3. WHEN two users edit the same field of the same record while offline, THE Backend SHALL retain both values with their provenance (author, device, timestamp) and SHALL flag the conflict for review by the ANM or AF — it SHALL NOT silently discard either value.
4. WHEN clinical measurement conflicts arise (for example, two different weight values recorded for the same beneficiary on the same day by different workers), THE Backend SHALL store both with full provenance and SHALL display the most recent by default in the App while making both visible.
5. WHEN the Backend detects probable duplicate beneficiary records (matching name, DOB, and ASHA area across different ASHAs), THE Backend SHALL propose a merge to a designated ANM or AF reviewer and SHALL preserve the full event history of both candidate records until the review is resolved.
6. WHEN a merge is approved by the reviewer, THE Backend SHALL propagate the canonical merged record to all relevant devices and SHALL redirect internal references from the retired record ID to the canonical ID.
7. WHEN device system clocks may be inaccurate, THE System SHALL record both the device timestamp and the Backend-received timestamp on every event and SHALL use server-received time for conflict ordering while retaining device time for display.

#### Property-Based Testing Notes

- **Confluence:** For any two sets of offline edits A and B to the same record, `merge(A, merge(B, base)) == merge(B, merge(A, base))` — merge order SHALL not affect the final merged state for non-conflicting fields.
- **No data loss:** After any merge operation, the union of all event-log entries from both branches SHALL be present in the merged record's event log.

---

### Requirement 33: Data Integrity and Auditability

**User Story:** As an auditor, I want tamper-evident records of who recorded what and when, so that data and decisions can be trusted.

#### Acceptance Criteria

1. WHEN a clinical or incentive-relevant record is created, THE App SHALL store with it: the author's user ID, device ID, App version, rule-set version (for clinical records), and device timestamp.
2. WHEN records are synced to the Backend, THE Sync_Engine SHALL include a tamper-evident integrity mechanism (SHA-256 hash chain over the event log entries for each record) so that alterations after sync are detectable.
3. WHEN a record is corrected, THE App SHALL keep the original field value immutably in the event log, add the corrected value as a new event with the correction reason and the correcting user's ID, and SHALL NOT perform silent in-place edits of clinical history.
4. WHEN an auditor or authorised supervisor requests an audit trail for a beneficiary or a worker, THE System SHALL produce it with role-appropriate redaction (excluding fields the requesting role is not authorised to see).
5. WHEN data validation rules detect impossible or implausible values at entry (impossible dates, biologically implausible vitals), THE App SHALL block or warn the user and SHALL log patterns of repeated bypass for data-quality monitoring.

#### Property-Based Testing Notes

- **Tamper detection:** For any synced event-log chain, modifying any byte of any event SHALL cause the hash-chain verification to fail on the next integrity check.
- **Round-trip:** `reconstruct(eventLog) == currentRecord` — replaying the ordered event log SHALL always reproduce the current field values of the record.

---

### Requirement 34: Paper-Compatible Outputs

**User Story:** As an ASHA who must still submit paper registers, I want the app to produce those outputs from my single entry, so that I never write the same data twice.

#### Acceptance Criteria

1. WHEN the ASHA requests a register page, THE App SHALL generate a print-ready PDF using the pdf Dart package, with layout matching the official register or form for: village survey, RCH, HBNC, HBYC, PNC, high-risk pregnancy, CBAC, TB treatment, and immunization registers.
2. WHEN the supervisor or ANM requests a monthly report, THE App SHALL generate the standard monthly reporting format from on-device or synced data for the requested period.
3. WHEN an official register or form template is updated by the government, THE Backend SHALL allow a State_Admin to publish a new template configuration; THE App SHALL apply it on next sync without an APK release.
4. WHEN a printer is unavailable, THE App SHALL present a full-screen, scrollable on-screen register view suitable for showing to a supervisor or photographing, plus a share action to messaging apps.
5. WHEN the ASHA needs to give a record to the family, THE App SHALL generate a family-friendly card or summary for: MCP card update, vaccination card, referral slip — in the selected language, formatted for legibility on a phone screen or as a PDF share.

---

### Requirement 35: Integration with Government Digital Systems

**User Story:** As an ANM and an ASHA, I want data to flow to RCH/ANMOL, U-WIN, Ni-kshay, NCD, HMIS and POSHAN systems without retyping, so that digital tools reduce work instead of adding to it.

#### Acceptance Criteria

1. WHEN an official API or data-integration channel exists for a government system (U-WIN, Ni-kshay, NCD application, ABDM), THE Backend SHALL integrate via that channel using the required authentication and security protocols.
2. WHEN no public API exists for a system (ANMOL, HMIS, POSHAN Tracker), THE System SHALL provide: an export in the system's accepted bulk-upload format, and a guided data-entry assistant in the ANM/DEO workspace that pre-fills fields from already-captured data to minimise keystrokes.
3. WHEN data originates in an external system (for example, vaccination from U-WIN, TB treatment outcome from Ni-kshay), THE Backend SHALL import or reconcile it and display the external source identifier alongside the local record.
4. WHEN field mapping between the System and an external system differs by state (different codes, different form versions), THE Backend SHALL use a state-level mapping configuration file to perform the translation.
5. WHEN an integration call fails or a record is rejected by an external system, THE System SHALL surface the rejection reason and a correction path to the appropriate user (ANM or ASHA) rather than silently discarding the record.
6. WHEN HMIS monthly indicators are needed, THE Backend SHALL auto-compute them from event data for the relevant period and SHALL present them to the ANM for review and approval before submission.
7. WHEN any data is shared with an external system, THE Backend SHALL log the sharing event (target system, record type, timestamp, user who triggered it) for DPDP accountability.

---

### Requirement 36: ABDM, ABHA and FHIR Interoperability

**User Story:** As a beneficiary, I want my health records linked to my ABHA, so that care is continuous across facilities.

#### Acceptance Criteria

1. WHEN the beneficiary consents to ABHA linkage, THE App SHALL support ABHA creation, verification, and linking — with offline capture of the required details and online verification completing on next connectivity using the ABDM sandbox APIs.
2. WHEN health records are exchanged with ABDM, THE Backend SHALL generate FHIR R4 resource bundles (using the fhir_r4 Python library) conforming to current ABDM FHIR profiles; THE App SHALL use compact, delta payloads between device and Backend to minimise data cost.
3. WHEN a beneficiary or a facility requests health records through ABDM consent-manager flows, THE Backend SHALL honour the consent artifact's scope and expiry and SHALL share only the permitted resource types.
4. WHEN a health facility or professional directory lookup is required (facility registry, health professional registry), THE Backend SHALL cache the relevant entries locally and serve them from the local cache for offline use.
5. WHEN ABDM FHIR profile specifications change, THE Backend SHALL absorb the mapping changes through configuration or code updates without requiring a new App APK release wherever possible.
6. WHEN the System is deployed, THE Backend SHALL have completed the required ABDM sandbox integration testing and obtained the applicable ABDM compliance certificate before go-live.

---

## Part 8 — Learning, Support and Supervision

---

### Requirement 37: Training and Micro-Learning

**User Story:** As an ASHA, I want short, practical lessons on my phone, so that I keep my skills sharp and learn new programmes without leaving my village.

#### Acceptance Criteria

1. WHEN an ASHA is onboarded, THE App SHALL provide an induction learning pathway aligned with the official ASHA training modules (HBNC, HBYC, NCD, TB, immunization, and ASHA Module 6/7) in audio, video, and illustrated formats, all available offline after download.
2. WHEN a lesson is presented, THE App SHALL keep each lesson to approximately two to five minutes of content and SHALL follow it with no more than five quiz questions; progress and scores SHALL be stored in the Local_Store.
3. WHEN the App detects a performance or knowledge gap (repeated skipping of danger-sign assessment steps, unusually high override rates, missed IFA distribution records, or data rejected by the ANM), THE App SHALL suggest the relevant micro-lesson using a supportive, non-punitive framing — not a warning.
4. WHEN a Red triage flag is raised, THE App SHALL offer an optional link to a 2-minute refresher lesson on the specific danger sign that triggered the flag.
5. WHEN a mandatory training course is required, THE App SHALL enforce a maximum daily lesson count and SHALL use a spaced-repetition quiz schedule to improve retention, preventing a single-session click-through completion.
6. WHEN the ASHA completes training modules, THE App SHALL record completion with a timestamp and quiz scores and SHALL sync the record toward official certification tracking; THE App SHALL generate a verifiable completion record shareable with the AF and the state training system.
7. WHEN trainers or state administrators publish new content, THE Backend SHALL support content versioning, language variants, and role-based assignment; THE App SHALL download new content in the background and notify the ASHA.
8. WHEN soft-skills content is available, THE App SHALL include modules on: community communication, health counselling, negotiation, financial literacy, stress management, and self-efficacy.
9. WHEN scenario-based practice is available, THE App SHALL offer offline simulated clinical cases (for example, a sick newborn with danger signs) that exercise the triage workflow in a practice mode where no real beneficiary records are created.
10. WHEN the ASHA has a protocol question, THE App SHALL provide a searchable offline reference-card library of job aids sourced from official ASHA training material.

---

### Requirement 38: Teleconsultation, Helpline and Peer Support

**User Story:** As an ASHA facing a difficult case, I want to reach a doctor or colleague quickly, so that I am not alone with the decision.

#### Acceptance Criteria

1. WHEN the ASHA needs clinical advice, THE App SHALL provide one-tap call actions to: her assigned ANM, CHO, MO, and national / state helplines (104 health advice, 108 emergency, 102 obstetric, and configured state-specific lines) — the calls SHALL work over basic voice even when data is unavailable.
2. WHEN data connectivity is sufficient, THE App SHALL support asynchronous case sharing: a pre-formatted message containing the referral note excerpt (minimum necessary clinical details, with beneficiary consent) sent to the ANM or MO, and a linkage option to e-Sanjeevani for a live teleconsultation.
3. WHEN an ASHA wants peer support, THE App SHALL provide an opt-in moderated peer group with voice-note and text Q&A in the selected language.
4. WHEN patient details are shared in any teleconsultation or peer-support channel, THE App SHALL share only the minimum necessary clinical details, with explicit beneficiary consent obtained before sharing.

---

### Requirement 39: ASHA Facilitator Supportive Supervision

**User Story:** As an ASHA Facilitator, I want to see how my ASHAs are doing and where they need help, so that I can mentor them rather than only check compliance.

#### Acceptance Criteria

1. WHEN an AF opens her dashboard, THE System SHALL display, for each ASHA under her: programme coverage percentages, overdue visit count, pending referral outcomes, recent Red flags (with resolution status), data-quality indicators, and learning progress — updated on the ASHA's last sync.
2. WHEN an AF plans a supervisory field visit, THE App SHALL provide digital supervision checklists (observing an ASHA visit, checking records, reviewing equipment and stock) that can be completed and saved offline with notes and photos.
3. WHEN the System identifies mentoring-relevant patterns for an ASHA (repeated data-entry errors, unusual override frequency, persistently missed tasks beyond workload-explained levels), THE System SHALL surface them in a supportive framing (for example, "may benefit from refresher on") and SHALL suggest an appropriate micro-lesson or AF visit.
4. WHEN an ASHA's workload is persistently excessive or physical access barriers are flagged, THE System SHALL highlight the situation to the AF and the Block_District_Officer for workload rebalancing consideration.
5. WHEN an AF wants to give feedback or recognition, THE App SHALL allow the AF to send a short text message, voice note, or recognition badge to the ASHA, visible on the ASHA's home screen.
6. WHEN an AF resolves or escalates an issue with an ASHA's record or task, THE App SHALL record the action, the resolution details, and schedule a follow-up check if required.

---

### Requirement 40: ANM and CHO Workspace

**User Story:** As an ANM, I want the data collected by ASHAs to arrive ready to use, so that I can focus on clinical care and sessions rather than re-entering records.

#### Acceptance Criteria

1. WHEN ASHAs in the ANM's sub-centre area sync, THE System SHALL present the ANM with new registrations, ANC/PNC updates, immunization records, and referral data, with validation errors highlighted for correction.
2. WHEN the ANM conducts a VHSND or sub-centre clinic session, THE System SHALL provide a session beneficiary list and allow the ANM to record services given, which SHALL update the individual beneficiary timelines.
3. WHEN the ANM verifies ASHA work for incentive processing, THE System SHALL provide an efficient review queue with the underlying event records as evidence for each claimable line item (Requirement 56).
4. WHEN a Red-flag referral or high-risk case arrives via sync, THE System SHALL alert the ANM or CHO with the full referral note and the ASHA's contact.
5. WHEN the ANM needs to submit data to a government portal, THE System SHALL provide the guided data-entry assistant described in Requirement 35.
6. WHEN the ANM or CHO needs to use the System in the field, THE System SHALL provide an offline-capable app experience on a tablet or phone scoped to her sub-centre area.

---

### Requirement 41: PHC and Facility Dashboard

**User Story:** As a PHC doctor, I want incoming referrals and area health indicators in one place, so that I can prepare for patients and act on risks.

#### Acceptance Criteria

1. WHEN a referral syncs to the Backend, THE Dashboard SHALL display it in a live referral queue at the destination facility, sorted by triage severity (Red first), with the full referral note, available patient history, and the originating ASHA's contact details.
2. WHEN a facility staff member records a referral outcome, THE Backend SHALL push a notification to the originating ASHA's device and to the ANM.
3. WHEN the MO reviews the area, THE Dashboard SHALL show active lists of: high-risk pregnancies, sick newborns, SAM children, TB patients, NCD defaulters, and overdue follow-ups — filterable by sub-centre and ASHA.
4. WHEN the facility team needs to plan, THE Dashboard SHALL show: expected deliveries in the next 4 weeks, immunization session demand, commodity stock levels, and outstanding referral outcomes.
5. WHEN a doctor wants to send feedback to the ASHA linked to a case, THE Dashboard SHALL support a short text or voice-note message sent back to the ASHA's device via the Backend.
6. WHEN the Dashboard is accessed on a slow internet connection, THE Dashboard SHALL render a lightweight view using cached data and SHALL progressively load heavier analytics components.

---

### Requirement 42: Block, District and State Analytics

**User Story:** As a district health officer, I want reliable and timely data across my area, so that I can detect outbreaks, direct resources and monitor programmes.

#### Acceptance Criteria

1. WHEN records sync to the Backend, THE Backend SHALL update programme coverage and outcome indicators (ANC coverage, institutional delivery rate, full immunization coverage, HBNC/HBYC completion, NCD screening rate, TB notification rate) in near real time.
2. WHEN a geographic view is requested, THE Dashboard SHALL render choropleth maps and heatmaps at block, PHC, sub-centre, and village levels; for cells with fewer than a configurable minimum count, THE System SHALL display aggregated figures or suppress the cell to prevent re-identification.
3. WHEN signals suggest an outbreak, a high-risk beneficiary cluster, or a service coverage gap, THE Backend SHALL generate an alert to the relevant Block_District_Officer with the supporting data and the affected area.
4. WHEN supply forecasting is needed, THE Backend SHALL estimate consumption rates and run-out dates for key commodities based on logged dispensing events and current stock levels.
5. WHEN data quality is poor for an area (high missing-data rates, delayed sync, anomalous patterns), THE Dashboard SHALL highlight the area and the specific indicator without naming individual workers by default.
6. WHEN analysis is needed for research or programme planning, THE System SHALL provide de-identified data exports and a queryable analytics interface with role-based access controls.
7. WHEN officers compare areas or time periods, THE Dashboard SHALL present performance metrics relative to configured programme targets and to the previous comparable period.

---

## Part 9 — Administration, Security and Compliance

---

### Requirement 43: Administration and Configuration Console

**User Story:** As a state or district administrator, I want to configure the system for my state without developers, so that rules, forms, languages and rates reflect local policy.

#### Acceptance Criteria

1. WHEN an admin manages users, THE System SHALL support bulk onboarding via CSV/Excel upload, role assignment, geographic area mapping (village, hamlet, sub-centre, PHC, block, district), worker reassignment, and account deactivation — with an audit log of all changes.
2. WHEN the organisational hierarchy changes (PHC mergers, block boundary revisions), THE Backend SHALL propagate the change to dashboard routing and data aggregation without requiring manual re-assignment of individual records.
3. WHEN configuration artefacts are updated — forms, schedules, rule sets, localisation strings, incentive catalogues, facility directories — THE System SHALL version the artefact, allow staged rollout to a subset of users for validation, and support rollback to the previous version.
4. WHEN a configuration change is published, THE System SHALL allow targeting by state, district, block, or named user group, and SHALL deliver it OTA to devices on their next sync.
5. WHEN a State_Admin monitors deployment health, THE Dashboard SHALL show: App version distribution across workers, last-sync time per worker, sync failure rates, device storage usage, and device health indicators.
6. WHEN the System is deployed to a new state, THE Backend SHALL provide a state-setup checklist covering: language selection, incentive catalogue loading, facility directory import, clinical protocol review, and staff onboarding — completable without developer assistance.

---

### Requirement 44: Data Security and Privacy Compliance (DPDP and ABDM)

**User Story:** As a beneficiary, I want my health data kept private and used lawfully, so that I can trust the system with sensitive information.

#### Acceptance Criteria

1. WHEN data is stored on a device, THE App SHALL encrypt the Local_Store using SQLCipher AES-256; WHEN data is in transit, THE System SHALL use TLS 1.3 with certificate pinning in the App to prevent MITM attacks.
2. WHEN personal data is collected, THE System SHALL limit collection to the fields necessary for the stated care or administrative purpose, record the purpose at the time of collection, and apply configurable retention periods per data category.
3. WHEN a beneficiary submits a Subject Access Request, correction request, or erasure request under DPDP, THE System SHALL provide a tracked request workflow with status updates and SHALL record its fulfilment with timestamp and resolution details.
4. WHEN a data breach is suspected, THE System SHALL provide: automated anomaly detection, a structured incident-logging workflow, and the notification process required under DPDP and ABDM.
5. WHEN data is processed by third-party cloud infrastructure or sub-processors, THE System SHALL ensure data residency in compliant jurisdictions and SHALL require Data Processing Agreements with each sub-processor before any data is shared.
6. WHEN a staff member accesses beneficiary data, THE Backend SHALL enforce least-privilege role-based access, log every data access with the user and purpose, and generate an alert for the Security_Admin when anomalous access patterns are detected.
7. WHEN data is used for analytics, ML model training, or research purposes, THE Backend SHALL use a de-identified dataset and SHALL require ethics board review and explicit consent for research use.
8. WHEN the App is launched on a rooted or integrity-compromised device, THE App SHALL detect this condition and SHALL restrict access to sensitive patient data, presenting a warning and a support contact.
9. WHEN data from stigmatised conditions (HIV/AIDS, TB, mental health, family planning, sexual health) is displayed, THE App and Dashboard SHALL apply stricter role-based visibility controls and SHALL use neutral or coded labels in shared or supervisor-facing views.

---

### Requirement 45: Worker Privacy, Anti-Surveillance Safeguards and Transparency

**User Story:** As an ASHA, I want to know exactly what the app tracks about me and be sure it is not used to punish me unfairly, so that I trust and willingly use it.

#### Acceptance Criteria

1. WHEN the App is installed, THE App SHALL present a plain-language, audio-supported notice to the ASHA specifying: exactly what data about her activities is collected, who can view it, and how it may be used.
2. WHEN location is used in any feature, THE App SHALL use it only when the ASHA has opted in for that specific feature, only while that feature is actively in use, and SHALL NOT perform continuous background GPS logging or use location data for geofencing-based attendance enforcement.
3. WHEN supervisors view ASHA performance data, THE System SHALL present it in a context of supportive mentoring and planning, and SHALL simultaneously give the ASHA access to the same data about herself through the App.
4. WHEN an ASHA disputes data recorded about her work or performance, THE System SHALL provide a grievance-submission channel with a recorded resolution process, an assigned owner, and a visible status until resolved.
5. WHEN worker representatives request aggregate information about how the platform is used across the workforce, THE System SHALL support this through governance-approved aggregated reporting that does not reveal individual worker details.
6. WHEN individual worker analytics are proposed for use in a formal appraisal or disciplinary process, THE System SHALL require explicit programme-leadership policy sign-off, and THE System SHALL inform the affected workers that their data is being used for this purpose.

---

### Requirement 46: AI Safety, Human Oversight and Monitoring

**User Story:** As a clinical safety officer, I want AI outputs to be safe, explainable and monitored, so that ASHAs stay in control and errors are caught early.

#### Acceptance Criteria

1. WHEN the System presents any CDSS suggestion, THE App SHALL label it as advice, require the ASHA to confirm her action before recording it, and SHALL store the ASHA's decision as the authoritative record — not the system suggestion.
2. WHEN the System's triage suggestion is at a lower severity than the ASHA's own observation, THE App SHALL prompt a reconsideration check ("Does the child look lethargic?") before accepting the lower severity, and SHALL always allow the ASHA to escalate to a higher severity without restriction.
3. WHEN triage outcomes, overrides, and referral results are synced, THE Backend SHALL compute metrics — over-triage rate, under-triage rate, override rate, and outcome mismatch rate — segmented by rule, language, area, and ASHA cohort, and SHALL alert the clinical safety team when any metric exceeds a configurable threshold.
4. WHEN a safety incident or near miss is identified (by an ASHA, AF, or clinical team), THE System SHALL provide an incident-reporting workflow with fields for: description, contributing factors, immediate outcome, corrective action proposed, and follow-up review date.
5. WHEN a voice-recognition or ML component performs below the minimum accuracy threshold for a specific language, dialect, or demographic group, THE System SHALL report the performance gap and SHALL provide the ability to disable or restrict that component for affected users until it is corrected.
6. WHEN a model or rule set is updated, THE System SHALL run validation against a held-out, clinician-labelled test set and SHALL require sign-off from a designated clinical authority before release.
7. WHEN the ASHA disagrees with a system suggestion, THE App SHALL capture her feedback and the reason in a structured form for clinical review.
8. WHEN CDSS output is displayed, THE App SHALL show the specific observations that the ASHA entered alongside the output, to discourage passive over-reliance on the system result.

---

### Requirement 47: Regulatory and Quality Management System Compliance

**User Story:** As the product owner, I want the platform to meet medical-software regulation and quality standards, so that it can be deployed legally in public health programmes.

#### Acceptance Criteria

1. WHEN the triage function is classified under Medical Devices Rules 2017 and CDSCO software guidance, THE System SHALL be developed under a documented Quality Management System with an intended-use statement and a formal SaMD classification analysis **[VALIDATE current CDSCO position on lay-user community health worker software, including whether triage constitutes Class A or Class B SaMD]**.
2. WHEN a release is prepared, THE System SHALL maintain: a requirements-to-test traceability matrix, a risk management file (hazard analysis and risk control record per IEC 62304 / ISO 14971 principles), and documented verification and validation evidence.
3. WHEN clinical performance claims are made (sensitivity, specificity, positive predictive value of the triage engine), THE System SHALL support a prospective or retrospective clinical validation study design comparing triage outputs to a clinical gold standard (IMNCI-trained clinician) in the target community settings.
4. WHEN a software change affects any clinically relevant behaviour, THE System SHALL follow a documented change-control process including: impact analysis, regression test execution, and sign-off by an authorised clinical and technical reviewer before release.
5. WHEN post-deployment adverse events, near misses, or complaints are reported, THE System SHALL provide a documented complaint-handling and vigilance-reporting workflow consistent with CDSCO post-market surveillance requirements.
6. WHEN legal liability for triage errors is assessed, THE System SHALL provide documentation of: intended use and limitations, ASHA user training requirements, the human-in-the-loop design, and the disclaimer labelling present in the App.

---

## Part 10 — Non-Functional and Operational Requirements

---

### Requirement 48: Performance and Low-End Device Constraints

**User Story:** As an ASHA with an older, low-memory phone, I want the app to run smoothly and not drain my battery or storage, so that it works on the phone I actually have.

#### Acceptance Criteria

1. WHEN the App is installed, THE App base APK (without language model, maps, or learning-content downloads) SHALL be under 50 MB.
2. WHEN the App runs on a device with 2 GB RAM and Android 9 or above, THE App SHALL render any screen within one second and THE Triage_Engine SHALL compute a flag within one second, without the OS killing the App during data entry.
3. WHEN the App is in use, THE App SHALL not run persistent background services; all background work SHALL use Android WorkManager with constraints that prevent unnecessary battery drain.
4. WHEN the device is powered off or the battery is exhausted mid-entry, THE App SHALL preserve the current draft (Requirement 1 AC3) and resume correctly after power-on without data corruption.
5. WHEN an App update is available, THE System SHALL deliver it as a delta APK patch; on slow connections, THE App SHALL defer the update download to a time when the network is better and SHALL remain fully functional on the current version in the interim.
6. WHEN a device does not meet the minimum hardware requirements (for example, Android below version 9 or RAM below 1.5 GB), THE App SHALL display a clear message and SHALL offer a reduced-feature mode (tap-only entry, no voice model, simplified triage) where technically feasible.
7. WHEN the ASHA enables low-power mode, THE App SHALL apply: dark UI theme, reduced animation, deferred non-critical sync to Wi-Fi only, and disabled non-essential background tasks.

---

### Requirement 49: Accessibility and Inclusion

**User Story:** As an ASHA with low vision, hearing difficulties or limited dexterity, I want the app to be usable for me, so that I am not excluded from the workforce tools.

#### Acceptance Criteria

1. WHEN a user adjusts display settings, THE App SHALL support: text scaling (up to 200%), high-contrast mode, and a bright-sunlight mode with increased minimum luminance contrast.
2. WHEN a user has a vision impairment, THE App SHALL support Android TalkBack screen-reader operation for all interactive elements, using meaningful content descriptions for all icons and images.
3. WHEN a user has a hearing impairment, THE App SHALL provide visual (on-screen banner) and vibration cues for all alerts that are also communicated via audio.
4. WHEN a user has dexterity limitations, THE App SHALL provide all interactive elements with a minimum 48 × 48 dp touch target and SHALL offer voice input as an alternative to all tap/type actions.
5. WHEN the ASHA is communicating with a beneficiary who has a disability or limited language ability, THE App SHALL offer pictorial communication aids and simplified illustrated health-message cards.

---

### Requirement 50: Backup, Recovery and Device Migration

**User Story:** As an ASHA who may lose or replace her phone, I want my data to be recoverable, so that months of work are not lost.

#### Acceptance Criteria

1. WHEN data is synced to the Backend, THE Backend SHALL retain it with geographic redundancy and regular automated backups, and THE System SHALL test restore procedures at least quarterly.
2. WHEN an ASHA obtains a new device, THE App SHALL restore her assigned area data after she completes secure re-verification (ASHA ID + OTP), applying data-minimisation limits so the new device receives only the data scoped to her current assignment.
3. WHEN an ASHA's device is lost, THE System SHALL limit data loss to records created after the last successful sync, and THE App SHALL inform the ASHA of the approximate count and date range of unsynced records when she recovers her account on a new device.
4. WHEN an ASHA ends a shift or work day, THE App SHALL display a sync-status summary (number of records pending sync) and SHALL prompt her to find network connectivity if any unsynced records exist.
5. WHEN an ASHA leaves the programme or her area is reassigned, THE System SHALL support a structured hand-over workflow that transfers ownership of her households and open tasks to a designated successor.

---

### Requirement 51: Observability, Quality Feedback and Support

**User Story:** As a product team, I want to know how the app performs in the field and hear from users, so that I can fix problems fast and improve usability.

#### Acceptance Criteria

1. WHEN the App crashes or encounters an unhandled error, THE App SHALL record diagnostic information (stack trace, device model, App version, Flutter error context) to the Local_Store, with no patient or personal data included, and SHALL transmit it to the Backend error-tracking service when connectivity returns.
2. WHEN usage analytics are collected, THE System SHALL collect only anonymised, aggregated metrics (feature invocation counts, median time-on-task, error rates, sync success rates) and SHALL disclose the full list of collected metrics to workers in the privacy notice (Requirement 45).
3. WHEN an ASHA needs help, THE App SHALL provide: an in-app help screen with audio explanations, a toll-free support helpline number, and a "report a problem" action that captures a voice note and optional screenshot with any visible patient identifiers blurred before transmission.
4. WHEN field support staff review issues, THE Dashboard SHALL provide an issue-tracker view with resolution time metrics and categorised failure reasons.
5. WHEN a new feature is released, THE System SHALL support staged rollout via feature flags to a configurable percentage of users, and SHALL support non-clinical A/B pilots for UX improvements.
6. WHEN the System is evaluated, THE Backend SHALL track and report: adoption rate, active-user retention, estimated time saved per task versus paper baseline, data completeness scores, and referral completion rates — measured against pre-deployment baselines.

---

### Requirement 52: Model Evaluation and Dataset Pipeline

**User Story:** As an ML engineer, I want a pipeline to evaluate and improve speech and triage components using appropriate datasets, so that quality is measurable and bias is controlled.

#### Acceptance Criteria

1. WHEN speech recognition is evaluated, THE System SHALL maintain a per-language and per-dialect benchmark using publicly available datasets (such as IndicVoices) supplemented by field-collected, consented clinical-vocabulary recordings, evaluated on the target low-end reference devices.
2. WHEN triage logic is evaluated, THE System SHALL use: clinician-labelled case sets, guideline-derived automated test cases, and — where ethically and legally permitted — de-identified retrospective field data; NFHS-5 and HMIS data SHALL be used for condition prevalence checks and scenario realism validation.
3. WHEN training or fine-tuning a model, THE System SHALL document for each dataset: provenance, licence terms, consent basis, known limitations, and demographic representation.
4. WHEN a model is quantised or compressed for on-device deployment, THE System SHALL re-run the full accuracy, latency, memory usage, and battery consumption test suite on the minimum-spec reference device before release.
5. WHEN model performance differs across languages, regions, sex, or age groups, THE System SHALL report the disaggregated metrics and SHALL require each group to meet a minimum performance threshold before that language/region/demographic group is released.
6. WHEN field data is collected for model improvement, THE System SHALL honour all consent terms from Requirement 5 and all de-identification requirements from Requirement 44, and SHALL maintain a data-lineage record for each training dataset version.

#### Property-Based Testing Notes

- **Round-trip invariant:** For any valid FHIR R4 resource generated by the System, `parse(serialise(resource)) == resource` using the fhir_r4 Python library — JSON serialisation SHALL be a perfect round-trip.

---

## Part 11 — Compensation and Incentives

---

### Requirement 53: Incentive Task Catalogue and Rate Configuration

**User Story:** As a state administrator, I want to configure the incentive categories and rates for my state, so that the system reflects actual policy and changes in orders.

#### Acceptance Criteria

1. WHEN the System is deployed in a state, THE Backend SHALL load a state-specific incentive catalogue defining: activity codes, monetary rates, eligibility conditions, required evidence types, and claim submission windows — and SHALL NOT hardcode any rate value in the App or Backend code **[VALIDATE against current NHM state programme implementation plans and government orders for the pilot state]**.
2. WHEN a government order changes an incentive rate or condition, THE System SHALL allow a State_Admin to publish a new catalogue version with an effective date; the previous version SHALL be retained for processing historical claims that predate the change.
3. WHEN a task type has multiple payment components (fixed honorarium, performance-based incentive, state government top-up, connectivity allowance), THE catalogue SHALL represent each component separately with its own rate and eligibility condition.
4. WHEN an ASHA views the incentive catalogue, THE App SHALL present each item in her selected language with an audio description of what the task pays and what evidence is required to claim it.

#### Property-Based Testing Notes

- **Invariant:** For any historical claim submitted before an effective-date change, the rate computation SHALL use the catalogue version active on the date the eligible event was completed — the version in effect at event time SHALL always be recoverable from the versioned catalogue.

---

### Requirement 54: Automatic Incentive Event Logging and Eligibility

**User Story:** As an ASHA, I want every task I complete to be counted towards my incentives automatically, so that I do not forget to claim or need to prove it twice.

#### Acceptance Criteria

1. WHEN a visit, service delivery, escort, registration, follow-up, or programme milestone is completed and the event matches a catalogue item with its eligibility conditions met, THE App SHALL create an incentive-eligible event record linked to the underlying clinical record — no separate claim entry by the ASHA is required.
2. WHEN a task is only partially complete (for example, 3 of 6 required HBNC visits completed), THE App SHALL display a progress indicator and SHALL clearly show what remains to achieve full eligibility.
3. WHEN eligibility depends on a future event (for example, full immunization by age one confirmed, delivery outcome confirmed, TB treatment completion confirmed), THE System SHALL track the pending condition and SHALL mark the event as eligible only when the condition is satisfied.
4. WHEN a completed task does not meet eligibility criteria, THE App SHALL display the ineligibility reason in plain language in the ASHA's selected language, with audio.
5. WHEN an external facility records a confirmatory event (institutional delivery confirmed at facility, Ni-kshay case confirmed), THE System SHALL use the external record as verification evidence for the incentive claim where policy permits.
6. WHEN the same event might be claimed by two different workers (for example, two ASHAs both claim escort for the same delivery), THE System SHALL detect the potential duplicate and SHALL flag it for the ANM's review before approving either claim.

#### Property-Based Testing Notes

- **Idempotence:** Recording the same eligible event multiple times (network retry scenario) SHALL result in exactly one incentive-eligible event record — no duplicate eligibility credit.
- **Invariant:** For any approved incentive event, the linked clinical record ID SHALL be present and resolvable in the Local_Store or Backend — orphaned incentive records SHALL not exist.

---

### Requirement 55: Earnings Dashboard and Transparency

**User Story:** As an ASHA, I want to see what I have earned, what is pending and why, so that I can plan my household budget and trust the process.

#### Acceptance Criteria

1. WHEN the ASHA opens the earnings view, THE App SHALL show the current month's total broken down by status: eligible (not yet claimed), claimed (awaiting verification), verified (awaiting approval), approved (awaiting payment), paid (payment received), and rejected (with reason) — with the amount and task description per line item.
2. WHEN a claim is delayed or rejected, THE App SHALL show: the stage the claim is currently at, the stated reason for delay or rejection, and the name of the role responsible for the next action.
3. WHEN a payment is received, THE App SHALL show the payment date and the bank reference number, and SHALL reconcile the paid amount against the approved claim amount, flagging discrepancies.
4. WHEN the ASHA requests a projection, THE App SHALL display an estimate of earnings for the current month if all in-progress eligible tasks are completed.
5. WHEN the ASHA requests history, THE App SHALL show previous months and years with per-task breakdowns, and SHALL generate a printable PDF earnings statement (for use with banks or microfinance applications).
6. WHEN the earnings screen is shown, THE App SHALL present it in the ASHA's selected language with audio summaries of key figures, and SHALL apply the device-lock privacy protection so earnings figures are not visible in recent-apps or to other household phone users.

---

### Requirement 56: Claim Voucher Generation, Verification and Submission

**User Story:** As an ASHA, I want my monthly claim voucher created for me and verified quickly, so that I am paid on time without paperwork.

#### Acceptance Criteria

1. WHEN the monthly claim period closes or the ASHA requests early generation, THE App SHALL automatically generate the claim voucher in the state's official format as both a printable PDF (pdf Dart package) and a digital submission record, listing each task with: task code, beneficiary reference (de-identified to a coded ID), service date, amount, and evidence record link.
2. WHEN the voucher is submitted, THE Backend SHALL route it to the responsible ANM or AF for verification, with the underlying clinical records available for the verifier to confirm each line item.
3. WHEN a verifier reviews a claim, THE System SHALL allow the verifier to approve, reject, or request correction on individual line items, with a mandatory reason for any rejection; THE System SHALL support sampling-based verification where state policy permits.
4. WHEN a claim line is rejected, THE App SHALL notify the ASHA with the specific reason and SHALL allow her to correct the issue and resubmit the affected lines; rejection categories SHALL be captured for programme analytics.
5. WHEN verification is complete, THE Backend SHALL forward the approved claim to the state payment system — via API where ASHA Soft / PFMS / DBT integration exists, or as a state-format export file with a guided data-entry assistant for the BPMU payment officer.
6. WHEN a verifier or BPMU officer reviews the claim backlog, THE Dashboard SHALL show: per-block claim ageing (days since submission), bottleneck stages, and rejection reasons — to support process improvement.
7. WHEN a voucher or export is generated, THE System SHALL include only the minimum beneficiary information required by the payment authority (coded ID, service date, amount), and SHALL NOT include clinical details in payment records.

#### Property-Based Testing Notes

- **Round-trip invariant:** For any approved claim record, `parse(generate_pdf(claim)) == claim` — all line items SHALL survive the PDF generation and parsing round-trip with no truncation or numeric precision loss.
- **Idempotence:** Generating the claim voucher for the same period twice SHALL produce an identical set of line items — no duplicate line creation on repeated generation.

---

### Requirement 57: Payment Tracking, Bank Details and Dispute Resolution

**User Story:** As an ASHA, I want my payment details validated and any dispute followed up, so that mismatches do not delay my money for months.

#### Acceptance Criteria

1. WHEN bank and identity details are entered or updated, THE System SHALL validate: IFSC code format and bank existence, account number format, Aadhaar-seeding status (where the API is available), and name matching — and SHALL flag likely mismatches before the payment cycle runs so the ASHA or ANM can correct them in time.
2. WHEN a payment is rejected by the bank or by PFMS, THE Backend SHALL retrieve the rejection reason code, surface it to the ASHA in plain language in the App, and display the specific correction steps required.
3. WHEN an ASHA believes a payment amount is incorrect or missing, THE App SHALL provide a dispute submission workflow where she can: select the disputed period/task, attach evidence from her event log, and submit the dispute; THE Backend SHALL assign the dispute an owner, track its status, and escalate if it is not resolved within a configurable SLA.
4. WHEN payments across a block are delayed beyond a configurable threshold (for example, 45 days after claim approval), THE Backend SHALL generate an alert to the Block_District_Officer and SHALL include the delayed count and aggregate amount in their dashboard.
5. WHEN auditors review the payment cycle, THE Backend SHALL produce a full reconciliation report tracing each eligible event through: event record → incentive log → claim voucher → approval → payment disbursement — with the tamper-evident audit trail from Requirement 33.
6. WHEN a dispute or payment issue is identified as a systemic policy problem (incorrect rate in the catalogue, employment classification dispute, minimum-wage entitlement) rather than a technical error, THE System SHALL aggregate similar issues and surface them to programme leadership as a policy-escalation report rather than presenting them as technical faults to the ASHA.

---

## Out of Scope: Problems Technology Cannot Solve

The following issues surfaced in the research and are documented so the platform does not misrepresent its ability to address them:

1. The employment classification of ASHAs (volunteer versus formal worker) and any minimum-wage entitlement arising from that classification.
2. The baseline level of incentives and honoraria, which are set by central and state governments.
3. Physical exhaustion caused by long travel distances between remote hamlets.
4. Supply-chain logistics for physical devices, batteries, and consumables (the System can detect and report shortfalls, but cannot deliver the items).
5. Shortages of health facility capacity and referral transport.

---

## Open Questions for Field Validation

1. What is the actual primary reason for claim voucher rejections at the PHC sector meeting — data errors, documentation gaps, or administrative delays?
2. In which hours of the day does an ASHA have uninterrupted, exclusive access to her phone?
3. How long do state-supplied Bluetooth devices remain functional and within calibration in field conditions?
4. Which government applications does the ASHA currently use in her daily work, and which does she consider trustworthy?
5. What minimum information does an ANM or PHC doctor need in a referral note to act without calling the ASHA back?
6. What colloquial terms does the ASHA use for each clinical symptom, per district and dialect, for Lexicon construction?
7. What are the exact incentive categories, rates, eligibility conditions, and evidence requirements in the pilot state today?
8. What is the realistic minimum Android version and RAM on devices currently issued or used by ASHAs in the pilot district?
9. Are there connectivity-window patterns (tower maintenance schedules, peak usage times) that the Sync_Engine should be aware of to optimise sync scheduling?
